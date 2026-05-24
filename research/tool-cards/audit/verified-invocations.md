# Verified CLI Invocations — `audit` group

> **Protocol**: Before writing a `Usage:` block in any tool card or SKILL.md for commands
> in this group, copy the canonical syntax from this document. Do NOT reconstruct syntax
> from prose — that is how hallucinated flags get introduced.
>
> All probes in this document were run against a real codebase (Stock-Monitor,
> tldr-code v0.4.0) and their outputs are captured in the `.probes/` directories
> alongside the dossiers. Probe types: `happy` = working/verified, `failure` = error case.
>
> **Format special cases** (differ from the defaults json/text/compact):
> - `tldr clones` accepts `sarif` and `dot` in addition to the standard three
> - `tldr vuln` and `tldr secure` accept `sarif`
> - All other audit commands reject `sarif` and `dot`

---

## `tldr api-check`

**Canonical syntax (from `tldr api-check --help`):**
```
tldr api-check [OPTIONS] <path>
```

| # | Command | Type |
|---|---------|------|
| P01 | `tldr api-check backend/providers` | happy |
| P02 | `tldr api-check backend` | happy-scale |
| P03 | `tldr api-check` | failure — missing path arg |
| P04 | `tldr api-check /no/such/dir` | failure — bad path |
| P05 | `tldr api-check backend/providers -f sarif` | failure — format rejected |
| P06 | `tldr api-check backend/providers -f text` | happy — text format |
| P07 | `tldr api-check backend/providers -f compact` | happy — compact format |
| P08 | `tldr api-check backend/providers -f dot` | failure — format rejected |
| P09 | `tldr api-check backend --category security` | happy — security category |
| P10 | `tldr api-check backend/providers --category wat` | failure — bad category |
| P11 | `tldr api-check backend --severity high` | happy — severity filter |
| P12 | `tldr api-check backend/providers --severity over9000` | failure — bad severity |
| P13 | `tldr api-check backend --category 'crypto,security,resources'` | happy — multi-category |
| P14 | `tldr api-check backend/providers/yahoo.py` | happy — file arg |
| P15 | `tldr api-check backend -l python` | happy — lang python |
| P16 | `tldr api-check backend/providers -l typescript` | failure — lang mismatch |
| P17 | `tldr api-check backend/providers -l brainfuck` | failure — bad lang |
| P18 | `tldr api-check backend/providers -O /tmp/out.json` | happy — output file |
| P19 | `tldr api-check backend/providers -q` | happy — quiet |

---

## `tldr churn`

**Canonical syntax (from `tldr churn --help`):**
```
tldr churn [OPTIONS] [PATH]
```

> **Note**: Requires a git repo. Fails on non-git directories.

| # | Command | Type |
|---|---------|------|
| P01 | `tldr churn` | happy — current dir |
| P02 | `tldr churn . --days 1000 --top 50` | happy-scale |
| P03 | (PATH defaults to `.` — no required arg) | N/A |
| P04 | `tldr churn /no/such/dir` | failure — bad path |
| P05 | `tldr churn -f sarif` | failure — format rejected |
| P06 | `tldr churn -f text` | happy — text format |
| P07 | `tldr churn -f compact` | happy — compact format |
| P08 | `tldr churn -f dot` | failure — format rejected |
| P09 | `tldr churn --days 30` | happy — last 30 days |
| P10 | `tldr churn --days 99999` | happy — all history |
| P11 | `tldr churn --top 1` | happy — top 1 file |
| P12 | `tldr churn --authors` | happy — include author breakdown |
| P13 | `tldr churn --exclude '*.md' --exclude 'venv/**'` | happy — exclude patterns |
| P14 | `tldr churn /tmp/non-git-dir` | failure — not a git repo |
| P15 | `tldr churn /tmp/empty-dir` | failure — empty dir |
| P16 | `tldr churn -l brainfuck` | failure — bad lang |
| P17 | `tldr churn -q --days 30` | happy — quiet |
| P18 | `tldr churn --hotspots` | happy — hotspots mode (combines churn + complexity) |
| P19 | `tldr churn backend/providers/yahoo.py` | happy — single file |

---

## `tldr clones`

**Canonical syntax (from `tldr clones --help`):**
```
tldr clones [OPTIONS] [PATH]
```

> **Format note**: `clones` accepts `sarif` and `dot` in addition to json/text/compact — unique in the audit group.

| # | Command | Type |
|---|---------|------|
| P01 | `tldr clones backend/providers` | happy |
| P02 | `tldr clones backend/providers --threshold 0.5` | happy-scale — lower threshold |
| P03 | (PATH defaults to `.` — no required arg) | N/A |
| P04 | `tldr clones /no/such/dir` | failure — bad path |
| P05 | `tldr clones backend/providers -f wat` | failure — unknown format |
| P06 | `tldr clones backend/providers -f text` | happy — text format |
| P07 | `tldr clones backend/providers -f compact` | happy — compact format |
| P08 | `tldr clones backend/providers -f sarif` | happy — sarif (clones-specific) |
| P09 | `tldr clones backend/providers -f dot` | happy — dot (clones-specific) |
| P10 | `tldr clones backend/providers --threshold 0.99` | happy — high threshold (exact only) |
| P11 | `tldr clones backend/providers --threshold 0.0` | happy — all fragments (very noisy) |
| P12 | `tldr clones backend/providers --min-tokens 100` | happy — min token count |
| P13 | `tldr clones backend/providers --min-lines 50` | happy — min line count |
| P14 | `tldr clones backend/providers --type-filter 1` | happy — Type-1 clones only |
| P15 | `tldr clones backend/providers --type-filter wat` | failure — bad type filter |
| P16 | `tldr clones backend/providers --normalize none` | happy — no normalization |
| P17 | `tldr clones backend/providers --normalize wat` | failure — bad normalize value |
| P18 | `tldr clones backend/providers --language python` | happy — local language flag |
| P19 | `tldr clones backend/providers --language typescript` | failure — lang mismatch |
| P20 | `tldr clones backend/providers -l python` | happy — global lang flag |
| P21 | `tldr clones backend/providers --include-within-file` | happy — within-file clones |
| P22 | `tldr clones backend/providers --show-classes` | happy — show clone class groupings |
| P23 | `tldr clones backend/providers --max-clones 1` | happy — limit clone count |
| P24 | `tldr clones backend/providers --max-files 1` | happy — limit file count |
| P25 | `tldr clones backend/providers --exclude-tests --exclude-generated` | happy — exclusion flags |
| P26 | `tldr clones backend/providers -o sarif` | happy — legacy output flag |
| P27 | `tldr clones backend/providers -q` | happy — quiet |

---

## `tldr cognitive`

**Canonical syntax (from `tldr cognitive --help`):**
```
tldr cognitive [OPTIONS] [PATH]
```

