---
name: tldr-runtime
description: Manage tldr's own infrastructure — the background daemon, on-disk Salsa cache, warmed analysis caches, token-savings telemetry, and environment diagnostics. Reach for this when tldr itself feels slow, when prepping a multi-query session, or when checking whether tldr is installed and routed correctly. NOT for analyzing the user's code — this skill manages tldr's runtime. Triggers on "start the daemon", "warm the cache", "is tldr cached", "tldr is slow", "check tldr environment", "tldr installation", "stats on tldr usage", "token savings", "tldr doctor".
allowed-tools: [Bash]
compatibility: "Requires tldr-code CLI v0.4.0+. Tested on darwin and linux."
metadata:
  version: "1.1.0"
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
| Build or refresh the vector index for semantic/similar search | EMBED | `tldr embed` |
| See how much disk the cache uses, or wipe it | INSPECT / CLEAR (on-disk) | `tldr cache` |
| See aggregate token savings across all sessions | TELEMETRY | `tldr stats` |
| Check whether language toolchains for `diagnostics` are installed | ENVIRONMENT | `tldr doctor` |

**The canonical opener: `tldr daemon start && tldr warm`.** That order matters. `tldr warm` warms **four** caches (call_graph, structure, file_tree, semantic_index) when it goes through the daemon's IPC route, but only **one** (call_graph) when run cold without a daemon. Skipping `daemon start` quietly leaves three cold caches you'll pay for on the first hit of each.

**When in doubt about a slow query, run `tldr daemon status -p "$(pwd)"`** — it shows running state plus live Salsa hits/misses/invalidations/recomputations. That's the diagnostic, not `cache stats` (which only reports on-disk file count without the daemon up). **Multi-daemon caveat:** bare `tldr daemon status` and `--project .` fail with "multiple daemons running" when >1 daemon exists in the registry — always pass an absolute path.

## Session startup — verified launch sequence

