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

## Architectural Deep Dive
* **Under the hood:** Performs a reverse AST search across the entire project workspace, building an index of all files that declare an import matching the target module.
* **Performance:** Cached via the daemon if running. Without daemon, requires parsing imports of the whole project.
* **LLM Cognitive Load:** Provides an immediate blast-radius check at the file level. The `--limit` flag is crucial because tracing a highly-imported utility module (like `logger`) will return thousands of files, destroying the context window.

## Intent & Routing
* **User/Agent Goal:** List inbound dependencies (who imports this file).
* **When to choose this over similar tools:** Use to trace reverse-dependencies at the file/module level before deleting or renaming a file.

## Agent Synthesis
> **How to use `tldr importers`:**
> Use this to find all files in the project that import a specific module.
> * **Crucial Rule:** Use `--limit <N>` (e.g., 20) to restrict output size on highly-imported utility modules.
> 
> **Command:** `tldr importers <module> --limit 20`
