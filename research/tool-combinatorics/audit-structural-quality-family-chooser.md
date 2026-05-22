# Lens: Audit structural quality — family chooser

**The question this lens answers**: "I want to know if the code is well-structured — which of `cohesion`, `coupling`, `clones` should I run? (And what about import coupling?)"

**Toolset**: `tldr cohesion`, `tldr coupling`, `tldr clones` — plus `tldr deps` (lives in the ops group) for the import-graph case

**Why a family-chooser lens, why these tools**: All three audit-group tools measure "is this code structurally healthy?" but at three different scopes — INSIDE one class, BETWEEN modules via function calls, ACROSS the whole project for duplication. The discriminator is **scope of the structural unit being judged**. A common confusion deserves a separate callout: `tldr coupling` is FUNCTION-CALL coupling. **Import-graph coupling lives in `tldr deps` (ops group), not here.**

## Decision tree

| The structural question is... | Scope | Reach for |
|-------------------------------|-------|-----------|
| "Do the methods inside this ONE class actually share state?" | Inside one class (LCOM4) | `tldr cohesion` |
| "Which modules are too tangled by function calls? Any cycles?" | Between modules, function-call edges, Martin metrics | `tldr coupling` (project-wide mode) |
| "Are these two specific files too entangled?" | Pair of files, call-by-call | `tldr coupling <FILE_A> <FILE_B>` (pair mode) |
| "Where is the same shape copy-pasted across the project?" | Project-wide token-similarity, Type-1/2/3 clones | `tldr clones` |
| **"Which modules import each other? Are there import cycles?"** | **Module import graph, not call graph** | **`tldr deps` (ops group, NOT this family)** |

## The default

**No single default — the structural unit decides.** That said, for a fresh structural audit on an unfamiliar Python project, **`tldr coupling <project> --top 20`** is the most generally useful first call: project-wide Martin afferent/efferent/instability across all modules, with cycle detection folded in. Escalate to `tldr cohesion <file>` when one class is already suspect (god class review), to `tldr clones <subdir>` when investigating copy-paste tech debt (scope to a subdirectory; the algorithm is O(N²) — full backends commonly exceed the 30s timeout), and **out of this family to `tldr deps`** whenever the question is import-shaped rather than call-shaped.

## Common mistakes

- **Using `tldr coupling` to find import cycles.** Coupling traces FUNCTION CALLS, not imports. The `--help` itself redirects to `tldr deps` for the import-graph case. Cycle hunts on imports → `tldr deps . --show-cycles`. Call-graph cycles → `tldr coupling --cycles-only`. They are different graphs and usually surface different problems.
- **Parsing `tldr coupling`'s output without branching on mode.** The schema flips entirely on whether `PATH_B` is supplied: pair mode returns `{ path_a, path_b, a_to_b, b_to_a, ... }`, project-wide mode returns `{ martin_metrics: {...}, pairwise_coupling: {...} }`. Branch on the presence of `martin_metrics` (project) vs `path_a` (pair) before parsing.
- **Trusting `tldr deps --show-cycles` output shape.** It returns a bare array, NOT the full `DepsReport` envelope. Code that reaches for `.stats` will break when `--show-cycles` is on. Branch on the flag.
- **Running `tldr cohesion --lang typescript`.** It is Python-only despite accepting `--lang`. The parser hardcodes `tree_sitter_python::LANGUAGE`; the flag is silently ignored. On non-Python trees it returns an empty `classes[]` with no `warnings`.
- **Running `tldr clones` on a full backend and waiting.** Detection is O(N²) all-vs-all token comparison. Scope to subdirectories (`tldr clones src/providers/`) for fast results; full medium backends (~50 files) routinely blow the 30s timeout.
- **Trusting `tldr clones` zero-results on a path that may not exist.** Non-existent paths return exit 0 with a valid empty report (NO upfront validation). Check `files_analyzed > 0` to distinguish "scanned and found nothing" from "path was bogus."
- **Reaching for `tldr smells --deep` instead of these dedicated tools for one specific dimension.** Smells will report cohesion/coupling/clone findings, but as smell bullets, not as auditable structural reports. Use the dedicated commands when you need LCOM4 numbers, Martin metrics, or fragment-level clone pairs.

## What this lens captures

- The scope discriminator (inside one class / between modules / across project) is mechanical once internalized.
- The cross-group callout (import coupling → `tldr deps`) prevents the most common wrong-tool failure in this area.

## What this lens misses

- **Inheritance hierarchy structure.** Parent-child relationships, diamond patterns, mixin abuse are their own analysis — `tldr inheritance`, covered in the API/design family.
- **Function-call cycles within one module's internals.** `tldr calls` traces a single call chain; this family is module-level.
- **Whether bad structure is actively causing bugs.** Structural metrics describe shape, not pain. For pain, cross-reference with `tldr hotspots` (smells/debt family).

## Pair with

- `audit-smells-debt-family-chooser.md` — once a structural problem is named, hotspots/debt tell you whether it's worth fixing
- `audit-api-design-family-chooser.md` — `tldr inheritance` covers the class-hierarchy structural axis this family doesn't

## Sources

- `research/tool-cards/audit/cohesion.md`
- `research/tool-cards/audit/coupling.md`
- `research/tool-cards/audit/clones.md`
- `research/tool-cards/ops/deps.md` *(cross-group reference for import coupling)*
