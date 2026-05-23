---
name: tldr-runtime
description: Manage tldr's own infrastructure — the background daemon, on-disk Salsa cache, warmed analysis caches, token-savings telemetry, and environment diagnostics. Reach for this when tldr itself feels slow, when prepping a multi-query session, or when checking whether tldr is installed and routed correctly. NOT for analyzing the user's code — this skill manages tldr's runtime. Triggers on "start the daemon", "warm the cache", "is tldr cached", "tldr is slow", "check tldr environment", "tldr installation", "stats on tldr usage", "token savings", "tldr doctor".
allowed-tools: [Bash]
compatibility: "Requires tldr-code CLI v0.4.0+. Tested on darwin and linux."
metadata:
  version: "1.0.0"
  author: "udhaya10"
  repository: "udhaya10/tldr-agent-skills"
  tldr.cli-version: "0.4.0"
  tldr.research-commit: "a025973"
  tldr.commands-wrapped: "cache, daemon, warm, stats, doctor"
---

# tldr-runtime

## When to use

Use this skill whenever the **subject is tldr itself**, not the code under analysis. The intent space: starting and stopping the background daemon, populating analysis caches before a query batch, inspecting the on-disk cache, surfacing aggregate token-savings telemetry, and verifying the local toolchain environment that backs `tldr diagnostics`.

This is the **infrastructure skill**. Everything else in the corpus assumes the daemon is up and caches are warm; this skill is what makes that assumption true. **Daemon-routed commands run ~35× faster after `tldr daemon start && tldr warm`** — running a multi-query session without this prep leaves money on the table.

If you're trying to analyze, search, trace, or audit code → leave for the appropriate sibling skill. If you're trying to manage tldr itself → you're in the right place.

## The decision — which tool to use

The discriminator is **which lifecycle stage you're at**, not which output you want. The three core tools (`daemon`, `warm`, `cache`) are NOT alternatives — they are stages of the same machinery.

| You want to... | Stage | Reach for |
|----------------|-------|-----------|
| Start, stop, or check the background process | RUN | `tldr daemon` |
| Pre-populate analysis caches before a query batch | FILL | `tldr warm` |
| See how much disk the cache uses, or wipe it | INSPECT / CLEAR (on-disk) | `tldr cache` |
| See aggregate token savings across all sessions | TELEMETRY | `tldr stats` |
| Check whether language toolchains for `diagnostics` are installed | ENVIRONMENT | `tldr doctor` |

**The canonical opener: `tldr daemon start && tldr warm`.** That order matters. `tldr warm` warms **four** caches (call_graph, structure, file_tree, semantic_index) when it goes through the daemon's IPC route, but only **one** (call_graph) when run cold without a daemon. Skipping `daemon start` quietly leaves three cold caches you'll pay for on the first hit of each.

**When in doubt about a slow query, run `tldr daemon status`** — it shows running state plus live Salsa hits/misses/invalidations/recomputations. That's the diagnostic, not `cache stats` (which only reports on-disk file count without the daemon up).

## Tool reference

### `tldr daemon` — RUN the background Salsa-cache process

Lifecycle manager for the background Salsa-cache process that serves daemon-routed analysis commands; six subcommands (start, stop, status, list, query, notify) hidden behind one umbrella.

**Why reach for it**:
- Manually start the daemon before a batch of analyses to guarantee the 10-100× cache speedup on every subsequent call
- `status` exposes Salsa `hits / misses / invalidations / recomputations` for diagnosing why a query is slower than expected
- `list` and `stop --all` handle the multi-project registry — one daemon per project, all visible at once
- Most analysis commands auto-spawn the daemon via `try_daemon_route`, so explicit invocation is the exception, not the rule

**When to use**:
- Kicking off a batch of analyses and want predictable warm-cache performance (`tldr daemon start && tldr warm`)
- Debugging "why is my query slow" — `tldr daemon status` shows whether the daemon is even running and what its Salsa stats look like
- Cleaning up after a multi-project session (`tldr daemon stop --all`)

**Usage**:
```bash
tldr daemon <start|stop|status|list|query|notify> [args...]
tldr daemon start [--project <path>]
tldr daemon stop [--all]
tldr daemon status
tldr daemon notify <FILE>
```

**Output**: Each subcommand returns its own JSON shape — `start` emits `pid + socket + message`, `status` emits running-state plus uptime and Salsa counters, `list` emits an array of registered daemons, `notify` reports dirty-file accumulation against a 20-file reindex threshold.

**Killer detail**: Every subcommand has a different top-level schema — agents schema-validating output must branch on the subcommand name, not assume a single envelope.

