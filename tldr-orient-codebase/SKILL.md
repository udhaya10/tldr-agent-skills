---
name: tldr-orient-codebase
description: Orient in an unfamiliar codebase — get the forest-to-leaf tour without a specific target in mind. Reach for this whenever the user wants a tour, onboarding, or general layout discovery rather than locating a specific concept. Replaces hours of grep-and-read with a progressive zoom from filesystem to API surface to dependency edges. Triggers on "I'm new to this codebase", "help me orient", "explore this repo", "what's in this project", "show me the structure", "tour of", "onboarding", "get familiar with", "give me the layout", "where do I start".
allowed-tools: [Bash]
compatibility: "Requires tldr-code CLI v0.4.0+. Tested on darwin and linux."
metadata:
  version: "1.0.0"
  author: "udhaya10"
  repository: "udhaya10/tldr-agent-skills"
  tldr.cli-version: "0.4.0"
  tldr.research-commit: "a025973"
  tldr.commands-wrapped: "tree, structure, extract, importers, imports"
---

# tldr-orient-codebase

## When to use

Use this skill when the user (or the agent) is starting from **zero context** on a codebase and wants a **general tour**, not a targeted lookup. The signal is "I don't have a specific symbol or concept in mind yet — I just need a mental model."

The discriminator vs sibling skills:

- For a specific concept the user wants to find ("where is billing handled") → see `tldr-locate-code`
- For a question framed as layers, coupling, or design boundaries → see `tldr-architecture`
- For diving into a specific function after orienting → see `tldr-understand-function`

If the user has already named a file, function, or concept, this skill is the wrong door — pick one of the siblings above.

## The approach — canonical vs rapid lens

Two flows share the same toolset. Pick the lens by **how much time the orientation task has**, not by what the user said. If the user said "give me a quick tour" or implied a time-box, use rapid. If the user said "I want to really understand this codebase" or there's no time pressure, use canonical.

### Canonical lens — "I have the time to do this properly"

The textbook progressive-zoom flow: **forest → tree → branch → leaf**. Each step's output feeds the next. Don't skip steps under this lens.

1. **`tldr tree -e <lang>`** — get the file inventory, scoped to one language. Reveals directory layout, `.gitignore`-clean. Confirms what kind of project this is (monorepo, single service, library).
2. **`tldr structure <dir>`** — get the function/class roster across the files identified in step 1. Per-file definition lists with line numbers. This is where the API surface becomes visible.
3. **`tldr extract <file>`** — for the 3–5 files that look most important from structure (high definition density, or located in `core/`, `lib/`, `services/`, `domain/` paths), get the full intra-file picture including the local call graph.
4. **`tldr importers <module>` and `tldr imports <file>`** — for the modules that look load-bearing, see the dependency direction. `importers` reveals who depends on this (blast radius if changed); `imports` reveals what it depends on (its own surface area).

What this captures: complete coverage of the important parts, a hierarchy in your head that mirrors the codebase's actual structure, cheap at the front and expensive only where it matters.

What this misses: time-boxed efficiency (use rapid for that), hot-spot prioritization (needs churn/complexity tools from other skills), the architectural cut (see `tldr-architecture`).

### Rapid lens — "I have ~60 minutes, give me the highest-signal tour"

Skip the filesystem-only step. Signal density per minute is highest at the API surface. The discipline is **highest signal first, accept the coverage gap**.

1. **`tldr structure <project> -l <dominant-lang>`** — one call, every function and class across the project with line numbers. Pass `-l` explicitly to avoid the auto-detect-picks-wrong-language silent failure.
2. **Scan output for "anchor files"** — files with many definitions, files in `core/` / `lib/` / `services/` / `domain/` paths, files referenced often in import statements. These are the project's spine. Usually 3–5 files; never more than ~10.
3. **`tldr extract <anchor-file>` × 3** — pick the top 3 anchor files and get the full intra-file call graph for each. That's the architectural skeleton.
4. **Stop.** Resist drilling further until you've started actual work. Orientation is for triage, not mastery.

What this captures: highest-density signal in the shortest time (`structure` + 3 `extract` calls is usually 20–30 minutes of real work), enough mental model to start triaging real questions, avoids the "I read every file" trap.

What this misses: filesystem surprises (unusual layouts, build artifacts in source dirs), 80% of files by coverage, dependency direction. If layout or dependencies matter to the task, switch to canonical.

> **The #1 rapid-lens mistake: cargo-culting `tldr tree` before `structure`.** Tree adds nothing for time-boxed orientation — `structure` already gives file paths via the line-number locations on every definition. Running tree first burns 5–10 minutes for zero new signal. Only run tree under the canonical lens, or when filesystem layout is itself the question.

