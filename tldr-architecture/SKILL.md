---
name: tldr-architecture
description: Map a codebase's architecture — structure, layers, coupling, dependencies, duplication, and lifecycle protocols. Reach for this any time you'd otherwise read many files or grep imports to understand how the project is ORGANIZED, what's COUPLED to what, where the BOTTLENECKS live, what's DUPLICATED, or what import/call CYCLES exist. Triggers on "show me the architecture", "what's the structure of this codebase", "map the layers", "show coupling", "show dependencies", "find import cycles", "what depends on what", "find code duplication", "which functions are the choke points", "is this class doing too much", "what's the implicit lifecycle protocol".
allowed-tools: [Bash]
compatibility: "Requires tldr-code CLI v0.4.0+. Tested on darwin and linux."
metadata:
  version: "1.0.0"
  author: "udhaya10"
  repository: "udhaya10/tldr-agent-skills"
  tldr.cli-version: "0.4.0"
  tldr.research-commit: "a025973"
  tldr.commands-wrapped: "hubs, coupling, cohesion, clones, deps, temporal, structure"
---

# tldr-architecture

## When to use

Use this skill whenever the intent is to understand **how a codebase is organized at the structural level** — its file inventory, the API roster, which functions are choke points, which modules are tangled, which modules import which, which classes lack cohesion, what code is duplicated, or what implicit call-order protocols exist. This is the "map the system" skill, not the "find one piece of code" skill.

The discriminators vs sibling skills:

- For a first-pass codebase tour (tree + structure + extract + importers) → see `tldr-orient-codebase`. Same tools partially overlap, but orient is a workflow ("get me oriented"); this skill is a deep-dive ("show me the architecture").
- For "what NEEDS cleanup" (smells, debt, hotspots, churn) → see `tldr-audit-smells`. This skill describes STRUCTURE; that skill describes PAIN.
- For tracing call/use relationships of ONE function → see `tldr-trace-relationships`. `hubs` is shared here because it identifies architecture-level bottlenecks (no function name needed), but per-function tracing belongs there.
- For "what will break if I change X" → see `tldr-change-impact`.

If you already know the file path and just need to read it, don't reach for this skill — read the file directly.

## The three-way coupling collision (READ THIS FIRST)

Three tools in this skill all sound like "coupling" or "dependencies" but answer **different questions on different graphs**. Picking the wrong one is the #1 LLM trap in this area.

| Tool | Graph | Unit | Answers |
|------|-------|------|---------|
| `tldr coupling` | Call graph | Modules (files) | "Which modules are tangled by FUNCTION CALLS? Are there CALL-graph cycles? What's each module's Martin instability?" |
| `tldr deps` | Import graph | Modules (files) | "Which modules IMPORT which? Are there IMPORT cycles? What does the architecture diagram look like?" |
| `tldr hubs` | Call graph | Functions | "Which FUNCTIONS are most-central — the choke points / load-bearing nodes?" |

They are NOT interchangeable. `coupling` and `deps` describe different graphs of the same modules. `hubs` ranks individual functions, not modules. Reaching for `coupling` to find "import cycles" returns nothing useful; reaching for `deps` to find "the most important functions" returns a file-level import map. Pick by **graph type** AND **unit**, not by which word your prompt happens to use.

## The decision — which tool to use

The discriminator is **what scope of structural unit** the question is about (filesystem / definitions / functions / modules / class / project), **which graph** (none / call / import / call-sequence / similarity), and **which metric** (none / centrality / Martin Ca/Ce/I / LCOM4 / Dice / FP-Growth support).

| The architectural question is... | Scope | Reach for |
|----------------------------------|-------|-----------|
| "What FILES exist in this project?" | Filesystem layout | `tldr tree` — covered in `tldr-orient-codebase` |
| "What's DEFINED in those files — the API roster?" | Functions/classes/imports per file | `tldr structure` |
| "Which FUNCTIONS are most-called — the choke points?" | Centrality on call graph | `tldr hubs` |
| "Which MODULES are tangled by FUNCTION CALLS? Call-graph cycles?" | Martin Ca/Ce/instability across modules | `tldr coupling <project>` (project-wide mode) |
| "Are these two specific FILES too entangled?" | Pair of files, call-by-call | `tldr coupling <FILE_A> <FILE_B>` (pair mode) |
| "Which MODULES IMPORT each other? IMPORT cycles? Architecture diagram?" | Module import graph | `tldr deps` |
| "Are the methods inside this ONE class actually cohesive?" | LCOM4 per class | `tldr cohesion` |
| "What CODE IS DUPLICATED across the project?" | Token-similarity, Type-1/2/3 clones | `tldr clones` |
| "What's the implicit call-order / lifecycle PROTOCOL the code follows?" | Method-call sequence mining (FP-Growth) | `tldr temporal` |

