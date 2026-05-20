# Command: `tldr contracts`

## Ground Truth (`tldr contracts --help`)
```text
Infer pre/postconditions from guard clauses, assertions, isinstance checks

Usage: tldr contracts [OPTIONS] <FILE> <FUNCTION>

Arguments:
  <FILE>
          Source file to analyze

  <FUNCTION>
          Function name to analyze

Options:
  -l, --lang <LANG>
          Programming language (auto-detected from file extension if not specified)

      --limit <LIMIT>
          Maximum conditions to report per category
          
          [default: 100]

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
* **Under the hood:** `contracts` uses AST extraction combined with heuristics to find runtime assertions, explicit `require`/`ensure` blocks, and structured docstring parameter constraints.
* **Performance:** AST parser, very fast.
* **LLM Cognitive Load:** Before an LLM rewrites a critical function, it extracts the contracts to ensure it doesn't accidentally remove a hidden mathematical boundary condition in the new implementation.

## Intent & Routing
* **User/Agent Goal:** Extract preconditions, postconditions, and assertions from the AST.
* **When to choose this over similar tools:** Use to explicitly identify undocumented assumptions in legacy code before rewriting it.

## Agent Synthesis
> **How to use `tldr contracts`:**
> Use this to extract mathematical boundaries and assertions from a function.
> 
> **Command:** `tldr contracts <dir>`
