# Research Journal 08: Skill Lifecycle Protocol

> **The maintenance discipline that keeps shipped skills coherent over time.** Journal 07 locked the skill architecture. This journal locks the operational protocol for keeping those skills versioned, traceable to research, and gracefully evolved (or retired) as `tldr-code` itself evolves.

## Why this exists

After completing the skill rewrite (14 intent-aligned skills), three lifecycle gaps became visible:

1. **No way to track skill versions.** Users on `npx skills update` would get new content with no indication of what changed or how big the change was.
2. **No way to trace a shipped skill back to the research evidence that produced it.** If a user reports "your `tldr-locate-code` skill claims X but the actual behavior is Y," there was no fast path from the skill to the underlying probe-verified dossier.
3. **No graceful retirement path.** When we deleted the 15 old skills in commit `0c6084f` without deprecation stubs, anyone who had `npx skills add`'d the old corpus before our restructure would have seen those skills silently disappear from their next `npx skills update` (per `vercel-labs/skills` PR #1218 which added "remove deleted skills" prompting).

Journal 08 fixes all three with metadata conventions, a deprecation stub pattern, and a regeneration workflow.

> **Rule of thumb:** Every shipped skill carries enough metadata that (a) the user can see what version they have, (b) a maintainer can trace its claims back to research evidence, and (c) a retirement can be announced before the folder is deleted.

---

## The metadata schema (locked)

Every active skill MUST carry this frontmatter:

```yaml
---
name: tldr-<skill-name>
description: <trigger-rich description>
allowed-tools: [Bash]
compatibility: "Requires tldr-code CLI v0.4.0+. Tested on darwin and linux."
metadata:
  version: "1.0.0"
  author: "udhaya10"
  repository: "udhaya10/tldr-agent-skills"
  tldr.cli-version: "0.4.0"
  tldr.research-commit: "<short git SHA>"
  tldr.commands-wrapped: "<comma-separated list of wrapped tldr CLI commands>"
---
```

| Field | Where it lives | Purpose |
|-------|---------------|---------|
| `compatibility` | **First-class spec field** (not metadata) | Spec-aware clients can warn users on CLI version mismatch |
| `metadata.version` | metadata | Semantic version; bumped per the rules below |
| `metadata.author` | metadata | Attribution |
| `metadata.repository` | metadata | Back-pointer when reading the installed SKILL.md |
| `metadata.tldr.cli-version` | metadata | Machine-readable companion to `compatibility` |
| `metadata.tldr.research-commit` | metadata | Git SHA of the research/ snapshot that produced this skill |
| `metadata.tldr.commands-wrapped` | metadata | The underlying CLI commands; enables searchability and impact analysis |

All `tldr.*` keys use the `tldr.` namespace per the agentskills.io spec's recommendation to namespace project-specific metadata.

### When to bump `metadata.version`

Semantic versioning, but anchored to the skill's *contract with the LLM*:

| Change type | Bump | Example |
|-------------|------|---------|
| Description, trigger phrases, or wording polish that doesn't change which commands the skill wraps or which tool defaults it recommends | **PATCH** (1.0.0 → 1.0.1) | Typo fix; clearer wording |
| New common-mistake added; tool-reference card expanded with new footgun; description gets a new trigger phrase | **MINOR** (1.0.0 → 1.1.0) | A `tldr-code` bugfix released; we update the corresponding footgun callout |
| Adds, removes, or re-routes commands wrapped by the skill; changes the default tool recommendation; changes the "When to use" boundary with sibling skills | **MAJOR** (1.0.0 → 2.0.0) | We split or merge skills (similar to the 14-skill restructure) |
| Skill is being deprecated entirely | **MINOR** + add `metadata.deprecated: "true"` | See deprecation protocol below |

**The version bump is the discipline.** A change to a SKILL.md that doesn't bump the version is suspicious — either the change is meaningless and shouldn't have been made, or the version got skipped and users won't see the drift.

### When to bump `metadata.tldr.research-commit`

Bump whenever ANY of the following change in the research that backs this skill:
- The dossier (`research/tldr/<group>/<cmd>.md`) for a wrapped command
- The tool card (`research/tool-cards/<group>/<cmd>.md`) for a wrapped command
- The combinatorics doc the skill was sourced from

Update to the SHA of the commit that most recently touched the relevant research. This makes the regeneration chain traceable: anyone can `git show <sha>` to see exactly what evidence the skill was built from.

---

## The deprecation stub pattern

When retiring a skill, **do NOT just delete the folder.** Replace it with a stub for one release cycle so users get a soft landing on `npx skills update`.

### Stub anatomy

```yaml
---
name: tldr-<old-name>
description: "[DEPRECATED — replaced by tldr-<new-name>] This skill was retired in <release>. DO NOT activate — see body for migration commands."
allowed-tools: [Bash]
metadata:
  deprecated: "true"
  replaced-by: "<comma-separated list of replacements>"
  deprecation-date: "<YYYY-MM-DD>"
  scheduled-removal: "next minor release"
---

# tldr-<old-name> — DEPRECATED

This skill has been retired in favor of more focused intent-aligned skills.

## Replacement(s)

- `tldr-new-name-1` — <one-line description of what to use it for>
- `tldr-new-name-2` — <one-line description>

## To migrate

\`\`\`bash
npx skills remove tldr-<old-name>
npx skills add udhaya10/tldr-agent-skills --all -g
\`\`\`

This deprecation stub will be removed entirely in a future release.
```

### Why the `[DEPRECATED]` prefix is load-bearing

