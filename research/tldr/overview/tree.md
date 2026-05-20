# Command: `tldr tree`

## Ground Truth (`tldr tree --help`)
```text
Show file tree structure

Usage: tldr tree [OPTIONS] [PATH]

Arguments:
  [PATH]
          Directory to scan (default: current directory)
          
          [default: .]

Options:
  -e, --ext <EXTENSIONS>
          Filter by file extensions (e.g., --ext .py --ext .rs)

  -H, --include-hidden
          Include hidden files and directories

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
* **Command Executed:** `tldr tree backend --ext .py`
* **Raw Output:** Returns a JSON object structured as a recursive file tree (`name`, `type`, `children`, `path`).
* **Observation:** The command works exactly as expected. The `--ext` flag successfully filters the tree to only show Python files, reducing token bloat.

## Source Code Reality
* **Target File:** `crates/tldr-cli/src/commands/tree.rs`
* **Code Evidence:** 
  ```rust
  if let Some(tree) = try_daemon_route::<FileTree>(&self.path, "tree", params_with_path(Some(&self.path)))
  ```
* **Observation 1:** Hits the daemon cache first, making it instantly responsive on large repositories.
* **Observation 2:** Respects `.gitignore` by default. You can pass `--include-hidden` to show `.env` files or hidden `.git` folders.

## Intent & Routing
* **User/Agent Goal:** See the file hierarchy and token counts of the project.
* **When to choose this over similar tools:** Use instead of `ls` because it respects .gitignore and shows token weight.

## Agent Synthesis
> **How to use `tldr tree` (Directory Structure):**
> Use this command to understand the layout of a project or folder without opening every file.
> 1. Use the `--ext` flag to filter out noise (e.g., `--ext .py --ext .ts`).
> 2. The output is a JSON tree, which is highly token-efficient for LLMs.
> 
> **Command:** `tldr tree <DIR_PATH> --ext .py`
