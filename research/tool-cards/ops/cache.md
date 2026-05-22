# tldr cache

**Pitch**: Inspect or wipe the on-disk Salsa cache; a human-operator command suppressed from agent skills because clearing it triggers a ~10x slowdown on every subsequent query.

**Why reach for it**
- (Humans only) See how many MB of cache files a project has accumulated
- (Humans only) Force a full rebuild after suspecting cache corruption
- Agents get zero value: `stats` is informational, `clear` is destructive and unrecoverable

**When to use**
- Operator wants to reclaim disk space across stale project caches
- Operator is debugging a tldr release upgrade and suspects cached state from a prior version
- Never inside an agent tool loop

**When NOT to use**
- Agent suspects stale cache — restart the daemon instead (`tldr daemon stop && tldr daemon start`) so the Salsa in-memory cache rebuilds without nuking the on-disk store
- Wanting in-memory Salsa hit/miss counters — those only appear when the daemon is running; otherwise `stats` returns just the disk-file count

**Output in plain words**: `stats` reports file count, total bytes, and a human-readable size (plus Salsa hit/miss/invalidation counters only when the daemon is up). `clear` reports files removed and bytes freed, then exits.

**Killer detail**: `tldr cache clear` is silent and unconditional — there's no `--force` or confirmation prompt, and a bad `--project` path still returns exit 0 with "No cache directory found," so a wrong directory looks identical to a successful no-op wipe.

**Source**: `research/tldr/ops/cache.md`
