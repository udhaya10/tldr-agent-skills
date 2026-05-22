# tldr semantic

**Pitch**: Natural-language code search backed by local Arctic embeddings — describe the concept, get the functions that implement it.

**Why reach for it**
- Bridges the vocabulary gap that breaks BM25 search (`"payment retry logic"` finds `TransactionProcessor.with_backoff`)
- Runs fully local via FastEmbed; no API calls, no per-query inference cost after warmup
- On-disk embedding cache makes the second-and-onwards query against a path sub-second
- Returns function spans with line ranges and a 5-line snippet — enough to triage without opening files

**When to use**
- The agent knows what the code *does* but not what it's *called*
- Onboarding to an unfamiliar codebase by concept ("rate limiting," "auth middleware")
- Locating an entry point before handing off to `extract`, `context`, or `impact`

**When NOT to use**
- Searching by exact symbol, token, or regex — `tldr search` is faster and deterministic
- Comparing two known fragments — use `tldr dice` (syntactic) or `tldr similar` (semantic, file-anchored)
- First-time indexing on a huge repo when latency matters — the initial build is seconds-to-minutes

**Output in plain words**: A ranked list of function-level result cards (file, class, function, score, line span, 5-line snippet) plus index metadata: `total_chunks`, `matches_above_threshold`, `cache_hit`, `latency_ms`.

**Killer detail**: `--langs` takes file extensions (`py`, `rs`, `ts`), not language names (`python`, `rust`) — unknown values are silently dropped, and a fully-dropped filter yields `total_chunks: 0` with zero results and no warning. Always check `total_chunks` before trusting an empty `results` array.

**Source**: `research/tldr/search/semantic.md`
