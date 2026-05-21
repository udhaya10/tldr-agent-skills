# Command: `tldr health`

## Environment Pin

| Field | Value |
|---|---|
| `tldr --version` | 0.4.0 |
| Build features | `semantic` (verified via runtime probe on 2026-05-21) |
| Target repo | Stock-Monitor @ commit `e601869` |
| Upstream `tldr-code` pinned to | local clone @ `6c4011a` (release v0.4.0) |
| Daemon state at probe time | N/A — `health` does not use the daemon route |
| OS | darwin 25.2.0 |
| Probe date | 2026-05-22 |

Re-run all evidence via [`health.probes/probe.sh`](./health.probes/probe.sh).

---

## Ground Truth (`tldr health --help`)

```text
Comprehensive code health dashboard

Usage: tldr health [OPTIONS] [PATH]

Arguments:
  [PATH]
          Path to analyze (file or directory)
          
          [default: .]

Options:
      --detail <DETAIL>
          Show detailed sub-analyzer output
          
          Valid values: complexity, cohesion, dead_code, martin, coupling, similarity, all

      --quick
          Quick mode (skip coupling and similarity - faster)

      --preset <PRESET>
          Threshold preset (strict, default, relaxed)

          Possible values:
          - strict:  Strict thresholds for high-quality codebases
          - default: Default thresholds (recommended)
          - relaxed: Relaxed thresholds for legacy code
          
          [default: default]

      --max-items <MAX_ITEMS>
          Maximum items to return for coupling and similarity analyses (default: 50)
          
          [default: 50]

      --summary
          Summary mode - omit detail arrays, only include summary metrics

  -f, --format <FORMAT>
          Output format
          
          Supported by every command: json, text, compact.
          
          Command-specific formats (rejected at runtime by other commands): sarif  — only: vuln, clones dot    — only: calls, impact, hubs, inheritance, clones, deps
          
          cli-error-clarity-v2 (P2.BUG-5): possible values are hidden on the global help to avoid promising sarif/dot for every subcommand. Run `tldr <cmd> --help` to confirm what a specific command emits, and see `validate_format_for_command` in `output.rs` for the source of truth.
          
          [default: json]

  -l, --lang <LANG>
          Programming language (auto-detect if not specified)

  -q, --quiet
          Suppress progress output

  -v, --verbose
          Enable verbose/debug output

  -h, --help
          Print help (see a summary with '-h')
```

---

## Output Shape

| Aspect | Value |
|---|---|
| Default format | `json` |
| Formats that work | `json`, `text`, `compact` (P01, P06, P16) |
| Formats that error | `sarif`, `dot` (P05: exit 1) |
| Typical output size | small (<2KB) in `--summary` mode; **heavy (>50KB)** in full mode with `--detail all`; medium for single sub-analyzer detail |
| Typical latency | **~30–50ms** for a 4-file dir (P01); **~9.7 seconds** for 56 files (P02). Health is **slow** — budget accordingly. |

**Top-level keys (JSON, summary mode):**
- `wrapper` (`string`) — literal `"health"` (constant identifier)
- `path` (`string`) — echoed path  ← **but see schema inconsistency below**
- `language` (`string \| null`) — detected language
- `quick_mode` (`bool`) — whether `--quick` was passed
- `total_elapsed_ms` (`float`) — total wall-clock time of all sub-analyzers
- `summary` (`object`) — per-analyzer aggregate metrics:
  - `files_analyzed` (`int`)
  - `functions_analyzed` (`int`)
  - `classes_analyzed` (`int`)
  - `avg_cyclomatic` (`float`)
  - `hotspot_count` (`int`) — functions with cyclomatic above threshold
  - `avg_lcom4` (`float`) — LCOM4 cohesion average (omitted when no classes)
  - `low_cohesion_count` (`int`)
  - `dead_count` (`int`)
  - `dead_percentage` (`float`)
  - `packages_in_pain_zone` (`int`) — Martin pain-zone (only in full mode)
  - `tight_coupling_pairs` (`int`) — only meaningful in full mode
  - `similar_pairs` (`int`) — only meaningful in full mode
- `errors` (`array`) — sub-analyzer errors (empty array on success)

