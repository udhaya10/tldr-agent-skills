# Verified CLI Invocations — `overview` group

> **Protocol**: Before writing a `Usage:` block in any tool card or SKILL.md for commands
> in this group, copy the canonical syntax from this document. Do NOT reconstruct syntax
> from prose — that is how hallucinated flags get introduced.
>
> All probes in this document were run against a real codebase (Stock-Monitor,
> tldr-code v0.4.0) and their outputs are captured in the `.probes/` directories
> alongside the dossiers. Probe types: `happy` = working/verified, `failure` = error case.

---

## `tldr definition`

**Canonical syntax (from `tldr definition --help`):**
```
tldr definition [OPTIONS] [FILE] [LINE] [COLUMN]
```

| # | Command | Type |
|---|---------|------|
| P01 | `tldr definition backend/providers/yahoo.py 40 12` | happy — positional |
| P02 | `tldr definition --symbol HistoricalDataProvider --file backend/providers/yahoo.py --project .` | happy — named symbol |
| P03 | `tldr definition` | failure — no args (all optional, but no-op result) |
| P04 | `tldr definition /no/such/path.py 1 1` | failure — bad path |
| P05 | `tldr definition backend/providers/yahoo.py 40 12 -f sarif` | failure — format rejected |
| P06 | `tldr definition backend/providers/yahoo.py 40 12 -f text` | happy — text format |
| P07 | `tldr definition backend/providers/yahoo.py 40 12 -f compact` | happy — compact format |
| P08 | `tldr definition --symbol HistoricalDataProvider` | failure — symbol without file |
| P09 | `tldr definition backend/providers/yahoo.py 40 12 -f dot` | failure — format rejected |
| P10 | `tldr definition --symbol NoSuchSymbol --file backend/providers/yahoo.py --project .` | failure — symbol not found |
| P11 | `tldr definition backend/db.py 1 1 -l python --symbol print --file backend/db.py` | failure — builtin (not found in source) |
| P12 | `tldr definition --symbol HistoricalDataProvider --file backend/providers/yahoo.py --workspace=false` | happy — workspace disabled |
| P13 | `tldr definition backend/providers/yahoo.py 40 12 -l brainfuck` | failure — bad lang |
| P14 | `tldr definition README.md 1 1` | failure — non-source file |
| P15 | `tldr definition backend/providers/yahoo.py 1 0` | failure — column zero / unresolved |
| P16 | `tldr definition backend/providers/yahoo.py 40 9999` | failure — column out of range |
| P17 | `tldr definition backend/providers/yahoo.py 999999 0` | failure — line out of range |
| P18 | `tldr definition backend/providers/yahoo.py 40 12 -O /tmp/out.json && cat /tmp/out.json` | happy — output file |
| P19 | `tldr definition --symbol Provider --file backend/providers/yahoo.py --project .` | happy — imported symbol |
| P20 | `tldr definition backend/providers/yahoo.py 12 0` | happy — usage site |

---

## `tldr explain`

**Canonical syntax (from `tldr explain --help`):**
```
tldr explain [OPTIONS] <FILE> <FUNCTION>
```

