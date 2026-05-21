# Command: `tldr chop`

## Environment Pin

| Field | Value |
|---|---|
| `tldr --version` | 0.4.0 |
| Build features | `semantic` (verified; chop itself is non-semantic, uses PDG engine) |
| Target repo | Stock-Monitor @ commit `e601869` |
| Upstream `tldr-code` pinned to | local clone @ `6c4011a` (release v0.4.0) |
| Daemon state at probe time | N/A — `tldr chop` does **not** call `try_daemon_route` (verified by grep) |
| OS | darwin 25.2.0 |
| Probe date | 2026-05-22 |

Re-run all evidence via [`chop.probes/probe.sh`](./chop.probes/probe.sh).

---

## Ground Truth (`tldr chop --help`)

```text
Compute chop slice - intersection of forward and backward slices

Usage: tldr chop [OPTIONS] <file> <function> <source_line> <target_line>

Arguments:
  <file>
          Source file to analyze

  <function>
          Function name containing both lines

  <source_line>
          Line to trace FROM (source of data flow)

  <target_line>
          Line to trace TO (target of data flow)

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

---

## Output Shape

| Aspect | Value |
|---|---|
| Default format | `json` |
| Formats that work | `json`, `text`, `compact` (P01, P06, P07) |
| Formats that error | `sarif`, `dot` (P05, P08: exit 1) |
| Typical output size | small (<500 bytes; <15 lines JSON) |

**Top-level keys (JSON, `ChopResult`):**
- `file` (`string`) — input FILE path verbatim (NOT canonicalized — schema-cleanup-v1 BUG-21 / P3.BUG-N2)
- `lines` (`array<u32>`) — line numbers on the dependency path (typically includes endpoints + intermediate nodes)
- `count`, `line_count` (`u32`) — both equal to `lines.length` (legacy duplicate fields)
- `source_line`, `target_line` (`u32`) — input values echoed verbatim
- `path_exists` (`bool`) — **true when chop was computed successfully**, false on any failure (NOT a literal file-existence check)
- `function` (`string`) — input function name verbatim
- `explanation` (`string`) — ALWAYS present; either "Found N lines on the dependency path from line X to line Y." (success) or "Analysis could not be completed: <error>." (failure)

**Same-line shape (P09):** `{ lines: [N], count: 1, path_exists: true, explanation: "Source and target are the same line (N)." }` — special case.

**Failure shape (P11/P12/P13/P14a/P16/P19):**
```json
{
  "file": "<input>", "lines": [], "count": 0, "line_count": 0,
  "source_line": X, "target_line": Y,
  "path_exists": false,
  "function": "<input>",
  "explanation": "Analysis could not be completed: <reason>"
}
```
**Exit code 0 on all failures.** The error is encapsulated in `explanation`. Agents MUST check `path_exists` and parse `explanation` to detect failures.

**Error shapes (exit-coded, NOT JSON-encapsulated):**
- Missing positional: clap-style `"error: the following required arguments were not provided: <X> …"` → exit **2**
- File not found: `"Error: file not found: /no/such/file.py"` → exit **1** (lowercase "file" — different from `tldr available`'s capitalized "File not found:" and `tldr calls`'s "Path not found:")
- Format reject: `"Error: --format sarif not supported by chop. ..."` → exit **1**
- Bad `--lang`: clap-style → exit **2**
- Negative `source_line` like `-5`: clap-style `"error: unexpected argument '-5' found / tip: to pass '-5' as a value, use '-- -5'"` → exit **2**

---

## Probe Matrix

| # | Probe | Type | Exit | Captured |
|---|-------|------|------|----------|
| P01 | `tldr chop yahoo.py _to_finite_float 21 25` | happy (3-line chop) | 0 | [`01-happy.*`](./chop.probes/) |
| P02 | `tldr chop yahoo.py fetch_historical_data 40 80` | happy-scale (empty PDG anchors) | 0 | [`02-happy-scale.*`](./chop.probes/) |
| P03 | `tldr chop file fn 20` *(no target_line)* | failure-missing-input | 2 | [`03-missing-arg.*`](./chop.probes/) |
| P04 | `tldr chop /no/such/file.py some_fn 1 10` | failure-badpath | 1 | [`04-badpath.*`](./chop.probes/) |
| P05 | `tldr chop ... -f sarif` | format-reject (sarif) | 1 | [`05-format-reject-sarif.*`](./chop.probes/) |
| P06 | `tldr chop ... -f text` | format-text | 0 | [`06-format-text.*`](./chop.probes/) |
| P07 | `tldr chop ... -f compact` | format-compact | 0 | [`07-format-compact.*`](./chop.probes/) |
| P08 | `tldr chop ... -f dot` | format-reject (dot) | 1 | [`08-format-reject-dot.*`](./chop.probes/) |
| P09 | `tldr chop yahoo.py _to_finite_float 20 20` | same-line special case | 0 | [`09-same-line.*`](./chop.probes/) |
| P10 | `tldr chop yahoo.py _to_finite_float 25 20` | reversed direction | 0 | [`10-reversed.*`](./chop.probes/) |
| P11 | `tldr chop yahoo.py no_such_function 10 20` | function-not-found (in-JSON) | 0 | [`11-function-not-found.*`](./chop.probes/) |
| P12 | `tldr chop ... 99999 100000` | source-line-out-of-range | 0 | [`12-source-oor.*`](./chop.probes/) |
| P13 | `tldr chop ... 20 99999` | target-line-out-of-range | 0 | [`13-target-oor.*`](./chop.probes/) |
| P14 | `tldr chop ... -l brainfuck` | bad-lang | 2 | [`14-bad-lang.*`](./chop.probes/) |
| P14a | `tldr chop yahoo.py _to_finite_float 20 24` | in-range BUT no PDG anchor (silent empty) | 0 | [`14a-empty-pdg-node.*`](./chop.probes/) |
| P15 | `tldr chop ... -o text` | legacy -o text override | 0 | [`15-output-flag-text.*`](./chop.probes/) |
| P16 | `tldr chop README.md anything 1 10` | non-source-md (silent fallback) | 0 | [`16-non-source-md.*`](./chop.probes/) |
| P17 | `tldr chop ... -q` | quiet | 0 | [`17-quiet.*`](./chop.probes/) |
| P18 | `tldr chop ... -5 24` | negative-line (clap rejection) | 2 | [`18-negative-line.*`](./chop.probes/) |
| P19 | `tldr chop ... 0 24` | zero-line (in-JSON error) | 0 | [`19-zero-line.*`](./chop.probes/) |

### Observations

- **P01** — Chop 21→25 in `_to_finite_float`: returns 3 lines [20, 21, 25] with `path_exists: true`, explanation `"Found 3 lines on the dependency path from line 21 to line 25."` Note the chop includes line 20 (a dependency of 21, even though 20 < source_line) — chop is the intersection of forward and backward slices, not strictly the range [source, target].
- **P02** — Chop 40→80 in `fetch_historical_data`: returns empty `lines`, `path_exists: false`, explanation about the lines not being anchored to PDG nodes. **Larger function picked PDG-unanchored lines** — re-pick line numbers to land on real statements.
- **P03** — stderr `"error: the following required arguments were not provided: <target_line>"`, exit `2`. All four positionals are required; clap enforces.
- **P04** — stderr `"Error: file not found: /no/such/file.py"`, exit `1`. **Lowercase "file"** — different from `tldr available`'s "File not found:" (capital F) and `tldr calls`'s "Path not found:" (capital P). Three different conventions across CLI for missing-path.
- **P05** — stderr `"Error: --format sarif not supported by chop. Use --format json. SARIF is only emitted by: vuln, clones."`, exit `1`.
- **P06** — Text format renders `"Chop Analysis: X -> Y / Function: ... / Path exists: N lines on dependency path / Lines: [list] / Explanation: ..."` block.
- **P07** — Single-line minified JSON.
- **P08** — stderr `"Error: --format dot not supported by chop. ..."`, exit `1`.
- **P09** — Same-line query (20 → 20): returns `{ lines: [20], count: 1, path_exists: true, explanation: "Source and target are the same line (20)." }` — special-case handled.
- **P10** — Reversed direction (source 25 > target 20): exit 0 with valid output. **The engine handles reversed inputs gracefully** — chop is symmetric in concept, but the explanation field may not reflect the input order. Always provide source ≤ target conventionally; do not rely on reverse semantics.
- **P11** — Function-not-found: exit 0 with `path_exists: false`, `lines: []`, `explanation: "Analysis could not be completed: function 'no_such_function' not found in <absolute_path>"`. **Failure is in-band (JSON), NOT exit-coded.**
- **P12** — `source_line: 99999`: exit 0 with `path_exists: false`, `lines: []`, explanation indicates the line is outside the function range. Same in-band failure pattern.
- **P13** — `target_line: 99999`: explanation `"Analysis could not be completed: line 99999 is outside function '_to_finite_float' (lines 18-25)"`. **The explanation includes the function's actual line bounds** — useful for clients to recover.
- **P14** — clap-style: `"error: invalid value 'brainfuck' for '--lang <LANG>': Unknown language: brainfuck"`, exit `2`.
- **P14a** — **Subtle silent failure mode:** lines 20 and 24 are WITHIN `_to_finite_float`'s body (lines 18-25) but no PDG node is anchored there (line 20 may be a docstring; line 24 may be a brace/comment/multi-line continuation). Returns `path_exists: false`, `lines: []`, explanation: `"parse error in <path>: line 24 is within function '_to_finite_float' (lines 18-25) but no PDG node is anchored there (likely a brace, comment, or part of a multi-line statement attributed to a neighbouring line)"`. **A line being inside the function bounds does NOT guarantee the chop will succeed** — only statement lines (with real AST/PDG nodes) work. **Recovery hint:** the explanation tells you to pick a "neighbouring line" — use `tldr extract <file>` or `tldr slice <file> <fn> <line>` to find PDG-anchored lines.
- **P15** — Legacy `-o text` flag (hidden via `#[arg(hide = true)]`): produces text output, equivalent to `-f text`. Two flag paths to the same behavior.
- **P16** — Markdown file: exit 0 with `path_exists: false`, explanation about Python parsing failure or function not found. **Silent language fallback to Python** (Language::from_path returns None → unwrap_or(Python)).
- **P17** — `-q` suppresses the `"Computing chop from line X to line Y in <file>::<fn>..."` progress message.
- **P18** — Negative source_line `-5`: clap rejects with `"error: unexpected argument '-5' found / tip: to pass '-5' as a value, use '-- -5'"`, exit `2`. **Same gotcha as `tldr hubs --threshold -0.1`** — values starting with `-` are parsed as flags. But chop's positionals are `u32` so negative values would be invalid anyway; the clap error is structurally correct.
- **P19** — `source_line: 0`: exit 0 with in-band failure. Line 0 is invalid but accepted by clap (u32 accepts 0); explanation indicates the line is outside function bounds.

