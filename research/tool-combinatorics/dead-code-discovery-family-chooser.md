# Lens: Dead-code discovery — family chooser

**The question this lens answers**: "I want to find code that's safe to delete — which of `dead`, `dead-stores`, `references` do I reach for, and how do I avoid deleting something that isn't actually dead?"

**Toolset** (spans multiple groups): `tldr dead` (trace), `tldr dead-stores` (deep), `tldr references` (trace)

**Why a family-chooser lens, why these tools**: All three answer "what's unused," but the CLI splits them by *level of analysis* — `dead` is a call-graph op (trace), `dead-stores` is SSA dataflow inside one function (deep), `references` is a symbol-usage walk (trace). From the agent's point of view they're one family: **discover, verify, then clean up granular**. Treating them as separate group concerns is how you delete a public export by accident or hand-grep for assignments the compiler already proved dead.

## Decision tree

| You want to find... | Granularity | Reach for | Then verify with |
|--------------------|-------------|-----------|------------------|
| Whole functions that look unreachable | Function-level, project-wide | `tldr dead` | `tldr references <name>` per candidate |
| Variable assignments whose values are never read | Assignment-level, single function | `tldr dead-stores -F <file> -F <fn>` | (none — SSA is exact; opt into `--compare` for live-vars cross-check) |
| Whether ONE named symbol is actually dead | Symbol, project-wide | `tldr references <name>` directly | — |

## The default

This family does not have a single-tool default — it has a **mandatory workflow**:

1. **`tldr dead`** to discover candidates. Treat output as a hypothesis list, not a delete list.
2. **`tldr references <name>`** on every `possibly_dead` candidate before deletion. `possibly_dead` means "exactly one identifier reference exists in the codebase" — and that one reference is the function's own definition. Public exports, reflection-called code, framework callbacks, and decorated routes all legitimately land there. Skip this verification and you will delete live code.
3. **`tldr dead-stores`** only after function-level deletions, when scrubbing wasted assignments inside a surviving function.

If the question is narrower — "is THIS one function unused?" — skip `dead` and go straight to `references`.

## Common mistakes

- **Deleting a `possibly_dead` candidate without running `references`.** The #1 way this family produces regressions. `dead` is discovery; `references` is the verdict. Whitelist real entry points via `--entry-points name1,name2,...` once identified.
- **Reaching for `dead-stores` when you meant `dead`** (or vice versa). `dead-stores` is per-function and finds unused *assignments*; `dead` is project-wide and finds unused *functions*. Wrong granularity, silent disappointment.
- **Treating `references` as recursive.** It's flat — level 1 only. For caller-of-caller chains, escalate to `tldr impact`. For dead-code verification, level 1 is exactly right.
- **Trusting `references --scope workspace` blindly.** The engine silently auto-narrows to `file` when the symbol looks file-local. Always read the `search_scope` field — a "1 reference" result under a narrowed scope is not project-wide.
- **Scripting around `dead-stores` exit codes assuming the deep-group convention.** It returns exit 1 on function-not-found, not exit 20 — it lives in the contracts namespace with its own error enum.

## What this lens captures

- The level-of-analysis split (project / function / symbol) is the right axis; picking becomes mechanical once internalized.
- Framing `dead` + `references` as a *workflow* rather than alternatives — the safety story is load-bearing.

## What this lens misses

- **Why** a function is dead historically — archaeology needs `tldr churn` + git log.
- **Whole-module** dead code (is this file importable but never imported?) — use `tldr importers <module>`.
- **Dead code introduced by the current diff** — pair `tldr change-impact` with a fresh `dead` run.

## Pair with

- `change-impact-family-chooser.md` — the blast-radius family, the other side of "is this safe to remove?"
- `understanding-a-function-family-chooser.md` — once a candidate is identified, `tldr explain` clarifies what you're about to delete

## Sources

- `research/tool-cards/trace/dead.md`
- `research/tool-cards/trace/references.md`
- `research/tool-cards/deep/dead-stores.md` *(note: lives in the deep group, but functionally belongs to this family — it's the assignment-level companion to `dead`'s function-level view)*
