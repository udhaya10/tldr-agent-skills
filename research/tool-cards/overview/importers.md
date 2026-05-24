# tldr importers

> **Before writing the Usage block**: check `verified-invocations.md` in this group's
> `tool-cards/overview/` directory and copy the canonical syntax verbatim.
> Do NOT reconstruct syntax from prose — that is how hallucinated flags get introduced.

**Pitch**: Reverse module-lookup — finds every file in a path that imports a given module, with the verbatim import line and line number.

**Why reach for it**
- Answers "who depends on this module?" in one call before a rename, deletion, or refactor
- Returns structured results with line numbers (unlike `tldr imports`, which lists modules without locations)
- Handles language-specific import syntax (Python dotted paths, TS specifiers, Go packages) — no grep regex juggling
- Daemon cache makes repeat queries effectively free

**When to use**
- About to delete or rename a module and need the consumer list
- Auditing the blast radius of a public API at module granularity
- Looking for every call site of a library import across a project

**When NOT to use**
- Need usages of a *symbol* rather than a *module* — use `tldr references`
- Want the imports of one specific file — that's the mirror command `tldr imports`
- Need a full directional dependency graph — use `tldr deps`

**Usage (copy from `verified-invocations.md` — do not reconstruct)**:
```bash
tldr importers [OPTIONS] <MODULE> [PATH]
tldr importers pandas backend                  # find all files under backend/ that import pandas
tldr importers pandas backend --limit 1        # cap results to first match
```

**Output in plain words**: The queried module name, an array of importing files each with their line number and the raw import statement, plus a `total` count that ignores `--limit` truncation.

**Killer detail**: On a mixed-language project root, auto-detect silently picks the dominant language and returns zero importers for a query in the *other* language — the Python fallback only triggers when detection returns None, not when it guesses wrong. Pass `-l <lang>` explicitly or scope the PATH to a single-language subdirectory.

**Source**: `research/tldr/overview/importers.md`
