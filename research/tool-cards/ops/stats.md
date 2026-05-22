# tldr stats

**Pitch**: Global usage summary that aggregates token savings across every daemon-tracked tldr invocation, regardless of which project they ran in.

**Why reach for it**
- Self-monitoring: see how many tokens the tldr layer has saved over an entire session history
- CWD-independent — runs from any directory because it reads `~/.tldr/stats.jsonl`, not project state
- Empty case is genuinely actionable, not opaque
- Zero positional args, minimal cognitive load

**When to use**
- Building a tldr-savings dashboard or reflection summary
- Confirming the daemon is actually being routed through (an empty `stats` after running many commands means the daemon never came up)
- Personal accounting of token-cost reduction

**When NOT to use**
- Per-project or per-daemon cache size — use `tldr cache stats` (on-disk) or `tldr daemon status` (live Salsa counters)
- Per-command latency breakdown — stats aggregates, it doesn't decompose

**Output in plain words**: When populated, JSON with `total_invocations`, `estimated_tokens_saved`, `raw_tokens_total`, `tldr_tokens_total`, and `savings_percent`. When empty, JSON with `message`, a `next_steps` array of exact commands to populate stats, and a `requires` array naming the prerequisites.

**Killer detail**: Stats only populates when the daemon has been running during commands — without `tldr daemon start` first, the JSONL file never gets written and `tldr stats` will return its empty-with-next-steps payload forever.

**Source**: `research/tldr/ops/stats.md`
