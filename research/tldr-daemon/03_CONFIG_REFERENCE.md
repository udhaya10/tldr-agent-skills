# Config Reference — TLDR Daemon

Every configurable value in the v0.4.0 daemon, where it lives, what it controls, and what status it has.

## ⚠️ Critical caveat — config file loading is NOT implemented in v0.4.0

The `DaemonConfig` struct exists with 4 fields, and its doc comment claims it is "loaded from `.tldr/config.json` or `.claude/settings.json`." However:

- The actual `daemon start` code (`crates/tldr-cli/src/commands/daemon/start.rs:177`) does:
  ```rust
  let config = DaemonConfig::default();
  let daemon = Arc::new(TLDRDaemon::new(project.to_path_buf(), config));
  ```
- No source file in `crates/` reads `.tldr/config.json` or `.claude/settings.json` (verified by `grep` excluding tests)
- The 4 config fields ARE read at runtime by the daemon — but only with their `Default` values

**So in v0.4.0**: creating a `.tldr/config.json` will not change daemon behavior. The fields are "configurable" in the schema sense but not the operational sense. This is forward-compatibility — the struct is ready, the loader is not yet implemented upstream.

Document your config files anyway (see "Forward-compatible config templates" below) so that when v0.5 or later wires up loading, your overrides apply automatically.

## The 4 `DaemonConfig` fields

Source: `crates/tldr-cli/src/commands/daemon/types.rs:34-58`.

### 1. `semantic_enabled`

| Aspect | Value |
|--------|-------|
| Type | `bool` |
| Default | `true` |
| Used to | Gate the embedding-based `tldr semantic` command. When `false`, semantic queries return an unrecognized-subcommand error even if compiled in. |
| Configurable today? | NO — uses default |
| Future override (when implemented) | `.tldr/config.json` → `"semantic_enabled": false` |

### 2. `auto_reindex_threshold`

| Aspect | Value |
|--------|-------|
| Type | `usize` (non-negative integer) |
| Default | `20` (per `DEFAULT_REINDEX_THRESHOLD` constant) |
| Used to | Trigger auto re-index when this many files have been marked dirty (via `tldr daemon notify`). Default 20 means the daemon waits for 20 changed files before re-indexing. |
| Configurable today? | NO — uses default |
| Future override | `.tldr/config.json` → `"auto_reindex_threshold": 50` |

### 3. `semantic_model`

