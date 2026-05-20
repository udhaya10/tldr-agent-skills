---
name: tldr-audit
description: Codebase health, security, and complexity analysis. Use this to find code smells, security vulnerabilities, duplicated logic, and high technical debt.
allowed-tools: [bash]
---
# Skill: tldr-audit

This skill provides comprehensive codebase health metrics, structural duplication detection, and security taint analysis using AST traversal and security engines.

## When to Use This Skill
Use this skill when auditing a new project, looking for refactoring targets (technical debt), or scanning for security vulnerabilities.

## Supported Commands

### 1. `tldr health`
Get a high-level codebase health dashboard (hotspots, complexity, smells).
* **Usage:** `tldr health <dir>`
* **Crucial Rule:** Run this first during an audit to find which files need deeper inspection.

### 2. `tldr smells`
Detect architectural code smells (god classes, long parameter lists, deep nested logic).
* **Usage:** `tldr smells <dir> --deep`
* **Crucial Rule:** ALWAYS use the `--deep` flag to enable critical architectural detectors rather than just surface linting.

### 3. `tldr vuln`
Run security taint analysis to find SQLi, XSS, and command injection paths.
* **Usage:** `tldr vuln <dir>`
* **Crucial Rule:** Only supports Python and Rust natively. It traces untrusted inputs to sensitive sinks.

### 4. `tldr secure`
Get an aggregated security dashboard.
* **Usage:** `tldr secure <dir> --quick`
* **Crucial Rule:** Aggregates vulnerabilities, resource leaks, and bounds checks. Use `--quick` on large repos to skip expensive deeper flow checks.

### 5. `tldr clones`
Detect duplicated logic (AST structural clones).
* **Usage:** `tldr clones <dir>`
* **Crucial Rule:** This finds copy-pasted code even if variable names were changed, as it compares the underlying AST structure, not raw text.

### 6. `tldr debt`
Calculate technical debt in minutes/hours based on known issue remediation times.
* **Usage:** `tldr debt <dir>`

### 7. Complexity Metrics
Analyze function and class complexity mathematically.
* **Usage:** `tldr complexity <dir>` (Cyclomatic: identifies branch-heavy functions that need more tests)
* **Usage:** `tldr cognitive <dir>` (Cognitive: identifies functions that are too hard for humans to read)
* **Usage:** `tldr cohesion <dir>` (Cohesion/LCOM4: identifies classes lacking single-responsibility that should be split)

## Methodology Rules
1. Start with `health` for a broad overview.
2. Use `smells --deep` to find concrete refactor targets.
3. Use `vuln` for specific taint traces rather than the aggregated `secure` view.
