# tldr deps

**Pitch**: Module-level import graph for a project — files and the files they import — with cycle detection, optional package collapsing, and first-class Graphviz output.

**Why reach for it**
- One of the few tldr commands that emits DOT format (`-f dot | dot -Tsvg`) for architecture diagrams
- `--show-cycles` collapses the response to just the cycle list — perfect for a CI "are there import cycles?" gate
- `--collapse-packages` flips file nodes into package nodes for high-level architectural views
- `--include-external` surfaces third-party dependencies alongside internal ones

**When to use**
- Mapping module imports as a graph (NOT call relationships — that's `tldr coupling`)
- CI cycle gate: `tldr deps . --show-cycles -f compact | jq 'length > 0'`
- Generating an architecture diagram for docs/onboarding via DOT output
- Auditing third-party dependency creep with `--include-external`

**When NOT to use**
- Tracking which functions call which functions — use `tldr coupling` (CALL graph) or `tldr calls`
- Listing the imports of a single file — use `tldr imports` (per-file LIST)
- Mapping class inheritance — use `tldr inheritance`

**Output in plain words**: JSON with `root`, detected `language`, `internal_dependencies` keyed by relative filename, optional `external_dependencies`, a `circular_dependencies` array, and a `stats` block with file/edge/cycle counts. With `-f dot`, you get a `digraph deps { ... }` block ready to pipe into Graphviz.

**Killer detail**: `--show-cycles` returns a bare array — NOT the full `DepsReport` envelope. The schema diverges based on the flag; downstream consumers expecting `.stats` will break when `--show-cycles` is on.

**Source**: `research/tldr/ops/deps.md`
