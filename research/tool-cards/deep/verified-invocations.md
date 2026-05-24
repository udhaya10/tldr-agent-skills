# Verified CLI Invocations — `deep` group

> **Protocol**: Before writing a `Usage:` block in any tool card or SKILL.md for commands
> in this group, copy the canonical syntax from this document. Do NOT reconstruct syntax
> from prose — that is how hallucinated flags get introduced.
>
> All probes in this document were run against a real codebase (Stock-Monitor,
> tldr-code v0.4.0) and their outputs are captured in the `.probes/` directories
> alongside the dossiers. Probe types: `happy` = working/verified, `failure` = error case.

---

## `tldr slice`

**Canonical syntax (from `tldr slice --help`):**
```
tldr slice [OPTIONS] <FILE> <FUNCTION> <LINE>
```

| # | Command | Type |
|---|---------|------|
| P01 | `tldr slice backend/db.py get_db_connection 49` | happy |
| P02 | `tldr slice backend/scripts/apply_classification_theme_workbook.py apply_rows_to_database 130` | happy-scale |
| P03 | `tldr slice` | failure — missing args |
| P04 | `tldr slice /no/such/file.py foo 1` | failure — bad path |
| P05 | `tldr slice backend/db.py get_db_connection 49 -f sarif` | failure — format rejected |
| P06 | `tldr slice backend/db.py get_db_connection 49 -f text` | happy — text format |
| P07 | `tldr slice backend/db.py get_db_connection 49 -d forward` | happy — forward direction |
| P08 | `tldr slice backend/db.py get_db_connection 49 --variable conn` | happy — variable filter |
| P09 | `tldr slice backend/db.py get_db_connection 9999` | failure — line out of range (exit 0, check explanation) |
| P10 | `tldr slice backend/db.py zzz_no_such_function 49` | failure — function not in file |
| P11 | `tldr slice backend/db.py get_db_connection 0` | failure — line zero |
| P12 | `tldr slice backend/db.py get_db_connection 48` | happy — line at declaration |
| P13 | `tldr slice backend/db.py get_db_connection 49 -f compact` | happy — compact format |
| P14 | `tldr slice backend/db.py get_db_connection 49` | happy — cold daemon |
| P15 | `tldr slice backend/db.py get_db_connection 49` | happy — warm daemon |
| P16 | `tldr extract backend/db.py \| jq -r '.functions[] \| select(.name=="is_sqlite_lock_error") \| .line' \| xargs -I {} tldr slice backend/db.py is_sqlite_lock_error {}` | happy — composition with extract |

---

## `tldr chop`

**Canonical syntax (from `tldr chop --help`):**
```
tldr chop [OPTIONS] <file> <function> <source_line> <target_line>
```

| # | Command | Type |
|---|---------|------|
| P01 | `tldr chop backend/providers/yahoo.py _to_finite_float 21 25` | happy |
| P02 | `tldr chop backend/providers/yahoo.py fetch_historical_data 40 80` | happy-scale |
| P03 | `tldr chop backend/providers/yahoo.py _to_finite_float 20` | failure — missing target line |
| P04 | `tldr chop /no/such/file.py some_fn 1 10` | failure — bad path |
| P05 | `tldr chop backend/providers/yahoo.py _to_finite_float 21 25 -f sarif` | failure — format rejected |
| P06 | `tldr chop backend/providers/yahoo.py _to_finite_float 21 25 -f text` | happy — text format |
| P07 | `tldr chop backend/providers/yahoo.py _to_finite_float 21 25 -f compact` | happy — compact format |
| P08 | `tldr chop backend/providers/yahoo.py _to_finite_float 21 25 -f dot` | failure — format rejected |
| P09 | `tldr chop backend/providers/yahoo.py _to_finite_float 20 20` | happy — same-line (special case, not error) |
| P10 | `tldr chop backend/providers/yahoo.py _to_finite_float 25 20` | happy — reversed order (silent, still works) |
| P11 | `tldr chop backend/providers/yahoo.py no_such_function 10 20` | failure — function not found (exit 0, path_exists: false) |
| P12 | `tldr chop backend/providers/yahoo.py _to_finite_float 99999 100000` | failure — source out of range (exit 0, path_exists: false) |
| P13 | `tldr chop backend/providers/yahoo.py _to_finite_float 20 99999` | failure — target out of range (exit 0, path_exists: false) |
| P14 | `tldr chop backend/providers/yahoo.py _to_finite_float 20 24 -l brainfuck` | failure — bad lang |
| P14a | `tldr chop backend/providers/yahoo.py _to_finite_float 20 24` | happy — empty PDG node |
| P15 | `tldr chop backend/providers/yahoo.py _to_finite_float 21 25 -o text` | happy — output flag |
| P16 | `tldr chop README.md anything 1 10` | failure — non-source file |
| P17 | `tldr chop backend/providers/yahoo.py _to_finite_float 21 25 -q` | happy — quiet |
| P18 | `tldr chop backend/providers/yahoo.py _to_finite_float -5 24` | failure — negative line |
| P19 | `tldr chop backend/providers/yahoo.py _to_finite_float 0 24` | failure — zero line |

