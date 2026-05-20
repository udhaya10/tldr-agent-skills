# Command: `tldr fix check`

## Ground Truth (`tldr fix check --help`)
```text
Run test command, diagnose failures, apply fixes, and re-run in a loop

Usage: tldr fix check [OPTIONS] --file <FILE> --test-cmd <TEST_CMD>

Options:
  -f, --file <FILE>
          Source file to fix

  -t, --test-cmd <TEST_CMD>
          Test command to run (e.g., "pytest tests/test_app.py")

      --max-attempts <MAX_ATTEMPTS>
          Maximum number of fix attempts (default: 5)
          
          [default: 5]

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
* **Command Executed:** Checked `tldr fix check --help` and rust source logic.
* **Observation:** `tldr fix check` is an autonomous loop. It runs a test command, parses the error output (like tracebacks or compiler errors), generates an AST-aware fix, applies it to the file, and runs the test command again until it passes or hits `--max-attempts`.

## Source Code Reality
* **Target File:** `crates/tldr-cli/src/commands/fix.rs` & `crates/tldr-core/src/fix/check.rs`
* **Code Evidence:** 
  ```rust
  let (success, error_output) = run_command(config.test_cmd);
  if success { final_pass = true; break; }
  ```
* **Observation 1:** The `--test-cmd` flag accepts a full string (e.g., `"pytest tests/test_app.py"`). The CLI actually executes this string in the shell.
* **Observation 2:** The `--file` flag restricts the autonomous agent to only applying fixes to a single source file, preventing it from wildly modifying the whole project.
* **Observation 3:** By default, it will loop 5 times (`--max-attempts 5`) before giving up.

## Intent & Routing
* **User/Agent Goal:** Automatically repair failing tests by looping edit-compile-test.
* **When to choose this over similar tools:** Use to autonomously fix bugs. MUST pass the exact test command via `--test-cmd`.

## Agent Synthesis
> **How to use `tldr fix check` (Autonomous Repair):**
> Use this command to autonomously fix a failing test or compiler error in a specific file.
> 1. You MUST provide the specific source file you want it to modify via `--file`.
> 2. You MUST provide the exact bash command that reproduces the error via `--test-cmd`.
> 3. The CLI will execute the test, read the stderr, write the code fix, and re-run the test in a loop up to 5 times until it passes.
> 
> **Command:** `tldr fix check --file src/app.py --test-cmd "pytest tests/test_app.py"`
