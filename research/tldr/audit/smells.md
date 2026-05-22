# Command: `tldr smells`

## Environment Pin

| Field | Value |
|---|---|
| `tldr --version` | 0.4.0 |
| Build features | `semantic` (verified; smells is AST-based, non-semantic for default mode) |
| Target repo | Stock-Monitor @ commit `e601869` |
| Upstream `tldr-code` pinned to | local clone @ `6c4011a` (release v0.4.0) |
| Daemon state at probe time | mixed (P27 cold, P28 warm) |
| OS | darwin 25.2.0 |
| Probe date | 2026-05-22 |

Re-run all evidence via [`smells.probes/probe.sh`](./smells.probes/probe.sh).
See also: [agent-oriented tool card](../../tool-cards/audit/smells.md).

---

## Ground Truth (`tldr smells --help`)

```text
Detect code smells

Usage: tldr smells [OPTIONS] [PATH]

Arguments:
  [PATH]
          Path to analyze (file or directory)

          [default: .]

Options:
  -l, --lang <LANG>
          Programming language to filter by (auto-detected if omitted)

  -t, --threshold <THRESHOLD>
          Threshold preset

          Possible values:
          - strict:  Strict thresholds for high-quality codebases
          - default: Default thresholds (recommended)
          - relaxed: Relaxed thresholds for legacy code

          [default: default]

  -s, --smell-type <SMELL_TYPE>
          Filter by smell type

          Possible values:
          - god-class, long-method, long-parameter-list, feature-envy, data-clumps,
          - low-cohesion (requires --deep), tight-coupling (requires --deep),
          - dead-code (requires --deep), code-clone (requires --deep),
          - high-cognitive-complexity (requires --deep), deep-nesting, data-class,
          - lazy-element, message-chain, primitive-obsession,
          - middle-man (requires --deep), refused-bequest (requires --deep),
          - inappropriate-intimacy (requires --deep)

      --suggest
          Include suggestions for fixing

      --deep
          Deep analysis: aggregate findings from cohesion, coupling, dead code, similarity, and cognitive complexity analyzers

      --no-default-ignore
          Walk vendored/build dirs

      --files <FILES>
          Limit the scan to specific files (repeatable; EXACT-PATH-ONLY, no glob expansion).
          Implies --include-tests

      --include-tests
          Include findings from test files. Default: false

  -f, --format <FORMAT>
          [json | text | compact | sarif (rejected) | dot (rejected)]
          [default: json]

  -q, --quiet  -v, --verbose  -h, --help
```

---

## Output Shape

| Aspect | Value |
|---|---|
| Default format | `json` |
| Formats that work | `json`, `text`, `compact` (P01, P06, P07) |
| Formats that error | `sarif`, `dot` (P05, P08: exit 1) |
| Typical output size | medium (~140 lines for 4-file dir; ~7500 for full backend; ~1000 for --deep on 4 files) |

**Top-level keys (JSON, `SmellsReport`):**
- `smells` (`array<Smell>`) — detected smells
- `files_scanned` (`u32`)
- `by_file` (`object`, KEYED by ABSOLUTE FILE PATH) — `{ "/abs/path/file.py": N, ... }` count per file
- `summary` (`object`) — `{ total_smells, by_type: {smell_type: count, ...}, avg_smells_per_file }`
- `excluded_test_smells` (`u32`) — count suppressed by default test-file filter
- `warnings` (`array<string>`) — deep-only advisory injected when NOT `--deep`, NOT `--smell-type`, NOT `--quiet`
- `total_smells` (`u32`) — **TOP-LEVEL MIRROR** of `summary.total_smells`
- `avg_smells_per_file` (`f64`) — **TOP-LEVEL MIRROR** of `summary.avg_smells_per_file`