| Aspect | Value |
|--------|-------|
| Type | `String` |
| Default in `DaemonConfig::default()` | `"bge-large-en-v1.5"` |
| **Actual user-facing default for `tldr semantic` / `tldr similar` / `tldr embed`** | **`arctic-m`** (per `default_value = "arctic-m"` on each CLI command's `--model` flag) |
| Used to (intent) | Choose embedding model for daemon-side semantic queries |
| **Used to (actual v0.4.0)** | **NOTHING — this field is dead config**. It's set in the struct, has a default, but `grep -r "self.config.semantic_model"` across `crates/` returns zero hits. No daemon code path reads it. |
| Configurable today? | NO — and irrelevant, since the field is unused |
| Future override (when loader lands AND field is wired up) | `.tldr/config.json` → `"semantic_model": "arctic-xs"` |

> **Important correction**: An earlier version of this doc said the "real" default was `bge-large-en-v1.5` and that upstream SETUP.md was wrong about `arctic-m`. Wrong on both counts.
>
> **The truth**:
> - `arctic-m` IS the default user-facing model — confirmed in `semantic.rs`, `similar.rs`, and `embed.rs`, plus the upstream README which says "On first run it downloads the arctic-embed-m model (~110MB, cached)"
> - `bge-large-en-v1.5` appears ONLY in `DaemonConfig::default()` and its tests — a dead Default for a struct field that no runtime code reads
> - Users will see `arctic-m`; the `bge-large-en-v1.5` reference in the schema is essentially noise until the field is actually wired into the daemon's semantic handler

**Available models for the `--model` flag** (per `semantic.rs`, `similar.rs`, `embed.rs`):
`arctic-xs`, `arctic-s`, `arctic-m` (default), `arctic-m-long`, `arctic-l`. Each has different speed/quality tradeoffs.

### 4. `idle_timeout_secs`

| Aspect | Value |
|--------|-------|
| Type | `u64` (non-negative integer, seconds) |
| Default | `1800` (30 minutes), from `IDLE_TIMEOUT_SECS` constant |
| Used to | Auto-shutdown the daemon after this many seconds of no client activity. Enforced in `daemon.rs` event loop. |
| Configurable today? | NO — uses default. The `--idle-timeout` CLI flag advertised in upstream TROUBLESHOOTING.md **does not exist**. |
| Future override | `.tldr/config.json` → `"idle_timeout_secs": 86400` (24 hours) |

## CLI flags that DO work in v0.4.0

Despite the broader config field surface, the only operational overrides are CLI flags on `daemon start`:

| Flag | Type | Default | Purpose |
|------|------|---------|---------|
| `--project`, `-p` | `PathBuf` | `.` (current dir) | Which project this daemon serves. Determines socket path, PID lock location, and cache directory. |
| `--foreground` | `bool` | `false` (background) | Run in foreground (no fork). Useful for service definitions where the supervisor manages the process lifecycle directly. |

That's it. No idle-timeout flag. No model flag. No semantic-toggle flag. No verbosity flag. No log destination flag.

## Env vars that DO work in v0.4.0

| Env var | Type | Purpose |
|---------|------|---------|
| `TLDR_DAEMON_REGISTRY_DIR` | path | Override the location of the multi-daemon registry directory. Mostly used for testing (so tests don't pollute the real registry). Not intended for end-user override. |

No env-var counterparts for the 4 `DaemonConfig` fields. No `TLDR_IDLE_TIMEOUT`, `TLDR_SEMANTIC_MODEL`, etc.

## Other daemon subcommand flags (for completeness)

| Subcommand | Flag | Purpose |
|------------|------|---------|
| `daemon stop` | `--project, -p` | Which daemon to stop |
| `daemon stop` | `--all` | Stop ALL daemons in the registry (mutually exclusive with --project) |
| `daemon status` | `--project, -p` | Which daemon to query |
| `daemon status` | `--session, -s` | Show session-specific stats |
| `daemon query` | `--project, -p` | Which daemon |
| `daemon query` | `--json, -j` | JSON params for the command |
| `daemon notify` | `--project, -p` | Which daemon |
| `warm` (top-level) | (positional path, defaults to `.`) | What to warm |
| `warm` | `--background, -b` | Run in background |
| `cache stats` | `--project, -p` | Which daemon |
| `cache clear` | `--project, -p` | Which daemon |

All non-data-related flags are `--project` selectors. The daemon subsystem is entirely path-oriented.

## Forward-compatible config templates

Create these files NOW so that when v0.5+ wires up config loading, your overrides will apply automatically. Until then, the files are ignored but harmless.

### `<project-root>/.tldr/config.json` — full example with every overridable value

```json
{
  "semantic_enabled": true,
  "auto_reindex_threshold": 50,
  "semantic_model": "bge-large-en-v1.5",
  "idle_timeout_secs": 86400
}
```

Recommended values for an "always-on" workflow:

- `semantic_enabled`: `true` — keep semantic search on if the binary was compiled with `--features semantic`
- `auto_reindex_threshold`: `50` — relax from default 20 if you have a large project with frequent small edits; bumping this reduces background re-index churn
- `semantic_model`: `"bge-large-en-v1.5"` — keep the default unless you have a specific reason to switch
- `idle_timeout_secs`: `86400` (24 hours) — the big win for always-on; once v0.5 wires this up, the daemon will stop auto-shutting every 30 min

### `<project-root>/.claude/settings.json` — alternative location (Claude convention)

The daemon spec says config can also be loaded from `.claude/settings.json`. The schema would be the same fields, presumably under a `tldr` namespace (TBD when loader lands):

```json
{
  "tldr": {
    "semantic_enabled": true,
    "auto_reindex_threshold": 50,
    "semantic_model": "bge-large-en-v1.5",
    "idle_timeout_secs": 86400
  }
}
```

The exact key path is **not yet specified by upstream**. Verify against the loader implementation when it lands.

### When you'd want different per-project configs

Because the daemon is per-project, you can have different configs per project:

| Project type | Recommended override |
|--------------|---------------------|
| Huge codebase (10K+ files) | `"auto_reindex_threshold": 100` to reduce re-index churn |
| Sensitive project (don't want semantic embeddings to disk) | `"semantic_enabled": false` |
| Project with rich vocabulary (acronym-heavy) | `"semantic_model": "arctic-l"` (better quality, slower) — assuming the model is available |
| Project you actively work on daily | `"idle_timeout_secs": 86400` (24h) — daemon stays warm overnight |
| Project you rarely touch | `"idle_timeout_secs": 600` (10 min) — daemon shuts down quickly to free memory |

For the "always-on across all your projects" pattern (Design A from `02_KEY_FINDINGS.md`), put the config at the **parent path** you've registered with the daemon:

```bash
mkdir -p ~/Workspace/.tldr
cat > ~/Workspace/.tldr/config.json <<EOF
{
  "semantic_enabled": true,
  "auto_reindex_threshold": 50,
  "semantic_model": "bge-large-en-v1.5",
  "idle_timeout_secs": 86400
}
EOF
```

This is the "pseudo-global" config — one file at the workspace parent, applies to the daemon serving all projects under it (when loader is implemented).

## When to revisit this reference

| Trigger | What to re-verify |
|---------|------------------|
| `tldr-code` releases v0.5+ | Whether config file loading is now implemented. If yes, the "Configurable today" column flips to YES for all 4 fields. |
| New flag spotted in CHANGELOG | Add the new flag to the appropriate table |
| New `DaemonConfig` field added | Add a new section in "The 4 fields" |
| Loader uses different key path in `.claude/settings.json` | Update the "Claude convention" sample |
| New env var added | Update the env vars table |

The methodology for re-verification is in `01_RESEARCH_METHODOLOGY.md`.

## Cross-references

- `01_RESEARCH_METHODOLOGY.md` — how this reference was built
- `02_KEY_FINDINGS.md` — the broader daemon architecture (per-project, multi-daemon registry, install design implications)
- `references/upstream-SETUP.md` — the upstream doc (some claims known to be stale, see `01_RESEARCH_METHODOLOGY.md` for the diff table)
- `../../tldr-setup-check/SKILL.md` — the skill that diagnoses tldr installation; should be updated to reflect the v0.4.0 reality after this research lands
- `../../tldr-runtime/SKILL.md` — the skill that wraps daemon/cache/warm; should reference this folder for the deeper schema
