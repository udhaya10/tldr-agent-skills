# Command: `tldr cognitive`

## Ground Truth (`tldr cognitive --help`)
```text
Calculate cognitive complexity for functions (SonarQube algorithm)

Usage: tldr cognitive [OPTIONS] [PATH]

Arguments:
  [PATH]
          File or directory to analyze
          
          [default: .]

Options:
      --function <FUNCTION>
          Specific function to analyze (analyzes all if not specified) Note: --function is the long form; -f short flag is NOT used to avoid collision with --format

  -l, --lang <LANG>
          Programming language (auto-detect if not specified)

      --threshold <THRESHOLD>
          Complexity threshold for violations (default: 15)
          
          [default: 15]

      --high-threshold <HIGH_THRESHOLD>
          High threshold for severe violations (default: 25)
          
          [default: 25]

      --show-contributors
          Show line-by-line complexity contributors

      --include-cyclomatic
          Include cyclomatic complexity comparison

      --top <TOP>
          Maximum functions to report (0 = all)
          
          [default: 50]

  -e, --exclude <EXCLUDE>
          Exclude patterns (glob syntax), can be specified multiple times

      --include-hidden
          Include hidden files (dotfiles)

      --max-files <MAX_FILES>
          Maximum files to process (0 = unlimited)
          
          [default: 0]

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
* **User/Agent Goal:** Calculate cognitive complexity.
* **When to choose this over similar tools:** Use to identify code that is too hard for humans to read.

## Agent Synthesis
> **Note:** This tool exists in the CLI but is considered lower-priority or niche. If required, read the CLI help block above to infer flags.
