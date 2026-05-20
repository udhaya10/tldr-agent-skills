# Command: `tldr churn`

## Ground Truth (`tldr churn --help`)
```text
Analyze git-based code churn

Usage: tldr churn [OPTIONS] [PATH]

Arguments:
  [PATH]
          Directory to analyze (default: current dir)
          
          [default: .]

Options:
      --days <DAYS>
          Days of history to analyze
          
          [default: 365]

      --top <TOP>
          Maximum files to show
          
          [default: 20]

  -e, --exclude <EXCLUDE>
          Exclude files matching pattern (glob syntax, can be repeated)

      --authors
          Include author statistics

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
* **User/Agent Goal:** Analyze git churn.
* **When to choose this over similar tools:** Use to find files that change too frequently.

## Agent Synthesis
> **Note:** This tool exists in the CLI but is considered lower-priority or niche. If required, read the CLI help block above to infer flags.
