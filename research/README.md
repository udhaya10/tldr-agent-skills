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

For each file above, the audit process is:
1. Parse the official [tldr-code documentation](https://github.com/parcadei/tldr-code/tree/main/docs/commands).
2. Read the actual Rust implementation (e.g., `crates/tldr-cli/src/commands/`).
3. Note any discrepancies between documented flags and actual implemented flags.
4. Finalize the command syntax for use in the agent `SKILL.md` files.