| # | Command | Type |
|---|---------|------|
| P01 | `tldr cognitive backend/providers/yahoo.py` | happy |
| P02 | `tldr cognitive backend/providers` | happy-scale |
| P03 | (PATH defaults to `.` — no required arg) | N/A |
| P04 | `tldr cognitive /no/such/dir` | failure — bad path |
| P05 | `tldr cognitive backend/providers -f sarif` | failure — format rejected |
| P06 | `tldr cognitive backend/providers -f text` | happy — text format |
| P07 | `tldr cognitive backend/providers -f compact` | happy — compact format |
| P08 | `tldr cognitive backend/providers -f dot` | failure — format rejected |
| P09 | `tldr cognitive backend/providers/yahoo.py --function fetch_historical_data` | happy — single function |
| P10 | `tldr cognitive backend/providers/yahoo.py --function no_such_function` | failure — function not found |
| P11 | `tldr cognitive backend/providers --threshold 0` | happy — all functions |
| P12 | `tldr cognitive backend/providers --threshold 9999` | happy — only very complex functions |
| P13 | `tldr cognitive backend/providers --high-threshold 5 --threshold 1` | happy — custom high threshold |
| P14 | `tldr cognitive backend/providers/yahoo.py --show-contributors --function fetch_historical_data` | happy — show nesting contributors |
| P15 | `tldr cognitive backend/providers --include-cyclomatic` | happy — add cyclomatic alongside cognitive |
| P16 | `tldr cognitive backend/providers --top 1` | happy — top N most complex |
| P17 | `tldr cognitive backend/providers --top 0` | failure — top zero |
| P18 | `tldr cognitive backend/providers --exclude '*.test.py' --exclude '__init__.py'` | happy — exclusions |
| P19 | `tldr cognitive backend/providers --max-files 1` | happy — max-files limit |
| P20 | `tldr cognitive backend/providers --include-hidden` | happy — include hidden files |
| P21 | `tldr cognitive backend/providers -l brainfuck` | failure — bad lang |
| P22 | `tldr cognitive backend/providers -l typescript` | failure — lang mismatch |
| P23 | `tldr cognitive backend/providers -q` | happy — quiet |
| P24 | `tldr cognitive /tmp/empty-dir` | failure — empty dir |

---

## `tldr cohesion`

**Canonical syntax (from `tldr cohesion --help`):**
```
tldr cohesion [OPTIONS] <PATH>
```

> **Note**: `PATH` is required (no default). Works only on files/dirs containing classes. Returns empty result (not error) when no classes are present.

| # | Command | Type |
|---|---------|------|
| P01 | `tldr cohesion backend/providers/base.py` | happy |
| P02 | `tldr cohesion backend/providers` | happy-scale |
| P03 | `tldr cohesion` | failure — missing path arg |
| P04 | `tldr cohesion /no/such/dir` | failure — bad path |
| P05 | `tldr cohesion backend/providers -f sarif` | failure — format rejected |
| P06 | `tldr cohesion backend/providers -f text` | happy — text format |
| P07 | `tldr cohesion backend/providers -f compact` | happy — compact format |
| P08 | `tldr cohesion backend/providers -f dot` | failure — format rejected |
| P09 | `tldr cohesion backend/providers --min-methods 10` | happy — min methods filter |
| P10 | `tldr cohesion backend/providers --min-methods 0` | failure — min methods zero |
| P11 | `tldr cohesion backend/providers --include-dunder` | happy — include dunder methods |
| P12 | `tldr cohesion backend --timeout 1` | happy — short timeout |
| P13 | `tldr cohesion backend/providers/base.py --project-root backend` | happy — project root hint |
| P14 | `tldr cohesion backend/providers -l brainfuck` | failure — bad lang |
| P15 | `tldr cohesion backend/providers -l typescript` | failure — lang mismatch |
| P16 | `tldr cohesion backend/providers -q` | happy — quiet |
| P17 | `tldr cohesion /tmp/empty-dir` | failure — empty dir |
| P18 | `tldr cohesion README.md` | failure — non-Python file |
| P19 | `tldr cohesion backend/db.py` | happy — no classes (empty result, not error) |

---

## `tldr complexity`

**Canonical syntax (from `tldr complexity --help`):**
```
tldr complexity [OPTIONS] <FILE> <FUNCTION>
```

> **Note**: Both FILE and FUNCTION are required positional arguments. For directory-wide complexity, use `tldr cognitive` instead.

| # | Command | Type |
|---|---------|------|
| P01 | `tldr complexity backend/providers/yahoo.py _to_finite_float` | happy |
| P02 | `tldr complexity backend/providers/yahoo.py fetch_historical_data` | happy-scale |
| P03 | `tldr complexity backend/providers/yahoo.py` | failure — missing function arg |
| P04 | `tldr complexity /no/such/file.py some_fn` | failure — bad path |
| P05 | `tldr complexity backend/providers/yahoo.py _to_finite_float -f sarif` | failure — format rejected |
| P06 | `tldr complexity backend/providers/yahoo.py _to_finite_float -f text` | happy — text format |
| P07 | `tldr complexity backend/providers/yahoo.py _to_finite_float -f compact` | happy — compact format |
| P08 | `tldr complexity backend/providers/yahoo.py _to_finite_float -f dot` | failure — format rejected |
| P09 | `tldr complexity backend/providers/yahoo.py no_such_function` | failure — function not found |
| P10 | `tldr complexity backend/providers/yahoo.py _to_finite_float -l brainfuck` | failure — bad lang |
| P11 | `tldr complexity README.md anything` | failure — non-source file |
| P12 | `tldr complexity backend anything` | failure — directory as file arg |
| P13 | `tldr complexity backend/providers/yahoo.py _to_finite_float -l python` | happy — lang python |
| P14 | `tldr complexity backend/providers/yahoo.py _to_finite_float -l typescript` | failure — lang mismatch |
| P15 | `tldr complexity backend/providers/yahoo.py _to_finite_float -q` | happy — quiet |
| P16 | `tldr complexity backend/providers/yahoo.py fetch_historical_data` | happy — cold daemon |
| P17 | `tldr complexity backend/providers/yahoo.py fetch_historical_data` | happy — warm daemon |

---

## `tldr contracts`

**Canonical syntax (from `tldr contracts --help`):**
```
tldr contracts [OPTIONS] <FILE> <FUNCTION>
```

> **Note**: Both FILE and FUNCTION are required. Infers pre/postconditions from guard clauses, assertions, and isinstance checks — not from docstrings.

