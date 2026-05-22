# tldr clones

**Pitch**: Token-based all-vs-all duplication detector that finds copy-pasted code grep can't catch — different identifiers, different literals, same structure.

**Why reach for it**
- Catches Type-1 (exact), Type-2 (renamed identifiers), and Type-3 (gapped/parameterized) clones that line-diff tools miss entirely
- One of only two audit commands that emits SARIF — drops directly into GitHub code scanning and VS Code
- `--threshold` knob lets the agent dial precision/recall from "exact duplicates only" (0.99) to "every pair" (0.0)
- Each `ClonePair` ships with both fragments, a similarity score, and a human `interpretation` string

**When to use**
- Surfacing copy-paste tech debt across files (especially after merges or vendoring)
- Tracking propagation of a known vulnerable snippet — find every clone of the bad pattern
- Pre-refactor scan: "what other places use this same shape and should change with it?"
- CI integration where SARIF output feeds GitHub/IDE scanners

**When NOT to use**
- Comparing two specific files or functions — `tldr dice` is the pair-target sibling
- Semantic similarity (different shape, same intent) — `tldr similar` uses embeddings instead of tokens

**Output in plain words**: A `CloneDetectionReport` with `clone_pairs[]` (each `id`, `clone_type`, `similarity`, two `Fragment`s with file/lines/preview, and `interpretation`), plus `stats`, `config` echo, and triple-mirrored top-level `total_clones`/`files_analyzed` for jq convenience.

**Killer detail**: Non-existent paths return exit 0 with a valid empty report — there is NO upfront path validation, so `tldr clones /no/such/dir` looks the same as a successful scan that found zero clones. Agents must inspect `files_analyzed > 0` to distinguish "scanned and found nothing" from "path didn't exist."

**Other footguns**
- Detection is O(N²); scope to subdirectories. Stock-Monitor's 4-file `providers/` runs in ~1s, but the full 56-file `backend/` exceeds 30s.
- `--type-filter wat` and `--normalize wat` silently fall back to defaults — both fields are `String`, not typed enums, so typos disappear.

**Source**: `research/tldr/audit/clones.md`
