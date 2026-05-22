# Research Journal 06: Cards and Combinatorics Protocol

> **The bridge from dossiers to skills.** Journal 04 produced 66 probe-backed dossiers — the authoritative *specification* of every `tldr` subcommand. This journal defines the next research layer: two intermediate document corpora that distill those dossiers into the prose materials from which skill files will eventually be authored.

## Why this exists

The 66 dossiers under `research/tldr/` are *evidence-grade* artifacts. They are the right shape for an auditor who needs to verify "does `tldr search` actually do X?" — sections for ground truth, source-code reality, probe matrix, output shape.

They are the **wrong shape** for two downstream consumers:

1. **A future skill author** who needs to write a 20–60 line SKILL.md with rich trigger language and sharp opinions. The dossier's 200–500 lines of evidence don't compress directly into that — you need an intermediate layer that already speaks in agent-relevant prose.
2. **An LLM at runtime** that needs to decide between sibling tools (e.g., `search` vs `semantic`), or chain tools across groups (e.g., `change-impact` → `whatbreaks`). The dossier per-command structure doesn't surface cross-tool wisdom.

This journal defines **two new corpora** that bridge that gap. Both are explicitly **intermediate maintenance documents**: they are not skills, not user-facing, not optimized for runtime token budget. They are the *thinking documents* from which final skills will be authored.

## The two corpora

| Corpus | Folder | Granularity | Purpose |
|--------|--------|-------------|---------|
| **Tool cards** | `research/tool-cards/` | One per CLI command (66 files) | Agent-relevant prose for a single tool: what it does, why reach for it, when (not) to use, killer detail |
| **Tool combinatorics** | `research/tool-combinatorics/` | One per *lens applied to a toolset* | Cross-tool reasoning patterns: how to combine, compare, sequence, or pick between related tools |

Both layers are written in **third person**, **opinionated**, **sharp**. They earn their place in the research corpus only if they add interpretation the underlying dossier or `--help` text does not.

---

## Phase 1: Tool cards

### Purpose

For each of the 66 commands, capture a tight prose card that an LLM (or a future skill author) can read in one breath and walk away with a working mental model of the tool — including the non-obvious tradeoffs and footguns the dossier surfaces.

### Structure (mandatory sections, in this order)

```markdown
# tldr <command>

**Pitch** (1 sentence): What it does, in agent-relevant terms.

**Why reach for it** (2-4 bullets): The unique value — speed, determinism,
token cost, capability that's impossible/painful without it.

**When to use** (3-5 bullets): Triggering situations, written as cues an
LLM might recognize ("about to read more than 2 files to find X").

**When NOT to use** (1-3 bullets): The anti-patterns. Cheaper alternatives
or wrong tool for the job.

**Output in plain words** (1-2 sentences): What you actually get back, in
prose. Not the JSON schema.

**Killer detail** (1 sentence): The non-obvious thing that separates this
from sibling tools — the "if you only remember one thing".

**Other footguns** (OPTIONAL, 1–3 bullets): Additional non-obvious failure
modes that didn't make the singular killer-detail slot. Use ONLY when the
dossier surfaces multiple unrelated traps of comparable severity.

**Source**: `research/tldr/<group>/<cmd>.md`
```

### Target size

~200 words per card (cards with the optional "Other footguns" section may
run to ~250 words).

> **Rule of thumb on "Other footguns":** If you find yourself using this
> section in more than ~1 in 3 cards, you're over-using it. The discipline
> of forcing a singular killer detail is load-bearing — the optional
> section is a relief valve for genuinely multi-trap commands, not a dump
> for every minor caveat. All 66 cards together ≈ 13K words — small enough that multiple cards can be loaded into a single context window during synthesis.

### Anti-patterns

- ❌ **Mechanically restating `--help`.** The card adds zero value if the LLM could derive it from the CLI itself.
- ❌ **Hedging.** "Both have their place" is never the right verdict. Pick a default; name the exceptions explicitly.
- ❌ **First or second person.** Third person matches Anthropic's skill-description convention; lets us paste prose directly into skill descriptions later.
- ❌ **Restating the dossier.** Cards are *interpretation*, not summary. If the dossier already says it cleanly, link there.

> **Rule of thumb:** If a card just paraphrases the dossier, it failed. The card's job is to surface the *opinion* the dossier evidence supports.

### Authoring source

Each card is written by reading the corresponding `research/tldr/<group>/<cmd>.md` dossier in full — particularly the Agent Synthesis section (which already speaks in opinion form). The card is the dossier's voice, compressed and sharpened.

---

## Phase 2: Tool combinatorics

### Two doc types

After the pilot for `search` + `overview` (12 cards → 4 combinatorics docs), it became clear that combinatorics content has two natural shapes, with different cost/benefit tradeoffs. Phase 2 therefore distinguishes **two doc types**:

