# Command: `tldr fix check`

## Environment Pin

| Field | Value |
|---|---|
| `tldr --version` | 0.4.0 |
| Build features | `semantic` (verified; fix orchestrates shell-out test commands, non-semantic) |
| Target repo | N/A — fixture-driven (custom buggy.py NameError) |
| Fixtures | `research/fixtures/fix-check/buggy.py` |
| Upstream `tldr-code` pinned to | local clone @ `6c4011a` (release v0.4.0) |
| Daemon state at probe time | N/A — `tldr fix check` does **not** call `try_daemon_route` (verified by grep) |
| OS | darwin 25.2.0 |
| Probe date | 2026-05-22 |

Re-run all evidence via [`fix-check.probes/probe.sh`](./fix-check.probes/probe.sh).
See also: [agent-oriented tool card](../../tool-cards/fix/fix-check.md).

**Subcommand naming note:** CLI is `tldr fix check` (space-separated); dossier filename uses `fix-check.md` for filesystem compatibility.

---

## Ground Truth (`tldr fix check --help`)

```text
Run test command, diagnose failures, apply fixes, and re-run in a loop

Usage: tldr fix check [OPTIONS] --file <FILE> --test-cmd <TEST_CMD>

Options:
  -f, --file <FILE>                 Source file to fix
  -t, --test-cmd <TEST_CMD>         Test command to run (e.g., "pytest tests/test_app.py")
      --max-attempts <MAX_ATTEMPTS> [default: 5]
  -f, --format <FORMAT>             [default: json]      ← !! -f CLASHES with --file !!
  -l, --lang <LANG>
  -q, --quiet  -v, --verbose  -h, --help
```

**`-f` short flag is a CONFLICT.** Both `--file` and `--format` declare `-f` shorthand. clap appears to resolve `-f <value>` as `--file` (local wins over global). See P17.

---

## Output Shape

| Aspect | Value |
|---|---|
| Default format | `json` |
| Formats that work | `json`, `compact` (P02, P07) |
| Format **bug** | **`--format text` produces JSON, NOT text** (P06: identical to default) |
| Formats that error | `sarif`, `dot` (P05, P08: exit 1) |
| Typical output size | small (~7 lines pretty JSON for happy; ~15 lines with attempts array) |

**Top-level keys (JSON, `FixCheckReport`):**
- `file` (`string`) — ABSOLUTE path to source file
- `test_cmd` (`string`) — verbatim command echoed
- `attempts` (`array<Attempt>`) — fix attempts performed during the loop
- `final_pass` (`bool`) — true if test eventually passed
- `iterations` (`u32`) — total iterations executed

