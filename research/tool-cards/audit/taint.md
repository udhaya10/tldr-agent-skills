# tldr taint

**Pitch**: Per-function CFG/DFG taint-flow tracer that flags dangerous sinks (`sql_query`, `shell_exec`, `file_open`, `code_exec`) and tells the caller, per sink, whether external taint actually reaches them.

**Why reach for it**
- Returns explicit `sources[]`, `sinks[]`, and `tainted_vars` keyed by CFG block — the only `tldr` command that exposes block-level taint state
- The `tainted` flag on each sink separates "dangerous API was called" from "dangerous API was called with attacker-controlled data"
- Targeted scope (one file, one function) makes it cheap to loop over a shortlist
- Built on the same engine `tldr vuln` uses, but exposes the raw flow data instead of a categorized report

**When to use**
- Already have a suspect function and need to know whether unsafe data actually reaches a sink inside it
- `tldr vuln` or `tldr secure` flagged a file and the next move is a per-function deep dive
- Want to see the CFG-block-level taint state for explaining a finding to a reviewer

**When NOT to use**
- Scanning a project — `taint` is strictly one-FILE-one-FUNCTION; use `tldr vuln` or `tldr secure` for breadth
- Looking for dangerous APIs regardless of flow — `tldr secure --quick` is the right tool

**Output in plain words**: JSON with `function, tainted_vars (block-id → vars), sources[], sinks[] (each with a `tainted: bool`), flows[], sanitized_vars[]`. The actionable signal is `sinks[*].tainted == true`; treat false-tainted sinks as "API used, no traced flow".

**Killer detail**: Function PARAMETERS are NOT treated as taint sources — `vulnerable_sql(user_id)` with `cursor.execute("..." + user_id)` returns `sources: []` and `tainted: false`. The engine only fires on EXPLICIT sources (file reads, network input); for parameter-as-source coverage, reach for `tldr vuln` or external SAST.

**Other footguns**
- `-f compact` is broken — returns pretty JSON byte-identical to default (workaround: pipe through `jq -c`).
- Passing a directory as FILE leaks a raw OS error (`"Is a directory (os error 21)"`) at exit 1; passing `README.md` silently falls back to the Python parser and exits 20 with `"Function not found"`.

**Source**: `research/tldr/audit/taint.md`
