---
name: tldr-locate-code
description: Locate code in a project — find functions, classes, or symbols you DON'T already have the name or path for. Reach for this ANY TIME you'd otherwise grep or read multiple files to find code. Replaces 3–10 file reads with one indexed query. Triggers on "where is X handled", "find the function that does Y", "is there code like this snippet anywhere", "what implements concept Z", "find similar code to this", "search for", "discover code that does", "find usages of a pattern".
allowed-tools: [Bash]
compatibility: "Requires tldr-code CLI v0.4.0+. Tested on darwin and linux."
metadata:
  version: "1.0.0"
  author: "udhaya10"
  repository: "udhaya10/tldr-agent-skills"
  tldr.cli-version: "0.4.0"
  tldr.research-commit: "a025973"
  tldr.commands-wrapped: "search, semantic, similar, dice, context"
---

# tldr-locate-code

## When to use

Use this skill whenever you have an **intent** ("find where billing is handled," "where is `parseConfig` defined," "is there code similar to this snippet") and need to **discover** code WITHOUT already knowing the file path or having the function name in hand.

The discriminator vs sibling skills:

- For a function/class you ALREADY have a name for → see `tldr-understand-function`
- For tracking USAGES of a known symbol → see `tldr-trace-relationships`
- For a broader codebase tour (not a targeted search) → see `tldr-orient-codebase`

If you already know the file path and just need to read it, don't reach for this skill — read the file directly.

## The decision — which tool to use

The discriminator is **what you already have going in**, not what you want out.

| You already have... | And you want... | Reach for |
|---------------------|-----------------|-----------|
| A token, identifier, or regex | All occurrences with surrounding context (signatures, callers, callees) | `tldr search` |
| A concept in your own words, no shared vocabulary | Implementations of that concept | `tldr semantic` |
| One example function or file | Other functions/files that are like it | `tldr similar` |
| Two specific functions or files | A single number scoring how alike they are | `tldr dice` |
| A function name + its callees as one bundle | An LLM-ready markdown pack to hand to another model | `tldr context` |

**Default: `tldr search` first, always — if you have any token to anchor on.** It's the cheapest, fastest, most deterministic. Sub-second on most repos, no model inference, no embedding cache to warm. Escalate only when search returns empty AND you genuinely have no shared vocabulary with the codebase.

## Tool reference

> **Command guardrail**: Only invoke the exact subcommands documented below. Do **not** invent or guess command names. If uncertain whether a command exists, run `tldr --help` before proceeding.

### `tldr search` — BM25-ranked code search with function cards

BM25-ranked code search that returns function cards with signatures, callers, callees, and code previews in one shot.

**Why reach for it**:
- One call replaces 3–10 file reads when locating code by name or token
- Deterministic ranking — same query, same answer, always
- Built-in callgraph context means you usually don't need a follow-up inspection call
- Sub-second on most repos; no model inference cost

**When to use**:
- About to read more than 2 files to locate a function, class, or symbol
- Looking for code by exact name, token, or regex pattern
- Investigating where a concept is implemented and want immediate surrounding context

**Usage**:
```bash
tldr search "<query>" [path] [-l <lang>] [-k <max>] [--regex] [--no-callgraph] [--hybrid "<regex>"]
```

**Output**: A ranked list of matched functions, each with signature, file path, line number, callers, callees, and a code preview. Top-level `total_results` indicates how many matched.

**Killer detail**: On multi-language repos, auto-detection picks the dominant language by file count and silently scopes the search to it. Pass `-l <lang>` explicitly or scope the path to one language's subdirectory, or you'll get zero results without knowing why.

**Branch on `total_results`, not exit code** — empty results return exit 0.

---

### `tldr semantic` — natural-language code search

Natural-language code search backed by local Arctic embeddings — describe the concept, get the functions that implement it.

**Why reach for it**:
- Bridges the vocabulary gap that breaks BM25 search (`"payment retry logic"` finds `TransactionProcessor.with_backoff`)
- Runs fully local via FastEmbed; no API calls
- On-disk embedding cache makes the second-and-onwards query against a path sub-second

**When to use**:
- You know what the code *does* but not what it's *called*
- Onboarding to an unfamiliar codebase by concept ("rate limiting," "auth middleware")
- Locating an entry point before handing off to inspection tools

**Usage**:
```bash
tldr semantic "<natural language query>" [path] [--langs py,rs,ts] [-n <max>] [-t <threshold>]
```

**Output**: A ranked list of function-level result cards (file, class, function, score, line span, 5-line snippet) plus index metadata (`total_chunks`, `matches_above_threshold`, `cache_hit`, `latency_ms`).

**Killer detail**: `--langs` takes file **extensions** (`py`, `rs`, `ts`), NOT language names (`python`, `rust`) — unknown values are silently dropped, and a fully-dropped filter yields `total_chunks: 0` with zero results and no warning. **Always check `total_chunks` before trusting an empty `results` array.**

---

### `tldr similar` — find code that does what this code does

Embedding-based "find code that does what this code does" search across a project, ranked per destination file by default.

**Why reach for it**:
- Surfaces semantic neighbors that share intent but not identifiers — the gap `tldr dice` and `tldr search` both miss
- Default aggregation collapses chunk noise into one row per destination file
- `--function` mode pivots from "files like this file" to "implementations like this function"

