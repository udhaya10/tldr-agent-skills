# Command: `tldr dice`

## Ground Truth (`tldr dice --help`)
```text
Compare similarity between two code fragments

Usage: tldr dice [OPTIONS] <TARGET1> <TARGET2>

Arguments:
  <TARGET1>
          First target: file, file::function, or file:start:end

  <TARGET2>
          Second target: file, file::function, or file:start:end

Options:
      --normalize <NORMALIZE>
          Normalization mode: none, identifiers, literals, all (default: all)
          
          [default: all]

      --language <LANGUAGE>
          Language hint (auto-detected if not specified)

  -o, --output <OUTPUT>
          Output format: json, text (default: json)
          
          [default: json]

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
* **User/Agent Goal:** Compare the structural similarity between two specific functions.
* **When to choose this over similar tools:** Use to verify if two functions are safe to merge during refactoring.

## Agent Synthesis
> **Note:** This tool exists in the CLI but is considered lower-priority or niche. If required, read the CLI help block above to infer flags.
