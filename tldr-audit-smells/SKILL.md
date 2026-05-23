---
name: tldr-audit-smells
description: Find code smells, technical debt, hotspots, and refactor priorities — answer "what should I clean up first" with named anti-patterns, monetizable remediation minutes, churn × complexity bug-risk scores, and resource-leak findings. Reach for this when the question is about code quality, cleanup, refactor backlogs, or where bugs are likely to land. Triggers on "code smells", "what needs cleanup", "technical debt", "refactor priorities", "where are bugs likely", "hotspots", "what's been changing", "resource leaks", "audit code quality", "code health", "what should I clean up first".
allowed-tools: [Bash]
compatibility: "Requires tldr-code CLI v0.4.0+. Tested on darwin and linux."
metadata:
  version: "1.0.0"
  author: "udhaya10"
  repository: "udhaya10/tldr-agent-skills"
  tldr.cli-version: "0.4.0"
  tldr.research-commit: "a025973"
  tldr.commands-wrapped: "smells, debt, hotspots, churn, todo, resources, health"
---

# tldr-audit-smells

## When to use

Use this skill for anything quality-related where the question is **"what's wrong / what should I clean up"**: code smells, technical debt, refactor priorities, churn-weighted bug risk, resource leaks, or a first-pass health dashboard for an unfamiliar codebase.

The discriminator vs sibling skills:

- For security findings (vulnerabilities, taint, injection) → see `tldr-audit-security`
- For pure complexity scores (cyclomatic, cognitive, Halstead, LOC) with no churn or smell layer → see `tldr-audit-complexity`
- For structural concerns (coupling, cohesion, hubs, layer violations, clone families across the project) → see `tldr-architecture`
- For finding dead code specifically, the dead-code-discovery workflow lives in `tldr-trace-relationships` (the `dead-code-discovery-family-chooser` lens)

## The decision — which tool to use

These seven tools emit **seven genuinely different signals**, not seven views of the same data. Pick by **what signal the audience needs**, not by overlap.

| You need to answer... | The signal is... | Reach for |
|-----------------------|------------------|-----------|
| "I don't know what dimension to look at — give me a triage dashboard" | Multi-analyzer rollup (complexity + cohesion + dead + coupling + similarity) | `tldr health` |
| "What concrete anti-patterns exist, and where?" | Per-finding name (god class, long method, feature envy) + file/line/severity | `tldr smells` |
| "How much would it cost to fix it all?" / "Which file owes us the most time?" | SQALE remediation minutes per file, monetizable with `--hourly-rate` | `tldr debt` |
| "Where will the next bug land? What should we refactor first?" | Churn × complexity multiplicative bug-risk score per file or function | `tldr hotspots` |
| "What files change most in the last quarter?" / "Who touches this code?" | Raw git frequency, line deltas, author rollup, language-agnostic | `tldr churn` |
| "Give me one prioritized refactor checklist for this file or directory" | Aggregated dead/complexity/cohesion/similar items with priority + score | `tldr todo` |
| "Are resources (files, sockets, locks) leaked or double-closed in this file?" | CFG-based per-path resource lifecycle bugs | `tldr resources` |

**Defaults — two-layer rule.** When the dimension is unknown (first-pass triage of an unfamiliar codebase, or "what's the worst part of this?"), reach for **`tldr health --quick --summary`** first — it runs six sub-analyzers in one call and tells you which dimension to drill into next. When the dimension is already "refactor prioritization" on a known repo (the most common framing), skip `health` and reach for **`tldr hotspots`** directly — complex AND actively changing = highest bug-risk per hour invested, and the per-entry `recommendation` string drops straight into an LLM prompt. Otherwise, pick by signal from the table above.

## Tool reference

> **Command guardrail**: Only invoke the exact subcommands documented below. Do **not** invent or guess command names. If uncertain whether a command exists, run `tldr --help` before proceeding.

### `tldr health` — one-shot multi-analyzer audit dashboard

One-shot code-quality dashboard that runs six sub-analyzers (complexity, cohesion, dead_code, martin, coupling, similarity) concurrently and returns a unified summary.

