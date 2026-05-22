# Lens: Deep data flow — family chooser

**The question this lens answers**: "I want a compiler-grade data-flow answer — which of `slice`, `chop`, `reaching-defs`, `available`, `dead-stores` is the right query for the question I actually have?"

**Toolset**: `tldr slice`, `tldr chop`, `tldr reaching-defs`, `tldr available`, `tldr dead-stores`

**Why a family-chooser lens, why these tools**: All five sit on the same internal CFG/DFG engine, but each answers a *different* dataflow question. The discriminator is the **shape of the question**, not the shape of the code: how many criterion points you have, whether you care about variables or expressions, and whether you're asking "where did this come from?" or "is this ever read?". Picking the wrong one wastes the call — the engines are precise, but they only answer the question you actually pose.

## Decision tree by question shape

| You're asking... | About... | Anchor points | Reach for |
|------------------|----------|---------------|-----------|
| "What lines (transitively) affect / are affected by this one?" | Lines | 1 criterion line | `tldr slice` |
| "What lines lie on the dependency path from A to B?" | Lines | 2 criterion lines | `tldr chop` |
| "For this USE of variable X, which DEFs could be its source?" | Variables | 1 function (optionally filter by var / line) | `tldr reaching-defs` |
| "Which expressions are already computed and still valid here?" | Expressions | 1 function (optionally `--check`/`--at-line`) | `tldr available` |
| "Which assignments are written but never read?" | Variables | 1 function | `tldr dead-stores` |

## The default

**`tldr slice` is the default first move** for the generic "what depends on this line?" question. It is the only deep-group command with a daemon cache (repeat queries are fast), and the direction knob (`-d backward|forward`) covers both "where did this value come from?" and "if I edit here, what breaks?". Escalate from there:

- Have **two endpoints** instead of one → `tldr chop` (intersection of forward and backward slices)
- Question is **about a variable's origin**, not a line → `tldr reaching-defs`
- Question is **about expressions** (CSE, redundancy) → `tldr available`
- Question is **"are any assignments wasted?"** → `tldr dead-stores`

## Common mistakes

- **Reaching for `tldr slice` when there are two endpoints.** Running slice twice and intersecting by hand is what `chop` already does in one call; the result is identical and you avoid an arithmetic error.
- **Confusing `available` with `reaching-defs`.** They look similar but answer different questions: `reaching-defs` is variable-centric ("which defs of `x` reach here?"), `available` is expression-centric ("is `a + b` already computed?"). If the question names a variable, use reaching-defs; if it names an expression, use available.
- **Treating a `chop` exit code as a success signal.** Exit code is 0 on every failure mode (function-not-found, line out of range, no PDG anchor). Branch on `path_exists` and read `explanation` — not on exit code.
- **Picking a `chop` line inside a docstring, brace, or multi-line continuation.** Those lines have no PDG node — `path_exists` will be false even when the line is "in" the function. Use `tldr extract` or a quick `tldr slice` first to find PDG-anchored lines.
- **Trusting `tldr available` on Python.** The AST extractor is conservative on dynamic-typed code; expect mostly empty `redundant_computations` lists. The tool shines on Rust / C / C++ / Go / TypeScript.
- **Trying to disable `--show-chains` or `--show-uninitialized` on `reaching-defs`.** Both are clap-rejected (exit 2) because of a `default_value = "true"` quirk. Both flags are always on; JSON output always carries the full report regardless.
- **Assuming consistent exit codes across deep-group commands.** `dead-stores` returns exit 1 on function-not-found while the other four return exit 20 (it lives in a different Rust error namespace). Cross-command scripting cannot rely on `exit 20 == not found`.

## What this lens captures

The question-shape discriminator (points vs variables vs expressions) is durable. Once internalized, the table above picks the right tool by the noun in the question, not by reading the help text again.

## What this lens misses

- **Cross-function dataflow.** All five are intra-function. Cross-function reasoning needs `tldr impact` (caller tree) or `tldr references` (use sites) first, then drop into deep on the target function.
- **Whole-file or whole-project dead code.** `dead-stores` is store-level inside one function; for unused *functions*, reach for `tldr dead`.
- **Security taint.** "Does untrusted input reach a sink?" looks like a chop but the right answer is `tldr taint` / `tldr secure` — taint tracking is a different engine.

## Pair with

- `understanding-a-function-family-chooser.md` — how to get the function name and bounds before posing a deep query
- `trace-relationships-family-chooser.md` — what to do BEFORE deep when the question crosses function boundaries

## Sources

- `research/tool-cards/deep/slice.md`
- `research/tool-cards/deep/chop.md`
- `research/tool-cards/deep/reaching-defs.md`
- `research/tool-cards/deep/available.md`
- `research/tool-cards/deep/dead-stores.md`
