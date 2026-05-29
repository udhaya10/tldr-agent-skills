---
name: tldr-change-impact
description: Figure out what will break if a change ships — map a git diff to affected tests, walk the reverse call graph from a function to find every caller-of-caller, or auto-dispatch when the target type is ambiguous. Reach for this BEFORE editing a hot symbol, BEFORE merging a PR, or whenever you'd otherwise eyeball "is this safe to change." Triggers on "what will break if I change", "impact of this change", "what tests will be affected", "is it safe to change", "blast radius of this change", "show me what changed between", "diff this against", "what does this PR affect".
allowed-tools: [Bash]
compatibility: "Requires tldr-code CLI v0.4.0+. Tested on darwin and linux."
metadata:
  version: "1.0.0"
  author: "udhaya10"
  repository: "udhaya10/tldr-agent-skills"
  tldr.cli-version: "0.4.0"
  tldr.research-commit: "a025973"
  tldr.commands-wrapped: "change-impact, impact, whatbreaks, diff"
---

# tldr-change-impact

## When to use

Use this skill whenever the question is **"what will be affected if this changes?"** — whether the "this" is a git delta (PR, uncommitted edits, feature branch), a single function name you're about to refactor, or an identifier you can't quite classify yet. All four tools in this skill answer the same intent, but they expect different starting points.

The discriminator vs sibling skills:

- For tracing call/usage relationships **with no change involved** (just "who calls X?") → see `tldr-trace-relationships`. The `impact` tool also lives there because it's load-bearing for pre-refactor risk too.
- For "what BUGS did my change introduce" rather than "what will my change affect" → see `tldr-fix-and-detect`.
- For warming the daemon before running impact-heavy queries on a cold cache → see `tldr-runtime`.

If you don't have a change to analyze AND you don't have a target symbol, you're upstream of this skill — locate the code first via `tldr-locate-code`.

## The decision — which tool to use

The discriminator is **starting point × direction**, not what you want out.

| You already have... | And you want... | Reach for | Direction |
|---------------------|-----------------|-----------|-----------|
| A git diff (PR, uncommitted edits, `--base origin/main`) or an explicit `-F` file list | Affected tests/functions, optionally as a runner-ready command string | `tldr change-impact` | Files → tests, forward |
| A function name | Recursive caller tree — every caller-of-caller up to `--depth`, with blast-radius totals | `tldr impact` | Symbol → callers, reverse |
| A target you can't classify (could be function, file, or module) | A unified summary with auto-routing and a `detection_reason` field | `tldr whatbreaks` | Auto-dispatched per detected type |
| Two specific files or directories | A structural diff at function/class/module/architecture granularity | `tldr diff` | Snapshot A vs snapshot B |

**Defaults by starting point** (no universal default — the question literally has no answer until you say what you have):

- **Have git changes** → `tldr change-impact`. It's the only one that consumes a delta natively. Don't grep symbols out of the diff first.
- **Have a function name** → `tldr impact`. Skip the wrapper — `whatbreaks` would just route here anyway and add overhead.
- **Target type is ambiguous** → `tldr whatbreaks`. Its `detection_reason` field shows how it classified the input, so misroutes are debuggable.
- **Want to see the changes themselves** (not "what they affect") → `tldr diff`. This is the "what changed" tool, not the "what'll break" tool.

`whatbreaks` is the meta-dispatcher; the others are specialized. Fallback, not habit.

## Tool reference

> **Command guardrail**: Only invoke the exact subcommands documented below. Do **not** invent or guess command names. If uncertain whether a command exists, run `tldr --help` before proceeding.

### `tldr change-impact` — git diff → affected tests

Maps a git diff (or explicit file list) to the test files and functions affected by those changes, optionally emitting a runner-ready test command for direct CI integration.

**Why reach for it**:
- Replaces a full test-suite run with a focused subset on PR CI
- `--runner pytest|jest|cargo-test|go-test|pytest-k` emits a paste-ready CLI string — no glue script needed
- Walks the call graph forward from changed code to identify ripple-affected tests, not just touched files
- Distinct exit code 3 for "no git baseline" surfaces the recoverable failure mode immediately

**When to use**:
- Setting up PR CI: `tldr change-impact --base origin/main --runner pytest | xargs pytest`
- Want to know which tests a refactor will invalidate before running anything
- Reviewing a PR and need to focus attention on the test files in scope

**When NOT to use**:
- Tracing blast radius from a single function — use `tldr impact` (per-symbol, no git involved)
- Need the test-affected list with full mapping back to which change caused which test — use `tldr whatbreaks`
- Comparing two specific files structurally — use `tldr diff`