**Why reach for it**:
- The right FIRST command in any audit — `--quick --summary` triages a codebase in one call instead of running six tools and aggregating their JSON
- `--detail <analyzer>` drills into one sub-analyzer's full output after the summary flags a problem — single command for both triage and deep-dive
- `--quick` skips the expensive cross-file analyses (coupling + similarity) — usable on real codebases at interactive speeds
- Returns hotspot counts, dead-code percentage, and average cyclomatic in one block — the typical "is this codebase healthy?" headline

**When to use**:
- Starting any code audit cold — get the lay of the land before picking a specific tool
- Asked "what's the worst part of this codebase?" — summary surfaces hotspots and low-cohesion classes
- CI health gate that needs one number across several dimensions
- Routing decision: high `hotspot_count` → drill with `tldr-audit-complexity`; high `dead_percentage` → drill via the dead-code workflow in `tldr-trace-relationships`

**When NOT to use**:
- Already know the dimension (just complexity, just cohesion, just dead code) — call the specific tool; health adds latency for analyses you'll ignore
- Need security findings — health doesn't cover that surface; see `tldr-audit-security`
- Need constraint/spec coverage — that lives in `tldr-audit-coverage`

**Usage**:
```bash
tldr health [path] [--quick] [--summary] [--detail <analyzer>]
```

**Output**: A summary block with files/functions/classes analyzed, average cyclomatic, hotspot counts, dead-code percentage, and (in full mode) coupling/similarity pair counts. `--detail <name>` swaps the summary for one sub-analyzer's full per-item output.

**Killer detail**: Health is SLOW on real codebases — **9.7 seconds for 56 files even in `--quick` mode**, and there is **NO daemon caching**, so repeat calls recompute everything. Budget the latency and prefer `--quick --summary` for triage; only drop `--quick` when coupling/similarity numbers are actually needed.

---

### `tldr smells` — named anti-pattern detector with line numbers

AST-based code-smell detector that names the anti-pattern (god class, long method, deep nesting, etc.) with file, line, severity, and optional refactor suggestion.

**Why reach for it**:
- One pass covers 10 default detectors plus 8 more under `--deep` — no need to assemble a lint pipeline
- `severity` (1-3) per finding gives a built-in prioritization signal for top-N triage
- `--suggest` adds a refactor hint per smell, ready to feed to an LLM with the source location
- `--smell-type <X>` and `-t strict|default|relaxed` thresholds turn it into a focused single-rule check or a broad audit

**When to use**:
- Need to find concrete anti-patterns (god class, feature envy, data clumps) with line numbers, not just metric scores
- Building a refactor backlog and want ranked candidates with reason strings
- Running a pre-commit / code-review check for one specific smell on changed files
- Want one tool that aggregates cohesion + coupling + dead-code + clone signals (use `--deep`)

**When NOT to use**:
- Want a single monetizable "how much debt" number — `tldr debt` rolls smells into SQALE minutes
- Want the unwritten *conventions* the code follows rather than its anti-patterns — that lives in `tldr-audit-api`

**Usage**:
```bash
tldr smells [path] [--deep] [--smell-type <type>] [-t strict|default|relaxed] [--suggest]
```

**Output**: A `smells[]` array of findings (each with `smell_type` in snake_case, absolute `file` path, `name`, `line`, `reason`, `severity`), plus `by_file` counts keyed by absolute path, a `summary` rollup, and a `warnings[]` advisory nudging toward `--deep` when applicable.

**Killer detail**: Passing `--smell-type` for one of the 8 deep-only smells (`low-cohesion`, `tight-coupling`, `dead-code`, `code-clone`, `high-cognitive-complexity`, `middle-man`, `refused-bequest`, `inappropriate-intimacy`) WITHOUT `--deep` returns **silent empty results with no warning** — the gating advisory is suppressed once `--smell-type` is set. Always pair those eight with `--deep`.

---

### `tldr debt` — SQALE remediation-minutes rollup

SQALE technical-debt aggregator that converts every rule violation into estimated remediation minutes and rolls them up per file, per category, and project-wide.

**Why reach for it**:
- `debt_minutes` per finding is a single comparable scalar — far easier to prioritize than mixed metric scores
- Optional `--hourly-rate $N` turns the rollup into a monetized estimate for stakeholder conversations
- Six SQALE categories (`reliability, security, maintainability, efficiency, changeability, testability`) give axis-aware filtering
- `top_files[]` ranked by total minutes is a ready-made refactor backlog

