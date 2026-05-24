# tldr extract

> **Before writing the Usage block**: check `verified-invocations.md` in this group's
> `tool-cards/overview/` directory and copy the canonical syntax verbatim.
> Do NOT reconstruct syntax from prose — that is how hallucinated flags get introduced.

**Pitch**: Full structural dump of a single file — every function, class, import, and the intra-file call graph — with line numbers.

**Why reach for it**
- Replaces reading a 1000-line file just to learn what's defined in it
- Line numbers in the output unblock downstream tools that demand explicit `<line>` arguments (`slice`, `reaching-defs`)
- Intra-file `call_graph` shows local function relationships without a project-wide build
- Daemon-cached on warm runs; cache key partitions correctly on language

**When to use**
- Don't know the function name yet and need the file's inventory before drilling down
- Need line numbers for every function as input to other commands
- Want to see how functions in one file call each other

**When NOT to use**
- Already know the function name and want depth — use `tldr explain`
- Need cross-file call relationships — use `tldr calls` or `tldr impact`
- Target is a directory — use `tldr structure` instead (extract rejects dirs with exit 11)

**Usage (copy from `verified-invocations.md` — do not reconstruct)**:
```bash
tldr extract [OPTIONS] <FILE>
tldr extract backend/db.py                  # full structural dump of one file
tldr extract backend/db.py -f compact       # compact format output
```

**Output in plain words**: A typed record per file with the function list (signatures and line numbers), class list with methods, import list, and a `caller → callee` map scoped to that file alone.

**Killer detail**: Passing `-l <lang>` bypasses the sibling-aware widening that makes `.h` files parse correctly in C++ projects. Leave the flag off and let auto-detect read neighboring files unless you have a verified reason to override.

**Source**: `research/tldr/overview/extract.md`