**`Smell` shape:**
- `smell_type` (`string`) — snake_case (e.g., `"lazy_element"`, `"long_method"`, `"god_class"`) — NOT the kebab-case from `--smell-type` flag
- `file` (`string`) — **ABSOLUTE path**, not project-relative
- `name` (`string`) — symbol name (function, class, method)
- `line` (`u32`)
- `reason` (`string`) — human-readable explanation including threshold
- `severity` (`u32`) — observed `1` (likely also `2`, `3`)

**Deep-only warning (BUG-18 fix):**
When NOT `--deep`, NOT `--smell-type <X>`, NOT `--quiet`, `warnings[]` contains:
```
"Note: 8 smell analyzers require --deep flag. Run with --deep for: low_cohesion, tight_coupling, dead_code, code_clone, high_cognitive_complexity, middle_man, refused_bequest, inappropriate_intimacy"
```
Suppressed when `-q`, `--deep`, or `--smell-type` is set.

**Empty-result shape (P12 god-class no matches, P14 deep-required without --deep, P24 empty dir, P25 README.md):**
```json
{
  "smells": [], "files_scanned": 4, "by_file": {},
  "summary": { "total_smells": 0, "by_type": {}, "avg_smells_per_file": 0.0 },
  "excluded_test_smells": 0, "warnings": [],
  "total_smells": 0, "avg_smells_per_file": 0.0
}
```
Exit 0. Same shape across all four no-result conditions.

**Error shapes:**
- Path not found: `"Error: Path not found: <path>"` → exit **1** (anyhow! — matches `tldr churn`/`tldr debt`/`tldr hotspots`)
- Bad `--threshold`: clap-style `"error: invalid value 'wat' for '--threshold <THRESHOLD>' [possible values: strict, default, relaxed]"` → exit **2**
- Bad `--smell-type`: clap-style with FULL list of 18 valid values inline → exit **2**
- Bad `--files <relative-path>`: `"Error: --files <input>: Path not found: <RESOLVED-ABS-PATH>"` → exit **1**
- Bad `--lang`: clap-style → exit **2**
- Format reject: `"Error: --format sarif not supported by smells. ..."` → exit **1**

---

## Probe Matrix

