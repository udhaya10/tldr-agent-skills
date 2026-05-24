# tldr coupling

> **Before writing the Usage block**: check `verified-invocations.md` in this group's
> `tool-cards/audit/` directory and copy the canonical syntax verbatim.
> Do NOT reconstruct syntax from prose — that is how hallucinated flags get introduced.

**Pitch**: Dual-mode function-call coupling analyzer — pairwise for two files, or project-wide with Robert Martin afferent/efferent/instability metrics plus cycle detection.

**Why reach for it**
- Project-wide mode produces canonical `martin_metrics` (Ca, Ce, instability) — the SOLID-principles answer to "how tangled is each module?"
- Pair mode returns the actual `a_to_b` and `b_to_a` call lists with caller/callee/line, so the verdict is auditable
- `--cycles-only` filters to dependency cycles — usually the highest-priority architectural fix
- Best-in-class error UX: bad inputs return a message that documents BOTH usage modes inline

**When to use**
- Auditing inter-module dependencies after a refactor and want Martin metrics
- Investigating whether two files are too entangled (pair mode with `<FILE_A> <FILE_B>`)
- Hunting dependency cycles via `--cycles-only` for an architectural cleanup
- Building a "most unstable modules" backlog (`--top N` ranks by instability)

**When NOT to use**
- Want IMPORT-graph coupling rather than function-call coupling — use `tldr deps` or `tldr imports` (the `--help` says so explicitly)
- Want intra-class structure (do methods share state?) — that's `tldr cohesion`

**Usage (copy from `verified-invocations.md` — do not reconstruct)**:
```
tldr coupling [OPTIONS] <PATH_A> [PATH_B]
```
```
tldr coupling backend/providers                                       # project-wide mode (single path)
tldr coupling backend/providers/yahoo.py backend/providers/base.py   # pair mode (two paths)
tldr coupling backend --cycles-only                                   # show only circular dependencies
```

**Output in plain words**: TWO different JSON schemas. Pair mode returns `{ path_a, path_b, a_to_b, b_to_a, total_calls, coupling_score, verdict }`. Project-wide mode returns `{ martin_metrics: { metrics:[{module, ca, ce, instability, in_cycle}], cycles, summary }, pairwise_coupling: {...} }`.

**Killer detail**: The output schema flips entirely based on whether PATH_B is supplied — agents must branch on the presence of the `martin_metrics` key (project mode) versus `path_a` (pair mode) before parsing. Single-file PATH_A with no PATH_B is rejected outright with the audit suite's best error, documenting both modes.

**Source**: `research/tldr/audit/coupling.md`
