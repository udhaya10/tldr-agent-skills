# tldr diff

**Pitch**: AST-aware structural diff between two files (or two directories at file/module/architecture granularity) — understands functions, classes, imports, and architectural layers, not just text.

**Why reach for it**
- Eight granularity levels from `token` up through `architecture`, each tuned to a different review intent
- `--semantic-only` strips formatting/whitespace noise — exactly what PR review wants
- Module-level diff yields a unique `import_graph_summary` (edges added/removed); architecture-level yields a `stability_score`
- `--granularity` errors list all 8 valid values inline — discoverable without re-reading help

**When to use**
- Reviewing a refactor and want to see renames/moves/extracts as first-class change types, not as line edits
- Comparing two versions of a class or module at the right abstraction level
- Architecture audit: `-g architecture` reports `cycles_introduced` and `cycles_resolved` between two directory snapshots
- CI gate for module-level import changes: pipe L7 output through jq

**When NOT to use**
- Diffing git refs against working tree — use `git diff` or feed change-detection through `tldr change-impact`
- Finding similar code across one tree — use `tldr clones`

**Output in plain words**: JSON with `file_a`, `file_b`, `identical`, a `changes` array tagging each as insert/delete/update/move/rename/format/extract, a `summary` block of per-type counts, and the `granularity` echoed back. L6/L7/L8 extend the schema with file/module/arch-specific sections.

**Killer detail**: `-g token` (L1) produces ~17,000 lines of stdout for two small files — token diffs are almost never what you want. The default `-g function` (L4) is the sweet spot; reach for L5+ for higher-level reviews and L3 only when L4 hides too much.

**Source**: `research/tldr/ops/diff.md`
