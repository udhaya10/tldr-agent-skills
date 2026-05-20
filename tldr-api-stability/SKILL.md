---
name: tldr-api-stability
description: API stability and architectural boundary analysis. Use this to verify backward compatibility, extract interfaces, or identify implemented design patterns.
allowed-tools: [bash]
---
# Skill: tldr-api-stability

This skill ensures that refactoring does not break external consumers and enforces clean architectural boundaries.

## When to Use This Skill
Use this skill when preparing a major version release, refactoring a public library, or converting a monolithic app into microservices.

## Supported Commands

### 1. `tldr api-check`
Check API backward compatibility between branches or states by diffing public AST nodes.
* **Usage:** `tldr api-check <dir> --against <BRANCH_OR_TAG>`
* **Crucial Rule:** Run this before committing to ensure you haven't accidentally removed or modified a public function signature, which would break downstream consumers.

### 2. `tldr interface`
Extract implicit interfaces by observing the actual methods invoked on an object across the Call Graph.
* **Usage:** `tldr interface <file>`
* **Crucial Rule:** When splitting a monolith, use this on a large class to see what interface it *actually* needs to implement to satisfy its current callers, rather than guessing.

### 3. `tldr patterns`
Detect Gang of Four (GoF) design patterns (Singleton, Factory, Observer, etc.) via structural AST matching.
* **Usage:** `tldr patterns <dir>`
* **Crucial Rule:** Helps rapidly document legacy code or identify where a pattern was implemented incorrectly (e.g., a Singleton that isn't actually thread-safe).
