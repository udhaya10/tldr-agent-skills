# Verified CLI Invocations — `search` group

> **Protocol**: Before writing a `Usage:` block in any tool card or SKILL.md for commands
> in this group, copy the canonical syntax from this document. Do NOT reconstruct syntax
> from prose — that is how hallucinated flags get introduced.
>
> All probes in this document were run against a real codebase (Stock-Monitor,
> tldr-code v0.4.0) and their outputs are captured in the `.probes/` directories
> alongside the dossiers. Probe types: `happy` = working/verified, `failure` = error case.

---

## `tldr context`

**Canonical syntax (from `tldr context --help`):**
```
tldr context [OPTIONS] <ENTRY> [PATH]
```

| # | Command | Type |
|---|---------|------|
| P01 | `tldr context _to_finite_float backend -l python` | happy |
| P02 | `tldr context fetch_historical_data backend -l python` | happy-scale |
| P03 | `tldr context` | failure — missing entry arg |
| P04 | `tldr context some_fn /no/such/dir` | failure — bad path |
| P05 | `tldr context _to_finite_float backend -l python -f sarif` | failure — format rejected |
| P06 | `tldr context _to_finite_float backend -l python -f text` | happy — text format |
| P07 | `tldr context _to_finite_float backend -l python -f compact` | happy — compact format |
| P08 | `tldr context _to_finite_float backend -l python -f dot` | failure — format rejected |
| P09 | `tldr context fetch_historical_data backend -l python -d 1` | happy — depth 1 |
| P10 | `tldr context fetch_historical_data backend -l python -d 10` | happy — depth 10 |
| P11 | `tldr context _to_finite_float backend -l python --include-docstrings` | happy — with docstrings |
| P12 | `tldr context fetch_historical_data backend -l python --file backend/providers/yahoo.py` | happy — file filter |
| P13 | `tldr context backend/providers/yahoo.py:fetch_historical_data` | happy — shorthand path:name |
| P14 | `tldr context no_such_entry backend -l python` | failure — entry not found |
| P15 | `tldr context _to_finite_float backend -l brainfuck` | failure — bad lang |
| P16 | `tldr context _to_finite_float -p backend -l python` | happy — project alias (-p) |
| P17 | `tldr context _to_finite_float backend -l python -q` | happy — quiet |
| P18 | `tldr context fetch_historical_data backend -l python` | happy — cold daemon |
| P19 | `tldr context fetch_historical_data backend -l python` | happy — warm daemon |
| P20 | `tldr context fetch_historical_data backend -l python --file backend/providers/yahoo.py` | happy — warm daemon file filter |
| P21 | `tldr context _to_finite_float` | happy — default path (uses project root) |

---

## `tldr dice`

**Canonical syntax (from `tldr dice --help`):**
```
tldr dice [OPTIONS] <TARGET1> <TARGET2>
```