| # | Probe | Type | Exit | Captured |
|---|-------|------|------|----------|
| P01 | `tldr smells backend/providers` | happy (7 smells, with warning) | 0 | [`01-happy.*`](./smells.probes/) |
| P02 | `tldr smells backend` | happy-scale | 0 | [`02-happy-scale.*`](./smells.probes/) |
| P03 | N/A: PATH defaults to `.`. | — | — | [`03-missing-arg.*`](./smells.probes/) (placeholder) |
| P04 | `tldr smells /no/such/dir` | failure-badpath | 1 | [`04-badpath.*`](./smells.probes/) |
| P05 | `tldr smells ... -f sarif` | format-reject (sarif) | 1 | [`05-format-reject-sarif.*`](./smells.probes/) |
| P06 | `tldr smells ... -f text` | format-text | 0 | [`06-format-text.*`](./smells.probes/) |
| P07 | `tldr smells ... -f compact` | format-compact | 0 | [`07-format-compact.*`](./smells.probes/) |
| P08 | `tldr smells ... -f dot` | format-reject (dot) | 1 | [`08-format-reject-dot.*`](./smells.probes/) |
| P09 | `tldr smells ... -t strict` | threshold strict | 0 | [`09-threshold-strict.*`](./smells.probes/) |
| P10 | `tldr smells ... -t relaxed` | threshold relaxed | 0 | [`10-threshold-relaxed.*`](./smells.probes/) |
| P11 | `tldr smells ... -t wat` | bad-threshold | 2 | [`11-threshold-bogus.*`](./smells.probes/) |
| P12 | `tldr smells ... -s god-class` | god-class filter (empty here) | 0 | [`12-smell-type-godclass.*`](./smells.probes/) |
| P13 | `tldr smells ... -s wat` | bad-smell-type (full list) | 2 | [`13-smell-type-bogus.*`](./smells.probes/) |
| P14 | `tldr smells ... -s low-cohesion` *(no --deep)* | needs-deep silent | 0 | [`14-smell-needs-deep.*`](./smells.probes/) |
| P15 | `tldr smells ... --suggest` | suggest fixes | 0 | [`15-suggest.*`](./smells.probes/) |
| P16 | `tldr smells ... --deep` | deep analysis | 0 | [`16-deep.*`](./smells.probes/) |
| P17 | `tldr smells ... --deep -s low-cohesion` | deep + smell-type | 0 | [`17-deep-low-cohesion.*`](./smells.probes/) |
| P18 | `tldr smells ... --no-default-ignore` | walk vendored | 0 | [`18-no-default-ignore.*`](./smells.probes/) |
| P19 | `tldr smells backend --files backend/providers/yahoo.py` | **--files DOUBLED PATH BUG** | 1 | [`19-files-specific.*`](./smells.probes/) |
| P20 | `tldr smells backend --files ../../../../etc/passwd` | traversal rejected | 1 | [`20-files-traversal.*`](./smells.probes/) |
| P21 | `tldr smells backend --include-tests` | include-tests | 0 | [`21-include-tests.*`](./smells.probes/) |
| P22 | `tldr smells ... -l brainfuck` | bad-lang | 2 | [`22-bad-lang.*`](./smells.probes/) |
| P23 | `tldr smells ... -l python` | lang-python explicit | 0 | [`23-lang-python.*`](./smells.probes/) |
| P24 | `tldr smells <empty-tmp-dir>` | empty-dir | 0 | [`24-empty-dir.*`](./smells.probes/) |
| P25 | `tldr smells README.md` | non-source-md (silent empty) | 0 | [`25-non-source-md.*`](./smells.probes/) |
| P26 | `tldr smells ... -q` | quiet (warning suppressed) | 0 | [`26-quiet.*`](./smells.probes/) |
| P27 | `tldr smells backend/providers` *(cold daemon)* | cold-daemon | 0 | [`27-cold-daemon.*`](./smells.probes/) |
| P28 | `tldr smells backend/providers` *(warm daemon)* | warm-daemon | 0 | [`28-warm-daemon.*`](./smells.probes/) |

### Observations

