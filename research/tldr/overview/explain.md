# Command: `tldr explain`

## Ground Truth (`tldr explain --help`)
```text
Comprehensive function analysis (signature, purity, complexity, callers, callees)

Usage: tldr explain [OPTIONS] <FILE> <FUNCTION>

Arguments:
  <FILE>
          Source file to analyze

  <FUNCTION>
          Function name to explain

Options:
      --depth <DEPTH>
          Call graph depth for callers/callees
          
          [default: 2]

  -o, --output <OUTPUT>
          Output file (stdout if not specified)

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
* **Command Executed:** `tldr explain backend/db.py get_db_connection`
* **Raw Output:** Returns a JSON object containing the function's signature, purity (e.g., `impure` with `io` effects), complexity (cyclomatic), and an array of callers and callees.
* **Observation:** This command is the ultimate all-in-one "Function Profile". It grabs the exact line numbers (like `extract`), calculates purity and complexity (like `cognitive`), and finds reverse and forward dependencies (like `impact` and `calls`) all in a single fast command.

## Source Code Reality
* **Target File:** `crates/tldr-cli/src/commands/remaining/explain.rs`
* **Code Evidence:** 
  ```rust
  if !self.file.exists() {
      return Err(RemainingError::file_not_found(&self.file).into());
  }
  ```
* **Observation 1:** Unlike `impact`, which requires a directory, `explain` **MUST** be given an exact file path and function name. 
* **Observation 2:** The caller/callee depth defaults to 2. This is usually enough for immediate context without hallucinating massive dependency trees.

## Intent & Routing
* **User/Agent Goal:** Generate a natural language summary of what a function or file does.
* **When to choose this over similar tools:** Use when exploring unfamiliar code quickly.

## Agent Synthesis
> **How to use `tldr explain` (Complete Function Profile):**
> Use this command when you want everything about a single function in one shot: its signature, what files call it, what external functions it calls, its cyclomatic complexity, and whether it has side effects (purity).
> 1. You MUST provide the exact file path and the exact function name.
> 2. This is significantly faster and more token-efficient than running `extract`, `impact`, and `complexity` separately.
> 
> **Command:** `tldr explain <FILE> <FUNCTION>`