Agent products (Cursor, Claude Code, Goose, etc.) match skills by reading their `description` field. The bracket-prefixed `[DEPRECATED — replaced by tldr-X]` text is seen by EVERY matcher across all 60+ supported agents. The matcher will steer the LLM away from activating this skill at runtime, even if the metadata-level `deprecated: true` key is ignored by that client (most clients don't honor metadata keys beyond `internal`).

This means deprecation works through TWO independent channels:
- **Description prefix** — universally honored (text-matching is core to every spec-compliant client)
- **Metadata flag** — honored by clients that read `metadata.deprecated`, advisory otherwise

Don't skip either. The description prefix is what protects users at runtime; the metadata flag is what tooling (like `bin/check-versions.sh`) reads for reporting.

### Removal timing

| Stage | When | What happens |
|-------|------|---------------|
| **Active** | Normal lifecycle | Skill has full body, version metadata, `deprecated: "false"` (or absent) |
| **Deprecated** | When retired | Folder still exists; SKILL.md replaced with stub; description prefixed `[DEPRECATED]` |
| **Removed** | After one minor release cycle | Folder deleted entirely; users on `npx skills update` see standard "removed upstream" prompt with no surprise (they already migrated) |

For our project: we retired 14 old skills in `0c6084f`, then re-added them as stubs in `<this work's commit>`. Schedule for actual deletion: next minor release (v1.1 or v2.0 of the skill corpus), giving users time to migrate.

---

## The regeneration workflow (when tldr-code ships a new version)

The full workflow for keeping skills current with `tldr-code` evolution:

```
1. Pull new tldr-code release
   └─► git pull on the upstream clone

2. Re-run probes per Journal 04
   └─► For each changed/new command:
       bash research/tldr/<group>/<cmd>.probes/probe.sh
   └─► Captures fresh .cmd/.out/.err triples; dossier evidence stays current

3. Re-run the 17/17 audit
   └─► for f in research/tldr/*/*.md; do bash research/_TEMPLATES/audit.sh "$f"; done
   └─► Catch any dossiers whose structure broke

4. Update affected cards per Journal 06
   └─► If a dossier changed (new flag, new footgun, behavior shift),
       update the corresponding research/tool-cards/<group>/<cmd>.md
       — particularly the "Killer detail" and "Other footguns" sections

5. Re-run affected family-chooser combinatorics
   └─► Any combinatorics doc citing a changed card may need its
       discriminator or common-mistakes updated

6. Re-render affected skills
   └─► Identify which of the 14 skills wrap the changed commands:
       bash bin/check-versions.sh   (uses metadata.tldr.commands-wrapped)
   └─► Re-write or edit the affected SKILL.md files
   └─► Bump metadata.version per the rules above
   └─► Bump metadata.tldr.cli-version to the new tldr-code version
   └─► Bump metadata.tldr.research-commit to the new git SHA

7. Validate self-containment is still intact
   └─► grep "research/" tldr-*/SKILL.md   → should be empty
   └─► grep "github.com" tldr-*/SKILL.md   → should be empty
   └─► bash bin/check-versions.sh   → no MISSING versions

8. Commit with a clear message
   └─► chore(skills): refresh against tldr-code v0.X.Y

9. Users get the update
   └─► npx skills update -g
```

If a `tldr-code` release renames or removes a command entirely:
- The skill that wrapped it must change. Decide: rename internally (within the existing skill) or retire+replace (use the deprecation stub pattern).
- Update `metadata.tldr.commands-wrapped` to remove the old name.
- Bump version (major if it's a removal; minor if it's a rename with same behavior).

---

## The `bin/check-versions.sh` helper

A small shell script ships in this repo at `bin/check-versions.sh`. It scans every `tldr-*/SKILL.md`, extracts version + deprecation status from the metadata block, and prints a one-row-per-skill report.

Use it:
- Before every release commit (sanity check that versions were bumped where needed)
- After regenerating skills (verify metadata picked up new SHA)
- Periodically (drift check — is anything deprecated past its scheduled removal date?)

The script also reminds the user how to install/update via the `vercel-labs/skills` CLI.

---

## Open questions deferred to operational practice

1. **Which version bump for "the dossier changed but the skill content didn't"?** Probably no bump — `metadata.tldr.research-commit` updates but `version` stays the same. The skill's contract with the LLM didn't change.

2. **How long is "one minor release cycle" before deletion?** Subjective. Lacking real usage signals (download counts on skills.sh), default to ~3 months OR until the next breaking change ships, whichever comes first.

3. **Should `metadata.tldr.research-commit` track per-command commits, or one commit for the whole skill?** Currently one commit per skill (simplest). Per-command would be more precise but harder to maintain. Revisit if a single skill regularly needs partial regeneration.

4. **What about the `metadata.internal: true` key?** That's the one key `vercel-labs/skills` actively honors — hides a skill from default discovery. Useful if you want to ship work-in-progress skills that only show up with `INSTALL_INTERNAL_SKILLS=1`. We don't use this currently; revisit if we want a beta/preview channel.

---

## Cross-references

- **Journal 04** — operational protocol for the dossier evidence layer (step 2 of regeneration workflow)
- **Journal 06** — cards and combinatorics protocol (steps 4-5 of regeneration workflow)
- **Journal 07** — the skill architecture decision (the 14 skills this protocol maintains)
- **`agent-skills-authoring/03_ECOSYSTEM_MAP.md`** — full ecosystem context (spec, distribution CLI, client implementations)
- **`bin/check-versions.sh`** — the version/deprecation report helper
