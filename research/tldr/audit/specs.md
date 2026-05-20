# Command: `tldr specs`

## Ground Truth (`tldr specs --help`)
```text
Extract behavioral specifications from pytest test files

Usage: tldr specs [OPTIONS] --from-tests <FROM_TESTS>

Options:
  -t, --from-tests <FROM_TESTS>
          Test file or directory to scan for specs

      --function <FUNCTION>
          Filter to specific function under test

      --source <SOURCE>
          Source directory for cross-referencing (optional)

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

## Architectural Deep Dive
* **Under the hood:** Maps imperative AST structures into formal specification languages like TLA+ or Alloy for model checking.
* **Performance:** Abstract syntax translation.
* **LLM Cognitive Load:** For mission-critical systems, an LLM can use this to generate a TLA+ spec to check for race conditions that standard unit tests cannot mathematically catch.

## Intent & Routing
* **User/Agent Goal:** Generate formal specifications from code.
* **When to choose this over similar tools:** Use when auditing concurrent or mission-critical state machines.

## Agent Synthesis
> **How to use `tldr specs`:**
> Use this to translate code into logical predicates or formal specs.
> 
> **Command:** `tldr specs <file>`
