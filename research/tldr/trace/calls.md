# Command: `tldr calls`

## Ground Truth (`tldr calls --help`)
```text
Build cross-file call graph

Usage: tldr calls [OPTIONS] [PATH]

Arguments:
  [PATH]
          Project root directory (default: current directory)
          
          [default: .]

Options:
  -l, --lang <LANG>
          Programming language (auto-detected if not specified)

      --respect-ignore
          Respect .gitignore and .tldrignore patterns

      --max-items <MAX_ITEMS>
          Maximum items (edges) to include in output (default: 200)
          
          [default: 200]

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
* **Command Executed:** `tldr calls get_db_connection .`
* **Raw Output:** `error: unexpected argument '.' found`
* **Observation:** The documentation/help implies `tldr calls [OPTIONS] [PATH]`. It DOES NOT take a `<FUNCTION>` positional argument like `impact` does! It generates the *entire project's* call graph at once.

* **Command Executed:** `tldr calls . --max-items 10`
* **Raw Output:** Returns a massive JSON object with two arrays: `nodes` (every single function in the project) and `edges` (how they connect, e.g., `src_file`, `src_func`, `dst_file`, `dst_func`, `call_type`).
* **Observation:** `max-items` successfully truncated the `edges` list, returning exactly 10 edges instead of 11,920.

## Source Code Reality
* **Target File:** `crates/tldr-cli/src/commands/calls.rs`
* **Code Evidence:** 
  ```rust
  if !self.path.exists() {
      anyhow::bail!("Path not found: {}", self.path.display());
  }
  ```
* **Observation 1:** `calls` operates strictly on a directory (`.`), never on a specific function or file. 
* **Observation 2:** If you do not provide a language via `--lang`, and the directory is empty, it correctly returns an empty JSON object instead of hallucinating "Python" and throwing parsing errors.
* **Observation 3:** This command generates an overwhelming amount of data (L2 Graph). Agents should almost NEVER use this command raw. They should use `--max-items 0` and route the output to a file if they need the raw graph.

## Architectural Deep Dive
* **Under the hood:** `calls` extracts the global forward call graph of a directory. It identifies every function call across every file and maps caller-callee relations project-wide.
* **Performance:** Computing the global call graph is intensive; daemon start is highly recommended.
* **LLM Cognitive Load:** Do not use this to trace individual functions. This command is strictly for global architectural dumps or visualizing project complexity from a birds-eye view.

## Intent & Routing
* **User/Agent Goal:** Dump the full cross-file forward call graph for an entire project.
* **When to choose this over similar tools:** Use strictly for global architectural analysis. For specific functions, use `impact` or `context`.

## Agent Synthesis
> **How to use `tldr calls`:**
> Use this to dump the global call graph of a directory.
> * **Crucial Rule:** Do NOT use this to trace a specific function (use `impact`, `references`, or `context`). This is strictly for global architectural dumps.
> 
> **Command:** `tldr calls <dir>`
