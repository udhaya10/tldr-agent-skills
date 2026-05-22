# Command: `tldr cohesion`

## Environment Pin

| Field | Value |
|---|---|
| `tldr --version` | 0.4.0 |
| Build features | `semantic` (verified; cohesion itself is AST-based, non-semantic) |
| Target repo | Stock-Monitor @ commit `e601869` |
| Upstream `tldr-code` pinned to | local clone @ `6c4011a` (release v0.4.0) |
| Daemon state at probe time | N/A — `tldr cohesion` does **not** call `try_daemon_route` (verified by grep) |
| OS | darwin 25.2.0 |
| Probe date | 2026-05-22 |

Re-run all evidence via [`cohesion.probes/probe.sh`](./cohesion.probes/probe.sh).
See also: [agent-oriented tool card](../../tool-cards/audit/cohesion.md).

---

## Ground Truth (`tldr cohesion --help`)

```text
Analyze class cohesion using LCOM4 metric

Usage: tldr cohesion [OPTIONS] <PATH>

Arguments:
  <PATH>
          File or directory to analyze

Options:
      --min-methods <MIN_METHODS>
          Minimum number of instance methods for a class to be included in analysis. Classes with fewer methods are filtered from results. For Rust and Go, only instance methods (with self/receiver) are counted, not associated functions like new() or default()

          [default: 1]

      --include-dunder
          Include dunder methods (__init__, __str__, etc.) in analysis

      --timeout <TIMEOUT>
          Analysis timeout in seconds

          [default: 30]

      --project-root <PROJECT_ROOT>
          Project root for path validation (optional)

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
| Formats that work | `json`, `text`, `compact` (P01, P06, P07 — but compact == json, NOT minified) |
| Formats that error | `sarif`, `dot` (P05, P08: exit 1) |
| Typical output size | small (~20 lines for one class) to medium (~150 lines for several classes with split-candidate detail) |

**Top-level keys (JSON, `CohesionReport`):**
- `classes` (`array<ClassCohesion>`) — one entry per analyzed class
- `summary` (`object`) — `{ total_classes, cohesive, split_candidates, avg_lcom4 }`

**`ClassCohesion` shape:**
- `class_name` (`string`)
- `file_path` (`string`) — **path shape depends on PATH input** — relative for single-file PATH, ABSOLUTE for directory PATH (see Crucial Rules)
- `line` (`u32`) — class definition line
- `lcom4` (`u32`) — Lack of Cohesion of Methods (LCOM4). `lcom4 = 1` → cohesive; `lcom4 > 1` → split candidate
- `method_count` (`u32`), `field_count` (`u32`)
- `verdict` (`string`) — `"cohesive"` or `"split_candidate"`
- `split_suggestion` (`string` | `null`) — when split_candidate: text like `"Consider splitting X into N classes: [methodA] + [methodB] + ..."`
- `components` (`array<ComponentInfo>`) — connected components in the method-field graph; each `{ methods: [string], fields: [string] }`

**Empty-result shape (P17/P18/P19) — IDENTICAL for empty-dir, non-python file, and python file with no classes:**
```json
{
  "classes": [],
  "summary": { "total_classes": 0, "cohesive": 0, "split_candidates": 0, "avg_lcom4": 0.0 }
}
```
Exit 0. NO `warnings` field (unlike `tldr cognitive --lang typescript` which adds one).

**Error shapes:**
- Missing PATH: clap-style → exit **2** (PATH is REQUIRED, no default)
- Bad path: `"Error: file not found: /no/such/dir"` → exit **1** (anyhow; lowercase "file")
- Format reject: `"Error: --format sarif not supported by cohesion. ..."` → exit **1**
- Bad `--lang`: clap-style → exit **2**

---

## Probe Matrix

| # | Probe | Type | Exit | Captured |
|---|-------|------|------|----------|
| P01 | `tldr cohesion backend/providers/base.py` | happy (single file, relative path) | 0 | [`01-happy.*`](./cohesion.probes/) |
| P02 | `tldr cohesion backend/providers` | happy-scale (directory, ABS paths) | 0 | [`02-happy-scale.*`](./cohesion.probes/) |
| P03 | `tldr cohesion` *(no PATH)* | failure-missing-input | 2 | [`03-missing-arg.*`](./cohesion.probes/) |
| P04 | `tldr cohesion /no/such/dir` | failure-badpath | 1 | [`04-badpath.*`](./cohesion.probes/) |
| P05 | `tldr cohesion ... -f sarif` | format-reject (sarif) | 1 | [`05-format-reject-sarif.*`](./cohesion.probes/) |
| P06 | `tldr cohesion ... -f text` | format-text | 0 | [`06-format-text.*`](./cohesion.probes/) |
| P07 | `tldr cohesion ... -f compact` | format-compact (== json pretty) | 0 | [`07-format-compact.*`](./cohesion.probes/) |
| P08 | `tldr cohesion ... -f dot` | format-reject (dot) | 1 | [`08-format-reject-dot.*`](./cohesion.probes/) |
| P09 | `tldr cohesion ... --min-methods 10` | high-min-methods (filters out) | 0 | [`09-min-methods-high.*`](./cohesion.probes/) |
| P10 | `tldr cohesion ... --min-methods 0` | zero-min-methods (include all) | 0 | [`10-min-methods-zero.*`](./cohesion.probes/) |
| P11 | `tldr cohesion ... --include-dunder` | include-dunders | 0 | [`11-include-dunder.*`](./cohesion.probes/) |
| P12 | `tldr cohesion backend --timeout 1` | very-short timeout | 0 | [`12-timeout-short.*`](./cohesion.probes/) |
| P13 | `tldr cohesion ... --project-root backend` | project-root flag | 0 | [`13-project-root.*`](./cohesion.probes/) |
| P14 | `tldr cohesion ... -l brainfuck` | bad-lang | 2 | [`14-bad-lang.*`](./cohesion.probes/) |
| P15 | `tldr cohesion ... -l typescript` | lang-mismatch IGNORED | 0 | [`15-lang-mismatch.*`](./cohesion.probes/) |
| P16 | `tldr cohesion ... -q` | quiet | 0 | [`16-quiet.*`](./cohesion.probes/) |
| P17 | `tldr cohesion <empty-tmp-dir>` | empty-dir | 0 | [`17-empty-dir.*`](./cohesion.probes/) |
| P18 | `tldr cohesion README.md` | non-python file | 0 | [`18-non-python-md.*`](./cohesion.probes/) |
| P19 | `tldr cohesion backend/db.py` | python file with no classes | 0 | [`19-no-classes.*`](./cohesion.probes/) |

### Observations

- **P01** — `base.py`: 1 class (`Provider`), `lcom4: 0`, `method_count: 0` (abstract methods are filtered out by the engine — the class has only `@abstractmethod` declarations, not concrete methods). Verdict: `"cohesive"`. **`file_path` is RELATIVE** (`"backend/providers/base.py"`).
- **P02** — `backend/providers/` (directory): 3 classes found (`DhanProvider`, `YahooProvider`, `Provider`). `DhanProvider` has lcom4=3, 7 methods, 2 fields → "split_candidate". `YahooProvider` has lcom4=5 → also split candidate. **`file_path` is ABSOLUTE** (`"/Users/udhayakumar/.../backend/providers/dhan.py"`) — schema inconsistency from P01.
- **P03** — stderr `"error: the following required arguments were not provided: <PATH>"`, exit `2`. **PATH is required (no default)** — distinct from most audit commands which default to `.`.
- **P04** — stderr `"Error: file not found: /no/such/dir"`, exit `1`. Lowercase "file" — matches `tldr chop`/`tldr dead-stores`; differs from `tldr cognitive` ("Path does not exist:") and `tldr churn` ("Path not found:").
- **P05** — stderr `"Error: --format sarif not supported by cohesion. ..."`, exit `1`.
- **P06** — Text format: nice tree-rendered output with `Component 1: ...`, `Component 2: ...`, then `Suggestion: Consider splitting X into N classes: ...`. Includes a summary footer `"Summary: 3 classes, 2 split candidates (66.7%), avg LCOM4: 2.67"`.
- **P07** — **`-f compact` is IDENTICAL to JSON pretty (NOT minified).** Same source-comment drift as `tldr reaching-defs` — the CLI doesn't use a dedicated compact formatter. 100 lines (same as P02).
- **P08** — stderr `"Error: --format dot not supported by cohesion. ..."`, exit `1`.
- **P09** — `--min-methods 10`: very few/no classes meet the threshold; 9-line stub output.
- **P10** — `--min-methods 0`: includes ALL classes including those with 0 instance methods. 144 lines.
- **P11** — `--include-dunder`: includes `__init__`, `__str__`, etc. in the analysis. Output is larger (118 lines) because more methods are counted, affecting lcom4 values.
- **P12** — `--timeout 1` (1 second) on full backend: 347 lines produced — analysis completed under 1s on this small repo. **No timeout exceeded.** On larger codebases, the engine would terminate gracefully (a warning would be added; not observed here).
- **P13** — `--project-root backend`: same output as P01 (in this scope). The flag is for "path validation" — likely used when relative paths in input must be resolved against an explicit project root.
- **P14** — clap-style: `"error: invalid value 'brainfuck' for '--lang <LANG>': Unknown language: brainfuck"`, exit `2`.
- **P15** — **`-l typescript` is IGNORED.** Output identical to P02 (3 Python classes found). The `--lang` flag exists in the CLI struct but **cohesion is Python-only** (per source docstring at `cohesion.rs:1` "LCOM4 analysis for Python classes"). The engine walks the directory and processes ALL Python files regardless of `--lang`.
- **P16** — `-q` quiet — no progress messages to suppress in this command (no `writer.progress()` call), so output identical to non-quiet.
- **P17** — Empty dir: `{ classes: [], summary: { all zeros } }`. NO `warnings` field. **Indistinguishable from P18 (non-python) and P19 (no-classes).**
- **P18** — `README.md` (non-Python file): IDENTICAL empty shape to P17. **Silent — no "this is not a Python file" warning.**
- **P19** — `backend/db.py` (Python file with functions but no classes): IDENTICAL empty shape to P17/P18. **Three failure modes return the same shape.** Agents cannot distinguish "wrong file type" from "no classes" from "empty dir" without external context.

---

## Source Code Reality

**Target file(s):**
- `crates/tldr-cli/src/commands/patterns/cohesion.rs` (1543 lines — large because it includes the union-find algorithm and tree-sitter AST walker)
- `crates/tldr-core/src/quality/cohesion.rs` (core LCOM4 logic)
- `crates/tldr-cli/src/commands/patterns/validation.rs` (path validators, limits)
- `crates/tldr-cli/src/output.rs:113` (`validate_format_for_command`)

**Pinned to upstream commit:** `6c4011a` (release v0.4.0)

**Argument struct:**
```rust
// crates/tldr-cli/src/commands/patterns/cohesion.rs (approx)
pub struct CohesionArgs {
    pub path: PathBuf,                  // REQUIRED — no default
    pub min_methods: u32,
    pub include_dunder: bool,
    pub output_format: OutputFormat,
    pub timeout: u64,
    pub project_root: Option<PathBuf>,
    pub lang: Option<Language>,
}
```
Reveals: PATH is a required positional (clap exit 2 on missing). Note `output_format` is a SECOND format flag (the command's own enum: Json | Text) separate from the global `-f/--format`. The global format takes precedence; the local form is legacy.

**Python-only (despite `--lang` flag):**
The source docstring (`cohesion.rs:1`) says: *"LCOM4 (Lack of Cohesion of Methods) analysis for Python classes."* The `parse_python` function uses `tree_sitter_python::LANGUAGE` hardcoded. **The `--lang` flag is parsed by clap for global consistency but the engine ignores it.** P15 confirms.

**Hard limits (TIGER/ELEPHANT mitigations):**
```rust
const MAX_UNION_FIND_ITERATIONS: usize = 10_000;
const DEFAULT_TIMEOUT_SECS: u64 = 30;
// + MAX_METHODS_PER_CLASS, MAX_FIELDS_PER_CLASS, MAX_CLASSES_PER_FILE,
//   MAX_DIRECTORY_FILES (from validation.rs)
```
Reveals: prevents runaway analysis. Classes with > MAX_METHODS_PER_CLASS or > MAX_FIELDS_PER_CLASS are skipped; directories with > MAX_DIRECTORY_FILES are truncated.

**file_path schema inconsistency (P01 vs P02):**
The single-file branch (`analyze_single_file`) keeps the user-supplied `self.path`, while the directory branch (`analyze_directory` via `walk_project`) emits canonical (absolute) paths from `walkdir`. This is a known inconsistency — agents must normalize before comparing paths across reports from different invocation modes.

**Format validation:** confirmed at `crates/tldr-cli/src/output.rs:113-163` — `cohesion` is in neither `SARIF_SUPPORTED` nor `DOT_SUPPORTED`.

**No daemon route:** `grep -n try_daemon_route patterns/cohesion.rs` returns 0 matches. Every call walks + parses + builds union-find from scratch.

---

## Architectural Deep Dive

- **Under the hood:** Build a bipartite graph of `methods <-> fields` (where field = `self.x` access) plus method-to-method edges (intra-class `self.method()` calls). Run union-find with path compression to count connected components. `lcom4 = number of connected components`. A class with `lcom4 > 1` has methods that don't share fields with each other — candidates for splitting.
- **Performance:** O(M × F) for the graph build (M methods, F fields per class) + union-find amortized O(α(N)) per operation. 30s default timeout via `--timeout`. Limits at `MAX_METHODS_PER_CLASS`, `MAX_FIELDS_PER_CLASS`, `MAX_DIRECTORY_FILES` prevent pathological cases.
- **LLM cognitive load:** "Should I split this class?" — LCOM4 > 1 with a `split_suggestion` containing the actual method groupings is one of the most actionable refactor signals in the audit suite. Agents proposing refactors can directly use `components[].methods` as the split groups.

---

## Intent & Routing

- **User/Agent Goal:** identify Python classes where methods don't share state — candidates for splitting into smaller, more cohesive classes (Single Responsibility Principle).
- **When to choose this over similar tools:**
  - Over `tldr coupling`: `coupling` measures inter-class dependencies; `cohesion` measures intra-class connectedness. Both are needed for the classic "high cohesion, low coupling" ideal.
  - Over `tldr complexity` / `tldr cognitive`: those measure per-function/per-file complexity; `cohesion` measures per-class structure.
  - Over manual review: `split_suggestion` gives the EXACT method groupings, not just a "this class is bad" verdict.
- **Prerequisites (composition):**
  - Python-only. Other-language projects will return 0 classes (P15 / P18).
  - `--min-methods` defaults to 1, which excludes interface-only abstract classes (P01: Provider had 0 instance methods).
  - To investigate dunder method contribution, use `--include-dunder` (P11).

---

## Agent Synthesis

> **How to use `tldr cohesion`:**
> Python-class LCOM4 (Lack of Cohesion of Methods) analyzer. `tldr cohesion <PATH>` returns JSON `{ classes, summary }`. Each `ClassCohesion` has `lcom4` (1 = cohesive, >1 = split candidate), `method_count`, `field_count`, `verdict`, and — when verdict is `"split_candidate"` — a `split_suggestion` string AND `components[]` array with the exact method/field groupings. Default JSON; `-f text` for tree-rendered output; `-f compact` is IDENTICAL to JSON pretty (NOT minified); sarif/dot rejected. Exit codes: 0 ok (including silent empties), 1 file-not-found / format-reject, 2 missing PATH / bad --lang.
>
> **Crucial Rules:**
> - **PATH is REQUIRED — no default.** Unlike most audit commands which default to `.`, `tldr cohesion <PATH>` mandates an explicit path. Missing PATH → clap exit 2 (P03).
> - **`tldr cohesion` is Python-only despite the `--lang` flag.** The engine hardcodes `tree_sitter_python::LANGUAGE` (cohesion.rs:1 docstring confirms "for Python classes"). `--lang typescript` returns Python results anyway (P15). Bad `--lang` values still reject (clap exit 2), but valid non-Python values are IGNORED.
> - **`file_path` schema differs between single-file and directory modes.** Single-file PATH → relative path (`"backend/providers/base.py"`). Directory PATH → ABSOLUTE path (`"/Users/.../backend/providers/dhan.py"`). Normalize before cross-mode comparison (P01 vs P02).
> - **THREE failure modes return the IDENTICAL empty shape:** empty dir (P17), non-Python file (P18), Python file with no classes (P19). No `warnings` field is added (unlike `tldr cognitive`). Agents cannot distinguish them from output alone.
> - **`-f compact` is NOT minified.** Same source-comment-drift pattern as `tldr reaching-defs`: the CLI uses the pretty formatter for both `Json` and `Compact`. Pipe through `jq -c .` for true one-line output.
> - **`split_suggestion` and `components[]` are the actionable refactor outputs.** When `verdict == "split_candidate"`, the engine pre-computes the EXACT method groupings: `components[].methods` lists method names per cohesion island. Use directly as refactor input.
> - **Default `--min-methods: 1` excludes ALL-abstract classes** (P01: `Provider` had `method_count: 0` because only `@abstractmethod` decls — they're filtered as not-instance-methods). For interface analysis, use `--min-methods 0`.
> - **Hard limits prevent runaway analysis** (`MAX_METHODS_PER_CLASS`, `MAX_FIELDS_PER_CLASS`, `MAX_DIRECTORY_FILES`, `MAX_UNION_FIND_ITERATIONS = 10000`). Pathological inputs are silently truncated.
> - **NO daemon route.** Every call re-parses and re-runs union-find. `tldr warm` is a no-op.
>
> **Command:** `tldr cohesion <PATH>`
>
> **With common flags:** `tldr cohesion <PATH> --min-methods 3 --include-dunder -f text` (use to surface meaningful split candidates only — classes with ≥3 methods including dunders, in human-readable form with split suggestions).
