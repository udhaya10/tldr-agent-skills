# Command: `tldr references`

## Ground Truth (`tldr references --help`)
```text
Find all references to a symbol

Usage: tldr references [OPTIONS] <SYMBOL> [PATH]

Arguments:
  <SYMBOL>
          Symbol to find references for

  [PATH]
          Path to search in (directory)
          
          [default: .]

Options:
      --include-definition
          Include definition location in results

  -t, --kinds <KINDS>
          Filter by reference kinds (comma-separated: call,read,write,import,type)

  -s, --scope <SCOPE>
          Search scope: local, file, workspace
          
          [default: workspace]

  -n, --limit <LIMIT>
          Maximum number of results to return
          
          [default: 20]

  -C, --context-lines <CONTEXT_LINES>
          Number of context lines before and after (not implemented yet)
          
          [default: 0]

      --min-confidence <MIN_CONFIDENCE>
          Minimum confidence threshold (0.0-1.0). References below this are filtered out
          
          [default: 0.0]

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
* **Command Executed:** `tldr references get_db_connection .`
* **Raw Output:** Returns a JSON object containing the exact `definition` location and an array of `references`. Crucially, the references include `kind` (e.g., `import`, `call`, `definition`) and `confidence`.
* **Observation:** This command is the absolute best way to find *how* a function is used across the codebase. It even tracks import statements, which `impact` sometimes misses.

## Source Code Reality
* **Target File:** `crates/tldr-cli/src/commands/references.rs`
* **Code Evidence:** 
  ```rust
  if !self.path.exists() {
      anyhow::bail!("Path not found: '{}'", self.path.display());
  }
  ```
* **Observation 1:** `references` requires a directory (like `.` or `src/`) to search. It will crash if passed a file.
* **Observation 2:** The `--limit` defaults to 20. If you are searching for a highly ubiquitous symbol, you may need to bump this.
* **Observation 3:** You can filter by `kind`. E.g., `--kinds call` will filter out the `import` statements.

## Intent & Routing
* **User/Agent Goal:** Find all usages of a specific symbol.
* **When to choose this over similar tools:** Use when renaming or modifying a variable/function to find all call sites.

## Agent Synthesis
> **How to use `tldr references` (Find All Usages):**
> Use this command to find every place a function, variable, or class is imported or called across the codebase.
> 1. You MUST pass a directory (e.g., `.`), not a file.
> 2. The target `<SYMBOL>` is just the name (e.g., `get_db_connection`).
> 3. It will return the `kind` of usage (e.g., `call` or `import`), which helps you trace how data flows across files.
> 4. If you expect more than 20 results, pass `--limit 100`.
> 
> **Command:** `tldr references <SYMBOL> . --limit 50`
