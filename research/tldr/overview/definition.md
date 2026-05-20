# Command: `tldr definition`

## Ground Truth (`tldr definition --help`)
```text
Go-to-definition - find where a symbol is defined

Usage: tldr definition [OPTIONS] [FILE] [LINE] [COLUMN]

Arguments:
  [FILE]
          Source file (positional, for position-based lookup)

  [LINE]
          line number (1-indexed, for position-based lookup)

  [COLUMN]
          column number (0-indexed, for position-based lookup)

Options:
      --symbol <SYMBOL>
          Find symbol by name instead of position

      --file <target_file>
          File to search in (used with --symbol)

      --project <PROJECT>
          Project root for cross-file resolution

      --workspace <WORKSPACE>
          Enable workspace-wide cross-file resolution.
          
          When enabled (default), if `--project` is not provided the project root is auto-detected from the source file by walking up looking for repository / package markers (`.git`, `Cargo.toml`, `pyproject.toml`, `package.json`, `go.mod`, `pom.xml`, `build.gradle`). Set to `false` (`--workspace=false`) to disable auto-detection and keep resolution strictly within the source file unless an explicit `--project` is provided.
          
          `definition-workspace-cross-file-v1`.
          
          [default: true]
          [possible values: true, false]

  -O, --output <OUTPUT>
          Output file (optional, stdout if not specified)

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
* **Under the hood:** Acts as a lightweight LSP (Language Server Protocol). It uses the AST to index symbol declarations (classes, structs, functions, globals) and resolves a query string to its exact file and byte range.
* **Performance:** AST indexing is highly optimized compared to regex search.
* **LLM Cognitive Load:** Replaces brute-force `grep`. `grep "class User"` might return 50 usages and the definition; `definition` returns *only* the definition, saving the agent from sifting through noise.

## Intent & Routing
* **User/Agent Goal:** Find the absolute file and line number where a symbol is defined.
* **When to choose this over similar tools:** Use instead of `grep` or `search` to accurately locate struct/class/function definitions, ignoring references/calls.

## Agent Synthesis
> **How to use `tldr definition`:**
> Use this to jump straight to the file and line where a symbol (function, class, variable) is defined.
> 
> **Command:** `tldr definition --symbol <name>`
