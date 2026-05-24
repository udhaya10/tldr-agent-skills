# Verified CLI Invocations — `ops` group

> **Protocol**: Before writing a `Usage:` block in any tool card or SKILL.md for commands
> in this group, copy the canonical syntax from this document. Do NOT reconstruct syntax
> from prose — that is how hallucinated flags get introduced.
>
> All probes in this document were run against a real codebase (Stock-Monitor,
> tldr-code v0.4.0) and their outputs are captured in the `.probes/` directories
> alongside the dossiers. Probe types: `happy` = working/verified, `failure` = error case.

---

## `tldr cache`

**Canonical syntax (from `tldr cache --help`):**
```
tldr cache [OPTIONS] <COMMAND>
```

> **Subcommands**: `stats`, `clear`, `help`. Invoke as `tldr cache stats` / `tldr cache clear`.

| # | Command | Type |
|---|---------|------|
| P01 | `tldr cache stats` | happy |
| P02 | `tldr cache stats --project .` | happy-scale |
| P03 | `tldr cache` | failure — missing subcommand |
| P04 | `tldr cache stats --project /no/such/dir` | failure — bad path |
| P05 | `tldr cache stats -f sarif` | failure — format rejected |
| P06 | `tldr cache stats -f text` | happy — text format |
| P07 | `tldr cache stats -f compact` | happy — compact format |
| P08 | `tldr cache stats -f dot` | failure — format rejected |
| P09 | `tldr cache stats -p .` | happy — short -p flag |
| P10 | `tldr cache clear --project /tmp/test-cache-dir` | happy — clear cache for project |
| P11 | `tldr cache clear --project /no/such/dir` | failure — bad path on clear |
| P12 | `tldr cache help` | happy — shows help |
| P13 | `tldr cache wat` | failure — unknown subcommand |
| P14 | `tldr cache stats -l brainfuck` | failure — bad lang |
| P15 | `tldr cache stats -l python` | happy — lang python |
| P16 | `tldr cache stats -q` | happy — quiet |
| P17 | `tldr cache stats --project /tmp/empty-no-cache-dir` | happy — no cache (empty result, not error) |

---

## `tldr change-impact`

**Canonical syntax (from `tldr change-impact --help`):**
```
tldr change-impact [OPTIONS] [PATH]
```

| # | Command | Type |
|---|---------|------|
| P01 | `tldr change-impact` | happy — unstaged changes in current dir |
| P02 | `tldr change-impact -F backend/providers/yahoo.py,backend/providers/dhan.py` | happy-scale — explicit files |
| P03 | (PATH defaults to `.` — no required arg) | N/A |
| P04 | `tldr change-impact /no/such/dir` | failure — bad path |
| P05 | `tldr change-impact -f sarif` | failure — format rejected |
| P06 | `tldr change-impact -f text` | happy — text format |
| P07 | `tldr change-impact -f compact` | happy — compact format |
| P08 | `tldr change-impact -f dot` | failure — format rejected |
| P09 | `tldr change-impact --base origin/main` | happy — diff against origin/main |
| P10 | `tldr change-impact --base HEAD~1` | happy — diff against HEAD~1 |
| P11 | `tldr change-impact --staged` | happy — staged changes only |
| P12 | `tldr change-impact --uncommitted` | happy — all uncommitted changes |
| P13 | `tldr change-impact -F backend/providers/yahoo.py --depth 1` | happy — depth 1 |
| P14 | `tldr change-impact -F backend/providers/yahoo.py --depth 0` | failure — depth zero |
| P15 | `tldr change-impact -F backend/providers/yahoo.py --include-imports` | happy — include import side-effects |
| P16 | `tldr change-impact -F backend/providers/yahoo.py --test-patterns '*_test.py,test_*.py'` | happy — custom test patterns |
| P17 | `tldr change-impact -F backend/providers/yahoo.py --runner pytest` | happy — runner pytest |
| P18 | `tldr change-impact -F backend/providers/yahoo.py --runner jest` | happy — runner jest |
| P19 | `tldr change-impact --runner wat` | failure — bad runner |
| P20 | `tldr change-impact -F backend/providers/yahoo.py --runner cargo-test` | happy — runner cargo-test |
| P21 | `tldr change-impact -l brainfuck` | failure — bad lang |
| P22 | `tldr change-impact -l python` | happy — lang python |
| P23 | `tldr change-impact -l typescript` | failure — lang mismatch |
| P24 | `tldr change-impact backend/providers/yahoo.py` | happy — file as path |
| P25 | `tldr change-impact /tmp/empty-dir` | failure — empty dir |
| P26 | `tldr change-impact /tmp/non-git-dir` | failure — not a git repo |
| P27 | `tldr change-impact -q` | happy — quiet |