| # | Command | Type |
|---|---------|------|
| P01 | `tldr contracts backend/providers/yahoo.py _to_finite_float` | happy |
| P02 | `tldr contracts backend/providers/yahoo.py fetch_historical_data` | happy-scale |
| P03 | `tldr contracts backend/providers/yahoo.py` | failure — missing function arg |
| P04 | `tldr contracts /no/such/file.py some_fn` | failure — bad path |
| P05 | `tldr contracts backend/providers/yahoo.py _to_finite_float -f sarif` | failure — format rejected |
| P06 | `tldr contracts backend/providers/yahoo.py _to_finite_float -f text` | happy — text format |
| P07 | `tldr contracts backend/providers/yahoo.py _to_finite_float -f compact` | happy — compact format |
| P08 | `tldr contracts backend/providers/yahoo.py _to_finite_float -f dot` | failure — format rejected |
| P09 | `tldr contracts backend/providers/yahoo.py no_such_function` | failure — function not found |
| P10 | `tldr contracts backend/providers/yahoo.py fetch_historical_data --limit 1` | happy — limit contracts |
| P11 | `tldr contracts backend/providers/yahoo.py fetch_historical_data --limit 0` | failure — limit zero |
| P12 | `tldr contracts backend/providers/yahoo.py _to_finite_float -l brainfuck` | failure — bad lang |
| P13 | `tldr contracts README.md anything` | failure — non-source file |
| P14 | `tldr contracts backend anything` | failure — directory as file arg |
| P15 | `tldr contracts backend/providers/yahoo.py _to_finite_float -l python` | happy — lang python |
| P16 | `tldr contracts backend/providers/yahoo.py _to_finite_float -l typescript` | failure — lang mismatch |
| P17 | `tldr contracts backend/providers/yahoo.py _to_finite_float -o text` | happy — output flag |
| P18 | `tldr contracts backend/providers/yahoo.py _to_finite_float -q` | happy — quiet |
| P19 | `tldr contracts backend/db.py get_connection` | happy — db function |

---

## `tldr coupling`

**Canonical syntax (from `tldr coupling --help`):**
```
tldr coupling [OPTIONS] <PATH_A> [PATH_B]
```

> **Note**: Measures function-call coupling (afferent/efferent, instability), NOT import-level dependencies. For import deps, use `tldr deps` or `tldr imports`.

| # | Command | Type |
|---|---------|------|
| P01 | `tldr coupling backend/providers/yahoo.py backend/providers/base.py` | happy — two-path mode |
| P02 | `tldr coupling backend/providers` | happy-scale — single-path mode |
| P03 | `tldr coupling` | failure — missing path arg |
| P04 | `tldr coupling /no/such/dir` | failure — bad path |
| P05 | `tldr coupling backend/providers -f sarif` | failure — format rejected |
| P06 | `tldr coupling backend/providers -f text` | happy — text format |
| P07 | `tldr coupling backend/providers -f compact` | happy — compact format |
| P08 | `tldr coupling backend/providers -f dot` | failure — format rejected |
| P09 | `tldr coupling backend --max-pairs 1` | happy — max pairs limit |
| P10 | `tldr coupling backend --top 3` | happy — top N coupled pairs |
| P11 | `tldr coupling backend --cycles-only` | happy — show only circular dependencies |
| P12 | `tldr coupling backend --include-tests` | happy — include test files |
| P13 | `tldr coupling backend --timeout 1` | happy — short timeout |
| P14 | `tldr coupling backend/providers/yahoo.py backend/providers/base.py --project-root backend` | happy — project root hint |
| P15 | `tldr coupling backend/providers -l brainfuck` | failure — bad lang |
| P16 | `tldr coupling backend/providers -l python` | happy — lang python |
| P17 | `tldr coupling backend/providers -l typescript` | failure — lang mismatch |
| P18 | `tldr coupling backend/providers -q` | happy — quiet |
| P19 | `tldr coupling /tmp/empty-dir` | failure — empty dir |
| P20 | `tldr coupling backend/providers/yahoo.py` | happy — single file |

---

## `tldr coverage`

**Canonical syntax (from `tldr coverage --help`):**
```
tldr coverage [OPTIONS] <REPORT>
```

> **Note**: Takes a REPORT file path (LCOV, Cobertura XML, or coverage.py JSON), NOT a source file path.
> Auto-detects format by default (`-R auto`). Supported formats: `lcov`, `cobertura`, `coveragepy`.

| # | Command | Type |
|---|---------|------|
| P01 | `tldr coverage <report.lcov>` | happy — LCOV report |
| P02 | `tldr coverage <report.lcov> --by-file --uncovered` | happy-scale |
| P03 | `tldr coverage` | failure — missing report arg |
| P04 | `tldr coverage /no/such/file.lcov` | failure — bad path |
| P05 | `tldr coverage <report.lcov> -f sarif` | failure — format rejected |
| P06 | `tldr coverage <report.lcov> -f text` | happy — text format |
| P07 | `tldr coverage <report.lcov> -f compact` | happy — compact format |
| P08 | `tldr coverage <report.lcov> -f dot` | failure — format rejected |
| P09 | `tldr coverage <report.xml> -R cobertura` | happy — cobertura format |
| P10 | `tldr coverage <coveragepy.json> -R coveragepy` | happy — coverage.py json format |
| P11 | `tldr coverage <report.lcov> -R lcov` | happy — explicit lcov |
| P12 | `tldr coverage <report.lcov> -R auto` | happy — auto-detect |
| P13 | `tldr coverage <report.lcov> -R cobertura` | failure — format mismatch |
| P14 | `tldr coverage <report.lcov> --threshold 100` | happy — 100% threshold (fail if below) |
| P15 | `tldr coverage <report.lcov> --threshold 0` | happy — always passes |
| P16 | `tldr coverage <report.lcov> --uncovered-only` | happy — show only uncovered lines |
| P17 | `tldr coverage <report.lcov> --filter 'src/main*' --by-file` | happy — glob filter |
| P18 | `tldr coverage <report.lcov> --sort asc --by-file` | happy — sort ascending |
| P19 | `tldr coverage <report.lcov> --sort desc --by-file` | happy — sort descending |
| P20 | `tldr coverage <report.lcov> --base-path /tmp --by-file` | happy — base path for relative paths |
| P21 | `tldr coverage <report.lcov> -R wat` | failure — bad report format |
| P22 | `tldr coverage <report.lcov> --sort wat` | failure — bad sort value |
| P23 | `tldr coverage <report.lcov> -q` | happy — quiet |
| P24 | `tldr coverage /tmp/empty.lcov` | failure — empty file |

---

## `tldr debt`

**Canonical syntax (from `tldr debt --help`):**
```
tldr debt [OPTIONS] [PATH]
```

| # | Command | Type |
|---|---------|------|
| P01 | `tldr debt backend/providers` | happy |
| P02 | `tldr debt backend` | happy-scale |
| P03 | (PATH defaults to `.` — no required arg) | N/A |
| P04 | `tldr debt /no/such/dir` | failure — bad path |
| P05 | `tldr debt backend/providers -f sarif` | failure — format rejected |
| P06 | `tldr debt backend/providers -f text` | happy — text format |
| P07 | `tldr debt backend/providers -f compact` | happy — compact format |
| P08 | `tldr debt backend/providers -f dot` | failure — format rejected |
| P09 | `tldr debt backend --category security` | happy — security category |
| P10 | `tldr debt backend --category wat` | failure — bad category |
| P11 | `tldr debt backend -k 1` | happy — top 1 item |
| P12 | `tldr debt backend -k 0` | failure — zero top |
| P13 | `tldr debt backend --min-debt 60` | happy — min debt threshold (minutes) |
| P14 | `tldr debt backend --min-debt 99999` | happy — very high threshold (likely empty) |
| P15 | `tldr debt backend --hourly-rate 100` | happy — custom hourly rate |
| P16 | `tldr debt backend/providers -l python` | happy — lang python |
| P17 | `tldr debt backend/providers -l typescript` | failure — lang mismatch |
| P18 | `tldr debt backend/providers -l brainfuck` | failure — bad lang |
| P19 | `tldr debt /tmp/empty-dir` | failure — empty dir |
| P20 | `tldr debt backend/providers -q` | happy — quiet |
| P21 | `tldr debt backend/providers/yahoo.py` | happy — single file |
| P22 | `tldr debt backend --category maintainability` | happy — maintainability category |

