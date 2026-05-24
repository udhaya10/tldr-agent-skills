# Key Insights — Agent Skills Authoring

What the 5 official docs taught us, **rated for value against our specific use case** (14 filesystem-based Claude Code skills wrapping the `tldr` CLI), with concrete gaps in our current implementation.

---

## TL;DR for the impatient

- **Our biggest opportunity**: every existing SKILL.md is 20–67 lines (well under the 500-line ceiling). The 66 dossiers we already built contain ~5–10× more actionable content than what currently ships in the skills. **The headroom to merge dossier knowledge into skills is huge.**
- **Anthropic's #1 lever** = `description` field. It's what Claude uses to *pick* a skill from 100+ candidates. Our descriptions are decent but can be tightened with the trigger language we now know works.
- **Anthropic's #1 architectural pattern** = progressive disclosure: a thin SKILL.md that points to deeper files loaded on demand. We don't use this at all yet — and our research dossiers are a perfect fit for the "deeper file" role.
- **One unexpected hard limit**: references should be **one level deep** from SKILL.md. If we nest dossiers behind skill pages behind index pages, Claude may only `head -100` the deep ones and miss content.

---

## Architectural concepts

### 1. Progressive disclosure (3 levels)

**The single most important concept in the entire docs set.**

| Level | What | When loaded | Token cost |
|-------|------|-------------|------------|
| 1. Metadata | YAML frontmatter (`name`, `description`) | Always, at startup | ~100 tokens/skill |
| 2. Body | SKILL.md markdown | When skill triggers | <5k tokens target |
| 3. Bundled files | Other `.md`, scripts, datasets | On-demand via bash | Effectively unlimited |

**Value to us: 🟢 HIGH.** Right now our skills are all single-file. We can adopt this pattern by linking the per-command research dossiers from each SKILL.md (e.g. `tldr-search/SKILL.md` → `research/tldr/search/context.md`). Claude only pays the dossier token cost when it actually needs to consult one.

### 2. Filesystem-based architecture

Skills are directories on a VM. Claude reads SKILL.md with `bash cat`, runs scripts with `bash python`. Script *output* enters context; script *source* does not.

**Value to us: 🟡 MEDIUM.** Already the model we operate under. Reinforces that bundling our `.probes/probe.sh` scripts is the right call — they execute, they don't bloat context.

---

## The `description` field — the discovery lever

### 3. Description is how Claude picks which skill to use

> *"Each Skill has exactly one description field. The description is critical for skill selection: Claude uses it to choose the right Skill from potentially 100+ available Skills."*

**Rules:**
- **Third person** (NOT "I can help…" or "You can…") — POV inconsistency breaks discovery
- **Specific** — include trigger words and contexts
- **Both what + when** — what the skill does AND when to invoke it
- Max 1024 chars, no XML tags

**Value to us: 🟢 HIGH.** Our existing descriptions are mostly third-person but lean abstract. Comparison:

| Skill | Current description | Trigger words present? |
|-------|--------------------|----------------------|
| `tldr-search` | "Semantic search, code similarity, and context generation. Use this to find where specific concepts are handled…" | ✅ "find", "where", "concepts" |
| `tldr-audit` | "Codebase health, security, and complexity analysis. Use this to find code smells, security vulnerabilities…" | ✅ "smells", "vulnerabilities", "debt" |
| `tldr-router` | "Maps user queries and intents to the correct tldr specialist skill." | ⚠️ No trigger words — what would the user say? |

**Action**: audit all 14 descriptions for trigger-word density. `router` in particular needs "I don't know which tldr skill to use" type triggers.

---

## Authoring style

### 4. "Concise is key" — assume Claude is smart

> *"Default assumption: Claude is already very smart. Only add context Claude doesn't already have."*

The good example was 50 tokens; the bad was 150 tokens for the same point. The bad version explained what PDFs are.

**Value to us: 🟢 HIGH.** Some of our skill bodies repeat what `--help` would tell Claude anyway. Strip those.

### 5. Three degrees of freedom (match specificity to fragility)

| Freedom | When | Form |
|---------|------|------|
| High | Many valid paths | "Analyze, check, suggest" text instructions |
| Medium | Preferred pattern with config | Pseudocode + parameters |
| Low | Fragile, must-not-deviate | "Run exactly: `python migrate.py --verify --backup`" |

**Value to us: 🟡 MEDIUM.** Most `tldr` commands are *low-freedom* operations (specific invocation with specific flags). Our existing skills already lean this way — we can tighten further with the footgun guidance from dossiers (e.g. "ALWAYS pass `-l` on multi-language repos").

### 6. Naming conventions

- **Gerund form preferred**: `processing-pdfs`, `analyzing-spreadsheets`
- Lowercase, hyphens, no `anthropic`/`claude` reserved words
- ≤64 chars

