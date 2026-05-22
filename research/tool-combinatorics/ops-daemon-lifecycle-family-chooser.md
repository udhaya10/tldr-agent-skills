# Lens: Ops daemon lifecycle — family chooser

**The question this lens answers**: "I want to manage tldr's background performance — which of `daemon`, `warm`, `cache` is the right lifecycle operation?"

**Toolset**: `tldr daemon`, `tldr warm`, `tldr cache`

**Why a family-chooser lens, why these tools**: These three look like overlapping "cache management" commands, but they are three *different* lifecycle operations on the same underlying machinery. The clean discriminator: `daemon` RUNS the background process, `warm` FILLS its caches with computed analysis results, and `cache` INSPECTS or CLEARS the on-disk Salsa files the daemon serves. They are not alternatives — they are stages.

## Decision tree by lifecycle stage

| You want to... | Stage | Reach for |
|----------------|-------|-----------|
| Start, stop, or check the background process | RUN | `tldr daemon` |
| Pre-populate analysis caches before a query batch | FILL | `tldr warm` |
| See how much disk the cache uses, or wipe it | STATS / CLEAR (on-disk) | `tldr cache` |

## The default

**Default depends on intent — these are not interchangeable.** The canonical opening sequence for a multi-query session is:

```
tldr daemon start && tldr warm
```

That order matters: `tldr warm` warms **four** caches (call_graph, structure, file_tree, semantic_index) when it goes through the daemon's IPC route, but only **one** (call_graph) when run cold without a daemon. Skipping `daemon start` quietly leaves you with three cold caches you'll pay for on the first hit.

- **Starting fresh / batch coming up** → `tldr daemon start` then `tldr warm`
- **Preparing for repeated queries from CI or a long agent loop** → `tldr daemon start && tldr warm --background` while linters and tests start in parallel
- **Diagnosing "why is my query slow?"** → `tldr daemon status` (shows Salsa hits / misses / invalidations / recomputations)
- **Reclaiming disk space across stale projects** → `tldr cache stats` then, only if needed, `tldr cache clear`
- **Single one-shot analysis** → reach for nothing in this family; let the analysis command auto-spawn the daemon via `try_daemon_route`

## Common mistakes

- **Running `tldr warm` without first starting the daemon.** Cold warm only populates one cache out of four. The daemon-routed path is strictly better; pair them.
- **Reaching for `tldr cache clear` when you suspect stale cache.** Clear is unconditional, silent, and triggers a ~10x slowdown on every subsequent query while the on-disk store rebuilds. The right move is `tldr daemon stop && tldr daemon start` — the in-memory Salsa cache rebuilds without nuking the on-disk store.
- **Trusting `tldr cache clear`'s success message.** It returns exit 0 with "No cache directory found" on a bad `--project` path — a wrong directory looks identical to a successful wipe. Verify the path before clearing.
- **Calling `tldr warm` on a single file.** Warm needs a directory. A file path produces the misleading `"Read-only file system (os error 30)"` because the canonicalize fallback chains into a write attempt at `/`.
- **Calling `tldr daemon start` twice.** Start on an already-running daemon errors with the PID echoed for manual kill. `stop` is idempotent (exit 0 even when nothing is running) — use it freely in scripts.
- **Expecting Salsa hit/miss counters from `tldr cache stats`.** Salsa counters only appear when the daemon is running; otherwise `cache stats` returns only file count and disk bytes. For Salsa counters, use `tldr daemon status`.
- **Assuming a single JSON envelope across `daemon` subcommands.** Every subcommand (start, stop, status, list, query, notify) returns a different top-level schema. Schema-validating consumers must branch on subcommand name.

## What this lens captures

The lifecycle framing — RUN / FILL / INSPECT — keeps these three from collapsing into a fuzzy "cache stuff" cluster. Each operation has a place in a session; none replaces another.

## What this lens misses

- **Per-command cache behavior.** The deep-group `slice` has its own daemon-cached path; the other deep commands do not. This lens doesn't cover which analysis commands actually benefit from a warm cache.
- **Multi-project registries.** `tldr daemon list` and `tldr daemon stop --all` handle the v0.3.0 multi-project case, but the orchestration of multi-repo sessions is out of scope for this chooser.
- **Cache invalidation triggers.** `tldr daemon notify <FILE>` accumulates dirty-file events against a 20-file reindex threshold; the file-watching strategy belongs in a separate ops doc.

## Pair with

- *(future)* `ops-performance-orchestration.md` — when to warm, when to let auto-spawn handle it, when to start daemons per-project
- `change-impact-family-chooser.md` *(future)* — `tldr stats` and `tldr deps` for the other ops sub-family (project introspection, not lifecycle)

## Sources

- `research/tool-cards/ops/daemon.md`
- `research/tool-cards/ops/warm.md`
- `research/tool-cards/ops/cache.md`