---

## `tldr halstead`

**Canonical syntax (from `tldr halstead --help`):**
```
tldr halstead [OPTIONS] [PATH]
```

| # | Command | Type |
|---|---------|------|
| P01 | `tldr halstead backend/providers/yahoo.py` | happy — single file |
| P02 | `tldr halstead backend/providers` | happy-scale |
| P03 | (PATH defaults to `.` — no required arg) | N/A |
| P04 | `tldr halstead /no/such/dir` | failure — bad path |
| P05 | `tldr halstead backend/providers -f sarif` | failure — format rejected |
| P06 | `tldr halstead backend/providers -f text` | happy — text format |
| P07 | `tldr halstead backend/providers -f compact` | happy — compact format |
| P08 | `tldr halstead backend/providers -f dot` | failure — format rejected |
| P09 | `tldr halstead backend/providers/yahoo.py --function fetch_historical_data` | happy — single function |
| P10 | `tldr halstead backend/providers/yahoo.py --function no_such_function` | failure — function not found |
| P11 | `tldr halstead backend/providers/yahoo.py --function fetch_historical_data --show-operators` | happy — show operators |
| P12 | `tldr halstead backend/providers/yahoo.py --function fetch_historical_data --show-operands` | happy — show operands |
| P13 | `tldr halstead backend/providers --threshold-volume 0` | happy — no volume threshold |
| P14 | `tldr halstead backend/providers --threshold-difficulty 0` | happy — no difficulty threshold |
| P15 | `tldr halstead backend --top 1` | happy — top 1 |
| P16 | `tldr halstead backend/providers --top 0` | failure — top zero |
| P17 | `tldr halstead backend/providers --exclude '__init__.py'` | happy — exclusion |
| P18 | `tldr halstead backend/providers --max-files 1` | happy — max-files limit |
| P19 | `tldr halstead backend/providers --include-hidden` | happy — include hidden |
| P20 | `tldr halstead backend/providers -l brainfuck` | failure — bad lang |
| P21 | `tldr halstead backend/providers -l typescript` | failure — lang mismatch |
| P22 | `tldr halstead backend/providers -q` | happy — quiet |
| P23 | `tldr halstead /tmp/empty-dir` | failure — empty dir |
| P24 | `tldr halstead README.md` | failure — non-source file |

---

## `tldr health`

**Canonical syntax (from `tldr health --help`):**
```
tldr health [OPTIONS] [PATH]
```

> **Note**: `--quick` skips slow analyses (coupling, similarity). `--detail coupling` and `--detail similarity` conflict with `--quick` and are silently ignored or error. Default (no `--quick`) runs all analyses — slow on large codebases.

| # | Command | Type |
|---|---------|------|
| P01 | `tldr health backend/providers --quick --summary` | happy |
| P02 | `tldr health backend --quick --summary` | happy-scale |
| P04 | `tldr health /no/such/path/definitely/missing` | failure — bad path |
| P05 | `tldr health backend/providers --quick -f sarif` | failure — format rejected |
| P06 | `tldr health backend/providers --quick -f text` | happy — text format |
| P07 | `tldr health backend/providers --quick --detail complexity` | happy — complexity detail |
| P08 | `tldr health backend/providers --quick --detail bogus` | failure — bad detail value |
| P09 | `tldr health backend/providers --quick --detail coupling` | failure — coupling conflicts with --quick |
| P10 | `tldr health backend/providers --quick --detail similarity` | failure — similarity conflicts with --quick |
| P11 | `tldr health backend/providers --quick --summary --preset strict` | happy — strict preset |
| P12 | `tldr health backend/providers --quick --summary --preset relaxed` | happy — relaxed preset |
| P13 | `tldr health /tmp/empty-dir` | failure — empty dir |
| P14 | `tldr health backend/providers --max-items 5 --summary` | happy — max-items limit |
| P15 | `tldr health backend/providers --summary` | happy — full mode (slow, no --quick) |
| P16 | `tldr health backend/providers --quick --summary -f compact` | happy — compact format |
| P17 | `tldr health backend/db.py --quick --summary` | happy — single file |

---

## `tldr hotspots`

**Canonical syntax (from `tldr hotspots --help`):**
```
tldr hotspots [OPTIONS] [PATH]
```

> **Note**: Requires a git repo. Combines git churn with complexity to rank files by maintenance risk.

| # | Command | Type |
|---|---------|------|
| P01 | `tldr hotspots` | happy — current dir |
| P02 | `tldr hotspots backend --top 50` | happy-scale |
| P03 | (PATH defaults to `.` — no required arg) | N/A |
| P04 | `tldr hotspots /no/such/dir` | failure — bad path |
| P05 | `tldr hotspots -f sarif` | failure — format rejected |
| P06 | `tldr hotspots -f text` | happy — text format |
| P07 | `tldr hotspots -f compact` | happy — compact format |
| P08 | `tldr hotspots -f dot` | failure — format rejected |
| P09 | `tldr hotspots --days 30` | happy — last 30 days |
| P10 | `tldr hotspots --days 99999` | happy — all history |
| P11 | `tldr hotspots --top 1` | happy — top 1 hotspot |
| P12 | `tldr hotspots --by-function --top 5` | happy — function-level hotspots |
| P13 | `tldr hotspots --show-trend` | happy — show change trend |
| P14 | `tldr hotspots --min-commits 1` | happy — low commit threshold |
| P15 | `tldr hotspots --min-commits 999` | happy — high threshold (likely empty) |
| P16 | `tldr hotspots --exclude '*.md' --exclude 'venv/**'` | happy — exclusions |
| P17 | `tldr hotspots --threshold 0.5` | happy — mid threshold |
| P18 | `tldr hotspots --threshold 0.99` | happy — high threshold |
| P19 | `tldr hotspots --since 2026-01-01` | happy — date filter |
| P20 | `tldr hotspots --since not-a-date` | failure — bad date format |
| P21 | `tldr hotspots --recency-halflife 0` | happy — no decay |
| P22 | `tldr hotspots --include-bots` | happy — include bot commits |
| P23 | `tldr hotspots -l brainfuck` | failure — bad lang |
| P24 | `tldr hotspots /tmp/non-git-dir` | failure — not a git repo |
| P25 | `tldr hotspots /tmp/empty-dir` | failure — empty dir |
| P26 | `tldr hotspots -q` | happy — quiet |

---

## `tldr inheritance`

**Canonical syntax (from `tldr inheritance --help`):**
```
tldr inheritance [OPTIONS] [PATH]
```

> **Format note**: `inheritance` accepts `dot` format in addition to json/text/compact.