**`--detail <sub-analyzer>` shape:** returns the full structured output of one of the 6 sub-analyzers (`complexity`, `cohesion`, `dead_code`, `martin`, `coupling`, `similarity`, or `all`). The shape varies per analyzer — e.g., `complexity` returns `{functions_analyzed, avg_cyclomatic, max_cyclomatic, ...per-function array..., summary{}}`. Use `--detail all` to dump everything.

**Empty-directory stub (P13):**
```json
{
  "wrapper": "health",
  "root": "/tmp/...",      ← NOTE: field name is "root", NOT "path"
  "language": null,
  "quick_mode": false,
  "summary": null,
  "details": {},
  "warnings": ["Empty directory: no source files to analyze"]
}
```
**Schema inconsistency:** the normal output uses `"path"` (line 302 in `health.rs`), but the empty-dir short-circuit at `health.rs:148` uses `"root"`. Agents parsing the response must check both keys. Also: `summary: null` here (vs an object in normal output) and an additional `warnings` array appears.

**Text format (P06):** Compact one-line-per-analyzer report:
```
Health Report: <path>
==================================================
Complexity:  avg CC=4.1, hotspots=1 (CC>10)
Cohesion:    7 classes, avg LCOM4=2.1, 2 low-cohesion
Dead Code:   none detected

Elapsed: 31ms
```

**Compact format (P16):** Single-line JSON.

**Error shapes — `health` has TWO distinct exit codes (NOT three as the T21 source comment claims):**
- **Exit 1** — anyhow-style runtime errors:
  - Bad path (P04): `Error: Path not found: <path>`
  - Format rejection (P05): standard validator error
  - `--quick` + `--detail=coupling` (P09): `Error: --detail=coupling requires full mode. Remove --quick flag to analyze coupling.` — clear and actionable
  - `--quick` + `--detail=similarity` (P10): same pattern
- **Exit 2** — clap-level errors:
  - Invalid `--detail` value (P08): `error: invalid value '<bad>' for '--detail <DETAIL>': Invalid detail value '<bad>'. Valid values: complexity, cohesion, dead_code, martin, coupling, similarity, all`

> **Source-comment drift:** `health.rs:13` claims *"T21: All health errors map to exit code 2"* but empirically this is **false**. Most errors exit 1 (via `anyhow::bail!`); only clap-level validation exits 2. Agents that branch on exit 2 will miss most failure cases.

---

## Probe Matrix

Slug convention: `NN-<token>[-<modifier>]`. The audit script globs by ID, so modifiers are safe.

| # | Probe | Type | Exit | Captured |
|---|-------|------|------|----------|
| P01 | `tldr health backend/providers --quick --summary` | happy | 0 | [`01-happy.*`](./health.probes/) |
| P02 | `tldr health backend --quick --summary` | happy-scale | 0 | [`02-happy-scale.*`](./health.probes/) |
| P03 | N/A: all inputs optional — `[PATH]` defaults to `.` (verified at `health.rs:31`). | — | — | — |
| P04 | `tldr health /no/such/path` | failure-badpath | 1 | [`04-badpath.*`](./health.probes/) |
| P05 | `tldr health backend/providers --quick -f sarif` | format-reject | 1 | [`05-format-reject-sarif.*`](./health.probes/) |
| P06 | `tldr health backend/providers --quick -f text` | format-text | 0 | [`06-format-text.*`](./health.probes/) |
| P07 | `tldr health backend/providers --quick --detail complexity` | flag-detail-valid | 0 | [`07-detail-complexity.*`](./health.probes/) |
| P08 | `tldr health backend/providers --quick --detail bogus` | failure-detail-invalid | 2 | [`08-detail-invalid.*`](./health.probes/) |
| P09 | `tldr health backend/providers --quick --detail coupling` | failure-quick-coupling | 1 | [`09-quick-coupling-conflict.*`](./health.probes/) |
| P10 | `tldr health backend/providers --quick --detail similarity` | failure-quick-similarity | 1 | [`10-quick-similarity-conflict.*`](./health.probes/) |
| P11 | `tldr health backend/providers --quick --summary --preset strict` | flag-preset-strict | 0 | [`11-preset-strict.*`](./health.probes/) |
| P12 | `tldr health backend/providers --quick --summary --preset relaxed` | flag-preset-relaxed | 0 | [`12-preset-relaxed.*`](./health.probes/) |
| P13 | `tldr health /tmp/tldr-health-empty` | boundary-empty-dir | 0 | [`13-empty-dir.*`](./health.probes/) |
| P14 | `tldr health backend/providers --max-items 5 --summary` | flag-max-items | 0 | [`14-max-items-5.*`](./health.probes/) |
| P15 | `tldr health backend/providers --summary` *(no --quick)* | mode-full | 0 | [`15-full-mode.*`](./health.probes/) |
| P16 | `tldr health backend/providers --quick --summary -f compact` | format-compact | 0 | [`16-format-compact.*`](./health.probes/) |
| P17 | `tldr health backend/db.py --quick --summary` | boundary-single-file | 0 | [`17-single-file.*`](./health.probes/) |