---

## Source Code Reality

**Target file(s):**
- `crates/tldr-cli/src/commands/contracts/chop.rs` (the CLI; under `contracts/` namespace, not `commands/` directly)
- `crates/tldr-core/src/program_analysis/chop.rs` (`compute_chop`)
- `crates/tldr-cli/src/output.rs:113` (`validate_format_for_command`)

**Pinned to upstream commit:** `6c4011a` (release v0.4.0)

**Argument struct:**
```rust
// crates/tldr-cli/src/commands/contracts/chop.rs:145-174
#[derive(Debug, Args)]
pub struct ChopArgs {
    #[arg(value_name = "file")] pub file: PathBuf,
    #[arg(value_name = "function")] pub function: String,
    #[arg(value_name = "source_line")] pub source_line: u32,
    #[arg(value_name = "target_line")] pub target_line: u32,
    #[arg(long = "output-format", short = 'o', hide = true,
          default_value = "json")] pub output_format: ContractsOutputFormat,
    #[arg(long, short = 'l')] pub lang: Option<Language>,
}
```
Reveals: all four positionals required; `source_line`/`target_line` are typed `u32` so negative values fail clap parsing. Legacy `--output-format`/`-o` flag is **hidden** (`hide = true`) — back-compat for the global `-f`/`--format`.