**Safe start pattern for scripts and automation**:

`start` is NOT idempotent — it errors if a daemon is already running for the same project. Two safe approaches:

```bash
# Option 1 — conditional (explicit)
tldr daemon status | grep -q '"not_running"' && tldr daemon start

# Option 2 — unconditional (simpler, preferred)
tldr daemon start 2>/dev/null || true
```

Option 2 is preferred: fewer moving parts, resilient to output format changes.

**One daemon per project**: The daemon is bound to a project directory via a path hash in the socket name. Starting from a different directory starts a separate daemon for that project — they don't conflict. The error only fires when you try to start a second daemon for the **same** project.

**Other footguns**:
- `stop` is idempotent (exit 0 even when no daemon was running), so scripts can call it without state checks; `start` on an already-running daemon errors with the PID echoed for manual kill
- `notify <FILE>` enforces a "file must be inside project root" security check (exit 1 otherwise) — prevents the daemon API from being used to probe arbitrary paths

---

### `tldr warm` — FILL the analysis caches before a query batch

Pre-builds the call graph cache so subsequent analysis commands hit warm caches instead of paying cold-build cost on the first query.

**Why reach for it**:
- One-shot prep that makes a batch of `search` / `semantic` / `impact` queries 10-100× faster
- `--background` returns instantly while the cache builds in a subprocess — drop it into CI alongside other prep steps
- When the daemon is running, warm goes through IPC and populates four caches in one call, not just the call graph
- The canonical pairing for "I'm about to run many analyses": `tldr daemon start && tldr warm`

**When to use**:
- Starting a multi-query analysis session and want predictable performance
- CI prep: `tldr warm --background` runs while linters and tests start in parallel
- After a large refactor when you want the call graph rebuilt fresh before exploring

**Usage**:
```bash
tldr warm [path] [--background]
```

**Output**: Three different JSON shapes depending on mode. Cold (no daemon): files, edges, languages, and the relative cache path. `--background`: just a status and "warming in background" message, with the work spawned to a child. Daemon-running: an IPC status message naming the four caches that were warmed.

**Killer detail**: The daemon-route warms FOUR caches (call_graph, structure, file_tree, semantic_index), but the in-process cold route only warms the call graph — so `tldr daemon start && tldr warm` gives strictly more cache coverage than `tldr warm` alone.

**Other footguns**:
- A bad PATH produces the misleading error `"Read-only file system (os error 30)"` because the canonicalize fallback chains into a write attempt at `/` — verify the path exists externally before invoking
- Pointing at a single file produces the same misleading error — warm needs a **directory**
- There's no `--force` and no way to skip rebuild when the cache is already warm

---

### `tldr cache` — INSPECT or CLEAR the on-disk Salsa store

Inspect or wipe the on-disk Salsa cache. **Mostly a human-operator command** — `stats` is informational, `clear` is destructive and triggers a ~10× slowdown on every subsequent query while the on-disk store rebuilds from scratch.

**Why reach for it**:
- See how many MB of cache files a project has accumulated (`cache stats`)
- Force a full rebuild after suspecting cache corruption from a tldr release upgrade (`cache clear`, rarely)
- Reclaim disk space across stale project caches

**When to use**:
- Operator wants to reclaim disk space across stale project caches
- Operator is debugging a tldr release upgrade and suspects cached state from a prior version
- **Never as a remedy for "my query feels stale"** — see Common mistakes

**Usage**:
```bash
tldr cache <stats|clear> [--project <path>]
```

**Output**: `stats` reports file count, total bytes, and a human-readable size (plus Salsa hit/miss/invalidation counters only when the daemon is up). `clear` reports files removed and bytes freed, then exits.

**Killer detail**: `tldr cache clear` is silent and unconditional — there's no `--force` or confirmation prompt, and a bad `--project` path still returns exit 0 with `"No cache directory found,"` so a wrong directory looks identical to a successful no-op wipe. **Verify the project path before clearing.**

---

### `tldr stats` — TELEMETRY for aggregate token savings

Global usage summary that aggregates token savings across every daemon-tracked tldr invocation, regardless of which project they ran in.

**Why reach for it**:
- Self-monitoring: see how many tokens the tldr layer has saved over an entire session history
- CWD-independent — runs from any directory because it reads `~/.tldr/stats.jsonl`, not project state
- Empty case is genuinely actionable: returns `next_steps` commands plus a `requires` array naming the prerequisites
- Zero positional args, minimal cognitive load

**When to use**:
- Building a tldr-savings dashboard or reflection summary
- Confirming the daemon is actually being routed through (an empty `stats` after running many commands means the daemon never came up)
- Personal accounting of token-cost reduction

