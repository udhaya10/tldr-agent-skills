# Command: `tldr dead`

## Ground Truth (`tldr dead --help`)
```text
Find dead (unreachable) code

Usage: tldr dead [OPTIONS] [PATH]

Arguments:
  [PATH]
          Project root directory (default: current directory)
          
          [default: .]

Options:
  -l, --lang <LANG>
          Programming language

  -e, --entry-points <ENTRY_POINTS>
          Custom entry point patterns (comma-separated)

      --max-items <MAX_ITEMS>
          Maximum number of dead functions to display
          
          [default: 100]

      --call-graph
          Use call-graph-based analysis instead of the default reference counting

      --no-default-ignore
          Walk vendored/build dirs (node_modules, target, dist, etc.) that would normally be skipped

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
* **Command Executed:** Checked `tldr dead --help` and tested on `Stock-Monitor`.
* **Raw Output:** Returns an array of `dead_functions` and `possibly_dead` functions (along with file, name, signature, and ref_count).
* **Observation:** The default analysis relies on reference counting. If a function has a `ref_count` of 0, it is flagged as dead. 

## Source Code Reality
* **Target File:** `crates/tldr-cli/src/commands/dead.rs`
* **Observation 1:** It accepts a comma-separated list of `--entry-points`. This is critical for library developers; without an entry point, public exports might be flagged as dead just because they aren't used internally.
* **Observation 2:** You can append `--call-graph`. Instead of simple reference counting, this builds the entire L2 graph from the entry points and finds unreachable nodes. This is slower but much more accurate for finding "islands" of dead code (where A calls B, and B calls A, but nothing calls A or B).

## Intent & Routing
* **User/Agent Goal:** Find unreachable functions and classes.
* **When to choose this over similar tools:** Use with `--call-graph` to find circular islands of dead code.

## Agent Synthesis
> **How to use `tldr dead` (Dead Code Detection):**
> Use this command to find unreachable functions, methods, and classes that can be safely deleted.
> 1. By default, it uses fast reference counting.
> 2. If you are analyzing a library, provide `--entry-points main,export_func`.
> 3. For the most accurate results (finding circular dead islands), append `--call-graph`.
> 
> **Command:** `tldr dead . --call-graph`