**Usage**:
```bash
tldr change-impact [path] [--base <ref>] [-F <file>...] [-l <lang>] [--runner pytest|jest|cargo-test|go-test|pytest-k]
```

**Output**: JSON with `changed_files`, `affected_tests`, `affected_test_functions`, `affected_functions`, a `detection_method` tag, call-graph metadata, and a status block. With `--runner X` the JSON is replaced by a single runner-formatted command string (empty when nothing is affected).

**Killer detail**: `-F` explicit files don't override language autodetect — on a TypeScript-dominant repo, `-F backend/foo.py` silently returns `changed_files: []` because the Python files don't exist in the TS call graph. **Always pair `-F` with `-l <lang>`.**

**Other footguns**:
- Exit 3 is unique to git-baseline failures (bad `--base`, non-git dir, empty repo); the error string includes a built-in "Try `--files <path>` or `--base <ref>`" hint — branch on exit 3 to fall back to explicit `-F`.
- Passing a file as PATH gives a best-in-class custom error ("change-impact requires a directory") instead of the cryptic upstream git error.

---

### `tldr impact` — recursive reverse call graph for one function

Recursive reverse call graph for one function — every caller, every caller-of-caller, up to `--depth`, with blast-radius totals.

**Why reach for it**:
- Single command answers "if I change this signature, who breaks?" — recursive, not flat
- Function-not-found errors include "Did you mean:" suggestions (exit 20) — agents can parse and retry
- `-f dot` emits a real reverse Graphviz graph (`rankdir=RL`); pipe to `dot -Tpng` for a picture
- Auto-recovers cross-file edges the AST builder misses via a references-enrichment fallback

**When to use**:
- About to change a function's signature, return type, or delete it
- Need to enumerate the transitive caller tree, not just direct callers
- Pre-refactor risk assessment on a known function name

**When NOT to use**:
- Want a flat list of EVERY use site (calls, reads, writes, imports) — use `tldr references` (in `tldr-trace-relationships`)
- Don't know the function name yet — discover it via `tldr search` (in `tldr-locate-code`) or `tldr hubs` (in `tldr-architecture`) first
- The whole project's edges — `tldr calls` (forward) or `tldr hubs` (centrality summary), both in sibling skills

**Usage**:
```bash
tldr impact <function-name> [path] [-l <lang>] [--depth <n>] [-f json|dot|text]
```

**Output**: JSON `targets` map keyed by `"file:function"` (one symbol can resolve in multiple files), each with `caller_count` and a recursive `callers[]` tree carrying `note` fields that mark when results came from the references-enrichment fallback.

