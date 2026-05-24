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
| **Skill rewrite** (14 intent-aligned `tldr-*` skills + 1 setup-check meta-skill = 15 total) | ✅ Complete | 15 |

The 15 skills below are intent-aligned (named after what the user wants to do, not after the underlying CLI group), self-contained (no external file references — cards inlined directly), and self-routing (no router skill needed; sharp descriptions match user intent). 14 of them wrap tldr commands by user intent; the 15th (`tldr-setup-check`) is a meta-skill that orients the LLM to tldr itself and diagnoses installation/setup issues.

---

## Quick Install

```bash
npx skills add udhaya10/tldr-agent-skills --all -g
```

Or browse and select individual skills:

```bash
npx skills add udhaya10/tldr-agent-skills -g
```

### About the skill ecosystem

Skills in this repository conform to the **[Agent Skills](https://agentskills.io/) open standard** — originally developed by Anthropic, released as a vendor-neutral spec, and adopted across ~60 agent products including Claude Code, Cursor, OpenAI Codex, Gemini CLI, Goose, GitHub Copilot, VS Code, OpenHands, and many more.

The ecosystem has three layers, and our project touches two of them:

- **The spec** — [agentskills.io](https://agentskills.io/) — defines the SKILL.md format and progressive-disclosure semantics. We follow it.
- **Distribution** — [`vercel-labs/skills`](https://github.com/vercel-labs/skills) — the `npx skills` CLI users run to install. The install command in the section above uses this tool.
- **Client implementation** — every agent product implements discovery/cataloging/activation on its own side. We don't need to do anything here; spec-compliant agents pick up our skills automatically.

The research that informed both the authoring and the ecosystem understanding lives in [`research/agent-skills-authoring/`](research/agent-skills-authoring/) — see `03_ECOSYSTEM_MAP.md` for the full map.

---

## AGENTS.md auto-distribution

Installing skills via `npx skills add` does not clone the repo — it only delivers `SKILL.md` files. There is no standard mechanism for distributing `AGENTS.md` content the same way.

This repo solves that differently: **`tldr-setup-check` bootstraps `AGENTS.md` at runtime**, the first time any agent invokes the skill in a project. On subsequent runs it detects whether the content is stale and updates automatically.

### How it works

`agent-rules.md` (at the root of this repo) contains the tldr-specific agent instructions wrapped in sentinel markers with an embedded hash:

```
<!-- BEGIN TLDR-AGENT-SKILLS hash:2798ef10 -->
...instructions...
<!-- END TLDR-AGENT-SKILLS -->
```

When `tldr-setup-check` reaches Step 7, it:
1. `curl`s `agent-rules.md` from the raw GitHub URL
2. Reads the hash from the fetched file's BEGIN marker
3. Compares it against the hash already in the project's `AGENTS.md`
4. **Hashes match** → no-op, nothing written
5. **Hashes differ** → replaces only the managed block, surrounding content untouched
6. **No marker yet** → creates `AGENTS.md` if missing, appends the block (first install)

After the first run, every future agent session loads the tldr instructions automatically via `AGENTS.md` — the skill only needs to fire once.

### Maintainer workflow

> Full pipeline documented in [MAINTAINER_WORKFLOW.md](MAINTAINER_WORKFLOW.md).

When you edit the body of `agent-rules.md`, you must recompute the hash before pushing:

```bash
# 1. Edit the body between the markers
vim agent-rules.md

# 2. Recompute and stamp the hash
python update_hash.py agent-rules.md
# ✅  agent-rules.md
#     hash: 2798ef10 → <new-hash>

# 3. Push — the new hash is the source of truth on GitHub
git add agent-rules.md && git commit -m "..." && git push
```

`update_hash.py` computes `SHA-256(body)[:4]` (first 4 bytes = 8 hex chars, same algorithm as beads) and stamps it into the BEGIN marker in place. The script takes an optional path argument; it defaults to `agent-rules.md` in the current directory.

Next time any agent runs `tldr-setup-check` in any project, Step 7 will detect the hash mismatch and pull in the updated instructions.

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
| **tldr-setup-check** *(meta)* | "Is tldr installed, latest, and well-configured? What is tldr anyway?" | --version, doctor, daemon status, stats, semantic (probe) — diagnoses and orients; refers to tldr-runtime for management |

**Total: 64 active CLI commands** mapped into 14 intent-aligned tool-wrapper skills, plus 1 meta-skill (`tldr-setup-check`) for LLM orientation and setup diagnosis = 15 skills total. No router — each skill's description self-routes based on user intent. Run `bash bin/check-versions.sh` to see the corpus state with versions.

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
- [Journal 08 — Skill Lifecycle Protocol](research/08_SKILL_LIFECYCLE_PROTOCOL.md) — versioning, deprecation stubs, and the regeneration workflow for keeping skills current as tldr-code evolves

### Agent-skills authoring research

Anthropic's official Agent Skills documentation (scraped 2026-05-22) and our synthesis:

- [Methodology + key insights](research/agent-skills-authoring/)
- Raw doc snapshots in `research/agent-skills-authoring/references/`

### Upstream watchlist

What we need from upstream that doesn't ship yet, plus the verification probes for detecting when each landed:

- [Upstream Watchlist](research/UPSTREAM_WATCHLIST.md) — tracks tldr-code, agentskills.io spec, vercel-labs/skills CLI, and Anthropic Agent Skills docs. Single doc with "what we need / what we watch for / how we'll know / what we do" per upstream.

### TLDR daemon lifecycle research

Source-level investigation of the `tldr-code` daemon (architecture, config schema, what's configurable in v0.4.0 vs what's documented-but-not-implemented). Informs the `tldr-runtime` and `tldr-setup-check` skills:

- [Research methodology](research/tldr-daemon/01_RESEARCH_METHODOLOGY.md) — why we couldn't trust upstream docs and how we verified each claim against source
- [Key findings](research/tldr-daemon/02_KEY_FINDINGS.md) — corrected daemon architecture (per-project, multi-daemon registry), corrections to prior project claims, implications for always-on install design
- [Config reference](research/tldr-daemon/03_CONFIG_REFERENCE.md) — exhaustive `DaemonConfig` schema with every field, every default, every override path (including which ones aren't implemented yet)
- Raw upstream doc snapshots in `research/tldr-daemon/references/`

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