## Default — intent-conditional, no universal default

This skill genuinely serves multiple incompatible intents. Pick the default by intent:

- **"I want to see WHAT'S DEFINED across the codebase"** → `tldr structure <dir>`. The API roster in one call.
- **"I want to see WHAT'S COUPLED via CALLS"** → `tldr coupling <project> --top 20`. Martin metrics + cycle detection.
- **"I want to see WHAT'S COUPLED via IMPORTS"** → `tldr deps . --show-cycles`. Cycle list, or drop `--show-cycles` for the full import graph.
- **"I want to see the MOST-CALLED nodes"** → `tldr hubs <dir>`. Composite centrality with `risk_level`.
- **"I want to see the IMPLICIT LIFECYCLE PROTOCOL"** → `tldr temporal <dir> --source-lang <lang>`. "A before B" call-sequence patterns.
- **"I want WITHIN-CLASS structural quality"** → `tldr cohesion <file>` (Python only — see below).
- **"I want PROJECT-WIDE DUPLICATION"** → `tldr clones <subdir>` (scope tightly — O(N²)).

For a fresh structural audit on an unfamiliar Python project, `tldr coupling <project> --top 20` AND `tldr deps . --show-cycles` together are the most generally useful pair — different graphs, different problems, both usually worth seeing.

## Tool reference

> **Command guardrail**: Only invoke the exact subcommands documented below. Do **not** invent or guess command names. If uncertain whether a command exists, run `tldr --help` before proceeding.

### `tldr structure` — function/class/import inventory across files

Function, class, and import inventory of a file or directory — tree-sitter parsed, with line numbers, across every source file in the target.

**Why reach for it**:
- Replaces "read 50 files to learn what exists" with one JSON call
- Aggregates across a whole directory; `tldr extract` only handles one file at a time
- Returns line numbers needed by `slice`, `impact`, and `extract` follow-ups
- Daemon cache properly partitions on language, so repeat queries are cheap and correct

**When to use**:
- Onboarding a new codebase and need the API roster across many files
- Picking high-value files to drill into with `tldr extract` or `tldr impact`
- Need function/class locations across a directory in one shot

**Usage**:
```bash
tldr structure <path> [-l <lang>] [-m <max>]
```

**Output**: A record per file listing its classes (with methods), top-level definitions, module-level methods, and imports. Empty directories return a `warnings` array rather than an error.

**Killer detail**: When language detection fails (unknown extension, mixed-language dir), the parser **silently falls back to Python** — a non-Python file may be analyzed as Python and emerge with an empty extraction. Always verify the `language` field in the response.

---

### `tldr hubs` — most-central functions in the call graph

Top-N most-central functions in the call graph, ranked by a composite of in-degree, out-degree, PageRank, and betweenness.

**Why reach for it**:
- Discovers candidate "choke point" functions WITHOUT needing a function name to start with
- Composite score and `risk_level` (LOW/MEDIUM/HIGH/CRITICAL) give an immediate prioritization signal
- `--algorithm` lets the caller pick the centrality lens: `indegree` (called by many), `pagerank` (called by important callers), `betweenness` (bottlenecks)
- Best path-error UX in the entire CLI — passing a file instead of a directory yields a friendly recovery hint

**When to use**:
- Picking refactor or test-coverage targets and need data on what matters most
- Looking for architectural bottlenecks before a redesign
- Want the executive summary of the call graph, not the whole graph

**When NOT to use**:
- You already have a function name and want its neighborhood — use `tldr impact <fn>`
- Need the full edge list for visualization — use `tldr calls -f dot`
- Ranking by code complexity, not network position — use `tldr complexity`

**Usage**:
```bash
tldr hubs <directory> [-n <top>] [--algorithm indegree|pagerank|betweenness|composite] [-f json|text|dot]
```

**Output**: JSON with `hubs[]` (each entry has function ref, composite score, per-algorithm metrics, risk level), `total_nodes`, `measures_used`, and `pagerank_info` when applicable.

**Killer detail**: `-f dot` does NOT emit a call graph — it emits the top hubs as standalone labeled boxes chained by invisible edges to force Graphviz into a vertical list. **For a real DOT call graph, use `tldr calls -f dot` instead.**

---

### `tldr coupling` — function-call coupling between modules

Dual-mode function-call coupling analyzer — pairwise for two files, or project-wide with Robert Martin afferent/efferent/instability metrics plus cycle detection.