| # | Command | Type |
|---|---------|------|
| P01 | `tldr explain backend/providers/yahoo.py _to_finite_float` | happy |
| P02 | `tldr explain backend/providers/yahoo.py fetch_historical_data` | happy-scale |
| P03 | `tldr explain backend/providers/yahoo.py` | failure — missing function arg |
| P04 | `tldr explain /no/such/file.py some_fn` | failure — bad path |
| P05 | `tldr explain backend/providers/yahoo.py _to_finite_float -f sarif` | failure — format rejected |
| P06 | `tldr explain backend/providers/yahoo.py _to_finite_float -f text` | happy — text format |
| P07 | `tldr explain backend/providers/yahoo.py _to_finite_float -f compact` | happy — compact format |
| P08 | `tldr explain backend/providers/yahoo.py _to_finite_float -f dot` | failure — format rejected |
| P09 | `tldr explain backend/providers/yahoo.py fetch_historical_data --depth 0` | happy — depth zero |
| P10 | `tldr explain backend/providers/yahoo.py fetch_historical_data --depth 5` | happy — depth five |
| P11 | `tldr explain backend/providers/yahoo.py no_such_function` | failure — function not found |
| P12 | `tldr explain backend/providers/yahoo.py YahooProvider.fetch_historical_data` | happy — qualified name |
| P13 | `tldr explain backend/providers/yahoo.py _to_finite_float -l python` | happy — lang flag |
| P14 | `tldr explain backend/providers/yahoo.py _to_finite_float -l brainfuck` | failure — bad lang |
| P15 | `tldr explain backend/providers/yahoo.py _to_finite_float -o /tmp/out.json && cat /tmp/out.json` | happy — output file |
| P16 | `tldr explain README.md anything` | failure — non-source file |
| P17 | `tldr explain backend anything` | failure — directory arg |
| P18 | `tldr explain backend/providers/yahoo.py YahooProvider.no_such_method` | failure — qualified miss |
| P19 | `tldr explain backend/providers/yahoo.py _to_finite_float -q` | happy — quiet |

---

## `tldr extract`

**Canonical syntax (from `tldr extract --help`):**
```
tldr extract [OPTIONS] <FILE>
```

| # | Command | Type |
|---|---------|------|
| P01 | `tldr extract backend/db.py` | happy |
| P02 | `tldr extract backend/api.py` | happy-scale |
| P03 | `tldr extract` | failure — missing arg |
| P04 | `tldr extract /no/such/file/definitely/missing.py` | failure — bad path |
| P05 | `tldr extract backend/db.py -f sarif` | failure — format rejected |
| P06 | `tldr extract backend/db.py -f text` | happy — text format |
| P07 | `tldr extract backend/db.py -l python` | happy — lang python |
| P08 | `tldr extract backend/db.py -l rust` | failure — lang mismatch |
| P09 | `tldr extract backend/db.py -f compact` | happy — compact format |
| P10 | `tldr extract README.md` | failure — non-source file |
| P11 | `tldr extract backend` | failure — directory arg |
| P12 | `tldr extract backend/db.py` | happy — cold daemon |
| P13 | `tldr extract backend/db.py` | happy — warm daemon |

---

## `tldr importers`

**Canonical syntax (from `tldr importers --help`):**
```
tldr importers [OPTIONS] <MODULE> [PATH]
```

| # | Command | Type |
|---|---------|------|
| P01 | `tldr importers backend.providers.base` | happy |
| P02 | `tldr importers pandas backend` | happy-scale |
| P03 | `tldr importers` | failure — missing module arg |
| P04 | `tldr importers pandas /no/such/dir` | failure — bad path |
| P05 | `tldr importers pandas backend -f sarif` | failure — format rejected |
| P06 | `tldr importers pandas backend -f text` | happy — text format |
| P07 | `tldr importers pandas backend -f compact` | happy — compact format |
| P08 | `tldr importers pandas backend -f dot` | failure — format rejected |
| P09 | `tldr importers pandas backend --limit 1` | happy — limit low |
| P10 | `tldr importers pandas backend --limit 0` | failure — limit zero |
| P11 | `tldr importers pandas backend -l typescript` | failure — lang mismatch |
| P12 | `tldr importers pandas backend -l brainfuck` | failure — bad lang |
| P13 | `tldr importers absolutely_no_such_module backend` | happy — empty result (no error) |
| P14 | `tldr importers backend.providers.base` | happy — dotted module |
| P15 | `tldr importers pandas backend -q` | happy — quiet |
| P16 | `tldr importers pandas backend` | happy — cold daemon |
| P17 | `tldr importers pandas backend` | happy — warm daemon |
| P18 | `tldr importers pandas backend -l typescript` | failure — warm daemon lang override |
| P19 | `tldr importers backend.providers.base` | failure — default path bug (no project index) |
| P20 | `tldr importers backend.providers.base -l python` | happy — explicit lang fixes default path |
| P21 | `tldr daemon start --project '/path/to/project' && tldr warm '/path/to/project' && tldr importers backend.providers.base` | happy — warm daemon composition |

