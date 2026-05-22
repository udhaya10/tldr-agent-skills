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
| **Skill rewrite** (14 new intent-aligned `tldr-*` skills) | ✅ Complete | 14 |

The 14 skills below are intent-aligned (named after what the user wants to do, not after the underlying CLI group), self-contained (no external file references — cards inlined directly), and self-routing (no router skill needed; sharp descriptions match user intent).

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

## The 14 Skills

| Skill | Intent it triggers on | Key Commands |
|-------|----------------------|--------------|
| **tldr-locate-code** | "Find code I don't already have the name/path for" | search, semantic, similar, dice, context |
| **tldr-understand-function** | "Tell me about this named function" | definition, explain, extract, context |
| **tldr-orient-codebase** | "Help me get oriented in this codebase" | tree, structure, extract, importers, imports |
| **tldr-trace-relationships** | "Trace call/usage/dependency relationships at function level" | calls, references, impact, dead |
| **tldr-trace-data-flow** | "Trace values, definitions, expressions at variable level" | slice, chop, reaching-defs, available, dead-stores |
| **tldr-change-impact** | "What will break if I change this?" | change-impact, impact, whatbreaks, diff |
| **tldr-architecture** | "Map the codebase's structure, layers, and coupling" | hubs, coupling, cohesion, clones, deps, temporal, structure |
| **tldr-runtime** | "Manage tldr's daemon, cache, and environment" | cache, daemon, warm, stats, doctor |
| **tldr-fix-and-detect** | "Find bugs or apply deterministic fixes" | bugbot, diagnostics, fix-diagnose, fix-check, fix-apply |
| **tldr-audit-security** | "Audit for vulnerabilities and security issues" | secure, taint, vuln |
| **tldr-audit-complexity** | "Measure code complexity and size" | cognitive, complexity, halstead, loc |
| **tldr-audit-smells** | "Find code smells, debt, and refactor priorities" | smells, debt, hotspots, churn, todo, resources, health |
| **tldr-audit-coverage** | "Assess test coverage and specification quality" | coverage, contracts, invariants, verify, specs |
| **tldr-audit-api** | "Audit API design, interfaces, and stability" | api-check, interface, inheritance, patterns, surface |

**Total: 64 active CLI commands** mapped into 14 intent-aligned skills. No router — each skill's description self-routes based on user intent.

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
├── tldr-locate-code/              # Skill: find code by intent
├── tldr-understand-function/      # Skill: inspect a known function
├── tldr-orient-codebase/          # Skill: onboard to a codebase
├── tldr-trace-relationships/      # Skill: function-level call/usage tracing
├── tldr-trace-data-flow/          # Skill: variable-level data flow
├── tldr-change-impact/            # Skill: what breaks if I change this
├── tldr-architecture/             # Skill: structure, coupling, layers
├── tldr-runtime/                  # Skill: daemon, cache, environment
├── tldr-fix-and-detect/           # Skill: detect bugs + deterministic fixes
├── tldr-audit-security/           # Skill: security audit
├── tldr-audit-complexity/         # Skill: complexity metrics
├── tldr-audit-smells/             # Skill: smells, debt, refactor priorities
├── tldr-audit-coverage/           # Skill: test coverage and specs
└── tldr-audit-api/                # Skill: API design and stability
```

---

## Requirements

- [tldr-code CLI](https://github.com/parcadei/tldr-code) must be installed
- Node.js (for `npx skills` CLI)