**Graceful failure encapsulation (the P11-P16 root cause):**
```rust
// chop.rs:207-229
let mut result = match compute_chop(
    canonical_path.to_str().unwrap_or_default(),
    &self.function, self.source_line, self.target_line, language,
) {
    Ok(r) => r,
    Err(e) => {
        ChopResult {
            file: user_path_str.clone(), lines: vec![], count: 0, line_count: 0,
            source_line: self.source_line, target_line: self.target_line,
            path_exists: false, function: self.function.clone(),
            explanation: Some(format!("Analysis could not be completed: {}", e)),
        }
    }
};
```
Reveals: every `compute_chop` Err is converted into a valid `ChopResult` with `path_exists: false` and an explanation string. **Exit code is 0 for these cases.** Agents must check `path_exists` and `explanation` to detect failures — exit code alone is misleading.

**Path-preservation hack (P3.BUG-N2):**
```rust
// chop.rs:206-237 (excerpt)
let user_path_str = self.file.display().to_string();
... compute_chop runs with canonical_path ...
result.file = user_path_str;
```
Reveals: the `file` field in the JSON output is forced back to the user-supplied path AFTER `compute_chop` (which may have stored a canonical path). This is intentional — macOS canonicalizes `/tmp` to `/private/tmp`, which would break round-trip parsing in agent pipelines.