**When to use**:
- Need one number to track "how much debt do we have?" across releases or teams
- Building a CI dashboard that surfaces top debtor files and their cost
- Want category-scoped audits (`--category security` for an outage post-mortem, `--category maintainability` for a refactor sprint)
- Comparing two directories or branches by aggregate remediation effort

**When NOT to use**:
- Need per-finding anti-pattern names with line numbers — that's `tldr smells`
- Want the *bug-risk* signal that combines complexity with how often code changes — `tldr hotspots`

**Usage**:
```bash
tldr debt <directory> [--category <cat>] [--hourly-rate <N>] [--top <N>]
```

**Output**: A `DebtReport` with per-violation `issues[]` (file, line, element, rule, message, category, debt_minutes), a `--top`-truncated `top_files[]` ranked by total minutes, and a `summary` with totals plus `by_category`, `by_rule`, `by_severity`, `debt_ratio`, `debt_density`.

**Killer detail**: Passing a single FILE as PATH **silently returns an empty result** with `language: null` and exit 0 — the analyzer walks directories only, with no upfront `is_file()` check. Always pass a directory, and verify `issues.length > 0` to detect this silent failure.

---

### `tldr hotspots` — churn × complexity bug-risk ranker

Adam-Tornhill-style churn × complexity ranker that points to the files (or functions) where bugs cluster — the highest-payoff refactor targets.

**Why reach for it**:
- The single most actionable refactor signal in the audit suite: complex AND actively changing = highest bug risk per hour invested
- `recommendation` strings per entry (`"Critical: High churn + high complexity + fragmented knowledge..."`) drop straight into LLM prompts
- `--by-function` collapses the analysis to per-function granularity — actionable for "which function in this file" rather than just "which file"
- `knowledge_fragmentation` surfaces tribal-knowledge debt (high author dispersion + high churn)

**When to use**:
- Picking refactor targets and want the highest bug-risk-per-hour file or function
- Investigating a production incident — hotspots tend to be where the regression came from
- Building a quarterly tech-debt plan; want a defensible "attack these N files first" list
- Want to combine git frequency with complexity in one shot rather than running and joining two commands

**When NOT to use**:
- Just want raw git frequency without complexity weighting — use `tldr churn`
- Need the SQALE minutes rollup for cost reporting — use `tldr debt`

**Usage**:
```bash
tldr hotspots [path] [--by-function] [--since YYYY-MM-DD] [--days N] [--recency-halflife N]
```

**Output**: A ranked `hotspots[]` (each with `churn_score`, `complexity_score`, `hotspot_score`, `commit_count`, `complexity`, `knowledge_fragmentation`, `author_count`, `recommendation`), plus a `summary` of corpus stats and `metadata` echoing the `scoring_weights` and algorithm version.

**Killer detail**: Empty directories **ERROR OUT with exit 1** and `"Not a git repository"` — diverging from `tldr churn`'s graceful exit-0 empty-dir special case. Two adjacent commands, same input, opposite behavior. Branch on exit code if you can't guarantee the path.

**Other footguns**:
- `--since <invalid-date>` is silently dropped — the field is `Option<String>` with no validation, so a typo returns the unfiltered default with no warning. Use strict ISO `YYYY-MM-DD`.
- `--days N` is mostly subsumed by `--recency-halflife 90` decay — commits older than ~270 days contribute under 12.5% weight regardless. Set `--recency-halflife 0` to actually disable decay.

---

### `tldr churn` — raw git change-frequency report

Git-history file-frequency analyzer that returns a structured top-N of the files changing most often over a time window, with line-delta and author rollups.

**Why reach for it**:
- Replaces `git log --stat | awk` pipelines with one structured JSON call, time-window filtered and top-N truncated
- Language-agnostic — operates purely on git diffs, so polyglot repos work without any `-l` setup
- `--authors` adds a top-level author aggregation; `is_shallow: true` warns when the clone truncates history
- Per-file `authors[]` and `commit_count` always populated, even without `--authors`

