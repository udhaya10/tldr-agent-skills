# Command: `tldr coupling`

## Ground Truth (`tldr coupling --help`)
```text
Analyze coupling between modules/classes via cross-module call edges (afferent/efferent, instability). Measures function-call coupling, not import-level dependencies — use `tldr deps` or `tldr imports` for that (P12.AGG12-14)

Usage: tldr coupling [OPTIONS] <PATH_A> [PATH_B]

Arguments:
  <PATH_A>
          First source module (pair mode) or directory to scan (project-wide mode)

  [PATH_B]
          Second source module (pair mode). Omit for project-wide scan

Options:
      --timeout <TIMEOUT>
          Timeout in seconds (TIGER E02 mitigation)
          
          [default: 30]

      --project-root <PROJECT_ROOT>
          Project root for path validation (optional)

  -n, --max-pairs <MAX_PAIRS>
          Maximum number of pairs to show in project-wide mode (default: 20)
          
          [default: 20]

      --top <TOP>
          Limit output to top N modules ranked by instability (project-wide mode only). 0 = show all
          
          [default: 0]

      --cycles-only
          Only show modules involved in dependency cycles (project-wide mode only)

      --include-tests
          Include test files in analysis (excluded by default)

  -l, --lang <LANG>
          Language filter (auto-detected if omitted)

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
* **Under the hood:** Computes Afferent coupling (Ca - who depends on me) and Efferent coupling (Ce - who I depend on) from the global Call/Import graph. It then computes Instability: I = Ce / (Ca + Ce).
* **Performance:** Requires a global dependency graph.
* **LLM Cognitive Load:** Allows the LLM to mathematically classify a class as "Fragile" (high Ce) or "Rigid" (high Ca), directly guiding whether it needs an Interface abstraction.

## Intent & Routing
* **User/Agent Goal:** Calculate module/class coupling metrics.
* **When to choose this over similar tools:** Use to untangle tight object coupling and decide where to place interfaces.

## Agent Synthesis
> **How to use `tldr coupling`:**
> Use this to calculate Afferent, Efferent, and Instability metrics.
> * **Crucial Rule:** Highly unstable classes should be abstracted behind interfaces.
> 
> **Command:** `tldr coupling <dir>`