### Observations

- **P01 (small dir, 22 lines):** Summary returns 4 files, 23 functions, 7 classes. `avg_cyclomatic: 4.1`, `hotspot_count: 1` (one function exceeds the cyclomatic threshold). Latency: 30ms.
- **P02 (full backend, 22 lines):** Same summary shape. Numbers: **56 files, 1286 functions, 68 classes, hotspot_count: 255, dead_count: 8, dead_percentage: 0.62%**. **Latency: 9.7 seconds** — health is genuinely slow on real codebases. `tight_coupling_pairs: 0` and `similar_pairs: 0` because `--quick` skipped those analyzers.
- **P04 (bad path):** stderr `Error: Path not found: <path>`, exit `1`. Source: `health.rs:129-131` uses `anyhow::bail!`. **Contradicts source comment T21.**
- **P05 (sarif rejection):** standard validator error, exit `1`.
- **P06 (text format, 8 lines):** Compact human-readable report. One line per sub-analyzer with key metrics inline. Good for chat output.
- **P07 (`--detail complexity`, 216 lines):** Full complexity sub-analyzer JSON. Top-level fields: `functions_analyzed`, `avg_cyclomatic`, `max_cyclomatic`, per-function array, and a trailing `summary{}`. Use this to drill into hotspots.
- **P08 (`--detail bogus`):** clap value_parser rejection. Exit `2`. Error: `invalid value 'bogus' for '--detail <DETAIL>': Invalid detail value 'bogus'. Valid values: complexity, cohesion, dead_code, martin, coupling, similarity, all`. **Lists all valid values** — agents can parse for recovery.
- **P09 (`--quick --detail coupling`):** Exit `1`. Error: `--detail=coupling requires full mode. Remove --quick flag to analyze coupling.` **Same message pattern for similarity (P10).** The conflict is enforced declaratively in `health.rs:105-115` (T23 mitigation).
- **P11 (`--preset strict`) vs P01:** **byte-identical.** P12 (`--preset relaxed`) also byte-identical. **The preset flag has no visible effect in summary mode.** Likely because summary counts pre-decided thresholds elsewhere; preset only affects detail-mode threshold flags. **Agent rule: don't pass `--preset` in summary mode expecting changed counts — it's a no-op there.**
- **P13 (empty dir):** Exit `0`. Returns a **stub shape with `root` (not `path`!)**, `language: null`, `summary: null`, `details: {}`, and `warnings: ["Empty directory: no source files to analyze"]`. This is the `schema-cleanup-v2 (P2.BUG-10)` short-circuit at `health.rs:142-164`. **Critical: schema differs from the normal-success case.**
- **P14 (`--max-items 5`) in summary mode:** byte-identical to P01. `--max-items` only affects the coupling/similarity *detail* arrays in full mode; no effect on summary metrics.
- **P15 (full mode, no `--quick`):** For a 4-file dir, identical summary numbers to P01 with `quick_mode: false` and 9ms additional latency. Coupling and similarity both reported `0` pairs — no extra signal at this scale.
- **P16 (compact):** Single-line JSON, same content as P01.
- **P17 (single file `backend/db.py`):** Works. `files_analyzed: 1`, `functions_analyzed: 9`. **Health really does accept a file path** — `--help` says "file or directory" and that's accurate.

---

## Source Code Reality

**Target file:** `crates/tldr-cli/src/commands/health.rs` (pinned to local clone at `6c4011a`).

