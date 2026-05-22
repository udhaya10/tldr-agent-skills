# Ecosystem Map — Agent Skills

> **Why this exists.** The Agent Skills ecosystem has three independent moving parts (the spec, the distribution CLI, and the per-agent client implementation) and three distinct audiences (skill producers, end-user consumers, agent product builders). Before mapping these out, we kept conflating them — most visibly, our README first claimed agentskills.io was a "third-party ecosystem distinct from Anthropic's Agent Skills" (wrong), then doubted whether `npx skills add` was a real command (also wrong). This document fixes the model.

## The three layers

The ecosystem splits cleanly into three concerns. Each has its own URL, its own audience, and its own role. Confusing them was our biggest mistake.

```
┌─────────────────────────────────────────────────────────────────────┐
│   LAYER 1 — THE SPEC                                                │
│   agentskills.io                                                    │
│   The open standard for SKILL.md format, naming rules, frontmatter, │
│   directory conventions, and progressive disclosure semantics.      │
│   Originally developed by Anthropic, released as an open standard,  │
│   now adopted across ~60 agent products.                            │
└─────────────────────────────────────────────────────────────────────┘
              │                              │
              │ followed by                  │ followed by
              ▼                              ▼
┌──────────────────────────┐   ┌─────────────────────────────────────┐
│  LAYER 2 — DISTRIBUTION  │   │  LAYER 3 — CLIENT IMPLEMENTATION    │
│  vercel-labs/skills      │   │  Per-agent integration              │
│  The npm `skills` CLI    │   │  Each agent product (Cursor, Goose, │
│  used by end-users to    │   │  Claude Code, OpenHands, VS Code…)  │
│  install skill folders   │   │  implements discovery + parsing +   │
│  to the right disk paths │   │  cataloging + activation per the    │
│  (~/.agents/skills/ etc.)│   │  spec on its side.                  │
└──────────────────────────┘   └─────────────────────────────────────┘
```

## Audience matrix — who reads what

|  | **Producers** *(authors of skills, like us)* | **Consumers** *(end users)* | **Agent builders** *(Cursor devs, Goose devs)* |
|--|----------------------------------------------|-----------------------------|---------------------------------------------|
| Spec (agentskills.io/specification) | **MUST** read — your SKILL.md has to parse | Optional | **MUST** read |
| Skill creation guides (best-practices, optimizing-descriptions, etc.) | **SHOULD** read — directly improves authoring | No | Optional |
| vercel-labs/skills CLI README | Optional — only if shipping install instructions | **MUST** know `npx skills add` exists | No |
| agentskills.io/client-implementation | **NO** — irrelevant | No | **MUST** read |

## Our project's place in the ecosystem

We are **skill producers**. Our concerns are layers 1 and 2 only:

| What we do | Layer | How |
|-----------|-------|-----|
| Write conformant SKILL.md files | Spec (1) | Frontmatter follows `name`/`description`/etc. constraints; body is just markdown |
| Tell users how to install | Distribution (2) | README points at `npx skills add udhaya10/tldr-agent-skills --all -g` |
| Tell agents how to discover our skills | Implementation (3) | **NOTHING** — that's the agent product's responsibility, not ours |

The implementation layer (3) is **completely outside our scope**. Cursor reads `~/.agents/skills/`; we don't tell Cursor how to do that. We just put files where Cursor looks.

## Anthropic vs agentskills.io — they're the same thing

Important nuance often conflated:

- **The Agent Skills FORMAT** was developed by Anthropic and shipped as Claude API/Claude Code skills.
- **The agentskills.io open standard** is that same format, released as a vendor-neutral spec that any agent product can implement.
- **The two ARE the same spec.** Anthropic ships one implementation (Claude); agentskills.io is the vendor-agnostic home of the spec.

Our `research/agent-skills-authoring/references/` folder includes references from BOTH origins because they cover slightly different framings:

- **Anthropic docs** (platform.claude.com) — Claude-specific concerns (Claude API `container.skills` param, Claude Code filesystem skills, enterprise considerations)
- **agentskills.io docs** — vendor-neutral spec, cross-client conventions, client-implementation guidance for non-Claude agents

The format content overlaps ~80%. Reading both isn't wasteful — each surfaces concerns the other glosses.

## Locked-in decisions for this project

| Decision | What we chose | Why |
|----------|--------------|-----|
| **Distribution tool** | `npx skills add` (vercel-labs/skills) | Confirmed working install path. Supports symlink-based install for clean `npx skills update` cycles. |
| **Install scope** | `-g` (user-level) by default per README | Most users want our skills globally available, not project-pinned |
| **Spec version we conform to** | agentskills.io spec as of 2026-05-22 | Latest at time of research |
| **Cross-client install path** | `.agents/skills/` convention | Spec-recommended for cross-client compatibility |
| **Agent products we target** | Any spec-compliant agent (Claude Code, Cursor, Goose, VS Code Copilot, OpenAI Codex, Gemini CLI, etc.) | Following the spec means we're automatically compatible with all 60+ adopters listed at agentskills.io |
| **Maintenance regeneration source** | `research/` folder (dossiers + cards + combinatorics) | Per Journal 07 — `research/` stays in repo as the build-time source for regenerating skills when tldr-code ships new versions |