**When to use**:
- Need raw "what changes a lot" intelligence without any complexity weighting
- Want author attribution across a time window (`--authors` + `--days`)
- Building a "files modified in last quarter" report or seeding a code-review rotation
- A pre-step before `tldr hotspots` to understand which file subset is even worth ranking

**When NOT to use**:
- Picking refactor targets — `tldr hotspots` multiplies churn by complexity, which is the actual signal you want
- Need co-change patterns (which files change *together*) — that's `tldr temporal`, lives in `tldr-architecture`

**Usage**:
```bash
tldr churn [path] [--days N] [--top N] [--authors]
```

**Output**: A `ChurnReport` with `files[]` ranked descending by `commit_count` (each with `lines_added/deleted/changed`, `first_commit`, `last_commit`, per-file `authors[]`), an optional top-level `authors[]` aggregation, a `summary` of totals, and an `is_shallow` flag.

**Killer detail**: Empty directories get a **special-case stub schema** with `summary: null` and a top-level `warnings: ["Empty directory: no files to analyze"]` field that does NOT appear in normal output — exit 0, but agents schema-validating the response must accept `summary` as `null | ChurnSummary`.

---

### `tldr todo` — aggregated refactor checklist

Unified refactor checklist that runs four sub-analyses (dead code, complexity, cohesion, similar) and aggregates the findings into a single prioritized, scored `items[]` list.

**Why reach for it**:
- One command replaces running `dead`, `complexity`, `cohesion`, and `similar` separately
- Every item ships with `priority` (sortable int), `severity`, and a 0.0–1.0 `score` for actionability filtering
- `--quick` skips the expensive similar-analysis when fast iteration matters
- `--detail <sub-analysis>` expands one section inline for drill-down without re-running

**When to use**:
- Generating a "what should I refactor next" checklist for a file or directory
- Pre-PR audit: sort items by priority and address the top N
- Pairing with `tldr hotspots` — hotspots tells you WHERE to start, todo tells you WHAT to do once there
- Driving a CI gate that fails on `severity == "critical"` items

**When NOT to use**:
- Hunting a specific code smell — use `tldr smells`
- Wanting a single multi-analyzer dashboard — use `tldr health`
- Wanting churn-weighted priorities — use `tldr hotspots`

**Usage**:
```bash
tldr todo [path] [--quick] [--detail <sub-analysis>] [--max-items <N>]
```

**Output**: JSON with `wrapper: "todo"`, the input `path`, an `items` array of `{category, priority, description, file, line, severity, score}` entries, a `summary` block aggregating sub-analysis counts, and `total_elapsed_ms`.

**Killer detail**: `--max-items 0` means "show all" here, but in `tldr contracts`, `tldr patterns`, and `tldr surface` the same flag means "literally zero." This cross-command divergence is the trap — always check the per-command help before relying on 0 as a sentinel.

---

### `tldr resources` — CFG-based resource-leak detector

CFG-based resource lifecycle analyzer — finds leaks, double-closes, and use-after-close bugs in a single file by walking every control-flow path.

**Why reach for it**:
- Examines all paths through a function, not just the happy path — catches leaks that only trigger on exceptions or early returns
- Three detectors in one command: R2 (leaks) is on by default; `--check-all` adds R3 (double-close) and R4 (use-after-close)
- `--suggest-context` proposes the actual refactor (e.g., wrap `open()` in `with`) instead of just flagging the problem
- `--constraints` emits LLM-consumable rule statements — direct prompt fodder for a repair agent

**When to use**:
- Reviewing a single file that handles files, DB connections, sockets, locks, or cursors
- Pre-commit check on code that opens external resources
- Generating refactor suggestions for legacy code missing `with`/`using`/`defer` blocks
- Pairing with `tldr temporal` (in `tldr-architecture`) to cross-check: temporal mines the project-wide acquire/release pattern, resources verifies a specific file follows it

**When NOT to use**:
- Want project-wide method-call sequencing (not just resource lifecycles) — that's `tldr temporal` in `tldr-architecture`
- Looking for security findings (taint, injection) — see `tldr-audit-security`

**Usage**:
```bash
tldr resources <file> [--check-all] [--suggest-context] [--constraints]
```

**Output**: A JSON record with `resources[]` (each with `name`, `resource_type`, `line`, `closed`), `leaks[]`, `double_closes[]`, `use_after_closes[]`, plus optional `suggestions[]` and `constraints[]` arrays, and a summary count block.

