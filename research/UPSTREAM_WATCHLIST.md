# Upstream Watchlist

> **Why this exists.** This project depends on four upstream surfaces, each of which evolves independently of us. When any of them ships changes that affect what we ship, we need to update — sometimes substantially. This doc is the single place where every upstream dependency is tracked: what we currently need, what we're watching for, how we'll detect a relevant change, and what we'll do when one lands.

## How to use this doc

Run a periodic review (suggested cadence: monthly OR after any upstream announces a release). For each upstream listed below:

1. Check the "How we'll know" column — run the suggested probe / re-scrape / version check
2. If something has changed: see "When detected, do this" for the concrete action list
3. Mark off completed updates in this doc itself (we keep a running log at the bottom)

The doc is also a reading list for new contributors who want to understand what this project depends on at the operational level.

---

## 1. `parcadei/tldr-code` (the Rust CLI we wrap)

**Current pin**: v0.4.0 (commit `6c4011a`)

### What we currently NEED but the upstream doesn't ship yet

| Need | Why we care | Workaround today | Upstream status |
|------|------------|------------------|-----------------|
| **Config file loading** (`.tldr/config.json` or `.claude/settings.json`) | Without this, the 4 `DaemonConfig` fields (semantic_enabled, auto_reindex_threshold, semantic_model, idle_timeout_secs) cannot be overridden. We're stuck with hardcoded defaults. | None — values are constants in v0.4.0. Service supervision (`KeepAlive=true`) masks the 30-min idle timeout but doesn't actually change it. | Documented in `crates/tldr-cli/src/commands/daemon/types.rs` as "loaded from .tldr/config.json or .claude/settings.json" — but the loader code does not exist. Pure scaffolding. |
| **`--idle-timeout` CLI flag on `daemon start`** | Upstream TROUBLESHOOTING.md claims this works (`tldr daemon start --idle-timeout 600`); it does NOT in v0.4.0. A real flag would let us extend daemon idle for always-on workflows without needing config-file loading first. | None — accept 30-min cycling with service auto-restart | Not present in `crates/tldr-cli/src/commands/daemon/start.rs` (DaemonStartArgs only has `--project` and `--foreground`). May ship alongside config loading, or as its own quick fix. |
| **Daemon-side semantic_model wired into runtime** | Even when config loading lands, the daemon's `semantic_model` field may still do nothing. `self.config.semantic_model` is never read anywhere in `crates/` in v0.4.0 — it's pure dead config. The user-facing `tldr semantic --model X` works (CLI flag default `arctic-m`), but daemon-routed semantic queries don't seem to consult the config field. | Use `--model` flag per invocation (works fine for arctic-m default; can switch with explicit override) | The field exists in the struct but has no read site. Either intended for v0.5+ or genuinely orphaned. |
| **Cwd walk-up for command routing** (or a `--global` daemon mode) | A daemon at `~/Workspace` does NOT serve `tldr structure .` from `~/Workspace/sub-project/` because commands route by canonical path argument, not cwd walk-up. Only `tldr daemon status` walks up cwd. The result: we can't ship a single always-on daemon that transparently covers many projects. Either cwd routing OR an explicit `--global` daemon mode would unblock our `bin/install-daemon-service.sh` design. | Per-project daemon (one service per project) OR pass absolute paths everywhere OR shell hook on `cd`. None match the "set up once, forget" UX goal. | Empirically verified to NOT work for default usage. See `tldr-daemon/04_INSTALL_DESIGN_BLOCKERS.md`. |

### What we're watching for (changes that would force us to update)

