# Repository Structure & Skill Authoring Guide

This document defines how folders and files must be structured in this repository to remain compatible with the [Agent Skills ecosystem (`npx skills`)](https://agentskills.io/).

## 1. The Root Layout (Flat Hierarchy)

The Agent Skills CLI expects skills to be discoverable at the top level of the repository. Do not nest skills deeply inside arbitrary subfolders (like `src/skills/` or `tldr/skills/`). 

Every skill must be its own top-level directory.

**Correct Layout:**
```text
agentic-utils/
├── tldr-router/         # Top-level directory for Skill 1
├── tldr-overview/       # Top-level directory for Skill 2
├── tldr-fix/            # Top-level directory for Skill 3
├── REPOSITORY_STRUCTURE.md
└── README.md
```

## 2. Anatomy of a Skill Folder

Inside each skill folder, the only strictly required file is `SKILL.md`. However, complex skills can use standardized subdirectories.

```text
tldr-fix/
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
name: tldr-fix
description: Autonomous repair loop. Diagnoses compiler errors, fixes bugs, and re-runs tests.
allowed-tools: [Bash, Read, Edit]
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

Based on our architectural decomposition and empirical research, the repository is structured with 14 specialized skills to accommodate the full `tldr-code` suite:

```text
agentic-utils/
│
├── tldr-router/               # Orchestrator
├── tldr-overview/             # L1 AST: tree, structure, extract, imports
├── tldr-search/               # Semantic: semantic, search, context, similar, dice
├── tldr-trace/                # L2 Graph: calls, impact, hubs, whatbreaks
├── tldr-deep/                 # L3-L5 Flow: slice, chop, reaching-defs
├── tldr-audit/                # Batch QA: health, smells, clones
├── tldr-fix/                  # Autonomous: fix check, bugbot, diagnostics
├── tldr-ops/                  # Infrastructure: daemon, warm, change-impact, diff
├── tldr-refactor-history/     # Git Coupling: temporal, hotspots, churn
├── tldr-refactor-oo/          # Object-Oriented: coupling, inheritance
├── tldr-formal-methods/       # Safety Proofs: contracts, invariants, resources
├── tldr-api-stability/        # API Boundaries: api-check, interface
├── tldr-metrics-raw/          # CI/CD Reporting: loc, halstead, coverage
└── tldr-security-taint/       # Granular tracing: taint
```

By adhering to this flat, modular structure, you can publish this repository once, and users can selectively install `tldr-fix` or `tldr-api-stability` via `npx skills add` without being forced to download unrelated toolsets.