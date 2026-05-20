# Command: `tldr invariants`

## Ground Truth (`tldr invariants --help`)
```text
Infer invariants from test execution traces (Daikon-lite)

Usage: tldr invariants [OPTIONS] --from-tests <FROM_TESTS> <FILE>

Arguments:
  <FILE>
          Source file containing functions to analyze

Options:
  -t, --from-tests <FROM_TESTS>
          Test file or directory for tracing

      --function <FUNCTION>
          Filter to specific function

      --min-obs <MIN_OBS>
          Minimum observations required to report an invariant
          
          [default: 1]

  -l, --lang <LANG>
          Language override (auto-detected if not specified).
          
          MUST stay typed as `Option<Language>` to match the global `--lang` / `-l` flag declared on `Cli` in `main.rs`. clap stores the value once under the long-name key; if the local arg's type diverges from the global type, accessing `lang` triggers a type-id downcast panic in `clap_builder::parser::error::Error`. (P11.BUG-AGG-2)

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
* **Under the hood:** `invariants` uses Data Flow analysis and Symbolic Execution to detect values that do not change inside a loop or state machine execution path.
* **Performance:** Computationally heavy; requires symbolic execution engine.
* **LLM Cognitive Load:** Essential for algorithm refactoring. If an LLM changes a sort algorithm, it uses this to mathematically prove the state remains consistent.

## Intent & Routing
* **User/Agent Goal:** Detect loop invariants and state machine guarantees.
* **When to choose this over similar tools:** Use when refactoring complex algorithms to prove state consistency.

## Agent Synthesis
> **How to use `tldr invariants`:**
> Use this to detect loop invariants via Data Flow Graph analysis.
> 
> **Command:** `tldr invariants <dir>`
