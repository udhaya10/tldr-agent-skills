# Research Journal 01: CLI Ground-Truth Discovery

## Purpose
The purpose of this research phase is to establish the **absolute ground truth** of the `tldr` command-line interface. 

While the official repository documentation (e.g., `docs/commands/*.md`) is useful for understanding intent, documentation inevitably drifts from implementation. Since we are building autonomous agent skills, giving an LLM incorrect flags or hallucinated commands will cause fatal execution errors. We must verify the exact surface area of the binary (`v0.4.0`) by interrogating the CLI itself.

## Process
Our process follows a "Trust but Verify" methodology:
1. **Identify the Binary:** Ensure we are running the correct version of the `tldr` CLI.
2. **Extract Top-Level Commands:** Run the global `--help` command to dump the authoritative list of available subcommands and global flags.
3. **Compare vs. Documentation:** Cross-reference the CLI output against our initial theoretical list to spot any hidden commands, missing features, or alias discrepancies.

## Execution Log

### Step 1: Version Verification
**Command Ran:** `tldr --version`  
**Why:** To ensure our research is pinned to a specific release and isn't polluted by local dev builds.  
**Output:**
```text
tldr 0.4.0
```

### Step 2: Global Help Extraction
**Command Ran:** `tldr --help`  
**Why:** This queries the `clap` (Rust CLI parser) implementation directly, bypassing human-written markdown. It provides the exact taxonomy, aliases, and global options accepted by the binary.

**Key Findings:**
1. **Global Options:** 
   The CLI accepts 5 global options that govern format, language, and verbosity. Importantly, the default format is `json`, which is perfect for LLM consumption.
   ```text
   -f, --format <FORMAT>  [default: json] (json, text, compact, sarif, dot)
   -l, --lang <LANG>      Auto-detects if not specified
   -q, --quiet
   -v, --verbose
   ```
2. **Total Command Count:** The CLI exposes exactly **63 top-level subcommands**.
3. **Aliases:** Almost every command has a short alias (e.g., `t` for `tree`, `wb` for `whatbreaks`). We should use the full names in our agent prompts for readability, but knowing the aliases prevents confusion.

**Full Output:**
```text
TLDR provides code analysis commands optimized for LLM consumption.

Commands are organized by analysis layer:
- L1 (AST): tree, structure
- L2 (Call Graph): calls, impact, dead
- L3 (CFG): reaching-defs, available
- L4 (DFG): dead-stores
- L5 (PDG): slice
- Search: search
- Context: context
- Quality: smells
- Security: taint, vuln, secure

Usage: tldr [OPTIONS] <COMMAND>

Commands:
  tree           Show file tree structure [aliases: t]
  structure      Extract code structure (functions, classes, imports) [aliases: s]
  calls          Build cross-file call graph [aliases: c]
  impact         Analyze impact of changing a function [aliases: i]
  dead           Find dead (unreachable) code [aliases: d]
  reaching-defs  Analyze reaching definitions for a function [aliases: rd]
  taint          Analyze taint flows to detect security vulnerabilities [aliases: ta]
  available      Analyze available expressions for CSE detection [aliases: av]
  slice          Compute program slice
  search         Enriched search with function-level context cards (BM25 + structure + call graph)
  context        Build LLM-ready context from entry point
  smells         Detect code smells
  extract        Extract complete module info from a file [aliases: e]
  imports        Parse import statements from a file
  importers      Find files that import a given module
  complexity     Calculate function complexity metrics
  churn          Analyze git-based code churn
  debt           Analyze technical debt using SQALE method
  health         Comprehensive code health dashboard [aliases: h]
  hubs           Detect hub functions using centrality analysis
  whatbreaks     Analyze what breaks if a target is changed [aliases: wb]
  patterns       Detect design patterns and coding conventions [aliases: p]
  inheritance    Extract class inheritance hierarchies [aliases: inh]
  change-impact  Find tests affected by code changes [aliases: ci]
  deps           Analyze module dependencies [aliases: dep]
  diagnostics    Run type checking and linting [aliases: diag]
  doctor         Check and install diagnostic tools [aliases: doc]
  references     Find all references to a symbol [aliases: refs]
  clones         Detect code clones in a codebase [aliases: cl]
  dice           Compare similarity between two code fragments
  loc            Count lines of code with type breakdown (code, comments, blanks)
  cognitive      Calculate cognitive complexity for functions (SonarQube algorithm) [aliases: cog]
  halstead       Calculate Halstead complexity metrics per function [aliases: hal]
  coverage       Parse coverage reports (Cobertura XML, LCOV, coverage.py JSON) [aliases: cov]
  hotspots       Identify churn x complexity hotspots [aliases: hot]
  embed          Generate embeddings for code chunks [aliases: emb]
  semantic       Semantic code search using natural language [aliases: sem]
  similar        Find similar code fragments [aliases: sim]
  daemon         Daemon management commands (start, stop, status)
  cache          Cache management commands (stats, clear)
  warm           Pre-warm call graph cache for faster subsequent queries [aliases: w]
  stats          Show TLDR usage statistics
  surface        Extract machine-readable API surface for a library/package [aliases: surf]
  contracts      Infer pre/postconditions from guard clauses, assertions, isinstance checks [aliases: con]
  dead-stores    Find dead stores using SSA-based analysis [aliases: ds]
  chop           Compute chop slice - intersection of forward and backward slices [aliases: chp]
  specs          Extract behavioral specifications from pytest test files [aliases: sp]
  invariants     Infer invariants from test execution traces (Daikon-lite) [aliases: inv]
  verify         Aggregated verification dashboard combining multiple analyses [aliases: ver]
  cohesion       Analyze class cohesion using LCOM4 metric [aliases: coh]
  temporal       Mine temporal constraints (method call sequences) [aliases: tem]
  resources      Analyze resource lifecycle (leaks, double-close, use-after-close) [aliases: res]
  coupling       Analyze coupling between modules/classes via cross-module call edges [aliases: coup]
  interface      Extract interface contracts (public API signatures, contracts) [aliases: iface]
  explain        Comprehensive function analysis [aliases: exp]
  todo           Aggregate improvement suggestions (dead code, complexity, cohesion, similar)
  secure         Security analysis dashboard [aliases: sec]
  definition     Go-to-definition - find where a symbol is defined [aliases: def]
  diff           AST-aware structural diff between two files [aliases: df]
  api-check      Detect API misuse patterns [aliases: ac]
  vuln           Vulnerability scanning via taint analysis
  fix            Diagnose and auto-fix errors from compiler/runtime output [aliases: fx]
  bugbot         Automated bug detection on code changes
```

## Next Actions
Now that the root command list is verified, the next phase is to iterate through these 63 commands individually (`tldr <command> --help`), extracting their specific flags and positional arguments, and saving that data into the dedicated markdown files within the `research/tldr/` folder structure.