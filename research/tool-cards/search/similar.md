# tldr similar

> **Before writing the Usage block**: check `verified-invocations.md` in this group's
> `tool-cards/search/` directory and copy the canonical syntax verbatim.
> Do NOT reconstruct syntax from prose — that is how hallucinated flags get introduced.

**Pitch**: Embedding-based "find code that does what this code does" search across a project, ranked per destination file by default.

**Why reach for it**
- Surfaces semantic neighbors that share intent but not identifiers — the gap `tldr dice` and `tldr search` both miss
- Default aggregation collapses chunk noise into one row per destination file (M16 fix to the old per-chunk firehose)
- On-disk embedding cache makes repeat queries against the same path cheap
- `--function` mode pivots from "files like this file" to "implementations like this function"

**When to use**
- Looking for refactor candidates, hidden duplication, or sibling implementations of an interface
- Hunting clone families that share a bug after fixing one site
- Discovering an existing helper before writing a new one

**When NOT to use**
- Have a specific candidate pair already — `tldr dice` is the cheaper two-target comparison
- Need exhaustive project-wide clone enumeration — `tldr clones` is the right unit of inquiry
- Searching by exact token or name — `tldr search` is deterministic and faster

**Usage (copy from `verified-invocations.md` — do not reconstruct)**:
```
tldr similar [OPTIONS] <FILE>
tldr similar backend/providers/base.py -p /path/to/project/backend/providers
tldr similar backend/providers/yahoo.py -F fetch_historical_data -p /path/to/project/backend/providers
```

**Output in plain words**: By default, a ranked list of destination files with `total_score`, `avg_score`, and `matched_chunks`. With `--function` or `--by-chunk`, a per-chunk report whose `source` block embeds the full query function content.

**Killer detail**: Relative `-p <PATH>` is broken — the index stores paths that fail to match the canonicalized source, every query returns "no indexed chunks found." Pass `-p` as an absolute path, or omit it and let the smart-path logic use the file's parent dir.

**Other footguns**
- `--include-self` is dead code in v0.4.0 — declared on the arg struct but never read; self is always excluded from results regardless of the flag.
- `--by-chunk` on a whole-file query (no `--function`) silently picks just the FIRST chunk of the source file as the query — you get a one-chunk run, not the all-chunks-vs-all-chunks comparison the name suggests. Pair `--by-chunk` with `--function <name>` for predictable per-chunk behavior.

**Source**: `research/tldr/search/similar.md`
