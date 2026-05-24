# Verified CLI Invocations — `trace` group

> **Protocol**: Before writing a `Usage:` block in any tool card or SKILL.md for commands
> in this group, copy the canonical syntax from this document. Do NOT reconstruct syntax
> from prose — that is how hallucinated flags get introduced.
>
> All probes in this document were run against a real codebase (Stock-Monitor,
> tldr-code v0.4.0) and their outputs are captured in the `.probes/` directories
> alongside the dossiers. Probe types: `happy` = working/verified, `failure` = error case.

---

## `tldr calls`

**Canonical syntax (from `tldr calls --help`):**
```
tldr calls [OPTIONS] [PATH]
```

| # | Command | Type |
|---|---------|------|
| P01 | `tldr calls backend/providers -l python` | happy |
| P02 | `tldr calls backend -l python` | happy-scale |
| P03 | (PATH defaults to `.` — no required arg) | N/A |
| P04 | `tldr calls /no/such/dir` | failure — bad path |
| P05 | `tldr calls backend/providers -l python -f sarif` | failure — format rejected |
| P06 | `tldr calls backend/providers -l python -f text` | happy — text format |
| P07 | `tldr calls backend/providers -l python -f compact` | happy — compact format |
| P08 | `tldr calls backend/providers -l python -f dot` | happy — dot format (graphviz) |
| P09 | `tldr calls backend -l python --max-items 5` | happy — max-items small |
| P10 | `tldr calls backend -l python --max-items 99999` | happy — max-items large |
| P11 | `tldr calls backend/providers -l python --respect-ignore=false` | happy — ignore .tldrignore |
| P12 | `tldr calls backend -l brainfuck` | failure — bad lang |
| P13 | `tldr calls /tmp/empty-dir` | failure — empty dir |
| P14 | `tldr calls . -l python --max-items 50` | happy — mixed root |
| P15 | `tldr calls backend/providers -l python -q` | happy — quiet |
| P16 | `tldr calls backend -l python` | happy — cold daemon |
| P17 | `tldr calls backend -l python` | happy — warm daemon |
| P18 | `tldr calls backend -l python -f dot` | happy — warm daemon dot format |
| P19 | `tldr calls backend -l python -f text` | happy — warm daemon text format |

---

## `tldr dead`

**Canonical syntax (from `tldr dead --help`):**
```
tldr dead [OPTIONS] [PATH]
```

> **Note**: `tldr dead` finds unreachable/dead **functions** at the project level.
> Do not confuse with `tldr dead-stores` (dead variable assignments inside one function).

| # | Command | Type |
|---|---------|------|
| P01 | `tldr dead backend/providers -l python` | happy |
| P02 | `tldr dead backend -l python` | happy-scale |
| P03 | (PATH defaults to `.` — no required arg) | N/A |
| P04 | `tldr dead /no/such/dir` | failure — bad path |
| P05 | `tldr dead backend/providers -l python -f sarif` | failure — format rejected |
| P06 | `tldr dead backend/providers -l python -f text` | happy — text format |
| P07 | `tldr dead backend/providers -l python -f compact` | happy — compact format |
| P08 | `tldr dead backend/providers -l python -f dot` | failure — format rejected |
| P09 | `tldr dead backend -l python --max-items 1` | happy — max-items small |
| P10 | `tldr dead backend -l python --max-items 99999` | happy — max-items large |
| P11 | `tldr dead backend/providers -l python --call-graph` | happy — call-graph mode |
| P12 | `tldr dead backend/providers -l python --entry-points fetch_historical_data,fetch_quotes` | happy — explicit entry points |
| P13 | `tldr dead backend/providers -l python --no-default-ignore` | happy — include test/example files |
| P14 | `tldr dead backend -l brainfuck` | failure — bad lang |
| P15 | `tldr dead /tmp/empty-dir` | failure — empty dir |
| P16 | `tldr dead backend/providers -l python -q` | happy — quiet |
| P17 | `tldr dead backend -l python` | happy — cold daemon |
| P18 | `tldr dead backend -l python` | happy — warm daemon |
| P19 | `tldr dead backend/providers -l python --call-graph` | happy — warm daemon call-graph |