| # | Command | Type |
|---|---------|------|
| P01 | `tldr dice backend/providers/base.py backend/providers/base.py` | happy — same file |
| P02 | `tldr dice backend/providers/yahoo.py backend/providers/dhan.py` | happy-scale |
| P03 | `tldr dice backend/providers/yahoo.py` | failure — missing second target |
| P04 | `tldr dice /no/such/file.py backend/providers/yahoo.py` | failure — bad path |
| P05 | `tldr dice backend/providers/base.py backend/providers/base.py -f sarif` | failure — format rejected |
| P06 | `tldr dice backend/providers/yahoo.py backend/providers/dhan.py -f text` | happy — text format |
| P07 | `tldr dice backend/providers/yahoo.py backend/providers/dhan.py -f compact` | happy — compact format |
| P08 | `tldr dice backend/providers/base.py backend/providers/base.py -f dot` | failure — format rejected |
| P09 | `tldr dice backend/providers/yahoo.py backend/providers/dhan.py --normalize none` | happy — no normalization |
| P10 | `tldr dice backend/providers/yahoo.py backend/providers/dhan.py --normalize identifiers` | happy — normalize identifiers |
| P11 | `tldr dice backend/providers/yahoo.py backend/providers/dhan.py --normalize literals` | happy — normalize literals |
| P12 | `tldr dice backend/providers/yahoo.py backend/providers/dhan.py --normalize wat` | failure — bad normalize value |
| P13 | `tldr dice backend/providers/yahoo.py backend/providers/dhan.py --language python` | happy — language flag |
| P14 | `tldr dice backend/providers/yahoo.py::fetch_historical_data backend/providers/dhan.py::fetch_historical_data` | happy — function spec (:: syntax) |
| P15 | `tldr dice backend/providers/yahoo.py:38:80 backend/providers/dhan.py:48:100` | happy — block range (: syntax) |
| P16 | `tldr dice backend/providers/yahoo.py:99999:99999 backend/providers/base.py:99999:99999` | failure — block range out of range |
| P17 | `tldr dice backend/providers/yahoo.py backend/providers/dhan.py -o text` | happy — output flag |
| P18 | `tldr dice backend/providers/yahoo.py backend/providers/dhan.py -o text -f compact` | happy — output + format combination |
| P19 | `tldr dice backend/providers/base.py package.json` | failure — mixed languages |
| P20 | `tldr dice backend/providers/base.py:1:10 backend/providers/base.py:1:10` | happy — same block (score = 1.0) |
| P21 | `tldr dice backend/providers/base.py backend/providers/base.py -q` | happy — quiet |

---

## `tldr search`

**Canonical syntax (from `tldr search --help`):**
```
tldr search [OPTIONS] <QUERY> [PATH]
```

| # | Command | Type |
|---|---------|------|
| P01 | `tldr search "database" backend` | happy |
| P02 | `tldr search "database" .` | happy-scale |
| P03 | `tldr search` | failure — missing query arg |
| P04 | `tldr search "database" /no/such/path/definitely/missing` | failure — bad path |
| P05 | `tldr search "database" backend -f sarif` | failure — format rejected |
| P06 | `tldr search "database" backend -f text` | happy — text format |
| P07 | `tldr search "database" backend -k 3` | happy — top-k 3 |
| P08 | `tldr search "database" backend --no-callgraph` | happy — no callgraph |
| P09 | `tldr search "ensure_.*_table" backend --regex` | happy — regex mode |
| P10 | `tldr search "database connection" backend --hybrid ".*sqlite.*"` | happy — hybrid BM25+regex |
| P11 | `tldr search "x" backend --regex --hybrid "y"` | failure — regex and hybrid conflict |
| P12 | `tldr search "def" backend` | failure — all-stopwords query (zero results) |
| P13 | `tldr search "zzzqqqxxxnotapresent" backend` | happy — zero results (not an error) |
| P14 | `tldr search "database" backend -f compact` | happy — compact format |

---

## `tldr semantic`

**Canonical syntax (from `tldr semantic --help`):**
```
tldr semantic [OPTIONS] <QUERY> [PATH]
```

> **Note**: Requires tldr built with `--features semantic`. If `tldr semantic --help` returns
> `error: unrecognized subcommand 'semantic'`, reinstall with `--features semantic`.

