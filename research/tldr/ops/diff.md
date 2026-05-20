# Command: `tldr diff`

## Ground Truth (`tldr diff --help`)
```text
AST-aware structural diff between two files

Usage: tldr diff [OPTIONS] <FILE_A> <FILE_B>

Arguments:
  <FILE_A>
          First file (or directory for L6/L7/L8) to compare

  <FILE_B>
          Second file (or directory for L6/L7/L8) to compare

Options:
  -g, --granularity <GRANULARITY>
          Diff granularity level

          Possible values:
          - token:        Token-level diff (L1)
          - expression:   Expression-level diff (L2)
          - statement:    Statement-level diff (L3)
          - function:     Function-level diff (L4) - default
          - class:        Class-level diff (L5)
          - file:         File-level diff (L6)
          - module:       Module-level diff (L7)
          - architecture: Architecture-level diff (L8)
          
          [default: function]

      --semantic-only
          Exclude formatting-only changes (comments, whitespace)

  -O, --output <OUTPUT>
          Output file (optional, stdout if not specified)

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
* **Command Executed:** Checked the `--help` output against the actual source implementation.
* **Observation:** `tldr diff` provides AST-aware diffs across 8 levels of granularity. It defaults to `function` level. 

## Source Code Reality
* **Target File:** `crates/tldr-cli/src/commands/remaining/diff.rs`
* **Code Evidence:** 
  ```rust
  if !self.file_a.is_dir() || !self.file_b.is_dir() {
      bail!("File-level (L6) diff requires directories, not individual files");
  }
  ```
  ```rust
  pub fn run_class_diff(file_a: &Path, file_b: &Path, semantic_only: bool)
  ```
* **Observation 1:** Granularity levels `L6 (file)`, `L7 (module)`, and `L8 (architecture)` **MUST** be run on directories, not files. The tool will throw a hard error if you pass individual files to these levels.
* **Observation 2:** Granularity levels `L1` through `L5 (class)` **MUST** be run on individual files.
* **Observation 3:** The `--semantic-only` flag is incredibly useful because it completely ignores formatting changes, comments, and whitespace, drastically reducing token count when analyzing changes.

## Intent & Routing
* **User/Agent Goal:** View an AST-aware structural diff.
* **When to choose this over similar tools:** Use instead of `git diff` to see what logical structures changed rather than raw lines.

## Agent Synthesis
> **How to use `tldr diff` (AST-Aware Diffs):**
> Use this instead of standard `git diff` to see structural changes without the noise of formatting or whitespace.
> 1. By default, it diffs at the `function` level.
> 2. You MUST use `--semantic-only` to ignore whitespace/comment changes.
> 3. To compare files: `tldr diff <FILE_A> <FILE_B> -g function --semantic-only`
> 4. To compare directories (architecture/module level): `tldr diff <DIR_A> <DIR_B> -g module`
