# Command: `tldr coverage`

## Ground Truth (`tldr coverage --help`)
```text
Parse coverage reports (Cobertura XML, LCOV, coverage.py JSON)

Usage: tldr coverage [OPTIONS] <REPORT>

Arguments:
  <REPORT>
          Path to coverage report file

Options:
  -R, --report-format <REPORT_FORMAT>
          Coverage report format (auto-detect if not specified)

          Possible values:
          - cobertura:  Cobertura XML format (GitLab/Jenkins standard)
          - lcov:       LCOV format (llvm-cov, gcov)
          - coveragepy: coverage.py JSON format
          - auto:       Auto-detect from file content
          
          [default: auto]

      --threshold <THRESHOLD>
          Minimum coverage threshold (default: 80%)
          
          [default: 80.0]

      --by-file
          Show per-file coverage breakdown

      --uncovered
          List uncovered lines and functions

      --filter <FILTER>
          Filter to files matching pattern (can be repeated)

      --sort <SORT>
          Sort files by coverage

          Possible values:
          - asc:  Ascending order (lowest coverage first)
          - desc: Descending order (highest coverage first)

      --base-path <BASE_PATH>
          Base path for resolving file paths (for existence checking)

      --uncovered-only
          Show only files below threshold

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
* **User/Agent Goal:** Execute the 'coverage' analysis capability.
* **When to choose this over similar tools:** Niche or specialized subcommand. Refer to the Ground Truth help block for specific flags.

## Agent Synthesis
> **Note:** This tool exists in the CLI but is considered lower-priority or niche. If required, read the CLI help block above to infer flags.