---

## `tldr daemon`

**Canonical syntax (from `tldr daemon --help`):**
```
tldr daemon [OPTIONS] <COMMAND>
```

> **Subcommands**: `start`, `stop`, `status`, `list`, `query`, `notify`.
> The daemon is per-project. Always check-first before starting:
> `tldr daemon status | grep -q '"not_running"' && tldr daemon start`

| # | Command | Type |
|---|---------|------|
| P01 | `tldr daemon status` | happy |
| P02 | `tldr daemon start && tldr daemon status && tldr daemon stop` | happy-scale — lifecycle |
| P03 | `tldr daemon` | failure — missing subcommand |
| P04 | `tldr daemon status --project /no/such/dir` | failure — bad path |
| P05 | `tldr daemon status -f sarif` | failure — format rejected |
| P06 | `tldr daemon status -f text` | happy — text format |
| P07 | `tldr daemon status -f compact` | happy — compact format |
| P08 | `tldr daemon status -f dot` | failure — format rejected |
| P09 | `tldr daemon start --project .` | happy — start for project |
| P10 | `tldr daemon start --project .` (already running) | happy — idempotent start |
| P11 | `tldr daemon list` | happy — list all running daemons |
| P12 | `tldr daemon status` (running) | happy — shows running status with Salsa counters |
| P13 | `tldr daemon query ping` | happy — ping query |
| P14 | `tldr daemon query wat` | failure — bad query type |
| P15 | `tldr daemon query status --json '{}'` | happy — query with JSON payload |
| P16 | `tldr daemon query status --json '{ malformed'` | failure — malformed JSON |
| P17 | `tldr daemon notify backend/providers/yahoo.py` | happy — notify file changed |
| P18 | `tldr daemon notify /no/such/file.py` | failure — bad path |
| P19 | `tldr daemon stop --project .` | happy — stop for project |
| P20 | `tldr daemon stop --project .` (not running) | happy — idempotent stop |
| P21 | `tldr daemon stop --all` | happy — stop all daemons |
| P22 | `tldr daemon status` (not running) | happy — shows not_running |
| P23 | `tldr daemon list` (empty) | happy — empty list |
| P24 | `tldr daemon wat` | failure — unknown subcommand |
| P25 | `tldr daemon status -l brainfuck` | failure — bad lang |
| P26 | `tldr daemon status -q` | happy — quiet |
| P27 | `timeout 1 tldr daemon start --foreground 2>&1 \| head -5` | happy — foreground mode (runs until killed) |

---

## `tldr deps`

**Canonical syntax (from `tldr deps --help`):**
```
tldr deps [OPTIONS] [PATH]
```

