# Command: `tldr coupling`

## Ground Truth (`tldr coupling --help`)
```text
Analyze coupling between modules/classes via cross-module call edges (afferent/efferent, instability). Measures function-call coupling, not import-level dependencies — use `tldr deps` or `tldr imports` for that (P12.AGG12-14)

Usage: tldr coupling [OPTIONS] <PATH_A> [PATH_B]

Arguments:
  <PATH_A>
          First source module (pair mode) or directory to scan (project-wide mode)

  [PATH_B]
          Second source module (pair mode). Omit for project-wide scan

Options:
      --timeout <TIMEOUT>
          Timeout in seconds (TIGER E02 mitigation)
          
          [default: 30]

      --project-root <PROJECT_ROOT>
          Project root for path validation (optional)

  -n, --max-pairs <MAX_PAIRS>
          Maximum number of pairs to show in project-wide mode (default: 20)
          
          [default: 20]

      --top <TOP>
          Limit output to top N modules ranked by instability (project-wide mode only). 0 = show all
          
          [default: 0]

      --cycles-only
          Only show modules involved in dependency cycles (project-wide mode only)

      --include-tests
          Include test files in analysis (excluded by default)

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
* **User/Agent Goal:** Execute the 'coupling' analysis capability.
* **When to choose this over similar tools:** Niche or specialized subcommand. Refer to the Ground Truth help block for specific flags.

## Agent Synthesis
> **Note:** This tool exists in the CLI but is considered lower-priority or niche. If required, read the CLI help block above to infer flags.
