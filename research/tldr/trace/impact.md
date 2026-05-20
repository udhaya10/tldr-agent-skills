# Command: `tldr impact`

## Ground Truth (`tldr impact --help`)
```text
Analyze impact of changing a function

Usage: tldr impact [OPTIONS] <FUNCTION> [PATH]

Arguments:
  <FUNCTION>
          Function name to analyze

  [PATH]
          Project root directory (default: current directory)
          
          [default: .]

Options:
  -l, --lang <LANG>
          Programming language

  -d, --depth <DEPTH>
          Maximum traversal depth
          
          [default: 5]

      --file <FILE>
          Filter by file path

      --type-aware
          Enable type-aware method resolution (resolves self.method() to ClassName.method)

  -f, --format <FORMAT>
          Output format
          
          Supported by every command: json, text, compact.
          
          Command-specific formats (rejected at runtime by other commands): sarif  — only: vuln, clones dot    — only: calls, impact, hubs, inheritance, clones, deps
          
          cli-error-clarity-v2 (P2.BUG-5): possible values are hidden on the global help to avoid promising sarif/dot for every subcommand. Run `tldr <cmd> --help` to confirm what a specific command emits, and see `validate_format_for_command` in `output.rs` for the source of truth.
          
          [default: json]

  -q, --quiet
          Suppress progress output

  -v, --verbose
          Enable verbose/debug output

  -h, --help
          Print help (see a summary with '-h')
```

## Empirical Probes
* **Command Executed:** `tldr impact get_db_connection .`
* **Raw Output:** `Error: Function not found: get_db_connection`
* **Observation:** Fails to find functions if the AST hasn't been cached or if the language isn't strongly typed enough to instantly resolve the edge on a cold start.

## Source Code Reality
* **Target File:** `crates/tldr-cli/src/commands/impact.rs`
* **Code Evidence:** 
  ```rust
  require_directory(&self.path, "impact")?;
  ```
  ```rust
  if let Some(report) = try_daemon_route::<ImpactReport>(&self.path, "impact", ...)
  ```
* **Observation 1:** `impact` **MUST** be run on a directory (like `.`). Passing a file throws a hard error.
* **Observation 2:** The command hits the daemon first. If the daemon isn't running or the project isn't warm, it does a cold graph build which can miss dynamic edges.

## Intent & Routing
* **User/Agent Goal:** View the reverse call graph (who calls this function).
* **When to choose this over similar tools:** Use to assess blast radius before changing or deleting a function.

## Agent Synthesis
> **How to use `tldr impact` (Blast Radius):**
> Use this to find all reverse-dependencies (who calls a function).
> 1. You MUST run this on a directory (e.g., `.`), never a file. 
> 2. The target `<FUNCTION>` is just the name of the function, no parentheses.
> 3. If the function is not found, you MUST ensure the cache is warm by running `tldr daemon start && tldr warm .` before running impact again.
> 
> **Command:** `tldr impact <FUNCTION_NAME> . --depth 5`
