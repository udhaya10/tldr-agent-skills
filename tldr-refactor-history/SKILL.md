---
name: tldr-refactor-history
description: History-driven refactoring analysis. Use this to find files that change too often (churn), files where most bugs happen (hotspots), or hidden dependencies where files are frequently committed together (temporal coupling).
allowed-tools: [bash]
---
# Skill: tldr-refactor-history

This skill leverages Git history rather than static AST to find architectural flaws that traditional code analysis misses.

## When to Use This Skill
Use this skill when prioritizing what to refactor, trying to find hidden dependencies across microservices, or identifying the most error-prone files in a codebase.

## Supported Commands

### 1. `tldr temporal`
Mine temporal constraints (files or methods that frequently change together in the same commit).
* **Usage:** `tldr temporal <dir>`
* **Advanced Flags:** 
  * `--min-support <N>`: Minimum number of times they must have changed together (default: 2).
  * `--min-confidence <FLOAT>`: Confidence threshold 0.0-1.0 (default: 0.5).
* **Crucial Rule:** If two files have high temporal coupling but no direct code imports, they share a hidden architectural dependency (e.g., matching database schemas). They should likely be refactored into a shared module.

### 2. `tldr hotspots`
Identify code hotspots by correlating the frequency of Git commits with issue/bug tracker linkages.
* **Usage:** `tldr hotspots <dir>`
* **Advanced Flags:**
  * `--time-window <DAYS>`: Analyze the last N days (default: 30).
  * `--min-commits <N>`: Minimum commits to be considered a hotspot.
* **Crucial Rule:** Hotspots represent the highest ROI for refactoring. A file with terrible code quality but zero churn is low priority. A file with bad quality AND high hotspot status is critical.

### 3. `tldr churn`
Analyze raw Git churn (frequency of file modifications).
* **Usage:** `tldr churn <dir>`
* **Crucial Rule:** High churn files are usually "God objects" or poorly abstracted configurations that violate the Open/Closed Principle and need to be split up.
