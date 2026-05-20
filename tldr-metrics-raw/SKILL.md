---
name: tldr-metrics-raw
description: Raw statistical reporting. Use this to generate JSON dumps of Lines of Code, Halstead mathematical complexity, or Code Coverage for CI/CD pipelines and dashboards.
allowed-tools: [bash]
---
# Skill: tldr-metrics-raw

This skill provides raw numerical outputs suitable for management dashboards, automated audits, or CI gating.

## When to Use This Skill
Use this skill ONLY when asked to generate statistical reports or check CI/CD thresholds. Do NOT use these metrics for direct, everyday refactoring decisions.

## Supported Commands

### 1. `tldr loc`
Calculate physical and logical Lines of Code (filtering out comments and blank lines).
* **Usage:** `tldr loc <dir>`
* **Advanced Flags:**
  * `--by-file`: Group by file instead of language.

### 2. `tldr halstead`
Calculate Halstead complexity metrics per function (Volume, Difficulty, Effort, Bugs).
* **Usage:** `tldr halstead <dir>`
* **Advanced Flags:**
  * `--threshold-difficulty <N>`: Flag functions above this difficulty (default: 20).
  * `--show-operators`: Print the exact operators found in the AST.
* **Crucial Rule:** These are highly abstract mathematical metrics. Do not attempt to fix code based on a "Difficulty score." Use `tldr-audit/smells` instead.

### 3. `tldr coverage`
Parse existing coverage report files (Cobertura XML, LCOV, coverage.py JSON).
* **Usage:** `tldr coverage <dir>`
* **Crucial Rule:** This tool does NOT run tests. It only parses existing coverage reports to generate a unified metric view.
