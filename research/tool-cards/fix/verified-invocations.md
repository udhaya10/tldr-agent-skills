# Verified CLI Invocations — `fix` group

> **Protocol**: Before writing a `Usage:` block in any tool card or SKILL.md for commands
> in this group, copy the canonical syntax from this document. Do NOT reconstruct syntax
> from prose — that is how hallucinated flags get introduced.
>
> All probes in this document were run against a real codebase (Stock-Monitor,
> tldr-code v0.4.0) and their outputs are captured in the `.probes/` directories
> alongside the dossiers. Probe types: `happy` = working/verified, `failure` = error case.

---

## `tldr bugbot check`

**Canonical syntax (from `tldr bugbot check --help`):**
```
tldr bugbot check [OPTIONS] [PATH]
```

> **Note**: `tldr bugbot` is a subcommand dispatcher. The only current subcommand is `check`.
> Running `tldr bugbot` alone (without `check`) returns an error.

| # | Command | Type |
|---|---------|------|
| P01 | `tldr bugbot check` | happy |
| P02 | `tldr bugbot check . --no-tools` | happy-scale — fast, no external tools |
| P03 | `tldr bugbot` | failure — missing subcommand |
| P04 | `tldr bugbot check /no/such/dir --no-tools` | failure — bad path |
| P05 | `tldr bugbot check . --no-tools -f sarif` | failure — format rejected |
| P06 | `tldr bugbot check . --no-tools -f text` | happy — text format |
| P07 | `tldr bugbot check . --no-tools -f compact` | happy — compact format |
| P08 | `tldr bugbot check . --no-tools -f dot` | failure — format rejected |
| P09 | `tldr bugbot check . --no-tools --base-ref HEAD~1` | happy — diff against HEAD~1 |
| P10 | `tldr bugbot check . --no-tools --base-ref not-a-ref` | failure — bad base ref |
| P11 | `tldr bugbot check . --no-tools --staged` | happy — staged changes only |
| P12 | `tldr bugbot check . --no-tools --max-findings 1` | happy — cap findings at 1 |
| P13 | `tldr bugbot check . --no-tools --max-findings 0` | failure — zero max findings |
| P14 | `tldr bugbot check . --no-tools --no-fail` | happy — always exit 0 |
| P15 | `tldr bugbot check . --tool-timeout 1` | happy — short tool timeout |
| P16 | `tldr bugbot check . --no-tools -l brainfuck` | failure — bad lang |
| P17 | `tldr bugbot check . --no-tools -l python` | happy — lang python |
| P18 | `tldr bugbot check . --no-tools -l typescript` | failure — lang mismatch |
| P19 | `tldr bugbot check . --no-tools -q` | happy — quiet |
| P20 | `tldr bugbot check /tmp/non-git-dir --no-tools` | failure — not a git repo |
| P21 | `tldr bugbot check /tmp/empty-dir --no-tools` | failure — empty dir |

---

## `tldr diagnostics`

**Canonical syntax (from `tldr diagnostics --help`):**
```
tldr diagnostics [OPTIONS] [PATH]
```

| # | Command | Type |
|---|---------|------|
| P01 | `tldr diagnostics backend/providers/yahoo.py --timeout 10` | happy |
| P02 | `tldr diagnostics backend/providers --timeout 10` | happy-scale |
| P03 | (PATH defaults to `.` — no required arg) | N/A |
| P04 | `tldr diagnostics /no/such/dir --timeout 10` | failure — bad path |
| P05 | `tldr diagnostics backend/providers/yahoo.py --timeout 10 -f sarif` | failure — format rejected |
| P06 | `tldr diagnostics backend/providers/yahoo.py --timeout 10 -f text` | happy — text format |
| P07 | `tldr diagnostics backend/providers/yahoo.py --timeout 10 -f compact` | happy — compact format |
| P08 | `tldr diagnostics backend/providers/yahoo.py --timeout 10 -f dot` | failure — format rejected |
| P09 | `tldr diagnostics backend/providers/yahoo.py --tools ruff --timeout 10` | happy — specific tool |
| P10 | `tldr diagnostics backend/providers/yahoo.py --tools wat --timeout 10` | failure — bad tool name |
| P11 | `tldr diagnostics backend/providers/yahoo.py --no-typecheck --timeout 10` | happy — skip typecheck |
| P12 | `tldr diagnostics backend/providers/yahoo.py --no-lint --timeout 10` | happy — skip lint |
| P13 | `tldr diagnostics backend/providers/yahoo.py -s error --tools ruff --timeout 10` | happy — severity filter |
| P14 | `tldr diagnostics backend/providers/yahoo.py -s wat` | failure — bad severity |
| P15 | `tldr diagnostics backend/providers/yahoo.py --tools ruff --ignore E501,F401 --timeout 10` | happy — ignore codes |
| P16 | `tldr diagnostics backend/providers/yahoo.py --tools ruff --output sarif --timeout 10` | happy — sarif output |
| P17 | `tldr diagnostics backend/providers/yahoo.py --tools ruff --output github-actions --timeout 10` | happy — github-actions output |
| P18 | `tldr diagnostics backend/providers/yahoo.py --output wat` | failure — bad output format |
| P19 | `tldr diagnostics backend/providers/yahoo.py --project --tools ruff --timeout 10` | happy — project-wide mode |
| P20 | `tldr diagnostics backend/providers/yahoo.py --tools ruff --strict --timeout 10` | happy — strict mode |
| P21 | `tldr diagnostics backend/providers/yahoo.py --timeout 1` | failure — timeout too short |
| P22 | `tldr diagnostics backend/providers/yahoo.py --tools ruff -l brainfuck` | failure — bad lang |
| P23 | `tldr diagnostics backend/providers/yahoo.py --tools ruff -l python --timeout 10` | happy — lang python |
| P24 | `tldr diagnostics /tmp/empty-dir --timeout 5` | failure — empty dir |
| P25 | `tldr diagnostics README.md --timeout 5` | failure — non-source file |
| P26 | `tldr diagnostics backend/providers/yahoo.py --tools ruff -q --timeout 10` | happy — quiet |