| # | Command | Type |
|---|---------|------|
| P01 | `tldr inheritance backend/providers` | happy |
| P02 | `tldr inheritance backend` | happy-scale |
| P03 | (PATH defaults to `.` — no required arg) | N/A |
| P04 | `tldr inheritance /no/such/dir` | failure — bad path |
| P05 | `tldr inheritance backend/providers -f sarif` | failure — format rejected |
| P06 | `tldr inheritance backend/providers -f text` | happy — text format |
| P07 | `tldr inheritance backend/providers -f compact` | happy — compact format |
| P08 | `tldr inheritance backend/providers -f dot` | happy — dot format (graphviz) |
| P09 | `tldr inheritance backend/providers --class YahooProvider` | happy — focus on class |
| P10 | `tldr inheritance backend/providers --class NoSuchClass` | failure — class not found |
| P11 | `tldr inheritance backend/providers --depth 2` | happy — depth without class (tree depth) |
| P12 | `tldr inheritance backend/providers --class YahooProvider --depth 1` | happy — depth with class |
| P13 | `tldr inheritance backend/providers --no-patterns` | happy — skip design patterns |
| P14 | `tldr inheritance backend/providers --no-external` | happy — skip external base classes |
| P15 | `tldr inheritance backend/providers -l brainfuck` | failure — bad lang |
| P16 | `tldr inheritance backend/providers -l python` | happy — lang python |
| P17 | `tldr inheritance backend/providers -l typescript` | failure — lang mismatch |
| P18 | `tldr inheritance backend/providers -o dot` | happy — legacy output flag |
| P19 | `tldr inheritance backend/providers -o wat` | failure — bad legacy output value |
| P20 | `tldr inheritance /tmp/empty-dir` | failure — empty dir |
| P21 | `tldr inheritance README.md` | failure — non-source file |
| P22 | `tldr inheritance backend/providers/base.py` | happy — single file |
| P23 | `tldr inheritance backend/providers -q` | happy — quiet |

---

## `tldr interface`

**Canonical syntax (from `tldr interface --help`):**
```
tldr interface [OPTIONS] <PATH>
```

> **Note**: PATH is required (no default).

| # | Command | Type |
|---|---------|------|
| P01 | `tldr interface backend/providers/base.py` | happy |
| P02 | `tldr interface backend/providers` | happy-scale |
| P03 | `tldr interface` | failure — missing path arg |
| P04 | `tldr interface /no/such/dir` | failure — bad path |
| P05 | `tldr interface backend/providers -f sarif` | failure — format rejected |
| P06 | `tldr interface backend/providers -f text` | happy — text format |
| P07 | `tldr interface backend/providers -f compact` | happy — compact format |
| P08 | `tldr interface backend/providers -f dot` | failure — format rejected |
| P09 | `tldr interface backend/providers/yahoo.py --project-root backend` | happy — project root hint |
| P10 | `tldr interface backend/providers -l brainfuck` | failure — bad lang |
| P11 | `tldr interface backend/providers -l python` | happy — lang python |
| P12 | `tldr interface backend/providers -l typescript` | failure — lang mismatch |
| P13 | `tldr interface /tmp/empty-dir` | failure — empty dir |
| P14 | `tldr interface README.md` | failure — non-source file |
| P15 | `tldr interface backend/providers -q` | happy — quiet |

---

## `tldr invariants`

**Canonical syntax (from `tldr invariants --help`):**
```
tldr invariants [OPTIONS] --from-tests <FROM_TESTS> <FILE>
```

> **Note**: Both `--from-tests` (a required flag, not positional) and `<FILE>` are required.
> Requires a pytest test file that actually executes the source function.

| # | Command | Type |
|---|---------|------|
| P01 | `tldr invariants <src.py> --from-tests <test_src.py>` | happy |
| P02 | `tldr invariants <src.py> --from-tests <test_src.py> --function clamp` | happy-scale |
| P03 | `tldr invariants --from-tests <test_src.py>` | failure — missing FILE arg |
| P04 | `tldr invariants /no/such/file.py --from-tests <test_src.py>` | failure — bad source path |
| P05 | `tldr invariants <src.py> --from-tests <test_src.py> -f sarif` | failure — format rejected |
| P06 | `tldr invariants <src.py> --from-tests <test_src.py> -f text` | happy — text format |
| P07 | `tldr invariants <src.py> --from-tests <test_src.py> -f compact` | happy — compact format |
| P08 | `tldr invariants <src.py> --from-tests <test_src.py> -f dot` | failure — format rejected |
| P09 | `tldr invariants <src.py> --from-tests <test_src.py> --min-obs 5` | happy — min observation count |
| P10 | `tldr invariants <src.py> --from-tests <test_src.py> --min-obs 999` | happy — high obs count (likely empty) |
| P11 | `tldr invariants <src.py> --from-tests <test_src.py> --function no_such_function` | failure — function not found |
| P12 | `tldr invariants <src.py>` | failure — missing --from-tests |
| P13 | `tldr invariants <src.py> --from-tests /no/such/tests` | failure — bad tests path |
| P14 | `tldr invariants <src.py> --from-tests <src.py>` | failure — source file used as tests (no test_ functions) |
| P15 | `tldr invariants <src.py> --from-tests <test_src.py> -l brainfuck` | failure — bad lang |
| P16 | `tldr invariants <src.py> --from-tests <test_src.py> -l python` | happy — lang python |
| P17 | `tldr invariants <src.py> --from-tests <test_src.py> -l typescript` | failure — lang mismatch |
| P18 | `tldr invariants <src.py> --from-tests <test_src.py> -o text` | happy — output flag |
| P19 | `tldr invariants <src.py> --from-tests <test_src.py> -o wat` | failure — bad output value |
| P20 | `tldr invariants <src.py> --from-tests <tests-dir/>` | happy — tests dir accepted |
| P21 | `tldr invariants <src.py> --from-tests <test_src.py> -q` | happy — quiet |
| P22 | `tldr invariants <src.py> --from-tests <test_src.py> --min-obs 0` | failure — min-obs zero |

---

## `tldr loc`

**Canonical syntax (from `tldr loc --help`):**
```
tldr loc [OPTIONS] [PATH]
```

| # | Command | Type |
|---|---------|------|
| P01 | `tldr loc backend/providers/yahoo.py` | happy |
| P02 | `tldr loc backend` | happy-scale |
| P03 | (PATH defaults to `.` — no required arg) | N/A |
| P04 | `tldr loc /no/such/dir` | failure — bad path |
| P05 | `tldr loc backend/providers -f sarif` | failure — format rejected |
| P06 | `tldr loc backend/providers -f text` | happy — text format |
| P07 | `tldr loc backend/providers -f compact` | happy — compact format |
| P08 | `tldr loc backend/providers -f dot` | failure — format rejected |
| P09 | `tldr loc backend/providers --by-file` | happy — per-file breakdown |
| P10 | `tldr loc backend --by-dir` | happy — per-directory breakdown |
| P11 | `tldr loc backend --by-file --by-dir` | happy — both breakdowns |
| P12 | `tldr loc backend -l python` | happy — lang python |
| P13 | `tldr loc . -l typescript` | happy — lang typescript |
| P14 | `tldr loc backend -l brainfuck` | failure — bad lang |
| P15 | `tldr loc backend/providers --exclude '__init__.py' --by-file` | happy — exclusion |
| P16 | `tldr loc backend/providers --include-hidden` | happy — include hidden |
| P17 | `tldr loc . --no-gitignore --max-files 5` | happy — bypass gitignore |
| P18 | `tldr loc backend --max-files 1` | happy — max files limit |
| P19 | `tldr loc backend/providers --max-files 0` | failure — max-files zero |
| P20 | `tldr loc /tmp/empty-dir` | failure — empty dir |
| P21 | `tldr loc README.md` | failure — non-source file |
| P22 | `tldr loc backend/providers -q` | happy — quiet |

