# Command: `tldr daemon`

## Ground Truth (`tldr daemon --help`)
```text
Daemon management commands (start, stop, status)

Usage: tldr daemon [OPTIONS] <COMMAND>

Commands:
  start   Start the TLDR daemon
  stop    Stop the TLDR daemon
  status  Show daemon status
  query   Send a raw query to the daemon
  notify  Notify daemon of file changes
  list    List all running daemons (multi-daemon registry, v0.3.0)
  help    Print this message or the help of the given subcommand(s)

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
* **Command Executed:** Checked `tldr daemon --help` and `tldr daemon status`.
* **Raw Output:** Returns JSON state of the background daemon (e.g., `{"status": "not_running"}`).
* **Observation:** The daemon is a background process that caches ASTs and graphs to make subsequent `tldr` queries instantaneous. It manages its own state and ties itself to a specific project directory.

## Source Code Reality
* **Observation 1:** The daemon has a multi-daemon registry (v0.3.0). It tracks multiple daemons if you have multiple projects open. 
* **Observation 2:** You start it via `tldr daemon start --project .`.
* **Observation 3:** By default, if the daemon is not running, CLI commands will fall back to cold-boot computation, which is slow. Thus, ensuring the daemon is running is a critical first step for an agent taking over a workspace.

## Intent & Routing
* **User/Agent Goal:** Manage the background analysis daemon.
* **When to choose this over similar tools:** Use `tldr daemon start` at the beginning of a session to speed up subsequent queries.

## Agent Synthesis
> **How to use `tldr daemon` (Cache Engine):**
> Use this to start the background caching engine, making all other `tldr` queries 10x-100x faster.
> 1. You should run this once at the beginning of your session.
> 2. To check if it's running: `tldr daemon status`
> 3. To start it: `tldr daemon start --project .`
> 
> **Command:** `tldr daemon start --project .`
