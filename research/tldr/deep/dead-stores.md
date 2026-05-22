# Command: `tldr dead-stores`

## Environment Pin

| Field | Value |
|---|---|
| `tldr --version` | 0.4.0 |
| Build features | `semantic` (verified; dead-stores itself is non-semantic, uses CFG+DFG+SSA engines) |
| Target repo | Stock-Monitor @ commit `e601869` |
| Upstream `tldr-code` pinned to | local clone @ `6c4011a` (release v0.4.0) |
| Daemon state at probe time | N/A — `tldr dead-stores` does **not** call `try_daemon_route` (verified by grep) |
| OS | darwin 25.2.0 |
| Probe date | 2026-05-22 |

Re-run all evidence via [`dead-stores.probes/probe.sh`](./dead-stores.probes/probe.sh).
See also: [agent-oriented tool card](../../tool-cards/deep/dead-stores.md).

---

## Ground Truth (`tldr dead-stores --help`)

```text
Find dead stores using SSA-based analysis

Usage: tldr dead-stores [OPTIONS] <file> <function>

Arguments:
  <file>
          Source file to analyze

  <function>
          Function name to analyze

Options:
  -l, --lang <LANG>
          Programming language (auto-detected from file extension if not specified)

      --compare
          Compare SSA-based detection with live-variables based detection

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
| Typical output size | small (~10 lines default; ~30 lines with --compare) |

**Top-level keys (JSON, `DeadStoresReport`):**
- `function` (`string`) — input function name verbatim
- `file` (`string`) — input file path verbatim (per BUG-8 cross-command-consistency-v1)
- `dead_stores_ssa` (`array<DeadStore>`) — SSA-based findings (conservative)
- `count` (`u32`) — length of `dead_stores_ssa`
- `dead_stores_live_vars` (`array<DeadStore>` | `null`) — only populated when `--compare` is set
- `live_vars_count` (`u32` | `null`) — only populated when `--compare` is set

**`DeadStore` shape:**
- `variable` (`string`) — original variable name
- `ssa_name` (`string`) — SSA-renamed form (e.g., `self_lv`, `required_lv` — suffix marks the analysis method)
- `line` (`u32`, 1-indexed)
- `block_id` (`u32`) — CFG block where the store occurs
- `is_phi` (`bool`) — true if this store is a phi-node (control-flow merge)

**Empty-result shape (P01 / P02):**
```json
{
  "function": "_to_finite_float",
  "file": "backend/providers/yahoo.py",
  "dead_stores_ssa": [],
  "count": 0,
  "dead_stores_live_vars": null,
  "live_vars_count": null
}
```
Exit 0. The `dead_stores_live_vars: null` is omitted-by-default — only present when `--compare`. SSA analysis is CONSERVATIVE (fewer findings); see P09 for the comparison disagreement pattern.

**Error shapes (all stderr):**
- Missing FUNCTION: clap-style `"error: the following required arguments were not provided: <function> …"` → exit **2**
- File not found: `"Error: file not found: /no/such/file.py"` → exit **1** (lowercase "file" — matches `tldr chop`, differs from `tldr available`'s capital F)
- Function not found: `"Error: function '<name>' not found in <file>"` → exit **1** (NOT exit 20 like `impact`/`explain`/`context` — see Source Code Reality)
- Directory as FILE: `"Error: IO error: Is a directory (os error 21)"` → exit **1** (raw OS error — `validate_file_path` does not pre-reject directories)
- Format reject: `"Error: --format sarif not supported by dead-stores. ..."` → exit **1**
- Bad `--lang`: clap-style → exit **2**

---

## Probe Matrix

| # | Probe | Type | Exit | Captured |
|---|-------|------|------|----------|
| P01 | `tldr dead-stores yahoo.py _to_finite_float` | happy | 0 | [`01-happy.*`](./dead-stores.probes/) |
| P02 | `tldr dead-stores yahoo.py fetch_historical_data` | happy-scale | 0 | [`02-happy-scale.*`](./dead-stores.probes/) |
| P03 | `tldr dead-stores <file>` *(no FUNCTION)* | failure-missing-input | 2 | [`03-missing-arg.*`](./dead-stores.probes/) |
| P04 | `tldr dead-stores /no/such/file.py some_fn` | failure-badpath | 1 | [`04-badpath.*`](./dead-stores.probes/) |
| P05 | `tldr dead-stores ... -f sarif` | format-reject | 1 | [`05-format-reject-sarif.*`](./dead-stores.probes/) |
| P06 | `tldr dead-stores ... -f text` | format-text | 0 | [`06-format-text.*`](./dead-stores.probes/) |
| P07 | `tldr dead-stores ... -f compact` | format-compact | 0 | [`07-format-compact.*`](./dead-stores.probes/) |
| P08 | `tldr dead-stores ... -f dot` | format-reject-dot | 1 | [`08-format-reject-dot.*`](./dead-stores.probes/) |
| P09 | `tldr dead-stores ... --compare` | compare-modes (SSA vs live-vars divergence) | 0 | [`09-compare.*`](./dead-stores.probes/) |
| P10 | `tldr dead-stores ... no_such_function` | function-not-found | 1 | [`10-function-not-found.*`](./dead-stores.probes/) |
| P11 | `tldr dead-stores ... -l brainfuck` | bad-lang | 2 | [`11-bad-lang.*`](./dead-stores.probes/) |
| P12 | `tldr dead-stores README.md anything` | non-source-md (silent Python fallback) | 1 | [`12-non-source-md.*`](./dead-stores.probes/) |
| P13 | `tldr dead-stores ... -o text` | legacy -o text flag | 0 | [`13-output-flag-text.*`](./dead-stores.probes/) |
| P14 | `tldr dead-stores ... -q` | quiet | 0 | [`14-quiet.*`](./dead-stores.probes/) |
| P15 | `tldr dead-stores backend anything` | directory-as-file (raw OS error) | 1 | [`15-directory-arg.*`](./dead-stores.probes/) |
| P16 | `tldr dead-stores ... -l python` | explicit-python | 0 | [`16-lang-python.*`](./dead-stores.probes/) |
| P17 | `tldr dead-stores ... -l typescript` *(on .py)* | lang-mismatch | 1 | [`17-lang-mismatch.*`](./dead-stores.probes/) |

### Observations

- **P01** — `_to_finite_float`: `dead_stores_ssa: []`, `count: 0`, both live-vars fields null. SSA detects NO dead stores in this simple Python function.
- **P02** — `fetch_historical_data` (larger function): same shape, still `dead_stores_ssa: []`. SSA is conservative on Python.
- **P03** — stderr `"error: the following required arguments were not provided: <function>"`, exit `2`.
- **P04** — stderr `"Error: file not found: /no/such/file.py"`, exit `1`. **Lowercase "file"** matches `tldr chop` convention; differs from `tldr available` ("File not found:" with capital F) and `tldr calls` ("Path not found:").
- **P05** — stderr `"Error: --format sarif not supported by dead-stores. ..."`, exit `1`.
- **P06** — Text format renders 4-line block: `"Dead Stores: <fn> (<file>)\n============================================================\nNo dead stores detected.\n"`.
- **P07** — Single-line compact JSON, same shape as P01.
- **P08** — stderr `"Error: --format dot not supported by dead-stores. ..."`, exit `1`.
- **P09** — **`--compare` reveals divergence:** SSA finds 0 dead stores; live-vars finds 3 (`self` at line 39, `required` at line 77, `available` at line 78). The `self` finding is a likely false-positive (method `self` parameter is implicitly used). **Substantive finding:** the two analyses disagree by 3 in a single function. **SSA is much more conservative.** The `ssa_name` suffix `_lv` marks live-vars findings — agents can disambiguate SSA-source vs live-vars-source rows by the suffix even without consulting the `dead_stores_live_vars`/`dead_stores_ssa` field key.
- **P10** — stderr `"Error: function 'no_such_function' not found in backend/providers/yahoo.py"`, exit `1`. **Notable divergence from other commands:** `tldr impact`/`tldr explain`/`tldr context` use exit `20` for FunctionNotFound; `dead-stores` uses exit `1`. Cross-command exit-code inconsistency for the SAME semantic error.
- **P11** — clap-style: `"error: invalid value 'brainfuck' for '--lang <LANG>': Unknown language: brainfuck"`, exit `2`.
- **P12** — Markdown file: stderr `"Error: function 'anything' not found in README.md"`, exit `1`. The `.md` file passed `validate_file_path` (exists, not a directory), then `Language::from_path` returned None → Python fallback → engine tries to parse markdown as Python → no function found. **Silent language fallback to Python** with the failure surfacing as function-not-found (NOT "unsupported language").
- **P13** — Legacy `-o text` (hidden via `#[arg(hide = true)]`): produces text output. Equivalent to `-f text`.
- **P14** — `-q` suppresses the `"Analyzing dead stores for ..."` progress message.
- **P15** — Directory as FILE: stderr `"Error: IO error: Is a directory (os error 21)"`, exit `1`. Raw OS error from `read_file_safe` — NOT the clean require_directory-style message used by `tldr hubs`/`tldr whatbreaks`. **Weak error UX** for this specific failure mode.
- **P16** — Explicit `-l python` on `.py`: identical to default behavior.
- **P17** — **Silent mismatch with subtle error:** `-l typescript` on a `.py` file: stderr `"Error: function '_to_finite_float' not found in backend/providers/yahoo.py"`, exit `1`. The TypeScript parser walks the Python file and finds no function with that name. The error message says "function not found" — does NOT mention the language mismatch. Misleading recovery hint; users may waste time checking the function name when the actual issue is the wrong `--lang`.

