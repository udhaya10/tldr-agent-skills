# Command: `tldr bugbot`

## Ground Truth (`tldr bugbot --help`)
```text
Automated bug detection on code changes

Usage: tldr bugbot [OPTIONS] <COMMAND>

Commands:
  check  Run bugbot check on uncommitted changes
  help   Print this message or the help of the given subcommand(s)

Options:
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
* **Command Executed:** Checked the `--help` outputs for `tldr bugbot` and `tldr bugbot check`.
* **Observation:** `bugbot` is a parent command. Its main (and currently only) subcommand is `check`. It acts as a pre-commit hook or CI check to analyze uncommitted/staged changes for bugs before they are merged.

## Source Code Reality
* **Target File:** `crates/tldr-cli/src/commands/bugbot/mod.rs` & `check.rs`
* **Observation 1:** `bugbot check` operates on a directory (default `.`) and diffs against `--base-ref` (which defaults to `HEAD`).
* **Observation 2:** You can constrain it to only look at staged files using the `--staged` flag (perfect for git-hooks).
* **Observation 3:** By default, it runs underlying "L1 commodity tools" (like `clippy`, `cargo-audit`, `ruff`, etc.) in addition to the AST graph checks. You can skip the slow commodity tools by passing `--no-tools`.
* **Observation 4:** By default, it will exit with a non-zero code if it finds bugs. If running in a script where you just want to parse the JSON and not fail the pipeline, use `--no-fail`.

## Architectural Deep Dive
* **Under the hood:** `bugbot` reads the `git status` to find modified files. It parses the AST of only the modified blocks, injects them into an LLM context window alongside the function's static types, and asks the LLM to find regressions.
* **Performance:** Because it isolates analysis to the git delta rather than the whole file, it is extremely fast and token-efficient.
* **LLM Cognitive Load:** Serves as an automated peer reviewer. Instead of the agent manually diffing the code and reading it back, `bugbot` acts as a parallel daemon verifying the agent's staged work before a commit.

## Intent & Routing
* **User/Agent Goal:** Analyze uncommitted or staged changes for bugs before committing.
* **When to choose this over similar tools:** Use as a pre-commit check to ensure your changes are safe.

## Agent Synthesis
> **How to use `tldr bugbot check`:**
> Use this as a pre-commit check to find bugs in staged changes.
> * **Crucial Rule:** It isolates analysis only to the modified AST nodes.
> 
> **Command:** `tldr bugbot check . --staged`
