# Command: `tldr todo`

## Ground Truth (`tldr todo --help`)
```text
Aggregate improvement suggestions (dead code, complexity, cohesion, similar)

Usage: tldr todo [OPTIONS] <PATH>

Arguments:
  <PATH>
          File or directory to analyze

Options:
      --detail <DETAIL>
          Show details for specific sub-analysis

      --quick
          Run quick mode (skip similar analysis)

      --max-items <MAX_ITEMS>
          Maximum number of items to display (0 = show all)
          
          [default: 20]

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
* **Command Executed:** Checked `tldr todo --help`.
* **Observation:** `tldr todo` behaves similarly to `tldr health`, but instead of a dashboard of metrics, it generates an actionable list of functions and files that need to be refactored, ranked by severity.

## Source Code Reality
* **Target File:** `crates/tldr-cli/src/commands/remaining/todo.rs`
* **Observation 1:** Unlike `health` (which defaults to `.`), `todo` requires the `<PATH>` argument explicitly. 
* **Observation 2:** The `--max-items` flag defaults to 20, which is perfectly safe for LLM context windows.
* **Observation 3:** Similar to `health`, the `--quick` flag skips the cross-file similarity analysis, significantly speeding up the command.

## Intent & Routing
* **User/Agent Goal:** Generate an actionable refactoring backlog.
* **When to choose this over similar tools:** Use `--quick` to get the top 20 functions that need cleanup without running slow clone detection.

## Agent Synthesis
> **How to use `tldr todo` (Refactoring List):**
> Use this command to get an actionable, prioritized list of the top 20 functions/files that need refactoring in the project (due to dead code, complexity, or low cohesion).
> 1. Provide the `<PATH>` argument (e.g., `.`).
> 2. Append `--quick` to skip slow cross-file similarity checks.
> 
> **Command:** `tldr todo . --quick`
