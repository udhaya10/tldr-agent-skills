# tldr churn

**Pitch**: Git-history file-frequency analyzer that returns a structured top-N of the files changing most often over a time window, with line-delta and author rollups.

**Why reach for it**
- Replaces `git log --stat | awk` pipelines with one structured JSON call, time-window filtered and top-N truncated
- Language-agnostic — operates purely on git diffs, so polyglot repos work without any `-l` setup
- `--authors` adds a top-level author aggregation; `is_shallow: true` warns when the clone truncates history
- Per-file `authors[]` and `commit_count` always populated, even without `--authors`

**When to use**
- Need raw "what changes a lot" intelligence without any complexity weighting
- Want author attribution across a time window (`--authors` + `--days`)
- Building a "files modified in last quarter" report or seeding a code-review rotation
- A pre-step before `tldr hotspots` to understand which file subset is even worth ranking

**When NOT to use**
- Picking refactor targets — `tldr hotspots` multiplies churn by complexity, which is the actual signal you want
- Need co-change patterns (which files change *together*) — that's `tldr temporal`

**Output in plain words**: A `ChurnReport` with `files[]` ranked descending by `commit_count` (each with `lines_added/deleted/changed`, `first_commit`, `last_commit`, per-file `authors[]`), an optional top-level `authors[]` aggregation, a `summary` of totals, and an `is_shallow` flag.

**Killer detail**: Empty directories get a special-case stub schema with `summary: null` and a top-level `warnings: ["Empty directory: no files to analyze"]` field that does NOT appear in normal output — exit 0, but agents schema-validating the response must accept `summary` as `null | ChurnSummary`.

**Source**: `research/tldr/audit/churn.md`