---

## `tldr patterns`

**Canonical syntax (from `tldr patterns --help`):**
```
tldr patterns [OPTIONS] [PATH]
```

| # | Command | Type |
|---|---------|------|
| P01 | `tldr patterns backend/providers` | happy |
| P02 | `tldr patterns backend` | happy-scale |
| P03 | (PATH defaults to `.` — no required arg) | N/A |
| P04 | `tldr patterns /no/such/dir` | failure — bad path |
| P05 | `tldr patterns backend/providers -f sarif` | failure — format rejected |
| P06 | `tldr patterns backend/providers -f text` | happy — text format |
| P07 | `tldr patterns backend/providers -f compact` | happy — compact format |
| P08 | `tldr patterns backend/providers -f dot` | failure — format rejected |
| P09 | `tldr patterns backend/providers --category naming` | happy — naming patterns |
| P10 | `tldr patterns backend/providers --category error-handling` | happy — error handling patterns |
| P11 | `tldr patterns backend/providers --category wat` | failure — bad category |
| P12 | `tldr patterns backend/providers --min-confidence 0.0` | happy — all patterns |
| P13 | `tldr patterns backend/providers --min-confidence 1.0` | happy — only perfect matches |
| P14 | `tldr patterns backend/providers --min-confidence 0.5` | happy — mid confidence |
| P15 | `tldr patterns backend --max-files 1` | happy — max files limit |
| P16 | `tldr patterns backend/providers --max-files 0` | failure — max-files zero |
| P17 | `tldr patterns backend/providers --no-constraints` | happy — skip constraint extraction |
| P18 | `tldr patterns backend/providers -l brainfuck` | failure — bad lang |
| P19 | `tldr patterns backend/providers -l python` | happy — lang python |
| P20 | `tldr patterns backend/providers -l typescript` | failure — lang mismatch |
| P21 | `tldr patterns /tmp/empty-dir` | failure — empty dir |
| P22 | `tldr patterns README.md` | failure — non-source file |
| P23 | `tldr patterns backend/providers -q` | happy — quiet |
| P24 | `tldr patterns backend/providers/yahoo.py` | happy — single file |

---

## `tldr resources`

**Canonical syntax (from `tldr resources --help`):**
```
tldr resources [OPTIONS] <FILE> [FUNCTION]
```

> **Note**: FILE is required; FUNCTION is optional (omit to scan the whole file).
> Do NOT pass a directory — will fail. Use `tldr secure` for directory-wide resource analysis.

| # | Command | Type |
|---|---------|------|
| P01 | `tldr resources backend/providers/yahoo.py` | happy — whole file |
| P02 | `tldr resources backend/providers/yahoo.py fetch_historical_data` | happy-scale — one function |
| P03 | `tldr resources` | failure — missing file arg |
| P04 | `tldr resources /no/such/file.py` | failure — bad path |
| P05 | `tldr resources backend/providers/yahoo.py -f sarif` | failure — format rejected |
| P06 | `tldr resources backend/providers/yahoo.py -f text` | happy — text format |
| P07 | `tldr resources backend/providers/yahoo.py -f compact` | happy — compact format |
| P08 | `tldr resources backend/providers/yahoo.py -f dot` | failure — format rejected |
| P09 | `tldr resources backend/providers/yahoo.py --check-leaks` | happy — leak check |
| P10 | `tldr resources backend/providers/yahoo.py --check-double-close` | happy — double-close check |
| P11 | `tldr resources backend/providers/yahoo.py --check-use-after-close` | happy — use-after-close check |
| P12 | `tldr resources backend/providers/yahoo.py --check-all` | happy — all checks |
| P13 | `tldr resources backend/providers/yahoo.py --suggest-context` | happy — suggest context managers |
| P14 | `tldr resources backend/providers/yahoo.py --show-paths` | happy — show flow paths |
| P15 | `tldr resources backend/providers/yahoo.py --constraints` | happy — show resource constraints |
| P16 | `tldr resources backend/providers/yahoo.py --summary` | happy — summary only |
| P17 | `tldr resources backend/providers/yahoo.py --project-root backend` | happy — project root hint |
| P18 | `tldr resources backend/providers/yahoo.py no_such_function` | failure — function not found |
| P19 | `tldr resources backend/providers/yahoo.py -l brainfuck` | failure — bad lang |
| P20 | `tldr resources backend/providers/yahoo.py -l python` | happy — lang python |
| P21 | `tldr resources backend/providers/yahoo.py -l typescript` | failure — lang mismatch |
| P22 | `tldr resources README.md` | failure — non-source file |
| P23 | `tldr resources backend/providers` | failure — directory arg (use tldr secure instead) |
| P24 | `tldr resources backend/providers/yahoo.py -o text` | happy — output flag |
| P25 | `tldr resources backend/providers/yahoo.py -q` | happy — quiet |

---

## `tldr secure`

**Canonical syntax (from `tldr secure --help`):**
```
tldr secure [OPTIONS] <PATH>
```

> **Note**: PATH is required (no default). Accepts `sarif` format (alongside json/text/compact).
> `--quick` is strongly recommended for large codebases.

| # | Command | Type |
|---|---------|------|
| P01 | `tldr secure backend/providers --quick` | happy |
| P02 | `tldr secure backend --quick` | happy-scale |
| P03 | `tldr secure` | failure — missing path arg |
| P04 | `tldr secure /no/such/dir` | failure — bad path |
| P05 | `tldr secure backend/providers --quick -f dot` | failure — format rejected |
| P06 | `tldr secure backend/providers --quick -f text` | happy — text format |
| P07 | `tldr secure backend/providers --quick -f compact` | happy — compact format |
| P08 | `tldr secure backend/providers --quick -f sarif` | happy — sarif (secure-specific) |
| P09 | `tldr secure backend/providers --quick` | happy — quick mode |
| P10 | `tldr secure backend/providers --quick --detail taint` | happy — taint detail |
| P11 | `tldr secure backend/providers --quick --detail wat` | failure — bad detail |
| P12 | `tldr secure backend/providers --quick -o /tmp/out.json` | happy — output file |
| P13 | `tldr secure backend/providers --quick --no-default-ignore` | happy — bypass default ignores |
| P14 | `tldr secure backend --quick --include-tests` | happy — include test files |
| P15 | `tldr secure backend/providers --quick -l brainfuck` | failure — bad lang |
| P16 | `tldr secure backend/providers --quick -l python` | happy — lang python |
| P17 | `tldr secure backend/providers --quick -l typescript` | failure — lang mismatch |
| P18 | `tldr secure /tmp/empty-dir --quick` | failure — empty dir |
| P19 | `tldr secure README.md --quick` | failure — non-source file |
| P20 | `tldr secure backend/providers/yahoo.py --quick` | happy — single file |
| P21 | `tldr secure backend/providers --quick -q` | happy — quiet |

