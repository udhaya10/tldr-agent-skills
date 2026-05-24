# `tldr embed`

> **Before writing the Usage block**: check `verified-invocations.md` in this group's
> `tool-cards/ops/` directory and copy the canonical syntax verbatim.
> Do NOT reconstruct syntax from prose — that is how hallucinated flags get introduced.

**Pitch**: Pre-generates and caches code embeddings for a file or directory, warming the vector index that `tldr semantic` and `tldr similar` query at runtime.

**Why reach for it**
- Amortizes embedding cost up front — first `tldr semantic` or `tldr similar` query runs at cached speed instead of paying the cold-start embedding penalty
- `--include-vectors` exports raw float32 vectors for external tooling (custom search, clustering, visualization)
- Granularity knob (`-g file|function`) controls whether embeddings track whole-file intent or individual function signatures
- Quiet separation from the query path — warming the cache doesn't affect what `semantic`/`similar` return, only how fast

**When to use**
- About to run many `tldr semantic` or `tldr similar` queries in a session and the embedding cache is cold
- Exporting vectors for external use (pass `--include-vectors -o embeddings.json`)
- Testing whether a specific model produces better results for your repo (swap `-m arctic-xs/arctic-m/arctic-l`)
- Running in CI to pre-warm the cache before a semantic search step

**When NOT to use**
- About to run a single semantic or similar query — those commands embed on demand automatically; the overhead is only noticeable at scale
- Want to find code by keyword, token, or regex — that's `tldr search`, which needs no embeddings

**Usage (copy from `verified-invocations.md` — do not reconstruct)**:
```bash
tldr embed <path>                        # function granularity, arctic-m model (defaults)
tldr embed <path> -g file -m arctic-xs   # file chunks, smaller model
tldr embed <path> --include-vectors -o embeddings.json  # export raw vectors
```

**Output in plain words**: A JSON report with chunk count, model used, granularity, and cache status. With `--include-vectors`, each chunk includes its float vector.

**Killer detail**: `--langs` accepts comma-separated file **extensions** (`py,rs,ts`) — NOT language names. Passing `--langs python` silently drops the filter entirely because `python` doesn't match any known extension, leaving embeddings generated for all files.

**Source**: `research/tool-cards/ops/verified-invocations.md` (embed section)
