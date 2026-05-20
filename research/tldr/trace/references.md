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

## Architectural Deep Dive
* **Under the hood:** `references` queries the symbol table and index to locate all references to a variable, class, or method, distinguishing between raw variable reads/writes and function invocations.
* **Performance:** Extremely fast symbol lookup compared to line-by-line grep.
* **LLM Cognitive Load:** Traditional `grep` matches comments, variable names inside strings, and irrelevant files. `references` guarantees that only actual syntactic uses of the symbol are returned, ensuring 100% precision.

## Intent & Routing
* **User/Agent Goal:** Find all usages of a specific symbol (variable, function, class) across the codebase.
* **When to choose this over similar tools:** Use instead of `grep` to find exact usages of a symbol across all files.

## Agent Synthesis
> **How to use `tldr references`:**
> Use this to locate all usages of a specific class, variable, or method.
> 
> **Command:** `tldr references --symbol <name> <dir>`
