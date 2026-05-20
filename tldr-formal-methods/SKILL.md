---
name: tldr-formal-methods
description: Formal verification and correctness proofs. Use this to extract mathematical contracts, verify loop invariants, or detect raw memory/resource leaks.
allowed-tools: [bash]
---
# Skill: tldr-formal-methods

This skill provides advanced verification tools for critical software where standard testing is insufficient.

## When to Use This Skill
Use this skill when auditing cryptographic functions, low-level system code, or mission-critical state machines to ensure absolute correctness.

## Supported Commands

### 1. `tldr contracts`
Extract preconditions, postconditions, and assertions.
* **Usage:** `tldr contracts <dir>`
* **Refactoring Value:** Use to identify undocumented assumptions in legacy code before rewriting it.

### 2. `tldr invariants`
Detect loop invariants and state machine guarantees.
* **Usage:** `tldr invariants <dir>`
* **Refactoring Value:** Essential when refactoring complex algorithms (like sorting or graph traversals) to ensure the mathematical bounds hold.

### 3. `tldr specs`
Generate formal specifications from code.
* **Usage:** `tldr specs <file>`
* **Refactoring Value:** Translates code into logical proofs, helping identify edge cases where the logic is incomplete.

### 4. `tldr resources`
Analyze resource acquisition and release (memory, file handles, sockets).
* **Usage:** `tldr resources <dir>`
* **Advanced Flags:**
  * `--strict`: Enforce RAII / context manager usage strictly.
* **Refactoring Value:** Prevents memory and socket leaks during major architectural rewrites.
