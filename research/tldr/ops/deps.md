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

## Architectural Deep Dive
* **Under the hood:** Scans the entire project's imports to construct a Directed Graph of modules. It runs cycle detection algorithms (like Tarjan's) to find strongly connected components (circular imports).
* **Performance:** Relies heavily on the daemon cache for large projects.
* **LLM Cognitive Load:** Visualizes architecture without reading files. The `--show-cycles` flag allows the LLM to instantly diagnose `ImportError: cannot import name` bugs without having to manually trace the import chain.

## Intent & Routing
* **User/Agent Goal:** Extract the high-level module dependency graph and detect circular imports.
* **When to choose this over similar tools:** Use the `--show-cycles` flag specifically when debugging circular dependency crashes.

## Agent Synthesis
> **How to use `tldr deps`:**
> Use this to map the dependency graph of modules or hunt down circular imports.
> * **Crucial Rule:** Use `--show-cycles` specifically to debug circular import crashes.
> 
> **Command:** `tldr deps . --show-cycles`
