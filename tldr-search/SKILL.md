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
Natural language search using local embeddings.
* **Usage:** `tldr semantic "<natural language query>" <dir>`

### 2. `tldr search`
Enriched BM25 keyword search that returns function-level context cards (including call graph data).
* **Usage:** `tldr search "<keyword>" <dir>`
* **Flags:** Use `--regex` to treat the query as a regular expression. Use `--no-callgraph` if it is too slow.

### 3. `tldr similar`
Finds code structurally/semantically similar to a specific file or function.
* **Usage:** `tldr similar <file> --function <func_name>`

### 4. `tldr context`
Builds an LLM-optimized context payload by crawling the call graph from an entry point.
* **Usage:** `tldr context <file>:<function>`
* **Crucial Rule:** The input MUST be formatted as `file:function` or it will fail.

### 5. `tldr dice`
Compares the similarity between two specific code fragments.
* **Usage:** `tldr dice <file1:func1> <file2:func2>`

## Methodology Rules
1. **Prefer `tldr semantic`** for abstract concepts (e.g., "where are payments processed?").
2. **Prefer `tldr search`** for exact variable names, constants, or regex patterns.
3. **Always run `tldr context file:func`** before attempting complex refactors on an entry point to ensure you have the full mental model of the surrounding graph.
