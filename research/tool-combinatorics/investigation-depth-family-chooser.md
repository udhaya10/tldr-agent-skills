# Lens: Investigation depth — family chooser

**The question this lens answers**: "I'm investigating a function's behavior — should I stay at the call-graph level (`impact`, `calls`, `references`) or escalate into variable/expression-level data flow (`slice`, `chop`, `reaching-defs`, `available`, `dead-stores`)?"

**Toolset** (spans multiple groups): `tldr impact`, `tldr calls`, `tldr references` (trace group); `tldr slice`, `tldr chop`, `tldr reaching-defs`, `tldr available`, `tldr dead-stores` (deep group).

**Why a family-chooser lens, why these tools**: The CLI splits these by engine — trace tools walk the AST call graph at function-relationship granularity, deep tools walk the per-function CFG/PDG at variable/expression granularity. From the agent's point of view there's one decision: **am I asking a question about call paths, or about values?** Trace answers "what calls what." Deep answers "where did this value come from, which lines mathematically influence this point." Pull deep when trace would have sufficed and you've spent compiler-grade resources on a question grep could have answered; stop at trace when the question was actually about a wrong value and you'll wander the call tree forever without ever looking at the line that corrupts the answer.

## Decision tree

The discriminator is **granularity of the question** — not the size of the codebase, not how "thorough" you want to be.

| The question is about... | Granularity | Reach for | Group |
|--------------------------|-------------|-----------|-------|
| Which functions call (or are called by) which | Function-to-function relationships | `tldr calls` (project graph), `tldr impact` (one function's callers), `tldr references` (one symbol's use sites) | trace |
| Which LINES influence (or are influenced by) THIS line | Statement-level, intra-function | `tldr slice` | deep |
| Which lines lie on the path from A to B | Statement-level, two anchors | `tldr chop` | deep |
| Which assignments could be the source of this variable's value here | Variable-level, intra-function | `tldr reaching-defs` | deep |
| Which expressions are already computed here (CSE) | Expression-level, intra-function | `tldr available` | deep |
| Which assignments are written but never read | Variable-level, intra-function | `tldr dead-stores` | deep |

## The default

**Start with trace. Escalate to deep only when the question becomes about a specific value, line, or variable INSIDE a function.**

Trace is cheaper, broader, and project-wide; deep is precise but intra-function and only answers if you can name a function plus (usually) a line or variable. The escalation path:

1. **`tldr impact <fn>` or `tldr references <name>`** — if the question is "what depends on this?" or "where is this touched?", trace closes the loop. Done.
2. **`tldr explain <fn>` (cross-family)** — if the question is "what does this function do?", overview's `explain` gives signature + purity + complexity + both call directions in one shot. Still no need for deep.
3. **`tldr slice` / `tldr reaching-defs`** — escalate only when trace has handed you a function name and the next question is "why does THIS line produce THAT value?" or "where did variable X get its value from at line N?"
4. **`tldr chop`** — when you have TWO specific lines and want the minimal set worth inspecting between them.

The signal that you should have escalated earlier: you've spent five trace calls chasing a caller tree, and the bug is actually that some assignment inside one function clobbers a value. Trace will never find that; deep will, immediately.

The signal that you escalated too early: you ran `tldr slice` on a function you don't yet know is even on the call path. Slice can only answer intra-function questions, so it can't help you decide whether to be in this function at all.

## Common mistakes

- **Reaching for deep when trace would have answered — the #1 failure mode.** "Who calls `process_order`?" is `tldr impact process_order`, not slice. Deep is intra-function; if the question crosses function boundaries, deep can't reach it. Agents who default to deep because it sounds more rigorous burn compiler-grade resources on questions that needed an AST walk.
- **Stopping at trace when the question was actually about a value.** Symmetric failure: an agent asks "what calls `foo`?" five times trying to figure out why `foo` returns the wrong number, when the answer is that line 47 inside `foo` overwrites the result before return. `tldr slice -F <file> -F <fn> -L 47 -d backward` finds it in one call. **When the question turns from "where is X used" to "why is X wrong here," cross the trace→deep boundary.**
- **Trusting `tldr impact --depth N` on Python.** On Python (also C#, Kotlin, Scala, OCaml, Lua) `--depth` is silently a no-op — the references-enrichment fallback fills cross-file edges only at level 1. Watch for `"Discovered via references"` notes before reporting a depth-N tree.
- **Treating `tldr chop` (or `tldr slice` on out-of-range lines) exit code as a success signal.** Exit is 0 on every failure mode in both. Branch on `path_exists: true` for chop; read the `explanation` field for slice. Also: lines inside docstrings, braces, or multi-line continuations have no PDG node and return empty results — use `tldr extract` first to find PDG-anchored lines.
- **Trusting `tldr available` on Python.** The AST extractor is conservative on dynamic-typed code; expect mostly empty `redundant_computations`. Available shines on Rust / C / C++ / Go / TypeScript.

## What this lens captures

- The trace→deep boundary is a real boundary: cross-function vs intra-function, function-relationship vs value-relationship. Naming it explicitly prevents both kinds of misreach.
- An escalation discipline — trace first, deep only when the question collapses to a single function and becomes about a specific value or line. Defaults to the cheaper engine and saves deep for questions it uniquely answers.

## What this lens misses

This lens picks SIDE (trace vs deep); it doesn't fully discriminate within either side.

- **Within trace** (`calls` / `impact` / `references` / `hubs` / `dead` / `whatbreaks`) — see `trace-relationships-family-chooser.md`, `change-impact-family-chooser.md`, `dead-code-discovery-family-chooser.md`.
- **Within deep** (`slice` / `chop` / `reaching-defs` / `available` / `dead-stores`) — see `deep-data-flow-family-chooser.md`.
- **Taint/security flows.** "Does untrusted input reach a sink?" looks like a `chop`, but `tldr taint` / `tldr secure` is the right engine (audit security family).
- **Choosing a starting function in the first place.** Neither family helps — start with `locator-showdown-family-chooser.md`, then return here.

## Pair with

- `trace-relationships-family-chooser.md` — within-family chooser for `calls` / `references` / `impact`
- `deep-data-flow-family-chooser.md` — within-family chooser for `slice` / `chop` / `reaching-defs` / `available` / `dead-stores`
- `change-impact-family-chooser.md` — when the trace-side question is specifically "what will this change break"
- `understanding-a-function-family-chooser.md` — when the question is "what does this function do" before deciding whether to go deeper

## Sources

- `research/tool-cards/trace/impact.md`
- `research/tool-cards/trace/calls.md`
- `research/tool-cards/trace/references.md`
- `research/tool-cards/deep/slice.md`
- `research/tool-cards/deep/chop.md`
- `research/tool-cards/deep/reaching-defs.md`
- `research/tool-cards/deep/available.md`
- `research/tool-cards/deep/dead-stores.md`
