---
name: tldr-formal-methods
description: Formal verification and correctness proofs. Use this to extract mathematical contracts, verify loop invariants, or detect raw memory/resource leaks.
allowed-tools: [bash]
---
# Skill: tldr-formal-methods

This skill provides advanced verification tools for critical software where standard unit testing is insufficient.

## When to Use This Skill
Use this skill when auditing cryptographic functions, low-level system code, or mission-critical state machines to ensure absolute mathematical correctness.

## Supported Commands

### 1. `tldr contracts`
Extract preconditions, postconditions, and assertions from the AST.
* **Usage:** `tldr contracts <dir>`
* **Crucial Rule:** Use to explicitly identify undocumented assumptions in legacy code before rewriting it, ensuring the new code honors the same boundaries.

### 2. `tldr invariants`
Detect loop invariants and state machine guarantees via Data Flow Graph analysis.
* **Usage:** `tldr invariants <dir>`
* **Crucial Rule:** Essential when refactoring complex algorithms (like sorting or graph traversals) to mathematically prove the state remains consistent during iterations.

### 3. `tldr specs`
Generate formal specifications (TLA+, Alloy, or logical predicates) from code.
* **Usage:** `tldr specs <file>`
* **Crucial Rule:** Translates imperative code into logical proofs, helping identify edge cases where the core logic is incomplete.

### 4. `tldr resources`
Perform static analysis on resource acquisition and release (memory, file handles, sockets).
* **Usage:** `tldr resources <dir>`
* **Advanced Flags:**
  * `--strict`: Enforce RAII / context manager usage strictly.
* **Crucial Rule:** Prevents silent memory and socket leaks during major architectural rewrites by ensuring every allocation path has a guaranteed deallocation path.
