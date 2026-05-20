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

## Architectural Deep Dive
* **Under the hood:** `debt` calculates technical debt using standard industry models (e.g., SonarQube's SQALE model). It assigns a time-to-fix (in minutes/hours) for every smell, complexity violation, and duplication found.
* **Performance:** Runs all audit engines and aggregates the time values.
* **LLM Cognitive Load:** Translates abstract code quality into tangible effort (time). Useful for the LLM to report back to users on the feasibility of a refactor ("This will take roughly 4 hours of effort based on the debt score").

## Intent & Routing
* **User/Agent Goal:** Calculate technical debt in minutes/hours.
* **When to choose this over similar tools:** Use when you need to quantify refactoring effort in terms of time.

## Agent Synthesis
> **How to use `tldr debt`:**
> Use this to calculate a time-estimate (minutes/hours) of the codebase's technical debt.
> 
> **Command:** `tldr debt <dir>`
