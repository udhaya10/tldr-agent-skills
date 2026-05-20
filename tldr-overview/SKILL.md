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
Extracts the skeleton (classes, functions, imports) of a directory without function bodies.
* **Usage:** `tldr structure <dir>`
* **Flags:** Use `--max-results <N>` if the output is too large.

### 2. `tldr tree`
Shows the directory structure alongside token counts.
* **Usage:** `tldr tree <dir>`

### 3. `tldr extract`
Extracts a specific function's body from a file.
* **Usage:** `tldr extract <file>`
* **Crucial Rule:** `extract` takes ONLY a file path. To find a specific function, run it on the file first to get the line numbers.

### 4. `tldr explain`
Generates a natural language summary of a function or file.
* **Usage:** `tldr explain <file> [function]`

### 5. `tldr imports`
Lists all import statements in a file.
* **Usage:** `tldr imports <file>`

### 6. `tldr importers`
Finds all files that import a specific module.
* **Usage:** `tldr importers <module>`
* **Flags:** Use `--limit <N>` to restrict output size.

### 7. `tldr deps`
Maps the dependency graph of modules.
* **Usage:** `tldr deps .`
* **Crucial Flag:** Use `--show-cycles` to instantly find circular import bugs.

### 8. `tldr definition`
Go-to-definition for a specific symbol.
* **Usage:** `tldr definition --symbol <name>`

## Methodology Rules
1. **Never use `cat` to discover codebase structure.** Always use `tldr structure` or `tldr tree` first.
2. **Never read whole files to find a function.** Use `tldr structure` to find the file/name, then `tldr extract <file>` to read the file and use the line numbers for downstream tracing tools.
3. If you encounter a circular import error during debugging, immediately run `tldr deps . --show-cycles`.