| Change | Detection | Required action |
|--------|-----------|----------------|
| **New CLI commands added** | Diff `tldr --help` output between versions OR `git log` on `crates/tldr-cli/src/commands/` | Per Journal 04: write a new dossier; per Journal 06: write a new tool card; per Journal 07: assign to an existing skill or create a new one |
| **Existing command behavior changes** (new flags, changed defaults, new failure modes) | Re-run the probe set per Journal 04 (`research/tldr/<group>/<cmd>.probes/probe.sh`) | Update the affected dossier + card; if the change affects the killer-detail or default tool selection, update the family-chooser combinatorics too; bump affected skill's `metadata.version` |
| **Default value changes** (e.g., default model changes from arctic-m to something else) | `grep "default_value" crates/tldr-cli/src/commands/<cmd>.rs` against the new clone | Update affected skill bodies; bump `metadata.version` |
| **New `DaemonConfig` field added** | Re-read `crates/tldr-cli/src/commands/daemon/types.rs` | Add to `research/tldr-daemon/03_CONFIG_REFERENCE.md`; if user-overridable, update the install-script template |
| **`--features semantic` becomes default** (or is removed) | Check upstream INSTALL.md + CHANGELOG | Update `tldr-setup-check`'s Step 3 (the semantic-availability probe) |
| **Breaking change to daemon IPC / socket format** | Look at `daemon_registry.rs`, `ipc.rs` diffs | Likely requires a probe re-run AND careful update of `tldr-runtime` skill body |

### How we'll know — concrete probes

```bash
# Update local clone
cd /Users/udhayakumar/Workspace/03-Parcadei-Ecosystem/tldr-code
git fetch && git log --oneline ..origin/main | head -20

# Check if config-file loading landed
grep -rE "\.tldr/config\.json|\.claude/settings\.json" crates/ --include="*.rs" | grep -v test
# (Empty in v0.4.0; any hits mean loading is wired up)

# Check daemon CLI flags
grep -A2 "#\[arg" crates/tldr-cli/src/commands/daemon/start.rs
# (Currently only --project and --foreground; new flags would appear here)

# Check the 4 DaemonConfig defaults
grep -A8 "impl Default for DaemonConfig" crates/tldr-cli/src/commands/daemon/types.rs

# Check default model in each user-facing semantic command
grep "default_value" crates/tldr-cli/src/commands/semantic.rs crates/tldr-cli/src/commands/similar.rs crates/tldr-cli/src/commands/embed.rs

# Check CHANGELOG for any release notes
head -100 CHANGELOG.md
```

### When detected, do this

For ANY non-trivial change to tldr-code:

1. **Re-run audit** (per Journal 04): `for f in research/tldr/*/*.md; do bash research/_TEMPLATES/audit.sh "$f"; done` — catches any structural drift
2. **Re-probe affected commands** (per Journal 04): `bash research/tldr/<group>/<cmd>.probes/probe.sh`
3. **Update affected cards** (per Journal 06): the killer-detail and "Other footguns" sections are most likely to need edits
4. **Update affected skills** (per Journal 08): bump `metadata.version` per the bump rules; update `metadata.tldr.cli-version` to the new version string; update `metadata.tldr.research-commit` to the new git SHA
5. **For the SPECIFIC scenario: config file loading lands** — separate playbook:
   - Update `research/tldr-daemon/03_CONFIG_REFERENCE.md`: flip the "Configurable today?" column from NO to YES for all 4 fields
   - Update `tldr-setup-check` SKILL.md: add a check step "is `.tldr/config.json` present and being honored?"
   - Update the future install script: also drop a `.tldr/config.json` with extended idle_timeout_secs so the daemon never cycles
   - Verify the daemon's `semantic_model` field is now actually READ (`grep "self.config.semantic_model" crates/`); if still empty, note in 03_CONFIG_REFERENCE that the field stays dead even with loading enabled

---

## 2. `agentskills.io` (the open SKILL.md format spec)

**Current pin**: spec as of scrape on 2026-05-22 (see `research/agent-skills-authoring/references/agentskills-io-*.md`)

### What we currently NEED

Nothing missing — the spec works for us as-is. All 15 skills conform.

### What we're watching for

| Change | Detection | Required action |
|--------|-----------|----------------|
| **New first-class frontmatter fields** (beyond `name`, `description`, `allowed-tools`, `compatibility`, `license`, `metadata`) | Diff `agentskills.io/specification.md` between scrapes | Decide per-field whether to add to our 15 skills; update Journal 08 if a new field would have lifecycle implications |
| **Changes to `name`/`description` constraints** (e.g., max length, character set) | Same as above | Re-validate all 15 SKILL.md files; rename if necessary |
| **Changes to required vs optional fields** | Same as above | Update Journal 06 template + every SKILL.md as needed |
| **New directory conventions** (e.g., a new well-known subfolder) | Same as above | Update Journal 06 + REPOSITORY_STRUCTURE.md |
| **Spec adopts a `deprecated` or `version` first-class field** | Same as above | Migrate our `metadata.deprecated` / `metadata.version` usage to the first-class fields; update Journal 08 |

