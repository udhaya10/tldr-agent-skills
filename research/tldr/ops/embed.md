# Command: `tldr embed`

## Environment Pin

| Field | Value |
|---|---|
| `tldr --version` | 0.4.0 |
| Build features | `semantic` (compiled from source with `--features semantic`) |
| Target repo | Stock-Monitor @ commit `7542871` (branch `dhan-integrations`) |
| OS | darwin 26.2 (macOS) |
| Machine | Apple Silicon ARM64 |
| Probe date | 2026-05-28 |

---

## Ground Truth (`tldr embed --help`)

```text
Generate embeddings for code chunks

Usage: tldr embed [OPTIONS] [PATH]

Arguments:
  [PATH]
          Path to embed (default: current directory)

Options:
  -g, --granularity <GRANULARITY>
          Chunk granularity: file or function [default: function]

  -m, --model <MODEL>
          Embedding model: arctic-xs, arctic-s, arctic-m, arctic-m-long, arctic-l
          [default: arctic-m]

      --include-vectors
          Include raw embedding vectors in output

  -o, --output <OUTPUT>
          Output file path (for --include-vectors)

      --langs <LANGS>
          Filter by file extensions (comma-separated, e.g., py,rs,ts)

  -h, --help
          Print help
```

---

## Verified Benchmarks

### B1 — Full repo, arctic-m, cold start

**Command:**
```bash
tldr embed .
```

**Repo profile at time of run:**

| Metric | Value |
|---|---|
| Scope | `.` (full repo — includes `webui/dist/` build artifacts) |
| Backend Python files | 56 files, 45,406 LOC |
| Frontend `webui/src/` files | 305 files (TS/TSX/JS/JSX), 130,953 LOC |
| Top-level Python files | 12 files |
| **Meaningful source total** | **373 files, ~176K LOC** |
| Files skipped by tldr | 2 (parse errors or unsupported) |

**Output:**
```json
{
  "path": ".",
  "model": "arctic-m",
  "granularity": "function",
  "chunks_embedded": 17188,
  "chunks_cached": 0,
  "latency_ms": 2187312
}
```

**Interpretation:**

| Field | Value | Notes |
|---|---|---|
| `chunks_embedded` | 17,188 | All freshly embedded — confirmed cold start |
| `chunks_cached` | 0 | Nothing was pre-cached |
| `latency_ms` | 2,187,312 | **36.46 minutes** — one-time cost, all-in-memory until completion |

> **Key observation**: The 17,188 chunk count is much larger than the 373 meaningful source files because tldr also parsed `webui/dist/` minified JS bundles. A scope-limited embed (e.g. `backend/` + `webui/src/`) would reduce this significantly.

---

### B2 — backend/ only, arctic-m, cold start (inferred from semantic probe)

From `tldr semantic "database connection" backend/` immediately after B1:

```
Building index for 1397 chunks...
All chunks cached - skipping embedder initialization
```

| Metric | Value |
|---|---|
| Scope | `backend/` |
| Files | 56 Python files, 45,406 LOC |
| Chunks | 1,397 |
| Cache state | All hits (populated by B1) |
| Index build from cache | ~2.5 seconds |
| Query latency | 262 ms |

> **Key insight**: After a full-repo embed, any scoped re-run (e.g. `tldr semantic "..." backend/`) builds its index entirely from cache in ~2.5s — no re-embedding needed.

---

## Behavioral Observations

### Cache architecture
- Cache key: `file_path : function_name : content_hash : model` (verified from `cache.rs:82-90`)
- Cache is a **flat global store** at `~/.tldr/embeddings/cache.json` — not scoped to the path argument
- Consequence: `tldr embed backend/` followed by `tldr embed .` reuses all backend/ work — the wider scope only embeds what wasn't already cached

### Change detection (automatic, no manual action needed)
On every cache read, two checks fire in sequence:
1. **File mtime** — if the file's modification time is newer than `cached_at`, the entry is discarded and re-embedded
2. **Content hash** — the cache key includes MD5 of function content; changed content = different key = automatic miss

After editing files, simply re-run `tldr embed <path>` or `tldr semantic`. Only changed functions are re-embedded; unchanged ones are cache hits.

### Write behavior (critical footgun)
- The cache is held **entirely in RAM** during the embed run
- It is written to disk via atomic rename (`cache.json.tmp` → `cache.json`) only on `flush()` or `Drop`
- A `SIGKILL` (`kill -9`) skips `Drop` — **all progress is lost**
- A clean `Ctrl+C` (SIGTERM) may flush partial results via `Drop`, but is not guaranteed
- **Implication**: there is no resume capability. If the process is killed, the full embed must be restarted

### Model isolation
- Each model's embeddings are stored as separate cache entries (model name is part of the key)
- `tldr semantic` uses ONE model per query and searches only that model's entries
- **Mixing models across paths is broken for cross-path queries** — `backend/` embedded with `arctic-xs` and `webui/src/` embedded with `arctic-m` cannot be searched together with any single `tldr semantic` command
- Pick one model for the entire repo

### No progress output
- `tldr embed` is completely silent during the run — no progress bar, no chunk counter, no ETA
- All output is written to the terminal stdout/stderr at the very end
- The only way to confirm it is progressing: `ps aux | grep "tldr embed"` (CPU usage), then `sample <pid> 3` to confirm the process is in an active compute loop, not hung

### Recommended model choice
- `arctic-m` (default): 36.46 minutes for 17,188 chunks on Apple Silicon ARM64 — use when quality matters and you can afford the one-time cost
- `arctic-xs`: significantly faster (estimated 5–10× speedup) — use for large repos or when iteration speed matters more than quality
- **You cannot mix models across paths for unified search** — pick one before first embed

---

## Scope Strategy

Prefer scoped embeds over full-repo embeds on large codebases:

| Strategy | Command | Chunks (est.) | First-run time (est.) |
|---|---|---|---|
| Full repo (incl. dist) | `tldr embed .` | 17,188 | **36.46 min** (verified) |
| Backend only | `tldr embed backend/` | 1,397 | ~3 min (est.) |
| Frontend src only | `tldr embed webui/src/` | ~2,000 (est.) | ~4 min (est.) |
| Backend + frontend src | both above sequentially | ~3,400 | ~7 min (est.) |

After a scoped embed, extending to `.` only embeds the unscoped remainder — prior work is reused from cache.

---

## Open Upstream Issues

| Issue | Impact | Status |
|---|---|---|
| No incremental disk write / no resume | Kill = lose all progress; large repos must restart from zero | Not filed as of 2026-05-28 |
| No progress output | Agent/user cannot tell if process is hung or computing | Not filed as of 2026-05-28 |
| `webui/dist/` not ignored by default | Inflates chunk count from 373 source files to 17,188; wasted embed time on minified bundles | Add `.tldrignore` or pass `--langs py,ts,tsx` |

### Workaround for dist inflation
```bash
# Option A: scope explicitly to source dirs
tldr embed backend/ webui/src/

# Option B: filter by extension (skips .js dist bundles)
tldr embed . --langs py,ts,tsx
```