| # | Command | Type |
|---|---------|------|
| P01 | `tldr semantic "database connection" backend/providers` | happy |
| P02 | `tldr semantic "database connection" backend` | happy-scale |
| P03 | `tldr semantic` | failure — missing query arg |
| P04 | `tldr semantic "x" /no/such/path/definitely/missing` | failure — bad path |
| P05 | `tldr semantic "database" backend/providers -f sarif` | failure — format rejected |
| P06 | `tldr semantic "database" backend/providers -f text` | happy — text format |
| P07 | `tldr semantic "database" backend/providers -n 3` | happy — top-3 results |
| P08 | `tldr semantic "database" backend/providers -t 0.8` | happy — high threshold |
| P09 | `tldr semantic "database" backend/providers -t 0.1` | happy — low threshold |
| P10 | `tldr semantic "database" backend/providers -m arctic-xs` | happy — model arctic-xs |
| P11 | `tldr semantic "database" backend/providers -m bogus-model` | failure — invalid model |
| P12 | `tldr semantic "database" backend/providers --langs py` | happy — filter by extension |
| P13 | `tldr semantic "database" backend/providers --langs python` | happy — filter by lang name |
| P14 | `tldr semantic "database" backend/providers --langs xyz` | failure — unknown lang filter |
| P15 | `tldr semantic "database" backend/providers --no-cache` | happy — bypass embedding cache |
| P16 | `tldr semantic "database" backend/providers -f compact` | happy — compact format |
| P17 | `tldr semantic "lookup external trading symbol for an asset" backend/providers` | happy — conceptual query |

---

## `tldr similar`

**Canonical syntax (from `tldr similar --help`):**
```
tldr similar [OPTIONS] <FILE>
```

| # | Command | Type |
|---|---------|------|
| P01 | `tldr similar backend/providers/base.py -p /path/to/project/backend/providers` | happy |
| P02 | `tldr similar backend/providers/yahoo.py -p /path/to/project/backend/providers` | happy-scale |
| P03 | `tldr similar` | failure — missing file arg |
| P04 | `tldr similar /no/such/file.py -p /path/to/project/backend/providers` | failure — bad path |
| P05 | `tldr similar backend/providers/base.py -p /path/to/project/backend/providers -f sarif` | failure — format rejected |
| P06 | `tldr similar backend/providers/base.py -p /path/to/project/backend/providers -f text` | happy — text format |
| P07 | `tldr similar backend/providers/base.py -p /path/to/project/backend/providers -f compact` | happy — compact format |
| P08 | `tldr similar backend/providers/base.py -p /path/to/project/backend/providers -f dot` | failure — format rejected |
| P09 | `tldr similar backend/providers/base.py -p /path/to/project/backend/providers -t 0.0` | happy — threshold zero |
| P10 | `tldr similar backend/providers/base.py -p /path/to/project/backend/providers -t 0.99` | happy — threshold high |
| P11 | `tldr similar backend/providers/base.py -p /path/to/project/backend/providers -n 1` | happy — top one |
| P12 | `tldr similar backend/providers/base.py -p /path/to/project/backend/providers -n 50` | happy — top fifty |
| P13 | `tldr similar backend/providers/base.py -p /path/to/project/backend/providers --by-chunk` | happy — by chunk |
| P14 | `tldr similar backend/providers/yahoo.py -F fetch_historical_data -p /path/to/project/backend/providers` | happy — function scope (-F is --function here, a real flag) |
| P15 | `tldr similar backend/providers/base.py -F HistoricalDataProvider -p /path/to/project/backend/providers` | failure — function missing |
| P16 | `tldr similar backend/providers/base.py -p /path/to/project/backend/providers --include-self` | happy — include self in results |
| P17 | `tldr similar backend/providers/base.py -p /path/to/project/backend/providers -m fake-model` | failure — bad model |
| P18 | `tldr similar backend/providers/base.py -p /path/to/project/backend/providers -m arctic-xs` | happy — model arctic-xs |
| P19 | `tldr similar backend/providers/base.py -p /path/to/project/backend/providers --no-cache` | happy — bypass embedding cache |
| P20 | `tldr similar backend/providers/base.py -p /path/to/project/backend/providers -q` | happy — quiet |
| P21 | `tldr similar backend/db.py -p /path/to/project/backend/providers` | failure — file outside scope dir |
| P22 | `tldr similar backend/providers/base.py -p backend/providers` | failure — relative path for -p (use absolute) |

> **Note on `-F`**: In `tldr similar`, `-F` is a legitimate short flag for `--function` (scope
> the similarity search to a specific function). This is NOT the same as the hallucinated `-F`
> flags that were introduced in the deep group. Do not confuse them.
