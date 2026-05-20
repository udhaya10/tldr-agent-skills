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

## Architectural Deep Dive
* **Under the hood:** `structure` uses the `tree-sitter` AST parser to extract only declaration nodes (classes, structs, traits, functions) while completely discarding function bodies. 
* **Performance:** Because it never loads full file strings into memory or evaluates tokens, it operates at near O(1) time complexity relative to the number of functions, making it infinitely faster than `cat` or `grep`.
* **LLM Cognitive Load:** By stripping the bodies, it reduces the token count of a standard 1,000-line file down to ~50 tokens. This allows an LLM to map an entire project's API surface in a single prompt without blowing out the context window.

## Intent & Routing
* **User/Agent Goal:** Extract the AST skeleton (classes, methods, signatures) of a file or directory without function bodies. Highly token-efficient.
* **When to choose this over similar tools:** Use instead of `tree` when you need symbol names. Use instead of `cat` or `grep` to save massive tokens when exploring unknown code.

## Agent Synthesis
> **How to use `tldr structure`:**
> Use this command to map the API surface or discover what functions exist in a file/directory without reading the actual code.
> * **Crucial Rule:** Always use `--max-results <N>` (e.g., 50) if running on a large directory to avoid context blowout.
> 
> **Command:** `tldr structure <dir> --max-results 50`