**Argument struct (`health.rs:28-55`):**
```rust
pub struct HealthArgs {
    #[arg(default_value = ".")]
    pub path: PathBuf,
    #[arg(long, value_parser = detail_parser)]
    pub detail: Option<String>,
    #[arg(long)]
    pub quick: bool,
    #[arg(long, value_enum, default_value = "default")]
    pub preset: PresetArg,
    #[arg(long, default_value = "50")]
    pub max_items: usize,
    #[arg(long)]
    pub summary: bool,
}
```
Path defaults to `.` (P03 N/A). `--detail` uses a **custom `value_parser`** that rejects unknown values at clap-parse time (P08 exit 2).

**`--detail` validator (`health.rs:80-99`):**
```rust
fn detail_parser(s: &str) -> Result<String, String> {
    let valid = [
        "complexity", "cohesion", "dead_code", "martin",
        "coupling", "similarity", "all",
    ];
    if valid.contains(&s) { Ok(s.to_string()) }
    else { Err(format!("Invalid detail value '{}'. Valid values: {}", s, valid.join(", "))) }
}
```
Confirms the 7 valid sub-analyzer names.

**Quick + detail conflict (`health.rs:103-117`):**
```rust
fn validate(&self) -> Result<()> {
    if self.quick {
        if let Some(ref detail) = self.detail {
            if detail == "coupling" || detail == "similarity" {
                anyhow::bail!(
                    "--detail={} requires full mode. Remove --quick flag to analyze {}.",
                    detail, detail
                );
            }
        }
    }
    Ok(())
}
```
T23 mitigation. P09/P10 confirm: `anyhow::bail!` → exit 1.

**Path validation (`health.rs:129-131`):**
```rust
if !self.path.exists() {
    anyhow::bail!("Path not found: {}", self.path.display());
}
```
Standard anyhow → exit 1. Contradicts the T21 source comment.

**Empty-dir short-circuit (`health.rs:142-164`):**
```rust
if lang.is_none() && self.path.is_dir() && Language::from_directory(&self.path).is_none() {
    let stub = serde_json::json!({
        "wrapper": "health",
        "root": self.path.display().to_string(),    // ← "root", not "path"
        "language": null,
        "quick_mode": self.quick,
        "summary": serde_json::Value::Null,
        "details": {},
        "warnings": ["Empty directory: no source files to analyze"],
    });
    ...
}
```
**Confirms the schema inconsistency.** Normal-mode output uses `"path"` (line 302); empty-dir stub uses `"root"`. The source mentions parity with `structure`'s warnings approach but doesn't reconcile the field name.

**No daemon route.** `health.rs` does not call `try_daemon_route`. Every invocation re-runs all 6 (or 4 in `--quick` mode) sub-analyzers concurrently. **Implication:** repeated `health` calls on the same directory don't benefit from caching — they re-compute every time.

**Source-comment drift (`health.rs:11-14`):**
```
//! # Premortem Mitigations
//! - T20: value_parser for --detail validation
//! - T21: All health errors map to exit code 2
//! - T23: Validate --quick + --detail=coupling/similar conflict
```
**T21 is empirically false.** Most errors exit 1 (anyhow paths); only T20 (clap value_parser) actually returns exit 2. Source documentation drift worth flagging upstream.

**Format validator** confirmed at `crates/tldr-cli/src/output.rs::validate_format_for_command` — `health` is in neither `SARIF_SUPPORTED` nor `DOT_SUPPORTED`.

---

## Architectural Deep Dive

- **Engine:** `run_health` in `tldr-core/src/quality/health.rs` runs 6 sub-analyzers concurrently: complexity (cyclomatic), cohesion (LCOM4), dead_code, martin (package coupling Ca/Ce/I/A/D), coupling (pairwise), similarity (function clone detection). `--quick` skips the last two (the expensive cross-file ones).
- **No caching.** No daemon route. Every invocation rebuilds the analysis from scratch. Latency scales with file count — 4 files in 30ms, 56 files in 9.7s.
- **Threshold model:** the `--preset` flag selects thresholds for `hotspot_count` and `low_cohesion_count` classification. **In `--summary` mode the preset has no observable effect on counts** (P11, P12 byte-identical to P01) — the threshold logic likely runs at the per-item level for detail mode only.
- **Empty-dir handling:** when the path is a directory with no source files of the auto-detected language, a stub response is returned (exit 0, `warnings` array, `summary: null`). **The stub uses different field names from the normal response** — `root` instead of `path`.
- **Sub-analyzer drilling:** `--detail <name>` returns the full structured output of one analyzer. `--detail all` returns everything. The 7 valid names are: complexity, cohesion, dead_code, martin, coupling, similarity, all.
- **LLM cognitive load:** Replaces "run 6 separate analysis commands and aggregate them yourself." Returns a one-shot dashboard. Agents use `--summary` for triage, then drill into `--detail <analyzer>` for the problem area.

