# Research Journal 12: The Progressive Disclosure Gap in agent-rules.md

> **Finding:** The current `agent-rules.md` has a missing escalation step between "use tldr for exploration" and "read the full file." Agents jump from `tldr extract` (signatures only) straight to reading raw source, skipping intermediate commands that provide implementation detail without full-file cost. This journal documents the gap and prescribes the escalation ladder rule.

> **Date:** 2026-05-29

---

## The Gap

The current `agent-rules.md` (the managed block distributed via `tldr-setup-check`) has three layers of guidance:

1. **"Use tldr for exploration"** — the blanket rule
2. **Intent → skill routing table** — which skill for which user goal
3. **Allowed exceptions** — when shell/read tools are OK

But the agent's actual decision tree reveals a hole:

```
Need to understand code?
  → Use tldr structure / extract / explain  ✅

Need implementation details?
  → Read the full file  ← GAP
```

Exception #4 ("Applying or verifying an edit in a single already-identified file") covers the editing case. But there is **no guidance** for "I need to understand the implementation of a function, not just its signature." The agent interprets this as needing raw source and reads the entire file.

---

## Why This Matters

| Behavior | Tokens consumed | Information density |
|----------|----------------|---------------------|
| `tldr extract file.py` | Low (~signatures) | High per token |
| Read full 800-line file to understand 1 function | Very high | Low per token |
| `tldr explain file.py fn` | Medium | High per token |
| `tldr context fn . --depth 2` | Medium | High per token |
| Read lines 200–260 (targeted) | Targeted | High per token |

Without the escalation ladder, agents burn context window on full-file reads when 60 targeted lines would suffice. This is the same token-efficiency problem Journal 10 documented for shell commands — but happening *within* the tldr-aware workflow itself.

---

## The Escalation Ladder (prescribed rule)

Insert before the "Allowed exceptions" section in `agent-rules.md`:

```markdown
### Rule: progressive disclosure — exhaust tldr before reading raw source

When you need implementation details beyond what `tldr structure` or `tldr extract` provide:

1. **First** — `tldr explain <file> <function>` (signature + purity + complexity + callers + callees)
2. **Then** — `tldr context <function> . --depth 2` (function + everything it calls, with bodies)
3. **Only then** — read the specific function's lines (use offset/limit, NOT the full file)

**Never read an entire file to understand one function.** If you know the function starts at line 200, read lines 200–260, not 1–800.

| Need | Command | Tokens |
|------|---------|--------|
| What functions exist? | `tldr structure` | Low |
| What does fn X do? (summary) | `tldr explain file X` | Medium |
| How does fn X work? (with callees) | `tldr context X . --depth 2` | Medium |
| Exact implementation of fn X | Read file with offset/limit | Targeted |
| Full file | ❌ Almost never needed | High |
```

---

## Relationship to Existing Rules

This rule does NOT replace anything — it fills the gap between:

- The **"do NOT use shell tools"** rule (which tells agents *what not to do*)
- The **intent → skill routing table** (which tells agents *which skill to load*)
- The **allowed exceptions** (which tell agents *when shell is OK*)

The escalation ladder tells agents **how to progressively deepen understanding** within the tldr workflow before ever reaching for raw source. It's the missing "how much detail do I need?" decision framework.

---

## Action Required

1. Add the escalation ladder rule to `agent-rules.md` (before "Allowed exceptions")
2. Recompute hash via `python update_hash.py agent-rules.md`
3. Push — next `tldr-setup-check` run in any project will pick up the new rule