**Killer detail**: On Python (and C#, Kotlin, Scala, OCaml, Lua), `--depth` is silently a no-op — the AST call graph misses cross-file edges, the references-enrichment fallback fills them in but only at level 1. **Watch for `"Discovered via references"` notes in the output to confirm depth is being ignored.** `--type-aware` is registered but unimplemented; ignore it.

---

### `tldr whatbreaks` — auto-dispatching blast-radius wrapper

One-shot blast-radius wrapper that auto-detects whether the target is a function, file, or module and dispatches to the right sub-analysis.

**Why reach for it**:
- Replaces a 2–3 step `extract → impact → importers` workflow with one invocation
- `detection_reason` field explains how the target was classified — debuggable when auto-detect misfires
- `--quick` skips the slow `change-impact` pass and roughly halves runtime on file targets
- Aggregates the underlying analyses into one `summary` row with caller, importer, and test-impact counts

**When to use**:
- Have a target identifier but aren't sure whether it's a function name, file path, or module path
- Want a unified "what will this change touch?" summary for a code review or PR description
- Need callers AND importers AND test fan-out in a single JSON for downstream tooling

**When NOT to use**:
- You already know it's a function — call `tldr impact <fn>` directly and skip the wrapper overhead
- You already know it's a module — call `tldr importers <module>` directly (in `tldr-orient-codebase`)
- Need per-caller detail in text form — text mode is just 4 summary lines; use JSON

**Usage**:
```bash
tldr whatbreaks <target> [path] [--type function|file|module] [--quick] [-f json|text]
```

**Output**: JSON with `target_type`, `detection_reason`, a `sub_results` object (one entry per dispatched analysis, each in a `{success, data|error, elapsed_ms}` envelope), and a flat `summary` of aggregate counters.

**Killer detail**: **Exit code 0 does NOT mean the analysis succeeded** — sub-analysis failures (e.g., "Function not found") are buried in `sub_results.<analysis>.success: false` while the wrapper exits 0. Agents MUST inspect each sub-result's `success` flag; the process exit code is misleading.

**Other footguns**:
- Dotted Python module paths like `backend.providers.base` are auto-classified as `function` when the first segment isn't a real directory under PATH. Always pass `--type module` for dotted paths.
- Bare filenames without `/` (e.g., `base.py`) are also misclassified as functions. Pass `--type file` explicitly.

---

### `tldr diff` — AST-aware structural diff between two snapshots

AST-aware structural diff between two files (or two directories at file/module/architecture granularity) — understands functions, classes, imports, and architectural layers, not just text.

**Why reach for it**:
- Eight granularity levels from `token` up through `architecture`, each tuned to a different review intent
- `--semantic-only` strips formatting/whitespace noise — exactly what PR review wants
- Module-level diff yields a unique `import_graph_summary` (edges added/removed); architecture-level yields a `stability_score`
- `--granularity` errors list all 8 valid values inline — discoverable without re-reading help

**When to use**:
- Reviewing a refactor and want to see renames/moves/extracts as first-class change types, not as line edits
- Comparing two versions of a class or module at the right abstraction level
- Architecture audit: `-g architecture` reports `cycles_introduced` and `cycles_resolved` between two directory snapshots
- CI gate for module-level import changes: pipe L7 output through jq

**When NOT to use**:
- Diffing git refs against working tree — use `git diff` directly, or feed change-detection through `tldr change-impact`
- Finding similar code across one tree — use `tldr clones` (in `tldr-architecture`)
- Asking "what will break" — `diff` shows you the changes, not their downstream effects

**Usage**:
```bash
tldr diff <file_a|dir_a> <file_b|dir_b> [-g token|line|statement|function|class|file|module|architecture] [--semantic-only] [-f json|text]
```

**Output**: JSON with `file_a`, `file_b`, `identical`, a `changes` array tagging each as insert/delete/update/move/rename/format/extract, a `summary` block of per-type counts, and the `granularity` echoed back. L6/L7/L8 extend the schema with file/module/arch-specific sections.

**Killer detail**: `-g token` (L1) produces ~17,000 lines of stdout for two small files — token diffs are almost never what you want. **The default `-g function` (L4) is the sweet spot**; reach for L5+ for higher-level reviews and L3 only when L4 hides too much.

## Common mistakes

- **Reaching into the wrong group entirely.** The #1 footgun: using `change-impact` when you have a function name (it wants a diff; feeding it function-name strings ends in empty `changed_files`), or using `impact` when what you have is a set of git-changed files (you'd have to grep symbols out of the diff first — skip that, use `change-impact`).
- **Trusting `whatbreaks` exit code 0.** Sub-analysis failures (e.g., "Function not found") are buried in `sub_results.<analysis>.success: false` while the wrapper still exits 0. Inspect each sub-result's `success` flag, not the process exit.
- **Trusting `whatbreaks` auto-detect on dotted Python module paths** like `backend.providers.base` — misclassified as `function` when the first segment isn't a real directory. Pass `--type module`. Same for bare filenames like `base.py` (no `/` → misclassified). Pass `--type file`.
- **Using `change-impact -F` on a mixed-language repo without `-l <lang>`.** Language autodetect runs even on explicit file lists; `-F backend/foo.py` on a TS-dominant repo silently returns empty.
- **Trusting `impact --depth N` on Python** (or C#, Kotlin, Scala, OCaml, Lua). The references-enrichment fallback only fills in level 1. Look for `"Discovered via references"` notes to confirm depth was ignored — and don't claim deep transitive coverage on those languages.
- **Reaching for `tldr diff` to answer "what will break."** Diff shows you the structural changes between two snapshots — it does NOT walk the call graph. Pair it with `change-impact` (for git deltas) or `impact` (for the symbols diff surfaces) when the real question is downstream effects.
- **Reaching for `tldr diff -g token`.** ~17,000 lines of stdout for two small files. Stick to the default `-g function` (L4) unless you have a specific reason to climb to L5+ or drop to L3.
- **Skipping `whatbreaks` when you genuinely don't know the target type.** Running `impact` on a module path or `change-impact` on a single function name both fail silently in their own ways. When in doubt, let `whatbreaks` classify — then drop down to the specialist on the next call.

## See also

- `tldr-trace-relationships` — for the broader "trace relationships" intent when there's no change involved (callers, references, dead code). The `impact` tool lives there too because it's load-bearing for both intents.
- `tldr-fix-and-detect` — when the question is "what bugs did my change introduce" rather than "what will my change affect"
- `tldr-runtime` — for diagnosing daemon health and cache state before running impact-heavy queries. The supervisor daemon (`tldr-cli-demon`) handles warming automatically
- `tldr-orient-codebase` — `tldr importers` answers the reverse-from-a-file question (who imports this file?) that `impact` can't
- `tldr-architecture` — `tldr hubs` ranks the whole project by centrality, complementing per-target impact analysis
