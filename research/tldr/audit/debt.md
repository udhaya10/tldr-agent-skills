# Command: `tldr debt`

## Ground Truth (`tldr debt --help`)
```text
Analyze technical debt using SQALE method

Usage: tldr debt [OPTIONS] [PATH]

Arguments:
  [PATH]
          Path to analyze (file or directory)
          
          [default: .]

Options:
  -c, --category <CATEGORY>
          Filter by SQALE category
          
          [possible values: reliability, security, maintainability, efficiency, changeability, testability]

  -k, --top <TOP>
          Number of top files to show
          
          [default: 20]

      --min-debt <MIN_DEBT>
          Minimum debt minutes to include file

      --hourly-rate <HOURLY_RATE>
          Hourly rate for cost estimation ($/hour)

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

## Intent & Routing
* **User/Agent Goal:** Calculate technical debt in minutes/hours.
* **When to choose this over similar tools:** Use for project planning and refactor prioritization.

## Agent Synthesis
> **Note:** This tool exists in the CLI but is considered lower-priority or niche. If required, read the CLI help block above to infer flags.