**Usage**:
```bash
tldr stats
```

**Output**: When populated, JSON with `total_invocations`, `estimated_tokens_saved`, `raw_tokens_total`, `tldr_tokens_total`, and `savings_percent`. When empty, JSON with `message`, a `next_steps` array of exact commands to populate stats, and a `requires` array.

**Killer detail**: Stats only populates when the daemon has been running during commands — without `tldr daemon start` first, the JSONL file at `~/.tldr/stats.jsonl` never gets written and `tldr stats` will return its empty-with-next-steps payload forever. **An empty `stats` after a heavy session is the signal your daemon never came up.**

---

### `tldr doctor` — ENVIRONMENT check for `diagnostics` toolchains

Environment check for whether the type-checkers and linters that back `tldr diagnostics` are installed on the local system. A human-operator setup command, not a routine agent call.

**Why reach for it**:
- One-shot inventory of which language toolchains are missing
- `--install <LANG>` runs the registered install command (`pip install pyright ruff`, etc.) — a destructive convenience for dev-machine setup
- The fastest answer to "why does `tldr diagnostics` keep saying my language isn't supported"

**When to use**:
- Operator setting up a fresh dev machine and wants a status board of language tooling
- Operator wants `tldr diagnostics` working for a specific language and prefers auto-install over reading docs
- Triaging a `tldr diagnostics` exit 60 ("missing toolchain") to see the full picture, not just the one missing tool

**Usage**:
```bash
tldr doctor [--install <LANG>]
```

**Output**: JSON object keyed by language name (~15 languages), each with `type_checker` and `linter` sub-objects reporting `installed`, the absolute path when present, and an `install` hint string when missing.

**Killer detail**: Only 7 of the ~15 detected languages have working `--install` support (go, kotlin, lua, python, ruby, rust, swift) — JavaScript, TypeScript, C, C++, C#, Java, PHP, and Scala all return exit 1 `"No auto-install available"` because their install commands aren't registered. For those eight, read the `install` hint string and run it yourself.

## Common mistakes

- **Running `tldr warm` without first starting the daemon.** Cold warm only populates one cache (call_graph) out of four. The daemon-routed path is strictly better; always pair them: `tldr daemon start && tldr warm`.
- **Reaching for `tldr cache clear` when you suspect stale cache.** Clear is unconditional, silent, and triggers a ~10× slowdown on every subsequent query while the on-disk store rebuilds. **The right move is `tldr daemon stop && tldr daemon start`** — the in-memory Salsa cache rebuilds without nuking the on-disk store, so the next query is fast instead of cold.
- **Trusting `tldr cache clear`'s success message.** It returns exit 0 with `"No cache directory found"` on a bad `--project` path — a wrong directory looks identical to a successful wipe. Verify the project path before clearing.
- **Calling `tldr warm` on a single file.** Warm needs a directory. A file path produces the misleading `"Read-only file system (os error 30)"` because the canonicalize fallback chains into a write attempt at `/`.
- **Calling `tldr daemon start` twice.** Start on an already-running daemon errors with the PID echoed for manual kill. Use `tldr daemon start 2>/dev/null || true` for idempotent starts in scripts — it silences the error and exits 0 regardless. `stop` is already idempotent; only `start` needs this guard.
- **Expecting Salsa hit/miss counters from `tldr cache stats` when the daemon is down.** Salsa counters only appear when the daemon is running; otherwise `cache stats` returns only file count and disk bytes. For live Salsa counters, use `tldr daemon status`.
- **Assuming a single JSON envelope across `daemon` subcommands.** Every subcommand (start, stop, status, list, query, notify) returns a different top-level schema. Schema-validating consumers must branch on subcommand name.
- **Reading an empty `tldr stats` as "I haven't used tldr much."** Stats only populates when the daemon was running during invocations. An empty payload after a heavy session means the daemon never came up — go fix that (`tldr daemon start`), not your usage habits.
- **Using `tldr doctor` to fix a per-call `diagnostics` failure.** When `tldr diagnostics` exits 60, it already prints the exact install hint for the missing tool. Read that hint first. Reach for `doctor` only when you want the full multi-language status board, or when you want `--install` to run the hint for you (and only for the 7 supported languages).
- **Using this skill to analyze code.** This skill manages tldr's runtime. For code search, tracing, audit, etc., leave for the appropriate sibling skill.

## See also

- All sibling skills benefit from a warm daemon — **daemon-routed commands run ~35× faster after `tldr daemon start && tldr warm`**. Run this skill's canonical opener at the start of any multi-query session and the rest of the corpus gets faster for free.