**`Attempt` shape:**
- `iteration` (`u32`) — 1-indexed iteration number
- `error_code` (`string`) — parsed error code (e.g., `"NameError"`, `"unparseable"` when error text doesn't match a known parser)
- `message` (`string`) — error message or empty string
- `fixed` (`bool`) — whether THIS iteration produced a fix
- `description` (`string` | `null`) — fix description when applied; null otherwise

**Empty-result shape (P02, test passes immediately):**
```json
{
  "file": "<absolute-path>",
  "test_cmd": "true",
  "attempts": [],
  "final_pass": true,
  "iterations": 1
}
```
Exit 0. **`iterations: 1`** because the test was run once (and passed) — distinct from "didn't run at all".

**Error shapes:**
- Missing `--test-cmd` (or `--file`): clap-style → exit **2**
- Bad `--file`: `"Error: Source file '/no/such/file.py' does not exist."` → exit **1** (best wording — quotes the path, explicit "does not exist")
- Format reject sarif: `"Error: --format sarif not supported by fix. ..."` (note: says `"by fix"` not `"by fix check"`) → exit **1**
- Bad `--lang`: clap-style → exit **2**
- `-f <value>` repeated (because `-f` is `--file`): `"error: the argument '--file <FILE>' cannot be used multiple times"` → exit **2**
- **Test FAILED after attempts:** `"Error: Some errors could not be fixed after N attempt(s)."` → exit **1**

---

## Probe Matrix

| # | Probe | Type | Exit | Captured |
|---|-------|------|------|----------|
| P01 | `tldr fix check --file buggy.py --test-cmd <python>` | happy (test fails, can't fix, exit 1) | 1 | [`01-happy.*`](./fix-check.probes/) |
| P02 | `tldr fix check --file buggy.py --test-cmd 'true'` | happy-scale (test passes, exit 0) | 0 | [`02-happy-scale.*`](./fix-check.probes/) |
| P03 | `tldr fix check --file <path>` *(no --test-cmd)* | failure-missing-input | 2 | [`03-missing-arg.*`](./fix-check.probes/) |
| P04 | `tldr fix check --file /no/such/file.py --test-cmd 'true'` | bad source-file path | 1 | [`04-badpath.*`](./fix-check.probes/) |
| P05 | `tldr fix check ... --format sarif` | format-reject (sarif) | 1 | [`05-format-reject-sarif.*`](./fix-check.probes/) |
| P06 | `tldr fix check ... --format text` | format-text (BUG: JSON emitted) | 0 | [`06-format-text.*`](./fix-check.probes/) |
| P07 | `tldr fix check ... --format compact` | format-compact (works) | 0 | [`07-format-compact.*`](./fix-check.probes/) |
| P08 | `tldr fix check ... --format dot` | format-reject (dot) | 1 | [`08-format-reject-dot.*`](./fix-check.probes/) |
| P09 | `tldr fix check ... --max-attempts 1 --test-cmd 'false'` | max-attempts 1 | 1 | [`09-max-attempts-low.*`](./fix-check.probes/) |
| P10 | `tldr fix check ... --max-attempts 0 --test-cmd 'false'` | max-attempts 0 (no attempts) | 1 | [`10-max-attempts-zero.*`](./fix-check.probes/) |
| P11 | `tldr fix check ... --test-cmd 'false'` *(default 5)* | max-attempts default | 1 | [`11-max-attempts-default.*`](./fix-check.probes/) |
| P12 | `tldr fix check ... --test-cmd '/no/such/cmd'` | bogus test-cmd | 1 | [`12-test-cmd-bogus.*`](./fix-check.probes/) |
| P13 | `tldr fix check ... --test-cmd 'exit 1'` | test-cmd fails | 1 | [`13-test-cmd-fail.*`](./fix-check.probes/) |
| P14 | `tldr fix check ... -l brainfuck` | bad-lang | 2 | [`14-bad-lang.*`](./fix-check.probes/) |
| P15 | `tldr fix check ... -l python --test-cmd 'true'` | explicit python | 0 | [`15-lang-python.*`](./fix-check.probes/) |
| P16 | `tldr fix check ... -l typescript --test-cmd 'false' --max-attempts 1` | lang-mismatch | 1 | [`16-lang-mismatch.*`](./fix-check.probes/) |
| P17 | `tldr fix check -f buggy.py --test-cmd 'true' -f compact` | **`-f` CLASH: clap interprets BOTH as --file** | 2 | [`17-short-f-ambiguity.*`](./fix-check.probes/) |
| P18 | `tldr fix check --file buggy.py -t 'true'` | -t short for --test-cmd | 0 | [`18-short-t-test-cmd.*`](./fix-check.probes/) |
| P19 | `tldr fix check ... -q --test-cmd 'true'` | quiet | 0 | [`19-quiet.*`](./fix-check.probes/) |

### Observations

- **P01** — Failing test (`python` not in shell PATH): `attempts: [{ iteration: 1, error_code: "unparseable", message: "sh: python: command not found", fixed: false }]`, `final_pass: false, iterations: 1`. stderr: `"Error: Some errors could not be fixed after 1 attempt."` Exit `1`. **Even with `--max-attempts 5` default, only 1 attempt** because the error was unparseable.
- **P02** — `--test-cmd 'true'` (always passes): `attempts: [], final_pass: true, iterations: 1`. Exit `0`. The test was run once, succeeded immediately. NO fix attempts.
- **P03** — stderr `"error: the following required arguments were not provided: --test-cmd <TEST_CMD>"`, exit `2`.
- **P04** — stderr `"Error: Source file '/no/such/file.py' does not exist."`, exit `1`. **BEST error wording in fix group** — quotes the path AND uses explicit "does not exist" instead of raw OS error.
- **P05** — stderr `"Error: --format sarif not supported by fix. Use --format json. SARIF is only emitted by: vuln, clones."`, exit `1`. **Note message says "by fix" not "by fix check"** — the format validator is keyed on the parent subcommand, not the child.
- **P06** — **`--format text` BUG:** output is identical to default JSON. text-mode renderer apparently not implemented for fix check. Workaround: parse JSON.
- **P07** — `--format compact`: single-line minified JSON. Works correctly.
- **P08** — stderr `"Error: --format dot not supported by fix. ..."`, exit `1`. Same parent-keyed message.
- **P09** — `--max-attempts 1`: still exit 1, 1 attempt (unparseable, no fix).
- **P10** — `--max-attempts 0`: `attempts: [], iterations: 1, final_pass: false`. **The test STILL RAN ONCE** (iterations: 1) — but no fix attempts (max-attempts: 0). **Edge case:** max-attempts 0 ≠ "don't run test"; it means "don't try to fix after test fails."
- **P11** — Default `--max-attempts 5`: still 1 attempt because error is unparseable. The loop short-circuits.
- **P12** — `--test-cmd '/no/such/cmd'`: same shape as P01 (unparseable error).
- **P13** — `--test-cmd 'exit 1'`: empty stderr from the cmd, `error_code: "unparseable"`, `message: ""`. Exit 1.
- **P14** — clap-style: `"error: invalid value 'brainfuck' for '--lang <LANG>': Unknown language: brainfuck"`, exit `2`.
- **P15** — `-l python --test-cmd 'true'`: identical to P02 (passing test).
- **P16** — `-l typescript` with failing test: same shape — language doesn't gate the test command. 1 attempt, exit 1.
- **P17** — **`-f` AMBIGUITY:** `tldr fix check -f path -f compact` → clap interprets BOTH `-f` as `--file` (the local arg) and errors `"the argument '--file <FILE>' cannot be used multiple times"`. **CONFIRMED BUG-TRAP:** `-f` is `--file`, NOT `--format`, in this subcommand. To set format, use `--format` long-form OR set it on the parent `tldr` command (though that won't work due to clap subcommand parsing).
- **P18** — `-t 'true'`: short flag for `--test-cmd`. Works as expected.
- **P19** — `-q quiet`: identical output (no progress messages observed).

---

## Source Code Reality

**Target file(s):**
- `crates/tldr-cli/src/commands/fix.rs` (combined diagnose/apply/check; ~600+ lines)
- `crates/tldr-core/src/fix/...` (loop driver)
- `crates/tldr-cli/src/output.rs:113` (`validate_format_for_command`)

**Pinned to upstream commit:** `6c4011a` (release v0.4.0)

**Argument struct:**
```rust
// crates/tldr-cli/src/commands/fix.rs:66-79
#[derive(Debug, Args)]
pub struct FixCheckArgs {
    #[arg(long, short = 'f')] pub file: PathBuf,
    #[arg(long, short = 't')] pub test_cmd: String,
    #[arg(long, default_value = "5")] pub max_attempts: usize,
}
```
Reveals: **`--file` uses `-f` short**, which CONFLICTS with the global `-f --format`. clap resolves with subcommand-arg precedence — the local `--file` wins. P17 confirms.

**Format validation:** confirmed at `crates/tldr-cli/src/output.rs:113-163` — `fix` (parent) is in neither `SARIF_SUPPORTED` nor `DOT_SUPPORTED`. Note: the validator is keyed on `"fix"` (parent), not `"fix check"` (child) — error message uses `"by fix"`.

**No daemon route:** `grep -n try_daemon_route fix.rs` returns 0 matches.

**Loop behavior** (inferred from `run_check`):
1. Run `--test-cmd` via shell.
2. If exit 0: emit `final_pass: true, iterations: 1, attempts: []`, exit 0.
3. If exit non-zero: parse stderr into a diagnosis.
4. If parseable AND fix available: apply, re-run test, loop until `--max-attempts` OR test passes OR fix unavailable.
5. If unparseable: bail immediately (only 1 attempt — matches P01).

---

## Architectural Deep Dive

- **Under the hood:** Shells out to `--test-cmd` via `std::process::Command` with `sh -c`. Captures stderr. Parses errors via the shared `tldr fix diagnose` parser. Calls the shared `tldr fix apply` engine. Loops until pass / max-attempts / unfixable. Emits structured `attempts[]` log.
- **Performance:** Bounded by test-cmd runtime × max-attempts. The fix-apply engine itself is fast (~50ms).
- **LLM cognitive load:** A self-healing CI loop primitive. **In practice, fails fast** because the deterministic fix registry is small (per fix-apply audit findings). Best paired with `tldr fix diagnose` upstream — fix check is for end-to-end CI workflows where a known-fixable pattern (e.g., TS2304 missing import) blocks tests.

---

## Intent & Routing

- **User/Agent Goal:** auto-fix-and-retest loop — run tests, diagnose failures, apply known fixes, re-run until success or attempt limit.
- **When to choose this over similar tools:**
  - Over `tldr fix apply`: apply is one-shot; check loops.
  - Over `tldr fix diagnose`: diagnose just parses; check executes the full loop.
  - Over manual rerun: ZERO setup if your error pattern matches the deterministic registry.
- **Prerequisites (composition):**
  - `--file` MUST exist.
  - `--test-cmd` MUST be runnable via `sh -c`.
  - The error pattern must be in the deterministic-fix registry (small set) — else loop ends after 1 unparseable attempt.

---

## Agent Synthesis

> **How to use `tldr fix check`:**
> Auto-fix + retest loop. `tldr fix check --file <FILE> --test-cmd <CMD>` runs `<CMD>`, parses failures, applies fixes via the shared `tldr fix apply` engine, and re-runs until success or `--max-attempts 5` (default). Returns JSON `{ file, test_cmd, attempts: [{ iteration, error_code, message, fixed, description }], final_pass, iterations }`. `attempts` is empty when the test passes immediately (P02). Default JSON; **`--format text` is BROKEN (emits JSON)**; `--format compact` works; `sarif`/`dot` rejected. Exit codes: 0 test-passed, 1 test-failed-after-attempts / bad-file / unparseable-error / format-reject, 2 missing --file/--test-cmd / `-f` ambiguity / bad-lang.
>
> **Crucial Rules:**
> - **`-f` IS `--file`, NOT `--format`.** P17: `tldr fix check -f buggy.py -f compact` → clap error `"argument '--file <FILE>' cannot be used multiple times"`. The local `--file -f` shadows the global `--format -f`. **To set output format, ALWAYS use `--format` long-form** (`--format compact` not `-f compact`).
> - **`--format text` is BROKEN** (P06: emits JSON identical to default). Compact and JSON work. Workaround: parse JSON or use compact.
> - **Unparseable error → 1 attempt, exit 1, regardless of --max-attempts.** P01, P11: with default `--max-attempts 5`, but error is `error_code: "unparseable"`, the loop bails after 1 attempt. **Recovery hint:** ensure your test command emits parseable errors (Python tracebacks, Rust E0xxx, TS2xxx, etc.).
> - **`--max-attempts 0`** doesn't skip the test — it runs the test ONCE (`iterations: 1`) and skips ALL fix attempts. Exit 1 if test fails, exit 0 if test passes. **Edge case:** use 0 to verify "test runs successfully without any fixes needed."
> - **Bad source-file error is BEST IN FIX GROUP:** `"Error: Source file '<path>' does not exist."` (P04). Quotes the path AND uses explicit "does not exist" instead of raw OS error (compare `tldr fix apply`'s `"Failed to read source file ... os error 2"`).
> - **Format-reject message is keyed on the PARENT subcommand.** P05: `"--format sarif not supported by fix"` (NOT `"by fix check"`). The validator looks up the parent. Cosmetic, but agents parsing the error string should expect `"fix"`.
> - **Test command runs via `sh -c`.** P12: `--test-cmd '/no/such/cmd'` returns shell error "command not found" parsed as unparseable. Works for any shell-runnable command — pytest, npm test, cargo test, etc.
> - **`attempts[].fixed: false`** indicates the iteration did NOT apply a fix (either no fix available or error unparseable). Filter `attempts | map(select(.fixed == true))` to see what was actually changed.
> - **`final_pass: true, attempts: []`** is the "everything was fine" sentinel (P02). Use this to detect "test passes without any auto-fix" workflows.
> - **`iterations` is 1-indexed and counts test runs, NOT fix attempts.** `iterations` can be > 0 even with empty `attempts[]` (test ran once, passed).
> - **NO daemon route.** Test commands run in fresh subprocesses each iteration.
>
> **Command:** `tldr fix check --file <FILE> --test-cmd <CMD>`
>
> **With common flags:** `tldr fix check --file src/app.py --test-cmd "pytest tests/" --max-attempts 3 --format compact | jq '{ passed: .final_pass, fixed_count: ([.attempts[] | select(.fixed)] | length) }'` (use for CI: report whether the loop healed the test and how many fixes were applied).
