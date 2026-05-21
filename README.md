# TLDR Agent Skills

A suite of **14 intent-driven agent skills** designed to give Large Language Models (LLMs) autonomous mastery over the [parcadei/tldr-code](https://github.com/parcadei/tldr-code) AST engine.

The `tldr-code` CLI is an incredibly powerful static analysis tool containing **60+ commands**. This repository systematically decomposes that raw CLI into modular, Progressive Disclosure skills (like `tldr-search`, `tldr-fix`, and `tldr-audit`) so agents like Claude Code, Cursor, or OpenHands can use them without hallucinating flags or suffering from cognitive overload.

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

| Skill | Purpose | Key Commands |
|-------|---------|--------------|
| **tldr-router** | Orchestrator - routes intent to appropriate skill | Intent analysis, skill selection |
| **tldr-overview** | Token-efficient codebase discovery | tree, structure, extract, explain, imports, importers, deps, definition |
| **tldr-search** | Semantic code search | semantic, search, context, similar, dice |
| **tldr-trace** | Call graph and impact analysis | calls, impact, hubs, whatbreaks, dead, references |
| **tldr-deep** | Deep code slicing and data flow | slice, chop, reaching-defs, available, dead-stores |
| **tldr-audit** | Quality, security, complexity analysis | health, smells, vuln, secure, clones, debt, complexity, cohesion |
| **tldr-fix** | Autonomous bug repair | bugbot, diagnostics, fix check/apply/diagnose |
| **tldr-ops** | Infrastructure and caching | daemon, warm, change-impact, diff, stats, todo |
| **tldr-refactor-history** | Git history refactoring | temporal, churn, hotspots |
| **tldr-refactor-oo** | Object-oriented analysis | coupling, inheritance |
| **tldr-formal-methods** | Formal verification | contracts, invariants, resources, specs |
| **tldr-api-stability** | API boundary checking | api-check, interface, patterns |
| **tldr-metrics-raw** | Code metrics | loc, halstead, coverage |
| **tldr-security-taint** | Security taint analysis | taint (SQLi, XSS, command injection) |

**Total: 47 CLI commands** mapped into 14 skills.

---

## Directory Structure

```
tldr-agent-skills/
├── README.md
├── REPOSITORY_STRUCTURE.md
├── LICENSE
├── research/                     # 66 research dossiers for all CLI commands
│   └── tldr/
│       ├── overview/            # tree, structure, extract, explain, deps, etc.
│       ├── search/             # semantic, search, context, similar, dice
│       ├── trace/              # calls, impact, hubs, whatbreaks
│       ├── deep/               # slice, chop, reaching-defs
│       ├── audit/              # health, smells, clones, complexity
│       ├── fix/                # bugbot, diagnostics, fix check
│       └── ops/                # daemon, warm, diff
├── tldr-router/                # SKILL.md - Orchestrator
├── tldr-overview/              # SKILL.md - Codebase discovery
├── tldr-search/               # SKILL.md - Semantic search
├── tldr-trace/                # SKILL.md - Call graph tracing
├── tldr-deep/                 # SKILL.md - Deep analysis
├── tldr-audit/                # SKILL.md - Quality audit
├── tldr-fix/                  # SKILL.md - Autonomous repair
├── tldr-ops/                  # SKILL.md - Infrastructure
├── tldr-refactor-history/     # SKILL.md - History refactoring
├── tldr-refactor-oo/          # SKILL.md - OOP analysis
├── tldr-formal-methods/       # SKILL.md - Formal verification
├── tldr-api-stability/        # SKILL.md - API stability
├── tldr-metrics-raw/          # SKILL.md - Code metrics
└── tldr-security-taint/       # SKILL.md - Security analysis
```

Each `tldr-*/SKILL.md` contains:
- YAML frontmatter (`name`, `description`, `allowed-tools`)
- When to use the skill
- Supported commands with usage examples
- Crucial rules to prevent hallucinations

---

## Research Documentation

- [Empirical Research Methodology](research/03_EMPIRICAL_RESEARCH_METHODOLOGY.md) - How commands were selected
- [Omitted Commands Rationale](research/05_OMITTED_COMMANDS_RATIONALE.md) - 19 commands intentionally hidden

---

## Requirements

- [tldr-code CLI](https://github.com/parcadei/tldr-code) must be installed
- Node.js (for `npx skills` CLI)