---

## Intent & Routing

- **User/Agent Goal:** Get a one-shot dashboard view of a codebase's quality, complexity, and dead code.
- **When to choose this over similar tools:**
  - Use *first* during any code audit — `--quick --summary` is the fastest way to triage.
  - Use *before* running `tldr complexity`, `tldr cohesion`, `tldr dead`, etc. separately. Health aggregates them.
  - Use *with* `--detail <analyzer>` to drill into a specific dimension after the summary flags a problem.
  - Use *with* `--summary` for compact agent-friendly output; omit for full detail.
- **Prerequisites:** None.
- **Composes well with:**
  - `tldr health <dir> --quick --summary` → spot problems → `tldr health <dir> --detail complexity` to drill in → `tldr extract <hotspot-file>` → `tldr slice <file> <function> <line>` for repair planning.
  - For multi-language repos: pass `-l <lang>` to scope the analysis; without it, auto-detect picks the dominant language.

---

## Agent Synthesis

> **How to use `tldr health`:**
> Use as the first command in any code audit. Aggregates 6 sub-analyzers (complexity, cohesion, dead_code, martin, coupling, similarity) into a unified dashboard. **Always start with `--quick --summary`** for triage; drill into one sub-analyzer via `--detail <name>` after spotting a problem. There is no daemon caching — every call recomputes.
>
> **Crucial Rules:**
> - **`[PATH]` is optional** (defaults to `.`) and accepts **both files and directories** — confirmed by P17.
> - **Two exit codes for failures:**
>   - `1` = anyhow paths: bad path, format reject, `--quick`+`--detail=coupling`/`similarity` conflict. **Most failures land here.**
>   - `2` = clap path: invalid `--detail` value only. The error lists all 7 valid sub-analyzers.
>   - **The source claims T21 maps all errors to exit 2 — this is wrong.** Verified empirically: most errors exit 1.
> - **`--quick` + `--detail=coupling` (or `similarity`) is a hard conflict.** The CLI rejects with `Error: --detail=coupling requires full mode. Remove --quick flag to analyze coupling.` (exit 1).
> - **`--preset strict|default|relaxed` is a NO-OP in `--summary` mode.** The summary counts don't change with preset. Use `--detail <analyzer>` if you need the preset's thresholds applied to per-item flagging.
> - **Schema inconsistency** between normal mode and empty-dir stub:
>   - Normal: `{wrapper, path, language, quick_mode, total_elapsed_ms, summary{}, errors[]}`
>   - Empty dir: `{wrapper, root, language: null, quick_mode, summary: null, details: {}, warnings: [...]}`. **Note `path` vs `root`** and presence of `warnings` array. Agents must handle both shapes.
> - **`--quick` SKIPS coupling and similarity** (faster, but `tight_coupling_pairs` and `similar_pairs` will always be 0). Use full mode (omit `--quick`) only when you actually want those cross-file analyses.
> - **`--max-items N` only affects coupling/similarity detail arrays in full mode** — no effect in `--summary` mode or when those analyzers are skipped.
> - **Health is slow on real codebases:** 9.7s for 56 files in `--quick` mode (P02). Budget time accordingly; for large repos consider `--quick --summary` first and only drill in selectively.
> - **`-f sarif` and `-f dot` are rejected** (exit 1).
>
> **Commands:**
> - Triage default: `tldr health <dir> --quick --summary`
> - Drill into one analyzer: `tldr health <dir> --detail complexity`
> - Full mode (slow): `tldr health <dir>`
> - Compact for piping: `tldr health <dir> --quick --summary -f compact`
> - Single file: `tldr health <file> --quick --summary`
> - Strict thresholds (for detail mode): `tldr health <dir> --detail complexity --preset strict`
