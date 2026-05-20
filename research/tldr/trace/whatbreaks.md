# Command: `tldr whatbreaks`

## Ground Truth (`tldr whatbreaks --help`)
```text
Analyze what breaks if a target is changed

Usage: tldr whatbreaks [OPTIONS] <TARGET> [PATH]

Arguments:
  <TARGET>
          Target to analyze (function name, file path, or module name)

  [PATH]
          Project root directory (default: current directory)
          
          [default: .]

Options:
  -t, --type <TARGET_TYPE>
          Force target type (overrides auto-detection)

          Possible values:
          - function: Function name - run impact analysis
          - file:     File path - run importers + change-impact
          - module:   Module name - run importers

  -d, --depth <DEPTH>
          Maximum depth for impact/caller traversal
          
          [default: 3]

      --quick
          Skip slow analyses (diff-impact)

  -l, --lang <LANG>
          Programming language (auto-detect if not specified)

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
* **Command Executed:** Checked `tldr whatbreaks --help` and source file.
* **Observation:** `whatbreaks` is a macro-command. It is essentially an orchestrator that automatically decides whether to run `impact` (if you pass a function), `importers` (if you pass a module), or `change-impact` (if you pass a file). 

## Source Code Reality
* **Target File:** `crates/tldr-cli/src/commands/whatbreaks.rs`
* **Code Evidence:** 
  ```rust
  require_directory(&self.path, "whatbreaks")?;
  ```
* **Observation 1:** Like `impact`, it **MUST** be run on a directory (`.`), never a file.
* **Observation 2:** By default, it auto-detects if your `<TARGET>` argument is a file path, a module name, or a function name. However, if the name is ambiguous (e.g., a function named exactly the same as a file without an extension), it will guess.
* **Observation 3:** You can explicitly force the type using `--type function`, `--type file`, or `--type module`. 

## Intent & Routing
* **User/Agent Goal:** Identify everything that will break if a target is changed.
* **When to choose this over similar tools:** Smart router that combines impact, importers, and change-impact. Always force `--type`.

## Agent Synthesis
> **How to use `tldr whatbreaks` (Blast Radius Orchestrator):**
> Use this command when you are about to delete or heavily modify a target and need to know everything that will break.
> 1. You MUST run this on a directory (e.g., `.`).
> 2. It accepts any target (a function name, a file path, or a module).
> 3. Always force the type via the `--type` flag (e.g., `--type function`) so it doesn't auto-detect incorrectly on ambiguous names.
> 
> **Command:** `tldr whatbreaks <TARGET> . --type function`
