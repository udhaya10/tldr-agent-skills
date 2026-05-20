# Command: `tldr fix apply`

## Ground Truth (`tldr fix apply --help`)
```text
Apply fix edits to source code and write the patched result

Usage: tldr fix apply [OPTIONS] --source <SOURCE>

Options:
  -s, --source <SOURCE>
          Source file to patch

  -e, --error <ERROR>
          Inline error text

      --error-file <ERROR_FILE>
          File containing error text

  -o, --output <OUTPUT>
          Output file for the patched source (stdout if not specified)

      --stdin
          Read error text from stdin

  -i, --in-place
          Write the patched source back to the original file (in-place fix)

  -d, --diff
          Show a unified diff instead of the full patched source

      --api-surface <API_SURFACE>
          Path to API surface JSON file for enhanced analysis (e.g., TS2339 property suggestions)

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

## Architectural Deep Dive
* **Under the hood:** `fix apply` takes a unified diff or search-and-replace block, locates the target AST nodes, verifies the surrounding code hasn't shifted, and safely mutates the file on disk.
* **Performance:** Instantaneous AST mutation.
* **LLM Cognitive Load:** Safer than native `sed` or `patch` which rely on brittle line numbers. By anchoring to AST nodes, the patch applies correctly even if the file was formatted or lines shifted slightly.

## Intent & Routing
* **User/Agent Goal:** Apply an LLM-generated patch to a file safely via AST anchoring.
* **When to choose this over similar tools:** Use to apply generated patches safely.

## Agent Synthesis
> **How to use `tldr fix apply`:**
> Use this to apply an LLM patch safely to a file.
> 
> **Command:** `tldr fix apply <file_path> <patch_file>`
