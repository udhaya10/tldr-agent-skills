# tldr hotspots

**Pitch**: Adam-Tornhill-style churn × complexity ranker that points to the files (or functions) where bugs cluster — the highest-payoff refactor targets.

**Why reach for it**
- The single most actionable refactor signal in the audit suite: complex AND actively changing = highest bug risk per hour invested
- `recommendation` strings per entry (`"Critical: High churn + high complexity + fragmented knowledge..."`) drop straight into LLM prompts
- `--by-function` collapses the analysis to per-function granularity — actionable for "which function in this file" rather than just "which file"
- `knowledge_fragmentation` surfaces tribal-knowledge debt (high author dispersion + high churn)

**When to use**
- Picking refactor targets and want the highest bug-risk-per-hour file or function
- Investigating a production incident — hotspots tend to be where the regression came from
- Building a quarterly tech-debt plan; want a defensible "attack these N files first" list
- Want to combine git frequency with complexity in one shot rather than running and joining two commands

**When NOT to use**
- Just want raw git frequency without complexity weighting — use `tldr churn`
- Need the SQALE minutes rollup for cost reporting — use `tldr debt`

**Output in plain words**: A ranked `hotspots[]` (each with `churn_score`, `complexity_score`, `hotspot_score`, `commit_count`, `complexity`, `knowledge_fragmentation`, `author_count`, `recommendation`), plus a `summary` of corpus stats and `metadata` echoing the `scoring_weights` and algorithm version.

**Killer detail**: Empty directories ERROR OUT with exit 1 and `"Not a git repository"` — diverging from `tldr churn`'s graceful exit-0 empty-dir special case. Two adjacent commands, same input, opposite behavior.

**Other footguns**
- `--since <invalid-date>` is silently dropped — the field is `Option<String>` with no validation, so a typo returns the unfiltered default with no warning. Use strict ISO `YYYY-MM-DD`.
- `--days N` is mostly subsumed by `--recency-halflife 90` decay — commits older than ~270 days contribute under 12.5% weight regardless. Set `--recency-halflife 0` to actually disable decay.

**Source**: `research/tldr/audit/hotspots.md`
