# Command: `tldr semantic`

## Ground Truth (`tldr semantic --help`)
```text
Semantic code search using natural language

Usage: tldr semantic [OPTIONS] <QUERY> [PATH]

Arguments:
  <QUERY>
          Natural language query

  [PATH]
          Path to search (default: current directory)
          
          [default: .]

Options:
  -n, --top <TOP>
          Maximum number of results
          
          [default: 10]

  -t, --threshold <THRESHOLD>
          Minimum similarity threshold (0.0 to 1.0)
          
          [default: 0.5]

  -m, --model <MODEL>
          Embedding model: arctic-xs, arctic-s, arctic-m, arctic-m-long, arctic-l
          
          [default: arctic-m]

      --langs <LANGS>
          Filter by language via file extensions (comma-separated, e.g., `--langs rs,py`).
          
          Values are parsed by `Language::from_extension`, which accepts file extensions such as `rs`, `py`, `ts`, `go`, `java`, `rb`, `kt`, `cpp`. Language names (`rust`, `python`) are NOT accepted here; use the global `--lang <LANG>` flag above for name-based single-language selection. Passing an unknown extension silently drops that entry from the filter.
          
          Renamed from `--lang` (pre-VAL-009) to avoid a clap TypeId collision with the global `--lang` arg which is `Option<Language>`.

      --no-cache
          Disable embedding cache

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
* **Observation:** Tool evaluated and integrated successfully via batch script profiling.

## Intent & Routing
* **User/Agent Goal:** Find code based on concepts or natural language queries (e.g., 'billing logic').
* **When to choose this over similar tools:** Use when you don't know the exact variable names or keywords. Use `search` for exact matches.

## Agent Synthesis
> **Note:** This tool exists in the CLI but is considered lower-priority or niche. If required, read the CLI help block above to infer flags.
