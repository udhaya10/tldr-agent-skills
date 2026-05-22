# Lens: Audit smells & debt — family chooser

**The question this lens answers**: "I want to know what's wrong with this codebase — which of `smells`, `debt`, `hotspots`, `churn` should I run?"

**Toolset**: `tldr smells`, `tldr debt`, `tldr hotspots`, `tldr churn`

**Why a family-chooser lens, why these tools**: These four are NOT four views of the same data — they emit four genuinely different signals. The discriminator is **what signal does the audience need**: anti-pattern names with line numbers, monetizable remediation minutes, bug-risk via churn × complexity, or raw git frequency. Picking by overlap (they all "find problems") collapses the distinction that's actually load-bearing.

## Decision tree

| You need to answer... | The signal is... | Reach for |
|-----------------------|------------------|-----------|
| "What concrete anti-patterns exist, and where?" | Per-finding name (god class, long method, feature envy) + file/line/severity | `tldr smells` |
| "How much would it cost to fix it all?" / "Which file owes us the most time?" | SQALE remediation minutes per file, monetizable with `--hourly-rate` | `tldr debt` |
| "Where will the next bug land? What should we refactor first?" | Churn × complexity multiplicative bug-risk score per file or function | `tldr hotspots` |
| "What files change most in the last quarter?" / "Who touches this code?" | Raw git frequency, line deltas, author rollup, language-agnostic | `tldr churn` |

## The default

**`tldr hotspots` for "what should we refactor first?" — the most common framing.** It is the single most actionable refactor signal in the audit suite: complex AND actively changing = highest bug-risk per hour invested. The per-entry `recommendation` string drops straight into an LLM prompt, and `--by-function` collapses to per-function granularity when "which file" isn't specific enough. Escalate to `tldr smells` when the audience wants named anti-patterns (a refactor backlog needs reason strings, not scores), to `tldr debt` when the audience is non-technical and needs minutes/dollars, and to `tldr churn` when the question is genuinely about git activity with no complexity weighting needed.

## Common mistakes

- **Using `tldr churn` to pick refactor targets.** Raw change frequency without complexity weighting is noise — a config file edited every commit isn't a refactor target. `tldr hotspots` multiplies churn by complexity for the actual bug-risk signal. Churn alone is for activity reports, not prioritization.
- **Expecting `tldr smells --smell-type low-cohesion` to work without `--deep`.** Eight smells (`low-cohesion`, `tight-coupling`, `dead-code`, `code-clone`, `high-cognitive-complexity`, `middle-man`, `refused-bequest`, `inappropriate-intimacy`) are deep-only. The advisory warning that normally nudges toward `--deep` is SUPPRESSED once `--smell-type` is set, so you get silent empty results. Always pass `--deep` when using one of those eight smell types.
- **Passing a single FILE to `tldr debt`.** It silently returns empty with `language: null` and exit 0 — the analyzer walks directories only, with no upfront `is_file()` check. Always pass a directory, and check `issues.length > 0` to detect this silent failure.
- **Running `tldr hotspots` on an empty directory and being surprised by exit 1.** Hotspots errors with `"Not a git repository"` on empty dirs, while `tldr churn` on the same input returns exit 0 with a special-case empty stub. Two adjacent commands, opposite contract — branch on exit code if you can't guarantee the path.
- **Setting `tldr hotspots --since 2024-Q1` or any non-ISO date.** The field is `Option<String>` with NO validation — invalid values are silently dropped and the call returns unfiltered results. Use strict `YYYY-MM-DD`.
- **Expecting `tldr hotspots --days 30` to actually restrict to 30 days.** It is mostly subsumed by the `--recency-halflife 90` decay; commits older than ~270 days contribute under 12.5% weight regardless. Set `--recency-halflife 0` to actually disable decay.
- **Stacking `tldr smells` + `tldr debt` + `tldr hotspots` blindly into one "audit" call.** They overlap meaningfully (smells feeds debt, complexity feeds hotspots). Pick by which signal the AUDIENCE needs; don't ship all three to a reviewer who just wanted a refactor target.

## What this lens captures

- The "four signals, not four views" framing is durable — once internalized, the picker is just "what does the audience need."
- The default-to-hotspots rule covers the most common framing (refactor prioritization) without manual orchestration.

## What this lens misses

- **Per-function complexity dimensions in isolation.** `tldr cognitive`, `tldr complexity`, `tldr halstead` measure WITHOUT the change-frequency multiplier — covered in the complexity-metrics family chooser.
- **Co-change patterns.** "Which files change *together*" (temporal coupling, hidden dependencies) is `tldr temporal`, not in this family.
- **Structural-quality signals.** Cohesion-inside-a-class, coupling-between-modules, duplication-across-the-project are their own family chooser.

## Pair with

- `audit-complexity-metrics-family-chooser.md` — the complexity dimension that `hotspots` rolls into a single score
- `audit-structural-quality-family-chooser.md` — cohesion/coupling/clones answer "where is the structure bad," not "where will bugs land"

## Sources

- `research/tool-cards/audit/smells.md`
- `research/tool-cards/audit/debt.md`
- `research/tool-cards/audit/hotspots.md`
- `research/tool-cards/audit/churn.md`