**`path_exists` semantics:**
The field is **not** a literal file-existence check. It's true when the chop was computed (lines successfully extracted from the PDG); false when any error path was taken (function not found, line out of range, no PDG anchor, etc.). **Confusing name — should arguably be `success` or `chop_computed`.**

**Format validation:** confirmed at `crates/tldr-cli/src/output.rs:113-163` — `chop` is in neither `SARIF_SUPPORTED` nor `DOT_SUPPORTED`.

---

## Architectural Deep Dive

- **Under the hood:** Builds a Program Dependency Graph (PDG) for the named function via tree-sitter, then computes `forward_slice(source) ∩ backward_slice(target)`. The intersection is the chop — every statement that's both reachable forward from source and reachable backward from target. Empty intersection (when source and target aren't on any common dependency path) returns empty `lines` with success-shape explanation.
- **Performance:** Cold per call (no daemon). ~50ms for a small function. Building the PDG is the dominant cost.
- **LLM cognitive load:** Replaces "which lines are between this read and that write?" — chop is the precise compiler-grade answer. Useful for understanding minimal changes (refactor an algorithm? chop tells you exactly which lines are involved). Pairs with `tldr slice` (single-direction) and `tldr reaching-defs` (variable definitions).

---

## Intent & Routing

- **User/Agent Goal:** find every line on the dependency path between two specific lines in a function — the minimal set that must be inspected when reasoning about how data flows from A to B.
- **When to choose this over similar tools:**
  - Over `tldr slice <fn> <line>`: `slice` is one-directional (forward or backward from a single line). `chop` is two-directional (intersection between two lines). Use slice for "what affects X?" or "what does X affect?"; chop for "what's between source and target?"
  - Over `tldr available <fn>`: `available` is expression-centric (CSE); `chop` is line-centric (dependency path).
  - Over manual reading: chop gives the EXACT line set that matters between two points, eliminating need to inspect the entire function.
