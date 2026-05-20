---
name: tldr-audit
description: Codebase health, security, and complexity analysis. Use this to find code smells, security vulnerabilities, duplicated logic, and high technical debt.
allowed-tools: [bash]
---
# Skill: tldr-audit

This skill provides comprehensive codebase health metrics, structural duplication detection, and security taint analysis.

## When to Use This Skill
Use this skill when auditing a new project, looking for refactoring targets (technical debt), or scanning for security vulnerabilities.

## Supported Commands

### 1. `tldr health`
Get a high-level codebase health dashboard (hotspots, complexity, smells).
* **Usage:** `tldr health <dir>`
* **Note:** Run this first during an audit to find which files need deeper inspection.

### 2. `tldr smells`
Detect architectural code smells like god classes, long parameter lists, and nested logic.
* **Usage:** `tldr smells <dir> --deep`
* **Crucial Rule:** ALWAYS use the `--deep` flag to enable critical architectural detectors.

### 3. `tldr vuln`
Run security taint analysis to find SQLi, XSS, and command injection.
* **Usage:** `tldr vuln <dir>`
* **Note:** Only supports Python and Rust natively. Excludes tests by default.

### 4. `tldr secure`
Get an aggregated security dashboard.
* **Usage:** `tldr secure <dir> --quick`
* **Note:** Aggregates vulnerabilities, resource leaks, and bounds checks. Use `--quick` on large repos.

### 5. `tldr clones`
Detect duplicated logic (AST structural clones).
* **Usage:** `tldr clones <dir>`
* **Note:** Finds copy-pasted code even if variable names were changed.

### 6. `tldr debt`
Calculate technical debt in minutes/hours.
* **Usage:** `tldr debt <dir>`

### 7. Complexity Metrics
Analyze function and class complexity.
* **Usage:** `tldr complexity <dir>` (Cyclomatic: branch-heavy functions)
* **Usage:** `tldr cognitive <dir>` (Cognitive: hard-to-read functions)
* **Usage:** `tldr cohesion <dir>` (Cohesion: classes that should be split)

## Methodology Rules
1. Start with `health` for a broad overview.
2. Use `smells --deep` to find refactor targets.
3. Use `vuln` for specific taint traces rather than the aggregated `secure` view.
