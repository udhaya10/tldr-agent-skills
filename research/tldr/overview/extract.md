# Command: `tldr extract`

## Ground Truth (`tldr extract --help`)
```text
Extract complete module info from a file

Usage: tldr extract [OPTIONS] <FILE>

Arguments:
  <FILE>
          File to extract

Options:
  -l, --lang <LANG>
          Programming language (auto-detected from file extension if not specified)

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
* **Command Executed:** `tldr extract backend/db.py`
* **Raw Output:** Returns a comprehensive JSON object (`ModuleInfo`) detailing `imports`, `functions` (with parameters, docstrings, and start/end lines), `classes`, `constants`, and an intra-file `call_graph` showing what functions within the file call each other.
* **Observation:** This is incredibly powerful. It parses out the exact start/end line numbers of every function in the file, which is perfectly positioned as a prerequisite step before running line-specific commands like `tldr slice` or `tldr chop`.

## Source Code Reality
* **Target File:** `crates/tldr-cli/src/commands/extract.rs` & `crates/tldr-core/src/ast/extract.rs`
* **Code Evidence:** 
  ```rust
  let resolved_lang: Option<Language> = match self.lang {
      Some(l) => Some(l),
      None => Language::from_path_with_siblings(&self.file),
  };
  ```
  ```rust
  if !canonical_file.starts_with(&canonical_base) {
      return Err(TldrError::PathTraversal(file_path.to_path_buf()));
  }
  ```
* **Observation 1:** It uses a smart "sibling-aware" language detector. If you run it on a `.h` file in a C++ project, it parses it as C++ instead of C. But you can strictly override this with `--lang`.
* **Observation 2:** It has strict path traversal protections. You cannot trick it into reading files outside the project boundary.
* **Observation 3:** Hits the daemon cache first for near-instant retrieval.

## Intent & Routing
* **User/Agent Goal:** Read the exact body of a specific function or class.
* **When to choose this over similar tools:** Use instead of `cat` or `grep` to read code precisely without context window bloat.

## Agent Synthesis
> **How to use `tldr extract` (File Intelligence):**
> Use this when you have found a file of interest and need to extract its imports, constants, classes, and function signatures. 
> 1. You MUST run this command before attempting to use line-specific commands (like `slice` or `chop`) so you don't guess line numbers. The output will give you exact `line` and `line_end` bounds.
> 2. It also generates an intra-file `call_graph`, which tells you how the functions *within* the file depend on each other.
> 
> **Command:** `tldr extract <FILE_PATH>`