- **P01** — `backend/providers/`: 7 smells detected (`lazy_element` × 4 for Provider base classes, `long_method` × 3 for fetch_* methods). `warnings: [...]` injected per BUG-18 fix. `total_smells: 7, avg_smells_per_file: 1.75`.
- **P02** — Full `backend/`: 7506 lines (severely truncated by 500-line cap). Many more smells detected on full repo.
- **P03** — **N/A.** PATH defaults to `.`.
- **P04** — stderr `"Error: Path not found: /no/such/dir"`, exit `1` (anyhow!). Matches `tldr churn`/`tldr debt`/`tldr hotspots`. Source comment confirms BUG-11 fix: pre-fix, missing path returned exit 0 with empty result — silently passed through.
- **P05** — stderr `"Error: --format sarif not supported by smells. ..."`, exit `1`.
- **P06** — Text format: human-readable smell report.
- **P07** — Single-line minified JSON.
- **P08** — stderr `"Error: --format dot not supported by smells. ..."`, exit `1`.
- **P09** — `--threshold strict`: 316 lines — more smells caught (lower thresholds).
- **P10** — `--threshold relaxed`: 86 lines — fewer smells (higher thresholds).
- **P11** — clap-style with full list: `"error: invalid value 'wat' for '--threshold <THRESHOLD>' [possible values: strict, default, relaxed]"`, exit `2`.
- **P12** — `--smell-type god-class`: empty result (no god classes in providers/). 14 lines. Filter ALSO suppresses the deep-only warning.
- **P13** — **Best-in-class error:** clap-style with ALL 18 valid smell types listed: `"[possible values: god-class, long-method, long-parameter-list, feature-envy, data-clumps, low-cohesion, tight-coupling, dead-code, code-clone, high-cognitive-complexity, deep-nesting, data-class, lazy-element, message-chain, primitive-obsession, middle-man, refused-bequest, inappropriate-intimacy]"`, exit `2`.
- **P14** — `--smell-type low-cohesion` WITHOUT `--deep`: empty result (low-cohesion requires --deep). NO warning that --deep is needed. **Silent feature gap** — user gets empty when they should be told to pass --deep.
- **P15** — `--suggest`: 153 lines — each smell gains a suggestion field (likely `suggestion: "<refactor hint>"`).
- **P16** — `--deep`: 993 lines (truncated). Runs cohesion + coupling + dead-code + similarity + cognitive-complexity analyzers. Most comprehensive output.
- **P17** — `--deep -s low-cohesion`: 72 lines, filters to only low-cohesion findings (which require deep). Shows ~5 low-cohesion findings.
- **P18** — `--no-default-ignore`: same line count — no vendored dirs in backend/providers/.
- **P19** — **`--files` PATH-DOUBLING BUG:** `tldr smells backend --files backend/providers/yahoo.py` → `"Error: --files backend/providers/yahoo.py: Path not found: /Users/.../backend/backend/providers/yahoo.py"`. The `--files` path is resolved RELATIVE to PATH (the project_root). User-supplied relative paths starting with `backend/...` get prefixed with PATH again. **UX pitfall** — use absolute paths or paths relative to PATH for `--files`.
- **P20** — `--files ../../../../etc/passwd`: stderr `"Error: --files ../../../../etc/passwd: Path not found: /Users/.../backend/../../../../etc/passwd"`, exit `1`. Traversal not explicitly rejected by name; instead the resolved path doesn't exist or fails validation. Either way, traversal blocked.
- **P21** — `--include-tests`: 7506 lines (same as P02 — no test files in this scope, but flag is honored).
- **P22** — clap-style: `"error: invalid value 'brainfuck' for '--lang <LANG>': Unknown language: brainfuck"`, exit `2`.
- **P23** — Explicit `-l python`: identical to default.
- **P24** — Empty dir: same empty shape as P12/P14. `files_scanned: 0` (NOT 4).
- **P25** — README.md: empty-result shape, exit 0. `files_scanned: 0`. NO warning/error for non-source. Same silent-empty as `tldr secure`.
- **P26** — `-q quiet`: `warnings: []` (the deep-only advisory is SUPPRESSED). Confirms the BUG-18 conditional: `(!self.deep && !quiet && self.smell_type.is_none())`.
- **P27 / P28** — Cold (P27) and warm (P28) daemon: both 139 lines, identical output. Daemon route via `try_daemon_route` caches the smells report. Daemon properly serves cached results.

---

## Source Code Reality

**Target file(s):**
- `crates/tldr-cli/src/commands/smells.rs` (~280+ lines)
- `crates/tldr-core/src/quality/smells.rs` (analyzer registry, threshold presets)
- `crates/tldr-cli/src/commands/daemon_router.rs` (`params_for_smells`)
- `crates/tldr-cli/src/output.rs:113` (`validate_format_for_command`)

**Pinned to upstream commit:** `6c4011a` (release v0.4.0)

**Argument struct:** PATH defaults to `.`. Two enum-typed flags (`-t threshold`, `-s smell-type`) — both have clap value_parser; bogus values produce best-in-class error with full valid-values list inline.

**BUG-11 path validation:**
```rust
// smells.rs:159-166
// BUG-11: validate path exists BEFORE any analysis. Without this
// check, a missing path silently slipped through: `is_dir()` returned
// false, the file branch ran with no files to scan, and the command
// returned exit 0 with empty results. Now: missing path => exit 1
// (matches `health`, `structure`, `deps`, `vuln`).
if !self.path.exists() {
    anyhow::bail!("Path not found: {}", self.path.display());
}
```
Source comment cites the fix — pre-fix `tldr smells /no/such/path` returned exit 0 (matching the silent-empty pattern of `tldr inheritance` P04). The fix aligns with `tldr health`/`tldr structure`/`tldr deps`/`tldr vuln`.

