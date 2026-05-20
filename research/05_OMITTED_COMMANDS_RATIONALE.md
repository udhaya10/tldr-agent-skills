# Omitted Commands Rationale

During the deep empirical profiling of the `tldr-code` CLI, we generated 67 command research dossiers. However, only **60 commands** were ultimately mapped into the 13 production-grade `SKILL.md` files.

This document serves as an audit trail for developers to understand **why** the remaining commands were explicitly excluded from the Agent Skills ecosystem.

## 1. Internal Engine Hallucinations (Not Public Commands)
These files were generated during the initial help-extraction scraping, but empirical testing proved they are not exposed as top-level CLI commands. They are internal engines that power other tools (like `slice`).
* **`cfg`** (Control Flow Graph): Omitted. If an agent tries to run `tldr cfg`, the CLI returns `error: unrecognized subcommand 'cfg'`.
* **`dfg`** (Data Flow Graph): Omitted. Same reason.
*(Note: Agents are instructed in `tldr-deep/SKILL.md` to access these graphs implicitly via `slice`, `reaching-defs`, and `chop`)*.

## 2. Active Suppression (Harmful or Useless to Autonomous Agents)
These commands are valid CLI tools but were intentionally hidden from the LLM. Giving an autonomous agent access to these commands causes performance degradation or token waste without providing actionable refactoring value.

* **`tldr cache`**: Omitted. This command clears the internal SQLite database cache. If an agent runs this autonomously while trying to "fix" something, it will wipe the cache and cause all subsequent `tldr` commands in the session to run 10x slower.
* **`tldr doctor`**: Omitted. This command checks if Python, Rustc, and other system binaries are installed. It is purely for a human operator debugging their local environment setup. An agent cannot fix missing system binaries.
* **`tldr surface`**: Omitted. This command extracts the API surface area, but it outputs massive amounts of raw structural data. The agent is much better served using `tldr api-check` (to compare surface changes) or `tldr interface` (to synthesize interfaces), which provide higher-level, actionable context.

## 3. Structural Duplicates and Grouping
* **`deps`**: We initially had two research files (`overview/deps.md` and `ops/deps.md`). This was consolidated into a single `deps` command under the `tldr-overview` skill.
* **`daemon`**: The `daemon` command has subcommands (`start`, `stop`, `status`). Instead of giving them separate entries, they are grouped under a single `daemon` entry in `tldr-ops/SKILL.md`.

## Summary
By rigorously pruning these 7 specific edge cases, we ensure the Claude Code agent only sees the highest-signal, safest, and most actionable commands, strictly adhering to the **Progressive Disclosure** and **Zero Trust** principles of our skill architecture.
