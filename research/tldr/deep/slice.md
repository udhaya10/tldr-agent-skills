# Command: `tldr slice`

## Environment Pin

| Field | Value |
|---|---|
| `tldr --version` | 0.4.0 |
| Build features | `semantic` (verified via runtime probe on 2026-05-21) |
| Target repo | Stock-Monitor @ commit `e601869` |
| Upstream `tldr-code` pinned to | local clone @ `6c4011a` (release v0.4.0) |
| Daemon state at probe time | warm (cycled mid-probe for P14/P15) |
| OS | darwin 25.2.0 |
| Probe date | 2026-05-22 |

Re-run all evidence via [`slice.probes/probe.sh`](./slice.probes/probe.sh).

---

## Ground Truth (`tldr slice --help`)

```text
Compute program slice

Usage: tldr slice [OPTIONS] <FILE> <FUNCTION> <LINE>

Arguments:
  <FILE>
          Source file path

  <FUNCTION>
          Function name containing the line

  <LINE>
          Line number to slice from

Options:
  -d, --direction <DIRECTION>
          Slice direction: backward (what affects this line) or forward (what this line affects)

          Possible values:
          - backward: Backward slice - what affects this line?
          - forward:  Forward slice - what does this line affect?
          
          [default: backward]

      --variable <VARIABLE>
          Variable to filter by (optional - traces all if not specified)

  -l, --lang <LANG>
          Programming language (auto-detected from file extension if not specified)

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
| Formats that work | `json`, `text`, `compact` (P01, P06, P13) |
| Formats that error | `sarif`, `dot` (P05: exit 1) |
| Typical output size | small (<1KB) for trivial functions; medium-heavy for large functions (P02: ~10KB pre-truncation for a ~75-line function) |

**Top-level keys (JSON, direct-compute "rich" shape):**
- `file` (`string`) — the source file
- `function` (`string`) — function name as queried
- `criterion_line` (`int`) — the line the slice was computed from
- `direction` (`string`) — `"backward"` or `"forward"`
- `variable` (`string \| null`) — null if no `--variable` filter
- `lines` (`array<int>`) — bare line numbers in the slice (backward-compatible field)
- `slice_lines` (`array<SliceLine>`) — rich per-line data (omitted if empty)
- `edges` (`array<SliceEdge>`) — data and control dependency edges (omitted if empty)
- `line_count` (`int`) — `lines.length`
- `explanation` (`string`, **optional but critical**) — when the slice is empty due to a known cause (e.g. criterion line outside function bounds), this field tells you why **AND includes the actual function bounds**

**`slice_lines[]` shape:**
- `line` (`int`), `code` (`string`)
- `definitions` (`array<string>`) — variables defined at this line (omitted when empty)
- `uses` (`array<string>`) — variables read at this line (omitted when empty)
- `dep_type` (`string`, optional) — `"data"` or `"control"`
- `dep_label` (`string`, optional)

**`edges[]` shape:**
- `from_line` (`int`), `to_line` (`int`)
- `dep_type` (`string`) — `"data"` or `"control"`
- `label` (`string`) — variable name for data edges; empty for control edges

> **Two shapes exist:** the direct-compute path emits the "rich" shape with `slice_lines` and `edges`; the daemon path returns a "legacy" shape (bare line numbers) which the CLI then enriches by reading the source file. Either way, the JSON exposed to the user includes `slice_lines`, but `edges` is **only populated on the direct-compute path** — when the daemon route hits, `edges` is `[]`.

**Text format (P06):** Compact LLM-friendly with `>` marker on the criterion line, `<-- criterion` flag, and indented code lines.

**Compact format (P13):** Single-line JSON.

**OOR (Out-Of-Range) explanation (P09, P11):** When the criterion line is outside the function's actual bounds, the response is:
```json
{
  "lines": [],
  "line_count": 0,
  "explanation": "Analysis could not be completed: line 9999 is outside function 'get_db_connection' (lines 48-53)"
}
```
**The explanation tells the agent both that the line is out of range AND the correct bounds (48-53)** — agents can self-correct. This is the `P12.AGG12-15` upstream improvement.

**Error shapes — `slice` has THREE distinct exit codes:**
- **Exit 1** — format validator rejection (P05): standard validator error.
- **Exit 2** — clap missing args (P03): lists *all three* missing positionals (`<FILE>`, `<FUNCTION>`, `<LINE>`) plus `Usage:` hint.
- **Exit 20** — semantic lookup failure:
  - `Error: Function not found: <name>` — function name not present in the file (P10), OR **the file itself doesn't exist** (P04). **The error message is misleading on bad paths** — slice reports "Function not found" even when the real problem is "File not found."

> **Empty slice ≠ error.** Lines `[]` with an `explanation` field is exit 0. Agents must check for `explanation` to distinguish a legitimate empty slice from a logically empty slice.

---

## Probe Matrix

Slug convention: `NN-<token>[-<modifier>]`. The audit script globs by ID, so modifiers are safe.

| # | Probe | Type | Exit | Captured |
|---|-------|------|------|----------|
| P01 | `tldr slice backend/db.py get_db_connection 49` | happy | 0 | [`01-happy.*`](./slice.probes/) |
| P02 | `tldr slice backend/scripts/apply_classification_theme_workbook.py apply_rows_to_database 130` | happy-scale | 0 | [`02-happy-scale.*`](./slice.probes/) |
| P03 | `tldr slice` *(no args)* | failure-missing-args | 2 | [`03-missing-arg.*`](./slice.probes/) |
| P04 | `tldr slice /no/such/file.py foo 1` | failure-badpath-as-fn-not-found | 20 | [`04-badpath.*`](./slice.probes/) |
| P05 | `tldr slice backend/db.py get_db_connection 49 -f sarif` | format-reject | 1 | [`05-format-reject-sarif.*`](./slice.probes/) |
| P06 | `tldr slice backend/db.py get_db_connection 49 -f text` | format-text | 0 | [`06-format-text.*`](./slice.probes/) |
| P07 | `tldr slice backend/db.py get_db_connection 49 -d forward` | direction-forward | 0 | [`07-forward.*`](./slice.probes/) |
| P08 | `tldr slice backend/db.py get_db_connection 49 --variable conn` | flag-variable-filter | 0 | [`08-variable-filter.*`](./slice.probes/) |
| P09 | `tldr slice backend/db.py get_db_connection 9999` | boundary-oor-line | 0 | [`09-oor-line.*`](./slice.probes/) |
| P10 | `tldr slice backend/db.py zzz_no_such_function 49` | failure-fn-not-in-file | 20 | [`10-fn-not-in-file.*`](./slice.probes/) |
| P11 | `tldr slice backend/db.py get_db_connection 0` | boundary-line-zero | 0 | [`11-line-zero.*`](./slice.probes/) |
| P12 | `tldr slice backend/db.py get_db_connection 48` | boundary-line-at-decl | 0 | [`12-line-at-decl.*`](./slice.probes/) |
| P13 | `tldr slice backend/db.py get_db_connection 49 -f compact` | format-compact | 0 | [`13-format-compact.*`](./slice.probes/) |
| P14 | `tldr slice backend/db.py get_db_connection 49` *(daemon stopped)* | env-cold-daemon | 0 | [`14-cold-daemon.*`](./slice.probes/) |
| P15 | `tldr slice backend/db.py get_db_connection 49` *(after `tldr warm`)* | env-warm-daemon | 0 | [`15-warm-daemon.*`](./slice.probes/) |
| P16 | `tldr extract backend/db.py \| jq ... \| xargs tldr slice ...` | composition-chain | 0 | [`16-composition.*`](./slice.probes/) |

### Observations

- **P01 (small function, 17 lines JSON):** Slice from line 49 in a 6-line `get_db_connection` returns only line 49 itself (`code: "    try:"`). `slice_lines` is present but minimal; `edges` is `[]` (single statement has no edges). No `definitions`/`uses` populated because the daemon serves the legacy shape and the CLI enriches with code only.
- **P02 (substantial function, 400 lines truncated):** Slice from line 130 in `apply_rows_to_database` returns lines starting from L122 (function start) — a real PDG output spanning the function's prologue and the dependency chain reaching L130.
- **P03 (no args):** clap error listing **all three** required positionals (`<FILE>`, `<FUNCTION>`, `<LINE>`), exit `2`.
- **P04 (bad file path):** **Confusing UX.** stderr `Error: Function not found: foo`, exit `20`. The actual problem is that the file doesn't exist, but `slice` has no upfront path-existence check (`slice.rs` runs the parser directly), so the failure surfaces as "function not found" instead. **Agents that branch on exit code 20 must consider both possibilities: missing function in a real file, OR missing file altogether.**
- **P05 (sarif rejection):** standard validator error, exit `1`.
- **P06 (text format, 7 lines):** `Program Slice (backward from line 49)` / `Function: backend/db.py::get_db_connection` / `Slice contains 1 lines:` / `> 49 | try: <-- criterion`. Compact, scannable.
- **P07 (forward direction) vs P01 (backward):** **byte-identical.** For a single-statement criterion in a 6-line function, forward and backward slicing converge. The empirical difference shows on larger functions.
- **P08 (`--variable conn`) vs P01 (no filter):** **byte-identical.** The variable filter is meaningful only when the slice spans multiple lines with multiple variables in play. Tiny functions don't exercise it.
- **P09 (line 9999, far OOR):** Exit `0`, empty `lines: []`, `explanation: "Analysis could not be completed: line 9999 is outside function 'get_db_connection' (lines 48-53)"`. **This is the most agent-friendly feature of `slice`:** the diagnostic reveals the actual function bounds (48-53) so the agent can re-query with a valid line.
- **P10 (function name not present):** exit `20`, stderr `Error: Function not found: zzz_no_such_function`. Clean error.
- **P11 (line=0):** Exit `0`. Same OOR explanation as P09 (line 0 is outside the function's 48-53 bounds).
- **P12 (line=48, the `def` line):** Exit `0`. Slice now reports `criterion_line: 48` with `code: "def get_db_connection():"`. **The function declaration line counts as inside the function for slicing purposes** — useful for slicing forward from a function's entry.
- **P13 (compact):** Single-line JSON, identical content to P01.
- **P14 (cold daemon) vs P15 (warm daemon):** Both 17 lines, both byte-identical to P01. For this micro-function, the daemon route adds no signal.
- **P16 (composition chain):** Runs `tldr extract backend/db.py | jq -r '.functions[] | select(.name=="is_sqlite_lock_error") | .line' | xargs -I {} tldr slice backend/db.py is_sqlite_lock_error {}`. **Full end-to-end chain works** — produces a 2-line slice with `definitions: [...]` populated (because the direct-compute path was used, not the daemon's legacy shape). **This is the canonical agent workflow:** `extract` discovers the line, `slice` traces the dependencies.

---

## Source Code Reality

**Target file:** `crates/tldr-cli/src/commands/slice.rs` (pinned to local clone at `6c4011a`).

**Argument struct (`slice.rs:19-41`):**
```rust
pub struct SliceArgs {
    pub file: PathBuf,                          // required
    pub function: String,                       // required
    pub line: u32,                              // required
    #[arg(long, short = 'd', default_value = "backward")]
    pub direction: SliceDirectionArg,
    #[arg(long)]
    pub variable: Option<String>,
    #[arg(long, short = 'l')]
    pub lang: Option<Language>,
}
```
All three positionals required (no `default_value`). Direction defaults to backward.

**No path-existence check.** `slice.rs` immediately runs language detection and then either hits the daemon route or calls `get_slice_rich`. There is no `if !self.file.exists()` guard. **This is why P04 reports "Function not found" instead of "File not found"** — the file-read failure inside the parser surfaces as a function-not-found error.

**Two output shapes wired in CLI:**
- `LegacySliceOutput` (`slice.rs:113-121`): bare `lines: Vec<u32>` — returned by daemon cache hits
- `SliceOutput` (`slice.rs:87-109`): rich shape with `slice_lines`, `edges`, optional `explanation` — returned on direct compute

When the daemon path is taken (`slice.rs:141-247`), the CLI enriches the legacy output with source code from disk, but `edges` is left as `Vec::new()` (line 242). **`edges` is only populated when the daemon misses and the direct-compute path runs.**

**OOR explanation helper (`slice.rs:466-482`):**
```rust
fn slice_oor_explanation(
    source_or_path: &str,
    function_name: &str,
    line: u32,
    language: Language,
) -> Option<String> {
    let (start, end) =
        find_function_bounds_from_path_or_source(source_or_path, function_name, language)?;
    if line < start || line > end {
        Some(format!(
            "Analysis could not be completed: line {} is outside function '{}' (lines {}-{})",
            line, function_name, start, end
        ))
    } else {
        None
    }
}
```
**Confirms P09/P11:** the explanation includes the resolved function bounds. The helper returns `None` (no explanation emitted) when the function can't even be located in source — that's a different failure mode that surfaces as exit 20 "Function not found" instead.

**Daemon route includes file+function+line as cache key** (`slice.rs:144`): `params_with_file_function_line(...)` — cache is correctly partitioned by criterion, so changing any of the three positionals invalidates the cache.

**Format validator** confirmed at `crates/tldr-cli/src/output.rs::validate_format_for_command` — `slice` is in neither `SARIF_SUPPORTED` nor `DOT_SUPPORTED`.

---

## Architectural Deep Dive

- **Engine:** `get_slice_rich` (in `tldr-core`) computes the Program Dependence Graph (PDG) = Control Flow Graph (CFG) ∪ Data Dependence Graph (DDG), then traverses transitively from the criterion node (line + optional variable) in the requested direction. Returns nodes (one per line in the slice) and edges (data and control dependencies between them).
- **Cache layer:** Daemon-backed, keyed on `(parent_dir, file, function, line)`. **Caveat:** daemon returns the legacy shape (bare line numbers); the rich `edges` field is only populated on the direct-compute path. Agents that depend on the `edges` array should run against a cold daemon or check whether `edges` is empty before trusting it.
- **Direction:** `backward` (default) = "what affects this line"; `forward` = "what does this line affect". For trivial single-statement criteria, both directions converge.
- **Variable filter:** `--variable <name>` restricts the trace to lines that touch the named variable. Meaningful only for multi-variable slices; no-op on small functions.
- **OOR diagnostic:** When the criterion line falls outside the resolved function bounds, the engine returns an empty slice plus an `explanation` field that includes the actual bounds. This is among the most agent-friendly error messages in the entire suite.
- **LLM cognitive load:** Replaces "read the entire 200-line function and manually trace which lines influence this one." `slice` gives the agent the minimal set of lines that mathematically affect (or are affected by) the criterion — the gold standard for debugging state corruption or tracking variable origins.

---

## Intent & Routing

- **User/Agent Goal:** Trace the *exact* mathematical dependency chain into or out of a specific line of code.
- **When to choose this over similar tools:**
  - Use *over* reading the whole function when you need only the lines that touch a specific variable or affect a specific outcome.
  - Use *backward* when debugging "where did this corrupt value come from?"
  - Use *forward* when planning "if I change this assignment, what downstream lines break?"
  - Use *with* `--variable` when the function has multiple in-flight variables and you only care about one.
- **Prerequisites:**
  - **Function name + line number must be known.** The only practical way to obtain a valid line number is via `tldr extract <file>` first.
  - File must be a parseable source file.
- **Composes well with:**
  - `tldr extract <file>` → pick a function and its line → `tldr slice <file> <function> <line>` *(this is the canonical chain — see P16)*
  - `tldr search "concept"` → pick a result card → use its `file_path` + `line_range[0]` for slice.
  - `tldr impact <function>` → find a critical caller → `tldr slice <caller-file> <caller-fn> <line>` to understand its data flow.

---

## Agent Synthesis

> **How to use `tldr slice`:**
> Use when you need to know exactly which lines mathematically affect (backward) or are affected by (forward) a specific line in a function. The result is a PDG-based slice — the gold standard for debugging state corruption and tracking variable origins. Always run `tldr extract <file>` first to get a valid line number; passing a guessed line that's outside the function bounds returns an empty slice with a helpful `explanation` field that includes the actual bounds.
>
> **Crucial Rules:**
> - **All three positionals are REQUIRED:** `<FILE> <FUNCTION> <LINE>`. Omitting any of them produces a clap error (exit 2) listing all missing args.
> - **Canonical workflow is `extract → slice`:** `tldr extract <file>` → find the function's start line → feed it into `tldr slice`. Don't guess line numbers — `slice` is line-number-sensitive.
> - **Three distinct exit codes:**
>   - `1` = format reject (swap `-f`)
>   - `2` = missing args (provide all three)
>   - `20` = "Function not found" — **ambiguous**: could be missing function name *or* missing file (no upfront file-existence check). Verify the file path before retrying.
> - **Empty slice ≠ error.** Exit 0 with `lines: []` plus an `explanation` field means the criterion line was outside the function's bounds. **The `explanation` includes the actual function bounds (e.g., `"line 9999 is outside function 'get_db_connection' (lines 48-53)"`)** — agents should parse this and retry with a line in the reported range.
> - **`edges` field is only populated on direct-compute, not daemon-cache hits.** If you need dependency edges (data vs control), run with a cold daemon (`tldr daemon stop`) or check for an empty `edges` array and re-run.
> - **`--variable <name>` and `-d forward/backward` are no-ops on trivial single-statement criteria.** They differentiate only when the slice spans multiple lines with multiple variables.
> - **Forward vs backward semantics:** `backward` (default) = "what affects this line"; `forward` = "what this line affects". Pick based on debugging direction.
> - **Function decl line counts as inside the function** — slicing from the `def`/`fn`/`function` line works and returns the signature as the criterion (P12).
> - **`-f sarif` and `-f dot` are rejected** (exit 1).
>
> **Commands:**
> - Canonical (with extract first):
>   ```bash
>   line=$(tldr extract <file> | jq -r '.functions[] | select(.name=="<func>") | .line')
>   tldr slice <file> <func> "$line"
>   ```
> - Backward (default): `tldr slice <file> <func> <line>`
> - Forward: `tldr slice <file> <func> <line> -d forward`
> - Filter to one variable: `tldr slice <file> <func> <line> --variable <var>`
> - Human-readable: `tldr slice <file> <func> <line> -f text`
