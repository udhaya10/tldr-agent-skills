---
name: tldr-ops
description: Daemon management, AST-aware diffs, and change impact. Use this to start the background cache, view logical (not line) diffs, or determine which tests to run based on uncommitted changes.
allowed-tools: [bash]
---
# Skill: tldr-ops

This skill manages the background daemon, caching, and CI/CD oriented commands.

## When to Use This Skill
Use this skill at the start of a session to speed up subsequent queries, when reviewing complex git changes, or to find out exactly which tests are affected by your current edits.

## Supported Commands

### 1. `tldr daemon`
Manage the background analysis daemon (runs the SQLite cache and PDG engine in memory).
* **Usage:** `tldr daemon start` / `tldr daemon stop` / `tldr daemon status`
* **Crucial Rule:** Run `tldr daemon start` at the beginning of a coding session to drastically speed up commands like `impact` and `calls`.

### 2. `tldr warm`
Pre-warm the call graph cache into the daemon.
* **Usage:** `tldr warm <dir>`
* **Crucial Rule:** Use this immediately after starting the daemon so subsequent graph lookups return instantly.

### 3. `tldr diff`
View an AST-aware structural diff between two files or directories.
* **Usage:** `tldr diff <FILE_A> <FILE_B>`
* **Crucial Rule:** You MUST provide two positional arguments. Use this instead of `git diff`. It ignores whitespace and formatting, showing only what logical structures (functions/classes) actually changed.

### 4. `tldr change-impact`
Find which tests are affected by uncommitted code changes by tracing the reverse call graph from the modified AST nodes.
* **Usage:** `tldr change-impact .`
* **Crucial Rule:** Use this before pushing a PR to figure out exactly which tests you need to run locally, saving massive CI time.

### 5. `tldr todo`
Act as an internal orchestrator that aggregates Dead Code, Complexity, Cohesion, and Similarity engines into a single, ranked Top-20 refactoring backlog.
* **Usage:** `tldr todo <dir> --quick`
* **Crucial Rule:** This saves you from running and merging multiple tools manually. ALWAYS use `--quick` to get the top 20 functions instantly by skipping the slow cross-file clone detection engine.

### 6. `tldr stats`
View CLI telemetry and cache hit rates.
* **Usage:** `tldr stats`
* **Crucial Rule:** This is for debugging the `tldr` CLI itself (e.g., checking if the daemon is working), NOT for getting codebase statistics.

## Methodology Rules
1. **Always start the daemon.** If you plan to run multiple `tldr` trace commands, run `tldr daemon start` followed by `tldr warm .`.
2. **Review logic, not lines.** Always use `tldr diff` to review your own changes before asking for a code review or creating a PR description.
