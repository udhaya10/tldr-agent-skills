# tldr debt

**Pitch**: SQALE technical-debt aggregator that converts every rule violation into estimated remediation minutes and rolls them up per file, per category, and project-wide.

**Why reach for it**
- `debt_minutes` per finding is a single comparable scalar — far easier to prioritize than mixed metric scores
- Optional `--hourly-rate $N` turns the rollup into a monetized estimate for stakeholder conversations
- Six SQALE categories (`reliability, security, maintainability, efficiency, changeability, testability`) give axis-aware filtering
- `top_files[]` ranked by total minutes is a ready-made refactor backlog

**When to use**
- Need one number to track "how much debt do we have?" across releases or teams
- Building a CI dashboard that surfaces top debtor files and their cost
- Want category-scoped audits (`--category security` for an outage post-mortem, `--category maintainability` for a refactor sprint)
- Comparing two directories or branches by aggregate remediation effort

**When NOT to use**
- Need per-finding anti-pattern names with line numbers — that's `tldr smells`
- Want the *bug-risk* signal that combines complexity with how often code changes — `tldr hotspots`

**Output in plain words**: A `DebtReport` with per-violation `issues[]` (file, line, element, rule, message, category, debt_minutes), a `--top`-truncated `top_files[]` ranked by total minutes, and a `summary` with totals plus `by_category`, `by_rule`, `by_severity`, `debt_ratio`, `debt_density`.

**Killer detail**: Passing a single FILE as PATH silently returns an empty result with `language: null` and exit 0 — the analyzer walks directories only, with no upfront `is_file()` check. Always pass a directory, and verify `issues.length > 0` to detect this silent failure.

**Source**: `research/tldr/audit/debt.md`
