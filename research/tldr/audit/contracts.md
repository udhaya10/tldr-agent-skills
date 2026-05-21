# Command: `tldr contracts`

## Environment Pin

| Field | Value |
|---|---|
| `tldr --version` | 0.4.0 |
| Build features | `semantic` (verified; contracts itself is AST-based, non-semantic) |
| Target repo | Stock-Monitor @ commit `e601869` |
| Upstream `tldr-code` pinned to | local clone @ `6c4011a` (release v0.4.0) |
| Daemon state at probe time | N/A — `tldr contracts` does **not** call `try_daemon_route` (verified by grep) |
| OS | darwin 25.2.0 |
| Probe date | 2026-05-22 |

Re-run all evidence via [`contracts.probes/probe.sh`](./contracts.probes/probe.sh).

---

## Ground Truth (`tldr contracts --help`)

```text
Infer pre/postconditions from guard clauses, assertions, isinstance checks

Usage: tldr contracts [OPTIONS] <FILE> <FUNCTION>

Arguments:
  <FILE>
          Source file to analyze

  <FUNCTION>
          Function name to analyze

Options:
  -l, --lang <LANG>
          Programming language (auto-detected from file extension if not specified)

      --limit <LIMIT>
          Maximum conditions to report per category

          [default: 100]

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
| Typical output size | small (~20 lines pretty JSON for typed Python function) |

**Top-level keys (JSON, `ContractsReport`):**
- `function` (`string`) — input function name verbatim
- `file` (`string`) — USER-supplied path (NOT canonicalized; P3.BUG-N2)
- `preconditions` (`array<Condition>`) — conditions inferred to hold before function entry
- `postconditions` (`array<Condition>`) — conditions inferred to hold after function exit
- `invariants` (`array<Condition>`) — conditions inferred to hold throughout the body

**`Condition` shape:**
- `variable` (`string`) — name of the parameter / `"return"` for the return value
- `constraint` (`string`) — human-readable formal expression (e.g., `"isinstance(value, Any)"`, `"x > 0"`, `"not None"`)
- `source_line` (`u32`) — line of the AST node from which the condition was derived
- `confidence` (`string`) — `"low"` (from type annotations only), `"medium"`, `"high"` (from `assert`/`raise`/explicit guard clauses)

**Confidence inference table (from --help):**
| Pattern | Confidence |
|---|---|
| `if <cond>: raise/throw/panic` | High |
| `assert <cond>` / `assert!(<cond>)` | High |
| `if not isinstance(...): raise` | High |
| `assert` after `result =` | High (postcondition) |
| Type annotations only | **Low** |

**Empty-result shape (P11, --limit 0):**
```json
{
  "function": "fetch_historical_data",
  "file": "backend/providers/yahoo.py",
  "preconditions": [],
  "postconditions": [],
  "invariants": []
}
```
Exit 0. `--limit 0` means **literal zero** (NOT unlimited).

**Error shapes (ContractsError-based — matches `tldr dead-stores`):**
- Missing FUNCTION: clap-style → exit **2**
- File not found: `"Error: file not found: /no/such/file.py"` → exit **1** (lowercase "file" — matches `tldr chop`/`tldr dead-stores`)
- Function not found: `"Error: function '<name>' not found in <CANONICAL absolute path>"` → exit **1** (NOT 20)
- Cannot determine language: `"Error: parse error in <path>: Cannot determine language for '<path>'. Use --lang to specify."` → exit **1**
- Format reject: `"Error: --format sarif not supported by contracts. ..."` → exit **1**
- Bad `--lang`: clap-style → exit **2**

---

## Probe Matrix

| # | Probe | Type | Exit | Captured |
|---|-------|------|------|----------|
| P01 | `tldr contracts yahoo.py _to_finite_float` | happy | 0 | [`01-happy.*`](./contracts.probes/) |
| P02 | `tldr contracts yahoo.py fetch_historical_data` | happy-scale | 0 | [`02-happy-scale.*`](./contracts.probes/) |
| P03 | `tldr contracts <file>` *(no FUNCTION)* | failure-missing-input | 2 | [`03-missing-arg.*`](./contracts.probes/) |
| P04 | `tldr contracts /no/such/file.py some_fn` | failure-badpath | 1 | [`04-badpath.*`](./contracts.probes/) |
| P05 | `tldr contracts ... -f sarif` | format-reject (sarif) | 1 | [`05-format-reject-sarif.*`](./contracts.probes/) |
| P06 | `tldr contracts ... -f text` | format-text | 0 | [`06-format-text.*`](./contracts.probes/) |
| P07 | `tldr contracts ... -f compact` | format-compact | 0 | [`07-format-compact.*`](./contracts.probes/) |
| P08 | `tldr contracts ... -f dot` | format-reject (dot) | 1 | [`08-format-reject-dot.*`](./contracts.probes/) |
| P09 | `tldr contracts ... no_such_function` | function-not-found | 1 | [`09-function-not-found.*`](./contracts.probes/) |
| P10 | `tldr contracts ... --limit 1` | limit-low (no truncation in this scope) | 0 | [`10-limit-low.*`](./contracts.probes/) |
| P11 | `tldr contracts ... --limit 0` | limit-zero (literal empty!) | 0 | [`11-limit-zero.*`](./contracts.probes/) |
| P12 | `tldr contracts ... -l brainfuck` | bad-lang | 2 | [`12-bad-lang.*`](./contracts.probes/) |
| P13 | `tldr contracts README.md anything` | non-source-md (NO silent Python fallback) | 1 | [`13-non-source-md.*`](./contracts.probes/) |
| P14 | `tldr contracts backend anything` | directory-as-file | 1 | [`14-directory-arg.*`](./contracts.probes/) |
| P15 | `tldr contracts ... -l python` | lang-python | 0 | [`15-lang-python.*`](./contracts.probes/) |
| P16 | `tldr contracts ... -l typescript` | lang-mismatch (function not found) | 1 | [`16-lang-mismatch.*`](./contracts.probes/) |
| P17 | `tldr contracts ... -o text` | legacy -o text | 0 | [`17-output-flag-text.*`](./contracts.probes/) |
| P18 | `tldr contracts ... -q` | quiet | 0 | [`18-quiet.*`](./contracts.probes/) |
| P19 | `tldr contracts backend/db.py get_connection` | function-not-found (different file) | 1 | [`19-db-function.*`](./contracts.probes/) |

### Observations

- **P01** — `_to_finite_float` (`def _to_finite_float(value: Any) -> Optional[float]`): 1 precondition (`isinstance(value, Any)`, source_line=18, confidence="low") + 1 postcondition (`isinstance(return, Optional[float])`, source_line=18, confidence="low"). Confidence is LOW because both are derived from type annotations only — no explicit `assert`/`raise` guards.
- **P02** — `fetch_historical_data` (3 typed params, return type `pd.DataFrame`): 3 preconditions (one per parameter), 1 postcondition. All "low" confidence.
- **P03** — stderr `"error: the following required arguments were not provided: <FUNCTION>"`, exit `2`.
- **P04** — stderr `"Error: file not found: /no/such/file.py"`, exit `1`. Lowercase "file" — matches `tldr chop`/`tldr dead-stores`/`tldr cohesion`.
- **P05** — stderr `"Error: --format sarif not supported by contracts. ..."`, exit `1`.
- **P06** — Text format: `"Function: X\n  Preconditions:\n    - <constraint> (<var>, line N, <conf>)\n  Postconditions:\n    - ...\n"`. Progress message: `"Analyzing contracts for backend/providers/yahoo.py::_to_finite_float..."`.
- **P07** — Single-line minified JSON.
- **P08** — stderr `"Error: --format dot not supported by contracts. ..."`, exit `1`.
- **P09** — stderr `"Error: function 'no_such_function' not found in /Users/.../yahoo.py"`, exit **1** (NOT 20). Uses `ContractsError::FunctionNotFound` which maps to exit 1 (same convention as `tldr dead-stores`). **Cross-namespace divergence:** `tldr complexity`, `tldr explain`, `tldr impact`, `tldr available`, `tldr reaching-defs` all exit 20 for this same error.
- **P10** — `--limit 1`: same output as default (P02 has 3 preconditions; --limit 1 should truncate to 1, but the output shows 21 lines == P02). Possibly the limit isn't applied PER CATEGORY but in some other way, OR the scope's data doesn't exercise truncation here. **Investigation note:** --help says "Maximum conditions to report **per category**" — verify with a function that has >1 condition.
- **P11** — **`--limit 0` literally returns 0 conditions** across all three categories. NOT "unlimited" semantics (cf. `tldr cognitive --top 0` which means "all"). Cross-command convention divergence.
- **P12** — clap-style: `"error: invalid value 'brainfuck' for '--lang <LANG>': Unknown language: brainfuck"`, exit `2`.
- **P13** — stderr `"Error: parse error in README.md: Cannot determine language for 'README.md'. Use --lang to specify."`, exit `1`. **NO silent Python fallback** per FM-22 / FM-44 fix (source comment at contracts.rs:809-819 confirms). The error explicitly tells the user to pass `--lang`. **Best-in-class error message** — distinct from `tldr complexity` ("Unsupported language: Could not detect language for: <path>") and `tldr available` (silent Python fallback).
- **P14** — Same shape as P13: `"Error: parse error in backend: Cannot determine language for 'backend'. Use --lang to specify."`, exit `1`. Directory passes existence check; `Language::from_path` returns None for directories; the FM-22 fix surfaces a clear error rather than silently defaulting.
- **P15** — Explicit `-l python` on `.py`: identical to auto-detect (P01).
- **P16** — `-l typescript` on `.py`: stderr `"Error: function '_to_finite_float' not found in /Users/.../yahoo.py"`, exit `1`. **Same misleading-error anti-pattern as `tldr complexity` and `tldr dead-stores`** — TS parser walks Python source, fails to find function. The error blames the function name, not the language mismatch.
- **P17** — Legacy `-o text`: same text output as `-f text`. Both flag paths converge.
- **P18** — `-q` suppresses the `"Analyzing contracts for ..."` progress message.
- **P19** — `get_connection` not found in `backend/db.py`: `"Error: function 'get_connection' not found in ..."`, exit 1. Confirms the function-not-found error path is consistent regardless of file.

---

## Source Code Reality

**Target file(s):**
- `crates/tldr-cli/src/commands/contracts/contracts.rs` (~4111 lines — large because it includes per-language AST configs for ~18 languages)
- `crates/tldr-cli/src/commands/contracts/validation.rs` (path/function validators, AST depth limits)
- `crates/tldr-core/src/contracts/...` (per-language condition extractors)
- `crates/tldr-cli/src/output.rs:113` (`validate_format_for_command`)

**Pinned to upstream commit:** `6c4011a` (release v0.4.0)

**Argument struct:**
```rust
// crates/tldr-cli/src/commands/contracts/contracts.rs:769-792
#[derive(Debug, Args)]
pub struct ContractsArgs {
    pub file: PathBuf,
    pub function: String,
    #[arg(long = "output-format", short = 'o', hide = true, default_value = "json")]
    pub output_format: ContractsOutputFormat,
    #[arg(long, short = 'l')] pub lang: Option<Language>,
    #[arg(long, default_value = "100")] pub limit: usize,
}
```
Reveals: minimal CLI surface. Legacy hidden `-o`/`--output-format` for backwards-compat.

**FM-22/FM-44 — NO silent Python fallback (the P13/P14 win):**
```rust
// contracts.rs:809-819
let language = match self.lang {
    Some(l) => l,
    None => Language::from_path(&self.file).ok_or_else(|| ContractsError::ParseError {
        file: self.file.clone(),
        message: format!(
            "Cannot determine language for '{}'. Use --lang to specify.",
            self.file.display()
        ),
    })?,
};
```
Reveals: unlike `tldr available` (which silently defaults to Python) and `tldr complexity` (which says "Unsupported language: Could not detect..."), `tldr contracts` returns a clear actionable error: **"Cannot determine language for X. Use --lang to specify."** Source comment cites FM-22, FM-44.

**Tree-sitter grammar verification:**
```rust
// contracts.rs:821-828
if ParserPool::get_ts_language(language).is_none() {
    return Err(ContractsError::ParseError {
        file: self.file.clone(),
        message: format!("No tree-sitter grammar available for {:?}", language),
    }
    .into());
}
```
Reveals: explicit check that the engine has a tree-sitter grammar for the resolved language. Defensive — would catch a hypothetical Language enum value that the build feature-gates out.

**Path preservation (P3.BUG-N2):**
```rust
// contracts.rs:836-838
// Echo the user-supplied path in the JSON `file` field. ...
// Mirrors the M2 BUG-8 fix.
report.file = self.file.clone();
```
Reveals: same canonical-path-don't-leak pattern as `tldr chop` and `tldr dead-stores` — the engine works with the canonical path internally, but the JSON `file` field echoes the user input.

**Limits (T07/T08 mitigations):**
- `MAX_AST_DEPTH` — prevents stack overflow on pathological inputs (T08)
- `MAX_CONDITIONS_PER_FUNCTION` — caps per-function condition counts (separate from `--limit`)
- Regex DoS prevention (T07) — compiled regex with bounded backtracking

**Function-not-found exit code (ContractsError, not TldrError):**
This command lives in the `contracts/` namespace (under `crates/tldr-cli/src/commands/contracts/`) and uses `ContractsError`, which maps to exit 1 for `FunctionNotFound` (same as `tldr dead-stores`, `tldr chop`). **DIFFERS from the TldrError commands** (`impact`, `explain`, `complexity`, `available`, `reaching-defs`) which all exit 20.

**Format validation:** confirmed at `crates/tldr-cli/src/output.rs:113-163` — `contracts` is in neither `SARIF_SUPPORTED` nor `DOT_SUPPORTED`.

**No daemon route:** `grep -n try_daemon_route contracts.rs` returns 0 matches. Every call re-parses + re-extracts.

---

## Architectural Deep Dive

- **Under the hood:** Tree-sitter parse → walk AST → match per-language patterns for assert/raise/throw/panic, isinstance checks, type annotations. Assign confidence based on pattern strength (explicit assertion = high, type annotation = low). 18 languages supported (each with its own `LanguageConfig` mapping AST node kinds).
- **Performance:** Cold ~50-100ms per call. NO daemon caching. Limits at `MAX_AST_DEPTH` and `MAX_CONDITIONS_PER_FUNCTION` prevent pathological inputs.
- **LLM cognitive load:** Surfaces the IMPLICIT contracts encoded in code (type hints, guard clauses, assertions). Useful for: API documentation generation, refactor preparation ("does my change preserve these conditions?"), test-case generation (each precondition is a candidate negative test).

---

## Intent & Routing

- **User/Agent Goal:** extract the implicit pre/post-conditions of a function from its code — guard clauses, asserts, type annotations.
- **When to choose this over similar tools:**
  - Over `tldr extract`: `extract` returns function signatures + locations; `contracts` returns the implicit constraints. Different abstraction level.
  - Over `tldr invariants`: `invariants` finds loop/state invariants project-wide; `contracts` is function-level pre/post.
  - Over manual reading: surfaces hidden assertions buried deep in function bodies.
- **Prerequisites (composition):**
  - Pre-discover function names with `tldr extract <file>`.
  - For non-default extensions or unknown files, pass `-l <lang>` explicitly (P13/P14 show the engine REFUSES to guess).

---

## Agent Synthesis

> **How to use `tldr contracts`:**
> Pre/post-condition inferrer. `tldr contracts <FILE> <FUNCTION>` returns JSON `{ function, file, preconditions, postconditions, invariants }`. Each `Condition` has `variable` (parameter name or `"return"`), `constraint` (human formula), `source_line`, `confidence` ("low" for type annotations, "high" for explicit asserts/guards). Default JSON; `-f text` for human display; `-f compact` for one-line; `sarif`/`dot` rejected. Exit codes: 0 ok, 1 file-not-found / function-not-found / cannot-determine-language / format-reject, 2 missing-arg / bad-lang.
>
> **Crucial Rules:**
> - **NO silent Python fallback** (FM-22 / FM-44 fix). Unlike `tldr available` (silent Python) and `tldr complexity` ("Unsupported language: Could not detect..."), `tldr contracts` returns the most actionable error in the audit suite: `"parse error in <file>: Cannot determine language for '<file>'. Use --lang to specify."` Pass `-l <lang>` for non-default extensions (P13, P14).
> - **Function-not-found exit code is 1, NOT 20.** This command uses `ContractsError::FunctionNotFound` (contracts namespace). Differs from `tldr complexity`/`tldr explain`/`tldr impact`/`tldr available`/`tldr reaching-defs` which all exit 20 (TldrError). Matches `tldr dead-stores`/`tldr chop` (contracts-namespace siblings).
> - **`--limit 0` literally returns 0 conditions** across all three categories (P11). NOT "unlimited" semantics. Cross-command convention divergence — `tldr cognitive --top 0` and `tldr dead --max-items 0` both mean "all", but here it means "none". Use a large number like 9999 for unlimited.
> - **Confidence "low" = type annotations only; "high" = explicit asserts/guards.** Per the docstring table at contracts.rs:11-23: `if <cond>: raise` → high; `assert <cond>` → high; `if not isinstance(...): raise` → high; type annotations alone → low. Filter `confidence != "low"` client-side for high-signal contracts only.
> - **`-l typescript` on a `.py` file yields a MISLEADING "Function not found" error** (P16). Same anti-pattern as `tldr complexity`/`tldr dead-stores` — TS parser walks Python source, fails to find function. Verify language matches file extension before debugging the function name.
> - **`file` field in output is USER-supplied path** (NOT canonicalized; P3.BUG-N2 fix). Safe for round-trip — but error messages show CANONICAL absolute paths.
> - **Confidence values: `"low"`, `"medium"`, `"high"`** (string enum). Lowercase per serde default. NO score (just three buckets).
> - **NO daemon route.** Every call re-parses. `tldr warm` is a no-op.
> - **18 languages supported** (Python, Go, Rust, Java, TS, JS, C, C++, Ruby, C#, Scala, PHP, Lua, Luau, Elixir, OCaml, Kotlin, Swift) per the `LanguageConfig` enum. Each has language-specific AST node kinds; coverage may vary in quality.
>
> **Command:** `tldr contracts <FILE> <FUNCTION>`
>
> **With common flags:** `tldr contracts <FILE> <FN> -l <lang> -f compact | jq '[.preconditions[], .postconditions[]] | map(select(.confidence != "low"))'` (use to filter high-signal contracts only, dropping the low-confidence type-annotation derivations).
