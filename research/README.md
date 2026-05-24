# Research Index: TLDR-Code CLI Surface

This `research/` directory serves as a living audit and verification workspace. Its purpose is to methodically verify the [tldr-code](https://github.com/parcadei/tldr-code) documentation against the actual Rust implementation before writing any agent skills.

We follow the **"Trust but Verify"** principle. Documentation drifts; code does not. 

By creating a dedicated markdown file for every single CLI command, we can easily track execution logic, exact flag arguments, and discrepancies without cluttering the main agent prompts.

---

## The 69-Command Surface Area

The commands are grouped logically by the agent skill they will eventually power. Click any command to view its audit dossier.

### 1. `overview/` (L1 AST Discovery)
* [definition](./tldr/overview/definition.md)
* [explain](./tldr/overview/explain.md)
* [extract](./tldr/overview/extract.md)
* [importers](./tldr/overview/importers.md)
* [imports](./tldr/overview/imports.md)
* [structure](./tldr/overview/structure.md)
* [tree](./tldr/overview/tree.md)

### 2. `search/` (Semantic & Content)
* [context](./tldr/search/context.md)
* [dice](./tldr/search/dice.md)
* [search](./tldr/search/search.md)
* [semantic](./tldr/search/semantic.md)
* [similar](./tldr/search/similar.md)

### 3. `trace/` (L2 Call Graph & Impact)
* [calls](./tldr/trace/calls.md)
* [dead](./tldr/trace/dead.md)
* [hubs](./tldr/trace/hubs.md)
* [impact](./tldr/trace/impact.md)
* [references](./tldr/trace/references.md)
* [whatbreaks](./tldr/trace/whatbreaks.md)

### 4. `deep/` (L3-L5 State & Data Flow)
* [available](./tldr/deep/available.md)
* [cfg](./tldr/deep/cfg.md)
* [chop](./tldr/deep/chop.md)
* [dead-stores](./tldr/deep/dead-stores.md)
* [dfg](./tldr/deep/dfg.md)
* [reaching-defs](./tldr/deep/reaching-defs.md)
* [slice](./tldr/deep/slice.md)

### 5. `audit/` (Quality, Security & Patterns)
* [api-check](./tldr/audit/api-check.md)
* [churn](./tldr/audit/churn.md)
* [clones](./tldr/audit/clones.md)
* [cognitive](./tldr/audit/cognitive.md)
* [cohesion](./tldr/audit/cohesion.md)
* [complexity](./tldr/audit/complexity.md)
* [contracts](./tldr/audit/contracts.md)
* [coupling](./tldr/audit/coupling.md)
* [coverage](./tldr/audit/coverage.md)
* [debt](./tldr/audit/debt.md)
* [halstead](./tldr/audit/halstead.md)
* [health](./tldr/audit/health.md)
* [hotspots](./tldr/audit/hotspots.md)
* [inheritance](./tldr/audit/inheritance.md)
* [interface](./tldr/audit/interface.md)
* [invariants](./tldr/audit/invariants.md)
* [loc](./tldr/audit/loc.md)
* [patterns](./tldr/audit/patterns.md)
* [resources](./tldr/audit/resources.md)
* [secure](./tldr/audit/secure.md)
* [smells](./tldr/audit/smells.md)
* [specs](./tldr/audit/specs.md)
* [taint](./tldr/audit/taint.md)
* [temporal](./tldr/audit/temporal.md)
* [verify](./tldr/audit/verify.md)
* [vuln](./tldr/audit/vuln.md)

### 6. `fix/` (Autonomous Repair)
* [bugbot](./tldr/fix/bugbot.md)
* [diagnostics](./tldr/fix/diagnostics.md)
* [fix-apply](./tldr/fix/fix-apply.md)
* [fix-check](./tldr/fix/fix-check.md)
* [fix-diagnose](./tldr/fix/fix-diagnose.md)

### 7. `ops/` (Daemon & Workflow)
* [cache](./tldr/ops/cache.md)
* [change-impact](./tldr/ops/change-impact.md)
* [daemon](./tldr/ops/daemon.md)
* [deps](./tldr/ops/deps.md)
* [diff](./tldr/ops/diff.md)
* [doctor](./tldr/ops/doctor.md)
* [stats](./tldr/ops/stats.md)
* [surface](./tldr/ops/surface.md)
* [todo](./tldr/ops/todo.md)
* [warm](./tldr/ops/warm.md)

---

## Audit Workflow

The canonical operational rulebook is [`04_PROBE_PROTOCOL.md`](./04_PROBE_PROTOCOL.md). Every dossier must follow that protocol. Quick summary:

1. **Pin the environment** — `tldr --version`, target repo + commit, daemon state, OS, date.
2. **Capture `--help` verbatim** — the Ground Truth section.
3. **Run the Probe Matrix** — mandatory P01–P05 (happy small, happy scale, missing arg, bad path, format rejection) plus conditional rows per Journal 04 §4.3. Use the canonical [`_TEMPLATES/probe.sh`](./_TEMPLATES/probe.sh) so probes are regeneratable.
4. **Document the Output Shape** — explicit JSON contract: top-level keys, nested structures, empty case, error case, typical size.
5. **Read the Rust source** — cite `crates/<crate>/src/<file>.rs:LNNN`. Look for arg validators, hardcoded limits, daemon-route shortcuts, fallback paths, format validators.
6. **Write Architectural Deep Dive + Intent & Routing** — explain the engine and routing logic.
7. **Distill the Agent Synthesis** — must reflect every flag exercised, every recovery hint from failure probes, every composition prerequisite.
8. **Verify with `bash _TEMPLATES/audit.sh <dossier-path>`** — mechanical check of the structural compliance items.

Historical journals 01, 02, 03 record how this protocol evolved. Journal 03 establishes the *principle* ("Zero Trust in Documentation"); Journal 04 is the enforceable rulebook.

Templates live in [`_TEMPLATES/`](./_TEMPLATES/) — `dossier.md` (the scaffold to copy), `probe.sh` (regeneratable probe script), `audit.sh` (mechanical compliance check), `tool-card.md` (the card scaffold, includes Usage-block guardrail).

## From Dossiers to Skills — the downstream pipeline

Once dossiers exist, [`06_CARDS_AND_COMBINATORICS_PROTOCOL.md`](./06_CARDS_AND_COMBINATORICS_PROTOCOL.md) describes the next two layers:

| Layer | Location | Purpose |
|-------|----------|---------|
| **Tool cards** | `tool-cards/<group>/<cmd>.md` | One per command — agent-relevant prose, killer detail, Usage block |
| **verified-invocations.md** | `tool-cards/<group>/verified-invocations.md` | Per-group canonical `--help` Usage lines + full probe table. **Single source of truth for CLI syntax.** |
| **Tool combinatorics** | `tool-combinatorics/<lens>.md` | Cross-tool reasoning — when to chain, compare, or choose between sibling tools |
| **SKILL.md** | `../<skill-name>/SKILL.md` | The live agent skill, authored from cards + combinatorics + verified-invocations |

**Critical authoring rule (discovered 2026-05-24):** Before writing any `Usage:` block in a tool card or SKILL.md, copy the syntax verbatim from the group's `verified-invocations.md`. Never reconstruct from prose — that is how hallucinated flags get introduced. See §16 of [`agent-skills-authoring/02_KEY_INSIGHTS.md`](./agent-skills-authoring/02_KEY_INSIGHTS.md).