## References in this folder — guide to what each is for

The `references/` subfolder has 11 markdown files, two distinct sets:

### Set A: Anthropic platform docs (scraped first)

Origin: `platform.claude.com/docs/en/agents-and-tools/agent-skills/...` and `…/build-with-claude/skills-guide`. Scraped 2026-05-22.

| File | Source page | Use for |
|------|-------------|---------|
| `overview.md` | Agent Skills Overview | Foundational concepts, progressive disclosure |
| `quickstart.md` | Agent Skills Quickstart (API tutorial) | Claude API invocation pattern (mostly N/A for our filesystem skills) |
| `best-practices.md` | Agent Skills Best Practices | **The authoring bible** — naming, descriptions, anti-patterns, checklist |
| `enterprise.md` | Agent Skills Enterprise | Org-scale practices: review, naming/cataloging, role-based bundles |
| `skills-guide.md` | Use Skills with the Claude API | API mechanics (skim only — most doesn't apply to filesystem skills) |

### Set B: agentskills.io open-spec docs + Vercel Labs CLI (scraped second)

Origin: `agentskills.io/...` and `github.com/vercel-labs/skills`. Scraped 2026-05-22.

| File | Source | Use for |
|------|--------|---------|
| `agentskills-io-llms-index.md` | `agentskills.io/llms.txt` | Index of all agentskills.io docs |
| `agentskills-io-home.md` | `agentskills.io/home` | Ecosystem overview + 60+ supporting agent products |
| `agentskills-io-specification.md` | `agentskills.io/specification` | **The format spec** — frontmatter fields, name constraints, progressive disclosure tiers |
| `agentskills-io-quickstart.md` | `agentskills.io/skill-creation/quickstart` | Vendor-neutral "create your first skill" tutorial |
| `agentskills-io-best-practices.md` | `agentskills.io/skill-creation/best-practices` | Vendor-neutral version of authoring guidance |
| `agentskills-io-client-implementation.md` | `agentskills.io/client-implementation/adding-skills-support` | **For agent builders only** — discovery/parsing/cataloging/activation. We don't author against this; it tells Cursor/Goose/etc. how to consume our skills. |
| `vercel-labs-skills-readme.md` | `github.com/vercel-labs/skills` README | The `npx skills` CLI — install/update/list commands, symlink option |

## What we should and should NOT read

When working on this project, the practical reading-list collapses to:

**Always relevant when authoring a skill**:
- `agentskills-io-specification.md` — format truth
- `best-practices.md` (Anthropic) — authoring bible
- `agentskills-io-best-practices.md` — vendor-neutral overlay

**Relevant when answering install/distribution questions**:
- `vercel-labs-skills-readme.md` — `npx skills` flags and behaviors

**Ignore unless explicitly relevant**:
- `agentskills-io-client-implementation.md` — only for agent product developers
- `enterprise.md`, `skills-guide.md` (Anthropic API mechanics) — only when integrating with the Claude API

## Open questions for future updates

1. **Spec drift** — agentskills.io is actively evolving (the home page already mentions Discord + GitHub Discussions). When the spec changes (new frontmatter fields, new directory conventions, etc.), we'll need to re-scrape and check our skills still conform. Suggest re-running this research annually OR when notified of spec changes.
2. **vercel-labs/skills feature evolution** — the CLI added `skills update` recently (per commit log). Future versions may add deprecation/version-awareness UX that interacts with our `metadata` field. Worth re-reading `vercel-labs-skills-readme.md` periodically.
3. **Anthropic vs open-spec divergence** — if Anthropic adds Claude-specific features that aren't in the open spec, we'll need to decide whether to use them (locking our skills to Claude) or stay vendor-neutral (works everywhere).
4. **Adoption metrics** — `find-skills` in vercel-labs/skills now reads a leaderboard at skills.sh. Worth investigating if/how our skills appear there.

## Cross-references

- `01_RESEARCH_METHODOLOGY.md` — how this folder's references were originally gathered (Anthropic docs only at the time)
- `02_KEY_INSIGHTS.md` — synthesis of authoring insights from the Anthropic docs (pre-dates the agentskills.io research)
- `../07_SKILL_ARCHITECTURE_DECISION.md` — applies the ecosystem understanding to our specific skill architecture choice (14 intent-aligned skills, no router)
