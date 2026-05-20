# Command: `tldr diagnostics`

## Ground Truth (`tldr diagnostics --help`)
```text
Run type checking and linting

Usage: tldr diagnostics [OPTIONS] [PATH]

Arguments:
  [PATH]
          File or directory to analyze
          
          [default: .]

Options:
  -l, --lang <LANG>
          Programming language (auto-detect if not specified)

      --tools <TOOLS>
          Specific tools to run (comma-separated, e.g., "pyright,ruff")

      --no-typecheck
          Skip type checking (linters only)

      --no-lint
          Skip linting (type checkers only)

  -s, --severity <SEVERITY>
          Minimum severity to report (error, warning, info, hint)

          Possible values:
          - error:   Show only errors
          - warning: Show errors and warnings
          - info:    Show errors, warnings, and info
          - hint:    Show all diagnostics including hints
          
          [default: hint]

      --ignore <IGNORE>
          Ignore specific error codes (comma-separated)

      --output <OUTPUT>
          Additional output format (sarif, github-actions)

          Possible values:
          - sarif:          SARIF 2.1.0 format for GitHub/GitLab Code Scanning
          - github-actions: GitHub Actions workflow commands (::error::, ::warning::)

      --project
          Analyze entire project (not just specified path)

      --max-annotations <MAX_ANNOTATIONS>
          Maximum number of annotations for GitHub Actions output
          
          [default: 50]

      --timeout <TIMEOUT>
          Timeout per tool in seconds
          
          [default: 60]

      --strict
          Fail on warnings (not just errors)

      --baseline <BASELINE>
          Compare against baseline file (show only new issues)

      --save-baseline <SAVE_BASELINE>
          Save current results as baseline

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
* **Command Executed:** Checked `--help` and rust source implementation for `tldr diagnostics`.
* **Observation:** `diagnostics` is a unified wrapper around standard L1 tools like `pyright`, `ruff`, `mypy`, `eslint`, or `tsc`. It runs them in parallel and standardizes their output into a single JSON schema.

## Source Code Reality
* **Target File:** `crates/tldr-cli/src/commands/diagnostics.rs`
* **Code Evidence:** 
  ```rust
  let mut tools: Vec<ToolConfig> = if self.tools.is_empty() {
      detect_available_tools(language)
  }
  ```
* **Observation 1:** If you don't specify `--tools`, it auto-detects what is installed on the machine (e.g., if it finds `ruff` on the PATH, it uses it).
* **Observation 2:** You can filter out noisy output using `--severity error` (which hides warnings, hints, and info).
* **Observation 3:** There is a hardcoded `--timeout 60` seconds per tool. This prevents a frozen `eslint` process from hanging the entire agent loop indefinitely.

## Architectural Deep Dive
* **Under the hood:** `diagnostics` is a multiplexer. It shells out to native language tooling (`pyright` for Python, `tsc` for TypeScript, `cargo check` for Rust), captures their wildly different stdout formats, and normalizes them into a unified JSON/text structure mapped to precise AST line numbers.
* **Performance:** Bound by the execution speed of the underlying native tools.
* **LLM Cognitive Load:** Eliminates parser hallucination. An LLM struggles to parse raw `tsc` errors mixed with formatting noise. This tool strips the noise and guarantees the agent receives only real `error` severity issues mapped to exact lines.

## Intent & Routing
* **User/Agent Goal:** Run native typecheckers and linters uniformly and parse outputs.
* **When to choose this over similar tools:** Use to verify code correctness using native compilers without dealing with complex stdout parsing.

## Agent Synthesis
> **How to use `tldr diagnostics`:**
> Use this to run native typecheckers/linters and get normalized output.
> * **Crucial Rule:** Always use `--severity error` to filter out formatting noise.
> 
> **Command:** `tldr diagnostics <dir> --severity error`