---

## `tldr hubs`

**Canonical syntax (from `tldr hubs --help`):**
```
tldr hubs [OPTIONS] [PATH]
```

| # | Command | Type |
|---|---------|------|
| P01 | `tldr hubs backend/providers -l python` | happy |
| P02 | `tldr hubs backend -l python` | happy-scale |
| P03 | (PATH defaults to `.` — no required arg) | N/A |
| P04 | `tldr hubs /no/such/dir` | failure — bad path |
| P05 | `tldr hubs backend/providers -l python -f sarif` | failure — format rejected |
| P06 | `tldr hubs backend/providers -l python -f text` | happy — text format |
| P07 | `tldr hubs backend/providers -l python -f compact` | happy — compact format |
| P08 | `tldr hubs backend/providers -l python -f dot` | happy — dot format (graphviz) |
| P09 | `tldr hubs backend -l python --top 1` | happy — top one |
| P10 | `tldr hubs backend -l python --top 100` | happy — top hundred |
| P11 | `tldr hubs backend -l python --algorithm indegree` | happy — indegree algorithm |
| P12 | `tldr hubs backend -l python --algorithm pagerank` | happy — pagerank algorithm |
| P13 | `tldr hubs backend -l python --algorithm betweenness` | happy — betweenness algorithm |
| P14 | `tldr hubs backend -l python --algorithm wat` | failure — bad algorithm |
| P15 | `tldr hubs backend -l python --threshold 0.5` | happy — threshold mid |
| P16 | `tldr hubs backend -l python --threshold 0.99` | happy — threshold high |
| P17 | `tldr hubs backend -l python --threshold 1.5` | failure — threshold out of range |
| P18 | `tldr hubs backend -l python --threshold -0.1` | failure — threshold negative |
| P19 | `tldr hubs backend -l brainfuck` | failure — bad lang |
| P20 | `tldr hubs backend/providers/base.py` | happy — file arg (single file) |
| P21 | `tldr hubs /tmp/empty-dir` | failure — empty dir |
| P22 | `tldr hubs backend/providers -l python -q` | happy — quiet |

---

## `tldr impact`

**Canonical syntax (from `tldr impact --help`):**
```
tldr impact [OPTIONS] <FUNCTION> [PATH]
```

| # | Command | Type |
|---|---------|------|
| P01 | `tldr impact get_db_connection backend` | happy |
| P02 | `tldr impact get_db_connection .` | happy-scale |
| P03 | `tldr impact` | failure — missing function arg |
| P04 | `tldr impact get_db_connection /no/such/path/definitely/missing` | failure — bad path |
| P05 | `tldr impact get_db_connection backend -f sarif` | failure — format rejected |
| P06 | `tldr impact get_db_connection backend -f text` | happy — text format |
| P07 | `tldr impact get_db_connection backend -f dot` | happy — dot format (graphviz) |
| P08 | `tldr impact get_db_connection backend -d 1` | happy — depth 1 |
| P09 | `tldr impact get_db_connection backend -d 10` | happy — depth 10 |
| P10 | `tldr impact get_db_connection backend --file backend/api.py` | happy — file filter |
| P11 | `tldr impact get_db_connection backend --type-aware` | happy — type-aware mode |
| P12 | `tldr impact zzz_nonexistent_function backend` | failure — function not found |
| P13 | `tldr impact get_db_connection backend/db.py` | happy — file as path (single file) |
| P14 | `tldr impact get_db_connection backend -f compact` | happy — compact format |
| P15 | `tldr impact get_db_connection backend` | happy — cold daemon |
| P16 | `tldr impact get_db_connection backend` | happy — warm daemon |

---

## `tldr references`

**Canonical syntax (from `tldr references --help`):**
```
tldr references [OPTIONS] <SYMBOL> [PATH]
```