**Why reach for it**:
- Project-wide mode produces canonical `martin_metrics` (Ca, Ce, instability) — the SOLID-principles answer to "how tangled is each module?"
- Pair mode returns the actual `a_to_b` and `b_to_a` call lists with caller/callee/line, so the verdict is auditable
- `--cycles-only` filters to dependency cycles — usually the highest-priority architectural fix
- Best-in-class error UX: bad inputs return a message that documents BOTH usage modes inline

**When to use**:
- Auditing inter-module dependencies after a refactor and want Martin metrics
- Investigating whether two files are too entangled (pair mode with `<FILE_A> <FILE_B>`)
- Hunting CALL-graph cycles via `--cycles-only`
- Building a "most unstable modules" backlog (`--top N` ranks by instability)

**When NOT to use**:
- Want IMPORT-graph coupling rather than function-call coupling — use `tldr deps` (the `--help` says so explicitly)
- Want intra-class structure — that's `tldr cohesion`

**Usage**:
```bash
tldr coupling <PATH_A> [PATH_B] [--top N] [--cycles-only]
```

**Output**: TWO different JSON schemas. Pair mode returns `{ path_a, path_b, a_to_b, b_to_a, total_calls, coupling_score, verdict }`. Project-wide mode returns `{ martin_metrics: { metrics:[{module, ca, ce, instability, in_cycle}], cycles, summary }, pairwise_coupling: {...} }`.

**Killer detail**: The output schema flips entirely based on whether `PATH_B` is supplied — agents must branch on the presence of the `martin_metrics` key (project mode) versus `path_a` (pair mode) before parsing. Single-file `PATH_A` with no `PATH_B` is rejected outright with the audit suite's best error, documenting both modes.

---

### `tldr deps` — module-level import graph

Module-level import graph for a project — files and the files they import — with cycle detection, optional package collapsing, and first-class Graphviz output.

**Why reach for it**:
- One of the few tldr commands that emits DOT format (`-f dot | dot -Tsvg`) for architecture diagrams
- `--show-cycles` collapses the response to just the cycle list — perfect for a CI "are there import cycles?" gate
- `--collapse-packages` flips file nodes into package nodes for high-level architectural views
- `--include-external` surfaces third-party dependencies alongside internal ones

