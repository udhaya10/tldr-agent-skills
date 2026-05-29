# Research Journal 09: The Two Worlds of tldr-code — Graph Traversal vs. Search

> **Architectural correction to Journal 07 / tldr-runtime skill.** Empirical benchmarking on 2026-05-29 revealed that `tldr warm` and `tldr search`/`tldr semantic` operate in **completely independent performance worlds**. This was not documented in any prior dossier, and the `tldr-runtime` skill contained a misleading claim that warm speeds up `search` and `semantic`. This journal records the evidence and corrects the record.

---

## Context

During a multi-repo daemon and warm verification session (benchmarking across three real projects), it became clear that the command timing did NOT match what a unified "warm benefits all analysis" model would predict. The investigation revealed two fully independent caching architectures with no shared state.

**Projects benchmarked:**

| Project | Files | Language |
|---------|-------|----------|
| tldr-cli-demon | 9 | TypeScript |
| llm-tldr | 45 | Python |
| codegraph | 171 | Go |

All projects had daemon running and warm completed (IPC path, 4-cache warm).

---

## The Two Worlds

### World 1: Graph Traversal (Salsa cache — powered by `tldr warm`)

These commands consume the Salsa call graph cache that `tldr warm` builds. With a warm daemon, they run from in-memory graph state. Without warm, they pay full graph construction cost on every call.

**Commands in World 1:** `calls`, `dead`, `hubs`, `impact`, `whatbreaks`, `slice`, `tree`, `structure`, `extract`, `imports`, `importers`

### World 2: Search / Semantic (independent stores — NOT powered by `tldr warm`)

These commands use entirely separate indices built by different subsystems. `tldr warm` does NOT populate their caches.

- **`search`** — BM25 text search. Rescans ALL files at query time regardless of warm state. Latency scales linearly with file count. No amount of warm will help a slow `search` call.
- **`semantic`** / **`similar`** — Embedding vector search. Pre-built by `tldr embed`. Pays a flat ~4.3s model cold-start per call (embedding model loads from disk). This is independent of both Salsa cache state and daemon state.

---

## Empirical Proof

Benchmarks run immediately after daemon start + warm completion (IPC path confirmed via `misses > 0`):

### Search — scales with file count, NOT warm state

| Project | Files | `search` latency | Notes |
|---------|-------|-----------------|-------|
| tldr-cli-demon | 9 | 141ms | |
| llm-tldr | 45 | 920ms | |
| codegraph | 171 | 4972ms | 4.5s — file count problem, not warm problem |

Warm state: all three projects fully warmed. The scaling is linear with file count because BM25 rescans all files at query time regardless of cache.

### Semantic — flat ~4.3s model cold-start, independent of warm

| Project | Files | `semantic` latency | Notes |
|---------|-------|--------------------|-------|
| tldr-cli-demon | 9 | 4276ms | |
| llm-tldr | 45 | 4314ms | |
| codegraph | 171 | 4482ms | |

All three projects pay essentially the same ~4.3s because the embedding model loads cold on every call — the vector index exists (built by `tldr embed`) but the model load dominates. This is independent of warm or file count.

### Graph traversal — benefits from warm, scales moderately

| Project | Files | `dead` | `calls` | `hubs` |
|---------|-------|--------|---------|--------|
| tldr-cli-demon | 9 | **25ms** | 136ms | 151ms |
| llm-tldr | 45 | 1142ms | 1782ms | 2114ms |
| codegraph | 171 | 1081ms | 4439ms | 5597ms |

---

## The Canonical Warm Health Test

**`tldr dead .`** is the correct command to verify warm is active.

**Why `dead` wins over `calls` or `hubs`:**
- Purely graph-traversal — dead code = unreachable functions = needs the full call graph
- No function name argument needed — `tldr dead .` works identically on every project
- Single-pass reachability sweep is the cheapest graph operation — consistently fastest of all graph commands
- If it returns fast, the Salsa call graph cache is live

**Benchmark (warm daemon):**
- 9 files: ~25ms
- 45 files: ~1s
- 171 files: ~1s

**If `tldr dead .` hangs or takes 10× longer than these baselines, warm has not taken effect.**

The wrong commands to use as a warm health test:
- `tldr search "anything"` — uses BM25, bypasses Salsa entirely
- `tldr daemon status` — shows process state, not cache state
- `tldr cache stats` — shows on-disk file count, not in-memory graph state

---

## Corrected Mental Model

```
tldr warm  →  Salsa call graph cache
               └── powers: calls, dead, hubs, impact, whatbreaks, slice,
                            tree, structure, extract, imports, importers

tldr embed →  Vector embedding index
               └── powers: semantic, similar

(nothing)  →  BM25 full-file scan at query time
               └── powers: search
```

The `search` BM25 path has no cache. It is fast on small repos and slow on large repos regardless of daemon state.

---

## What This Corrects in the Corpus

### `tldr-runtime/SKILL.md` — `tldr warm` section

**Before (incorrect):**
> "One-shot prep that makes a batch of `search` / `semantic` / `impact` queries 10-100× faster"

**After (correct):**
> "One-shot prep that makes graph-traversal commands (`calls`, `impact`, `dead`, `hubs`, `whatbreaks`) 10-100× faster. `search` and `semantic` are NOT powered by warm — they use independent indices."

### `tldr-runtime/SKILL.md` — Common mistakes

Missing entry: "Expecting `tldr warm` to speed up `search` or `semantic`" — added.

---

## Implication for `tldr-locate-code` skill

`search` being slow on large repos (171 files → ~5s) is NOT fixable with warm. The only mitigations are:
1. Scope to a subdirectory (`tldr search "pattern" backend/`)
2. Accept the latency as a file-count property
3. Use `tldr semantic` if concept-based search is acceptable (different latency profile: flat ~4.3s)

---

## Source

- Session benchmarks: 2026-05-29, tldr-cli-demon / llm-tldr / codegraph
- Daemon state at benchmark time: running, IPC-warmed (misses > 0 confirmed for all three projects)
- tldr-code version: 0.4.0

---

## Cross-references

- **`research/tldr-daemon/`** — daemon architecture docs
- **`tldr-runtime/SKILL.md`** — primary skill corrected by this journal
- **Journal 07** — the skill architecture decision (did not capture the two-worlds distinction)
- **Journal 04** — probe protocol (this journal follows the same evidence-first approach)
