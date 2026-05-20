# Command: `tldr fix diagnose`

## Ground Truth (`tldr fix diagnose --help`)
```text
Parse error output and produce a structured diagnosis with optional fix

Usage: tldr fix diagnose [OPTIONS] --source <SOURCE>

Options:
  -s, --source <SOURCE>
          Source file to analyze (required for tree-sitter based analysis)

  -e, --error <ERROR>
          Inline error text (mutually exclusive with --error-file)

      --error-file <ERROR_FILE>
          File containing error text (mutually exclusive with --error)

      --stdin
          Read error text from stdin (when neither --error nor --error-file is given)

      --api-surface <API_SURFACE>
          Path to API surface JSON file for enhanced analysis (e.g., TS2339 property suggestions)

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
* **Command Executed:** Checked `tldr fix diagnose --help`
* **Observation:** Unlike `check` (which runs the loop automatically), `diagnose` is a manual step. You pipe the raw compiler error or traceback into it, and it returns a JSON object containing the exact file, line, parsed AST node that caused the error, and an LLM-ready explanation/fix.

## Source Code Reality
* **Observation 1:** You can pass the error text in three ways: `--error "text"`, `--error-file path.log`, or by piping it via `--stdin` (e.g., `cargo check 2>&1 | tldr fix diagnose --source src/main.rs --stdin`).
* **Observation 2:** It REQUIRES the `--source` file argument so it knows which file's AST to parse to figure out *why* the error happened.
* **Observation 3:** There is an undocumented superpower: `--api-surface`. If you run `tldr surface` first and pass the result here, it will automatically suggest the correct property name if you have a typo (like TS2339).

## Intent & Routing
* **User/Agent Goal:** Explain cryptic compiler or test errors via AST inspection.
* **When to choose this over similar tools:** Use by piping the error text (e.g., `pytest 2>&1 | tldr fix diagnose --stdin`).

## Agent Synthesis
> **How to use `tldr fix diagnose` (Error Decoder):**
> Use this when a script or compiler fails, and you need to understand exactly what AST node caused the error.
> 1. Pipe the failing command's stderr into this command using `--stdin`.
> 2. You MUST provide the `--source` file that you suspect is causing the error.
> 3. It will return a structured diagnosis explaining the error and suggesting a fix.
> 
> **Command:** `pytest tests/test_app.py 2>&1 | tldr fix diagnose --source src/app.py --stdin`
