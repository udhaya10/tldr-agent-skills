# tldr fix check

> **Before writing the Usage block**: check `verified-invocations.md` in this group's
> `tool-cards/fix/` directory and copy the canonical syntax verbatim.
> Do NOT reconstruct syntax from prose — that is how hallucinated flags get introduced.

**Pitch**: End-to-end test → diagnose → apply → retest loop, bounded by `--max-attempts`, returning a structured log of each attempt and whether the test eventually passed.

**Why reach for it**
- Closes the loop that `fix diagnose` + `fix apply` only do single-shot — runs the test command, parses the failure, applies a registry fix, re-runs, repeats
- `attempts[]` array logs every iteration with `error_code`, `fixed: bool`, and a description — easy to filter "what actually got changed"
- `final_pass: true, attempts: []` is the clean "test was already green" signal
- Works with any shell-runnable test command (`pytest`, `npm test`, `cargo test`, anything via `sh -c`)

**When to use**
- A known-fixable error pattern (e.g., TS2304 missing import) is blocking the test suite and an agent wants the registry to heal it without human attention
- Wrapping a CI step where the agent should retry up to N times before failing the build
- Verifying "test passes without any auto-fix needed" — pass `--max-attempts 0` to run the test exactly once and skip all repair attempts

**When NOT to use**
- The error pattern isn't in the deterministic registry — the loop bails after 1 unparseable attempt regardless of `--max-attempts`
- One-shot diagnosis is enough — use `tldr fix diagnose` (no test execution)
- Just trying to detect findings in a diff — use `tldr bugbot` (no test loop, no fix attempts)

**Usage (copy from `verified-invocations.md` — do not reconstruct)**:
```
tldr fix check [OPTIONS] --file <FILE> --test-cmd <TEST_CMD>
tldr fix check --file <buggy.py> --test-cmd 'python -c "import buggy; buggy.compute(5)"'
tldr fix check --file <buggy.py> -t 'true'
```

**Output in plain words**: A JSON report with the source file (absolute), the test command verbatim, an `attempts[]` array (each entry has iteration, parsed error code, message, whether a fix was applied, and what it was), a `final_pass` boolean, and the total `iterations` count.

**Killer detail**: `-f` is `--file`, NOT `--format` — the local short flag shadows the global. `tldr fix check -f buggy.py -f compact` errors with `"argument '--file <FILE>' cannot be used multiple times"`. Always use `--format` long-form to set output format on this subcommand; and note that `--format text` is broken anyway (silently emits JSON), so reach for `--format compact` when you want one line.

**Source**: `research/tldr/fix/fix-check.md`
