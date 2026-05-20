---
name: tldr-refactor-history
description: History-driven refactoring analysis. Use this to find files that change too often (churn), files where most bugs happen (hotspots), or hidden dependencies where files are frequently committed together (temporal coupling).
allowed-tools: [bash]
---
# Skill: tldr-refactor-history

This skill leverages Git history to find architectural flaws that static analysis misses.

## When to Use This Skill
Use this skill when prioritizing what to refactor, trying to find hidden dependencies across microservices, or identifying the most error-prone files in a codebase.

## Supported Commands

### 1. `tldr temporal`
Mine temporal constraints (files or methods that frequently change together in the same commit).
* **Usage:** `tldr temporal <dir>`
* **Advanced Flags:** 
  * `--min-support <N>`: Minimum number of times they must have changed together (default: 2).
  * `--min-confidence <FLOAT>`: Confidence threshold 0.0-1.0 (default: 0.5).
* **Refactoring Value:** If two files have high temporal coupling, they share a hidden dependency and should likely be refactored to share a common module.

### 2. `tldr hotspots`
Identify code hotspots based on frequency of commits and issue linkages.
* **Usage:** `tldr hotspots <dir>`
* **Advanced Flags:**
  * `--time-window <DAYS>`: Analyze the last N days (default: 30).
  * `--min-commits <N>`: Minimum commits to be considered a hotspot.
* **Refactoring Value:** Hotspots are the most dangerous files in the system. They are the highest priority for refactoring.

### 3. `tldr churn`
Analyze raw Git churn (frequency of file modifications).
* **Usage:** `tldr churn <dir>`
* **Advanced Flags:**
  * `--since <DATE>` / `--until <DATE>`: Date bounds.
* **Refactoring Value:** High churn files are usually "God objects" or poorly abstracted configurations that need to be split up.
