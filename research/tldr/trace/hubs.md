# Command: `tldr hubs`

## Ground Truth (`tldr hubs --help`)
```text
Detect hub functions using centrality analysis

Usage: tldr hubs [OPTIONS] [PATH]

Arguments:
  [PATH]
          Project root directory (default: current directory)
          
          [default: .]

Options:
      --top <TOP>
          Number of top hubs to return
          
          [default: 10]

      --algorithm <ALGORITHM>
          Centrality algorithm to use

          Possible values:
          - all:         All algorithms: in_degree, out_degree, pagerank, betweenness
          - indegree:    In-degree only (fast)
          - outdegree:   Out-degree only (fast)
          - pagerank:    PageRank only
          - betweenness: Betweenness only (slow for large graphs)
          
          [default: all]

      --threshold <THRESHOLD>
          Minimum composite score threshold (0.0-1.0)

  -l, --lang <LANG>
          Programming language (auto-detect if not specified)

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
* **Command Executed:** Checked `tldr hubs --help` and source file.
* **Observation:** Identifies the most critical/central functions in the codebase graph.

## Source Code Reality
* **Observation 1:** The `--algorithm` flag defaults to `all` (running in/out degree, pagerank, and betweenness). For large codebases, `betweenness` is extremely slow.
* **Observation 2:** If it hangs, agents should switch to `--algorithm indegree`.

## Architectural Deep Dive
* **Under the hood:** `hubs` calculates centrality metrics (like Indegree or PageRank) across the project-wide call graph. It identifies nodes (functions/classes) with disproportionately high incoming references.
* **Performance:** Requires building the global call graph first.
* **LLM Cognitive Load:** Helps an agent immediately locate "god functions" or critical dependencies. A bug in a hub function has massive cascading effects, so the agent must proceed with extreme caution if modifying them.

## Intent & Routing
* **User/Agent Goal:** Find the most depended-upon "god functions" in the codebase.
* **When to choose this over similar tools:** Use to locate critical architectural hubs and high-risk refactoring targets.

## Agent Synthesis
> **How to use `tldr hubs`:**
> Use this to find highly coupled "god functions" that are critical to the system.
> 
> **Command:** `tldr hubs <dir> --algorithm indegree`
