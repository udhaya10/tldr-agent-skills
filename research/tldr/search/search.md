# Command: `tldr search`

## Ground Truth (`tldr search --help`)
```text
Enriched search with function-level context cards (BM25 + structure + call graph)

Usage: tldr search [OPTIONS] <QUERY> [PATH]

Arguments:
  <QUERY>
          Search query (natural language or code terms; BM25 by default, regex when `--regex` is set)

  [PATH]
          Directory to search in (default: current directory)
          
          [default: .]

Options:
  -l, --lang <LANG>
          Programming language (auto-detect if not specified)

  -k, --top-k <TOP_K>
          Maximum number of result cards to return
          
          [default: 10]

      --no-callgraph
          Skip call graph enrichment (much faster, no callers/callees)

      --regex
          Use regex pattern matching instead of BM25 ranking. The query is interpreted as a regex pattern

      --hybrid <HYBRID>
          Hybrid mode: combine BM25 relevance with regex filtering. The positional query is used for BM25 ranking, this pattern for regex filtering

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
* **Command Executed:** `tldr search "sqlite lock retry" . --no-callgraph`
* **Raw Output:** Returns a JSON object with `results` array containing the most relevant functions/classes (with file, line_range, signature, score, matched_terms, and a code preview).
* **Observation:** The natural language search successfully parsed the query and ranked relevant context. The `--no-callgraph` flag dramatically speeds it up by skipping the L2 edges calculation for every result.

## Source Code Reality
* **Target File:** `crates/tldr-cli/src/commands/search.rs`
* **Observation 1:** `tldr search` supports three modes: BM25 (natural language, default), Regex (using `--regex`), and Hybrid (using `--hybrid <regex>`).
* **Observation 2:** The `-k` flag defaults to 10 results.
* **Observation 3:** By default, it hits the daemon cache.

## Intent & Routing
* **User/Agent Goal:** Find exact keywords, variables, or regex patterns with structural context.
* **When to choose this over similar tools:** Use instead of `grep` because this returns LLM-ready context cards (callers/callees) instead of raw text lines.

## Agent Synthesis
> **How to use `tldr search` (Semantic/Code Search):**
> Use this command to find where a specific concept, error message, or feature is implemented in the codebase when you don't know the exact file or function name.
> 1. Use natural language or code terms for the `<QUERY>` argument.
> 2. Always append `--no-callgraph` to save compute time and tokens unless you explicitly need caller/callee edges in the search results.
> 3. If you know exactly what you are looking for, use `--regex` instead of the default BM25 ranking.
> 
> **Command:** `tldr search "your natural language query" . --no-callgraph -k 5`