**When to use**:
- Mapping module IMPORTS as a graph (NOT call relationships — that's `tldr coupling`)
- CI cycle gate: `tldr deps . --show-cycles -f compact | jq 'length > 0'`
- Generating an architecture diagram for docs/onboarding via DOT output
- Auditing third-party dependency creep with `--include-external`

**When NOT to use**:
- Tracking which functions call which functions — use `tldr coupling` (CALL graph) or `tldr calls`
- Listing the imports of a single file — use `tldr imports` (per-file LIST)
- Mapping class inheritance — use `tldr inheritance` (in `tldr-audit-api`)

**Usage**:
```bash
tldr deps <path> [--show-cycles] [--collapse-packages] [--include-external] [-f json|compact|dot]
```

**Output**: JSON with `root`, detected `language`, `internal_dependencies` keyed by relative filename, optional `external_dependencies`, a `circular_dependencies` array, and a `stats` block with file/edge/cycle counts. With `-f dot`, you get a `digraph deps { ... }` block ready to pipe into Graphviz.

**Killer detail**: `--show-cycles` returns a **bare array — NOT the full `DepsReport` envelope**. The schema diverges based on the flag; downstream consumers expecting `.stats` will break when `--show-cycles` is on.

---

### `tldr cohesion` — LCOM4 within a single class

LCOM4 analyzer that measures whether the methods inside a single class actually share state — and, when they don't, hands back the exact method groupings to split into.

**Why reach for it**:
- `lcom4 = 1` means "cohesive"; `lcom4 > 1` means the class has methods that don't touch any shared fields — concrete split candidates
- When verdict is `"split_candidate"`, the engine pre-computes `components[].methods` AND a `split_suggestion` string — the refactor plan is in the output
- Operates per-class with union-find on the method↔field graph, so the answer is structural rather than heuristic
- Bounded by hard limits (`MAX_METHODS_PER_CLASS`, 30s timeout)

**When to use**:
- Reviewing a god class and want a defensible "split into these N groups" recommendation
- Auditing whether classes follow the Single Responsibility Principle
- Identifying utility classes masquerading as cohesive ones
- A counterpart to `tldr coupling` for the classic "high cohesion, low coupling" check

**When NOT to use**:
- Need module-level dependency analysis (between classes/files) — that's `tldr coupling`
- Want generic anti-pattern detection across many smell types — `tldr smells --deep` includes cohesion (see `tldr-audit-smells`)

**Usage**:
```bash
tldr cohesion <path> [-l <lang>]
```

**Output**: A `classes[]` array — each entry has `lcom4`, `method_count`, `field_count`, `verdict` (`"cohesive"` or `"split_candidate"`), `components[]` with explicit method/field groupings, and an actionable `split_suggestion` string when applicable — plus a `summary` rollup.

**Killer detail**: **It is Python-only despite accepting `--lang`.** The parser hardcodes `tree_sitter_python::LANGUAGE`, so `--lang typescript` is silently ignored and returns whatever Python classes exist (or empty silently on a non-Python tree). Three distinct failure modes (empty dir, non-Python file, Python file with no classes) all produce the identical empty shape with no `warnings`.

---

### `tldr clones` — project-wide duplication detector

Token-based all-vs-all duplication detector that finds copy-pasted code grep can't catch — different identifiers, different literals, same structure.

**Why reach for it**:
- Catches Type-1 (exact), Type-2 (renamed identifiers), and Type-3 (gapped/parameterized) clones that line-diff tools miss entirely
- One of only two audit commands that emits SARIF — drops directly into GitHub code scanning and VS Code
- `--threshold` knob lets the agent dial precision/recall from "exact duplicates only" (0.99) to "every pair" (0.0)
- Each `ClonePair` ships with both fragments, a similarity score, and a human `interpretation` string

**When to use**:
- Surfacing copy-paste tech debt across files (especially after merges or vendoring)
- Tracking propagation of a known vulnerable snippet — find every clone of the bad pattern
- Pre-refactor scan: "what other places use this same shape and should change with it?"
- CI integration where SARIF output feeds GitHub/IDE scanners

**When NOT to use**:
- Comparing two specific files or functions — `tldr dice` is the pair-target sibling (see `tldr-locate-code`)
- Semantic similarity (different shape, same intent) — `tldr similar` uses embeddings instead of tokens

**Usage**:
```bash
tldr clones <path> [--threshold 0.0-1.0] [--type-filter type1|type2|type3] [--normalize <mode>] [-f json|sarif]
```

**Output**: A `CloneDetectionReport` with `clone_pairs[]` (each `id`, `clone_type`, `similarity`, two `Fragment`s with file/lines/preview, and `interpretation`), plus `stats`, `config` echo, and triple-mirrored top-level `total_clones`/`files_analyzed` for jq convenience.

**Killer detail**: **Non-existent paths return exit 0 with a valid empty report** — there is NO upfront path validation, so `tldr clones /no/such/dir` looks the same as a successful scan that found zero clones. **Always inspect `files_analyzed > 0`** to distinguish "scanned and found nothing" from "path didn't exist."

**Other footguns**:
- Detection is O(N²); scope to subdirectories. A 4-file `providers/` runs in ~1s, but a full 56-file `backend/` exceeds 30s.
- `--type-filter wat` and `--normalize wat` silently fall back to defaults — both fields are `String`, not typed enums, so typos disappear.

---

### `tldr temporal` — implicit call-order / lifecycle protocol mining

Mines method-call sequences across a codebase and reports which methods are typically called before which — the implicit lifecycle protocol the code follows.

**Why reach for it**:
- FP-Growth-style sequence mining surfaces "A before B" patterns no per-file analysis can find
- Each constraint comes with `support`, `confidence`, and concrete `examples: [{file, line}]` — actionable, not abstract
- `--include-trigrams` extends to 3-method sequences for fuller protocol shapes (e.g., `connect → query → close`)
- Catches lifecycle protocols other audit tools miss: builder patterns, init/teardown ordering, acquire/release pairs

**When to use**:
- Reverse-engineering an API's expected call order ("how do callers usually use this library?")
- Looking for resource lifecycle bugs at the project level (pair with `tldr resources` for the per-file CFG view)
- Auditing whether a new code path follows the same `before → after` pattern as existing call sites
- Inferring builder/fluent-API protocols by querying a specific method's typical predecessors

**When NOT to use**:
- Need the call graph (who-calls-whom) rather than call ordering — that's `tldr calls`
- Per-file resource leak detection — `tldr resources` does CFG-based leak analysis
- Files that *change* together in git history (NOT what this tool does) — see `tldr-audit-smells` for churn/hotspots

**Usage**:
```bash
tldr temporal <path> [--source-lang python|rust|typescript|auto] [--include-trigrams] [--query <method>] [--min-support N] [--min-confidence 0.0-1.0]
```

**Output**: A `constraints` array of bigrams (each with `before`, `after`, `support`, `confidence`, examples), an optional `trigrams` array for 3-method sequences, and metadata reporting `files_analyzed` and `sequences_extracted`.

**Killer detail**: **`--source-lang` defaults to a hardcoded `"python"` (not auto-detect)** — the ONLY tldr command with a non-auto language default. **Non-Python repos get silent empty results unless `--source-lang <lang>` or `--source-lang auto` is passed.**

**Other footguns**:
- `-f compact` returns PRETTY JSON, not single-line (same quirk as `tldr taint` and `tldr resources`). Pipe through `jq -c` if compact is actually needed.
- `--query <method>` is EXACT MATCH against qualified `before`/`after` names, not substring search. Use `jq '.constraints[] | select(.before | contains("X"))'` for fuzzy lookups.

## Common mistakes

- **Using `tldr coupling` to find import cycles — the #1 cross-tool confusion in this skill.** Coupling traces FUNCTION CALLS, not imports. Coupling's `--help` itself redirects to `tldr deps` for the import-graph case. **Import cycles → `tldr deps . --show-cycles`. Call-graph cycles → `tldr coupling --cycles-only`.** Different graphs, usually different problems. An LLM that reaches for `coupling` because the word matches "dependencies" gets call coupling and falsely concludes "no import problems" while the import graph is on fire.
- **Using `tldr deps` to learn which functions are important.** Deps is FILE-level imports; it has nothing to say about which functions matter. For function-importance use `tldr hubs` (centrality on the call graph). Same word ("dependencies") points at two different graphs.
- **Using `tldr hubs` and expecting the full call graph.** Hubs returns ranked NODES with centrality scores, not edges. For a visual call graph, use `tldr calls -f dot`. **`tldr hubs -f dot` does NOT emit the call graph** — it emits hubs as boxes chained by invisible edges.
- **Reaching for `tldr structure` when you only need files** (or `tldr tree` when you need definitions). Tree is a pure filesystem walk; structure parses ASTs. Use tree to find files, structure to find what's in them.
- **Running `tldr cohesion --lang typescript` (or any non-Python lang).** Python-only despite accepting `--lang`; the flag is silently ignored. On non-Python trees it returns empty `classes[]` with no `warnings`. If you need cohesion findings on TS/Rust, you cannot get them from this tool today.
- **Running `tldr clones` on a full backend.** Detection is O(N²); scope to subdirectories. Medium backends (~50 files) routinely blow the 30s timeout. Also: **non-existent paths return exit 0 with a valid empty report** — check `files_analyzed > 0`.
- **Running `tldr temporal` on a non-Python repo without `--source-lang`.** It defaults to hardcoded `python` (unique among tldr commands), so a Rust/TS repo returns silent empty results. Always pass `--source-lang <lang>` or `--source-lang auto`.
- **Confusing `tldr temporal` (call ORDER mining) with git-history co-change.** Temporal mines "method A is called before method B" patterns from source code — NOT "file A and file B change together in git commits." For the git-history view (churn × complexity hotspots, co-change), see `tldr-audit-smells`.
- **Parsing `tldr coupling` output without branching on mode.** The schema flips on `PATH_B`: pair mode returns `{ path_a, path_b, a_to_b, b_to_a, ... }`; project-wide mode returns `{ martin_metrics: {...}, pairwise_coupling: {...} }`. Branch on the presence of `martin_metrics` vs `path_a` before parsing.
- **Parsing `tldr deps --show-cycles` as a `DepsReport`.** That flag returns a bare array, not the envelope. Code reaching for `.stats` will break when `--show-cycles` is on. Branch on the flag.
- **Trusting `tldr tree` filters on a warm daemon cache.** Cached `FileTree` is returned as-is; `--ext` / `--include-hidden` are NOT re-applied. Stop the daemon or expect the full cached tree. (Tree itself lives in `tldr-orient-codebase`, but the gotcha matters whenever you start an architecture walk from it.)

## See also

- `tldr-orient-codebase` — when the intent is a first-pass codebase tour (tree → structure → extract → importers/imports), not an architecture deep-dive
- `tldr-audit-smells` — when the intent is "what needs cleanup" (smells, debt, hotspots, **churn / files that change together in git history**) rather than "how is it structured"
- `tldr-trace-relationships` — once `tldr hubs` identifies a load-bearing function and the next question is "who calls it / what depends on it" (`tldr impact`, `tldr calls`, `tldr references`)
- `tldr-change-impact` — once a module is named and the question becomes "what will break if I change this"
- `tldr-audit-api` — for inheritance hierarchies (`tldr inheritance`), API surface, and pattern detection (the class-design axis this skill doesn't cover)
- `tldr-understand-function` — once you have a specific function name and want its signature, callers, callees, or extracted file inventory
