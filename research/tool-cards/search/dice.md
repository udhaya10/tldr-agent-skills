# tldr dice

**Pitch**: One-shot syntactic similarity score between two code fragments, returning a Dice coefficient and a clone-type bucket.

**Why reach for it**
- Confirms a clone suspicion in a single call — no project-wide index required
- Normalization modes let the caller decide whether to ignore identifiers, literals, or both
- Token counts alongside the score expose "same logic, different verbosity" vs "trivial near-duplicate"
- Sub-second on typical file pairs; no model inference, no daemon, no embeddings

**When to use**
- Already have two candidate fragments and need to score how alike they are
- Deciding whether two functions are worth deduping or refactoring together
- Sanity-checking that a port or rewrite preserved structure

**When NOT to use**
- Discovering clones across a codebase — use `tldr clones` for the project-wide scan
- Asking "do these behave the same" rather than "do these look the same" — use `tldr similar` for semantic matching
- Line-level review of the differences — `diff` is the right tool

**Output in plain words**: A small JSON blob with both target specs, the Dice coefficient (0.0–1.0), a human-readable interpretation bucket, and post-normalization token counts for each side.

**Killer detail**: The documented `file::function` target form is dead — it silently compares the whole files. Use `file:start:end` line ranges (sourced from `tldr extract`) whenever function-level comparison is the actual intent.

**Source**: `research/tldr/search/dice.md`
