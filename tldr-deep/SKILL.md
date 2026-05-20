---
name: tldr-deep
description: Deep static analysis and data flow tracing. Use this to track exact mathematical line influences, trace variable origins, or find assigned-but-unused variables.
allowed-tools: [bash]
---
# Skill: tldr-deep

This skill provides advanced control flow and data flow analysis capabilities via the internal PDG (Program Dependence Graph) and DFG (Data Flow Graph) engines.

## When to Use This Skill
Use this skill for hard debugging of state corruption, tracing where a variable got its incorrect value, or analyzing mathematical data flow intersections without guessing.

## Supported Commands

### 1. `tldr slice`
Trace exactly what lines of code mathematically affect a target line (backward slice) or what a line affects (forward slice).
* **Usage:** `tldr slice <file_path> <function> <line_number>`
* **Advanced Flags:** `-d forward` to trace downstream impact instead of upstream causes.
* **Crucial Rule:** You MUST pass the exact file path, function name, and line number. Do not guess the line number. Use `tldr extract` first to find it.

### 2. `tldr chop`
Find the intersection of data flow between a source line and a target line.
* **Usage:** `tldr chop <file> <func> <source_line> <target_line>`
* **Crucial Rule:** Use when tracking how a specific variable mutates between two specific points in a function, filtering out all unrelated logic.

### 3. `tldr reaching-defs`
Trace where a variable's value mathematically originated via DFG traversal.
* **Usage:** `tldr reaching-defs <file> <func> <line>`
* **Crucial Rule:** Use when a variable has the wrong value at runtime and you need to find the exact assignment that reached this line.

### 4. `tldr available`
Find available expressions at a specific line (useful for compiler-level logic checks).
* **Usage:** `tldr available <file> <func> <line>`

### 5. `tldr dead-stores`
Perform liveness analysis to find variables that are assigned but never subsequently read on any execution path.
* **Usage:** `tldr dead-stores <file>`
* **Crucial Rule:** Use for cleanup and identifying silent logic errors where a computed value is accidentally thrown away.

## Methodology Rules
1. **Never guess line numbers.** Always use `tldr extract <file>` first to get the accurate line numbers required by `slice`, `chop`, and `reaching-defs`.
2. **`cfg` and `dfg` do NOT exist.** Do not attempt to run `tldr cfg` or `tldr dfg`. The control flow and data flow graphs are accessed implicitly via the commands above.