---

## `tldr smells`

**Canonical syntax (from `tldr smells --help`):**
```
tldr smells [OPTIONS] [PATH]
```

> **Note**: Some smell types (e.g., `low-cohesion`) require `--deep` to be enabled.

| # | Command | Type |
|---|---------|------|
| P01 | `tldr smells backend/providers` | happy |
| P02 | `tldr smells backend` | happy-scale |
| P03 | (PATH defaults to `.` — no required arg) | N/A |
| P04 | `tldr smells /no/such/dir` | failure — bad path |
| P05 | `tldr smells backend/providers -f sarif` | failure — format rejected |
| P06 | `tldr smells backend/providers -f text` | happy — text format |
| P07 | `tldr smells backend/providers -f compact` | happy — compact format |
| P08 | `tldr smells backend/providers -f dot` | failure — format rejected |
| P09 | `tldr smells backend/providers -t strict` | happy — strict threshold |
| P10 | `tldr smells backend/providers -t relaxed` | happy — relaxed threshold |
| P11 | `tldr smells backend/providers -t wat` | failure — bad threshold value |
| P12 | `tldr smells backend/providers -s god-class` | happy — god-class smell type |
| P13 | `tldr smells backend/providers -s wat` | failure — bad smell type |
| P14 | `tldr smells backend/providers -s low-cohesion` | failure — requires --deep |
| P15 | `tldr smells backend/providers --suggest` | happy — include fix suggestions |
| P16 | `tldr smells backend/providers --deep` | happy — deep analysis |
| P17 | `tldr smells backend/providers --deep -s low-cohesion` | happy — deep + low-cohesion |
| P18 | `tldr smells backend/providers --no-default-ignore` | happy — bypass default ignores |
| P19 | `tldr smells backend --files backend/providers/yahoo.py` | happy — file filter |
| P20 | `tldr smells backend --files ../../../../etc/passwd` | failure — path traversal rejected |
| P21 | `tldr smells backend --include-tests` | happy — include test files |
| P22 | `tldr smells backend/providers -l brainfuck` | failure — bad lang |
| P23 | `tldr smells backend/providers -l python` | happy — lang python |
| P24 | `tldr smells /tmp/empty-dir` | failure — empty dir |
| P25 | `tldr smells README.md` | failure — non-source file |
| P26 | `tldr smells backend/providers -q` | happy — quiet |
| P27 | `tldr smells backend/providers` | happy — cold daemon |
| P28 | `tldr smells backend/providers` | happy — warm daemon |

---

## `tldr specs`

**Canonical syntax (from `tldr specs --help`):**
```
tldr specs [OPTIONS] --from-tests <FROM_TESTS>
```

> **Note**: `--from-tests` is a required flag (no positional FILE). Accepts a test file or dir.
> Works only on pytest test files (Python).

| # | Command | Type |
|---|---------|------|
| P01 | `tldr specs --from-tests <test_src.py>` | happy |
| P02 | `tldr specs --from-tests <tests-dir/>` | happy-scale — directory |
| P03 | `tldr specs` | failure — missing --from-tests |
| P04 | `tldr specs --from-tests /no/such/tests` | failure — bad path |
| P05 | `tldr specs --from-tests <test_src.py> -f sarif` | failure — format rejected |
| P06 | `tldr specs --from-tests <test_src.py> -f text` | happy — text format |
| P07 | `tldr specs --from-tests <test_src.py> -f compact` | happy — compact format |
| P08 | `tldr specs --from-tests <test_src.py> -f dot` | failure — format rejected |
| P09 | `tldr specs --from-tests <test_src.py> --function add` | happy — function filter |
| P10 | `tldr specs --from-tests <test_src.py> --function no_such_function` | failure — function not found |
| P11 | `tldr specs --from-tests <test_src.py> --source <src-dir/>` | happy — cross-reference source |
| P12 | `tldr specs --from-tests <test_src.py> --source /no/such/source` | failure — bad source path |
| P13 | `tldr specs --from-tests <test_src.py> -l brainfuck` | failure — bad lang |
| P14 | `tldr specs --from-tests <test_src.py> -l python` | happy — lang python |
| P15 | `tldr specs --from-tests <test_src.py> -l typescript` | failure — lang mismatch |
| P16 | `tldr specs --from-tests <test_src.py> -o text` | happy — output flag |
| P17 | `tldr specs --from-tests <test_src.py> -o wat` | failure — bad output value |
| P18 | `tldr specs --from-tests <src.py>` | failure — non-test file (no test_ functions) |
| P19 | `tldr specs --from-tests <test_src.py> -q` | happy — quiet |
| P20 | `tldr specs --from-tests /tmp/empty-tests-dir` | failure — empty dir |

---

## `tldr taint`

**Canonical syntax (from `tldr taint --help`):**
```
tldr taint [OPTIONS] <FILE> <FUNCTION>
```

> **Note**: Both FILE and FUNCTION are required. Works best with a dedicated taint fixture. For full-codebase vulnerability scanning, prefer `tldr vuln`.

| # | Command | Type |
|---|---------|------|
| P01 | `tldr taint <sinks.py> vulnerable_sql` | happy |
| P02 | `tldr taint <sinks.py> vulnerable_shell` | happy-scale |
| P03 | `tldr taint <sinks.py>` | failure — missing function arg |
| P04 | `tldr taint /no/such/file.py vulnerable_sql` | failure — bad path |
| P05 | `tldr taint <sinks.py> vulnerable_sql -f sarif` | failure — format rejected |
| P06 | `tldr taint <sinks.py> vulnerable_sql -f text` | happy — text format |
| P07 | `tldr taint <sinks.py> vulnerable_sql -f compact` | happy — compact format |
| P08 | `tldr taint <sinks.py> vulnerable_sql -f dot` | failure — format rejected |
| P09 | `tldr taint <sinks.py> vulnerable_sql --verbose` | happy — verbose output |
| P10 | `tldr taint <sinks.py> no_such_function` | failure — function not found |
| P11 | `tldr taint <sinks.py> vulnerable_sql -l python` | happy — lang python |
| P12 | `tldr taint <sinks.py> vulnerable_sql -l typescript` | failure — lang mismatch |
| P13 | `tldr taint <sinks.py> vulnerable_sql -l brainfuck` | failure — bad lang |
| P14 | `tldr taint <sinks.py> safe_function` | happy — clean function (no taint, empty result) |
| P15 | `tldr taint <sinks.py> safe_sql` | happy — parameterized query (no taint) |
| P16 | `tldr taint <sinks.py> vulnerable_eval` | happy — eval sink |
| P17 | `tldr taint <sinks.py> vulnerable_path` | happy — path traversal sink |
| P18 | `tldr taint <sinks.py> vulnerable_sql -q` | happy — quiet |
| P19 | `tldr taint README.md anything` | failure — non-source file |
| P20 | `tldr taint <fixtures-dir/> vulnerable_sql` | failure — directory as file arg |