---

## `tldr imports`

**Canonical syntax (from `tldr imports --help`):**
```
tldr imports [OPTIONS] <FILE>
```

| # | Command | Type |
|---|---------|------|
| P01 | `tldr imports backend/providers/base.py` | happy |
| P02 | `tldr imports backend/providers/yahoo.py` | happy-scale |
| P03 | `tldr imports` | failure — missing arg |
| P04 | `tldr imports /no/such/file.py` | failure — bad path |
| P05 | `tldr imports backend/providers/base.py -f sarif` | failure — format rejected |
| P06 | `tldr imports backend/providers/base.py -f text` | happy — text format |
| P07 | `tldr imports backend/providers/base.py -f compact` | happy — compact format |
| P08 | `tldr imports backend/providers/base.py -f dot` | failure — format rejected |
| P09 | `tldr imports backend/providers/base.py -l python` | happy — lang python |
| P10 | `tldr imports backend/providers/base.py -l brainfuck` | failure — bad lang |
| P11 | `tldr imports backend/providers/base.py --legacy-array` | happy — legacy array output |
| P12 | `tldr imports backend/providers/base.py -l typescript` | failure — lang mismatch |
| P13 | `tldr imports backend` | failure — directory arg |
| P14 | `tldr imports README.md` | failure — non-source file |
| P15 | `tldr imports backend/providers/yahoo.py -q` | happy — quiet |
| P16 | `tldr imports backend/providers/yahoo.py` | happy — cold daemon |
| P17 | `tldr imports backend/providers/yahoo.py` | happy — warm daemon |
| P18 | `tldr imports backend/providers/yahoo.py --legacy-array` | happy — warm daemon legacy array |
| P19 | `tldr imports backend/providers/base.py -l typescript` | failure — warm daemon lang mismatch |

---

## `tldr structure`

**Canonical syntax (from `tldr structure --help`):**
```
tldr structure [OPTIONS] [PATH]
```

| # | Command | Type |
|---|---------|------|
| P01 | `tldr structure backend/db.py` | happy — single file |
| P02 | `tldr structure backend` | happy-scale — directory |
| P04 | `tldr structure /no/such/path/definitely/missing` | failure — bad path |
| P05 | `tldr structure backend/db.py -f sarif` | failure — format rejected |
| P06 | `tldr structure backend/db.py -f text` | happy — text format |
| P07 | `tldr structure backend -m 5` | happy — max-results 5 |
| P08 | `tldr structure backend/db.py -l python` | happy — lang python |
| P09 | `tldr structure backend/db.py -l rust` | failure — lang mismatch |
| P10 | `tldr structure backend/db.py -f compact` | happy — compact format |
| P11 | `tldr structure /tmp/tldr-structure-empty` | failure — empty dir |
| P12 | `tldr structure backend/db.py` | happy — cold daemon |
| P13 | `tldr structure backend/db.py` | happy — warm daemon |

> **Note**: `--depth` does NOT exist on `tldr structure`. If the question needs depth-limited output, use `tldr tree` instead.

---

## `tldr tree`

**Canonical syntax (from `tldr tree --help`):**
```
tldr tree [OPTIONS] [PATH]
```

| # | Command | Type |
|---|---------|------|
| P01 | `tldr tree backend --ext .py` | happy |
| P02 | `tldr tree . --ext .py` | happy-scale |
| P04 | `tldr tree /no/such/path/definitely/missing` | failure — bad path |
| P05 | `tldr tree backend --ext .py -f sarif` | failure — format rejected |
| P06 | `tldr tree backend --ext .py -f text` | happy — text format |
| P07 | `tldr tree backend -H --ext .py` | happy — include hidden |
| P08 | `tldr tree . --ext .py --ext .js` | happy — multi-extension filter |
| P09 | `tldr tree backend` | happy — no ext filter (all files) |
| P10 | `tldr tree backend --ext .py -f compact` | happy — compact format |
| P11 | `tldr tree backend --ext .py` | happy — cold daemon |