**Value to us: 🔴 LOW (already done).** Our `tldr-<group>` pattern is established and consistent. Not worth renaming.

---

## Information architecture

### 7. SKILL.md body should be under 500 lines

**Value to us: 🔴 LOW (already compliant).** All 14 skills are 20–67 lines — 87% under the ceiling. We have massive headroom to grow them.

### 8. Reference files: one level deep from SKILL.md

> *"Claude may partially read files when they're referenced from other referenced files… Keep references one level deep from SKILL.md."*

**Bad**: `SKILL.md → advanced.md → details.md → actual info`
**Good**: `SKILL.md → advanced.md` (info lives in advanced.md, not nested deeper)

**Value to us: 🟢 HIGH.** Critical constraint we must respect. Our dossiers live two levels deep (`research/tldr/<group>/<cmd>.md`). When linking from `SKILL.md`, we link **directly** to that path — don't introduce an intermediate `research/tldr/<group>/INDEX.md` index page.

### 9. Files >100 lines need a Table of Contents

So Claude sees the full scope even if it only `head -100` previews.

**Value to us: 🟢 HIGH.** Our dossiers are 200–500 lines each. They have section headers (which is good), but no explicit "Contents" block at the top. **Cheap fix**: add a 9-line ToC at the top of each dossier mirroring its `## ` headers.

### 10. Three reusable patterns

1. **High-level guide + references** — SKILL.md = TOC + quickstart; details in linked files
2. **Domain-specific organization** — `reference/finance.md`, `reference/sales.md`
3. **Conditional details** — show basic content, link out for advanced (e.g. tracked changes, OOXML)

**Value to us: 🟢 HIGH.** Pattern 1 maps cleanly onto our setup: `tldr-search/SKILL.md` lists the 5 commands + 1-line each + link to `research/tldr/search/<cmd>.md` for the full Agent Synthesis.

---

## Workflow patterns

### 11. Checklists for multi-step workflows

```
Task Progress:
- [ ] Step 1: Analyze the form (run analyze_form.py)
- [ ] Step 2: Create field mapping (edit fields.json)
- [ ] Step 3: Validate (run validate_fields.py)
```

**Value to us: 🟡 MEDIUM.** Useful for `tldr-fix` (multi-step diagnose → patch → verify) and `tldr-ops` (daemon lifecycle). Most other skills are single-shot.

### 12. Feedback loops: validate → fix → repeat

**Value to us: 🟡 MEDIUM.** Same scope — fix-flow and ops mostly.

---

## Content hygiene

### 13. No time-sensitive info ("After August 2025, use…")

**Value to us: 🟢 HIGH.** Several skills mention `tldr 0.4.0` features — fine as a version pin, but anything like "the new daemon API replaces the old polling approach" would rot. Audit needed.

### 14. Consistent terminology

Pick one term, use it everywhere ("API endpoint", not "endpoint/URL/route/path" mixed).

**Value to us: 🟡 MEDIUM.** Worth a pass when we rewrite. Examples from our skills: "function" vs "symbol" vs "definition" — sometimes interchangeable, sometimes not.

### 15. Examples are concrete, not abstract

Provide input → output pairs.

**Value to us: 🟢 HIGH.** Our dossiers already have captured probes (`01-happy.cmd` / `.out`) — perfect raw material. We can quote a tiny representative probe in the SKILL.md itself as a worked example.

---

## CLI Syntax Integrity — verified-invocations protocol

### 16. Never reconstruct CLI syntax from prose — use verified-invocations.md

**Root cause of hallucinated flags**: When a tool card or SKILL.md describes what a command does in prose but omits the exact `--help` Usage line, an LLM author will reconstruct the syntax from the description. This produces plausible-looking but wrong invocations — flags that don't exist, wrong argument ordering, or wrong subcommand forms.

**Example failure**: The deep group's `tldr slice -F <file> -F <function>` was invented from prose. The real Usage is `tldr slice [OPTIONS] <FILE> <FUNCTION>` (positional arguments, no `-F` flag).

**The fix**: Per-group `verified-invocations.md` files live at:
```
research/tool-cards/<group>/verified-invocations.md
```
Each file records:
1. The canonical `--help` Usage line (copied verbatim from the CLI)
2. A full probe table: every tested invocation, marked `happy` (verified) or `failure` (documented error case)

**Rule**: Before writing any `Usage:` block in a tool card or SKILL.md, open the group's `verified-invocations.md` and **copy the syntax verbatim**. Do NOT reconstruct from prose.

**Groups and their verified-invocations files**:

| Group | File |
|-------|------|
| deep | `research/tool-cards/deep/verified-invocations.md` |
| overview | `research/tool-cards/overview/verified-invocations.md` |
| search | `research/tool-cards/search/verified-invocations.md` |
| trace | `research/tool-cards/trace/verified-invocations.md` |
| fix | `research/tool-cards/fix/verified-invocations.md` |
| ops | `research/tool-cards/ops/verified-invocations.md` |
| audit | `research/tool-cards/audit/verified-invocations.md` |

**Watch-out**: `tldr similar -F` is NOT hallucinated — `-F` is the real `--function` short flag in that command. Check the verified file before flagging a false positive.

**Value to us: 🟢 HIGH (critical).** This is the single most important authoring guard we have. Hallucinated flags cause silent failures or wrong results at runtime. Every SKILL.md Usage block must trace back to a verified probe.

---

## Development methodology

### 16. Build evaluations FIRST

> *"Create evaluations BEFORE writing extensive documentation. This ensures your Skill solves real problems rather than documenting imagined ones."*

**Value to us: 🟡 MEDIUM-HIGH.** We didn't do this. We can retrofit by treating our existing dossier probes as a de-facto eval set: each `.probes/*.out` is a ground-truth behavior, and we can ask "did the skill's guidance lead Claude to invoke the command correctly?"

### 17. Iterate with Claude A (author) ↔ Claude B (user)

Use one Claude instance to write the skill, another (fresh, with skill loaded) to actually use it. Observe Claude B's failures, feed back to Claude A.

**Value to us: 🟢 HIGH.** This is exactly the loop the Ralph approach already enables. We can run a skill update by Ralph (Claude A) and validate with a fresh `claude` instance running a representative task (Claude B).

---

## Anti-patterns to flag in our skills

| Anti-pattern | Where we likely have it |
|--------------|------------------------|
| Windows paths (`scripts\foo.py`) | Probably nowhere — Mac/Linux env |
| Too many options ("use pypdf or pdfplumber or…") | Some of our skills list 3 sibling commands without saying when to pick which — borderline |
| Vague names (`helper`, `utils`) | Not us — all named `tldr-<group>` |
| Reserved word usage (`anthropic-…`, `claude-…`) | None |
| Magic numbers in scripts | Need to audit `probe.sh` scripts |
| Deeply nested file references | None yet — but we'd introduce them if we built `INDEX.md` middlemen |

---

## What does NOT apply to us

The following sections of the docs are explicitly out of scope for our case:

- **API container/skills upload** (`skills-guide.md`) — we use Claude Code filesystem skills, not API uploads
- **`beta:` headers** (`code-execution-2025-08-25`, `skills-2025-10-02`) — Claude Code skills don't need these
- **claude.ai zip upload flow** — same reason
- **Network access constraints** (no network on API container) — Claude Code skills have full network
- **Pre-installed packages list** — N/A, we run on the user's machine
- **Multi-model testing** (Haiku/Sonnet/Opus matrix) — relevant but lower priority; we can validate against Opus first since that's the primary author/user

---

## Overall value assessment

| Source doc | Value rating | Why |
|-----------|--------------|-----|
| `best-practices.md` | 🟢🟢🟢 GOLD | The authoring bible. Every section directly applicable. The checklist at the end is a ready-made scoring rubric. |
| `overview.md` | 🟢🟢 HIGH | Progressive disclosure is the key concept that unlocks pairing dossiers with skills. |
| `enterprise.md` | 🟢 MEDIUM | Review checklist (§Risk tier assessment, §Naming and cataloging) is useful even at our solo scale. Skip the org-admin parts. |
| `skills-guide.md` | 🟡 LOW | API-mechanic focus. Skim only — most doesn't apply to filesystem skills. |
| `quickstart.md` | 🔴 MINIMAL | API tutorial for pre-built pptx/xlsx skills. Confirms what the API flow looks like but no authoring guidance. |

**Single highest-leverage takeaway**: adopt progressive disclosure. Our SKILL.md files become thin TOCs that point to the 66 dossiers we already built. Token-cheap for the agent, deeply detailed when needed, evidence-backed throughout.

---

## Proposed next action

A **pilot** that proves the pattern end-to-end on one skill before rolling across all 14:

1. Pick `tldr-search` (small group: 5 commands, all dossiers complete)
2. Rewrite `tldr-search/SKILL.md` using:
   - Pattern 1 (high-level guide + references)
   - Trigger-word-rich description
   - Concrete example pulled from `research/tldr/search/search.probes/01-happy.out`
   - Links to each of the 5 dossiers (one level deep, no intermediate index)
   - Body kept under 200 lines
3. Add a Table of Contents to the 5 search dossiers (so Claude can preview-read them effectively)
4. Validate with a fresh Claude instance: ask it a search-flavored question, observe whether it consults the right dossier and gives a footgun-aware answer

If the pilot wins, repeat for the other 13 skills (estimated ~1–2 hours each with Ralph).
