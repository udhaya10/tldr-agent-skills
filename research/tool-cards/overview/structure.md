# tldr structure

> **Before writing the Usage block**: check `verified-invocations.md` in this group's
> `tool-cards/overview/` directory and copy the canonical syntax verbatim.
> Do NOT reconstruct syntax from prose — that is how hallucinated flags get introduced.

**Pitch**: Function, class, and import inventory of a file or directory — tree-sitter parsed, with line numbers, across every source file in the target.

**Why reach for it**
- Replaces "read 50 files to learn what exists" with one JSON call
- Aggregates across a whole directory; `tldr extract` only handles one file at a time
- Returns line numbers needed by `slice`, `impact`, and `extract` follow-ups
- Daemon cache properly partitions on language, so repeat queries are cheap and correct

**When to use**
- Onboarding a new codebase and need the API roster across many files
- Picking high-value files to drill into with `tldr extract` or `tldr impact`
- Need function/class locations across a directory in one shot

**When NOT to use**
- Just want to know which files exist — use `tldr tree` (no parsing cost)
- Want full function bodies and intra-file call graph — use `tldr extract` on the chosen file
- Targeting a multi-thousand-file repo without scoping — output explodes; pass a subdirectory or `-m N`

**Usage (copy from `verified-invocations.md` — do not reconstruct)**:
```bash
tldr structure [OPTIONS] [PATH]
tldr structure backend/db.py          # single file inventory
tldr structure backend                # directory-wide inventory
tldr structure backend -m 5          # cap to 5 results
```

**Output in plain words**: A record per file listing its classes (with methods), top-level definitions, module-level methods, and imports. Empty directories return a `warnings` array rather than an error.

**Killer detail**: When language detection fails (unknown extension, mixed-language dir), the parser silently falls back to Python — a non-Python file may be analyzed as Python and emerge with an empty extraction. Always verify the `language` field in the response.

**Source**: `research/tldr/overview/structure.md`
