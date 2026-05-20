---
name: tldr-search
description: Semantic search, code similarity, and context generation. Use this to find where specific concepts are handled, discover similar code blocks, or build an LLM-ready call tree around a specific function.
allowed-tools: [bash]
---
# Skill: tldr-search

This skill provides semantic search, structural code similarity, and context generation.

## When to Use This Skill
Use this skill when you know *what* a piece of code does conceptually but don't know *where* it is, when looking for duplicated logic, or when you need to gather the entire call context around a specific entry point before modifying it.

## Supported Commands

### 1. `tldr semantic`
Natural language search using FastEmbed embeddings.
* **Usage:** `tldr semantic "<natural language query>" <dir>`
* **Crucial Rule:** Use when you don't know exact variable names. Ex: `tldr semantic "user billing logic" .`

### 2. `tldr search`
Enriched BM25 keyword/regex search.
* **Usage:** `tldr search "<keyword>" <dir>`
* **Crucial Rule:** Use `--regex` for pattern matching. Use `--no-callgraph` if the query times out due to traversing massive caller trees.

### 3. `tldr similar`
Finds functions mathematically similar to a source target via AST/Dice comparison.
* **Usage:** `tldr similar <file> --function <func_name>`

### 4. `tldr context`
Crawls the AST downward to build a complete LLM-optimized context tree around an entry point.
* **Usage:** `tldr context <file>:<function>`
* **Crucial Rule:** The input MUST be formatted precisely as `file:function` or it will fail.
* **Warning:** This only crawls *downward* (callees). To find callers, use `tldr-trace/impact`.

### 5. `tldr dice`
Compare the exact structural overlap (Dice coefficient) between two specific functions.
* **Usage:** `tldr dice <file1:func1> <file2:func2>`
* **Crucial Rule:** Useful to verify if two messy legacy functions are safe to merge.

## Methodology Rules
1. **Prefer `tldr semantic`** for abstract concepts (e.g., "where are payments processed?").
2. **Prefer `tldr search`** for exact variable names, constants, or regex patterns.
3. **Always run `tldr context file:func`** before attempting complex refactors on an entry point to ensure you have the full mental model of the surrounding downward graph.
