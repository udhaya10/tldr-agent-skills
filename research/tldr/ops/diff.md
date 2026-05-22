# Command: `tldr diff`

## Environment Pin

| Field | Value |
|---|---|
| `tldr --version` | 0.4.0 |
| Build features | `semantic` (verified; diff is AST-based, non-semantic) |
| Target repo | Stock-Monitor @ commit `e601869` |
| Upstream `tldr-code` pinned to | local clone @ `6c4011a` (release v0.4.0) |
| Daemon state at probe time | N/A — `tldr diff` does **not** call `try_daemon_route` (verified by grep) |
| OS | darwin 25.2.0 |
| Probe date | 2026-05-22 |

Re-run all evidence via [`diff.probes/probe.sh`](./diff.probes/probe.sh).
See also: [agent-oriented tool card](../../tool-cards/ops/diff.md).

---

## Ground Truth (`tldr diff --help`)

```text
AST-aware structural diff between two files

Usage: tldr diff [OPTIONS] <FILE_A> <FILE_B>

Arguments:
  <FILE_A>                                     First file (or dir for L6/L7/L8)
  <FILE_B>                                     Second file (or dir for L6/L7/L8)

Options:
  -g, --granularity <GRANULARITY>              [token|expression|statement|function|class|file|module|architecture]
                                               [default: function]
      --semantic-only                          Exclude formatting-only changes
  -O, --output <OUTPUT>                        Output file
  -f, --format <FORMAT>                        [default: json]
  -l, --lang <LANG>
  -q, --quiet  -v, --verbose  -h, --help
```

**Granularity levels (L1–L8):**
- L1 `token` — token-level diff
- L2 `expression` — expression-level
- L3 `statement` — statement-level
- L4 `function` (default) — function-level
- L5 `class` — class-level
- L6 `file` — file-level (REQUIRES directories as FILE_A/B)
- L7 `module` — module-level (with import graph)
- L8 `architecture` — architecture-level (with arch metrics)

---

## Output Shape

| Aspect | Value |
|---|---|
| Default format | `json` |
| Formats that work | `json`, `text` (P01, P06) |
| Format **bug** | **`-f compact` returns pretty JSON byte-identical to default** (P07: 17524 bytes both) |
| Formats that error | `sarif`, `dot` (P05, P08: exit 1) |
| Typical output size | small (~30 lines text, ~180 lines JSON for two-file diff); HUGE for token-level (~17,700 lines) |

**TOP-LEVEL SCHEMA DIVERGES by granularity:**

### L1-L5 (token, expression, statement, function, class):
```json
{
  "file_a": "<path>", "file_b": "<path>", "identical": <bool>,
  "changes": [{ "change_type", "node_kind", "name", "old_location"?, "new_location"? }, ...],
  "summary": { "total_changes", "semantic_changes", "inserts", "deletes", "updates", "moves", "renames", "formats", "extracts" },
  "granularity": "<level>"
}
```

### L6 (file):
Adds `"file_changes": []`.

### L7 (module):
Adds `"module_changes": []` and `"import_graph_summary": { "total_edges_a", "total_edges_b", "edges_added", "edges_removed", "modules_with_import_changes" }`.

### L8 (architecture):
Adds `"arch_changes": []` and `"arch_summary": { "layer_migrations", "directories_added", "directories_removed", "cycles_introduced", "cycles_resolved", "stability_score" }`.

**`Change` shape** (L1-L5): `{ change_type, node_kind, name, old_location?, new_location? }`. Observed `change_type` values: `"delete"`, `"insert"`, `"update"`, plus per `summary` keys also `"move"`, `"rename"`, `"format"`, `"extract"`. Observed `node_kind`: `"function"`, `"class"`.

**Identical-files shape (P19):**
```json
{
  "file_a": "<same>", "file_b": "<same>", "identical": true, "changes": [],
  "summary": { /* all zeros */ }, "granularity": "function"
}
```
Exit 0.

**Error shapes:**
- Missing FILE_B: clap-style → exit **2**
- File not found: `"Error: file not found: /no/such/a.py"` → exit **5** (RemainingError::FileNotFound — matches `tldr secure`/`tldr vuln`/`tldr dead-stores`)
- Bad `--granularity`: clap-style with FULL 8-value list inline → exit **2** (best-in-class discoverability)
- Bad `--lang`: clap-style → exit **2**
- Dir-vs-file (e.g., L4 function on dir): `"Error: parse error in <path>: Unsupported language: .unknown"` → exit **1**
- Format reject sarif: `"Error: --format sarif not supported by diff. ..."` → exit **1**

---

## Probe Matrix

