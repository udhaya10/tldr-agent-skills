---
name: tldr-understand-function
description: Inspect a function or file by name (or cursor, or path) — get signature, purity, complexity, callers, callees, file inventory, or a handoff bundle. Reach for this ANY TIME the agent has a known starting point (function name, file path, cursor coordinate) and would otherwise read multiple files to learn what one symbol or file looks like. Triggers on "what does function X do", "tell me about function Y", "show me the signature of", "inspect this function", "is this function safe to refactor", "go to definition", "extract the API of this file", "what's defined in this file", "pack this function for handoff".
allowed-tools: [Bash]
---

# tldr-understand-function

## When to use

Use this skill whenever the agent ALREADY has a **starting point** — a function name, a class-qualified method (`Class.method`), a file path, or a cursor coordinate (`file:line:col`) — and needs to learn what's actually there: signature, purity, complexity, who calls it, what it calls, what else lives in the same file, or a packaged bundle to hand off.

The discriminator vs sibling skills:

- For code the agent does NOT yet have a name or path for → see `tldr-locate-code`
- For tracking every USAGE of a known symbol across the project → see `tldr-trace-relationships`
- For a broader codebase tour (not one function or one file) → see `tldr-orient-codebase`

If the agent already has a function name and reaches for `tldr search` to "find" it again, that's a wasted call — `tldr explain <name>` answers the actual question.

## The decision — which tool to use

The discriminator is **the cardinality of input → output**. That single dimension picks the right tool nearly every time. Going deeper than needed wastes tokens; going shallower than needed forces a second call.

| Input cardinality | Output cardinality | Reach for | Relative cost |
|-------------------|--------------------|-----------|---------------|
| One cursor (file + line + col) | One binding site (file, line, kind) | `tldr definition` | Cheapest |
| One named function | One comprehensive report (signature + purity + complexity + callers + callees) | `tldr explain` | Medium |
| One file | All definitions + intra-file call graph | `tldr extract` | Medium |
| One entry function | A transitive walk (entry + every callee within depth) packed for handoff | `tldr context` | Largest |

**The decision rule by situation**:

- **Don't know the function name yet, but have the file** → `tldr extract` on the file. Get the roster, then pick.
- **Know the name, just need where it lives** → `tldr definition`. One result, cheap.
- **Know the name, deciding whether to refactor** → `tldr explain`. Purity verdict + caller count is the signal.
- **Know the name, handing the function plus its dependencies to another model or skill** → `tldr context`. The bundle is exactly what the next-stage prompt wants.

**Cross-family check**: if the agent has only a vague idea (no name, no file path, no cursor), this is the wrong skill — pivot to `tldr-locate-code`. If the agent has a known symbol and wants every use site (not the definition site), pivot to `tldr-trace-relationships`.

## Tool reference

### `tldr definition` — go-to-definition for a single symbol

Go-to-definition for a single symbol — by cursor position or by name — returning the binding's file, line, kind, and a builtin marker.

**Why reach for it**:
- Resolves one specific binding (parameter, local, class, import) — not a grep-style guess
- Handles imports, local scopes, and Python cross-file resolution that plain text search gets wrong
- Returns a typed `SymbolKind` so the agent knows whether it landed on a `class`, `method`, `parameter`, or builtin without re-reading the file

**When to use**:
- Holding a cursor coordinate from another tool and need the declaration site
- Disambiguating which `X` is meant in a file that shadows the name across scopes
- Checking whether a name is a Python builtin before assuming a source file exists
- Following an import alias back to its origin file

**When NOT to use**:
- Need every function in the file → use `tldr extract`
- Need depth (purity, complexity, callers) for a named function → use `tldr explain`
- Looking for *usages* of a known declaration → that's `tldr references` in `tldr-trace-relationships`

**Output**: A single record describing the symbol (name, kind, builtin flag) plus a definition location with file, line, and column — or no location at all when the symbol is a Python builtin.

**Killer detail**: Line is 1-indexed but column is 0-indexed. Mismatched indexing when piping coordinates from editors or `tldr extract` (which emit 1-indexed columns) is the dominant cause of `unresolved at` errors. **Always decrement column** when piping from a 1-indexed source.

---

### `tldr explain` — deep-dive report on one named function

Deep-dive on one named function — signature, purity, complexity, callers, and callees — consolidated into one report.

**Why reach for it**:
- One call replaces piping through `tldr extract` + `tldr complexity` + `tldr calls` + `tldr references`
- Cyclomatic value is the canonical one from `tldr_core` — safe to compare across commands
- Purity classifier emits a four-state verdict (`pure`, `impure`, `unknown-medium`, `unknown-low`) with effect tags, so the agent can reason about blast radius before editing
- Accepts both bare names and `Class.method` qualified form

**When to use**:
- About to modify a function and need to know who calls it and what it touches
- Triaging "should I refactor this?" — purity + caller count is the signal
- Wanting both call directions plus context in one shot, not two

**When NOT to use**:
- Don't know the function name yet → start with `tldr extract` to get the roster
- Only need the declaration site → `tldr definition` is cheaper
- Need a single numeric metric → `tldr complexity` (in `tldr-audit-complexity`) is leaner

**Output**: A typed report with the function's location range, signature, purity verdict with effects, complexity numbers, and merged caller/callee lists (external callees marked with a `<external>` sentinel file).

