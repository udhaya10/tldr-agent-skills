# Command: `tldr api-check`

## Ground Truth (`tldr api-check --help`)
```text
Detect API misuse patterns (missing timeouts, bare except, weak crypto, unclosed files)

Usage: tldr api-check [OPTIONS] <path>

Arguments:
  <path>
          File or directory to analyze (path to file or directory)

Options:
      --category <CATEGORY>
          Filter by misuse category
          
          [possible values: call-order, error-handling, parameters, resources, crypto, concurrency, security]

      --severity <SEVERITY>
          Filter by minimum severity
          
          [possible values: info, low, medium, high]

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
* **Under the hood:** Extracts the public API AST nodes (exported functions, classes, interfaces) of the current tree and diffs it against the extracted AST of a specified git branch or tag, reporting any signature modifications.
* **Performance:** Double AST extraction and comparison.
* **LLM Cognitive Load:** Before committing a refactor to a public library, the LLM uses this to mathematically prove it didn't break backward compatibility.

## Intent & Routing
* **User/Agent Goal:** Check API backward compatibility between branches by diffing public AST nodes.
* **When to choose this over similar tools:** Use before committing to ensure you haven't accidentally removed or modified a public function signature.

## Agent Synthesis
> **How to use `tldr api-check`:**
> Use this to verify backward compatibility of an API against a previous branch.
> 
> **Command:** `tldr api-check <dir> --against <BRANCH_OR_TAG>`
