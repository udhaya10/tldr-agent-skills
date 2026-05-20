---
name: tldr-overview
description: Token-efficient codebase discovery and architectural mapping. Use this to understand project structure, find API layers, extract function signatures, and map dependencies without reading raw files.
allowed-tools: [bash]
---
# Skill: tldr-overview

This skill provides token-efficient codebase discovery and architectural mapping. It replaces brute-force `cat` and `grep` with targeted AST extraction.

## When to Use This Skill
Use this skill when exploring a new repository, trying to understand how modules connect, or looking for the exact definition/signature of a specific class or function.

## Supported Commands

### 1. `tldr structure`
Extract the AST skeleton (classes, methods, signatures) of a file or directory without function bodies. Highly token-efficient.
* **Usage:** `tldr structure <dir>`
* **Crucial Rule:** Always use `--max-results <N>` (e.g., 50) if running on a large directory to avoid context blowout.

### 2. `tldr tree`
Display a `.gitignore`-respecting directory tree annotated with token counts.
* **Usage:** `tldr tree <dir>`
* **Crucial Rule:** Use this instead of `ls` to instantly see where the bulk of the codebase's logic (tokens) resides.

### 3. `tldr extract`
Extract the exact AST nodes and line numbers of a file.
* **Usage:** `tldr extract <file>`
* **Crucial Rule:** `extract` takes ONLY a file path. To find a specific function, run it on the file first to get the line numbers for downstream tracing tools (like `slice`).

### 4. `tldr explain`
Generate an AI/heuristic natural language summary of a complex function or file.
* **Usage:** `tldr explain <file> [function]`

### 5. `tldr imports`
List outbound dependencies (what this file imports).
* **Usage:** `tldr imports <file>`

### 6. `tldr importers`
List inbound dependencies (who imports this file).
* **Usage:** `tldr importers <module>`
* **Crucial Rule:** Use `--limit <N>` to restrict output size on highly-imported utility modules.

### 7. `tldr deps`
Extract the high-level module dependency graph.
* **Usage:** `tldr deps .`
* **Crucial Rule:** Use `--show-cycles` specifically to debug circular import crashes.

### 8. `tldr definition`
Find the absolute file and line number where a symbol is defined.
* **Usage:** `tldr definition --symbol <name>`
* **Crucial Rule:** Use this instead of `grep` to accurately locate struct/class/function definitions.

## Methodology Rules
1. **Never use `cat` to discover codebase structure.** Always use `tldr structure` or `tldr tree` first.
2. **Never read whole files to find a function.** Use `tldr structure` to find the file/name, then `tldr extract <file>` to read the file and use the line numbers for downstream tracing tools.
3. If you encounter a circular import error during debugging, immediately run `tldr deps . --show-cycles`.
