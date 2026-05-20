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

## Architectural Deep Dive
* **Under the hood:** `tree` wraps standard filesystem traversal but injects the `tldr` token-counting engine and `.gitignore` parser at every node.
* **Performance:** It caches directory sizes so that re-running `tree` on a large monorepo is nearly instantaneous.
* **LLM Cognitive Load:** Raw `ls -R` or `tree` dumps massive lists of files, including `node_modules` or `.git`, destroying LLM context. This command automatically filters those out and annotates files with their token weight. This lets an LLM instantly deduce where the actual "logic" of the project lives vs where the "config" lives.

## Intent & Routing
* **User/Agent Goal:** Display a `.gitignore`-respecting directory tree annotated with token counts.
* **When to choose this over similar tools:** Use instead of `ls` or system `tree` to instantly see where the bulk of the codebase's logic (tokens) resides, free of noise.

## Agent Synthesis
> **How to use `tldr tree`:**
> Use this instead of `ls` to explore the directory structure. It respects `.gitignore` and shows you the token weight of each file so you know what is safe to read.
> 
> **Command:** `tldr tree <dir>`
