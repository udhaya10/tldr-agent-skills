# Command: `tldr secure`

## Ground Truth (`tldr secure --help`)
```text
Security analysis dashboard (taint, resources, bounds, contracts, behavioral, mutability)

Usage: tldr secure [OPTIONS] <PATH>

Arguments:
  <PATH>
          File path or directory to analyze

Options:
  -l, --lang <LANG>
          Programming language to filter by (auto-detected if omitted)

      --detail <DETAIL>
          Show details for specific sub-analysis

      --quick
          Run quick mode (taint, resources, bounds only)

  -o, --output <OUTPUT>
          Write output to file instead of stdout

      --no-default-ignore
          Walk vendored/build dirs (node_modules, target, dist, etc.) that would normally be skipped

      --include-tests
          Include findings on test files. Mirrors `tldr vuln --include-tests` (M-X3 `js-test-file-suppression-v1`). Default: `false` — findings emitted from JS/TS test files (paths under `test/`, `tests/`, `__tests__/`, or filenames ending in `.test.{js,ts,jsx,tsx}`, `.spec.{js,ts,jsx,tsx}`, or `.e2e.{js,ts}`) and Rust test files (paths under `/tests/` or filenames ending in `_test.rs` / `tests.rs`) are suppressed because they exercise sink behavior on synthetic inputs and pollute production-codebase scans. Pass `--include-tests` to restore them. Mirrors the `--include-smells` precedent (opt-in for noisy categories)

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
* **Command Executed:** Checked `tldr secure --help` and tested on `Stock-Monitor`.
* **Raw Output:** Returns a top-level `summary` block counting taints, leaks, missing contracts, unsafe blocks, and unwrap calls.
* **Observation:** `secure` is to `vuln` what `health` is to `complexity`. It is a dashboard that aggregates multiple security engines (Taint Analysis, Resource Leaks, Bounds Checking, Contracts).

## Source Code Reality
* **Target File:** `crates/tldr-cli/src/commands/remaining/secure.rs`
* **Observation 1:** Passing `--quick` restricts it to only run `taint`, `resources`, and `bounds`, skipping the behavioral and mutability checks.
* **Observation 2:** Like `health`, you can drill down into a specific analysis using the `--detail` flag.

## Architectural Deep Dive
* **Under the hood:** `secure` is an aggregated security dashboard that checks for misconfigurations, hardcoded secrets (via regex/entropy), missing bounds checks, and unsafe function usage (e.g., `eval()`, `strcpy()`), alongside basic taint flows.
* **Performance:** The `--quick` flag disables deep taint tracking, acting like a fast linter.
* **LLM Cognitive Load:** Provides a broad overview of basic security hygiene across the project without getting bogged down in complex cross-file data flows.

## Intent & Routing
* **User/Agent Goal:** Get an aggregated security dashboard.
* **When to choose this over similar tools:** Use `--quick` on large repos to get a fast security check, but use `vuln` if you need detailed taint traces.

## Agent Synthesis
> **How to use `tldr secure`:**
> Use this for a broad security hygiene overview.
> * **Crucial Rule:** Use `--quick` on large repos to skip expensive deeper flow checks.
> 
> **Command:** `tldr secure <dir> --quick`
