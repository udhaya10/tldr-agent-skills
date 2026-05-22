# Lens: Change impact — family chooser

**The question this lens answers**: "I want to know what a change will break — which of `change-impact`, `impact`, `whatbreaks` fits what I have in hand?"

**Toolset** (spans multiple groups): `tldr change-impact` (ops), `tldr impact` (trace), `tldr whatbreaks` (trace)

**Why a family-chooser lens, why these tools**: All three answer "what does this affect," but the CLI splits them by *starting point*, not intent. `change-impact` lives in ops because it consumes a git delta (a CI/workflow surface); `impact` lives in trace because it walks the call graph backward from one symbol; `whatbreaks` lives in trace as a dispatcher that auto-routes any target type. From the agent's point of view they're one family — picking is a function of what you already have. Treating them as separate group concerns is how agents end up running `change-impact` with no git baseline, or hand-grepping a diff for function names to feed `impact`.

## Decision tree

The discriminator is **starting point × direction**:

| You have... | You want... | Reach for | Direction |
|-------------|-------------|-----------|-----------|
| A git diff (or `-F` file list) | Affected tests/functions, optionally as a runner-ready command | `tldr change-impact` | Files → tests, forward |
| A function name | Recursive caller tree — every caller-of-caller up to `--depth` | `tldr impact` | Symbol → callers, reverse |
| A target you're not sure how to classify | A unified summary that auto-routes | `tldr whatbreaks` | Auto-dispatched per detected type |

## The default

No universal default — pick by what's in hand:

- **Have git changes** (PR, uncommitted diff, feature branch) → `tldr change-impact`. It's the only one that consumes a delta natively.
- **Have a function name and want blast radius** → `tldr impact`. Skip the wrapper — `whatbreaks` would just route here anyway and add overhead.
- **Target type is ambiguous** (e.g., an identifier that might be a function OR a module) → `tldr whatbreaks`. Its `detection_reason` field shows how it classified the input, so misroutes are debuggable.

`whatbreaks` is the meta-dispatcher; the others are specialized. Fallback, not habit.

## Common mistakes

- **Reaching for `change-impact` when you have a function name, not a diff.** It wants files; feeding it function names ends in empty `changed_files`. Use `impact`.
- **Reaching for `impact` when you have a set of changed files.** You'd have to grep symbols out of the diff first. Skip the manual step — `change-impact` walks the diff directly.
- **Trusting `whatbreaks` auto-detect on dotted Python module paths** like `backend.providers.base` — misclassified as `function` when the first segment isn't a real directory. Pass `--type module`. Same for bare filenames like `base.py` (no `/` → misclassified). Pass `--type file`.
- **Trusting `whatbreaks` exit code 0.** Sub-analysis failures are buried in `sub_results.<analysis>.success: false` while the wrapper still exits 0. Inspect each sub-result's `success` flag.
- **Using `change-impact -F` on a mixed-language repo without `-l <lang>`.** Language autodetect runs even on explicit file lists; `-F backend/foo.py` on a TS-dominant repo silently returns empty.
- **Trusting `impact --depth N` on Python** (or C#, Kotlin, Scala, OCaml, Lua). The references-enrichment fallback only fills in level 1. Look for `"Discovered via references"` notes to confirm depth was ignored.

## What this lens captures

- The starting-point × direction axis is the durable discriminator — "what do you have going in?" picks correctly even when new siblings land.
- The wrapper-vs-specialist tradeoff: `whatbreaks` saves orchestration when target type is ambiguous, but costs latency and a misleading exit code when it isn't.

## What this lens misses

- **Reverse direction from a file** (who imports this file?) — that's `tldr importers`.
- **Whole-project hub identification** — `tldr hubs` ranks by centrality, not by impact of one target.
- **Why a change is risky** beyond who-calls-whom — cohesion, coupling, historical churn are different lenses.

## Pair with

- `dead-code-discovery-family-chooser.md` — the other side of "is this safe to remove?"
- `understanding-a-function-family-chooser.md` — once you've identified a high-impact function, `tldr explain` clarifies what's inside it

## Sources

- `research/tool-cards/ops/change-impact.md` *(note: lives in the ops group, but functionally belongs to this family — it's the git-delta starting-point sibling to `impact` and `whatbreaks`)*
- `research/tool-cards/trace/impact.md`
- `research/tool-cards/trace/whatbreaks.md`