**Killer detail**: Passing a DIRECTORY instead of a file **leaks a raw OS error** (`"Error: IO error: Is a directory (os error 21)"`, exit 1) — the CLI never pre-checks `is_file()`. Always pass a single regular file; loop externally if scanning many.

**Other footguns**:
- `-f compact` is BROKEN — returns byte-identical pretty JSON because the legacy local output_format enum only knows `Json`/`Text`. Use `jq -c` for actual compact output.
- `--summary` flag appears to be a no-op (returns full output identical to default). Don't rely on it for filtering.

## Common mistakes

- **Using `tldr churn` to pick refactor targets.** Raw change frequency without complexity weighting is noise — a config file edited every commit isn't a refactor target. `tldr hotspots` multiplies churn by complexity for the actual bug-risk signal. Churn alone is for activity reports, not prioritization.
- **Expecting `tldr smells --smell-type low-cohesion` to work without `--deep`.** Eight smells (`low-cohesion`, `tight-coupling`, `dead-code`, `code-clone`, `high-cognitive-complexity`, `middle-man`, `refused-bequest`, `inappropriate-intimacy`) are deep-only. The advisory warning that normally nudges toward `--deep` is SUPPRESSED once `--smell-type` is set, so you get silent empty results. Always pass `--deep` with those eight.
- **Passing a single FILE to `tldr debt`.** It silently returns empty with `language: null` and exit 0 — the analyzer walks directories only, with no upfront `is_file()` check. Always pass a directory, and check `issues.length > 0` to detect this silent failure.
- **Passing a DIRECTORY to `tldr resources`.** Opposite mistake — `resources` requires a single file and leaks a raw OS error (`"Is a directory"`, exit 1) on directory input. Loop externally if you need to scan many files.
- **Running `tldr hotspots` on an empty directory and being surprised by exit 1.** Hotspots errors with `"Not a git repository"` on empty dirs, while `tldr churn` on the same input returns exit 0 with a special-case empty stub. Two adjacent commands, opposite contract — branch on exit code if you can't guarantee the path.
- **Setting `tldr hotspots --since 2024-Q1` or any non-ISO date.** The field is `Option<String>` with NO validation — invalid values are silently dropped and the call returns unfiltered results. Use strict `YYYY-MM-DD`.
- **Expecting `tldr hotspots --days 30` to actually restrict to 30 days.** It is mostly subsumed by the `--recency-halflife 90` decay; commits older than ~270 days contribute under 12.5% weight regardless. Set `--recency-halflife 0` to actually disable decay.
- **Treating `tldr health` as cheap.** It is ~9.7 seconds for 56 files even with `--quick`, and has NO daemon caching, so repeat calls recompute everything. Budget the latency; use `--quick --summary` for triage and only drop `--quick` when coupling/similarity numbers are actually needed.
- **Trusting `--max-items 0` to mean the same thing across commands.** In `tldr todo` it means "show all"; in `tldr contracts`, `tldr patterns`, and `tldr surface` the same flag means "literally zero." Always check per-command help.
- **Stacking `tldr smells` + `tldr debt` + `tldr hotspots` blindly into one "audit" call.** They overlap meaningfully (smells feeds debt, complexity feeds hotspots). Pick by which signal the AUDIENCE needs; don't ship all three to a reviewer who just wanted a refactor target.

## See also

- `tldr-audit-complexity` — when the specific question is "how complex" (cyclomatic, cognitive, Halstead, LOC) — a different signal type than churn-weighted bug risk or named anti-patterns
- `tldr-architecture` — when the question is "how structured" (coupling, cohesion across modules, hubs, layer violations, co-change / temporal coupling, project-wide clone families) — different concern than per-file or per-finding quality
- `tldr-audit-security` — for vulnerabilities, taint, and injection findings — `tldr health` does NOT cover that surface
- `tldr-audit-coverage` — for "is this code actually tested / specified" rather than "is this code dirty"
- `tldr-trace-relationships` — for the dead-code-discovery workflow (the `dead-code-discovery-family-chooser` lens) when "find unused functions" is the specific intent rather than a generic quality audit
