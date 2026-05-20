# Command: `tldr reaching-defs`

## Ground Truth (`tldr reaching-defs --help`)
```text
Analyze reaching definitions for a function

Usage: tldr reaching-defs [OPTIONS] <FILE> <FUNCTION>

Arguments:
  <FILE>
          Source file to analyze

  <FUNCTION>
          Function name to analyze

Options:
  -l, --lang <LANG>
          Programming language (auto-detected from file extension if not specified)

      --var <VAR>
          Filter output to specific variable

      --line <LINE>
          Show definitions reaching specific line

      --show-chains
          Show def-use chains (enabled by default)

      --show-uninitialized
          Flag potentially uninitialized uses (enabled by default)

      --show-in-out
          Show IN/OUT sets per block

      --chains-only
          Show only def-use/use-def chains, hide header, blocks, and statistics

      --params <PARAMS>
          Function parameters (comma-separated, for uninit detection)

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
* **User/Agent Goal:** Trace where a variable's value originated.
* **When to choose this over similar tools:** Use when a variable has the wrong value and you need to find the assignment.

## Agent Synthesis
> **Note:** This tool exists in the CLI but is considered lower-priority or niche. If required, read the CLI help block above to infer flags.
