# Command: `tldr context`

## Ground Truth (`tldr context --help`)
```text
Build LLM-ready context from entry point

Usage: tldr context [OPTIONS] <ENTRY> [PATH]

Arguments:
  <ENTRY>
          Entry point function name

  [PATH]
          Project root directory as positional argument (mirrors sibling path-taking commands like `impact`, `whatbreaks`). When set, this takes precedence over `--project`. (med-cleanup-bundle-v1 / M1)
          
          [default: .]

Options:
  -p, --project <PROJECT>
          Project root directory (deprecated alias for the positional path argument; kept for back-compat). (med-cleanup-bundle-v1 / M1)

  -l, --lang <LANG>
          Programming language

  -d, --depth <DEPTH>
          Maximum traversal depth
          
          [default: 3]

      --include-docstrings
          Include function docstrings

      --file <FILE>
          Filter to functions in this file (for disambiguating common names like "render")

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
* **Command Executed:** `tldr context "backend/db.py:get_db_connection" .`
* **Raw Output:** Returns a JSON object containing the `entry_point`, `depth`, and an array of `functions` (with signatures, file paths, line numbers, and who they call).
* **Observation:** The `context` command successfully accepts a `<file>:<func>` shorthand syntax. This is highly useful for disambiguating functions with common names across files.

## Source Code Reality
* **Target File:** `crates/tldr-cli/src/commands/context.rs`
* **Code Evidence:** 
  ```rust
  // context-file-func-cross-lang-and-cpp-qualified-v1 (P14.AGG13-5, AGG14-8):
  // accept the `<file>:<func>` shorthand so users can disambiguate
  ```
* **Observation 1:** The rust code specifically highlights a parser feature that splits the string right-to-left. This allows agents to pass exactly what file and function they want in one argument.
* **Observation 2:** The positional `[PATH]` argument (which defaults to `.`) takes precedence over the deprecated `--project` flag.
* **Observation 3:** By default, it does *not* include docstrings. You have to explicitly ask for them to enrich the LLM context.

## Intent & Routing
* **User/Agent Goal:** Extract a specific function and the exact bodies of everything it calls (downward tree).
* **When to choose this over similar tools:** Use this BEFORE modifying a major function to ensure you understand everything it calls. WARNING: This only shows CALLEES (downward). To find CALLERS (who calls this), you must use `tldr impact` or `tldr references`.

## Agent Synthesis
> **How to use `tldr context` (LLM Context Builder):**
> Use this to gather the signatures and basic call patterns of an entry function and its immediate descendants.
> 1. Use the `<file>:<function>` shorthand format for the entry argument to ensure you target the exact function.
> 2. Always append the `--include-docstrings` flag so you get the actual meaning of the functions, not just their names.
> 
> **Command:** `tldr context <FILE>:<FUNCTION_NAME> . --depth 3 --include-docstrings`
