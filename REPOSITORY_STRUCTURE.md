# Repository Structure & Skill Authoring Guide

This document defines how folders and files must be structured in this repository to remain compatible with the [Agent Skills ecosystem (`npx skills`)](https://agentskills.io/).

## 1. The Root Layout (Flat Hierarchy)

The Agent Skills CLI expects skills to be discoverable at the top level of the repository. Do not nest skills deeply inside arbitrary subfolders (like `src/skills/` or `tldr/skills/`). 

Every skill must be its own top-level directory.

**Correct Layout:**
```text
tldr-agent-skills/
├── tldr-locate-code/         # Top-level directory for Skill 1
├── tldr-understand-function/ # Top-level directory for Skill 2
├── tldr-fix-and-detect/      # Top-level directory for Skill 3
├── REPOSITORY_STRUCTURE.md
└── README.md
```

## 2. Anatomy of a Skill Folder

Inside each skill folder, the only strictly required file is `SKILL.md`. However, complex skills can use standardized subdirectories.

```text
tldr-fix-and-detect/
├── SKILL.md             # REQUIRED: The agent prompt, instructions, and frontmatter
├── scripts/             # OPTIONAL: Bash or Python scripts the agent can execute
│   └── run_fix.sh       
└── templates/           # OPTIONAL: JSON/YAML templates the agent might need to read
    └── fix-config.json
```

### Why use `scripts/`?
If your skill requires a complex 50-line bash pipeline, do not write it directly into the `SKILL.md` prompt. Instead, place it in `scripts/my_script.sh`, and tell the agent in `SKILL.md` to run `bash ./scripts/my_script.sh`. This keeps the prompt context small and prevents LLM syntax hallucinations.

## 3. The `SKILL.md` Standard

Every `SKILL.md` must follow a specific structure so the agent harness can parse it correctly.

### Part A: YAML Frontmatter (Metadata)
This must be at the very top of the file. It defines the skill for the CLI.

```yaml
---
name: tldr-fix-and-detect
description: Find bugs in code via static analysis OR apply deterministic fixes. Two branches — detection (bugbot, diagnostics) and repair (fix-diagnose, fix-check, fix-apply).
allowed-tools: [Bash]
---
```
*Note: Only list the tools the agent actually needs (`allowed-tools`). Giving a read-only skill the `Edit` tool is an anti-pattern.*

### Part B: The Body (Agent Instructions)
Keep the body concise (ideally under 200 lines). The body should contain:
1. **When to use this skill:** (Intent triggers)
2. **Methodology:** (How the agent should think/act)
3. **Commands:** (Exact, copy-pasteable bash commands)

---

## 4. Implementation Blueprint: The TLDR Suite

Based on our architectural decomposition (see `research/07_SKILL_ARCHITECTURE_DECISION.md`), the repository is structured with 14 **intent-aligned** skills (no router) to accommodate the full `tldr-code` surface. Each skill triggers on a user intent, not on a CLI group.

```text
tldr-agent-skills/
│
├── tldr-locate-code/          # Find code by name, concept, or pattern (search, semantic, similar, dice, context)
├── tldr-understand-function/  # Inspect a known function (definition, explain, extract, context)
├── tldr-orient-codebase/      # Onboard to a codebase (tree, structure, extract, importers, imports)
├── tldr-trace-relationships/  # Function-level call/usage tracing (calls, references, impact, dead)
├── tldr-trace-data-flow/      # Variable/expression-level data flow (slice, chop, reaching-defs, available, dead-stores)
├── tldr-change-impact/        # What breaks if I change this (change-impact, impact, whatbreaks, diff)
├── tldr-architecture/         # Structure, coupling, layers (hubs, coupling, cohesion, clones, deps, temporal, structure)
├── tldr-runtime/              # Daemon, cache, environment (cache, daemon, warm, stats, doctor)
├── tldr-fix-and-detect/       # Detect bugs + deterministic fixes (bugbot, diagnostics, fix-diagnose/check/apply)
├── tldr-audit-security/       # Security audit (secure, taint, vuln)
├── tldr-audit-complexity/     # Complexity metrics (cognitive, complexity, halstead, loc)
├── tldr-audit-smells/         # Smells, debt, refactor priorities (smells, debt, hotspots, churn, todo, resources, health)
├── tldr-audit-coverage/       # Test coverage and specs (coverage, contracts, invariants, verify, specs)
├── tldr-audit-api/            # API design and stability (api-check, interface, inheritance, patterns, surface)
└── tldr-setup-check/          # META: orientation + diagnose tldr installation (--version, doctor, daemon status, stats, semantic probe)
```

By adhering to this flat, modular structure, you can publish this repository once, and users can selectively install `tldr-fix-and-detect` or `tldr-audit-api` via `npx skills add` without being forced to download unrelated toolsets.

---

## 5. The Research Corpus (`research/`)

The `research/` directory is the **source of truth** that the 14 tool-wrapper skills are authored from (a 15th meta-skill, `tldr-setup-check`, was added later for LLM orientation and is documented in its own SKILL.md). The research folder is intentionally kept separate from the skill folders so that the npx-skills consumer never sees it; only repository contributors and skill authors do.

```text
tldr-agent-skills/
├── research/
│   ├── 01_CLI_DISCOVERY_JOURNAL.md       # How commands were enumerated
│   ├── 02_CLI_HELP_EXTRACTION_JOURNAL.md # How --help was captured
│   ├── 03_EMPIRICAL_RESEARCH_METHODOLOGY.md  # Zero-trust-docs principle
│   ├── 04_PROBE_PROTOCOL.md              # Operational rulebook for dossiers
│   ├── 05_OMITTED_COMMANDS_RATIONALE.md  # Why some commands are excluded
│   ├── 06_CARDS_AND_COMBINATORICS_PROTOCOL.md  # Bridge from dossiers to skills
│   ├── _TEMPLATES/                       # Mandatory templates
│   ├── fixtures/                         # Probe test fixtures
│   ├── tldr/<group>/<cmd>.md             # Layer 1: probe-verified dossiers
│   ├── tool-cards/<group>/<cmd>.md       # Layer 2: agent-oriented prose
│   ├── tool-combinatorics/<topic>.md     # Layer 3: family-chooser + orchestration docs
│   └── agent-skills-authoring/           # Anthropic Agent Skills doc research
└── tldr-*/                               # Skills authored from the corpus
```

When authoring or revising a `tldr-*/SKILL.md`, the canonical source flow is:

```
dossier (evidence)  →  tool card (per-tool prose)  →  combinatorics (cross-tool)  →  SKILL.md
```

Each layer is more compressed and agent-oriented than the layer below it. Skills MUST NOT contradict the dossier evidence; the dossier wins on factual claims.

See [research/06_CARDS_AND_COMBINATORICS_PROTOCOL.md](research/06_CARDS_AND_COMBINATORICS_PROTOCOL.md) for the full protocol governing the cards and combinatorics layers.