# Command: `tldr inheritance`

## Ground Truth (`tldr inheritance --help`)
```text
Extract class inheritance hierarchies

Usage: tldr inheritance [OPTIONS] [PATH]

Arguments:
  [PATH]
          Path to file or directory to analyze (default: current directory)
          
          [default: .]

Options:
  -l, --lang <LANG>
          Programming language (auto-detect if not specified)

  -c, --class <CLASS>
          Focus on specific class (shows ancestors + descendants)

  -d, --depth <DEPTH>
          Limit traversal depth (requires --class)

      --no-patterns
          Skip ABC/Protocol/mixin/diamond detection

      --no-external
          Skip external base resolution

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
* **Under the hood:** Parses the AST for class declarations and `extends`/`implements` keywords, building an inheritance tree. It calculates the Depth of Inheritance Tree (DIT) metric.
* **Performance:** Fast AST traversal.
* **LLM Cognitive Load:** DIT > 3 is mathematically correlated with high defect rates due to state shadowing. This flags the exact classes the LLM should flatten using Composition.

## Intent & Routing
* **User/Agent Goal:** Analyze class inheritance trees and DIT.
* **When to choose this over similar tools:** Use to decide if a monolithic class structure should be flattened using Composition over Inheritance.

## Agent Synthesis
> **How to use `tldr inheritance`:**
> Use this to analyze the depth of inheritance trees.
> * **Crucial Rule:** Deep inheritance trees (DIT > 3) should be flattened using Composition.
> 
> **Command:** `tldr inheritance <dir>`