### How we'll know

```bash
# Re-fetch the spec index
firecrawl scrape "https://agentskills.io/llms.txt" -o /tmp/agentskills-index-new.md
diff research/agent-skills-authoring/references/agentskills-io-llms-index.md /tmp/agentskills-index-new.md

# Re-fetch the spec document
firecrawl scrape "https://agentskills.io/specification" -o /tmp/agentskills-spec-new.md
diff research/agent-skills-authoring/references/agentskills-io-specification.md /tmp/agentskills-spec-new.md

# Check for new pages in llms.txt
grep -E "agentskills\.io.*\.md" /tmp/agentskills-index-new.md
```

Also: the agentskills.io home page mentions a Discord and GitHub for announcements. Worth subscribing if active development continues.

Spec source repo: `https://github.com/agentskills/agentskills`

### When detected, do this

1. Re-scrape the affected page into `research/agent-skills-authoring/references/` (overwriting the old version OR with a date suffix for diff tracking)
2. Update `research/agent-skills-authoring/03_ECOSYSTEM_MAP.md` if the change shifts the spec/distribution/client-implementation boundaries
3. Update affected SKILL.md files (likely a sweep across all 15)
4. Update Journal 08 if the change affects lifecycle assumptions

---

## 3. `vercel-labs/skills` (the `npx skills` CLI)

**Current pin**: v1.5.7 (per `npm view skills` on 2026-05-22)

### What we currently NEED

Nothing critical — `add`, `update`, `list`, `remove` all work and meet our needs.

### What we currently WANT (but not blocking)

| Want | Why | Workaround today |
|------|-----|-----------------|
| **Version-aware `update`** (show "1.0 → 1.1" diffs when a skill is updated upstream) | Users would see what changed across skill updates | None — users see "skill updated" with no detail |
| **Honor `metadata.deprecated`** (warn on `npx skills update` when an installed skill is now deprecated) | The deprecation pattern we documented in Journal 08 would actually fire automatically | None — users see silent removal when a deprecated skill is later deleted |
| **Per-skill version pinning** (`npx skills add owner/repo --version 1.0`) | Lets users hold a known-good version while we ship breaking changes | None — always pulls latest |

### What we're watching for

| Change | Detection | Required action |
|--------|-----------|----------------|
| **New install/update commands** | Re-fetch `vercel-labs/skills` README | Update README install instructions; possibly update Journal 08 |
| **Metadata fields honored** (especially `deprecated`, `version`, our `tldr.*` keys) | Same as above; also look at CLI source if curious about semantics | If `metadata.deprecated` becomes honored — re-evaluate our deprecation stub pattern (might be redundant) |
| **New supported agent products added/removed** | Re-fetch the supported-agents table from the README | Update `research/agent-skills-authoring/03_ECOSYSTEM_MAP.md`'s "60+ agents" reference |
| **Major version bump (v2.x)** | `npm view skills version` | Read CHANGELOG carefully; possibly significant migration |

### How we'll know

```bash
# Check current version
npm view skills version

# Re-fetch the README
firecrawl scrape "https://raw.githubusercontent.com/vercel-labs/skills/main/README.md" -o /tmp/vercel-skills-readme-new.md
diff research/agent-skills-authoring/references/vercel-labs-skills-readme.md /tmp/vercel-skills-readme-new.md

# Check for new commands in the bin
npx skills --help 2>&1 | head -30
```

### When detected, do this

1. Re-scrape the README into `research/agent-skills-authoring/references/`
2. Update `research/agent-skills-authoring/03_ECOSYSTEM_MAP.md` table of CLI capabilities
3. Update README install/update instructions if commands changed
4. If `metadata.deprecated` is now honored — simplify our Journal 08 deprecation protocol (the description-prefix becomes optional)

---

