# Command: `tldr fix apply`

## Ground Truth (`tldr fix apply --help`)
```text
Apply fix edits to source code and write the patched result

Usage: tldr fix apply [OPTIONS] --source <SOURCE>

Options:
  -s, --source <SOURCE>
          Source file to patch

  -e, --error <ERROR>
          Inline error text

      --error-file <ERROR_FILE>
          File containing error text

  -o, --output <OUTPUT>
          Output file for the patched source (stdout if not specified)

      --stdin
          Read error text from stdin

  -i, --in-place
          Write the patched source back to the original file (in-place fix)

  -d, --diff
          Show a unified diff instead of the full patched source

      --api-surface <API_SURFACE>
          Path to API surface JSON file for enhanced analysis (e.g., TS2339 property suggestions)

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
* **User/Agent Goal:** Apply an LLM-generated fix to a file.
* **When to choose this over similar tools:** Use to orchestrate file patching.

## Agent Synthesis
> **Note:** This tool exists in the CLI but is considered lower-priority or niche. If required, read the CLI help block above to infer flags.
