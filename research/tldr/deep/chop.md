# Command: `tldr chop`

## Ground Truth (`tldr chop --help`)
```text
Compute chop slice - intersection of forward and backward slices

Usage: tldr chop [OPTIONS] <file> <function> <source_line> <target_line>

Arguments:
  <file>
          Source file to analyze

  <function>
          Function name containing both lines

  <source_line>
          Line to trace FROM (source of data flow)

  <target_line>
          Line to trace TO (target of data flow)

Options:
  -l, --lang <LANG>
          Programming language (auto-detected from file extension if not specified)

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
* **Under the hood:** `chop` finds the intersection of a backward slice from a target line and a forward slice from a source line. This highlights only the nodes in the PDG that lie directly on the path of dependency between the two points.
* **Performance:** Computes two separate slices and intersects them. O(N) relative to the size of the localized PDG.
* **LLM Cognitive Load:** When tracking how a variable was modified between its declaration (source) and its usage (target), `chop` completely filters out all unrelated logic, loops, and conditions inside the function, leaving a clean, linear mutation path for the LLM to review.

## Intent & Routing
* **User/Agent Goal:** Find the intersection of data flow between a source line and a target line.
* **When to choose this over similar tools:** Use when tracking how a specific variable mutates between two specific points in a function, filtering out all unrelated logic.

## Agent Synthesis
> **How to use `tldr chop`:**
> Use this to isolate the exact lines that modified a variable between a starting source line and an ending target line.
> 
> **Command:** `tldr chop <file> <func> <source_line> <target_line>`
