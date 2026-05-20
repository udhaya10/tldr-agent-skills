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

## Intent & Routing
* **User/Agent Goal:** Find the intersection of data flow between a source line and a target line.
* **When to choose this over similar tools:** Use when tracking how a variable mutates between two specific points.

## Agent Synthesis
> **Note:** This tool exists in the CLI but is considered lower-priority or niche. If required, read the CLI help block above to infer flags.