**Killer detail**: `--depth` is dead code in v0.4.0 — declared on the struct but never read. Depths 0, 2, and 5 produce byte-identical output. **Don't waste tokens setting it.**

---

### `tldr extract` — full structural dump of a single file

Full structural dump of a single file — every function, class, import, and the intra-file call graph — with line numbers.

**Why reach for it**:
- Replaces reading a 1000-line file just to learn what's defined in it
- Line numbers in the output unblock downstream tools that demand explicit `<line>` arguments (`slice`, `reaching-defs`)
- Intra-file `call_graph` shows local function relationships without a project-wide build
- Daemon-cached on warm runs; cache key partitions correctly on language

**When to use**:
- Don't know the function name yet and need the file's inventory before drilling down
- Need line numbers for every function as input to other commands
- Want to see how functions in one file call each other

**When NOT to use**:
- Already know the function name and want depth → use `tldr explain`
- Need cross-file call relationships → use `tldr calls` or `tldr impact` in `tldr-trace-relationships`
- Target is a directory → use `tldr structure` in `tldr-orient-codebase` instead (extract rejects dirs with exit 11)

**Output**: A typed record per file with the function list (signatures and line numbers), class list with methods, import list, and a `caller → callee` map scoped to that file alone.

**Killer detail**: Passing `-l <lang>` bypasses the sibling-aware widening that makes `.h` files parse correctly in C++ projects. **Leave the flag off and let auto-detect read neighboring files** unless there's a verified reason to override.

---

### `tldr context` — pack a function + callees into LLM-ready markdown

Packs an entry function plus its transitive callees into one LLM-ready markdown bundle, sized to drop into a prompt.

**Why reach for it**:
- Replaces "read the function, then chase every helper it calls" with a single command
- `-f text` emits markdown via `to_llm_string()` — paste-ready, no post-processing
- Daemon-cached path is ~35× faster than rebuild on repeat queries against the same project
- Depth knob (`-d`) lets the caller trade context completeness against token budget

**When to use**:
- About to hand a function and its dependencies to another model or skill
- Investigating an unfamiliar entry point and want signature + callees in one shot
- Building a focused review pack for a single function instead of slurping whole files
- Need cyclomatic / block metrics alongside the dependency tree

**When NOT to use**:
- Just need raw caller/callee edges → use `tldr calls` in `tldr-trace-relationships` and skip the per-node decoration
- Want deep single-function analysis without the transitive walk → use `tldr explain`
- Still searching for the entry point → wrong family; pivot to `tldr-locate-code`

**Output**: A `RelevantContext` payload listing the entry plus every reachable function within depth, each with signature, file (relative to PATH), line, callees, and complexity. Text format renders the same data as markdown with code-block-wrapped signatures.

**Killer detail**: Using `--file` or the `<file>:<func>` shorthand silently disables the daemon route — the protocol can't carry those filters, so disambiguation costs the speedup.

**Other footguns**:
- `--file` is interpreted relative to PATH, not cwd. When `PATH=backend`, pass `--file providers/yahoo.py`, NOT `--file backend/providers/yahoo.py` — the latter silently matches nothing and returns `functions: []` with exit 0.
- With default `PATH=.` and no `-l`, duplicate function names across the project resolve via silent first-match-wins (e.g. `_to_finite_float` picks `precomputed_indicators.py` over `providers/yahoo.py`). Always scope PATH and pass `-l` when the name might be ambiguous.

## Common mistakes

- **Reaching for `tldr context` when `tldr explain` would do.** Context's transitive walk is expensive. If the agent only needs to understand the function in isolation (not its callees), explain is the right tool and ~5× smaller output.
- **Using `tldr explain` to inventory a file's functions.** Explain takes one name; the agent would be guessing. Use `tldr extract` for "what's in this file" and pivot to explain once a name catches the eye.
- **Setting `tldr explain --depth N`.** Dead code in v0.4.0 — depths 0, 2, 5 produce byte-identical output. Don't waste tokens setting it.
- **Calling `tldr definition` with mismatched indexing.** Line is 1-indexed, column is 0-indexed. Editor-pipe coordinates (1-indexed both) silently fail with `unresolved at`. Always decrement column when piping from a 1-indexed source.
- **Calling `tldr context` with `--file` or `<file>:<func>` shorthand and expecting daemon speed.** Both silently disable the daemon route; the cold-build cost gets paid.
- **Reaching for the wrong skill entirely.** If the agent has only an idea (no name, no file path, no cursor), this is the wrong skill — pivot to `tldr-locate-code`. If the agent has a known symbol and wants every place it's used (not the definition site), pivot to `tldr-trace-relationships` — `tldr explain` gives caller *names* but `tldr references` gives kind-classified use sites.
- **Passing `-l <lang>` to `tldr extract` on C/C++ projects.** Bypasses sibling-aware widening for `.h` parsing. Leave the flag off.

## See also

- `tldr-locate-code` — when the agent does NOT have a name, file, or cursor yet and needs to discover code from an idea or token
- `tldr-trace-relationships` — when the agent has a known symbol and wants every use site (callers, references, blast radius) — flat use-site lists rather than function-centric reports
- `tldr-orient-codebase` — when the scope is broader than one function or file (project tree, module structure, import graph)
- `tldr-audit-complexity` — when the agent needs raw complexity numbers in isolation rather than the full `explain` report
