# tldr halstead

**Pitch**: Halstead software-science scorer that counts operators and operands per function and derives the classic vocabulary/length/volume/difficulty/effort/bugs/time measures.

**Why reach for it**
- Lexical complexity dimension — orthogonal to `tldr complexity` (decision points) and `tldr cognitive` (nesting); a function can pass both and still score high on Halstead volume
- The `bugs` field (`volume / 3000`, classic Halstead estimate) makes a defensible "where should we add tests?" shortlist
- `--show-operators` / `--show-operands` expose the actual token classification — invaluable for explaining why a score is unexpectedly high
- Independent `--threshold-volume` (default 1000) and `--threshold-difficulty` (default 20); a function violates if it exceeds EITHER

**When to use**
- Need a vocabulary/length view of complexity to complement structural metrics — auditing test coverage priorities, sizing review effort
- Want token-level evidence for a refactor recommendation (raw operator/operand lists)
- Running a project-wide scan with volume/difficulty thresholds for CI gating

**When NOT to use**
- Care about control-flow paths or nesting — use `tldr complexity` (cyclomatic) or `tldr cognitive` (SonarQube)
- Need a single-function deep dive with daemon caching — `tldr complexity` is the cheap path

**Output in plain words**: JSON `{functions[], violations[], summary, warnings?}`. Each function carries a nested `metrics: {n1, n2, N1, N2, vocabulary, length, volume, difficulty, effort, time, bugs}` plus a `status` of `good`/`warning`/`bad`.

**Killer detail**: Unlike `tldr cognitive`, a non-source single FILE (e.g., `README.md`) returns exit 11 with `"Unsupported language: Could not detect language for: README.md"` — the explicit error is preferable, but agents handling both commands cannot share an error path: `cognitive` swallows the same input as exit 0 with an empty result.

**Source**: `research/tldr/audit/halstead.md`
