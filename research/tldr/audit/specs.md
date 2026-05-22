# Command: `tldr specs`

## Environment Pin

| Field | Value |
|---|---|
| `tldr --version` | 0.4.0 |
| Build features | `semantic` (verified; specs is AST-based test scanner, non-semantic) |
| Target repo | N/A — fixture-driven (specs requires pytest test files) |
| Fixtures | `research/fixtures/invariants/test_src.py` (reused from invariants — 6 pytest test functions over `add`, `clamp`, `divide`) |
| Upstream `tldr-code` pinned to | local clone @ `6c4011a` (release v0.4.0) |
| Daemon state at probe time | N/A — `tldr specs` does **not** call `try_daemon_route` (verified by grep) |
| OS | darwin 25.2.0 |
| Probe date | 2026-05-22 |

Re-run all evidence via [`specs.probes/probe.sh`](./specs.probes/probe.sh).

---

## Ground Truth (`tldr specs --help`)

```text
Extract behavioral specifications from pytest test files

Usage: tldr specs [OPTIONS] --from-tests <FROM_TESTS>

Options:
  -t, --from-tests <FROM_TESTS>
          Test file or directory to scan for specs

      --function <FUNCTION>
          Filter to specific function under test

      --source <SOURCE>
          Source directory for cross-referencing (optional)

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
| Formats that work | `json`, `text`, `compact` (P01, P06, P07) |
| Formats that error | `sarif`, `dot` (P05, P08: exit 1) |
| Typical output size | medium (~225 lines for 6-test-function fixture) |

**Top-level keys (JSON, `SpecsReport`):**
- `functions` (`array<FunctionSpecs>`) — per-function-under-test specifications
- `summary` (`object`) — `{ total_specs, by_type: { input_output, exception, property }, test_functions_scanned, test_files_scanned, functions_found }`

**`FunctionSpecs` shape:**
- `function_name` (`string`) — function being tested (e.g., `"add"`, `"clamp"`)
- `summary` (`string`) — empty in observation; possibly populated by future passes
- `test_count` (`u32`) — observed 0 in P01 (count of test functions exercising this — possibly aggregate bug)
- `input_output_specs` (`array<IOSpec>`) — concrete input → expected output pairs
- `exception_specs` (`array<ExceptionSpec>`) — tests that assert exceptions
- `property_specs` (`array<PropertySpec>`) — pytest parametrize / property-based specs

**`IOSpec` shape:**
```json
{
  "function": "add",
  "inputs": [1, 2],
  "output": 3,
  "test_function": "test_add_positives",
  "line": 7,
  "confidence": "high"
}
```
- `function` — the function under test (duplicates outer `function_name`)
- `inputs` — array of JSON-typed literal values from the assert
- `output` — JSON-typed expected value
- `test_function` — test that produced this spec
- `line` — test source line
- `confidence` — observed `"high"` (likely also `"medium"`, `"low"`)

**Three spec kinds via `summary.by_type`:**
- `input_output` — concrete assertEqual / assert == specs
- `exception` — `pytest.raises(X)` blocks
- `property` — `@pytest.mark.parametrize` and property-based

**Empty-result shape (P10 function-not-found, P18 non-test file, P20 empty dir):**
```json
{
  "functions": [],
  "summary": {
    "total_specs": 0,
    "by_type": { "input_output": 0, "exception": 0, "property": 0 },
    "test_functions_scanned": <N>,
    "test_files_scanned": <N>,
    "functions_found": 0
  }
}
```
Exit 0. **`test_functions_scanned` and `test_files_scanned` differentiate failure modes**: P20 (empty dir) shows both 0; P18 (regular .py file) shows 1 file scanned, 0 test functions; P10 (function-not-found) shows 6 test functions scanned (engine ran fully).

**Error shapes (ContractsError-based):**
- Missing `--from-tests`: clap-style → exit **2** (it's a required long-only flag)
- Test path not found: `"Error: test path not found: /no/such/tests"` → exit **1** (ContractsError::TestPathNotFound — matches `tldr invariants`)
- Format reject: `"Error: --format sarif not supported by specs. ..."` → exit **1**
- Bad `--lang`: clap-style → exit **2**
- Bad legacy `-o`: clap-style `"invalid value 'wat' for '--output-format <OUTPUT_FORMAT>' [possible values: json, text]"` → exit **2**

---

## Probe Matrix

| # | Probe | Type | Exit | Captured |
|---|-------|------|------|----------|
| P01 | `tldr specs --from-tests test_src.py` | happy | 0 | [`01-happy.*`](./specs.probes/) |
| P02 | `tldr specs --from-tests <dir>` | happy-scale (directory) | 0 | [`02-happy-scale.*`](./specs.probes/) |
| P03 | `tldr specs` *(no --from-tests)* | failure-missing-input | 2 | [`03-missing-arg.*`](./specs.probes/) |
| P04 | `tldr specs --from-tests /no/such/tests` | failure-badpath | 1 | [`04-badpath.*`](./specs.probes/) |
| P05 | `tldr specs ... -f sarif` | format-reject (sarif) | 1 | [`05-format-reject-sarif.*`](./specs.probes/) |
| P06 | `tldr specs ... -f text` | format-text | 0 | [`06-format-text.*`](./specs.probes/) |
| P07 | `tldr specs ... -f compact` | format-compact | 0 | [`07-format-compact.*`](./specs.probes/) |
| P08 | `tldr specs ... -f dot` | format-reject (dot) | 1 | [`08-format-reject-dot.*`](./specs.probes/) |
| P09 | `tldr specs ... --function add` | function filter | 0 | [`09-function-filter.*`](./specs.probes/) |
| P10 | `tldr specs ... --function no_such_function` | function-not-found (silent) | 0 | [`10-function-not-found.*`](./specs.probes/) |
| P11 | `tldr specs ... --source <fixture-dir>` | source cross-ref | 0 | [`11-source-flag.*`](./specs.probes/) |
| P12 | `tldr specs ... --source /no/such/source` | **bad --source NOT validated** | 0 | [`12-source-bad.*`](./specs.probes/) |
| P13 | `tldr specs ... -l brainfuck` | bad-lang | 2 | [`13-bad-lang.*`](./specs.probes/) |
| P14 | `tldr specs ... -l python` | explicit-python | 0 | [`14-lang-python.*`](./specs.probes/) |
| P15 | `tldr specs ... -l typescript` | lang-mismatch (silent ignore) | 0 | [`15-lang-mismatch.*`](./specs.probes/) |
| P16 | `tldr specs ... -o text` | legacy -o text | 0 | [`16-output-flag-text.*`](./specs.probes/) |
| P17 | `tldr specs ... -o wat` | bad legacy -o | 2 | [`17-output-flag-bogus.*`](./specs.probes/) |
| P18 | `tldr specs --from-tests src.py` | non-test file (silent empty) | 0 | [`18-from-tests-not-test.*`](./specs.probes/) |
| P19 | `tldr specs ... -q` | quiet | 0 | [`19-quiet.*`](./specs.probes/) |
| P20 | `tldr specs --from-tests <empty-dir>` | empty-tests-dir | 0 | [`20-empty-tests-dir.*`](./specs.probes/) |

### Observations

- **P01** — `test_src.py`: 3 functions found (`add`, `clamp`, `divide`), 225 lines total output. Each function has `input_output_specs[]` with concrete input/output pairs and line refs. P01 IOSpec for `add`: `{ inputs: [1, 2], output: 3, test_function: "test_add_positives", line: 7, confidence: "high" }`.
- **P02** — Directory `--from-tests <fixture-dir>`: 225 lines — identical to P01 since fixture dir contains only test_src.py (and src.py which yields nothing).
- **P03** — stderr `"error: the following required arguments were not provided: --from-tests <FROM_TESTS>"`, exit `2`. **No positional FILE** — `--from-tests` is the ONLY required arg.
- **P04** — stderr `"Error: test path not found: /no/such/tests"`, exit `1`. ContractsError::TestPathNotFound — matches `tldr invariants` P13.
- **P05** — stderr `"Error: --format sarif not supported by specs. ..."`, exit `1`.
- **P06** — Text format: 24 lines — per-function block with input→output pairs.
- **P07** — Single-line minified JSON.
- **P08** — stderr `"Error: --format dot not supported by specs. ..."`, exit `1`.
- **P09** — `--function add`: filters to `add` only. 90 lines (vs 225 for all 3 functions).
- **P10** — **SILENT EMPTY:** `--function no_such_function`: `functions: []`, exit 0. `summary.test_functions_scanned: 6, test_files_scanned: 1, functions_found: 0`. The test scan ran fully (6 tests scanned) but no matching function specs — distinguishable from "no tests" by these counts.
- **P11** — `--source <fixture-dir>`: identical output to P01 (225 lines). The source flag enables cross-referencing but doesn't change the spec extraction visible here. May affect `summary` field in different scenarios.
- **P12** — **BAD `--source` IS NOT VALIDATED!** `--source /no/such/source` returns exit 0 with same output as P01 (225 lines). **Asymmetry vs `--from-tests`** (which IS validated, P04). `--source` is `Option<PathBuf>` but never checked for existence in `run()`. Bug or feature: non-existent source paths are silently ignored.
- **P13** — clap-style: `"error: invalid value 'brainfuck' for '--lang <LANG>': Unknown language: brainfuck"`, exit `2`.
- **P14** — Explicit `-l python`: identical to default.
- **P15** — `-l typescript` on Python: 225 lines — same output as default. **`--lang` SILENTLY IGNORED.** Same anti-pattern as `tldr invariants` (which has same source comment about needing the flag for clap type consistency).
- **P16** — Legacy `-o text`: 24 lines, same as `-f text` (P06).
- **P17** — clap-style: `"error: invalid value 'wat' for '--output-format <OUTPUT_FORMAT>' [possible values: json, text]"`, exit `2`. Legacy `-o` only supports `json`/`text` (NOT compact/sarif/dot).
- **P18** — `--from-tests <source-file>`: exit 0 with `{ functions: [], summary: { test_functions_scanned: 0, test_files_scanned: 1, functions_found: 0 } }`. **Distinguishable from empty-dir P20** by `test_files_scanned: 1`. The engine scanned 1 file but found no `test_*` functions in it.
- **P19** — `-q` suppresses the `"Extracting specs from <path>..."` progress message.
- **P20** — Empty dir: `{ functions: [], summary: { test_files_scanned: 0, ... } }` — `test_files_scanned: 0` distinguishes from non-test file (P18 has 1).

---

## Source Code Reality

**Target file(s):**
- `crates/tldr-cli/src/commands/contracts/specs.rs` (~280 lines)
- `crates/tldr-core/src/contracts/specs/...` (AST scanning, parametrize handling)
- `crates/tldr-cli/src/output.rs:113` (`validate_format_for_command`)

**Pinned to upstream commit:** `6c4011a` (release v0.4.0)

**Argument struct:**
```rust
// crates/tldr-cli/src/commands/contracts/specs.rs:71-92
#[derive(Debug, Args)]
pub struct SpecsArgs {
    #[arg(long = "from-tests", short = 't')] pub from_tests: PathBuf,
    #[arg(long = "output-format", short = 'o', hide = true, default_value = "json")]
    pub output_format: ContractsOutputFormat,
    #[arg(long)] pub function: Option<String>,
    #[arg(long)] pub source: Option<PathBuf>,
}
```
Reveals: ONLY `--from-tests` is required. **NO positional FILE** — unlike `tldr invariants` which requires both `--from-tests` AND a source FILE positional. This makes `tldr specs` self-contained: it extracts specs from tests alone; `--source` is just for cross-referencing summaries.

**Path validation (ONLY `--from-tests`):**
```rust
// specs.rs:99-105
if !self.from_tests.exists() {
    return Err(ContractsError::TestPathNotFound {
        path: self.from_tests.clone(),
    }
    .into());
}
```
Reveals: only `--from-tests` is validated. `--source` is NOT validated (P12 confirms). **Asymmetric path validation** — same source file (lines 99-105) validates only one of two PathBuf args.

**No `-l, --lang` flag in source struct above:**
Wait — the `--help` shows `-l, --lang`. The flag exists at the global `Cli` level (main.rs), not in `SpecsArgs`. clap routes it via the global parser. Source has no SpecsArgs.lang field — that's why the silent-ignore happens: the local handler doesn't reference it.

**Format validation:** confirmed at `crates/tldr-cli/src/output.rs:113-163` — `specs` is in neither `SARIF_SUPPORTED` nor `DOT_SUPPORTED`.

**No daemon route:** `grep -n try_daemon_route specs.rs` returns 0 matches.

---

## Architectural Deep Dive

- **Under the hood:** Walks pytest test files (functions named `test_*`). For each test, parses `assert X(args) == result` patterns into IOSpecs, `pytest.raises(E)` into ExceptionSpecs, `@parametrize` into PropertySpecs. Aggregates per-function-under-test. Confidence assigned by structural patterns.
- **Performance:** Cold ~10-50ms per test file. NO daemon caching.
- **LLM cognitive load:** Extracts the BEHAVIORAL specification from existing tests — what the function is SUPPOSED to do per the test suite. Useful for: contract documentation generation, refactor safety (verify new impl satisfies same input/output pairs), test-quality audits ("are my tests actually specifying behavior?"). Complements `tldr invariants` (infers from observed test calls) by extracting EXPLICIT assertions.

---

## Intent & Routing

- **User/Agent Goal:** extract the explicit behavioral spec encoded in tests — input/output pairs, exception specs, parametrized tests.
- **When to choose this over similar tools:**
  - Over `tldr invariants`: invariants infers numerical/type constraints from observed argument values; specs extracts assert-based specs (the EXPLICIT contract).
  - Over `tldr contracts`: contracts infers from CODE patterns (asserts, guards); specs extracts from TEST patterns.
  - Over manual test review: aggregates many tests into per-function spec lists.
- **Prerequisites (composition):**
  - `--from-tests` MUST exist (validated). `--source` doesn't need to exist (P12).
  - Tests must follow `test_*` naming convention (P18: regular `.py` file scanned but no test_* functions = empty result).
  - For per-function focus, use `--function <name>` — filter to function-name UNDER TEST (not the test function name).

---

## Agent Synthesis

> **How to use `tldr specs`:**
> Behavioral-spec extractor from pytest test files. `tldr specs --from-tests <PATH>` returns JSON `{ functions, summary }`. Each `FunctionSpecs` has `function_name, summary, test_count, input_output_specs, exception_specs, property_specs`. Each `IOSpec` has `{ function, inputs: [...], output, test_function, line, confidence }`. `summary` has `total_specs, by_type: { input_output, exception, property }, test_functions_scanned, test_files_scanned, functions_found`. Default JSON; `-f text` for per-function block; `-f compact` for one-line; `sarif`/`dot` rejected. Exit codes: 0 ok (including silent empties), 1 test-path-not-found / format-reject, 2 missing --from-tests / bad-lang / bad legacy -o.
>
> **Crucial Rules:**
> - **`--source` is NOT validated** (P12: `--source /no/such/source` returns exit 0). **Asymmetric** with `--from-tests` which IS validated (P04 exit 1 with test-path-not-found). Agents passing programmatically-derived source paths should validate independently — silent acceptance is a UX trap.
> - **NO positional FILE.** Unlike `tldr invariants` (which requires source FILE + `--from-tests`), `tldr specs` works from tests ALONE. `--source` is optional and only for cross-referencing.
> - **`--lang <X>` silently IGNORED.** P15: `-l typescript` on Python tests returns same output as default. The lang flag is at the global `Cli` level (no `SpecsArgs.lang` field), so the local handler never references it. Same anti-pattern as `tldr invariants` — patterns-namespace habit.
> - **Three failure modes are DISTINGUISHABLE by summary counts:** function-not-found (test_files_scanned: 1, test_functions_scanned: N>0, functions_found: 0); non-test file (test_files_scanned: 1, test_functions_scanned: 0); empty dir (test_files_scanned: 0). Inspect `test_files_scanned` vs `test_functions_scanned` to disambiguate.
> - **Three spec types observed in `by_type`:** `input_output` (assert == patterns), `exception` (pytest.raises blocks), `property` (parametrize / property-based). Each has a count in `summary.by_type`.
> - **`inputs` is an ARRAY of JSON-typed literal values.** Extracted verbatim from test calls. For complex objects, may be serialized as JSON or skipped — verify confidence field for low-extraction confidence.
> - **`confidence` values observed:** `"high"`. Other expected: `"medium"`, `"low"` depending on extraction precision (e.g., variable args vs literal args).
> - **Test-path-not-found exit code is 1** (ContractsError::TestPathNotFound). Matches `tldr invariants`.
> - **Legacy `-o` only supports `json`/`text`** (P17). NO compact/dot/sarif via legacy flag. Cross-flag inconsistency: global `-f` supports compact but local `-o` doesn't.
> - **NO daemon route.** Every call walks test files freshly.
>
> **Command:** `tldr specs --from-tests <PATH> [--function <NAME>] [--source <DIR>]`
>
> **With common flags:** `tldr specs --from-tests tests/ --function process_payment | jq '.functions[0].input_output_specs[] | { inputs, output, line }'` (use for spec-driven refactor: dump all input/output assertions for one function as JSON pairs, ideal for verifying that a new implementation still satisfies the same contract).
