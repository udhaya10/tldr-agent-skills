# tldr tree

> **Before writing the Usage block**: check `verified-invocations.md` in this group's
> `tool-cards/overview/` directory and copy the canonical syntax verbatim.
> Do NOT reconstruct syntax from prose — that is how hallucinated flags get introduced.

**Pitch**: Recursive directory listing that respects `.gitignore` by default and returns structured JSON nodes — no AST, just files.

**Why reach for it**
- One call replaces `ls -R` plus a hand-written ignore filter — `node_modules`, `.venv`, build outputs are excluded automatically
- Structured JSON is `jq`-navigable; no parsing ASCII tree output
- `--ext` is repeatable and tolerant (`.py` and `py` both work) for quick language-scoping
- Cheap — pure filesystem walk, no tree-sitter cost

**When to use**
- First discovery step on an unfamiliar repo
- Picking which files to feed into `tldr structure`, `tldr extract`, or `tldr semantic`
- Need a `.gitignore`-clean file enumeration filtered by extension

**When NOT to use**
- Need to know what's *defined* in the files (functions, classes) — use `tldr structure`
- Targeting an unfiltered full repo — output explodes (~13k lines on Stock-Monitor); always scope with `--ext` or a subdirectory

**Usage (copy from `verified-invocations.md` — do not reconstruct)**:
```bash
tldr tree [OPTIONS] [PATH]
tldr tree backend --ext .py              # list Python files under backend/
tldr tree . --ext .py --ext .js          # filter by multiple extensions
```

**Output in plain words**: A recursive node tree where directories carry a `children` array and files carry a `path`, with `name` and `type` on every node. Empty filter results return a dir node with empty `children`, not an error.

**Killer detail**: When the daemon cache is warm, the cached `FileTree` is returned as-is and `--ext` / `--include-hidden` flags are NOT re-applied. For predictable filtering, run against a stopped daemon or expect the full cached tree.

**Source**: `research/tldr/overview/tree.md`