## Tool reference

### `tldr tree` — `.gitignore`-clean recursive file listing

Recursive directory listing that respects `.gitignore` by default and returns structured JSON nodes — no AST, just files.

**Why reach for it**:
- One call replaces `ls -R` plus a hand-written ignore filter — `node_modules`, `.venv`, build outputs are excluded automatically
- Structured JSON is `jq`-navigable; no parsing ASCII tree output
- `--ext` is repeatable and tolerant (`.py` and `py` both work) for quick language-scoping
- Cheap — pure filesystem walk, no tree-sitter cost

**When to use** (canonical lens only):
- First discovery step on an unfamiliar repo
- Picking which files to feed into `tldr structure`, `tldr extract`, or downstream tools
- Need a `.gitignore`-clean file enumeration filtered by extension

**When NOT to use**:
- Need to know what's *defined* in the files (functions, classes) — use `tldr structure`
- Targeting an unfiltered full repo — output explodes (~13k lines on a mid-size repo); always scope with `--ext` or a subdirectory
- Under the rapid lens — skip directly to `tldr structure`

**Output**: A recursive node tree where directories carry a `children` array and files carry a `path`, with `name` and `type` on every node. Empty filter results return a dir node with empty `children`, not an error.

**Killer detail**: When the daemon cache is warm, the cached `FileTree` is returned as-is and `--ext` / `--include-hidden` flags are NOT re-applied. For predictable filtering, run against a stopped daemon or expect the full cached tree.

---

### `tldr structure` — function/class/import inventory across many files

Function, class, and import inventory of a file or directory — tree-sitter parsed, with line numbers, across every source file in the target.

**Why reach for it**:
- Replaces "read 50 files to learn what exists" with one JSON call
- Aggregates across a whole directory; `tldr extract` only handles one file at a time
- Returns line numbers needed by `slice`, `impact`, and `extract` follow-ups
- Daemon cache properly partitions on language, so repeat queries are cheap and correct

**When to use**:
- Onboarding a new codebase and need the API roster across many files
- Picking high-value files to drill into with `tldr extract` next
- Need function/class locations across a directory in one shot
- **First call under the rapid lens** (with `-l <lang>` explicit)

**When NOT to use**:
- Just want to know which files exist — use `tldr tree` (no parsing cost)
- Want full function bodies and intra-file call graph — use `tldr extract` on the chosen file
- Targeting a multi-thousand-file repo without scoping — output explodes; pass a subdirectory or `-m N`

**Output**: A record per file listing its classes (with methods), top-level definitions, module-level methods, and imports. Empty directories return a `warnings` array rather than an error.

**Killer detail**: When language detection fails (unknown extension, mixed-language dir), the parser silently falls back to Python — a non-Python file may be analyzed as Python and emerge with an empty extraction. **Always verify the `language` field in the response**, and prefer passing `-l <lang>` explicitly on the first call.

---

### `tldr extract` — full structural dump of one file

Full structural dump of a single file — every function, class, import, and the intra-file call graph — with line numbers.

**Why reach for it**:
- Replaces reading a 1000-line file just to learn what's defined in it
- Line numbers in the output unblock downstream tools that demand explicit `<line>` arguments
- Intra-file `call_graph` shows local function relationships without a project-wide build
- Daemon-cached on warm runs; cache key partitions correctly on language

**When to use**:
- Don't know the function name yet and need the file's inventory before drilling down
- Need line numbers for every function as input to other commands
- Want to see how functions in one file call each other
- **Step 3 of canonical lens or step 3 of rapid lens** — once anchor files are picked

**When NOT to use**:
- Already know the function name and want depth — see `tldr-understand-function`
- Need cross-file call relationships — see `tldr-trace-relationships`
- Target is a directory — use `tldr structure` instead (extract rejects directories with exit 11)

**Output**: A typed record per file with the function list (signatures and line numbers), class list with methods, import list, and a `caller → callee` map scoped to that file alone.

