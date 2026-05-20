# Command: `tldr dead-stores`

## Ground Truth (`tldr dead-stores --help`)
```text
Find dead stores using SSA-based analysis

Usage: tldr dead-stores [OPTIONS] <file> <function>

Arguments:
  <file>
          Source file to analyze

  <function>
          Function name to analyze

Options:
  -l, --lang <LANG>
          Programming language (auto-detected from file extension if not specified)

      --compare
          Compare SSA-based detection with live-variables based detection

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
* **Under the hood:** Performs mathematical liveness analysis. A variable is "live" at a point if there is a path from that point to a read of the variable. If a variable is assigned a value but is not live immediately after, it is a dead store.
* **Performance:** Iterative backward data-flow analysis. Fast.
* **LLM Cognitive Load:** A dead store is often a symptom of a silent logic bug (e.g., computing a complex value and writing it to a variable, but accidentally using a different variable later, or leaving the calculation completely unused). This command exposes these structural bugs instantly.

## Intent & Routing
* **User/Agent Goal:** Perform liveness analysis to find variables that are assigned but never subsequently read.
* **When to choose this over similar tools:** Use to clean up code and identify silent logic errors where computed values are accidentally discarded.

## Agent Synthesis
> **How to use `tldr dead-stores`:**
> Use this to find variables that are assigned values but are never read afterwards on any execution path.
> 
> **Command:** `tldr dead-stores <file>`
