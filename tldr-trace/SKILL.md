---
name: tldr-trace
description: Trace function calls, dependencies, and blast radius. Use this to find all references to a symbol, see what a function affects (callers), or identify dead code and architectural bottlenecks.
allowed-tools: [bash]
---
# Skill: tldr-trace

This skill provides forward and reverse call graph traversal, impact analysis, and dead code detection via the internal call-graph engine.

## When to Use This Skill
Use this skill when refactoring a function to understand its blast radius, searching for all usages of a specific variable/function, or hunting down dead/unreachable code.

## Supported Commands

### 1. `tldr impact`
View the reverse call graph (who calls this function).
* **Usage:** `tldr impact <func_name> <dir>`
* **Crucial Rule:** The function name is a POSITIONAL argument, not a flag. Use this to assess blast radius (upward tree).

### 2. `tldr references`
Find all usages of a specific symbol (variable, function, class) across the codebase.
* **Usage:** `tldr references --symbol <name> <dir>`

### 3. `tldr whatbreaks`
Cross-engine blast radius analyzer. Finds callers AND importers affected by a change.
* **Usage:** `tldr whatbreaks <file> <function> --type <callers|importers>`
* **Crucial Rule:** Always force the `--type` flag. Use this right before modifying a public API.

### 4. `tldr calls`
Dump the full cross-file forward call graph for an entire project/directory.
* **Usage:** `tldr calls <dir>`
* **Crucial Rule:** Do NOT use this to trace a specific function (use `impact`, `references`, or `context`). This is strictly for global architectural dumps.

### 5. `tldr hubs`
Find the most depended-upon "god functions" in the codebase.
* **Usage:** `tldr hubs <dir> --algorithm indegree`

### 6. `tldr dead`
Identify unreachable functions and classes.
* **Usage:** `tldr dead <dir> --call-graph`
* **Crucial Rule:** Always use the `--call-graph` flag to detect circular islands of dead code that technically reference each other but are disconnected from `main`.

## Methodology Rules
1. **For function-specific tracing:** Use `impact` (who calls it) or `references` (where is the symbol used). Do NOT use `calls`.
2. **For blast radius:** Use `whatbreaks` with explicit type flags to see the downstream consequences of a change.