---

## `tldr fix apply`

**Canonical syntax (from `tldr fix apply --help`):**
```
tldr fix apply [OPTIONS] --source <SOURCE>
```

> **Note**: This is a subcommand of `tldr fix`. Invoke as `tldr fix apply`, NOT `tldr fix-apply`.
> The `--source` flag (`-s`) is REQUIRED.

| # | Command | Type |
|---|---------|------|
| P01 | `tldr fix apply -s <file> -e "NameError: name 'valeu' is not defined. Did you mean: 'value'?"` | happy |
| P02 | `tldr fix apply -s <file> --error-file <error.txt>` | happy-scale — error from file |
| P03 | `tldr fix apply -e "NameError: name 'valeu' is not defined. Did you mean: 'value'?"` | failure — missing --source |
| P04 | `tldr fix apply -s /no/such/file.py -e "NameError: name 'valeu' is not defined. Did you mean: 'value'?"` | failure — bad path |
| P05 | `tldr fix apply -s <file> -e "<error>" -f sarif` | failure — format rejected |
| P06 | `tldr fix apply -s <file> -e "<error>" -f text` | happy — text format |
| P07 | `tldr fix apply -s <file> -e "<error>" -f compact` | happy — compact format |
| P08 | `tldr fix apply -s <file> -e "<error>" -f dot` | failure — format rejected |
| P09 | `tldr fix apply -s <file> -e "<error>" -d` | happy — show diff only |
| P10 | `tldr fix apply -s <file> -e "<error>" -o /tmp/patched.py` | happy — write to output file |
| P11 | `tldr fix apply -s /tmp/buggy.py -e "<error>" -i` | happy — in-place patch |
| P12 | `cat error.txt \| tldr fix apply -s <file> --stdin` | happy — error from stdin |
| P13 | `tldr fix apply -s <file> < /dev/null` | failure — no error input |
| P14 | `tldr fix apply -s <file> -e "<error>" --error-file <file>` | failure — -e and --error-file conflict |
| P15 | `tldr fix apply -s <file> --error-file /no/such/error.txt` | failure — bad error file |
| P16 | `tldr fix apply -s <file> -e "<error>" --api-surface /no/such/api.json` | failure — bad api-surface |
| P17 | `tldr fix apply -s <file> -e "<error>" -l brainfuck` | failure — bad lang |
| P18 | `tldr fix apply -s <file> -e "<error>" -l python` | happy — lang python |
| P19 | `tldr fix apply -s <file> -e "<error>" -l typescript` | failure — lang mismatch |
| P20 | `tldr fix apply -s <file> -e "NameError: foo not defined"` | happy — unrelated error (patch attempted) |
| P21 | `tldr fix apply -s <file> -e "<error>" -q` | happy — quiet |

---

## `tldr fix check`

**Canonical syntax (from `tldr fix check --help`):**
```
tldr fix check [OPTIONS] --file <FILE> --test-cmd <TEST_CMD>
```

> **Note**: This is a subcommand of `tldr fix`. Invoke as `tldr fix check`, NOT `tldr fix-check`.
> Both `--file` and `--test-cmd` (or `-t`) are REQUIRED.
> **Warning**: `-f` is ambiguous — it matches both `--file` and `--format`. Use `--file` explicitly.

