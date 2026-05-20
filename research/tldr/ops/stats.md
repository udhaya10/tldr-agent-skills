# Command: `tldr stats`

## Ground Truth (`tldr stats --help`)
```text
Show TLDR usage statistics

Usage: tldr stats [OPTIONS]

Options:
  -f, --format <FORMAT>
          Output format
          
          Supported by every command: json, text, compact.
          
          Command-specific formats (rejected at runtime by other commands): sarif  — only: vuln, clones dot    — only: calls, impact, hubs, inheritance, clones, deps
          
          cli-error-clarity-v2 (P2.BUG-5): possible values are hidden on the global help to avoid promising sarif/dot for every subcommand. Run `tldr <cmd> --help` to confirm what a specific command emits, and see `validate_format_for_command` in `output.rs` for the source of truth.
          
          [default: json]

  -l, --lang <LANG>
          Programming language (auto-detect if not specified)

  -q, --quiet
          Suppress progress output

  -v, --verbose
          Enable verbose/debug output

  -h, --help
          Print help (see a summary with '-h')
```

## Empirical Probes
* **Command Executed:** Checked `tldr stats --help` and ran `tldr stats`.
* **Raw Output:** Initially returns a JSON object stating `No usage recorded yet`. 
* **Observation:** `tldr stats` doesn't report on the *codebase*; it reports on the *CLI itself*. It tracks how many times you've invoked commands and what their latencies are, provided the daemon is running.

## Source Code Reality
* **Target File:** `crates/tldr-cli/src/commands/daemon/stats.rs`
* **Observation 1:** The daemon records telemetry locally. 
* **Observation 2:** This is purely an operational tool to measure the performance of the TLDR CLI engine.

## Architectural Deep Dive
* **Under the hood:** `stats` queries the IPC socket of the background daemon to retrieve internal SQLite cache hit rates, AST node counts, and memory usage.
* **Performance:** Instant.
* **LLM Cognitive Load:** This is exclusively for debugging the toolchain. If a command is timing out, the agent runs `stats` to see if the daemon is actually running or if the cache is cold.

## Intent & Routing
* **User/Agent Goal:** View CLI telemetry and cache hit rates.
* **When to choose this over similar tools:** Use ONLY to debug the `tldr` CLI itself, not for codebase metrics.

## Agent Synthesis
> **How to use `tldr stats`:**
> Use this to verify if the background daemon is running and caching properly.
> * **Crucial Rule:** This is for debugging the `tldr` CLI itself, NOT for getting codebase statistics.
> 
> **Command:** `tldr stats`