| # | Command | Type |
|---|---------|------|
| P01 | `tldr deps backend/providers` | happy |
| P02 | `tldr deps backend` | happy-scale |
| P03 | (PATH defaults to `.` — no required arg) | N/A |
| P04 | `tldr deps /no/such/dir` | failure — bad path |
| P05 | `tldr deps backend/providers -f sarif` | failure — format rejected |
| P06 | `tldr deps backend/providers -f text` | happy — text format |
| P07 | `tldr deps backend/providers -f compact` | happy — compact format |
| P08 | `tldr deps backend/providers -f dot` | happy — dot format (graphviz) |
| P09 | `tldr deps backend/providers --include-external` | happy — include external deps |
| P10 | `tldr deps backend/providers --collapse-packages` | happy — collapse package tree |
| P11 | `tldr deps backend --depth 1` | happy — depth 1 |
| P12 | `tldr deps backend --depth 0` | failure — depth zero |
| P13 | `tldr deps backend --show-cycles` | happy — highlight cycles |
| P14 | `tldr deps backend --max-cycle-length 1` | happy — short cycles only |
| P15 | `tldr deps backend -l python` | happy — lang python |
| P16 | `tldr deps backend -l typescript` | failure — lang mismatch |
| P17 | `tldr deps backend -l brainfuck` | failure — bad lang |
| P18 | `tldr deps backend/providers -o text` | happy — output flag text |
| P19 | `tldr deps backend/providers -o dot` | happy — output flag dot |
| P20 | `tldr deps backend/providers -o wat` | failure — bad output value |
| P21 | `tldr deps /tmp/empty-dir` | failure — empty dir |
| P22 | `tldr deps README.md` | failure — non-source file |
| P23 | `tldr deps backend/providers/yahoo.py` | happy — file as path (single file deps) |
| P24 | `tldr deps backend/providers -q` | happy — quiet |

---

## `tldr diff`

**Canonical syntax (from `tldr diff --help`):**
```
tldr diff [OPTIONS] <FILE_A> <FILE_B>
```

| # | Command | Type |
|---|---------|------|
| P01 | `tldr diff backend/providers/yahoo.py backend/providers/dhan.py` | happy |
| P02 | `tldr diff backend/providers backend --granularity file` | happy-scale — dir diff |
| P03 | `tldr diff backend/providers/yahoo.py` | failure — missing second arg |
| P04 | `tldr diff /no/such/a.py backend/providers/yahoo.py` | failure — bad path |
| P05 | `tldr diff backend/providers/yahoo.py backend/providers/dhan.py -f sarif` | failure — format rejected |
| P06 | `tldr diff backend/providers/yahoo.py backend/providers/dhan.py -f text` | happy — text format |
| P07 | `tldr diff backend/providers/yahoo.py backend/providers/dhan.py -f compact` | happy — compact format |
| P08 | `tldr diff backend/providers/yahoo.py backend/providers/dhan.py -f dot` | failure — format rejected |
| P09 | `tldr diff backend/providers/yahoo.py backend/providers/dhan.py -g token` | happy — token granularity |
| P10 | `tldr diff backend/providers/yahoo.py backend/providers/dhan.py -g expression` | happy — expression granularity |
| P11 | `tldr diff backend/providers/yahoo.py backend/providers/dhan.py -g statement` | happy — statement granularity |
| P12 | `tldr diff backend/providers/yahoo.py backend/providers/dhan.py -g class` | happy — class granularity |
| P13 | `tldr diff backend/providers backend/providers -g file` | happy — file granularity |
| P14 | `tldr diff backend/providers backend/providers -g module` | happy — module granularity |
| P15 | `tldr diff backend backend -g architecture` | happy — architecture granularity |
| P16 | `tldr diff backend/providers/yahoo.py backend/providers/dhan.py -g wat` | failure — bad granularity |
| P17 | `tldr diff backend/providers/yahoo.py backend/providers/dhan.py --semantic-only` | happy — semantic-only mode |
| P18 | `tldr diff backend/providers/yahoo.py backend/providers/dhan.py -O /tmp/diff-out.json` | happy — output file |
| P19 | `tldr diff backend/providers/yahoo.py backend/providers/yahoo.py` | happy — identical files (score = 1.0) |
| P20 | `tldr diff backend/providers/yahoo.py backend/providers/dhan.py -l brainfuck` | failure — bad lang |
| P21 | `tldr diff backend/providers/yahoo.py backend/providers/dhan.py -l python` | happy — lang python |
| P22 | `tldr diff backend/providers/yahoo.py backend/providers/dhan.py -l typescript` | failure — lang mismatch |
| P23 | `tldr diff backend backend/providers/yahoo.py` | failure — dir vs file mismatch |
| P24 | `tldr diff backend/providers/yahoo.py backend/providers/dhan.py -q` | happy — quiet |