| # | Command | Type |
|---|---------|------|
| P01 | `tldr fix check --file <buggy.py> --test-cmd 'python -c "import buggy; buggy.compute(5)"'` | happy |
| P02 | `tldr fix check --file <buggy.py> --test-cmd 'true'` | happy-scale — always-pass test |
| P03 | `tldr fix check --file <buggy.py>` | failure — missing --test-cmd |
| P04 | `tldr fix check --file /no/such/file.py --test-cmd 'true'` | failure — bad path |
| P05 | `tldr fix check --file <buggy.py> --test-cmd 'true' --format sarif` | failure — format rejected |
| P06 | `tldr fix check --file <buggy.py> --test-cmd 'true' --format text` | happy — text format |
| P07 | `tldr fix check --file <buggy.py> --test-cmd 'true' --format compact` | happy — compact format |
| P08 | `tldr fix check --file <buggy.py> --test-cmd 'true' --format dot` | failure — format rejected |
| P09 | `tldr fix check --file <buggy.py> --test-cmd 'false' --max-attempts 1` | happy — one attempt, fails |
| P10 | `tldr fix check --file <buggy.py> --test-cmd 'false' --max-attempts 0` | failure — zero attempts |
| P11 | `tldr fix check --file <buggy.py> --test-cmd 'false'` | happy — default attempts, exhausted |
| P12 | `tldr fix check --file <buggy.py> --test-cmd '/no/such/command'` | failure — bad test command |
| P13 | `tldr fix check --file <buggy.py> --test-cmd 'exit 1'` | happy — test always fails (exhausts attempts) |
| P14 | `tldr fix check --file <buggy.py> --test-cmd 'true' -l brainfuck` | failure — bad lang |
| P15 | `tldr fix check --file <buggy.py> --test-cmd 'true' -l python` | happy — lang python |
| P16 | `tldr fix check --file <buggy.py> --test-cmd 'false' -l typescript --max-attempts 1` | failure — lang mismatch |
| P17 | `tldr fix check -f <buggy.py> --test-cmd 'true' -f compact` | failure — -f ambiguity (file vs format) |
| P18 | `tldr fix check --file <buggy.py> -t 'true'` | happy — -t short for --test-cmd |
| P19 | `tldr fix check --file <buggy.py> --test-cmd 'true' -q` | happy — quiet |

---

## `tldr fix diagnose`

**Canonical syntax (from `tldr fix diagnose --help`):**
```
tldr fix diagnose [OPTIONS] --source <SOURCE>
```

> **Note**: This is a subcommand of `tldr fix`. Invoke as `tldr fix diagnose`, NOT `tldr fix-diagnose`.
> The `--source` flag (`-s`) is REQUIRED. Returns diagnosis only — no file is modified (use `fix apply` to patch).

| # | Command | Type |
|---|---------|------|
| P01 | `tldr fix diagnose -s <file> -e "NameError: name 'valeu' is not defined. Did you mean: 'value'?"` | happy |
| P02 | `tldr fix diagnose -s <file> --error-file <error.txt>` | happy-scale — error from file |
| P03 | `tldr fix diagnose -e "NameError: name 'valeu' is not defined. Did you mean: 'value'?"` | failure — missing --source |
| P04 | `tldr fix diagnose -s /no/such/file.py -e "<error>"` | failure — bad path |
| P05 | `tldr fix diagnose -s <file> -e "<error>" -f sarif` | failure — format rejected |
| P06 | `tldr fix diagnose -s <file> -e "<error>" -f text` | happy — text format |
| P07 | `tldr fix diagnose -s <file> -e "<error>" -f compact` | happy — compact format |
| P08 | `tldr fix diagnose -s <file> -e "<error>" -f dot` | failure — format rejected |
| P09 | `cat error.txt \| tldr fix diagnose -s <file> --stdin` | happy — error from stdin |
| P10 | `tldr fix diagnose -s <file> < /dev/null` | failure — no error input |
| P11 | `tldr fix diagnose -s <file> -e "<error>" --error-file <file>` | failure — -e and --error-file conflict |
| P12 | `tldr fix diagnose -s <file> --error-file /no/such/error.txt` | failure — bad error file |
| P13 | `tldr fix diagnose -s <file> -e "<error>" --api-surface /no/such/api.json` | failure — bad api-surface |
| P14 | `tldr fix diagnose -s <file> -e "<error>" -l brainfuck` | failure — bad lang |
| P15 | `tldr fix diagnose -s <file> -e "<error>" -l python` | happy — lang python |
| P16 | `tldr fix diagnose -s <file> -e "<error>" -l typescript` | failure — lang mismatch |
| P17 | `tldr fix diagnose -s <file> -e 'some random garbage text'` | happy — unparseable error (best-effort) |
| P18 | `tldr fix diagnose -s <file> --error-file <error.txt> -f text` | happy — error with location |
| P19 | `tldr fix diagnose -s <file> -e "<error>" -q` | happy — quiet |