| Doc type | Purpose | Granularity | Loaded when |
|----------|---------|-------------|-------------|
| **Family-chooser** | Help the LLM pick between sibling tools that all solve a related problem (e.g., `search` vs `semantic` vs `similar` vs `dice`) | One per sub-family; small, targeted | LLM is at a choice point and needs the discriminator |
| **Orchestration** | Help the LLM execute a workflow across a toolset under multiple possible lenses (e.g., codebase-orientation under canonical vs rapid vs pre-change lens) | One per topic; contains all lens treatments internally as sub-sections | LLM is doing a workflow and benefits from seeing all lens options together |

**File naming convention:**
- Family-chooser docs: `<topic>-family-chooser.md` (e.g., `locating-code-family-chooser.md`)
- Orchestration docs: `<topic>-orchestration.md` (e.g., `security-audit-orchestration.md`)
- Pure single-lens docs (rare): `<topic>-<lens>.md` — only when one lens treatment must be loaded in true isolation

> **Rule of thumb:** Default to one orchestration doc per topic that contains all lens sections internally. Split into pure single-lens docs only when the lens treatments are large enough (>1,500 words each) that joint loading wastes context, OR when the lens treatments are written by genuinely different authors who'd diverge in voice if asked to share a file.

### Why this split

The orchestration doc model trades **file count** for **per-file size**:
- Many-small-docs model (one file per lens): ~40 combinatorics docs at full scale, each ~500 words
- Orchestration model: ~20 combinatorics docs at full scale, each ~1,500–2,500 words (containing multiple lens sections)

The orchestration model halves the surface area to maintain. It preserves the lens-first *content* discipline (each lens still has its own sharp, opinion-rich section internally) but consolidates the *file* structure. Family-chooser docs stay separate because they're small, targeted, and loaded by an LLM in a different mental mode (picking between siblings, not executing a workflow).

### The breakthrough: lens-first organization

Phase 2 is organized by **lens applied to a toolset**, not by toolset alone. The same set of tools can serve multiple distinct intents, and each intent surfaces a different tradeoff. Collapsing them into a single document loses the distinction that is actually load-bearing.

> **Rule of thumb:** A toolset describes the *what*. A lens describes the *why*. The combinatoric corpus is organized by the why.

#### Worked example

Consider the toolset `{change-impact, whatbreaks, trace impact}`. The same three tools serve at least four distinct reasoning patterns:

| Lens | The question this lens answers |
|------|-------------------------------|
| **Canonical / best-practice** | "What's the textbook way to use these tools when planning a change?" |
| **Risk-first / break-discovery** | "Where will this break? Find that first, then decide whether the rest is worth investigating." |
| **Design archaeology** | "Why is the code shaped this way? What invariants did the original author care about?" |
| **Defensive / what-am-I-missing** | "I've done the obvious analysis — what would I miss if I stopped here?" |

Each lens visits the same three tools but in different order, with different emphasis, surfacing different insights. **Four documents, three tools, four reasoning patterns.** Collapsing these into one "impact analysis playbook" would lose the angle that actually matters in each case.

### Structure (per combinatorics document)

```markdown
# Lens: <name of the intent/angle>

**The question this lens answers** (1 sentence)

**Toolset** (the SET — order-agnostic): <list>

**Why this lens, why these tools** (2-3 sentences — what's the angle?)

**Moves** (loose, not strict sequence — order is not the point, the
tradeoff is):
- Move 1: <tool> for <purpose>
- Move 2: <tool> for <purpose>
- Move 3: <tool> for <purpose>

**What this lens captures** (insights this approach surfaces)

**What this lens misses** (other lenses on the same toolset that catch
different things — link to siblings)

**Pair with** (complementary lenses, with links)

**Sources** (links to relevant tool cards)
```

### Target size

400–900 words per document. Combinatorics docs can breathe more than cards because they are pattern-level and reasoning-dense.

> **Empirical note from the 16-doc Phase 2 Step 1 batch:** docs ran 451–884 words, clustering around 700. Audit and fix family-choosers naturally ran toward the upper end because the underlying tool cards surface dense silent-failure footguns that the "Common mistakes" section must surface to discriminate siblings. **Do not force shorter docs at the cost of cutting sibling-discriminating content** — that's exactly the highest-value section.

### The "pick a default" rule has two acceptable forms

A family-chooser doc MUST commit to a default. There are two acceptable shapes:

1. **Single default** with named exceptions — e.g., "`tldr search` is the default; escalate to `tldr semantic` when no shared vocabulary exists."
2. **Intent-conditional defaults** — e.g., for `audit-api-design`: "`patterns` for LLM onboarding, `interface` for refactor capture, `api-check` for CI gating, `inheritance` for hierarchy review." Each intent has a clear default; the doc doesn't pretend the intents collapse.

What is NEVER acceptable: **hedging** — phrases like "all have their place," "depends on context," "use whichever fits" without naming the contexts. That is the failure mode the family-chooser doc exists to prevent.

> **Empirical note from Phase 2 Step 1:** 5 of 14 family-choosers settled on intent-conditional defaults rather than single defaults (36%). The intent-conditional form is not a fallback — it's the right answer when the family genuinely serves multiple incompatible intents (e.g., extract surface vs detect misuse vs check CI). Forcing a single default in those cases would be lying to the LLM.