| # | Command | Type |
|---|---------|------|
| P01 | `tldr references _to_finite_float backend -l python` | happy |
| P02 | `tldr references Provider backend -l python` | happy-scale |
| P03 | `tldr references` | failure — missing symbol arg |
| P04 | `tldr references foo /no/such/dir` | failure — bad path |
| P05 | `tldr references _to_finite_float backend -l python -f sarif` | failure — format rejected |
| P06 | `tldr references _to_finite_float backend -l python -f text` | happy — text format |
| P07 | `tldr references _to_finite_float backend -l python -f compact` | happy — compact format |
| P08 | `tldr references _to_finite_float backend -l python -f dot` | failure — format rejected |
| P09 | `tldr references _to_finite_float backend -l python --limit 2` | happy — limit small |
| P10 | `tldr references _to_finite_float backend -l python --limit 0` | failure — limit zero |
| P11 | `tldr references _to_finite_float backend -l python --include-definition` | happy — include definition site |
| P12 | `tldr references _to_finite_float backend -l python --kinds call` | happy — call kind only |
| P13 | `tldr references pandas backend -l python --kinds import --limit 5` | happy — import kind only |
| P14 | `tldr references _to_finite_float backend -l python --kinds invalid_kind` | failure — bad kind |
| P15 | `tldr references _to_finite_float backend/providers/yahoo.py -l python -s file` | happy — file scope |
| P16 | `tldr references symbol backend/providers/yahoo.py -l python -s local` | happy — local scope |
| P17 | `tldr references _to_finite_float backend -l python -s solar_system` | failure — bad scope |
| P18 | `tldr references _to_finite_float backend -l python -C 3` | happy — context lines |
| P19 | `tldr references _to_finite_float backend -l python --min-confidence 0.99` | happy — high confidence filter |
| P20 | `tldr references _to_finite_float backend -l python --min-confidence 2.0` | failure — confidence out of range |
| P21 | `tldr references no_such_symbol_anywhere backend -l python` | happy — zero results (not an error) |
| P22 | `tldr references _to_finite_float backend -l python -o text` | happy — legacy output flag |
| P23 | `tldr references _to_finite_float backend -l brainfuck` | failure — bad lang |
| P24 | `tldr references _to_finite_float backend -l python -q` | happy — quiet |

---

## `tldr whatbreaks`

**Canonical syntax (from `tldr whatbreaks --help`):**
```
tldr whatbreaks [OPTIONS] <TARGET> [PATH]
```

| # | Command | Type |
|---|---------|------|
| P01 | `tldr whatbreaks fetch_historical_data backend -l python` | happy — function target |
| P02 | `tldr whatbreaks backend/providers/base.py backend -l python` | happy — file target |
| P03 | `tldr whatbreaks` | failure — missing target arg |
| P04 | `tldr whatbreaks foo /no/such/dir` | failure — bad path |
| P05 | `tldr whatbreaks fetch_historical_data backend -l python -f sarif` | failure — format rejected |
| P06 | `tldr whatbreaks fetch_historical_data backend -l python -f text` | happy — text format |
| P07 | `tldr whatbreaks fetch_historical_data backend -l python -f compact` | happy — compact format |
| P08 | `tldr whatbreaks fetch_historical_data backend -l python -f dot` | failure — format rejected |
| P09 | `tldr whatbreaks backend/providers/base.py backend -l python --type function` | happy — force function type |
| P10 | `tldr whatbreaks fetch_historical_data backend -l python --type file` | happy — force file type |
| P11 | `tldr whatbreaks backend.providers.base backend -l python --type module` | happy — module type |
| P12 | `tldr whatbreaks foo backend -l python --type widget` | failure — bad type |
| P13 | `tldr whatbreaks fetch_historical_data backend -l python -d 1` | happy — depth 1 |
| P14 | `tldr whatbreaks fetch_historical_data backend -l python -d 10` | happy — depth 10 |
| P15 | `tldr whatbreaks backend/providers/base.py backend -l python --quick` | happy — quick mode |
| P16 | `tldr whatbreaks foo backend/providers/base.py` | happy — file as path |
| P17 | `tldr whatbreaks fetch_historical_data backend -l brainfuck` | failure — bad lang |
| P18 | `tldr whatbreaks no_such_function_anywhere backend -l python` | happy — zero results (not an error) |
| P19 | `tldr whatbreaks fetch_historical_data backend -l python -q` | happy — quiet |
| P20 | `tldr whatbreaks backend.providers.base backend -l python` | happy — module autodetect |