---

## Source Code Reality

**Target file(s):**
- `crates/tldr-cli/src/commands/contracts/dead_stores.rs` (in the `contracts/` namespace, not `commands/` directly)
- `crates/tldr-core/src/program_analysis/dead_stores.rs` (`find_dead_stores_dfg`, `find_dead_stores_live_vars`)
- `crates/tldr-cli/src/commands/contracts/types.rs:892` (`DeadStoresReport`)
- `crates/tldr-cli/src/commands/contracts/validation.rs` (`validate_file_path`, `read_file_safe`)
- `crates/tldr-cli/src/output.rs:113` (`validate_format_for_command`)

**Pinned to upstream commit:** `6c4011a` (release v0.4.0)

**Argument struct:**
```rust
// crates/tldr-cli/src/commands/contracts/dead_stores.rs:58-84
#[derive(Debug, Args)]
pub struct DeadStoresArgs {
    #[arg(value_name = "file")] pub file: PathBuf,
    #[arg(value_name = "function")] pub function: String,
    #[arg(long = "output-format", short = 'o', hide = true,
          default_value = "json")] pub output_format: ContractsOutputFormat,
    #[arg(long, short = 'l')] pub lang: Option<Language>,
    #[arg(long)] pub compare: bool,
}
```
Reveals: required positionals `<file>`, `<function>`. Hidden legacy `--output-format`/`-o` short alias for the global `-f`. `--compare` is a simple bool flag.