---

## `tldr doctor`

**Canonical syntax (from `tldr doctor --help`):**
```
tldr doctor [OPTIONS]
```

| # | Command | Type |
|---|---------|------|
| P01 | `tldr doctor` | happy |
| P02 | `tldr doctor -f json -q` | happy-scale |
| P03 | (no required args) | N/A |
| P04 | `tldr doctor --install brainfuck` | failure — unknown language |
| P05 | `tldr doctor -f sarif` | failure — format rejected |
| P06 | `tldr doctor -f text` | happy — text format |
| P07 | `tldr doctor -f compact` | happy — compact format |
| P08 | `tldr doctor -f dot` | failure — format rejected |
| P09 | `tldr doctor --install python` | SKIPPED — would actually install analyzer |
| P10 | `tldr doctor --install wat` | failure — unknown lang for install |
| P11 | `tldr doctor -l python` | happy — lang python filter |
| P12 | `tldr doctor -l typescript` | happy — lang typescript filter |
| P13 | `tldr doctor -l brainfuck` | failure — bad lang |
| P14 | `tldr doctor -q` | happy — quiet |
| P15 | `tldr doctor --install python --install rust` | SKIPPED — would install multiple |
| P16 | `tldr doctor --install ''` | failure — empty install arg |
| P17 | `cd /tmp/test-dir && tldr doctor -f json -q` | happy — from unrelated dir |

---

## `tldr stats`

**Canonical syntax (from `tldr stats --help`):**
```
tldr stats [OPTIONS]
```

> **v0.4.0 known bug**: `tldr stats` always returns empty data. Most commands bypass the
> daemon (`try_daemon_route` falls back to direct). Even the 8 that do route never write
> to `~/.tldr/stats.jsonl`. Use `tldr daemon status` Salsa counters as the routing health
> signal instead. Do not troubleshoot empty stats in v0.4.0.

| # | Command | Type |
|---|---------|------|
| P01 | `tldr stats` | happy — always empty in v0.4.0 |
| P02 | `tldr stats -f text` | happy — text format |
| P03 | (no required args) | N/A |
| P04 | (no PATH/file arg) | N/A |
| P05 | `tldr stats -f sarif` | failure — format rejected |
| P06 | `tldr stats -f text` | happy — text format |
| P07 | `tldr stats -f compact` | happy — compact format |
| P08 | `tldr stats -f dot` | failure — format rejected |
| P09 | `tldr stats -f json` | happy — json format |
| P10 | `tldr stats -l brainfuck` | failure — bad lang |
| P11 | `tldr stats -l python` | happy — lang python |
| P12 | `tldr stats -q` | happy — quiet |
| P13 | `tldr stats -v` | happy — verbose (same as default in v0.4.0) |
| P14 | `cd /tmp/test-dir && tldr stats` | happy — from unrelated dir |
| P15 | `tldr stats extra-positional` | failure — unexpected positional arg |

---

## `tldr surface`

**Canonical syntax (from `tldr surface --help`):**
```
tldr surface [OPTIONS] <TARGET>
```

| # | Command | Type |
|---|---------|------|
| P01 | `tldr surface json` | happy — stdlib module |
| P02 | `tldr surface backend/providers` | happy-scale — local directory |
| P03 | `tldr surface` | failure — missing target |
| P04 | `tldr surface no_such_package_zzz_brainfuck` | failure — unknown package |
| P05 | `tldr surface json -f sarif` | failure — format rejected |
| P06 | `tldr surface json -f text` | happy — text format |
| P07 | `tldr surface json -f compact` | happy — compact format |
| P08 | `tldr surface json -f dot` | failure — format rejected |
| P09 | `tldr surface json --lookup json.loads` | happy — lookup specific symbol |
| P10 | `tldr surface json --lookup json.no_such_function` | failure — symbol not found |
| P11 | `tldr surface json --include-private` | happy — include private symbols |
| P12 | `tldr surface json --limit 5` | happy — limit results |
| P13 | `tldr surface json --limit 0` | failure — limit zero |
| P14 | `tldr surface json --manifest-path /no/such/Cargo.toml` | failure — bad manifest path |
| P15 | `tldr surface json -l brainfuck` | failure — bad lang |
| P16 | `tldr surface json -l python` | happy — lang python |
| P17 | `tldr surface json -l typescript` | failure — lang mismatch |
| P18 | `tldr surface backend` | happy — local dir as target |
| P19 | `tldr surface /tmp/empty-dir` | failure — empty dir |
| P20 | `tldr surface json -q` | happy — quiet |

