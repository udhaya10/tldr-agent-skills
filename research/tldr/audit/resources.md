# Command: `tldr resources`

## Ground Truth (`tldr resources --help`)
```text
Analyze resource lifecycle (leaks, double-close, use-after-close)

Usage: tldr resources [OPTIONS] <FILE> [FUNCTION]

Arguments:
  <FILE>
          Source file to analyze

  [FUNCTION]
          Function to analyze (optional; analyze all if omitted)

Options:
  -l, --lang <LANG>
          Language filter (auto-detected if omitted)

      --check-leaks
          Run leak detection (R2) - enabled by default

      --check-double-close
          Run double-close detection (R3)

      --check-use-after-close
          Run use-after-close detection (R4)

      --check-all
          Run all checks (R2, R3, R4)

      --suggest-context
          Suggest context manager usage (R6)

      --show-paths
          Show detailed leak paths (R7)

      --constraints
          Generate LLM constraints (R9)

      --summary
          Output summary statistics only

      --project-root <PROJECT_ROOT>
          Project root for path validation (optional)

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
* **Under the hood:** Performs static analysis on the Control Flow Graph to trace resource allocations (`open`, `malloc`, `socket`) ensuring that all possible execution paths (including exceptions) hit a corresponding `close`/`free` node.
* **Performance:** Moderate; requires CFG traversal.
* **LLM Cognitive Load:** Prevents the LLM from introducing silent memory leaks during massive rewrites by verifying RAII or context manager coverage.

## Intent & Routing
* **User/Agent Goal:** Perform static analysis on resource acquisition and release.
* **When to choose this over similar tools:** Use during major rewrites to ensure every allocation path has a guaranteed deallocation path.

## Agent Synthesis
> **How to use `tldr resources`:**
> Use this to verify memory, file, and socket closures.
> 
> **Command:** `tldr resources <dir>`