**FunctionNotFound exit code is 1, not 20 (P10 root cause):**
```rust
// dead_stores.rs:153-163 (excerpt)
let cfg = get_cfg_context(&source, function, language).map_err(|e| {
    let msg = e.to_string();
    if msg.contains("not found") || msg.contains("Not found") {
        ContractsError::FunctionNotFound { function: ..., file: ... }
    } else {
        ContractsError::SsaError(format!("CFG extraction failed: {}", e))
    }
})?;
```
Reveals: the contracts namespace has its OWN error type (`ContractsError`) separate from `TldrError`. `ContractsError::FunctionNotFound` maps to exit **1** (via the default anyhow conversion), NOT to exit 20 like `TldrError::FunctionNotFound` does. **Cross-namespace exit-code divergence** — same semantic error, different exit code based on which Rust error type the command uses internally.

**SSA node limit check:**
```rust
// dead_stores.rs:179-185
let def_count = dfg.refs.iter()
    .filter(|r| matches!(r.ref_type, RefType::Definition | RefType::Update))
    .count();
check_ssa_node_limit(def_count)?;
```
Reveals: TIGER T04 mitigation — bails on extremely large functions to prevent runaway SSA construction. The limit is set in `contracts/limits.rs`.

**`--compare` adds live-vars detection:**
```rust
// dead_stores.rs:190-197
let (dead_stores_live_vars, live_vars_count) = if compare {
    let live_vars_dead = find_dead_stores_live_vars(&source, function, language)?;
    let count = live_vars_dead.len() as u32;
    (Some(live_vars_dead), Some(count))
} else {
    (None, None)
};
```
Reveals: live-vars analysis is run as a SEPARATE pass when `--compare` is set. The two methods are documented as: SSA = "precise" (conservative), live-vars = "lower-precision" (more findings, more false positives). P09 demonstrates the divergence.

**Format validation:** confirmed at `crates/tldr-cli/src/output.rs:113-163` — `dead-stores` is in neither `SARIF_SUPPORTED` nor `DOT_SUPPORTED`.

**No daemon route:** `grep -n try_daemon_route dead_stores.rs` returns 0 matches. Every call rebuilds CFG + DFG (+ SSA). `tldr warm` is a no-op.

---

## Architectural Deep Dive

- **Under the hood:** Three-stage analysis. (1) Build CFG via `get_cfg_context`. (2) Build DFG via `get_dfg_context`. (3) Run SSA-based dead-store detection: a definition is dead if (a) the same variable is redefined later without an intervening use, OR (b) the variable is never used anywhere in the function (excluding parameters). `--compare` additionally runs live-vars dead-store detection for cross-validation.
- **Performance:** Cold per call (no daemon). ~100-300ms per function; the SSA construction dominates. `--compare` doubles the cost (two analyses).
- **LLM cognitive load:** Compiler-grade dead-store detection. Useful for finding wasted assignments, debug leftovers, and refactor artifacts. The dual-analysis `--compare` mode is the safest signal — agreement between SSA and live-vars is high-confidence; disagreement (P09) flags edge cases (parameter handling, control-flow merges) worth manual review.

