---
name: tldr-fix
description: Autonomous repair, diagnostics, and code patching. Use this to analyze uncommitted changes for bugs, loop edit-compile-test cycles to fix failing tests, or explain cryptic compiler errors.
allowed-tools: [bash]
---
# Skill: tldr-fix

This skill provides autonomous bug fixing, pre-commit diagnostics, and LLM-driven patch application by orchestrating native tools and AST analysis.

## When to Use This Skill
Use this skill to diagnose failing tests, find bugs in staged changes before committing, or autonomously fix code until a test suite passes.

## Supported Commands

### 1. `tldr bugbot check`
Analyze uncommitted or staged changes for bugs before committing.
* **Usage:** `tldr bugbot check . --staged`
* **Crucial Rule:** Use this as a pre-commit check to ensure your changes are safe. It isolates analysis only to the modified AST nodes.

### 2. `tldr diagnostics`
Run native typecheckers and linters (e.g., pyright, ruff, tsc) uniformly and parse their outputs into a standard format.
* **Usage:** `tldr diagnostics <dir> --severity error`
* **Crucial Rule:** Always use `--severity error` to filter out formatting noise and strictly focus on real bugs/type errors.

### 3. `tldr fix check`
Automatically repair failing tests by looping an edit-compile-test cycle.
* **Usage:** `tldr fix check . --test-cmd "<YOUR_TEST_COMMAND>"`
* **Crucial Rule:** You MUST provide the exact test command via the `--test-cmd` flag. The tool will autonomously edit the code, re-run the test, and verify if the fix worked.

### 4. `tldr fix diagnose`
Explain cryptic compiler or test errors via AST inspection.
* **Usage:** `<YOUR_COMMAND> 2>&1 | tldr fix diagnose --stdin`
* **Crucial Rule:** Pipe failing output directly into this command. It uses the LLM to inspect the error, look up the relevant AST nodes, and explain exactly why it failed.

### 5. `tldr fix apply`
Apply an LLM-generated patch to a file.
* **Usage:** `tldr fix apply <file_path> <patch_file>`

## Methodology Rules
1. **For pre-commit:** Always run `tldr bugbot check . --staged` before creating a git commit to prevent regressions.
2. **For autonomous fixing:** Ensure your `--test-cmd` in `fix check` is highly specific to the failing test to save time and prevent runaway loops.