---

## `tldr reaching-defs`

**Canonical syntax (from `tldr reaching-defs --help`):**
```
tldr reaching-defs [OPTIONS] <FILE> <FUNCTION>
```

| # | Command | Type |
|---|---------|------|
| P01 | `tldr reaching-defs backend/providers/yahoo.py _to_finite_float` | happy |
| P02 | `tldr reaching-defs backend/providers/yahoo.py fetch_historical_data` | happy-scale |
| P03 | `tldr reaching-defs backend/providers/yahoo.py` | failure — missing function arg |
| P04 | `tldr reaching-defs /no/such/file.py some_fn` | failure — bad path |
| P05 | `tldr reaching-defs backend/providers/yahoo.py _to_finite_float -f sarif` | failure — format rejected |
| P06 | `tldr reaching-defs backend/providers/yahoo.py _to_finite_float -f text` | happy — text format |
| P07 | `tldr reaching-defs backend/providers/yahoo.py _to_finite_float -f compact` | happy — compact format |
| P08 | `tldr reaching-defs backend/providers/yahoo.py _to_finite_float -f dot` | failure — format rejected |
| P09 | `tldr reaching-defs backend/providers/yahoo.py fetch_historical_data --var df` | happy — variable filter |
| P10 | `tldr reaching-defs backend/providers/yahoo.py fetch_historical_data --line 60` | happy — line filter |
| P11 | `tldr reaching-defs backend/providers/yahoo.py _to_finite_float --show-in-out` | happy — show in/out sets |
| P12 | `tldr reaching-defs backend/providers/yahoo.py fetch_historical_data --chains-only` | happy — chains only |
| P13 | `tldr reaching-defs backend/providers/yahoo.py _to_finite_float --show-chains=false` | failure — flag rejected by clap |
| P14 | `tldr reaching-defs backend/providers/yahoo.py _to_finite_float --show-uninitialized=false` | failure — flag rejected by clap |
| P15 | `tldr reaching-defs backend/providers/yahoo.py fetch_historical_data --params 'self,symbol,start_date,end_date'` | happy — suppress false positives on params |
| P16 | `tldr reaching-defs backend/providers/yahoo.py no_such_function` | failure — function not found (exit 20) |
| P17 | `tldr reaching-defs backend/providers/yahoo.py _to_finite_float -l brainfuck` | failure — bad lang |
| P18 | `tldr reaching-defs backend/providers/yahoo.py _to_finite_float --var nonexistent_var` | failure — var not found |
| P19 | `tldr reaching-defs backend/providers/yahoo.py _to_finite_float --line 999999` | failure — line out of range |
| P20 | `tldr reaching-defs backend/providers/yahoo.py _to_finite_float -q` | happy — quiet |
| P21 | `tldr reaching-defs README.md anything` | failure — non-source file |

---

## `tldr available`

**Canonical syntax (from `tldr available --help`):**
```
tldr available [OPTIONS] <FILE> <FUNCTION>
```