- **Prerequisites (composition):**
  - Both `source_line` and `target_line` must be **PDG-anchored statement lines** (not docstrings, braces, or multi-line continuations). If a probe returns `path_exists: false` with the "no PDG node anchored there" explanation, pick a neighbouring line.
  - Use `tldr slice <file> <fn> <line>` first to find valid PDG-anchored lines OR `tldr extract <file>` to see statement line bounds.

---

## Agent Synthesis

> **How to use `tldr chop`:**
> Bi-directional program-slice chop: intersection of `forward_slice(source_line)` and `backward_slice(target_line)`. `tldr chop <file> <function> <source_line> <target_line>` returns JSON `{ file, lines, count, line_count, source_line, target_line, path_exists, function, explanation }`. `path_exists: true` indicates chop was computed; `path_exists: false` indicates a failure (with details in `explanation`). Default JSON, `-f text` for human display, `-f compact` for one-line, `sarif`/`dot` rejected. Exit codes: 0 always for in-band JSON failures (encapsulated), 1 file-not-found / format-reject, 2 clap missing-arg / bad-lang / negative-line.
>
> **Crucial Rules:**
> - **Exit code 0 ≠ chop succeeded.** Function-not-found, line-out-of-range, PDG-no-anchor, and unsupported-language ALL return exit 0 with `path_exists: false` AND a descriptive `explanation`. **Agents MUST inspect `path_exists`** (boolean) and parse `explanation` — process exit code is misleading. Same anti-pattern as `tldr whatbreaks`.
> - **`path_exists` is misnamed.** It does NOT check whether the FILE exists. It means "chop was computed successfully" (PDG built, lines extracted). A failed analysis on an existing file returns `path_exists: false`.
> - **In-range lines may still produce empty chops.** Lines within the function's byte range (e.g., 20-24 inside `_to_finite_float` lines 18-25) may NOT have PDG nodes anchored — docstrings, braces, comments, and multi-line statement continuations land "between" PDG nodes. P14a: line 24 was inside the function but the explanation said `"no PDG node is anchored there (likely a brace, comment, or part of a multi-line statement attributed to a neighbouring line)"`. **Fix:** use `tldr slice <file> <fn> <line>` first to identify PDG-anchored lines, then pass those to `chop`.
> - **Reversed direction works.** `chop file fn 25 20` returns valid output (P10) — the engine doesn't error on source > target. But the explanation may not reflect the input order. Use `min(source, target)` and `max(source, target)` conventionally.
> - **Negative line values fail clap, not the engine.** `chop file fn -5 24` is rejected with clap's "unexpected argument" because `-5` starts with `-` (same gotcha as `tldr hubs --threshold -0.1`). Also, source_line/target_line are u32 — negatives are nonsensical anyway.
> - **File-not-found uses lowercase "file not found:"** (P04) — different from `tldr available`'s "File not found:" (capital F) and `tldr calls`'s "Path not found:" (capital P). Match on the substring for cross-command path-error detection.
> - **`file` field is the USER-supplied path, NOT canonicalized.** Even though the engine uses the canonical path internally, the output echoes the input verbatim (P3.BUG-N2 fix) — keeps `/tmp/...` from being rewritten to `/private/tmp/...` on macOS. Round-trip-safe for agents.
> - **Markdown/unknown-extension files silently fall back to Python parsing**, then fail with an in-band JSON explanation (P16). Pass `-l <real_lang>` for non-default extensions.
> - **Same-line query is a recognized special case.** `chop file fn 20 20` returns `{ lines: [20], count: 1, path_exists: true, explanation: "Source and target are the same line (20)." }` (P09).
> - **NO daemon route.** Every call rebuilds the PDG.
>
> **Command:** `tldr chop <file> <function> <source_line> <target_line>`
>
> **With common flags:** `tldr chop <file> <fn> <src> <tgt> -l <lang> -f compact | jq .lines` (use to extract just the line set for downstream tooling; check `.path_exists` first to ensure the chop actually computed).
