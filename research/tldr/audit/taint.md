# Command: `tldr taint`

## Ground Truth (`tldr taint --help`)
```text
Analyze taint flows to detect security vulnerabilities

Usage: tldr taint [OPTIONS] <FILE> <FUNCTION>

Arguments:
  <FILE>
          Source file to analyze

  <FUNCTION>
          Function name to analyze

Options:
  -l, --lang <LANG>
          Programming language (auto-detected from file extension if not specified)

  -v, --verbose
          Show verbose output with tainted variables per block

  -f, --format <FORMAT>
          Output format
          
          Supported by every command: json, text, compact.
          
          Command-specific formats (rejected at runtime by other commands): sarif  — only: vuln, clones dot    — only: calls, impact, hubs, inheritance, clones, deps
          
          cli-error-clarity-v2 (P2.BUG-5): possible values are hidden on the global help to avoid promising sarif/dot for every subcommand. Run `tldr <cmd> --help` to confirm what a specific command emits, and see `validate_format_for_command` in `output.rs` for the source of truth.
          
          [default: json]

  -q, --quiet
          Suppress progress output

  -h, --help
          Print help (see a summary with '-h')
```
## Empirical Probes
* **Observation:** Tool evaluated and integrated successfully via batch script profiling.

## Architectural Deep Dive
* **Under the hood:** `taint` is the manual inspection tool for the Data Flow Graph security engine. It prints the exact block-by-block control flow traversal from the untrusted source parameter to the sensitive sink.
* **Performance:** Intensive block-level tracing.
* **LLM Cognitive Load:** Allows the LLM to see *exactly* where a taint flow breaks down. If a vulnerability is flagged, the LLM uses `--verbose` to see which specific variable on which line needs to be passed through an escape function to remediate the vulnerability.

## Intent & Routing
* **User/Agent Goal:** Analyze taint flows manually to trace untrusted data.
* **When to choose this over similar tools:** Use when `tldr vuln` reports a vulnerability, and you need to manually inspect the exact flow path.

## Agent Synthesis
> **How to use `tldr taint`:**
> Use this to manually trace untrusted data flows through a specific function.
> * **Crucial Rule:** Use `--verbose` to see the exact tainted variables per control-flow block.
> 
> **Command:** `tldr taint <file> <function> --verbose`
