# Lens: Audit complexity metrics — family chooser

**The question this lens answers**: "I want a complexity number — which of `cognitive`, `complexity`, `halstead` should I run?"

**Toolset**: `tldr cognitive`, `tldr complexity`, `tldr halstead`

**Why a family-chooser lens, why these tools**: All three reduce code to a complexity score, but each scores a different dimension at a different scope. The discriminator is **what you already know × which dimension you care about**: do you have ONE named function or a whole tree, and are you measuring control flow, human readability, or token vocabulary? Picking by name alone ("which is the complexity tool?") gets you the wrong scope half the time.

## Decision tree

| You already have... | And you want... | Dimension | Reach for |
|---------------------|-----------------|-----------|-----------|
| A directory or file with many functions | A ranked list of the worst offenders by readability | Cognitive complexity (SonarQube nesting penalty) across all functions | `tldr cognitive` |
| One specific function name | The four structural metrics in one cheap call | Cyclomatic + cognitive + max_nesting + LoC for one function | `tldr complexity` |
| A directory or file | Token-vocabulary effort, predicted bug count, or size-of-review estimate | Halstead volume / difficulty / effort / bugs | `tldr halstead` |
| A complex function and need to know WHY it's complex | Per-line breakdown of which `if`/`for`/`while` contributed | Cognitive contributors | `tldr cognitive --show-contributors` |

## The default

**`tldr cognitive <DIR> --include-cyclomatic` for the "find the worst functions" intent — that is the most common one.** It ranks every function in the path by cognitive score (which penalizes nesting more than cyclomatic does, better matching human "what is this doing?" effort) AND folds in cyclomatic in the same call, so two metrics arrive for the price of one. Escalate to `tldr complexity <file> <function>` only when the function is already named and the agent wants the daemon-cached sub-millisecond repeat path. Reach for `tldr halstead` when the question is specifically about size-effort, test-priority shortlists (the `bugs` field), or token-level evidence for a review.

## Common mistakes

- **Looping `tldr complexity` over every function in a directory to build a ranking.** Don't. `tldr cognitive <DIR>` already ranks every function in one call with the same canonical engine. The loop is slower AND loses the project-wide `summary` / `violations[]` rollup.
- **Reaching for `tldr complexity` to discover candidates.** Complexity is single-function and takes the name as a required positional. If the function name isn't already in hand, use `tldr cognitive` (for ranking) or `tldr extract` (for the file's roster) first.
- **Trusting `tldr cognitive` on an empty/wrong-language directory without checking `warnings[]`.** Three silent-empty modes return identical exit 0 with empty shapes: function-not-found, empty directory, and language-mismatch. ONLY the lang-mismatch case populates `warnings: ["No supported source files found in <path>"]`. Other empties look identical to a successful "found nothing."
- **Passing `-l typescript` to `tldr complexity` on a `.py` file.** It does NOT report a mismatch — the TS parser walks the Python source, fails to locate the function, and exits 20 with a misleading `"Function not found"`. When the language might be ambiguous, omit `-l` and trust auto-detect, or pass the file's actual language.
- **Treating Halstead's `bugs` field as a fault prediction.** It's `volume / 3000`, the classic Halstead estimate — useful as a relative shortlist ("test these first"), useless as an absolute count. Don't put it in a stakeholder report as "we have N bugs."
- **Assuming the three tools' cognitive scores might disagree.** They don't. `tldr complexity` and `tldr cognitive` share `tldr_core::calculate_complexity`. Pick by scope (one function vs many), not by hoping for a different number.

## What this lens captures

- The dimension × scope discriminator is durable: control-flow vs readability vs vocabulary × one function vs many is a 2×3 picker, never ambiguous once internalized.
- The cheap-vs-cheap distinction (cognitive ranks, complexity fills one cell, halstead is its own axis) keeps token cost minimal.

## What this lens misses

- **Bug-risk weighted by change frequency.** Complexity alone is half the signal; multiply by churn for actionable refactor targets — that's `tldr hotspots`, covered in the smells/debt family.
- **Monetizable remediation effort.** None of these three converts to remediation minutes; `tldr debt`'s SQALE rollup is the right tool for stakeholder-grade reporting.
- **Anti-pattern naming.** Complexity numbers don't say "this is a god class" or "this is feature envy" — `tldr smells` does.

## Pair with

- `audit-smells-debt-family-chooser.md` — for the bug-risk and monetizable-debt sibling signals
- `audit-structural-quality-family-chooser.md` — when the complexity question is actually about coupling/cohesion at the class or module level

## Sources

- `research/tool-cards/audit/cognitive.md`
- `research/tool-cards/audit/complexity.md`
- `research/tool-cards/audit/halstead.md`
