# TLDR Agent Skills

A suite of agent skills designed to give Large Language Models (LLMs) autonomous mastery over the [parcadei/tldr-code](https://github.com/parcadei/tldr-code) AST engine.

The `tldr-code` CLI is a powerful static analysis tool with **66 commands** (64 actively exposed via CLI, 2 internal-only). This repository decomposes that surface into modular, progressive-disclosure agent skills — and backs them with a **probe-verified research corpus** so the skills carry sharp, evidence-grounded guidance instead of paraphrased docs.

---

## Current state (2026-05-22)

| Layer | Status | Files |
|-------|--------|-------|
| **Research dossiers** (probe-verified per-command spec) | ✅ Complete | 64/64 active commands, ~3,900 captured probe outputs |
| **Tool cards** (agent-oriented prose, one per command) | ✅ Complete | 64/64 |
| **Family-chooser combinatorics** (which sibling to pick) | ✅ Complete | 16 docs (all sub-families + 2 cross-group) |
| **Multi-lens orchestration combinatorics** (multi-tool workflows) | ⏸️ Deferred | ~12–15 expected |
| **Skill architecture decision** (Journal 07 — 14 intent-aligned skills, no router) | ✅ Locked | See [Journal 07](research/07_SKILL_ARCHITECTURE_DECISION.md) |
| **Skill rewrite** (14 new intent-aligned `tldr-*` skills) | ⏸️ Pending | 14 |

The current `tldr-*/SKILL.md` files are the original stub-level group-aligned skills (~20–67 lines each). They will be retired wholesale and replaced by 14 new intent-aligned skills per the architecture decision in Journal 07.

---

## Quick Install

```bash
npx skills add udhaya10/tldr-agent-skills --all -g
```

Or browse and select individual skills:

```bash
npx skills add udhaya10/tldr-agent-skills -g
```

---

## The 14 Skills (current — stub-level, pending rewrite)

| Skill | Purpose | Key Commands |
|-------|---------|--------------|
| **tldr-router** | Orchestrator — routes intent to appropriate skill | Intent analysis, skill selection |
| **tldr-overview** | Token-efficient codebase discovery | tree, structure, extract, explain, definition, importers, imports |
| **tldr-search** | Code search and similarity | search, semantic, context, similar, dice |
| **tldr-trace** | Call graph, references, blast radius | calls, references, impact, hubs, whatbreaks, dead |
| **tldr-deep** | Data-flow and slicing | slice, chop, reaching-defs, available, dead-stores |
| **tldr-audit** | Quality, security, complexity, smells | health, smells, vuln, secure, clones, debt, complexity, cohesion, +18 more |
| **tldr-fix** | Diagnostics and deterministic repair | bugbot, diagnostics, fix-diagnose, fix-check, fix-apply |
| **tldr-ops** | Caching, lifecycle, diff, reporting | daemon, warm, cache, change-impact, diff, stats, todo, +others |
| **tldr-refactor-history** | Git history coupling | temporal, churn, hotspots |
| **tldr-refactor-oo** | Object-oriented metrics | coupling, inheritance |
| **tldr-formal-methods** | Contracts, invariants, verify | contracts, invariants, specs, resources, verify |
| **tldr-api-stability** | API and interface boundaries | api-check, interface, patterns |
| **tldr-metrics-raw** | Code metrics for CI | loc, halstead, coverage |
| **tldr-security-taint** | Granular security taint | taint |

**Total: 64 active CLI commands** mapped into 14 skills.

---

## Research architecture (3 layers)

The research corpus is the source of truth that skills are built from. It has three layers, increasing in agent-readiness:

```
Layer 1: Dossiers          (research/tldr/<group>/<cmd>.md)
  ↓                        Probe-verified per-command spec — every claim
  ↓                        backed by a captured probe in <cmd>.probes/.
  ↓
Layer 2: Tool cards        (research/tool-cards/<group>/<cmd>.md)
  ↓                        ~200-word agent-oriented prose per command,
  ↓                        with a singular "killer detail" footgun callout.
  ↓
Layer 3: Combinatorics     (research/tool-combinatorics/<topic>-<lens>.md)
  ↓                        Cross-tool reasoning — family-choosers (which
  ↓                        sibling to pick) and (eventually) multi-lens
  ↓                        orchestration docs.

         Skills            (tldr-*/SKILL.md)
                           Authored from cards + combinatorics. Currently
                           stub-level; rewrite pending.
```

### Methodology journals

The research process itself is documented:

- [Journal 01 — CLI Discovery](research/01_CLI_DISCOVERY_JOURNAL.md)
- [Journal 02 — CLI Help Extraction](research/02_CLI_HELP_EXTRACTION_JOURNAL.md)
- [Journal 03 — Empirical Research Methodology](research/03_EMPIRICAL_RESEARCH_METHODOLOGY.md) — the "Zero Trust in Documentation" principle
- [Journal 04 — Probe Protocol](research/04_PROBE_PROTOCOL.md) — operational rulebook for the dossier evidence layer
- [Journal 05 — Omitted Commands Rationale](research/05_OMITTED_COMMANDS_RATIONALE.md) — why some CLI surface is intentionally excluded
- [Journal 06 — Cards and Combinatorics Protocol](research/06_CARDS_AND_COMBINATORICS_PROTOCOL.md) — the bridge from dossiers to skills
- [Journal 07 — Skill Architecture Decision](research/07_SKILL_ARCHITECTURE_DECISION.md) — locks in the final shape: 14 intent-aligned skills, no router, cards inlined per skill

### Agent-skills authoring research

Anthropic's official Agent Skills documentation (scraped 2026-05-22) and our synthesis:

- [Methodology + key insights](research/agent-skills-authoring/)
- Raw doc snapshots in `research/agent-skills-authoring/references/`

---

## Directory Structure

```
tldr-agent-skills/
├── README.md
├── REPOSITORY_STRUCTURE.md
├── LICENSE
├── research/
│   ├── 01_CLI_DISCOVERY_JOURNAL.md
│   ├── 02_CLI_HELP_EXTRACTION_JOURNAL.md
│   ├── 03_EMPIRICAL_RESEARCH_METHODOLOGY.md
│   ├── 04_PROBE_PROTOCOL.md
│   ├── 05_OMITTED_COMMANDS_RATIONALE.md
│   ├── 06_CARDS_AND_COMBINATORICS_PROTOCOL.md
│   ├── _TEMPLATES/                # Templates: dossier.md, probe.sh, audit.sh
│   ├── fixtures/                  # Test fixtures used by some probes
│   ├── tldr/                      # Layer 1: 66 probe-verified dossiers
│   │   ├── overview/              # 7 commands
│   │   ├── search/                # 5 commands
│   │   ├── trace/                 # 6 commands
│   │   ├── deep/                  # 5 active + 2 omitted stubs (cfg, dfg)
│   │   ├── audit/                 # 26 commands
│   │   ├── fix/                   # 5 commands
│   │   └── ops/                   # 10 commands
│   ├── tool-cards/                # Layer 2: 64 agent-oriented prose cards
│   │   └── (mirrors research/tldr/ structure)
│   ├── tool-combinatorics/        # Layer 3: 16 family-chooser docs
│   └── agent-skills-authoring/    # Anthropic Agent Skills authoring research
├── tldr-router/                   # Skill: orchestrator
├── tldr-overview/                 # Skill: codebase discovery
├── tldr-search/                   # Skill: code search
└── ... (11 more tldr-* skill folders)
```

---

## Requirements

- [tldr-code CLI](https://github.com/parcadei/tldr-code) must be installed
- Node.js (for `npx skills` CLI)
