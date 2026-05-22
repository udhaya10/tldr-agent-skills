# tldr search

**Pitch**: BM25-ranked code search that returns function cards with signatures, callers, callees, and code previews in one shot.

**Why reach for it**
- One call replaces 3–10 file reads when locating code by name or token
- Deterministic ranking — same query, same answer, always
- Built-in callgraph context means you usually don't need a follow-up `extract` or `definition`
- Sub-second on most repos; no model inference cost

**When to use**
- About to read more than 2 files to locate a function, class, or symbol
- Looking for code by exact name, token, or regex pattern
- Investigating where a concept is implemented and want immediate surrounding context (signatures + callers/callees)
- Need to find candidates for refactor, dedupe, or audit

**When NOT to use**
- Searching by *meaning* rather than tokens — use `tldr semantic` instead
- You already know the exact file path — just read the file

**Output in plain words**: A ranked list of matched functions, each with its signature, file path, line number, who calls it, what it calls, and a code preview. Top-level `total_results` indicates how many matched; branch on this rather than exit code (empty results are exit 0).

**Killer detail**: On multi-language repos, auto-detection picks the dominant language by file count and silently scopes the search to it. Pass `-l <lang>` explicitly or scope the path to one language's subdirectory, or you'll get zero results without knowing why.

**Source**: `research/tldr/search/search.md`
