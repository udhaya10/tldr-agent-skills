# tldr daemon

> **Before writing the Usage block**: check `verified-invocations.md` in this group's
> `tool-cards/ops/` directory and copy the canonical syntax verbatim.
> Do NOT reconstruct syntax from prose — that is how hallucinated flags get introduced.

**Pitch**: Lifecycle manager for the background Salsa-cache process that serves daemon-routed analysis commands; six subcommands (start, stop, status, list, query, notify) hidden behind one umbrella.

**Why reach for it**
- `status` exposes Salsa `hits / misses / invalidations / recomputations` for diagnosing why a query is slower than expected
- `list` and `stop --all` handle the v0.3.0 multi-project registry — one daemon per project, all visible at once
- The supervisor daemon (`tldr-cli-demon`) manages start/warm/embed automatically — agents should only use `daemon status` and `daemon list` for diagnostics

**When to use**
- Debugging "why is my query slow" — `tldr daemon status -p "$(pwd)"` shows whether the daemon is even running and what its Salsa stats look like (bare `status` and `--project .` fail when >1 daemon exists)
- Checking which projects have active daemons (`tldr daemon list`)

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
