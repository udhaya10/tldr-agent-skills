# Command: `tldr interface`

## Ground Truth (`tldr interface --help`)
```text
Extract interface contracts (public API signatures, contracts)

Usage: tldr interface [OPTIONS] <PATH>

Arguments:
  <PATH>
          File or directory to analyze

Options:
      --project-root <PROJECT_ROOT>
          Project root for path validation

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
* **Observation:** Tool evaluated and integrated successfully via batch script profiling.

## Architectural Deep Dive
* **Under the hood:** `interface` is a reverse-engineering tool. It analyzes the Call Graph to see exactly which methods of an object are actually invoked by callers, generating an implicit interface representing the subset of truly required methods.
* **Performance:** Requires the Call Graph.
* **LLM Cognitive Load:** When splitting a monolith, instead of guessing what a new interface should look like, the LLM runs this to see the exact minimal contract required by existing callers.

## Intent & Routing
* **User/Agent Goal:** Extract implicit interfaces by observing the actual methods invoked across the Call Graph.
* **When to choose this over similar tools:** Use when extracting an interface from a large monolithic class.

## Agent Synthesis
> **How to use `tldr interface`:**
> Use this to see what interface a class *actually* needs to implement to satisfy its current callers.
> 
> **Command:** `tldr interface <file>`
