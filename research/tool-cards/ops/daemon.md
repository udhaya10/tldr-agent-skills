# tldr daemon

> **Before writing the Usage block**: check `verified-invocations.md` in this group's
> `tool-cards/ops/` directory and copy the canonical syntax verbatim.
> Do NOT reconstruct syntax from prose — that is how hallucinated flags get introduced.

**Pitch**: Lifecycle manager for the background Salsa-cache process that serves daemon-routed analysis commands; six subcommands (start, stop, status, list, query, notify) hidden behind one umbrella.

**Why reach for it**
- Manually start the daemon before a batch of analyses to guarantee the 10-100x cache speedup on every subsequent call
- `status` exposes Salsa `hits / misses / invalidations / recomputations` for diagnosing why a query is slower than expected
- `list` and `stop --all` handle the v0.3.0 multi-project registry — one daemon per project, all visible at once
- Most analysis commands auto-spawn the daemon via `try_daemon_route`, so explicit invocation is the exception, not the rule

**When to use**
- Kicking off a batch of analyses and want predictable warm-cache performance (`tldr daemon start && tldr warm`)
- Debugging "why is my query slow" — `tldr daemon status -p "$(pwd)"` shows whether the daemon is even running and what its Salsa stats look like (bare `status` and `--project .` fail when >1 daemon exists)
- Cleaning up after a multi-project session (`tldr daemon stop --all`)

**When NOT to use**
- Just running a single one-shot analysis — let the analysis command spawn the daemon itself
- Inspecting on-disk cache size (use `tldr cache stats`, not `daemon status`)

**Usage (copy from `verified-invocations.md` — do not reconstruct)**:
```
tldr daemon [OPTIONS] <COMMAND>
```
```
# P01 — check running state (use absolute path for multi-daemon safety)
tldr daemon status -p "$(pwd)"
# P02 — full lifecycle: start, confirm, stop
tldr daemon start && tldr daemon status && tldr daemon stop
# P11 — list all running daemons
tldr daemon list
```

**Output in plain words**: Each subcommand returns its own JSON shape — `start` emits `pid + socket + message`, `status` emits running-state plus uptime and Salsa counters, `list` emits an array of registered daemons, `notify` reports dirty-file accumulation against a 20-file reindex threshold.

**Killer detail**: Every subcommand has a different top-level schema — agents schema-validating output must branch on the subcommand name, not assume a single envelope.

**Other footguns**
- `stop` is idempotent (exit 0 even when no daemon was running), so scripts can call it without state checks; `start` on an already-running daemon errors with the PID echoed for manual kill.
- `notify <FILE>` enforces a "file must be inside project root" security check (exit 1 otherwise) — prevents the daemon API from being used to probe arbitrary paths.

**Source**: `research/tldr/ops/daemon.md`
