# Command: `tldr imports`

## Ground Truth (`tldr imports --help`)
```text
Parse import statements from a file

Usage: tldr imports [OPTIONS] <FILE>

Arguments:
  <FILE>
          File to parse

Options:
  -l, --lang <LANG>
          Programming language (auto-detect if not specified)

      --legacy-array
          Emit the legacy bare-array JSON shape (`[ImportInfo, ...]`) instead of the canonical envelope object `{file, language, imports}`. Provided for backward compatibility with consumers that hard-coded `jq '.[]'` over the top level. New code should consume the envelope shape

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
* **Under the hood:** Parses the AST for `Import` and `ImportFrom` nodes (or their equivalents in other languages), resolving aliases and relative paths into absolute module references.
* **Performance:** Single-file AST parse, extremely fast.
* **LLM Cognitive Load:** Gives the LLM an immediate map of outbound dependencies (what this file relies on) without needing to parse the top of the file manually.

## Intent & Routing
* **User/Agent Goal:** List outbound dependencies (what this file imports).
* **When to choose this over similar tools:** Use when you need to know a file's immediate dependencies to understand its external state requirements.

## Agent Synthesis
> **How to use `tldr imports`:**
> Use this to see what external and internal modules a specific file relies on.
> 
> **Command:** `tldr imports <file>`
