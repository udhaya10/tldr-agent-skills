# Command: `tldr halstead`

## Ground Truth (`tldr halstead --help`)
```text
Calculate Halstead complexity metrics per function

Usage: tldr halstead [OPTIONS] [PATH]

Arguments:
  [PATH]
          File or directory to analyze
          
          [default: .]

Options:
      --function <FUNCTION>
          Specific function to analyze (analyzes all if not specified)

  -l, --lang <LANG>
          Programming language (auto-detect if not specified)

      --show-operators
          Show list of operators found

      --show-operands
          Show list of operands found

      --threshold-volume <THRESHOLD_VOLUME>
          Volume threshold for warnings (default: 1000)
          
          [default: 1000]

      --threshold-difficulty <THRESHOLD_DIFFICULTY>
          Difficulty threshold for warnings (default: 20)
          
          [default: 20]

      --top <TOP>
          Maximum functions to report (0 = all)
          
          [default: 0]

  -e, --exclude <EXCLUDE>
          Exclude patterns (glob syntax), can be specified multiple times

      --include-hidden
          Include hidden files (dotfiles)

      --max-files <MAX_FILES>
          Maximum files to process (0 = unlimited)
          
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
* **Observation:** Tool evaluated and integrated successfully via batch script profiling.

## Architectural Deep Dive
* **Under the hood:** Parses the AST into Operators (keywords, arithmetic, function calls) and Operands (variables, literals). Calculates Halstead Volume, Difficulty, and Effort based on the unique vs total count of each.
* **Performance:** Fast AST traversal.
* **LLM Cognitive Load:** Mathematical abstraction. The LLM is explicitly warned *not* to use this for direct refactoring, as a "Difficulty score of 50" provides no actionable steps compared to structural smells.

## Intent & Routing
* **User/Agent Goal:** Calculate Halstead complexity metrics.
* **When to choose this over similar tools:** Use ONLY for automated audits or mathematical CI metrics.

## Agent Synthesis
> **How to use `tldr halstead`:**
> Use this to get mathematical complexity metrics per function.
> * **Crucial Rule:** Do not attempt to fix code based on a Difficulty score. Use `tldr-audit/smells` instead.
> 
> **Command:** `tldr halstead <dir>`
