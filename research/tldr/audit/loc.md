# Command: `tldr loc`

## Ground Truth (`tldr loc --help`)
```text
Count lines of code with type breakdown (code, comments, blanks)

Usage: tldr loc [OPTIONS] [PATH]

Arguments:
  [PATH]
          Directory or file to analyze
          
          [default: .]

Options:
  -l, --lang <LANG>
          Filter to specific language

      --by-file
          Show per-file breakdown

      --by-dir
          Aggregate by directory

  -e, --exclude <EXCLUDE>
          Exclude patterns (glob syntax), can be specified multiple times

      --include-hidden
          Include hidden files (dotfiles)

      --no-gitignore
          Ignore .gitignore rules

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
* **User/Agent Goal:** Execute the 'loc' analysis capability.
* **When to choose this over similar tools:** Niche or specialized subcommand. Refer to the Ground Truth help block for specific flags.

## Agent Synthesis
> **Note:** This tool exists in the CLI but is considered lower-priority or niche. If required, read the CLI help block above to infer flags.