| # | Probe | Type | Exit | Captured |
|---|-------|------|------|----------|
| P01 | `tldr diff yahoo.py dhan.py` | happy (function L4 default) | 0 | [`01-happy.*`](./diff.probes/) |
| P02 | `tldr diff backend/providers backend -g file` | happy-scale (L6) | 0 | [`02-happy-scale.*`](./diff.probes/) |
| P03 | `tldr diff yahoo.py` *(no FILE_B)* | failure-missing-input | 2 | [`03-missing-arg.*`](./diff.probes/) |
| P04 | `tldr diff /no/such/a.py <file>` | bad-file_a | 5 | [`04-badpath.*`](./diff.probes/) |
| P05 | `tldr diff ... -f sarif` | format-reject (sarif) | 1 | [`05-format-reject-sarif.*`](./diff.probes/) |
| P06 | `tldr diff ... -f text` | format-text | 0 | [`06-format-text.*`](./diff.probes/) |
| P07 | `tldr diff ... -f compact` | **format-compact BROKEN** | 0 | [`07-format-compact.*`](./diff.probes/) |
| P08 | `tldr diff ... -f dot` | format-reject (dot) | 1 | [`08-format-reject-dot.*`](./diff.probes/) |
| P09 | `tldr diff ... -g token` | L1 token (HUGE output) | 0 | [`09-granularity-token.*`](./diff.probes/) |
| P10 | `tldr diff ... -g expression` | L2 expression | 0 | [`10-granularity-expression.*`](./diff.probes/) |
| P11 | `tldr diff ... -g statement` | L3 statement | 0 | [`11-granularity-statement.*`](./diff.probes/) |
| P12 | `tldr diff ... -g class` | L5 class | 0 | [`12-granularity-class.*`](./diff.probes/) |
| P13 | `tldr diff <dir> <dir> -g file` | L6 file (dir mode) | 0 | [`13-granularity-file.*`](./diff.probes/) |
| P14 | `tldr diff <dir> <dir> -g module` | L7 module (import graph!) | 0 | [`14-granularity-module.*`](./diff.probes/) |
| P15 | `tldr diff <dir> <dir> -g architecture` | L8 architecture (arch metrics!) | 0 | [`15-granularity-arch.*`](./diff.probes/) |
| P16 | `tldr diff ... -g wat` | bad granularity (full list shown) | 2 | [`16-granularity-bogus.*`](./diff.probes/) |
| P17 | `tldr diff ... --semantic-only` | semantic-only | 0 | [`17-semantic-only.*`](./diff.probes/) |
| P18 | `tldr diff ... -O <tmp>` | output to file | 0 | [`18-output-file.*`](./diff.probes/) |
| P19 | `tldr diff <same> <same>` | identical files | 0 | [`19-identical.*`](./diff.probes/) |
| P20 | `tldr diff ... -l brainfuck` | bad-lang | 2 | [`20-bad-lang.*`](./diff.probes/) |
| P21 | `tldr diff ... -l python` | explicit python | 0 | [`21-lang-python.*`](./diff.probes/) |
| P22 | `tldr diff ... -l typescript` | lang-mismatch | 0 | [`22-lang-mismatch.*`](./diff.probes/) |
| P23 | `tldr diff <dir> <file>` | dir-vs-file (granularity mismatch) | 1 | [`23-dir-vs-file.*`](./diff.probes/) |
| P24 | `tldr diff ... -q` | quiet | 0 | [`24-quiet.*`](./diff.probes/) |

### Observations