## 4. Anthropic Agent Skills docs (`platform.claude.com/docs/.../agent-skills`)

**Current pin**: docs as of scrape on 2026-05-22 (see `research/agent-skills-authoring/references/*.md` — the non-`agentskills-io-*` files)

### What we currently NEED

Nothing missing — current docs informed our authoring approach (captured in `02_KEY_INSIGHTS.md`) and that approach holds up.

### What we're watching for

| Change | Detection | Required action |
|--------|-----------|----------------|
| **New best-practice guidance** | Re-scrape `best-practices.md` | Compare against `02_KEY_INSIGHTS.md`; update if new insights worth absorbing |
| **New Anthropic-only fields** (e.g., Claude API container parameters that don't exist in the open spec) | Re-scrape `skills-guide.md` | Decide whether to use Claude-specific features (locks us to Claude) or stay vendor-neutral (works everywhere) |
| **New SKILL.md format requirements** (Anthropic could add stricter validation) | Re-scrape `overview.md` and `specification.md` | Validate all 15 skills; update authoring journal |
| **Evaluation tooling lands** | Re-scrape `evaluating-skills.md` (if it exists) | Consider building eval scenarios for our 15 skills |

### How we'll know

Periodic re-scrape (suggested cadence: quarterly, or after Anthropic announces a major Agent Skills update):

```bash
for url in \
    "https://platform.claude.com/docs/en/agents-and-tools/agent-skills/overview" \
    "https://platform.claude.com/docs/en/agents-and-tools/agent-skills/best-practices" \
    "https://platform.claude.com/docs/en/agents-and-tools/agent-skills/quickstart" \
    "https://platform.claude.com/docs/en/agents-and-tools/agent-skills/enterprise" \
    "https://platform.claude.com/docs/en/build-with-claude/skills-guide" ; do
    name=$(basename "$url" | sed 's/.*\///')
    firecrawl scrape "$url" --only-main-content -o "/tmp/anthropic-${name}-new.md"
    diff "research/agent-skills-authoring/references/${name}.md" "/tmp/anthropic-${name}-new.md" || \
      echo "^ ${name} has changed; review needed"
done
```

### When detected, do this

1. Re-scrape into `research/agent-skills-authoring/references/`
2. Update `research/agent-skills-authoring/02_KEY_INSIGHTS.md` with any new takeaways
3. If a new best practice is high-value, sweep the 15 SKILL.md files to apply it

---

## Review log

Append entries here when an upstream change is detected and acted on. Helps establish cadence + catches if a dependency goes stale.

| Date | Upstream | Change detected | Action taken | Commit |
|------|----------|----------------|--------------|--------|
| 2026-05-22 | tldr-code v0.4.0 | Initial research baseline | Probed 64 commands, built dossier corpus, wrote 15 skills | `a025973`, `0055b39` |
| 2026-05-22 | agentskills.io spec | Initial scrape | Built Ecosystem Map + Key Insights | `dabd0f3` |
| 2026-05-22 | vercel-labs/skills v1.5.7 | Initial check | Documented CLI capabilities + lifecycle | `dabd0f3` |
| 2026-05-22 | Anthropic platform.claude.com | Initial scrape (5 pages) | Built Authoring research folder | (multiple) |
| _(future)_ | _(upstream)_ | _(what changed)_ | _(what we did)_ | _(SHA)_ |

---

## Cross-references

- `tldr-daemon/01_RESEARCH_METHODOLOGY.md` — detailed verification procedures for tldr-code changes
- `tldr-daemon/03_CONFIG_REFERENCE.md` — the 4 DaemonConfig fields + their "Configurable today?" status (this watchlist's main payload)
- `agent-skills-authoring/01_RESEARCH_METHODOLOGY.md` — how we scraped the Anthropic docs originally
- `agent-skills-authoring/03_ECOSYSTEM_MAP.md` — explains who owns each upstream layer
- `04_PROBE_PROTOCOL.md` (Journal 04) — the operational protocol for re-running probes against tldr-code
- `08_SKILL_LIFECYCLE_PROTOCOL.md` (Journal 08) — version-bump rules to follow when skills update in response to upstream changes
