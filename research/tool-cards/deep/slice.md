# tldr slice

**Pitch**: PDG-based program slice from a single line — the exact set of lines that mathematically affect (backward) or are affected by (forward) the criterion.

**Why reach for it**
- Replaces "read the whole 200-line function and trace by hand" with a compiler-grade dependency answer
- The only deep-group command with a daemon cache — repeat queries are fast
- Out-of-range criterion lines return an `explanation` field that includes the real function bounds, so agents self-correct without re-querying metadata
- Direction knob (`-d backward|forward`) covers both "where did this value come from?" and "if I change this, what breaks?"

**When to use**
- Debugging a corrupt value and want the minimal backward set of contributing lines
- Planning a single-line edit and want every downstream line it could touch (forward)
- Tracing one variable through a multi-variable function — pass `--variable <name>`
- Have ONE criterion line; if there are two endpoints, use `tldr chop` instead

**When NOT to use**
- Want lines BETWEEN two specific points — that's `tldr chop` (intersection of two slices)
- Question is variable-origin across all uses, not a single line — `tldr reaching-defs` is variable-centric

**Output in plain words**: A list of line numbers in the slice plus a `slice_lines` array with code, definitions, and uses per line; `edges` carries data/control dependency links when the direct-compute path runs.

**Killer detail**: When the criterion line is outside the function, exit code is 0 — agents must parse the `explanation` string, which embeds the actual bounds (e.g., `"line 9999 is outside function 'get_db_connection' (lines 48-53)"`) and retry inside that range.

**Source**: `research/tldr/deep/slice.md`
