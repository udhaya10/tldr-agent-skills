# tldr warm

> **Before writing the Usage block**: check `verified-invocations.md` in this group's
> `tool-cards/ops/` directory and copy the canonical syntax verbatim.
> Do NOT reconstruct syntax from prose — that is how hallucinated flags get introduced.

**Pitch**: Pre-builds the call graph cache so subsequent analysis commands hit warm caches instead of paying cold-build cost on the first query.

**Why reach for it**
- One-shot prep that makes a batch of `search` / `semantic` / `impact` queries 10-100x faster
- `--background` returns instantly while the cache builds in a subprocess — drop it into CI alongside other prep steps
- When the daemon is running, warm goes through IPC and populates four caches in one call, not just the call graph
- The canonical pairing for "I'm about to run many analyses": `tldr daemon start && tldr warm`

**When to use**
- Starting a multi-query analysis session and want predictable performance
- CI prep: `tldr warm --background` runs while linters and tests start in parallel
- After a large refactor when you want the call graph rebuilt fresh before exploring

**When NOT to use**
- Running a single one-shot query — the underlying command will build only what it needs
- Wanting to see cache size after warming — use `tldr cache stats`
- Pointing at a single file — warm needs a directory (it produces a raw OS error for files)

**Usage (copy from `verified-invocations.md` — do not reconstruct)**:
```
tldr warm [OPTIONS] [PATH]
```
```
# P01 — warm project root
tldr warm
# P02 — warm a specific subdirectory
tldr warm backend
# P09 — return immediately, cache builds in background
tldr warm --background
```

**Output in plain words**: Three different JSON shapes depending on mode. Cold (no daemon): files, edges, languages, and the relative cache path. `--background`: just a status and "warming in background" message, with the work spawned to a child. Daemon-running: an IPC status message naming the four caches that were warmed.

**Killer detail**: The daemon-route warms FOUR caches (call_graph, structure, file_tree, semantic_index), but the in-process cold route only warms the call graph — so `tldr daemon start && tldr warm` gives strictly more cache coverage than `tldr warm` alone.

**Other footguns**
- A bad PATH produces the bizarre error "Read-only file system (os error 30)" because the canonicalize fallback chains into a write attempt at `/` — verify the path exists externally before invoking, the error message is genuinely misleading.
- There's no `--force` and no way to skip rebuild when the cache is already warm; pair with `tldr daemon stop` and `rm -rf .tldr/cache` if you genuinely need a clean slate.

**Source**: `research/tldr/ops/warm.md`
