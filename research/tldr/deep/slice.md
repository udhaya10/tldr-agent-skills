# Command: `tldr slice`

## Ground Truth (`tldr slice --help`)
```text
Compute program slice

Usage: tldr slice [OPTIONS] <FILE> <FUNCTION> <LINE>

Arguments:
  <FILE>
          Source file path

  <FUNCTION>
          Function name containing the line

  <LINE>
          Line number to slice from

Options:
  -d, --direction <DIRECTION>
          Slice direction: backward (what affects this line) or forward (what this line affects)

          Possible values:
          - backward: Backward slice - what affects this line?
          - forward:  Forward slice - what does this line affect?
          
          [default: backward]

      --variable <VARIABLE>
          Variable to filter by (optional - traces all if not specified)

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
* **Command Executed:** `tldr slice backend/db.py get_yahoo_symbol_from_security_id 168`
* **Raw Output:** Returns a JSON object containing `slice_lines` and `edges`, including the lines and control dependencies that mathematically affect line 168.
* **Observation:** `slice` correctly filters out unrelated lines in the function and tracks variable usages back to the function arguments (like `conn` and `security_id`).

## Source Code Reality
* **Target File:** `crates/tldr-cli/src/commands/slice.rs`
* **Code Evidence:** 
  ```rust
  let direction: SliceDirection = self.direction.into();
  ```
  ```rust
  if let Some(output) = try_daemon_route::<LegacySliceOutput>(
      project, "slice", params_with_file_function_line(&self.file, &self.function, self.line),
  )
  ```
* **Observation 1:** `slice` defaults to a `backward` search (what affects this line). You can flip it to `forward` (what this line affects) via the `-d` flag.
* **Observation 2:** The command hits the daemon first for caching.
* **Observation 3:** `slice` depends on `pdg` (Program Dependence Graph). If the exact line number passed doesn't contain an AST node, the slice will return empty.

## Architectural Deep Dive
* **Under the hood:** `slice` computes Program Dependence Graphs (PDGs) by combining the Control Flow Graph (CFG) and Data Dependence Graph (DDG). It computes transitively closed dependencies from a specific starting node (line & variable) either backward (what influences this line) or forward (what this line influences).
* **Performance:** Building a complete PDG for a large function is mathematically complex and memory-intensive, but once constructed, slicing queries resolve in milliseconds.
* **LLM Cognitive Load:** Slicing is the gold standard for tracking down why a variable has an incorrect value. Instead of manually inspecting every line in a 300-line function with complex branching, `tldr slice` isolates the exact 15 lines that mathematically contributed to that state.

## Intent & Routing
* **User/Agent Goal:** Trace exactly what lines of code mathematically affect a target line (backward) or what a line affects (forward).
* **When to choose this over similar tools:** Use when debugging state corruption or tracking variable origins. Always run `tldr extract` first to find the exact line numbers.

## Agent Synthesis
> **How to use `tldr slice`:**
> Use this to trace the exact mathematical dependency chain (backward or forward) of a line inside a function.
> * **Crucial Rule:** You MUST pass the exact file path, function name, and line number. Do not guess the line number; find it first using `tldr extract`.
> 
> **Command:** `tldr slice <file_path> <function> <line_number>`