**BUG-18 stderr-hygiene fix:**
```rust
// smells.rs:219-243
// determinism-and-stderr-hygiene-v1 (BUG-18): the M14
// (med-cleanup-bundle-v1) deep-only-smells hint used to be
// unconditionally written to stderr via `eprintln!`, which
// broke the JSON-mode contract (`tldr smells <path> 2>err >
// out.json` always produced a non-empty stderr stream).
//
// Relocate the same advisory into `SmellsReport.warnings` so
// BOTH JSON consumers (introspectable via `report.warnings[]`)
// AND text consumers (rendered to stdout by the text
// formatter — see `format_smells_text`) still see it.
let deep_only_warning: Option<String> =
    (!self.deep && !quiet && self.smell_type.is_none()).then(|| {
        const DEEP_ONLY_SMELLS: &[&str] = &[
            "low_cohesion", "tight_coupling", "dead_code", "code_clone",
            "high_cognitive_complexity", "middle_man", "refused_bequest",
            "inappropriate_intimacy",
        ];
        format!(/* hint string */)
    });
```
Reveals: 8 deep-only smells listed in source. Warning is suppressed in three conditions: `--deep` (the analyzers ARE running), `--quiet` (user opted out), `--smell-type` (warning would be misleading).

**`--files` validation (v0.2.3 #1.D):**
```rust
// smells.rs:193-200
let canonical =
    tldr_core::validation::validate_file_path(f_str, Some(&project_root))
        .map_err(|e| anyhow::anyhow!("--files {}: {}", f.display(), e))?;
