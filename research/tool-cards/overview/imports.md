# tldr imports

**Pitch**: Single-file import lister — returns the typed import statements of one source file.

**Why reach for it**
- Parses multi-line and aliased imports correctly across languages, not just regex-matchable patterns
- Returns a typed JSON envelope (`{file, language, imports}`) ready to pipe into another tool
- Daemon route honors `--lang` correctly (unlike `tldr importers`, where the daemon drops the flag)
- `--legacy-array` toggle for `jq '.[]'` consumers — compatible on both cold and warm paths

**When to use**
- Following the dependencies of one specific file outward
- Building a per-file module summary alongside `tldr extract`
- Traversing the import graph in tandem with `tldr importers` (the reverse direction)

**When NOT to use**
- Need to know *who* imports a module — that's `tldr importers`
- Need line numbers for the import statements — `tldr imports` does NOT emit them; use `tldr importers <MODULE>` per module to recover locations
- Need the full file inventory (functions, classes) — use `tldr extract`

**Output in plain words**: A wrapper object with the file path, detected language, and an array of imports where each entry carries the module name, optional imported names for `from X import Y` style, an `is_from` flag, and an optional alias.

**Killer detail**: A wrong `-l <lang>` is a silent empty-array failure — `imports file.py -l typescript` returns `{language: "typescript", imports: []}` with exit 0. Both cold and warm-daemon paths share this trap. Validate `imports.length > 0` or omit `--lang` entirely.

**Source**: `research/tldr/overview/imports.md`