| # | Command | Type |
|---|---------|------|
| P01 | `tldr available backend/providers/yahoo.py _to_finite_float` | happy |
| P02 | `tldr available backend/providers/yahoo.py fetch_historical_data` | happy-scale |
| P03 | `tldr available backend/providers/yahoo.py` | failure — missing function arg |
| P04 | `tldr available /no/such/file.py some_fn` | failure — bad path |
| P05 | `tldr available backend/providers/yahoo.py _to_finite_float -f sarif` | failure — format rejected |
| P06 | `tldr available backend/providers/yahoo.py _to_finite_float -f text` | happy — text format |
| P07 | `tldr available backend/providers/yahoo.py _to_finite_float -f compact` | happy — compact format |
| P08 | `tldr available backend/providers/yahoo.py _to_finite_float -f dot` | failure — format rejected |
| P09 | `tldr available backend/providers/yahoo.py _to_finite_float --check 'float(value)'` | happy — check specific expression |
| P10 | `tldr available backend/providers/yahoo.py _to_finite_float --at-line 21` | happy — filter to line |
| P11 | `tldr available backend/providers/yahoo.py _to_finite_float --killed-by 'value'` | happy — killed-by query |
| P12 | `tldr available backend/providers/yahoo.py _to_finite_float --cse-only` | happy — text-only flag (no-op in JSON) |
| P13 | `tldr available backend/providers/yahoo.py no_such_function` | failure — function not found |
| P14 | `tldr available backend/providers/yahoo.py _to_finite_float -l brainfuck` | failure — bad lang |
| P15 | `tldr available README.md anything` | failure — non-source file |
| P16 | `tldr available backend/providers/yahoo.py _to_finite_float --check 'totally_made_up'` | failure — expression not found |
| P17 | `tldr available backend/providers/yahoo.py _to_finite_float --at-line 999999` | failure — line out of range |
| P18 | `tldr available backend/providers/yahoo.py _to_finite_float -q` | happy — quiet |

---

## `tldr dead-stores`

**Canonical syntax (from `tldr dead-stores --help`):**
```
tldr dead-stores [OPTIONS] <file> <function>
```

| # | Command | Type |
|---|---------|------|
| P01 | `tldr dead-stores backend/providers/yahoo.py _to_finite_float` | happy |
| P02 | `tldr dead-stores backend/providers/yahoo.py fetch_historical_data` | happy-scale |
| P03 | `tldr dead-stores backend/providers/yahoo.py` | failure — missing function arg |
| P04 | `tldr dead-stores /no/such/file.py some_fn` | failure — bad path |
| P05 | `tldr dead-stores backend/providers/yahoo.py _to_finite_float -f sarif` | failure — format rejected |
| P06 | `tldr dead-stores backend/providers/yahoo.py _to_finite_float -f text` | happy — text format |
| P07 | `tldr dead-stores backend/providers/yahoo.py _to_finite_float -f compact` | happy — compact format |
| P08 | `tldr dead-stores backend/providers/yahoo.py _to_finite_float -f dot` | failure — format rejected |
| P09 | `tldr dead-stores backend/providers/yahoo.py fetch_historical_data --compare` | happy — SSA + live-vars comparison |
| P10 | `tldr dead-stores backend/providers/yahoo.py no_such_function` | failure — function not found (exit 1, NOT exit 20) |
| P11 | `tldr dead-stores backend/providers/yahoo.py _to_finite_float -l brainfuck` | failure — bad lang |
| P12 | `tldr dead-stores README.md anything` | failure — non-source file |
| P13 | `tldr dead-stores backend/providers/yahoo.py _to_finite_float -o text` | happy — output flag |
| P14 | `tldr dead-stores backend/providers/yahoo.py _to_finite_float -q` | happy — quiet |
| P15 | `tldr dead-stores backend anything` | failure — directory arg |
| P16 | `tldr dead-stores backend/providers/yahoo.py _to_finite_float -l python` | happy — explicit lang |
| P17 | `tldr dead-stores backend/providers/yahoo.py _to_finite_float -l typescript` | failure — lang mismatch |
