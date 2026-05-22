# tldr chop

**Pitch**: Two-point program chop — the intersection of `forward_slice(source_line)` and `backward_slice(target_line)`, giving every line on the dependency path from A to B.

**Why reach for it**
- Answers "what's actually between this read and that write?" with the precise compiler-grade line set
- One call replaces re-running `slice` twice and computing the intersection by hand
- Echoes the user-supplied file path verbatim (no `/private/tmp` canonicalization surprise) — round-trip-safe in agent pipelines
- Same-line query is a recognized special case, not an error

**When to use**
- Have TWO specific lines in the same function and want the minimal set worth inspecting
- Planning a localized refactor and want to know which intermediate statements are on the data-flow path
- Investigating "did this assignment really reach that branch?" between two known points

**When NOT to use**
- Only have one criterion line — use `tldr slice` (chop with one endpoint is just a slice)
- Want every use of a variable across the function — `tldr reaching-defs` is variable-centric

**Output in plain words**: A small JSON record with `lines` (the chop), `path_exists`, `source_line`, `target_line`, the input function name, and an `explanation` string that always carries either a success summary or the failure reason.

**Killer detail**: Exit code is 0 on every failure mode (function-not-found, line out of range, no PDG anchor, unknown language) — the real success signal is `path_exists: true`, and despite the name it does NOT check file existence; it means "chop was computed." Always branch on `path_exists` and read `explanation`, never on exit code.

**Other footguns**
- A line WITHIN the function's byte range can still produce `path_exists: false` because docstrings, braces, and multi-line statement continuations have no PDG node — pick a neighbouring statement line. Use `tldr slice` or `tldr extract` first to find PDG-anchored lines.
- Reversed direction (source > target) works silently and returns valid output but the explanation may not reflect the input order — pass `min(source,target)` and `max(source,target)` conventionally.

**Source**: `research/tldr/deep/chop.md`
