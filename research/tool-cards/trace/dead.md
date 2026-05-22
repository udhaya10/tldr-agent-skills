# tldr dead

**Pitch**: Project-wide unreachable-function detector — what code is safe to delete.

**Why reach for it**
- Replaces hand-rolled `grep` with framework-aware analysis (`'use server'`, `.d.ts`, decorators all handled)
- Splits results into definitively-dead (zero refs) and possibly-dead (single ref = the definition itself)
- Refcount mode is single-pass and fast; `--call-graph` available when precision matters
- Whitelist known entry points via `--entry-points name1,name2,...` to suppress false positives

**When to use**
- Cleaning up before a refactor and want a list of deletion candidates
- Auditing legacy code paths during onboarding
- Need a baseline "dead percentage" for tech-debt tracking

**When NOT to use**
- Verifying ONE function is unused — `tldr references <name>` is the direct answer
- Hunting unused assignments inside functions — that's `tldr deep dead-stores`, a different concern

**Output in plain words**: JSON with `dead_functions` (0 refs), `possibly_dead` (1 ref), a `by_file` grouping, and totals including a `dead_percentage`. The list is paged by `--max-items`; the totals always reflect the full count.

**Killer detail**: `possibly_dead` means "exactly one identifier reference exists in the codebase" — that one reference is the function's own definition. Public exports, reflection-called code, framework callbacks, and decorated routes all legitimately land here, so always verify a candidate with `tldr references <name>` before deleting.

**Source**: `research/tldr/trace/dead.md`
