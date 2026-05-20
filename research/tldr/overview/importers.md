# Command: `tldr importers`

## Ground Truth (`tldr importers --help`)
```text
Find files that import a given module

Usage: tldr importers [OPTIONS] <MODULE> [PATH]

Arguments:
  <MODULE>
          Module name to search for

  [PATH]
          Directory to search (default: current directory)
          
          [default: .]

Options:
  -l, --lang <LANG>
          Programming language (auto-detected from directory if not specified)

  -m, --limit <LIMIT>
          Maximum number of importing files to show (0 = unlimited)
          
          [default: 50]

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
* **Observation:** Tool evaluated and integrated successfully via batch script profiling.

## Intent & Routing
* **User/Agent Goal:** Find all files in the project that import a specific module.
* **When to choose this over similar tools:** Use to trace reverse-dependencies at the file/module level.

## Agent Synthesis
> **Note:** This tool exists in the CLI but is considered lower-priority or niche. If required, read the CLI help block above to infer flags.
## Empirical Probes
* **Command Executed:** Checked `tldr importers --help` and source file.
* **Observation:** The inverse of `deps`. Given a module, what else uses it?

## Source Code Reality
* **Observation 1:** It accepts the `<MODULE>` name (e.g., `requests` or `utils.db`).
* **Observation 2:** Has a default limit of 50.

## Intent & Routing
* **User/Agent Goal:** Find all files in the project that import a specific module.
* **When to choose this over similar tools:** Use to trace reverse-dependencies at the file/module level.

## Agent Synthesis
> **How to use `tldr importers` (Reverse Dependency Search):**
> 1. Use this when you want to modify a module and need to find every file that imports it.
> **Command:** `tldr importers <MODULE>`
