# Command: `tldr clones`

## Ground Truth (`tldr clones --help`)
```text
Detect code clones in a codebase

Usage: tldr clones [OPTIONS] [PATH]

Arguments:
  [PATH]
          Path to analyze (default: current directory)
          
          [default: .]

Options:
      --min-tokens <MIN_TOKENS>
          Minimum tokens for a clone (default: 25)
          
          [default: 25]

      --min-lines <MIN_LINES>
          Minimum lines for a clone (default: 5)
          
          [default: 5]

  -t, --threshold <THRESHOLD>
          Similarity threshold (0.0-1.0, default: 0.7)
          
          [default: 0.7]

      --type-filter <TYPE_FILTER>
          Filter by clone type: 1, 2, 3, or all (default: all)
          
          [default: all]

      --normalize <NORMALIZE>
          Normalization mode: none, identifiers, literals, all (default: all)
          
          [default: all]

      --language <LANGUAGE>
          Filter by language: python, typescript, go, rust

  -o, --output <OUTPUT>
          Output format: json, text, sarif (default: json) Use sarif for IDE/CI integration (GitHub, VS Code, etc.)
          
          [default: json]

      --show-classes
          Show clone classes (transitive grouping)

      --include-within-file
          Include clones within the same file

      --max-clones <MAX_CLONES>
          Maximum clones to report (default: 20)
          
          [default: 20]

      --max-files <MAX_FILES>
          Maximum files to analyze (default: 1000)
          
          [default: 1000]

      --exclude-generated
          Exclude generated files (e.g., *.pb.go, *_generated.ts, vendor/, etc.)

      --exclude-tests
          Exclude test files (e.g., test_*.py, *_test.go, *_spec.rb, tests/, __tests__/)

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
* **Command Executed:** Checked `tldr clones --help` and source file.
* **Observation:** Detects duplicate code using an AST-based engine.

## Source Code Reality
* **Observation 1:** Supports `--format sarif` for GitHub Code Scanning integration.
* **Observation 2:** Supports `--normalize identifiers` which ignores differences in variable names when detecting clones.
* **Observation 3:** By default ignores clones within the same file. Must use `--include-within-file` to detect those.

## Architectural Deep Dive
* **Under the hood:** `clones` parses files into ASTs, normalizes variable/function names (removing textual identifiers), hashes the structural node sequences, and detects Type-1 (exact match) and Type-2/Type-3 (structural match with different variables/types) code clones.
* **Performance:** AST hashing and cross-comparison is O(N^2) on the number of functions.
* **LLM Cognitive Load:** Finds copy-pasted code even if the developer changed all the variable names. This gives the LLM the exact targets to abstract into a shared utility function.

## Intent & Routing
* **User/Agent Goal:** Detect duplicated logic (AST structural clones).
* **When to choose this over similar tools:** Use to find DRY violations where code was copy-pasted and modified slightly.

## Agent Synthesis
> **How to use `tldr clones`:**
> Use this to detect copy-pasted structural logic, even if variable names were changed.
> 
> **Command:** `tldr clones <dir>`