---

## `tldr temporal`

**Canonical syntax (from `tldr temporal --help`):**
```
tldr temporal [OPTIONS] <PATH>
```

> **Note**: PATH is required (no default). Mines co-occurrence patterns from call sequences — requires enough code (multiple files/methods) to find patterns.

| # | Command | Type |
|---|---------|------|
| P01 | `tldr temporal backend/providers` | happy |
| P02 | `tldr temporal backend` | happy-scale |
| P03 | `tldr temporal` | failure — missing path arg |
| P04 | `tldr temporal /no/such/dir` | failure — bad path |
| P05 | `tldr temporal backend/providers -f sarif` | failure — format rejected |
| P06 | `tldr temporal backend/providers -f text` | happy — text format |
| P07 | `tldr temporal backend/providers -f compact` | happy — compact format |
| P08 | `tldr temporal backend/providers -f dot` | failure — format rejected |
| P09 | `tldr temporal backend/providers --min-support 1` | happy — low support (more patterns) |
| P10 | `tldr temporal backend/providers --min-support 999` | happy — high support (likely empty) |
| P11 | `tldr temporal backend/providers --min-confidence 0.0` | happy — all confidence levels |
| P12 | `tldr temporal backend/providers --min-confidence 1.0` | happy — only certain patterns |
| P13 | `tldr temporal backend/providers --query fetch_historical_data` | happy — query one method |
| P14 | `tldr temporal backend/providers --source-lang python` | happy — explicit source lang |
| P15 | `tldr temporal backend/providers --source-lang auto` | happy — auto-detect |
| P16 | `tldr temporal backend/providers --source-lang wat` | failure — bad source lang |
| P17 | `tldr temporal backend --max-files 1` | happy — max files limit |
| P18 | `tldr temporal backend --include-trigrams` | happy — include 3-method sequences |
| P19 | `tldr temporal backend/providers --include-examples 0` | happy — suppress examples |
| P20 | `tldr temporal backend/providers --timeout 1` | happy — short timeout |
| P21 | `tldr temporal backend/providers --project-root backend` | happy — project root hint |
| P22 | `tldr temporal backend/providers -l brainfuck` | failure — bad lang |
| P23 | `tldr temporal backend/providers -l python` | happy — lang python |
| P24 | `tldr temporal /tmp/empty-dir` | failure — empty dir |
| P25 | `tldr temporal README.md` | failure — non-source file |
| P26 | `tldr temporal backend/providers -q` | happy — quiet |

---

## `tldr verify`

**Canonical syntax (from `tldr verify --help`):**
```
tldr verify [OPTIONS] [PATH]
```

> **Note**: `--quick` strongly recommended. Full mode is slow on large codebases.

| # | Command | Type |
|---|---------|------|
| P01 | `tldr verify backend/providers --quick` | happy |
| P02 | `tldr verify backend --quick` | happy-scale |
| P03 | (PATH defaults to `.` — no required arg) | N/A |
| P04 | `tldr verify /no/such/dir` | failure — bad path |
| P05 | `tldr verify backend/providers --quick -f sarif` | failure — format rejected |
| P06 | `tldr verify backend/providers --quick -f text` | happy — text format |
| P07 | `tldr verify backend/providers --quick -f compact` | happy — compact format |
| P08 | `tldr verify backend/providers --quick -f dot` | failure — format rejected |
| P09 | `tldr verify backend/providers --quick` | happy — quick mode |
| P10 | `tldr verify backend/providers --quick --detail contracts` | happy — contracts detail |
| P11 | `tldr verify backend/providers --quick --detail wat` | failure — bad detail |
| P12 | `tldr verify backend/providers --quick -l brainfuck` | failure — bad lang |
| P13 | `tldr verify backend/providers --quick -l python` | happy — lang python |
| P14 | `tldr verify backend/providers --quick -l typescript` | failure — lang mismatch |
| P15 | `tldr verify /tmp/empty-dir --quick` | failure — empty dir |
| P16 | `tldr verify backend/providers/yahoo.py --quick` | happy — single file |
| P17 | `tldr verify README.md --quick` | failure — non-source file |
| P18 | `tldr verify backend/providers --quick -o text` | happy — output flag |
| P19 | `tldr verify backend/providers --quick -o wat` | failure — bad output value |
| P20 | `tldr verify backend/providers --quick -q` | happy — quiet |

---

## `tldr vuln`

**Canonical syntax (from `tldr vuln --help`):**
```
tldr vuln [OPTIONS] <PATH>
```

> **Format note**: `vuln` accepts `sarif` format (alongside json/text/compact) — useful for CI/SAST integration.
> PATH is required (no default). Accepts file or directory.

| # | Command | Type |
|---|---------|------|
| P01 | `tldr vuln backend/providers` | happy |
| P02 | `tldr vuln <sinks.py>` | happy-scale — fixture with known vulns |
| P03 | `tldr vuln` | failure — missing path arg |
| P04 | `tldr vuln /no/such/dir` | failure — bad path |
| P05 | `tldr vuln backend/providers -f dot` | failure — format rejected |
| P06 | `tldr vuln backend/providers -f text` | happy — text format |
| P07 | `tldr vuln backend/providers -f compact` | happy — compact format |
| P08 | `tldr vuln <sinks.py> -f sarif` | happy — sarif (vuln-specific) |
| P09 | `tldr vuln backend/providers --severity critical` | happy — severity filter |
| P10 | `tldr vuln backend/providers --severity info` | happy — all severities |
| P11 | `tldr vuln backend/providers --severity wat` | failure — bad severity |
| P12 | `tldr vuln <sinks.py> --vuln-type sql_injection` | happy — sql injection type |
| P13 | `tldr vuln backend/providers --vuln-type wat` | failure — bad vuln type |
| P14 | `tldr vuln <sinks.py> --vuln-type sql_injection --vuln-type command_injection` | happy — multi vuln type |
| P15 | `tldr vuln backend/providers --include-informational` | happy — include info-level findings |
| P16 | `tldr vuln backend/providers --include-smells` | happy — include smell-adjacent findings |
| P17 | `tldr vuln backend --include-tests` | happy — include test files |
| P18 | `tldr vuln backend/providers -O /tmp/vuln-out.json` | happy — output file |
| P19 | `tldr vuln backend/providers --no-default-ignore` | happy — bypass default ignores |
| P20 | `tldr vuln backend/providers -l brainfuck` | failure — bad lang |
| P21 | `tldr vuln backend/providers -l python` | happy — lang python |
| P22 | `tldr vuln backend/providers -l typescript` | failure — lang mismatch |
| P23 | `tldr vuln webui/src` | happy — non-native language dir (may be empty) |
| P24 | `tldr vuln /tmp/empty-dir` | failure — empty dir |
| P25 | `tldr vuln README.md` | failure — non-source file |
| P26 | `tldr vuln backend/providers -q` | happy — quiet |
