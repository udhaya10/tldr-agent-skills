# Command: `tldr dice`

## Ground Truth (`tldr dice --help`)
```text
Compare similarity between two code fragments

Usage: tldr dice [OPTIONS] <TARGET1> <TARGET2>

Arguments:
  <TARGET1>
          First target: file, file::function, or file:start:end

  <TARGET2>
          Second target: file, file::function, or file:start:end

Options:
      --normalize <NORMALIZE>
          Normalization mode: none, identifiers, literals, all (default: all)
          
          [default: all]

      --language <LANGUAGE>
          Language hint (auto-detected if not specified)

  -o, --output <OUTPUT>
          Output format: json, text (default: json)
          
          [default: json]

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
* **Under the hood:** `dice` computes the Sørensen–Dice coefficient between two specific AST nodes (functions). It tokenizes the functions into n-grams and calculates the exact mathematical overlap percentage.
* **Performance:** Instantaneous O(1) comparison since it only targets two predefined functions.
* **LLM Cognitive Load:** When an agent is asked to DRY up (merge) two messy legacy functions, it can use this to mathematically verify how much actual structural overlap exists before attempting a risky merge operation.

## Intent & Routing
* **User/Agent Goal:** Compare the exact structural overlap (Dice coefficient) between two specific functions.
* **When to choose this over similar tools:** Use to verify if two functions are safe to merge during refactoring.

## Agent Synthesis
> **How to use `tldr dice`:**
> Use this to mathematically compare how similar two specific functions are.
> * **Crucial Rule:** Useful to verify if two messy legacy functions are safe to merge.
> 
> **Command:** `tldr dice <file1:func1> <file2:func2>`
