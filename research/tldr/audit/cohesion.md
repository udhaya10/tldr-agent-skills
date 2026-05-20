# Command: `tldr cohesion`

## Ground Truth (`tldr cohesion --help`)
```text
Analyze class cohesion using LCOM4 metric

Usage: tldr cohesion [OPTIONS] <PATH>

Arguments:
  <PATH>
          File or directory to analyze

Options:
      --min-methods <MIN_METHODS>
          Minimum number of instance methods for a class to be included in analysis. Classes with fewer methods are filtered from results. For Rust and Go, only instance methods (with self/receiver) are counted, not associated functions like new() or default()
          
          [default: 1]

      --include-dunder
          Include dunder methods (__init__, __str__, etc.) in analysis

      --timeout <TIMEOUT>
          Analysis timeout in seconds
          
          [default: 30]

      --project-root <PROJECT_ROOT>
          Project root for path validation (optional)

  -l, --lang <LANG>
          Language filter (auto-detected if omitted)

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
* **User/Agent Goal:** Analyze class cohesion (LCOM4).
* **When to choose this over similar tools:** Use to identify classes that should be split into smaller classes.

## Agent Synthesis
> **Note:** This tool exists in the CLI but is considered lower-priority or niche. If required, read the CLI help block above to infer flags.
