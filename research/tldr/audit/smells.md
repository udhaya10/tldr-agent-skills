# Command: `tldr smells`

## Ground Truth (`tldr smells --help`)
```text
Detect code smells

Usage: tldr smells [OPTIONS] [PATH]

Arguments:
  [PATH]
          Path to analyze (file or directory)
          
          [default: .]

Options:
  -l, --lang <LANG>
          Programming language to filter by (auto-detected if omitted)

  -t, --threshold <THRESHOLD>
          Threshold preset

          Possible values:
          - strict:  Strict thresholds for high-quality codebases
          - default: Default thresholds (recommended)
          - relaxed: Relaxed thresholds for legacy code
          
          [default: default]

  -s, --smell-type <SMELL_TYPE>
          Filter by smell type

          Possible values:
          - god-class:                 God Class (>20 methods or >500 LOC)
          - long-method:               Long Method (>50 LOC or cyclomatic >10)
          - long-parameter-list:       Long Parameter List (>5 parameters)
          - feature-envy:              Feature Envy
          - data-clumps:               Data Clumps
          - low-cohesion:              Low Cohesion (LCOM4 >= 2) -- requires --deep
          - tight-coupling:            Tight Coupling (score >= 0.6) -- requires --deep
          - dead-code:                 Dead Code (unreachable functions) -- requires --deep
          - code-clone:                Code Clone (similar functions) -- requires --deep
          - high-cognitive-complexity: High Cognitive Complexity (>= 15) -- requires --deep
          - deep-nesting:              Deep Nesting (nesting depth >= 5)
          - data-class:                Data Class (many fields, few/no methods)
          - lazy-element:              Lazy Element (class with only 1 method and 0-1 fields)
          - message-chain:             Message Chain (long method call chains > 3)
          - primitive-obsession:       Primitive Obsession (many primitive-typed parameters)
          - middle-man:                Middle Man (>60% delegation) -- requires --deep
          - refused-bequest:           Refused Bequest (<33% inherited usage) -- requires --deep
          - inappropriate-intimacy:    Inappropriate Intimacy (bidirectional coupling) -- requires --deep

      --suggest
          Include suggestions for fixing

      --deep
          Deep analysis: aggregate findings from cohesion, coupling, dead code, similarity, and cognitive complexity analyzers in addition to the standard smell detectors

      --no-default-ignore
          Walk vendored/build dirs (node_modules, target, dist, etc.) that would normally be skipped

      --files <FILES>
          Limit the scan to specific files (repeatable; EXACT-PATH-ONLY, no glob expansion). Each entry is validated via `validate_file_path` (rejects path traversal / non-existent files). When set, the path argument becomes a project-root anchor for output ordering only and the walker is bypassed. Implies `--include-tests` (caller picked the list)

      --include-tests
          Include findings from test files. Default: test-file findings are excluded (PR-review default). Implicit `true` when `--files` is non-empty

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
* **Command Executed:** `tldr smells backend/db.py --deep --suggest`
* **Raw Output:** Returns a JSON object with an array of `smells` containing the `smell_type`, file, line number, reason, severity, and actionable `suggestion`.
* **Observation:** The `--deep` flag is required to run advanced detectors (like Code Clone, Tight Coupling, and Dead Code). Without it, it only runs basic AST size metrics (like God Class or Long Method).

## Source Code Reality
* **Target File:** `crates/tldr-cli/src/commands/smells.rs`
* **Code Evidence:** 
  ```rust
  let include_tests = self.include_tests || !self.files.is_empty();
  ```
* **Observation 1:** Smells in test files are skipped by default. However, if you explicitly pass a test file via `--files`, it automatically enables `include_tests=true`.
* **Observation 2:** The `--files` flag requires exact paths, no globs.

## Intent & Routing
* **User/Agent Goal:** Detect code smells like god classes, long parameter lists, and nested logic.
* **When to choose this over similar tools:** MUST use `--deep` to enable the most critical architectural smell detectors.

## Agent Synthesis
> **How to use `tldr smells` (Code Quality Audit):**
> Use this to identify technical debt, code clones, tight coupling, and structural issues in a file or project.
> 1. Always use the `--deep` flag. Without it, you will miss the most important architectural smells (like coupling and clones).
> 2. Always use the `--suggest` flag to get LLM-ready remediation advice.
> 3. If scanning a specific file, pass it directly as the `[PATH]` argument.
> 
> **Command:** `tldr smells <FILE_OR_DIR> --deep --suggest`