**Killer detail**: Passing `-l <lang>` bypasses the sibling-aware widening that makes `.h` files parse correctly in C++ projects. **Leave the flag off and let auto-detect read neighboring files** unless you have a verified reason to override. (Note: this is the opposite advice from `structure` and `importers` — `extract`'s auto-detect is sibling-aware and works correctly.)

---

### `tldr importers` — reverse module-lookup (who depends on this?)

Reverse module-lookup — finds every file in a path that imports a given module, with the verbatim import line and line number.

**Why reach for it**:
- Answers "who depends on this module?" in one call before a rename, deletion, or refactor
- Returns structured results with line numbers (unlike `tldr imports`, which lists modules without locations)
- Handles language-specific import syntax (Python dotted paths, TS specifiers, Go packages) — no grep regex juggling
- Daemon cache makes repeat queries effectively free

**When to use** (canonical lens, step 4):
- About to assess the blast radius of a load-bearing module
- Auditing the consumer list of a public API at module granularity
- Looking for every call site of a library import across a project

**When NOT to use**:
- Need usages of a *symbol* rather than a *module* — see `tldr-trace-relationships`
- Want the imports of one specific file — that's the mirror command `tldr imports`
- Under the rapid lens — orientation is over; importers belongs in change-impact follow-up

**Output**: The queried module name, an array of importing files each with their line number and the raw import statement, plus a `total` count that ignores `--limit` truncation.

**Killer detail**: On a mixed-language project root, auto-detect silently picks the dominant language and returns zero importers for a query in the *other* language — the Python fallback only triggers when detection returns None, not when it guesses wrong. **Pass `-l <lang>` explicitly or scope the PATH to a single-language subdirectory.**

---

### `tldr imports` — single-file import lister

Single-file import lister — returns the typed import statements of one source file.

**Why reach for it**:
- Parses multi-line and aliased imports correctly across languages, not just regex-matchable patterns
- Returns a typed JSON envelope (`{file, language, imports}`) ready to pipe into another tool
- Daemon route honors `--lang` correctly (unlike `tldr importers`, where the daemon drops the flag)
- `--legacy-array` toggle for `jq '.[]'` consumers — compatible on both cold and warm paths

**When to use** (canonical lens, step 4):
- Following the outward dependencies of one specific file
- Building a per-file module summary alongside `tldr extract`
- Traversing the import graph in tandem with `tldr importers` (the reverse direction)

**When NOT to use**:
- Need to know *who* imports a module — that's `tldr importers`
- Need line numbers for the import statements — `tldr imports` does NOT emit them; use `tldr importers <MODULE>` per module to recover locations
- Need the full file inventory (functions, classes) — use `tldr extract`

**Output**: A wrapper object with the file path, detected language, and an array of imports where each entry carries the module name, optional imported names for `from X import Y` style, an `is_from` flag, and an optional alias.

**Killer detail**: A wrong `-l <lang>` is a silent empty-array failure — `imports file.py -l typescript` returns `{language: "typescript", imports: []}` with exit 0. Both cold and warm-daemon paths share this trap. **Validate `imports.length > 0` or omit `--lang` entirely.**

## Common mistakes

- **Cargo-culting `tldr tree` before `tldr structure` under the rapid lens.** Tree adds zero new signal when time-boxed — structure already returns file paths via line-number locations. Only run tree first when filesystem layout is itself the question, or when operating under the canonical lens.
- **Skipping steps in the canonical flow.** Canonical is "broad-to-narrow with no skipping" — running `extract` on a hand-picked file without first seeing `structure` means anchor-file selection is guesswork. The funnel only works wide-at-the-top.
- **Drilling past step 4 of the rapid lens.** Rapid is for triage, not mastery. If the orientation keeps growing into a 20-file deep-dive, the task has changed from "orient" to "investigate" — pick a sibling skill (`tldr-locate-code`, `tldr-understand-function`) and proceed there.
- **Skipping `-l <lang>` on multi-language repos.** `structure`, `importers`, and `imports` all auto-detect language by dominant file count; a wrong guess is silent. `structure` falls back to Python and emerges with empty extractions; `importers` returns zero hits in the non-dominant language; `imports` returns `[]` with exit 0. Pass `-l` explicitly on the first call or scope the PATH to one language.
- **Passing `-l <lang>` to `tldr extract` reflexively.** Extract's auto-detect is sibling-aware (makes `.h` files in C++ parse correctly). Forcing the flag bypasses that widening. The pattern is opposite to `structure`/`importers`/`imports` — leave `-l` off for extract unless there's a verified reason.
- **Trusting an empty `tldr tree` after the daemon is warm.** Warm-cache responses skip `--ext` and `--include-hidden` re-application. If filtering is load-bearing, stop the daemon or expect the full cached tree.
- **Reaching for this skill when the user already named a target.** If they said "show me `parseConfig`" or "find the billing code," skip orientation entirely — see `tldr-understand-function` or `tldr-locate-code` directly.

## See also

- `tldr-locate-code` — when the user has a specific concept or symbol to find rather than wanting a general tour
- `tldr-architecture` — when the question is specifically about layers, coupling, hubs, or structure-as-design
- `tldr-understand-function` — when, after orienting, the user wants to dive into a specific function by name
- `tldr-trace-relationships` — when, after orienting, the user wants to see who calls or references a specific symbol