```
Reveals: `--files` entries go through `tldr_core::validation::validate_file_path` (M28 shared validator) with `project_root` as anchor. This causes P19's path-doubling: if PATH is `backend` and `--files backend/providers/yahoo.py`, the validator resolves `--files` relative to `project_root=<canonical backend>`, producing `backend/backend/providers/yahoo.py`. **Path-traversal attempts (P20) produce hard errors, NOT silent skip** (cited in source comment).

**Daemon route:** present via `try_daemon_route::<SmellsReport>` at smells.rs:203. Cold/warm parity verified (P27/P28 identical).

**Format validation:** confirmed at `crates/tldr-cli/src/output.rs:113-163` — `smells` is in neither `SARIF_SUPPORTED` nor `DOT_SUPPORTED`.

---

## Architectural Deep Dive

- **Under the hood:** AST-based smell detection. Default mode runs 10 fast detectors (god class, long method, long parameter list, feature envy, data clumps, deep nesting, data class, lazy element, message chain, primitive obsession). `--deep` mode adds 8 more analyzers that delegate to other tldr commands: cohesion, coupling, dead-code, similarity, cognitive-complexity, middle-man, refused-bequest, inappropriate-intimacy.
- **Performance:** Cold ~150-300ms per 4-file dir; `--deep` adds 1-3s. Daemon route caches results (~10x faster on warm).
- **LLM cognitive load:** Best general-purpose anti-pattern detector. The `severity` field (1-3) allows ranking. `--suggest` adds refactor hints — feed directly to LLM with the source location. Pair with `tldr patterns` (extracts CONVENTIONS) for full code-style audit.

---

## Intent & Routing

- **User/Agent Goal:** find anti-patterns and code smells across a codebase — God classes, Long methods, Data clumps, etc.
- **When to choose this over similar tools:**
  - Over `tldr patterns`: patterns extracts CONVENTIONS (what the code does); smells finds ANTI-patterns (what it shouldn't do).
  - Over individual commands (`tldr cohesion`, `tldr coupling`, `tldr dead`, etc.): smells `--deep` aggregates them all.
  - Over external lint tools: tree-sitter based, no language-server required.
- **Prerequisites (composition):**
  - Use `--deep` to run all 18 detectors (otherwise 8 require --deep).
  - For specific smell-type focus, use `-s <kebab-case-type>` — but check the `--help` for which require `--deep`.
  - For LLM workflows, add `--suggest` to get refactor hints per smell.

---

## Agent Synthesis

> **How to use `tldr smells`:**
> Anti-pattern / code-smell detector. `tldr smells [PATH]` returns JSON `{ smells, files_scanned, by_file, summary, excluded_test_smells, warnings, total_smells, avg_smells_per_file }`. Each `Smell` has `{ smell_type (snake_case), file (ABSOLUTE path), name, line, reason, severity }`. Default detects 10 smells; `--deep` adds 8 more (cohesion, coupling, dead-code, similarity, cognitive, middle-man, refused-bequest, inappropriate-intimacy). 3 threshold presets (`-t strict|default|relaxed`). Filter to one type via `-s <kebab-case>`. Add `--suggest` for refactor hints. Default JSON; `-f text` for report; `-f compact` for one-line; `sarif`/`dot` rejected. Exit codes: 0 ok (including silent empties), 1 path-not-found / format-reject / bad --files, 2 bad-threshold / bad-smell-type / bad-lang.
>
> **Crucial Rules:**
> - **`--smell-type <X>` requiring `--deep` returns SILENT EMPTY without `--deep`.** P14: `tldr smells <path> -s low-cohesion` (no --deep) returns `smells: [], warnings: []`, exit 0. No error or warning that --deep is required. **Silent feature gap** — read --help to know which 8 smell types need `--deep`: `low-cohesion, tight-coupling, dead-code, code-clone, high-cognitive-complexity, middle-man, refused-bequest, inappropriate-intimacy`.
> - **`smell_type` values are SNAKE_CASE in output, NOT kebab-case** like the `--smell-type` flag. E.g., flag `--smell-type long-method` → JSON `smell_type: "long_method"`. Cross-format inconsistency between input and output.
> - **`file` field in `Smell` is ABSOLUTE PATH**, not project-relative. P01: `"/Users/udhayakumar/Workspace/17-Roshan-Projects/Stock-Monitor/backend/providers/base.py"`. Strip prefix manually for portable output. Distinct from many other commands which use project-relative.
> - **`by_file` is a KEYED OBJECT, keyed by absolute file path.** Same convention as `tldr loc`'s `by_language`. Iterate via `Object.entries()`.
> - **`warnings[]` contains the deep-only advisory** when ALL of: `!--deep`, `!-q`, `!--smell-type`. P26: `-q` suppresses to `warnings: []`. Source: BUG-18 / determinism-and-stderr-hygiene-v1 fix relocated the advisory from stderr to `warnings[]` to keep JSON stdout/stderr clean.
> - **`--files <relative-path>` is resolved RELATIVE to PATH.** P19 bug-trap: `tldr smells backend --files backend/providers/yahoo.py` produces "Path not found: /.../backend/backend/providers/yahoo.py" (path-doubled). Use either absolute paths OR paths relative to the PATH argument (not project root). Path-traversal attempts are blocked (P20).
> - **Path-not-found exit code is 1** (anyhow! — matches `tldr churn`/`tldr debt`/`tldr hotspots`). Source comment cites BUG-11: pre-fix this was silent exit 0.
> - **Bad-smell-type error lists all 18 valid types inline.** Best-in-class CLI error for discoverability.
> - **`severity` is INTEGER 1-3 (observed 1).** Not the string `"low"`/`"medium"`/`"high"` pattern used elsewhere. Cross-command inconsistency.
> - **DAEMON ROUTE present.** Cold and warm calls return byte-identical output (P27/P28 verified).
>
> **Command:** `tldr smells [PATH]`
>
> **With common flags:** `tldr smells <PATH> --deep --suggest -t strict -f compact | jq '.smells | sort_by(-.severity) | .[:10]'` (use for top-10 highest-severity smells with refactor suggestions, deep analysis enabled).
