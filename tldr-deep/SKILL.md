---
name: tldr-deep
description: Deep static analysis and data flow tracing. Use this to track exact mathematical line influences, trace variable origins, or find assigned-but-unused variables.
allowed-tools: [bash]
---
# Skill: tldr-deep

This skill provides advanced control flow and data flow analysis capabilities via the internal PDG (Program Dependence Graph) engine.

## When to Use This Skill
Use this skill for deep debugging of state corruption, tracing where a variable got its incorrect value, or analyzing data flow intersections.

## Supported Commands

### 1. `tldr slice`
Trace exactly what lines of code mathematically affect a target line (backward slice).
* **Usage:** `tldr slice <file_path> <function> <line_number>`
* **Crucial Rule:** You MUST pass the exact file path, function name, and line number. Do not guess the line number. Use `tldr extract` first to find it.

### 2. `tldr chop`
Find the intersection of data flow between a source line and a target line.
* **Usage:** `tldr chop <file> <func> <source_line> <target_line>`
* **Note:** Use when tracking how a variable mutates between two specific points in a function.

### 3. `tldr reaching-defs`
Trace where a variable's value originated.
* **Usage:** `tldr reaching-defs <file> <func> <line>`
* **Note:** Use when a variable has the wrong value and you need to find the exact assignment.

### 4. `tldr available`
Find available expressions at a specific line.
* **Usage:** `tldr available <file> <func> <line>`

### 5. `tldr dead-stores`
Find variables that are assigned but never read.
* **Usage:** `tldr dead-stores <file>`
* **Note:** Use for cleanup and identifying silent logic errors where a computed value is thrown away.

## Methodology Rules
1. **Never guess line numbers.** Always use `tldr extract <file> <func>` first to get the accurate line numbers required by `slice`, `chop`, and `reaching-defs`.
2. **`cfg` and `dfg` do NOT exist.** Do not attempt to run `tldr cfg` or `tldr dfg`. The control flow and data flow graphs are accessed implicitly via the commands above.