- **P01** — `yahoo.py vs dhan.py` (default L4 function): 9 changes detected (deletes for yahoo's `_to_finite_float`, `YahooProvider`; inserts for dhan's `DhanProvider`). `identical: false`. Output is the structured change list.
- **P02** — L6 file diff between `backend/providers` and `backend`: 308 lines. Many file-level changes since the dirs differ in structure.
- **P03** — stderr `"error: the following required arguments were not provided: <FILE_B>"`, exit `2`.
- **P04** — stderr `"Error: file not found: /no/such/a.py"`, exit **5** (RemainingError::FileNotFound). Matches `tldr secure`/`tldr vuln`/`tldr dead-stores`. Lowercase "file".
- **P05** — stderr `"Error: --format sarif not supported by diff. Use --format json. SARIF is only emitted by: vuln, clones."`, exit `1`.
- **P06** — Text format: 31 lines, human-readable diff summary.
- **P07** — **`-f compact` IS BROKEN:** byte-identical to default JSON (17524 bytes both). Same bug class as `tldr resources`/`tldr taint`/`tldr temporal`. Workaround: `jq -c`.
- **P08** — stderr `"Error: --format dot not supported by diff. ..."`, exit `1`.
- **P09** — **L1 token: 17,721 LINES** stdout. Extremely expensive — every single token diff. Use sparingly.
- **P10** — L2 expression: 16,650 lines. Slightly less than token.
- **P11** — L3 statement: 2,452 lines. More reasonable.
- **P12** — L5 class: 39 lines. Compact — focuses on class-level shape.
- **P13** — L6 file (same dir twice): `identical: true, changes: [], file_changes: []`. Schema adds `file_changes` field.
- **P14** — **L7 module:** adds `module_changes` + `import_graph_summary: { total_edges_a, total_edges_b, edges_added, edges_removed, modules_with_import_changes }`. **Unique architectural metric** — import-graph delta count.
- **P15** — **L8 architecture:** adds `arch_changes` + `arch_summary: { layer_migrations, directories_added, directories_removed, cycles_introduced, cycles_resolved, stability_score }`. **Stability score is 1.0 for identical input** — likely 0.0-1.0 range. Architecture-level diff for high-level refactor diffs.
- **P16** — clap-style: `"error: invalid value 'wat' for '--granularity <GRANULARITY>' [possible values: token, expression, statement, function, class, file, module, architecture]"`, exit `2`. **Best-in-class** — all 8 values shown.
- **P17** — `--semantic-only`: same line count (177) as default in this scope. Filters formatting changes; effect depends on input (whitespace differences are minimal here).
- **P18** — `-O <tmp>` writes JSON to file; stdout EMPTY. Same pattern as `tldr secure -o` and `tldr vuln -O`. **Capital `-O`** short flag (matches secure/vuln; uppercase).
- **P19** — Identical files: `identical: true, changes: [], summary: { all_zeros }, granularity: "function"`. Clean canonical output.
- **P20** — clap-style: `"error: invalid value 'brainfuck' for '--lang <LANG>': Unknown language: brainfuck"`, exit `2`.
- **P21** — `-l python` explicit: identical to default.
- **P22** — `-l typescript` on Python files: 177 lines — SAME as default. **`--lang` is silently ignored OR auto-detect overrides** for this command.
- **P23** — **Dir-vs-file at default L4:** `tldr diff backend backend/providers/yahoo.py`: stderr `"Error: parse error in backend: Unsupported language: .unknown"`, exit `1`. The engine fails when trying to parse the directory as a single file. **Need matching argument types per granularity level.**
- **P24** — `-q` suppresses progress.

---

## Source Code Reality

**Target file(s):**
- `crates/tldr-cli/src/commands/remaining/diff.rs` (~2500+ lines — huge because of per-granularity diff engines)
- `crates/tldr-cli/src/output.rs:113` (`validate_format_for_command`)

**Pinned to upstream commit:** `6c4011a` (release v0.4.0)

**Argument struct:**
```rust
// crates/tldr-cli/src/commands/remaining/diff.rs:64-82
#[derive(Debug, Args)]
pub struct DiffArgs {
    pub file_a: PathBuf,
    pub file_b: PathBuf,
    #[arg(long, short = 'g', default_value = "function")] pub granularity: DiffGranularity,
    #[arg(long)] pub semantic_only: bool,
    #[arg(long, short = 'O')] pub output: Option<PathBuf>,
}
```
Reveals: 8-level typed enum `DiffGranularity`. `-O` (capital) for `--output`. NO `--lang` field on local struct (uses global `Cli` flag).

**Path validation:**
```rust
// diff.rs:191-197 (also lines 2446-2450 in newer code path)
if !self.file_a.exists() {
    return Err(RemainingError::file_not_found(&self.file_a).into());
}
if !self.file_b.exists() {
    return Err(RemainingError::file_not_found(&self.file_b).into());
}
```
Reveals: BOTH paths validated upfront. RemainingError → exit 5.

**Format validation:** confirmed at `crates/tldr-cli/src/output.rs:113-163` — `diff` is in neither `SARIF_SUPPORTED` nor `DOT_SUPPORTED`.

**No daemon route:** `grep -n try_daemon_route remaining/diff.rs` returns 0 matches.

---

## Architectural Deep Dive

- **Under the hood:** Per-granularity AST diff engines. L1-L5 work on single files (tokenize → walk AST → tree-edit-distance). L6-L8 work on directories (walk file trees, compare import graphs, compare architectural metrics). Detection of `change_type` uses sub-tree matching: `delete` (only in A), `insert` (only in B), `update` (changed body, same name+location), `move` (same body, different location), `rename` (changed name, same body), `format` (whitespace-only changes — excluded by `--semantic-only`).
- **Performance:** L1 token is by far the slowest (17K lines for 2 small files). L5+ is much faster. NO daemon caching.
- **LLM cognitive load:** Powerful refactor-analysis tool. For PR review, `-g class` or `-g file` is ideal (focused output). For deep semantic comparison, `-g function --semantic-only` is the workhorse. For architecture audits, `-g architecture` gives `stability_score`.

