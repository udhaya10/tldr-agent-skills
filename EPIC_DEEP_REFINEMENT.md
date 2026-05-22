# BEADS EPIC: Deep Refinement of TLDR Commands

> **⚠️ SUPERSEDED.** This epic captured the original framing for command-by-command refinement (~13 skills × 60 commands, checkbox-tracked). It has been **superseded by the operational research arc**:
>
> - **[research/04_PROBE_PROTOCOL.md](research/04_PROBE_PROTOCOL.md)** — the operational rulebook that replaced the informal "Deep Refinement Methodology" below. All 64 active commands were processed under Journal 04 (Ralph-driven, probe-verified, structurally audited 17/17).
> - **[research/06_CARDS_AND_COMBINATORICS_PROTOCOL.md](research/06_CARDS_AND_COMBINATORICS_PROTOCOL.md)** — the bridge from dossiers to skills (cards + combinatorics layers).
>
> The checkbox backlog below is **fully completed** — every command has a dossier, a tool card, and at least one combinatorics doc citing it. This file is kept as historical context for the project's evolution; do not use it as the current task list.

---

**Original objective (now obsolete):** Systematically revisit all 60 `tldr-code` commands across our 13 skills. For each command, we will apply the "Deep Refinement Methodology" to uncover its true architectural mechanics, LLM-specific value proposition, and edge cases. We will then update the research dossiers and `SKILL.md` files to capture these expert nuances.

## 🔬 The Deep Refinement Methodology (Per Command)
1. **Architectural Deep Dive:** How does it work under the hood? (AST vs SQLite vs PDG vs Git history).
2. **Agentic Value Proposition:** Why does an LLM care? What manual work or token-waste does this command replace?
3. **Edge Cases & LLM Constraints:** Are there mandatory flags (`--quick`, `--max-results`) needed to prevent context blowout or hallucinations?
4. **Collaborative Synthesis:** Present findings to the user for approval.
5. **Repository Injection:** Update `research/.../*.md` and the corresponding `SKILL.md` file.

---

## 📋 Task Backlog (60 Commands)

### 1. `tldr-overview` (Discovery & Architecture)
- [ ] `tldr structure`
- [ ] `tldr tree`
- [ ] `tldr extract`
- [ ] `tldr explain`
- [ ] `tldr imports`
- [ ] `tldr importers`
- [ ] `tldr deps`
- [ ] `tldr definition`

### 2. `tldr-search` (Semantic & Content Search)
- [ ] `tldr semantic`
- [ ] `tldr search`
- [ ] `tldr similar`
- [ ] `tldr context`
- [ ] `tldr dice`

### 3. `tldr-trace` (Dependency & Blast Radius)
- [ ] `tldr impact`
- [ ] `tldr references`
- [ ] `tldr whatbreaks`
- [ ] `tldr calls`
- [ ] `tldr hubs`
- [ ] `tldr dead`

### 4. `tldr-deep` (Hard Debugging & State Tracking)
- [ ] `tldr slice`
- [ ] `tldr chop`
- [ ] `tldr reaching-defs`
- [ ] `tldr available`
- [ ] `tldr dead-stores`

### 5. `tldr-audit` (Batch QA & Vulnerability)
- [ ] `tldr health`
- [ ] `tldr smells`
- [ ] `tldr vuln`
- [ ] `tldr secure`
- [ ] `tldr clones`
- [ ] `tldr debt`
- [ ] `tldr complexity`
- [ ] `tldr cognitive`
- [ ] `tldr cohesion`

### 6. `tldr-fix` (Autonomous Repair)
- [ ] `tldr bugbot` (bugbot check)
- [ ] `tldr diagnostics`
- [ ] `tldr fix check`
- [ ] `tldr fix diagnose`
- [ ] `tldr fix apply`

### 7. `tldr-ops` (Infrastructure)
- [x] `tldr todo` *(Completed during prototyping)*
- [ ] `tldr daemon`
- [ ] `tldr warm`
- [ ] `tldr diff`
- [ ] `tldr change-impact`
- [ ] `tldr stats`

### 8. `tldr-refactor-history` (Git Coupling)
- [ ] `tldr temporal`
- [ ] `tldr hotspots`
- [ ] `tldr churn`

### 9. `tldr-refactor-oo` (Object-Oriented)
- [ ] `tldr coupling`
- [ ] `tldr inheritance`

### 10. `tldr-formal-methods` (Safety Proofs)
- [ ] `tldr contracts`
- [ ] `tldr invariants`
- [ ] `tldr specs`
- [ ] `tldr resources`

### 11. `tldr-api-stability` (API Boundaries)
- [ ] `tldr api-check`
- [ ] `tldr interface`
- [ ] `tldr patterns`

### 12. `tldr-metrics-raw` (CI/CD Reporting)
- [ ] `tldr loc`
- [ ] `tldr halstead`
- [ ] `tldr coverage`

### 13. `tldr-security-taint` (Granular Tracing)
- [ ] `tldr taint`

---
*Note: We will process these skill-by-skill. Once a skill group is completed, we will commit and push the updates.*
