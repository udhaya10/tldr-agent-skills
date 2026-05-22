# Lens: Locator showdown — family chooser

**The question this lens answers**: "I need to find code about X — should I reach for the search group (`search`, `semantic`, `similar`, `dice`, `context`) or the overview group's locators (`extract`, `definition`, `explain`)?"

**Toolset** (spans multiple groups): `tldr search`, `tldr semantic`, `tldr similar`, `tldr dice`, `tldr context` (search group); `tldr extract`, `tldr definition`, `tldr explain` (overview group); cross-ref: `tldr references` (trace group, for usages of a known symbol).

**Why a family-chooser lens, why these tools**: The CLI splits these tools across THREE groups, but from the agent's point of view they're two different jobs accidentally rendered as eight commands. The search group answers **"WHERE in the project does this concept/token live?"** — discovery from a query. The overview locators answer **"GIVEN a function name (or cursor), what does it look like?"** — inspection from a known starting point. The within-family choosers (`locating-code-family-chooser.md`, `understanding-a-function-family-chooser.md`) discriminate within each side cleanly. This doc discriminates BETWEEN the two sides — the call agents botch when they pull the wrong family entirely and waste an entire round-trip.

## Decision tree

The discriminator is **do you have a starting point already, or are you looking for one?**

| What you have going in | What you want | Reach for | Group |
|------------------------|---------------|-----------|-------|
| A vague idea (no name, no file) | Candidates to investigate | `tldr search` (if any shared vocabulary) or `tldr semantic` (if none) | search |
| One known example fragment | Other code like it | `tldr similar` | search |
| Two known fragments | A similarity score | `tldr dice` | search |
| A FILE you want to learn about | Its function/class roster + intra-file call graph | `tldr extract` | overview |
| A FUNCTION NAME you want to drill into | Signature, purity, complexity, callers, callees | `tldr explain` | overview |
| A CURSOR (file + line + col) | The binding site of that symbol | `tldr definition` | overview |
| A FUNCTION + its callees as one bundle | A markdown pack for handoff to another model | `tldr context` | search (but functionally an overview locator) |
| A KNOWN SYMBOL NAME and want every use site | Flat list of references classified call/read/write/import/type | `tldr references` | trace |

## The default

**If you have a name, cursor, or file path — use the overview locators. If you have only an idea, use the search group. There is no universal default across the two sides — the discriminator is unambiguous.**

Tie-breakers when the input is ambiguous:

- "I have a string that might be a function name OR a concept term" → run `tldr search "<token>"` first. If results are non-empty, you have a name; pivot to `tldr explain` or `tldr extract`. If empty AND you suspect vocabulary mismatch, fall back to `tldr semantic`.
- "I have a file path and want to know what concept lives there" → `tldr extract` first (inventory the file), THEN `tldr semantic -p <file>` if you still don't recognize what it does.

## Common mistakes

- **Reaching for the wrong group entirely — the #1 failure mode.** Running `tldr search "rate limiter"` when you ALREADY have `RateLimiter.acquire()` in hand wastes a query and returns the function you knew about. Conversely, running `tldr extract <file>` when you don't know which file the concept lives in produces a roster of names you can't connect to anything. **Starting point determines side; ignore the CLI group structure when picking.**
- **Reaching for `tldr explain` to inventory a file.** Explain takes one name; you'd be guessing. Use `tldr extract` for "what's in this file" and pivot to explain once a name catches your eye.
- **Reaching for `tldr semantic` before `tldr search`.** Semantic is slower, less deterministic, and worse than search whenever any shared vocabulary exists. Semantic earns its keep only when the agent's terms (`"billing logic"`) genuinely don't appear in the code (`ChargeProcessor.run`).
- **Reaching for `tldr search` to find usages of a KNOWN symbol.** Search returns ranked function cards, not a flat use-site list. For "every place `foo` is called/read/written," use `tldr references foo` — AST-verified, kind-classified, and the right tool for the question.
- **Using `tldr context` as a search tool.** Context is for handoff — it packs an entry function plus its transitive callees into one markdown bundle and requires the entry name. If you reach for it during discovery, you're in the wrong family.

## What this lens captures

- The starting-point discriminator (idea vs name/cursor/file) is durable — it picks the right SIDE even when new siblings land in either group.
- The cross-group callout: `tldr context` is shelved in the search group but functions as an overview locator; `tldr references` is shelved in trace but is the right answer to "find every use site of a known symbol." Treating group membership as functional taxonomy is the trap this doc exists to short-circuit.

## What this lens misses

This lens picks SIDE; it doesn't fully discriminate within either side. For within-side choices:

- **Within the search group** (which of `search` / `semantic` / `similar` / `dice`?) — see `locating-code-family-chooser.md`.
- **Within the overview locators** (which of `definition` / `explain` / `extract` / `context`?) — see `understanding-a-function-family-chooser.md`.
- **Chained workflows** — sometimes `semantic` first to learn the vocabulary, THEN `search` exhaustively on the discovered terms is right. Family-choosers don't surface chains.

## Pair with

- `locating-code-family-chooser.md` — within-family chooser for the search side
- `understanding-a-function-family-chooser.md` — within-family chooser for the overview locators
- `trace-relationships-family-chooser.md` — what to do after locating, when the next question is "who uses this?"

## Sources

- `research/tool-cards/search/search.md`
- `research/tool-cards/search/semantic.md`
- `research/tool-cards/search/similar.md`
- `research/tool-cards/search/dice.md`
- `research/tool-cards/search/context.md`
- `research/tool-cards/overview/extract.md`
- `research/tool-cards/overview/definition.md`
- `research/tool-cards/overview/explain.md`
- `research/tool-cards/trace/references.md` *(cross-reference for "usages of a known symbol")*