---

## Intent & Routing

- **User/Agent Goal:** structurally diff two files (or two directories at L6+) — find what's been added/removed/moved/renamed at any granularity from tokens to architecture.
- **When to choose this over similar tools:**
  - Over `git diff`: AST-aware (semantic vs syntactic). `git diff` shows token-level text changes; `tldr diff` understands functions, classes, imports.
  - Over `tldr change-impact`: change-impact finds AFFECTED TESTS; diff finds CHANGED STRUCTURE.
  - Over `tldr clones`: clones finds SIMILAR code across one tree; diff compares two specific paths.
- **Prerequisites (composition):**
  - Both FILE_A and FILE_B must exist (validated upfront).
  - For L6+ granularity, BOTH paths must be DIRECTORIES (P23 fails with dir-vs-file mismatch).
  - Use `--semantic-only` for PR-review noise filtering.

---

## Agent Synthesis

> **How to use `tldr diff`:**
> AST-aware structural diff. `tldr diff <FILE_A> <FILE_B>` returns JSON `{ file_a, file_b, identical, changes: [{ change_type, node_kind, name, old_location?, new_location? }], summary: { total_changes, semantic_changes, inserts, deletes, updates, moves, renames, formats, extracts }, granularity }`. 8 granularity levels via `-g {token, expression, statement, function (default), class, file, module, architecture}` — schema EXTENDS at L6/L7/L8 with `file_changes`, `module_changes` + `import_graph_summary`, `arch_changes` + `arch_summary`. Default JSON; `-f text` for summary; **`-f compact` BROKEN (returns pretty JSON)**; `sarif`/`dot` rejected. `-O <file>` writes to file. Exit codes: 0 ok, 1 dir-vs-file mismatch / format-reject, 2 missing FILE_B / bad-granularity / bad-lang, 5 file-not-found.
>
> **Crucial Rules:**
> - **`-g token` (L1) produces MASSIVE output** (P09: 17,721 lines for 2 small files). Token-level diffs are RARELY what you want — use `-g statement` or higher for actionable diffs. **Default `-g function` (L4) is the sweet spot.**
> - **L6+ granularity (file, module, architecture) REQUIRES DIRECTORIES**. P23: `-g function` (default) on `<dir> <file>` errors with `"parse error in backend: Unsupported language: .unknown"` exit 1. For directory diffs, use `-g file` or higher.
> - **`-f compact` IS BROKEN** (P07: byte-identical to default pretty JSON, 17524 bytes both). Same bug class as `tldr resources`/`tldr taint`/`tldr temporal`. Workaround: `jq -c`.
> - **L7 module diff produces UNIQUE import_graph_summary** with `edges_added`, `edges_removed`, `modules_with_import_changes` (P14). Use for "what imports changed in this refactor?" CI checks.
> - **L8 architecture diff produces UNIQUE arch_summary** with `stability_score` (0.0-1.0), `cycles_introduced`/`cycles_resolved`, `layer_migrations` (P15). Use for high-level architectural refactor audits.
> - **`-g <bad>` produces the BEST-IN-CLASS error** with ALL 8 valid values listed inline (P16: `"[possible values: token, expression, statement, function, class, file, module, architecture]"`). Discoverable.
> - **File-not-found exit code is 5** (RemainingError::FileNotFound — matches `tldr secure`/`tldr vuln`/`tldr dead-stores`). Lowercase `"file not found:"`.
> - **`-O` (capital) for `--output`** — matches `tldr secure -O`/`tldr vuln -O`/`tldr api-check -O`. When set, stdout is empty and file gets the JSON.
> - **`-l typescript` on Python files is SILENT** (P22: same output as default). Same anti-pattern as elsewhere — engine auto-detects regardless.
> - **`change_type` values:** `delete, insert, update, move, rename, format, extract`. The `summary` counts each — filter via `jq '.changes[] | select(.change_type == "update")'` for refactor-focused review.
> - **`--semantic-only` excludes `change_type: "format"`** (whitespace/comment-only changes). Critical for PR-review noise reduction.
> - **NO daemon route.** Every call re-parses both files.
>
> **Command:** `tldr diff <FILE_A> <FILE_B>`
>
> **With common flags:** `tldr diff <FILE_A> <FILE_B> -g function --semantic-only -f text` (use for PR-review-style human-readable diff, excluding whitespace-only changes).