### File naming convention

`<topic>-<lens>.md` — e.g., `impact-analysis-canonical.md`, `impact-analysis-archaeology.md`. Topic-first sorts related lenses together in a directory listing.

### Anti-patterns

- ❌ **Repeating Phase 1 content.** Cards describe individual tools. Combinatorics describes the *interaction*. If a doc is just "tool A does X, tool B does Y, tool C does Z," it belongs in three cards, not one combinatorics doc.
- ❌ **Speculative combinations.** Only document combinations you've verified work. A hypothetical "you could pipe X to Y" earns its place only after someone runs it.
- ❌ **Generic platitudes.** "Use multiple tools together" is not a pattern. Be specific about which tools, which lens, which tradeoff.
- ❌ **Forcing multi-lens treatment everywhere.** Most toolsets get one useful lens. Multi-lens is for cases where additional lenses *actually* surface different tradeoffs.

### Emergence over taxonomy

Do **not** predefine the full list of lenses up front. Lenses emerge from reading the Phase 1 cards and asking "what reasoning patterns do I actually use with these tools?" Forcing content into a pre-chosen lens taxonomy will produce hollow docs.

A starter brainstorm of *possible* lens families — not a mandate, just priming:

- Canonical / textbook
- Risk-first / break-discovery
- Archaeology / rationale recovery
- Defensive / what-am-I-missing
- Onboarding / orientation
- Pre-refactor / change planning
- Post-bug / hindsight
- Performance / hot-path
- Audit / compliance
- Knowledge extraction

Expect the real corpus to have 15–30 combinatorics docs across ~5–8 lens families that actually earn their keep.

---

## Discipline carried over from earlier journals

This protocol does **not** replace Journals 03 and 04. The dossiers remain the authoritative spec. Cards and combinatorics docs are *derivative* — they inherit their authority from the dossier evidence, not from independent claims.

| Claim type | Where it lives |
|-----------|----------------|
| "This command takes flag `-X` with default value Y" | Dossier (probe-verified) |
| "This command is fast and deterministic" | Card (interpretation of probe evidence) |
| "Use this command before that command when planning a refactor" | Combinatorics doc (cross-tool reasoning) |
| "When picking between A, B, C — start with A" | Combinatorics doc (lens: family chooser) |

If a card or combinatorics doc makes a factual claim that contradicts its source dossier, the dossier wins. If the dossier is wrong, fix the dossier first (re-run probes per Journal 04) before updating the derivative docs.

---

## Why this is the right intermediate layer

The end goal is rewriting the 14 `tldr-*/SKILL.md` files using progressive disclosure (per Anthropic's authoring best practices, captured in `research/agent-skills-authoring/02_KEY_INSIGHTS.md`). Skills need:

- A trigger-rich, third-person description (broad activation surface)
- A concise body that points to deeper material on demand
- Sharp, opinionated guidance — not balanced overviews

Cards provide the **tool-level opinion source**. Combinatorics provides the **cross-tool reasoning source**. Together they give a skill author the raw material to write a tight SKILL.md that captures both the per-tool pitch and the orchestration intelligence — without having to re-derive either from raw dossier evidence.

> **Rule of thumb:** A skill written from cards + combinatorics should be defensible: every claim in it should trace back to a card (and through the card to a dossier) or to a combinatorics doc.

---

## Execution order

1. **Phase 1 (cards) first, batched.** All 66 cards can be authored in parallel — each one only needs its own dossier as input. No cross-tool reasoning required.
2. **Phase 2 (combinatorics) second, emergent.** After all cards exist, sit with them. Identify the toolsets and lenses that actually have something to say. Write the high-value patterns first, not the comprehensive matrix.
3. **Pilot before bulk on Phase 2.** Write 2–3 combinatorics docs by hand, evaluate the format, refine the structure, then scale.

---

## Open questions to resolve during execution

These are deliberately left undecided here — they should be answered by the practice, not by upfront speculation:

1. **How granular should "toolset" be?** Strict family groupings (e.g., the 5 search commands) or freely-formed cross-group sets (e.g., `change-impact` + `cohesion` + `clones`)?
2. **Should combinatorics docs cite specific probes** from `research/tldr/<group>/<cmd>.probes/`, or just cite the dossier?
3. **At what corpus size do we start consolidating?** Anthropic warns of skill "recall limits"; the same likely applies to combinatorics docs. If we end up with 40 lens docs, are some redundant?
4. **Do lens families recur across toolsets?** If "archaeology" applies to both impact-analysis and refactor-planning, is there shared structure worth factoring out?

---

## Cross-references

- **Journal 03** — establishes "Zero Trust in Documentation" principle
- **Journal 04** — operational protocol for the dossier evidence layer
- **Journal 07** — the skill architecture decision that this layer feeds into (14 intent-aligned skills, no router, cards inlined per skill)
- **`agent-skills-authoring/02_KEY_INSIGHTS.md`** — Anthropic's skill-authoring guidance that motivates the final skill rewrite
- **`tldr/<group>/<cmd>.md`** — the dossier evidence each card and combinatorics doc must defer to