> **Known bugs — v0.4.0 (empirically verified):**
>
> **Bug 1 — Partial routing.** Only these commands route through the daemon (increment Salsa counters): `tree`, `structure`, `extract`, `calls`, `impact`, `dead`, `imports`, `importers`. These bypass the daemon entirely: `smells`, `complexity`, `context`, `slice`, `search`, `semantic`, and most audit/metric commands.
>
> **Bug 2 — Stats recording broken.** Even when commands DO route through the daemon (Salsa counters increment), `~/.tldr/stats.jsonl` is never written. `tldr stats` will always return "No usage recorded yet" in v0.4.0 regardless of daemon state or routing. These are two independent bugs.
>
> Track both at [parcadei/tldr-code](https://github.com/parcadei/tldr-code).

**Step 1 — Start the daemon (idempotent)**
```bash
tldr daemon start 2>/dev/null || true
```

**Step 2 — Warm all four caches via IPC**
```bash
tldr warm .
```

**Step 3 — Verify IPC is working (warm's misses are the signal)**
```bash
tldr daemon status -p "$(pwd)"
```
After warm, `misses` should be `> 0` (warm itself routes via IPC). **If `misses > 0`, the daemon socket is live and warm succeeded.** If `misses` is still `0`, the socket isn't ready — run the recovery below and repeat.

> **Multi-daemon caveat:** bare `tldr daemon status` and `--project .` fail with "multiple daemons running" when >1 daemon exists in the registry. Always use `-p "$(pwd)"` (absolute path). This only affects `status` — `start`, `stop`, `warm`, and `notify` all canonicalize `.` correctly.

> Note: do NOT use analysis commands (e.g. `tldr search`) as the IPC probe — in v0.4.0 they bypass the daemon and will never increment counters regardless of socket state.

**Recovery if Step 3 shows misses = 0:**
```bash
tldr daemon stop && tldr daemon start 2>/dev/null || true && tldr warm .
```
Then re-run Step 3 (`tldr daemon status -p "$(pwd)"`) before continuing.

## Tool reference

> **Command guardrail**: Only invoke the exact subcommands documented below. Do **not** invent or guess command names. If uncertain whether a command exists, run `tldr --help` before proceeding.

### `tldr daemon` — RUN the background Salsa-cache process

Lifecycle manager for the background Salsa-cache process that serves daemon-routed analysis commands; six subcommands (start, stop, status, list, query, notify) hidden behind one umbrella.

**Why reach for it**:
- Manually start the daemon before a batch of analyses to guarantee the 10-100× cache speedup on every subsequent call
- `status` exposes Salsa `hits / misses / invalidations / recomputations` for diagnosing why a query is slower than expected
- `list` and `stop --all` handle the multi-project registry — one daemon per project, all visible at once
- Most analysis commands auto-spawn the daemon via `try_daemon_route`, so explicit invocation is the exception, not the rule

**When to use**:
- Kicking off a batch of analyses and want predictable warm-cache performance (`tldr daemon start && tldr warm`)
- Debugging "why is my query slow" — `tldr daemon status -p "$(pwd)"` shows whether the daemon is even running and what its Salsa stats look like
- Cleaning up after a multi-project session (`tldr daemon stop --all`)

**Usage**:
```bash
tldr daemon <start|stop|status|list|query|notify> [args...]
tldr daemon start [--project <path>]
tldr daemon stop [--all]
tldr daemon status -p "$(pwd)"
tldr daemon notify <FILE>
```

**Output**: Each subcommand returns its own JSON shape — `start` emits `pid + socket + message`, `status` emits running-state plus uptime and Salsa counters, `list` emits an array of registered daemons, `notify` reports dirty-file accumulation against a 20-file reindex threshold.

**Killer detail**: Every subcommand has a different top-level schema — agents schema-validating output must branch on the subcommand name, not assume a single envelope.

**Safe start pattern for scripts and automation**:

`start` is NOT idempotent — it errors if a daemon is already running for the same project. Two safe approaches:

```bash
# Option 1 — conditional (explicit; use absolute path for multi-daemon safety)
tldr daemon status -p "$(pwd)" | grep -q '"not_running"' && tldr daemon start

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
- One-shot prep that makes graph-traversal commands (`calls`, `impact`, `dead`, `hubs`, `whatbreaks`) 10-100× faster — `search` and `semantic` are NOT powered by warm (see Two Worlds below)
- `--background` returns instantly while the cache builds in a subprocess — drop it into CI alongside other prep steps
- When the daemon is running, warm goes through IPC and populates four caches in one call, not just the call graph
- The canonical pairing for "I'm about to run many analyses": `tldr daemon start && tldr warm`

**Two worlds — what warm does and does NOT speed up:**

`tldr warm` builds the Salsa call graph cache. It powers graph-traversal commands only:

| World | Commands | Cache built by |
|-------|----------|---------------|
| **Graph traversal** | `calls`, `dead`, `hubs`, `impact`, `whatbreaks`, `slice`, `tree`, `structure` | `tldr warm` → Salsa |
| **Search (BM25)** | `search` | None — BM25 rescans ALL files at query time; latency scales with file count regardless of warm state |
| **Semantic/vector** | `semantic`, `similar` | `tldr embed` → vector index (flat ~4.3s model cold-start per call; independent of warm) |

**Warm health test** — use `tldr dead .` (not `tldr search`):

```bash
# Verify warm is active — purely graph-traversal, works on any project, no args needed
tldr dead .
# Warm: ~25ms on a 9-file project, ~1s on a 171-file project
# Cold or broken: 10× slower or hangs
```

`tldr search` bypasses Salsa entirely — using it as a warm test will always "pass" regardless of warm state.

**When to use**:
- Starting a multi-query analysis session of graph commands (`calls`, `impact`, `dead`, `hubs`) — warm makes them 10-100× faster
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

### `tldr embed` — BUILD the vector index for semantic/similar search

Pre-generates and caches code embeddings for a path, warming the vector index that `tldr semantic` and `tldr similar` query at runtime. **This is a mandatory prerequisite before the first `tldr semantic` or `tldr similar` call on any cold codebase.**

**Why reach for it**:
- Amortises the full embedding cost up front — the first `tldr semantic` or `tldr similar` query runs at cached (sub-second) speed instead of paying the inline cold-build penalty (minutes + gigabytes of RAM on large repos)
- Separates the slow build step from the fast search step — after one `tldr embed`, all subsequent semantic queries are instant
- `--include-vectors` exports raw float32 vectors for external tooling (custom search, clustering, visualisation)
- Granularity knob (`-g file|function`) controls chunk size; default is function-level

**When to use**:
- **Before the first `tldr semantic` or `tldr similar` call in any session where the cache is cold** — check with `ls ~/.tldr/embeddings/ 2>/dev/null || echo cold`
- After a large refactor or merge where the index may be stale
- When switching to a different model (`-m arctic-xs` vs `-m arctic-m`) and want to pre-build the new model's cache
- In CI to pre-warm the cache before a semantic search step

**When NOT to use**:
- The cache already exists and the codebase hasn't changed — `tldr semantic` will hit it directly
- Searching by exact keyword, token, or regex — that's `tldr search`, which needs no embeddings

**Usage**:
```bash
tldr embed .                              # function granularity, arctic-m model (defaults)
tldr embed <path> -g file -m arctic-xs   # file chunks, smaller/faster model
tldr embed <path> --include-vectors -o embeddings.json  # export raw vectors
```

**Output**: JSON with `chunks_embedded`, `chunks_cached`, `model`, `granularity`, and `latency_ms`. With `--include-vectors`, each chunk includes its float vector.

**Killer detail**: `--langs` accepts comma-separated file **extensions** (`py,rs,ts`) — NOT language names. Passing `--langs python` silently drops the filter entirely, causing embeddings to be generated for all files. Verify `chunks_embedded` in the output to confirm the filter worked.

**Verified first-run benchmarks** (Stock-Monitor, Apple Silicon ARM64, arctic-m):

| Scope | Files | LOC | Chunks | First-run time |
|---|---|---|---|---|
| `.` (full repo incl. dist) | ~16,606 | — | 17,188 | **36.46 min** |
| `backend/` | 56 | 45,406 | 1,397 | ~3 min (est.) |
| `webui/src/` | 305 | 130,953 | ~2,000 | ~4 min (est.) |

After the first run, all chunks are cached. Re-running on the same path completes in **~2.5 seconds** (cache hits only). Individual `tldr semantic` queries complete in **~260 ms**.

**Scope tip**: Running `tldr embed .` on a repo with a `webui/dist/` folder inflates chunk count from ~373 source files to 17,188 because minified JS bundles are parsed. Avoid by scoping or filtering:
```bash
tldr embed backend/ webui/src/          # explicit source dirs
tldr embed . --langs py,ts,tsx          # skip .js dist bundles
```

**Critical footguns**:
- **Never run `tldr semantic` without `tldr embed` on a cold large codebase.** `tldr semantic` embeds on demand if no cache exists, but this is slow (minutes), memory-heavy (gigabytes), and — if the agent retries the command — will spawn multiple parallel index-build processes that each do the full work independently.
- **Never spawn multiple `tldr embed` or `tldr semantic` processes for the same path concurrently.** Each builds the full index from scratch with no coordination. Kill all but one and wait.
- `tldr embed` is separate from `tldr warm`. `tldr warm` refreshes the Salsa structural cache (used by `tree`, `calls`, `impact`, etc.). `tldr embed` refreshes the vector embedding cache (used by `semantic`, `similar`). Both may need to be run; they are independent.

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

**Killer detail — known bug in v0.4.0**: `tldr stats` will always return empty regardless of daemon state. This is a separate bug from routing: even commands that DO route through the daemon (`tree`, `structure`, `extract`, `calls`, `impact`, `dead`, `imports`, `importers` — all confirmed to increment Salsa counters) never write to `~/.tldr/stats.jsonl`. Additionally, `smells`, `complexity`, `context`, `slice`, `search`, `semantic` and most audit/metric commands bypass the daemon entirely (Salsa counters do not increment). **Do not use `tldr stats` as a health signal in v0.4.0 — it will always be empty. Use `tldr daemon status` Salsa counters instead.** Track both bugs at [parcadei/tldr-code](https://github.com/parcadei/tldr-code).

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

- **Running `tldr semantic` without first running `tldr embed`.** On a cold large codebase, `tldr semantic` builds the entire vector index inline — minutes of CPU time and gigabytes of RAM. If the agent retries, multiple parallel index-build processes spawn, each doing the full work independently. The fix: run `tldr embed .` once, wait for completion, then call `tldr semantic`.
- **Spawning multiple `tldr embed` or `tldr semantic` processes for the same path.** They don't coordinate — each builds the full index from scratch. Kill all but one (`pkill -f "tldr embed"`) and wait.
- **Running `tldr warm` without first starting the daemon.** Cold warm only populates one cache (call_graph) out of four. The daemon-routed path is strictly better; always pair them: `tldr daemon start && tldr warm`.
- **Expecting `tldr warm` to speed up `search` or `semantic`.** Warm builds the Salsa call graph cache, which powers ONLY graph-traversal commands (`calls`, `dead`, `hubs`, `impact`, `whatbreaks`, `slice`). `search` runs BM25 over all files at query time — latency scales with file count (e.g. ~5s for 171 files), and warm has zero effect on it. `semantic` pays a flat ~4.3s model cold-start per call regardless of warm state — to speed up semantic, run `tldr embed` (vector index). If `search` is slow, the fix is to scope to a subdirectory, not to warm more aggressively. (Empirical data: search=141ms@9 files, 920ms@45 files, 4972ms@171 files — fully warmed daemon, all three.)
- **Reaching for `tldr cache clear` when you suspect stale cache.** Clear is unconditional, silent, and triggers a ~10× slowdown on every subsequent query while the on-disk store rebuilds. **The right move is `tldr daemon stop && tldr daemon start`** — the in-memory Salsa cache rebuilds without nuking the on-disk store, so the next query is fast instead of cold.
- **Trusting `tldr cache clear`'s success message.** It returns exit 0 with `"No cache directory found"` on a bad `--project` path — a wrong directory looks identical to a successful wipe. Verify the project path before clearing.
- **Calling `tldr warm` on a single file.** Warm needs a directory. A file path produces the misleading `"Read-only file system (os error 30)"` because the canonicalize fallback chains into a write attempt at `/`.
- **Calling `tldr daemon start` twice.** Start on an already-running daemon errors with the PID echoed for manual kill. Use `tldr daemon start 2>/dev/null || true` for idempotent starts in scripts — it silences the error and exits 0 regardless. `stop` is already idempotent; only `start` needs this guard.
- **Using bare `tldr daemon status` or `--project .` when multiple daemons are running.** With >1 daemon in the registry, both fail with "multiple daemons running (N); use --project <abs-path>." This only affects `status` — `start`, `stop`, `warm`, and `notify` all canonicalize `.` correctly. Always use `tldr daemon status -p "$(pwd)"`.
- **Expecting Salsa hit/miss counters from `tldr cache stats` when the daemon is down.** Salsa counters only appear when the daemon is running; otherwise `cache stats` returns only file count and disk bytes. For live Salsa counters, use `tldr daemon status -p "$(pwd)"`.
- **Assuming a single JSON envelope across `daemon` subcommands.** Every subcommand (start, stop, status, list, query, notify) returns a different top-level schema. Schema-validating consumers must branch on subcommand name.
- **Reading an empty `tldr stats` as a configuration problem in v0.4.0.** In v0.4.0, `tldr stats` always returns empty — analysis commands bypass `try_daemon_route` entirely and `stats.jsonl` is never written. This is an upstream bug, not a setup issue. Do not spend time troubleshooting empty stats in v0.4.0.
- **Using `tldr doctor` to fix a per-call `diagnostics` failure.** When `tldr diagnostics` exits 60, it already prints the exact install hint for the missing tool. Read that hint first. Reach for `doctor` only when you want the full multi-language status board, or when you want `--install` to run the hint for you (and only for the 7 supported languages).
- **Using this skill to analyze code.** This skill manages tldr's runtime. For code search, tracing, audit, etc., leave for the appropriate sibling skill.

## See also

- All sibling skills benefit from a warm daemon — **daemon-routed commands run ~35× faster after `tldr daemon start && tldr warm`**. Run this skill's canonical opener at the start of any multi-query session and the rest of the corpus gets faster for free.
