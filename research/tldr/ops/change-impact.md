# Command: `tldr change-impact`

## Ground Truth (`tldr change-impact --help`)
```text
Find tests affected by code changes

Usage: tldr change-impact [OPTIONS] [PATH]

Arguments:
  [PATH]
          Project root directory (default: current directory)
          
          [default: .]

Options:
  -l, --lang <LANG>
          Programming language (auto-detect if not specified)

  -F, --files <FILES>
          Explicit list of changed files (comma-separated)

  -b, --base <BASE>
          Git base branch for diff (e.g., "origin/main" for PR workflow)

      --staged
          Only consider staged files (pre-commit workflow)

      --uncommitted
          Consider all uncommitted changes (staged + unstaged)

  -d, --depth <DEPTH>
          Maximum call graph traversal depth
          
          [default: 10]

      --include-imports
          Include import graph in analysis (not just call graph)

      --test-patterns <TEST_PATTERNS>
          Custom test file patterns (comma-separated globs)

      --runner <RUNNER>
          Output format for test runner integration

          Possible values:
          - pytest:     pytest: space-separated test files
          - pytest-k:   pytest with -k: pytest test_file.py::TestClass::test_func
          - jest:       jest --findRelatedTests format
          - go-test:    go test -run regex
          - cargo-test: cargo test filter

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
* **Command Executed:** Checked `--help` and rust source implementation.
* **Observation:** `change-impact` bridges the gap between `diff` and `impact`. It looks at what lines you changed in git, walks the call graph backwards, and finds exactly which unit tests are affected by your changes.

## Source Code Reality
* **Target File:** `crates/tldr-cli/src/commands/change_impact.rs`
* **Code Evidence:** 
  ```rust
  require_directory(&self.path, "change-impact")?;
  ```
* **Observation 1:** Just like `impact`, this command **MUST** be run on a directory (like `.`), never on a specific file. It will throw a hard error if you pass a file.
* **Observation 2:** By default, it figures out the changes itself using git. You can use `--uncommitted` to analyze your current working tree, `--staged` for pre-commit, or `-b origin/main` for PR reviews.
* **Observation 3:** The `--runner` flag is a superpower for agents. If you pass `--runner pytest`, it formats the output exactly as a bash string that the agent can execute directly (e.g., `pytest test_a.py test_b.py`).

## Intent & Routing
* **User/Agent Goal:** Find which tests are affected by uncommitted code changes.
* **When to choose this over similar tools:** Use before pushing a PR to run only the necessary tests.

## Agent Synthesis
> **How to use `tldr change-impact` (Test Selectivity):**
> Use this command after modifying code to figure out exactly which tests you need to run to verify your changes, saving time over running the entire test suite.
> 1. You MUST run this on a directory (e.g., `.`).
> 2. Pass the `--uncommitted` flag to check the files you are actively working on.
> 3. Use the `--runner` flag to format the output for your specific test framework (e.g., `pytest`, `jest`, `cargo-test`).
> 
> **Command:** `tldr change-impact . --uncommitted --runner pytest`