---

## Intent & Routing

- **User/Agent Goal:** find assignments to variables whose values are never used. Useful for refactoring (delete dead code), debugging (find unused intermediates), and code review (catch typos like `result = compute()` then `return reseult`).
- **When to choose this over similar tools:**
  - Over `tldr dead` (function-level dead code): `dead` finds entire functions never called; `dead-stores` finds individual assignments inside one function. Different granularity.
  - Over `tldr reaching-defs <fn> <var>`: `reaching-defs` answers "where is X defined?"; `dead-stores` answers "which defs are wasted?" Inverse questions.
  - Over manual review: SSA-based detection catches edge cases (control-flow merges) that grep can't.
- **Prerequisites (composition):**
  - Use `tldr extract <file>` to enumerate function names first.
  - For confidence, run with `--compare` to cross-validate SSA against live-vars. Findings present in BOTH are highest-confidence.
  - For mixed-language projects, supply `-l <lang>` explicitly. Mis-spelled `-l` (P17) surfaces as a misleading "function not found" error.

---

## Agent Synthesis

> **How to use `tldr dead-stores`:**
> SSA-based dead-store detector. `tldr dead-stores <file> <function>` returns JSON `{ function, file, dead_stores_ssa, count, dead_stores_live_vars, live_vars_count }`. Default SSA-only output; `--compare` adds live-vars pass for cross-validation. Each `DeadStore` has `variable`, `ssa_name` (with `_lv` suffix for live-vars source), `line`, `block_id`, `is_phi`. Default JSON, `-f text` for human display, `-f compact` for one-line, `sarif`/`dot` rejected. Exit codes: 0 ok (including 0 dead stores), 1 file-not-found / function-not-found / format-reject / directory-as-file / lang-mismatch, 2 clap missing-arg / bad-lang.
>
> **Crucial Rules:**
> - **Function-not-found returns exit 1, NOT 20.** This command uses `ContractsError::FunctionNotFound` (contracts namespace), which maps to exit 1. Other commands (`impact`/`explain`/`context`) use `TldrError::FunctionNotFound` → exit 20. **Cross-namespace exit-code divergence for the same semantic error** (P10). Agents scripting around dead-stores cannot use the impact/explain "function-not-found = exit 20" convention.
> - **SSA and live-vars analyses disagree, often substantially.** P09: same function, SSA finds 0, live-vars finds 3. Live-vars flags method-`self` as a dead store (likely false positive). **For high-confidence findings, use `--compare` AND treat only the intersection (matches in BOTH arrays) as actionable.** Use SSA alone for conservative output; use `--compare` when investigating.
> - **`-l <wrong-lang>` surfaces as a MISLEADING "function not found" error.** P17: `-l typescript` on a `.py` file yields `"Error: function '_to_finite_float' not found in backend/providers/yahoo.py"` — does NOT mention the language mismatch. Agents debugging this should verify the language matches the file extension before checking the function name.
> - **Markdown / unknown extensions silently fall back to Python parsing**, then fail with "function not found". P12. Pass `-l <real_lang>` for non-default extensions.
> - **Directory as FILE produces raw OS error.** P15: `"IO error: Is a directory (os error 21)"`, exit 1. **Weak error UX** compared to `tldr hubs`/`tldr whatbreaks` which use `require_directory` for clean messages. Always pass an actual file path.
> - **`ssa_name` suffix encodes the analysis source.** Findings in `dead_stores_live_vars` have `ssa_name` ending in `_lv`; findings in `dead_stores_ssa` use unsuffixed SSA names. Even without inspecting the parent field key, agents can distinguish the source.
> - **NO daemon route.** Every call rebuilds CFG + DFG (+ SSA + optional live-vars).
> - **`live_vars_count: null` when --compare is unset.** Both `dead_stores_live_vars` and `live_vars_count` are null in default mode. Defensive parsing: check `dead_stores_live_vars !== null` before iterating.
>
> **Command:** `tldr dead-stores <file> <function>`
>
> **With common flags:** `tldr dead-stores <file> <function> -l <lang> --compare -f compact` (use to cross-validate findings; pipe to `jq '[.dead_stores_ssa[].variable] - [.dead_stores_live_vars[].variable]'` or similar set-operations to extract intersection/difference).
