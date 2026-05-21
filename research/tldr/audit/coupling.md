# Command: `tldr coupling`

## Environment Pin

| Field | Value |
|---|---|
| `tldr --version` | 0.4.0 |
| Build features | `semantic` (verified; coupling itself is AST-based, non-semantic) |
| Target repo | Stock-Monitor @ commit `e601869` |
| Upstream `tldr-code` pinned to | local clone @ `6c4011a` (release v0.4.0) |
| Daemon state at probe time | N/A — `tldr coupling` does **not** call `try_daemon_route` (verified by grep) |
| OS | darwin 25.2.0 |
| Probe date | 2026-05-22 |

Re-run all evidence via [`coupling.probes/probe.sh`](./coupling.probes/probe.sh).

---

## Ground Truth (`tldr coupling --help`)

```text
Analyze coupling between modules/classes via cross-module call edges (afferent/efferent, instability). Measures function-call coupling, not import-level dependencies — use `tldr deps` or `tldr imports` for that (P12.AGG12-14)

Usage: tldr coupling [OPTIONS] <PATH_A> [PATH_B]

Arguments:
  <PATH_A>
          First source module (pair mode) or directory to scan (project-wide mode)

  [PATH_B]
          Second source module (pair mode). Omit for project-wide scan

Options:
      --timeout <TIMEOUT>
          Timeout in seconds (TIGER E02 mitigation)

          [default: 30]

      --project-root <PROJECT_ROOT>
          Project root for path validation (optional)

  -n, --max-pairs <MAX_PAIRS>
          Maximum number of pairs to show in project-wide mode (default: 20)

          [default: 20]

      --top <TOP>
          Limit output to top N modules ranked by instability (project-wide mode only). 0 = show all

          [default: 0]

      --cycles-only
          Only show modules involved in dependency cycles (project-wide mode only)

      --include-tests
          Include test files in analysis (excluded by default)

  -l, --lang <LANG>
          Language filter (auto-detected if omitted)

  -f, --format <FORMAT>
          Output format

          Supported by every command: json, text, compact.

          Command-specific formats (rejected at runtime by other commands): sarif  — only: vuln, clones dot    — only: calls, impact, hubs, inheritance, clones, deps

          cli-error-clarity-v2 (P2.BUG-5): possible values are hidden on the global help to avoid promising sarif/dot for every subcommand. Run `tldr <cmd> --help` to confirm what a specific command emits, and see `validate_format_for_command` in `output.rs` for the source of truth.

          [default: json]

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
| Formats that work | `json`, `text`, `compact` (P01, P06, P07) |
| Formats that error | `sarif`, `dot` (P05, P08: exit 1) |
| Typical output size | small (~20 lines pair mode) to medium (~110 lines project-wide) |

**TWO COMPLETELY DIFFERENT SCHEMAS** based on PATH_B presence:

### Pair mode (PATH_A + PATH_B):
```json
{
  "path_a": "<file_a>",
  "path_b": "<file_b>",
  "a_to_b": { "calls": [{ caller, callee, line }, ...], "count": N },
  "b_to_a": { "calls": [...], "count": M },
  "total_calls": N+M,
  "coupling_score": 0.0-1.0,
  "verdict": "loose" | "moderate" | "tight" | "high"
}
```

### Project-wide mode (PATH_A only, must be directory):
```json
{
  "martin_metrics": {
    "schema_version": "1.0",
    "modules_analyzed": N,
    "metrics": [{ module, ca, ce, instability, in_cycle }, ...],
    "cycles": [...],
    "summary": { avg_instability, total_cycles }
  },
  "pairwise_coupling": {
    "modules_analyzed": N,
    "pairs_analyzed": P,
    "total_cross_file_pairs": T,
    "tight_coupling_count": C,
    "top_pairs": [...]
  }
}
```

**`MartinMetric` shape:** `{ module, ca (afferent — incoming), ce (efferent — outgoing), instability (ce/(ca+ce)), in_cycle }`. Robert Martin's classic coupling metrics.

**Empty-result shape (P19, empty dir):**
Project-wide shape with all-zero metrics. NO `warnings` field.

**Error shapes:**
- Missing PATH_A: clap-style → exit **2**
- Bad path / file-as-single-arg (P04, P20): `"Error: For pair mode, provide two file paths: tldr coupling <file_a> <file_b>\nFor project-wide mode, provide a directory: tldr coupling <directory>"` → exit **1** (best-in-class help-text-in-error UX!)
- Format reject: `"Error: --format sarif not supported by coupling. ..."` → exit **1**
- Bad `--lang`: clap-style → exit **2**

---

## Probe Matrix

| # | Probe | Type | Exit | Captured |
|---|-------|------|------|----------|
| P01 | `tldr coupling yahoo.py base.py` | happy (pair mode) | 0 | [`01-happy.*`](./coupling.probes/) |
| P02 | `tldr coupling backend/providers` | happy-scale (project-wide) | 0 | [`02-happy-scale.*`](./coupling.probes/) |
| P03 | `tldr coupling` *(no PATH_A)* | failure-missing-input | 2 | [`03-missing-arg.*`](./coupling.probes/) |
| P04 | `tldr coupling /no/such/dir` | failure-badpath (with usage hint) | 1 | [`04-badpath.*`](./coupling.probes/) |
| P05 | `tldr coupling ... -f sarif` | format-reject (sarif) | 1 | [`05-format-reject-sarif.*`](./coupling.probes/) |
| P06 | `tldr coupling ... -f text` | format-text | 0 | [`06-format-text.*`](./coupling.probes/) |
| P07 | `tldr coupling ... -f compact` | format-compact | 0 | [`07-format-compact.*`](./coupling.probes/) |
| P08 | `tldr coupling ... -f dot` | format-reject (dot) | 1 | [`08-format-reject-dot.*`](./coupling.probes/) |
| P09 | `tldr coupling backend --max-pairs 1` | max-pairs-low (project mode) | 0 | [`09-max-pairs-low.*`](./coupling.probes/) |
| P10 | `tldr coupling backend --top 3` | top-3 | 0 | [`10-top-three.*`](./coupling.probes/) |
| P11 | `tldr coupling backend --cycles-only` | cycles-only flag | 0 | [`11-cycles-only.*`](./coupling.probes/) |
| P12 | `tldr coupling backend --include-tests` | include-tests | 0 | [`12-include-tests.*`](./coupling.probes/) |
| P13 | `tldr coupling backend --timeout 1` | timeout-short | 0 | [`13-timeout-short.*`](./coupling.probes/) |
| P14 | `tldr coupling yahoo.py base.py --project-root backend` | project-root | 0 | [`14-project-root.*`](./coupling.probes/) |
| P15 | `tldr coupling ... -l brainfuck` | bad-lang | 2 | [`15-bad-lang.*`](./coupling.probes/) |
| P16 | `tldr coupling ... -l python` | lang-python | 0 | [`16-lang-python.*`](./coupling.probes/) |
| P17 | `tldr coupling ... -l typescript` | lang-mismatch | 0 | [`17-lang-mismatch.*`](./coupling.probes/) |
| P18 | `tldr coupling ... -q` | quiet | 0 | [`18-quiet.*`](./coupling.probes/) |
| P19 | `tldr coupling <empty-tmp-dir>` | empty-dir | 0 | [`19-empty-dir.*`](./coupling.probes/) |
| P20 | `tldr coupling yahoo.py` *(file, no PATH_B)* | file-as-single-arg | 1 | [`20-single-file.*`](./coupling.probes/) |

### Observations

- **P01** — Pair mode: yahoo.py vs base.py. Output: `{ a_to_b: { count: 1 }, b_to_a: { count: 0 }, total_calls: 1, coupling_score: 0.5, verdict: "high" }`. One call edge from `YahooProvider.__init__` to `Provider.__init__`. `line: 0` (init call site line not captured).
- **P02** — Project-wide on `backend/providers/` (4 files): 4 modules analyzed (`__init__.py`, `base.py`, `dhan.py`, `yahoo.py`). Each gets a MartinMetric entry with ca/ce/instability/in_cycle. Plus `pairwise_coupling` block with `top_pairs[]`. **Completely different schema from pair mode.**
- **P03** — stderr `"error: the following required arguments were not provided: <PATH_A>"`, exit `2`.
- **P04** — **Best-in-class error UX:** stderr `"Error: For pair mode, provide two file paths: tldr coupling <file_a> <file_b>\nFor project-wide mode, provide a directory: tldr coupling <directory>"`, exit `1`. The error explains BOTH usage modes — no other command in the audit suite documents both modes in the error.
- **P05** — stderr `"Error: --format sarif not supported by coupling. Use --format json. SARIF is only emitted by: vuln, clones."`, exit `1`.
- **P06** — Text format renders a human-readable summary. Tabular display of Martin metrics for project-wide mode; simpler pair-mode summary for pair mode.
- **P07** — Single-line minified JSON.
- **P08** — stderr `"Error: --format dot not supported by coupling. ..."`, exit `1`.
- **P09** — `--max-pairs 1` on full backend: limits `pairwise_coupling.top_pairs[]` to 1 entry. The Martin metrics array is unaffected (since martin metrics are per-module, not per-pair). 487 lines stdout — likely truncated by probe.sh.
- **P10** — `--top 3` (top 3 modules by instability): truncates `martin_metrics.metrics[]` to 3 entries. `--top 0` is "show all" (cross-command convention divergence from `tldr cognitive --top 0` which means "all" too, BUT `tldr contracts --limit 0` means "zero").
- **P11** — `--cycles-only`: filters `martin_metrics.metrics[]` to only modules where `in_cycle == true`. Stock-Monitor backend has cycles in this scope.
- **P12** — `--include-tests`: includes test files (default-excluded). Larger output because more modules.
- **P13** — `--timeout 1` (1 second): output produced — no timeout exceeded on this small repo. Larger codebases might trigger timeout warning.
- **P14** — `--project-root backend` with pair mode: same output as P01 (the flag is for path validation; doesn't affect coupling logic in this case).
- **P15** — clap-style: `"error: invalid value 'brainfuck' for '--lang <LANG>': Unknown language: brainfuck"`, exit `2`.
- **P16** — `-l python` explicit: identical to default auto-detect.
- **P17** — **`-l typescript` IGNORED:** Output identical to P02 (same 4 Python modules analyzed). The `--lang` flag is accepted but doesn't actually filter the analysis. **Silent flag — same anti-pattern as `tldr cohesion --lang`.**
- **P18** — `-q` quiet: no progress messages in this command, so same as default.
- **P19** — Empty dir: project-wide shape with all-zero metrics. NO `warnings` field. Indistinguishable from "no Python files in dir" or "wrong language" silently.
- **P20** — Single file as PATH_A (no PATH_B): **same error as P04** with the helpful "pair mode / project-wide mode" usage hint. `tldr coupling` REJECTS single-file inputs — it requires either two files (pair mode) or one directory (project-wide mode).

---

## Source Code Reality

**Target file(s):**
- `crates/tldr-cli/src/commands/patterns/coupling.rs` (~1500+ lines — large because of per-language AST configs)
- `crates/tldr-core/src/quality/coupling.rs` (Martin metric computation, cycle detection)
- `crates/tldr-cli/src/output.rs:113` (`validate_format_for_command`)

**Pinned to upstream commit:** `6c4011a` (release v0.4.0)

**Argument struct:**
```rust
// crates/tldr-cli/src/commands/patterns/coupling.rs:75-109
#[derive(Debug, Clone, Args)]
pub struct CouplingArgs {
    pub path_a: PathBuf,
    pub path_b: Option<PathBuf>,
    #[arg(long, default_value = "30")] pub timeout: u64,
    #[arg(long)] pub project_root: Option<PathBuf>,
    #[arg(long, short = 'n', default_value = "20")] pub max_pairs: usize,
    #[arg(long, default_value = "0")] pub top: usize,
    #[arg(long)] pub cycles_only: bool,
    #[arg(long)] pub include_tests: bool,
    #[arg(long, short = 'l')] pub lang: Option<TldrLanguage>,
}
```
Reveals: PATH_A required, PATH_B optional. The mode dispatch is based on PATH_B presence AND PATH_A being a file vs directory. `--top` default 0 (means "show all" per `--help`).

**Helpful error message (P04/P20):**
The error text `"For pair mode, provide two file paths... For project-wide mode, provide a directory..."` is constructed in the validation layer when the input doesn't match either mode (e.g., PATH_A is a non-existent path, OR PATH_A is a single file with no PATH_B).

**Two distinct output schemas:**
- `analyze_pair()` → `PairCouplingReport` with `{ path_a, path_b, a_to_b, b_to_a, total_calls, coupling_score, verdict }`
- `analyze_project_wide()` → `ProjectCouplingReport` with `{ martin_metrics: {...}, pairwise_coupling: {...} }`

**No daemon route:** `grep -n try_daemon_route coupling.rs` returns 0 matches. Every call re-parses + builds graph + computes metrics.

**Format validation:** confirmed at `crates/tldr-cli/src/output.rs:113-163` — `coupling` is in neither `SARIF_SUPPORTED` nor `DOT_SUPPORTED`.

---

## Architectural Deep Dive

- **Under the hood:** Walks PATH (file or directory) via tree-sitter; per-language AST configs extract function definitions, imports, and call sites. Build cross-module call graph; compute afferent (Ca = incoming edges) and efferent (Ce = outgoing edges) per module; instability = Ce / (Ca + Ce). Detect cycles via DFS.
- **Performance:** Cold ~50-200ms per call. NO daemon caching. Timeout flag prevents pathological runs (TIGER E02 mitigation).
- **LLM cognitive load:** "Should these modules be tighter or looser?" — Martin metrics give the canonical SOLID-principles answer. Pair mode for "are these two files too entangled?"; project-wide for the global picture + cycle detection. Note the explicit `--help` disambiguation: this is FUNCTION-CALL coupling, NOT import coupling (use `tldr deps` for imports).

---

## Intent & Routing

- **User/Agent Goal:** measure architectural coupling — answer "how tangled is this module with the rest?" via function-call edges (NOT import edges).
- **When to choose this over similar tools:**
  - Over `tldr deps`: `deps` is IMPORT-graph; `coupling` is CALL-graph. The `--help` explicitly says use `deps`/`imports` for import-level dependencies (P12.AGG12-14 disambiguation).
  - Over `tldr cohesion`: `cohesion` is intra-class (LCOM4); `coupling` is inter-module.
  - Over `tldr calls`: `calls` is the raw cross-file call graph; `coupling` aggregates it into Martin metrics + per-pair coupling scores.
- **Prerequisites (composition):**
  - Choose mode explicitly: PAIR_A + PATH_B for two-file analysis; PATH_A only (directory) for project-wide. Single-file PATH_A is rejected (P20).
  - For mixed-language projects, `-l <lang>` is silently ignored (P17) — like `tldr cohesion`. Effectively language-agnostic (walks all supported source extensions).

---

## Agent Synthesis

> **How to use `tldr coupling`:**
> Dual-mode function-call coupling analyzer. **Pair mode:** `tldr coupling <FILE_A> <FILE_B>` returns `{ a_to_b, b_to_a, total_calls, coupling_score, verdict }`. **Project-wide mode:** `tldr coupling <DIR>` returns `{ martin_metrics: { schema_version, modules_analyzed, metrics:[{module, ca, ce, instability, in_cycle}], cycles, summary }, pairwise_coupling: {...} }`. NOT import-level — use `tldr deps`/`tldr imports` for imports. Default JSON; `-f text` for human display; `-f compact` for one-line; `sarif`/`dot` rejected. Exit codes: 0 ok, 1 path-not-found / single-file (rejected) / format-reject, 2 missing PATH_A / bad --lang.
>
> **Crucial Rules:**
> - **TWO completely different JSON schemas** based on PATH_B presence. Pair mode: top-level keys are `path_a`/`path_b`/`a_to_b`/`b_to_a`/`coupling_score`/`verdict`. Project mode: top-level keys are `martin_metrics`/`pairwise_coupling`. **Agents schema-validating output must branch on mode.** Detect mode by checking for `martin_metrics` key (project) or `path_a` key (pair).
> - **Single-file PATH_A (no PATH_B) is REJECTED with the BEST error in the audit suite.** `"Error: For pair mode, provide two file paths: tldr coupling <file_a> <file_b>\nFor project-wide mode, provide a directory: tldr coupling <directory>"` (P04, P20). The error documents BOTH usage modes inline.
> - **`-l <lang>` is SILENTLY IGNORED.** Probe P17: `-l typescript` on Python project returns the same Python-module output as default. Bad values still reject (clap exit 2), but valid values don't filter. Same anti-pattern as `tldr cohesion`. **Cross-command pattern:** the pattern/contracts namespace tends to declare `--lang` for global consistency but ignore it in the engine.
> - **`coupling` measures function-call coupling, NOT imports.** Explicit per `--help`: "use `tldr deps` or `tldr imports` for [import-level dependencies]" (P12.AGG12-14). Two functions could be tightly coupled via calls without importing each other (e.g., via type parameter or factory).
> - **`--top 0` means "show all"** in project mode (matches `tldr cognitive --top 0`, differs from `tldr contracts --limit 0` which means "literally zero"). Source default. For most queries, leave it at 0.
> - **Verdict bucket strings:** observed `"high"` in P01 for coupling_score 0.5. Likely `loose | moderate | tight | high` (thresholds not externally documented; verify against engine source).
> - **NO daemon route.** Every call re-parses + re-builds the cross-module graph. `tldr warm` is a no-op.
> - **Empty dir produces project-wide shape with zeros, NO `warnings` field.** Indistinguishable from a non-existent language / no-matching-files case. Inspect `martin_metrics.modules_analyzed > 0` to detect.
>
> **Command:** `tldr coupling <PATH_A> [PATH_B]`
>
> **With common flags:** `tldr coupling <DIR> --top 5 --cycles-only -f text` (use to surface only the high-instability modules involved in cycles — actionable refactor candidates).
