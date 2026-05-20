# Command: `tldr deps`

## Ground Truth (`tldr deps --help`)
```text
Analyze module dependencies

Usage: tldr deps [OPTIONS] [PATH]

Arguments:
  [PATH]
          Path to analyze (directory)
          
          [default: .]

Options:
  -l, --lang <LANG>
          Programming language filter: python, typescript, go, rust

      --include-external
          Include external (third-party) dependencies in the report

      --collapse-packages
          Collapse files into package-level nodes

  -d, --depth <DEPTH>
          Maximum transitive depth (None = unlimited)

      --show-cycles
          Only show circular dependencies (skip full graph)

      --max-cycle-length <MAX_CYCLE_LENGTH>
          Maximum cycle length to report (default: 10)
          
          [default: 10]

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
* **User/Agent Goal:** Map the dependency graph of modules or hunt down circular imports.
* **When to choose this over similar tools:** Use the `--show-cycles` flag specifically when debugging 'ImportError: cannot import name' issues.

## Agent Synthesis
> **Note:** This tool exists in the CLI but is considered lower-priority or niche. If required, read the CLI help block above to infer flags.
## Empirical Probes
* **Command Executed:** Checked `tldr deps --help` and source file.
* **Observation:** Module dependency analyzer. Similar to `structure` but focuses on import graphs.

## Source Code Reality
* **Observation 1:** Has an incredibly useful `--show-cycles` flag that filters the entire graph down to just the circular dependencies.
* **Observation 2:** Skips third-party libraries unless you explicitly pass `--include-external`.

## Intent & Routing
* **User/Agent Goal:** Map the dependency graph of modules or hunt down circular imports.
* **When to choose this over similar tools:** Use the `--show-cycles` flag specifically when debugging 'ImportError: cannot import name' issues.

## Agent Synthesis
> **How to use `tldr deps` (Dependency Graph):**
> 1. Use this to map out how modules depend on each other.
> 2. The most powerful agentic use-case is appending `--show-cycles` to hunt down circular import errors.
> **Command:** `tldr deps . --show-cycles`
