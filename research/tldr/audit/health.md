# Command: `tldr health`

## Ground Truth (`tldr health --help`)
```text
Comprehensive code health dashboard

Usage: tldr health [OPTIONS] [PATH]

Arguments:
  [PATH]
          Path to analyze (file or directory)
          
          [default: .]

Options:
      --detail <DETAIL>
          Show detailed sub-analyzer output
          
          Valid values: complexity, cohesion, dead_code, martin, coupling, similarity, all

      --quick
          Quick mode (skip coupling and similarity - faster)

      --preset <PRESET>
          Threshold preset (strict, default, relaxed)

          Possible values:
          - strict:  Strict thresholds for high-quality codebases
          - default: Default thresholds (recommended)
          - relaxed: Relaxed thresholds for legacy code
          
          [default: default]

      --max-items <MAX_ITEMS>
          Maximum items to return for coupling and similarity analyses (default: 50)
          
          [default: 50]

      --summary
          Summary mode - omit detail arrays, only include summary metrics

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
* **Command Executed:** `tldr health . --quick --summary`
* **Raw Output:** Returns a top-level JSON object summarizing the codebase's health (`files_analyzed`, `avg_cyclomatic`, `hotspot_count`, `low_cohesion_count`, `dead_percentage`, etc.) without dumping the massive detail arrays.
* **Observation:** The `health` command is an aggregator. It runs `complexity`, `cohesion`, `dead`, and optionally `coupling` and `similar` under the hood. Using `--quick` forces it to skip the slow L2 cross-file checks (coupling/similar), making it significantly faster for a baseline check.

## Source Code Reality
* **Target File:** `crates/tldr-cli/src/commands/health.rs`
* **Code Evidence:** 
  ```rust
  if !self.path.exists() {
      anyhow::bail!("Path not found: {}", self.path.display());
  }
  ```
* **Observation 1:** `health` operates on a path (default `.`).
* **Observation 2:** The `--detail` flag allows you to selectively drill down into one specific sub-analyzer if you see a red flag in the summary.
* **Observation 3:** Empty directories handle gracefully, returning a stub report instead of crashing.

## Architectural Deep Dive
* **Under the hood:** `health` is an aggregator. It spawns the Complexity, Cohesion, and Smells engines concurrently and merges their findings into a single, weighted score for each file, producing a high-level dashboard.
* **Performance:** Spawns multiple engines, so it takes some time on large repos.
* **LLM Cognitive Load:** Gives the LLM an immediate prioritization list. Instead of guessing which file to refactor or reading through 50 files, the LLM runs this and gets the top 5 most problematic files sorted by objective mathematical debt.

## Intent & Routing
* **User/Agent Goal:** Get a high-level codebase health dashboard (hotspots, complexity, smells).
* **When to choose this over similar tools:** Run this first during an audit to find which files need deeper inspection before running specific metric tools.

## Agent Synthesis
> **How to use `tldr health`:**
> Use this command to get a high-level dashboard of the most problematic files in the repository.
> 
> **Command:** `tldr health <dir>`
