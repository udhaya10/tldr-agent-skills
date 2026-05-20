---
name: tldr-api-stability
description: API stability and architectural boundary analysis. Use this to verify backward compatibility, extract interfaces, or identify implemented design patterns.
allowed-tools: [bash]
---
# Skill: tldr-api-stability

This skill ensures that refactoring does not break external consumers and enforces clean boundaries.

## When to Use This Skill
Use this skill when preparing a major version release, refactoring a public library, or converting a monolithic app into microservices.

## Supported Commands

### 1. `tldr api-check`
Check API backward compatibility between branches or states.
* **Usage:** `tldr api-check <dir> --against <BRANCH_OR_TAG>`
* **Refactoring Value:** Run this before committing to ensure you haven't accidentally removed or modified a public function signature.

### 2. `tldr interface`
Extract implicit interfaces from usage patterns.
* **Usage:** `tldr interface <file>`
* **Refactoring Value:** When splitting a monolith, use this on a large class to see what interface it actually needs to implement to satisfy its callers.

### 3. `tldr patterns`
Detect GoF design patterns (Singleton, Factory, Observer, etc.).
* **Usage:** `tldr patterns <dir>`
* **Refactoring Value:** Helps document legacy code or identify where a pattern was implemented incorrectly.