**When to use**:
- Looking for refactor candidates, hidden duplication, or sibling implementations of an interface
- Hunting clone families that share a bug after fixing one site
- Discovering an existing helper before writing a new one

**Usage**:
```bash
tldr similar <file> [-F <function>] [-n <top>] [-t <threshold>] [-p <ABSOLUTE_PATH>]
```

**Output**: By default, a ranked list of destination files with `total_score`, `avg_score`, and `matched_chunks`. With `--function` or `--by-chunk`, a per-chunk report whose `source` block embeds the query function content.

**Killer detail**: Relative `-p <PATH>` is broken — the index stores paths that fail to match the canonicalized source. **Pass `-p` as an absolute path, or omit it entirely** (the smart-path fallback uses the file's parent dir).

**Other footguns**:
- `--include-self` is dead code; self is always excluded from results regardless of the flag
- `--by-chunk` on a whole-file query silently picks just the FIRST chunk of the source file; pair with `--function <name>` for predictable per-chunk behavior

---

### `tldr dice` — pairwise similarity score

One-shot syntactic similarity score between two code fragments, returning a Dice coefficient and a clone-type bucket.

**Why reach for it**:
- Confirms a clone suspicion in a single call — no project-wide index required
- Normalization modes let the caller decide whether to ignore identifiers, literals, or both
- Sub-second on typical file pairs; no model inference, no daemon, no embeddings

**When to use**:
- Already have two candidate fragments and need to score how alike they are
- Deciding whether two functions are worth deduping or refactoring together
- Sanity-checking that a port or rewrite preserved structure

**Usage**:
```bash
tldr dice <file1:start:end> <file2:start:end> [--normalize <mode>]
```

**Output**: A small JSON blob with both target specs, the Dice coefficient (0.0–1.0), a human-readable interpretation bucket, and post-normalization token counts for each side.

**Killer detail**: The documented `file::function` target form is dead — it silently compares the whole files. **Use `file:start:end` line ranges** (sourced from `tldr extract`) whenever function-level comparison is the actual intent.

---

### `tldr context` — pack a function + callees into LLM-ready markdown

Packs an entry function plus its transitive callees into one LLM-ready markdown bundle, sized to drop into a prompt.

**Why reach for it**:
- Replaces "read the function, then chase every helper it calls" with a single command
- `-f text` emits markdown via `to_llm_string()` — paste-ready, no post-processing
- Daemon-cached path is ~35× faster than rebuild on repeat queries
- Depth knob (`-d`) trades context completeness against token budget

**When to use**:
- About to hand a function and its dependencies to another model or skill
- Investigating an unfamiliar entry point and want signature + callees in one shot
- Building a focused review pack for a single function instead of slurping whole files

**Usage**:
```bash
tldr context <entry-function> [path] [-l <lang>] [-d <depth>] [--include-docstrings] [-f text|compact]
```

**Output**: A `RelevantContext` payload listing the entry plus every reachable function within depth, each with signature, file (relative to PATH), line, callees, and complexity. Text format renders the same data as markdown with code-block-wrapped signatures.

**Killer detail**: Using `--file` or the `<file>:<func>` shorthand silently disables the daemon route — the protocol can't carry those filters, so disambiguation costs the speedup.

**Other footguns**:
- `--file` is interpreted relative to PATH, not cwd. When `PATH=backend`, pass `--file providers/yahoo.py`, NOT `--file backend/providers/yahoo.py`
- With default `PATH=.` and no `-l`, duplicate function names across the project resolve via silent first-match-wins; scope PATH and pass `-l` when the name might be ambiguous

## Common mistakes

- **Reaching for `tldr semantic` first because it sounds smarter.** Semantic is slower, less deterministic, and worse than search whenever any shared vocabulary exists. Use semantic only when query terms genuinely don't appear in the codebase ("billing logic" might map to `ChargeProcessor.run`).
- **Reaching for the wrong skill entirely.** If you ALREADY have a function name (not just an intent), `tldr-understand-function` is usually the right skill — running search/semantic to find code you already know about wastes the call. If you have a known symbol and want every USE site, `tldr-trace-relationships` is the right skill (search returns ranked function cards, not a flat use-site list).
- **Using `tldr similar` with relative `-p`.** Always pass absolute paths or omit `-p` entirely. The smart-path fallback only kicks in for the literal default `.`; any other relative path returns "no indexed chunks found."
- **Using `tldr dice` with `file::function` target form.** Dead form — silently compares whole files. Use `file:start:end` ranges from `tldr extract`.
- **Skipping `-l <lang>` on multi-language repos.** All five tools auto-detect language by dominant file count; the wrong guess is silent. A search for `"database"` on a JS-dominant root returns zero Python matches without warning.
- **Using `tldr semantic`'s `--langs` with language names.** Takes extensions (`py`, `rs`), not names (`python`, `rust`). Unknown values silently dropped — check `total_chunks` before trusting an empty result.
- **Using `tldr context` during discovery.** Context is for handoff once you have a function name. If you reach for it while still searching, you're in the wrong tool — use `tldr search` or `tldr semantic` to find the entry point first.

## See also

- `tldr-understand-function` — once you have a function name and want signature, purity, complexity, callers, callees, or extracted file inventory
- `tldr-trace-relationships` — when you have a known symbol and want every use site (callers, references, blast radius)
- `tldr-orient-codebase` — when you need a broader codebase tour, not a targeted code search
