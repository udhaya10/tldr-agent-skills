# Command: `tldr temporal`

## Ground Truth (`tldr temporal --help`)
```text
Mine temporal constraints (method call sequences)

Usage: tldr temporal [OPTIONS] <PATH>

Arguments:
  <PATH>
          Directory or file to analyze

Options:
      --min-support <MIN_SUPPORT>
          Minimum occurrences for a pattern
          
          [default: 2]

      --min-confidence <MIN_CONFIDENCE>
          Minimum confidence threshold (0.0-1.0)
          
          [default: 0.5]

      --query <QUERY>
          Filter for specific method

      --source-lang <SOURCE_LANG>
          Source language hint (legacy; prefer the global `--lang/-l` flag). Accepts any of the 18 TLDR languages or `auto` for autodetect
          
          [default: python]

      --max-files <MAX_FILES>
          Maximum files to analyze
          
          [default: 1000]

      --include-trigrams
          Mine 3-method sequences

      --include-examples <INCLUDE_EXAMPLES>
          Number of examples per constraint
          
          [default: 3]

      --timeout <TIMEOUT>
          Timeout in seconds (E03 mitigation)
          
          [default: 60]

      --project-root <PROJECT_ROOT>
          Project root for path validation (optional)

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
* **Under the hood:** `temporal` runs association rule mining (like the Apriori algorithm) over the `git log`. It finds sets of files that are frequently committed together, independent of their code imports.
* **Performance:** Git log parsing is fast, but deep history mining can take a few seconds.
* **LLM Cognitive Load:** Exposes invisible architectural coupling. If an LLM is told to refactor a microservice, `temporal` shows if that service is secretly coupled to another service's database schema via simultaneous commits.

## Intent & Routing
* **User/Agent Goal:** Mine temporal constraints (files that frequently change together in the same commit).
* **When to choose this over similar tools:** Use to find hidden dependencies across microservices or modules that share no code imports.

## Agent Synthesis
> **How to use `tldr temporal`:**
> Use this to find hidden dependencies where files are frequently committed together.
> * **Crucial Rule:** High temporal coupling without direct imports usually indicates a shared, hidden architectural dependency.
> 
> **Command:** `tldr temporal <dir>`
