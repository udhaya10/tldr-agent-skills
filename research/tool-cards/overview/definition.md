# tldr definition

**Pitch**: Go-to-definition for a single symbol — by cursor position or by name — returning the binding's file, line, kind, and a builtin marker.

**Why reach for it**
- Resolves one specific binding (parameter, local, class, import) — not a grep-style guess
- Handles imports, local scopes, and Python cross-file resolution that plain text search gets wrong
- Returns a typed `SymbolKind` so the agent knows whether it landed on a `class`, `method`, `parameter`, or builtin without re-reading the file

**When to use**
- Holding a cursor coordinate from another tool and need the declaration site
- Disambiguating which `X` is meant in a file that shadows the name across scopes
- Checking whether a name is a Python builtin before assuming a source file exists
- Following an import alias back to its origin file

**When NOT to use**
- Need every function in the file — use `tldr extract`
- Need depth (purity, complexity, callers) for a named function — use `tldr explain`
- Looking for *usages* of a known declaration — that's `tldr references`

**Output in plain words**: A single record describing the symbol (name, kind, builtin flag) plus a definition location with file, line, and column — or no location at all when the symbol is a Python builtin.

**Killer detail**: Line is 1-indexed but column is 0-indexed. Mismatched indexing when piping coordinates from editors or `tldr extract` (which emit 1-indexed columns) is the dominant cause of `unresolved at` errors.

**Source**: `research/tldr/overview/definition.md`
