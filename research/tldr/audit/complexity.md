# Command: `tldr complexity`

## Ground Truth (`tldr complexity --help`)
```text
Calculate function complexity metrics

Usage: tldr complexity [OPTIONS] <FILE> <FUNCTION>

Arguments:
  <FILE>
          file containing the function

  <FUNCTION>
          Function name to analyze

Options:
  -l, --lang <LANG>
          Programming language (auto-detect if not specified)

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
* **Under the hood:** Calculates McCabe's Cyclomatic Complexity by counting the number of linearly independent paths (nodes - edges + 2) in a function's Control Flow Graph. It counts `if`, `while`, `for`, `case`, etc.
* **Performance:** Single pass over the AST.
* **LLM Cognitive Load:** A function with complexity > 10 has too many branches to be fully tested easily. The LLM uses this to identify which functions desperately need unit tests or need to be split up to reduce testing permutations.

## Intent & Routing
* **User/Agent Goal:** Analyze function complexity (Cyclomatic).
* **When to choose this over similar tools:** Use to find branch-heavy functions that need more unit tests.

## Agent Synthesis
> **How to use `tldr complexity`:**
> Use this to identify branch-heavy functions that require more testing or splitting.
> 
> **Command:** `tldr complexity <dir>`
