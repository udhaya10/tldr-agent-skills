# Command: `tldr structure`

## Ground Truth (`tldr structure --help`)
```text
Extract code structure (functions, classes, imports)

Usage: tldr structure [OPTIONS] [PATH]

Arguments:
  [PATH]
          Directory to scan (default: current directory)
          
          [default: .]

Options:
  -l, --lang <LANG>
          Programming language (auto-detected if not specified)

  -m, --max-results <MAX_RESULTS>
          Maximum number of files to process (0 = unlimited)
          
          [default: 0]

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
* **Command Executed:** Checked `tldr structure --help` and source file.
* **Observation:** Extracts the outline of every file (functions, classes, imports) without the bodies. 

## Source Code Reality
* **Observation 1:** Uses tree-sitter to parse out the AST shells.
* **Observation 2:** By default, it processes all files (`--max-results 0`). For massive codebases, this generates a massive JSON payload. Agents should probably combine this with standard bash commands to limit scope (e.g., passing a specific folder instead of `.`).

## Intent & Routing
* **User/Agent Goal:** See the outline of classes, functions, and imports in a directory without reading the bodies.
* **When to choose this over similar tools:** Use instead of `tree` when you need symbol names. Use instead of `cat` to save massive tokens.

## Agent Synthesis
> **How to use `tldr structure` (Codebase Skeleton):**
> 1. Use this to get the exact names of classes, functions, and imports in a directory.
> 2. Pass a specific subdirectory rather than `.` on massive monorepos to save context tokens.
> **Command:** `tldr structure src/components/`
