# Command: `tldr similar`

## Ground Truth (`tldr similar --help`)
```text
Find similar code fragments

Usage: tldr similar [OPTIONS] <FILE>

Arguments:
  <FILE>
          Source file to find similar code for

Options:
  -F, --function <FUNCTION>
          Specific function name (optional, searches whole file if not specified)

  -n, --top <TOP>
          Maximum number of results
          
          [default: 5]

  -t, --threshold <THRESHOLD>
          Minimum similarity threshold
          
          [default: 0.7]

  -p, --path <PATH>
          Path to search for similar code (default: current directory)
          
          [default: .]

  -m, --model <MODEL>
          Embedding model: arctic-xs, arctic-s, arctic-m, arctic-m-long, arctic-l
          
          [default: arctic-m]

      --include-self
          Include self in results (by default, the query is excluded)

      --no-cache
          Disable embedding cache

      --by-chunk
          M16 (med-cleanup-bundle-v1): emit one row per matching chunk (legacy behavior). The default — when no `--function` is given and the target is a whole file — aggregates chunk matches per destination file and ranks by total similarity, since per-chunk scoring on a 600-LOC file made the user wade through 5 unrelated 4-9 line helpers

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
* **Under the hood:** `similar` compares AST structural nodes (ignoring variable names) or uses vector embeddings to find functions that are mathematically or semantically analogous to a source target.
* **Performance:** Cross-file structural comparison is computationally heavy on large repositories.
* **LLM Cognitive Load:** Allows the LLM to quickly locate duplicated logic (copy-paste refactoring targets) or see how a specific pattern was implemented elsewhere without having to read the whole project.

## Intent & Routing
* **User/Agent Goal:** Find functions structurally/mathematically similar to a source target.
* **When to choose this over similar tools:** Use to find duplicated code or learn how a pattern is implemented elsewhere.

## Agent Synthesis
> **How to use `tldr similar`:**
> Use this to find code blocks that share structural or semantic logic with your target function.
> 
> **Command:** `tldr similar <file> --function <func_name>`
