# Command: `tldr hotspots`

## Ground Truth (`tldr hotspots --help`)
```text
Identify churn x complexity hotspots

Usage: tldr hotspots [OPTIONS] [PATH]

Arguments:
  [PATH]
          Directory to analyze (default: current directory)
          
          [default: .]

Options:
      --days <DAYS>
          Days of git history to analyze
          
          [default: 365]

      --top <TOP>
          Number of hotspots to return
          
          [default: 20]

      --by-function
          Analyze at function level (default: file level)

      --show-trend
          Include complexity trend analysis

      --min-commits <MIN_COMMITS>
          Minimum commits to be considered a hotspot
          
          [default: 3]

  -e, --exclude <EXCLUDE>
          Exclude patterns (glob syntax, can be repeated)

      --threshold <THRESHOLD>
          Minimum hotspot score threshold (0.0 to 1.0)

      --since <SINCE>
          Since date (ISO format, e.g., 2024-01-01)

      --recency-halflife <RECENCY_HALFLIFE>
          Exponential decay half-life in days (default: 90, 0 = no decay)
          
          [default: 90]

      --include-bots
          Include bot/automated commits in churn analysis (default: filtered)

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
* **User/Agent Goal:** Execute the 'hotspots' analysis capability.
* **When to choose this over similar tools:** Niche or specialized subcommand. Refer to the Ground Truth help block for specific flags.

## Agent Synthesis
> **Note:** This tool exists in the CLI but is considered lower-priority or niche. If required, read the CLI help block above to infer flags.