---

## `tldr todo`

**Canonical syntax (from `tldr todo --help`):**
```
tldr todo [OPTIONS] <PATH>
```

| # | Command | Type |
|---|---------|------|
| P01 | `tldr todo backend/providers --quick` | happy |
| P02 | `tldr todo backend --quick` | happy-scale |
| P03 | `tldr todo` | failure — missing path arg |
| P04 | `tldr todo /no/such/dir` | failure — bad path |
| P05 | `tldr todo backend/providers --quick -f sarif` | failure — format rejected |
| P06 | `tldr todo backend/providers --quick -f text` | happy — text format |
| P07 | `tldr todo backend/providers --quick -f compact` | happy — compact format |
| P08 | `tldr todo backend/providers --quick -f dot` | failure — format rejected |
| P09 | `tldr todo backend/providers --quick` | happy — quick mode (no deep analysis) |
| P10 | `tldr todo backend/providers --quick --detail dead` | happy — detail dead code |
| P11 | `tldr todo backend/providers --quick --detail complexity` | happy — detail complexity |
| P12 | `tldr todo backend/providers --quick --detail wat` | failure — bad detail value |
| P13 | `tldr todo backend/providers --quick --max-items 1` | happy — max-items 1 |
| P14 | `tldr todo backend/providers --quick --max-items 0` | failure — max-items zero |
| P15 | `tldr todo backend/providers --quick -O /tmp/todo-out.json` | happy — output file |
| P16 | `tldr todo backend/providers --quick -l brainfuck` | failure — bad lang |
| P17 | `tldr todo backend/providers --quick -l python` | happy — lang python |
| P18 | `tldr todo backend/providers --quick -l typescript` | failure — lang mismatch |
| P19 | `tldr todo /tmp/empty-dir --quick` | failure — empty dir |
| P20 | `tldr todo backend/providers/yahoo.py --quick` | happy — single file |
| P21 | `tldr todo README.md --quick` | failure — non-source file |
| P22 | `tldr todo backend/providers --quick -q` | happy — quiet |

---

## `tldr warm`

**Canonical syntax (from `tldr warm --help`):**
```
tldr warm [OPTIONS] [PATH]
```

| # | Command | Type |
|---|---------|------|
| P01 | `tldr warm` | happy — warm project root |
| P02 | `tldr warm backend` | happy-scale — warm subdirectory |
| P03 | (PATH defaults to `.` — no required arg) | N/A |
| P04 | `tldr warm /no/such/dir` | failure — bad path |
| P05 | `tldr warm -f sarif` | failure — format rejected |
| P06 | `tldr warm -f text` | happy — text format |
| P07 | `tldr warm -f compact` | happy — compact format |
| P08 | `tldr warm -f dot` | failure — format rejected |
| P09 | `tldr warm --background` | happy — background mode |
| P10 | `tldr warm -b` | happy — short -b flag |
| P11 | `tldr warm` (with daemon running) | happy — warms daemon cache |
| P12 | `tldr warm -l brainfuck` | failure — bad lang |
| P13 | `tldr warm -l python backend/providers` | happy — lang python scoped path |
| P14 | `tldr warm -l typescript backend/providers` | failure — lang mismatch |
| P15 | `tldr warm /tmp/empty-dir` | failure — empty dir |
| P16 | `tldr warm README.md` | failure — non-source file |
| P17 | `tldr warm backend/providers/yahoo.py` | happy — file as path |
| P18 | `tldr warm -q backend/providers` | happy — quiet |
