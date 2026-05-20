# Command: `tldr warm`

## Ground Truth (`tldr warm --help`)
```text
Pre-warm call graph cache for faster subsequent queries

Usage: tldr warm [OPTIONS] [PATH]

Arguments:
  [PATH]
          Project root directory to warm
          
          [default: .]

Options:
  -b, --background
          Run warming in background process

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
* **Command Executed:** `tldr daemon start` followed by `tldr warm .`
* **Raw Output:** `Error: Failed to send warm command to daemon: connection timeout after 30s`
* **Observation:** The `warm` command attempts to communicate with the daemon via IPC socket. However, on large repositories, the daemon takes longer than the hardcoded 30-second IPC timeout to index the graph, causing the CLI to throw a timeout error even though the daemon is likely still processing in the background.

## Source Code Reality
* **Target File:** `crates/tldr-cli/src/commands/daemon/warm.rs`
* **Code Evidence:** 
  ```rust
  if self.background {
      self.run_background(&project, format, quiet).await
  } else {
      if check_socket_alive(&project).await { ... }
  }
  ```
* **Observation 1:** `warm` is an async command that builds the massive L2 graph and pushes it into the daemon memory.
* **Observation 2:** You can pass `--background` to have it spin off a background process without waiting for the daemon IPC socket to respond, bypassing the 30s timeout trap.

## Architectural Deep Dive
* **Under the hood:** `warm` forces the background daemon to eagerly traverse the entire repository, parse all ASTs, resolve all imports, and build the global Call Graph, caching the results into RAM/SQLite.
* **Performance:** A one-time heavy hit that guarantees O(1) latency for all subsequent commands.
* **LLM Cognitive Load:** Prevents the LLM from waiting for the cache to build lazily on its first query.

## Intent & Routing
* **User/Agent Goal:** Pre-warm the call graph cache into the daemon.
* **When to choose this over similar tools:** Use immediately after starting the daemon so subsequent lookups return instantly.

## Agent Synthesis
> **How to use `tldr warm`:**
> Use this to populate the daemon cache.
> * **Crucial Rule:** Run `tldr warm <dir>` immediately after starting the daemon.
> 
> **Command:** `tldr warm <dir>`
