# Command: `tldr available`

## Ground Truth (`tldr available --help`)
```text
Analyze available expressions for CSE detection

Usage: tldr available [OPTIONS] <FILE> <FUNCTION>

Arguments:
  <FILE>
          Source file to analyze

  <FUNCTION>
          Function name to analyze

Options:
  -l, --lang <LANG>
          Programming language (auto-detected from file extension if not specified)

      --check <CHECK>
          Check if a specific expression is available (e.g., "a + b")

      --at-line <AT_LINE>
          Show expressions available at a specific line number

      --killed-by <KILLED_BY>
          Show what kills a specific expression

      --cse-only
          Show only CSE opportunities, skip per-block details

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
* **Under the hood:** Computes the "available expressions" data-flow property. An expression `x op y` is available at a point if every path from the entry node to that point evaluates it, and none of its variables are modified after the last evaluation.
* **Performance:** Traditional compiler data-flow pass.
* **LLM Cognitive Load:** Useful for verifying compiler-level logic, checking if calculations can be safely hoisted out of loops, or identifying redundant calculations that the developer repeated unnecessarily.

## Intent & Routing
* **User/Agent Goal:** Find available expressions at a specific line.
* **When to choose this over similar tools:** Use for compiler-level logic checks, code cleanup, or performance optimizations (hoisting).

## Agent Synthesis
> **How to use `tldr available`:**
> Use this to identify expressions that have already been evaluated and are mathematically available at a specific line.
> 
> **Command:** `tldr available <file> <func> <line>`
