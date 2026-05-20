# Command: `tldr patterns`

## Ground Truth (`tldr patterns --help`)
```text
Detect design patterns and coding conventions

Usage: tldr patterns [OPTIONS] [PATH]

Arguments:
  [PATH]
          Path to file or directory to analyze (default: current directory)
          
          [default: .]

Options:
  -l, --lang <LANG>
          Programming language (auto-detect if not specified)

  -c, --category <CATEGORY>
          Filter to specific pattern category

      --min-confidence <MIN_CONFIDENCE>
          Minimum confidence threshold (0.0-1.0)
          
          [default: 0.5]

      --max-files <MAX_FILES>
          Maximum files to analyze (0 = unlimited)
          
          [default: 1000]

      --no-constraints
          Skip LLM constraint generation

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
* **Under the hood:** `patterns` runs a graph-matching algorithm against the AST/CFG to detect the structural fingerprints of Gang of Four (GoF) design patterns (e.g., a private constructor + static instance variable = Singleton).
* **Performance:** Complex graph-matching.
* **LLM Cognitive Load:** Rapidly maps the architectural intent of legacy code. If it detects an Observer pattern, the LLM immediately understands the event-driven nature of the file without reading it.

## Intent & Routing
* **User/Agent Goal:** Detect Gang of Four design patterns via structural AST matching.
* **When to choose this over similar tools:** Use to rapidly document legacy code architecture.

## Agent Synthesis
> **How to use `tldr patterns`:**
> Use this to detect implemented design patterns (Singleton, Factory, Observer).
> 
> **Command:** `tldr patterns <dir>`
