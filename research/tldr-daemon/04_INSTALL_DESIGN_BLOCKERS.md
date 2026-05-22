# Install Design Blockers — Why we did NOT ship a daemon install script

> **Status: postponed.** We designed an always-on daemon install script (launchd / systemd user service), ran a verification probe against tldr-code v0.4.0, and found multiple blockers that prevent a clean "set it and forget it" solution. This document captures every blocker with the evidence we collected, so a future contributor (or the upstream author) knows what would need to change.

## Why this exists

The original goal: a single command (`bash bin/install-daemon-service.sh`) that installs a launchd plist (macOS) or systemd unit (Linux) so the tldr daemon runs always-on, gives the user the ~35× speedup from cached queries without them having to think about it, and survives reboots / login cycles.

After researching the upstream source and running an empirical verification probe, we concluded the upstream v0.4.0 daemon architecture does not support that goal cleanly. The reasons are documented below.

We chose to **postpone the install script** rather than ship something that papers over the limitations. The corrected expectation is that v0.5+ may fix several of these blockers; when it does, we revisit. The `UPSTREAM_WATCHLIST.md` doc tracks the specific changes we're waiting for.

## The 8 blockers, in order of severity

### Blocker 1 — Commands route by PATH ARGUMENT, not by cwd walk-up

**The most important blocker.** The original install design assumed one daemon at a parent path (e.g., `~/Workspace`) would serve queries from any sub-directory under it. Empirical verification showed this is FALSE for actual commands. Only `tldr daemon status` walks up cwd to find a daemon; everything else routes strictly by the canonical absolute path passed as an argument.

**Verified via probe** (2026-05-22):

```bash
# Start daemon at parent
$ tldr daemon start -p ~/Workspace/.../tldr-agent-skills
{ "status": "ok", "pid": 59812, "socket": ".../tldr-6506badd.sock" }

# From sub-dir, run a real command with cwd-relative path
$ cd ~/Workspace/.../tldr-agent-skills/research
$ tldr structure .
# stats BEFORE: misses=0,  AFTER: misses=0  ← daemon was NOT used
# The command worked but did cold compute

# From sub-dir, run same command with explicit ABSOLUTE path to parent
$ tldr structure ~/Workspace/.../tldr-agent-skills
# stats BEFORE: misses=0,  AFTER: misses=1  ← daemon WAS used

# Second run of same absolute-path command (from anywhere) — cache hit
$ tldr structure ~/Workspace/.../tldr-agent-skills
# stats BEFORE: misses=1,  AFTER: hits=1, misses=1  ← daemon cache hit
```

**Implication**: a single daemon rooted at `~/Workspace` cannot transparently serve queries from `~/Workspace/<any-sub-project>/`. Users would have to either pass absolute paths to every command (annoying) or run a separate daemon per project (high overhead). Neither matches the goal of "set up once, forget."

### Blocker 2 — No auto-start mechanism in the CLI

Commands silently fall through to cold compute when no daemon is running. Nothing in `try_daemon_route` or any command path spawns a daemon. The only function that starts a daemon is called only from explicit `tldr daemon start`.

**Verified via source**:

- `crates/tldr-cli/src/commands/daemon_router.rs::try_daemon_route` — returns `None` when no socket; caller falls through
- `crates/tldr-cli/src/commands/daemon/warm.rs::run_async` — checks `check_socket_alive`; if not, runs warming **in foreground in the current process** (does NOT spawn a daemon)
- `crates/tldr-cli/src/commands/daemon/start.rs::run_background` — the ONLY caller of `start_daemon_background`, invoked only by explicit `tldr daemon start`

**Implication**: without service infrastructure (launchd/systemd) OR shell hooks OR explicit user-typed commands, the daemon is **effectively never running**. The "35× speedup" upstream advertises is opt-in via a user action that's never prompted. Most users probably don't even know they should start one.

### Blocker 3 — No idle-timeout override in v0.4.0

The daemon auto-shuts after 30 minutes of no client activity. There is no way to extend this in v0.4.0:

| Mechanism | Status |
|-----------|--------|
| `--idle-timeout` CLI flag on `daemon start` | **Does not exist.** TROUBLESHOOTING.md upstream wrongly claims it does. The DaemonStartArgs struct only has `--project` and `--foreground`. |
| `TLDR_IDLE_TIMEOUT` env var | Does not exist. The only daemon env var in the codebase is `TLDR_DAEMON_REGISTRY_DIR` (for testing). |
| `.tldr/config.json` with `idle_timeout_secs` field | **The struct exists; the loader does not.** `daemon start` calls `DaemonConfig::default()` and never reads any config file. Creating the file today is futile. |
| `.claude/settings.json` equivalent | Same — documented in struct doc-comment, not implemented |

**Implication**: even with a service installed (launchd `KeepAlive=true` / systemd `Restart=always`), the daemon will cycle every 30 minutes of idle time. The service will restart it immediately after each graceful shutdown, but:

- There's a brief window during restart where commands pay cold compute
- The cache persists on disk (Salsa store), so restarts are mostly transparent — but not entirely
- Continuous restart cycling is wasteful (process spawn + cache load) compared to just letting one process stay up

### Blocker 4 — `DaemonConfig.semantic_model` is dead config

The struct field is declared with a default of `"bge-large-en-v1.5"`. `grep -r "self.config.semantic_model" crates/` returns **zero hits**. No daemon code path reads it at runtime.

The actual user-facing default is `arctic-m`, defined as `default_value = "arctic-m"` on each user-facing semantic command (`semantic.rs`, `similar.rs`, `embed.rs`).

**Implication**: even when v0.5+ wires up config file loading, this specific field may still do nothing — needs to be wired into the daemon's semantic handler separately. Users wanting to override the default semantic model today must use the `--model` flag per invocation OR set up a shell alias / wrapper script.

### Blocker 5 — Upstream docs are unreliable on daemon behavior

Several upstream documents (`docs/SETUP.md`, `docs/TROUBLESHOOTING.md`) state things that are not true in v0.4.0:

| Doc claim | Actual v0.4.0 behavior | Source |
|-----------|----------------------|--------|
| "Default idle timeout: 300 seconds" | 1800 seconds (30 min) | `IDLE_TIMEOUT_SECS` constant in `types.rs` |
| "`tldr daemon start --idle-timeout 600` adjusts idle timeout" | No `--idle-timeout` flag exists | `DaemonStartArgs` struct |
| "Default semantic model is `arctic-m`" (claimed by SETUP.md) | TRUE for CLI commands, but the DaemonConfig schema disagrees with default `bge-large-en-v1.5` (which is unused anyway) | Mixed |
| "Config files at `.tldr/config.json` or `.claude/settings.json` let you override settings" | Files are NOT read in v0.4.0 | Verified by `grep` |

**Implication**: any install design that reads upstream docs as authoritative will ship wrong content. We had to source-dive to get accurate behavior. Future contributors face the same trap.

### Blocker 6 — Per-project daemon model doesn't scale to multi-project workflows

The daemon is fundamentally per-project (per-project PID lock, per-project socket, per-project entry in the multi-daemon registry). For a user who works across many projects, the architecture means:

- One service per project the user works in regularly (N services to manage)
- N daemons consuming memory continuously
- Each project needs its own install-script invocation
- New projects need a new service install before they benefit from caching

**Implication**: there's no clean "primary user setup" that gives them daemon coverage across all the work they do. Either they install N services (manual + maintenance burden) or accept that some projects pay cold compute (defeating the install script's goal).

### Blocker 7 — Empty `tldr stats` when daemon wasn't running during prior commands

A subtle UX issue: `tldr stats` reports cumulative token savings, but only counts queries that went through the daemon. Without a service installed, most users never had a daemon running during their queries, so stats stays at zero. They get no signal that tldr is even worth caching for.

**Implication**: bootstrapping users into the "always-on daemon" pattern is hard because they have no concrete data showing the value until they've already set it up. A successful install script would solve this, but circles back to blockers 1-3.

### Blocker 8 — Two unrelated `tldr` projects with overlapping command surfaces

`parcadei/tldr-code` (Rust) and `parcadei/llm-tldr` (Python) both ship CLIs named `tldr` with overlapping subcommands but different implementations. A user who runs `pip install llm-tldr` (because that's the more popular one with 1.2k stars) gets a different binary with different config, different daemon behavior, and different defaults than the one our research targets.

**Implication**: any install script we ship needs to first verify the user has the **Rust** `tldr-code` binary specifically, not the Python `llm-tldr`. The detection logic is non-trivial (both binaries respond to `tldr --version` with similar-looking output).

## Workarounds that exist (but don't meet the goal)

Each of these solves PART of the problem at the cost of UX or scope:

| Workaround | What it gives you | What it costs |
|-----------|-------------------|---------------|
| **Manual `tldr daemon start` per project** | Daemon is running for the project you explicitly started it in | User remembers to do it; not always-on; not auto-restart on idle |
| **One service per primary project** (Option C from our design discussion) | Always-on daemon for ONE project | Multiple services for multiple projects; new projects need a new install |
| **Service at a parent path + always pass absolute paths in commands** | Single daemon serves many projects | User must remember to pass absolute paths; tools/hooks must do the same; default `tldr structure .` from sub-dir bypasses the daemon |
| **Shell hook on `cd` to auto-start a daemon for the project entered** | Lazy per-project daemons | Shell-specific (zsh vs bash vs fish); fragile against `direnv`/`autoenv`; doesn't help non-shell invocations (hooks, CI, agent products) |
| **Wrapper script in PATH that auto-starts daemon if missing** | Zero user config, transparent | Adds ~50–100ms to every tldr call; masks upstream binary; brittle to PATH ordering |
| **Wait for upstream v0.5+ to ship config loading + idle-timeout override + (possibly) cwd routing** | Eventually a clean install design | Indefinite timeline; depends on upstream priorities |

## What would need to change upstream for a clean install design

For us to ship `bin/install-daemon-service.sh` confidently:

1. **Config file loading wired up** (`.tldr/config.json` or `.claude/settings.json`) — lets us set `idle_timeout_secs: 86400` so the daemon doesn't cycle. **Most impactful.**
2. **OR `--idle-timeout` CLI flag actually implemented** — same effect, simpler. The doc already claims this exists.
3. **Commands walk cwd up to find a daemon** (matching the `daemon status` discovery behavior) — would make "single daemon at parent path" finally work as users expect.
4. **OR an explicit "global / user-scoped daemon" mode** — e.g., `tldr daemon start --global` that listens on `~/.tldr/socket` and serves any path.
5. **Auto-spawn from `tldr warm`** at minimum — running `tldr warm <path>` could start a daemon for that path if none exists, eliminating the "user must run two commands" friction.

Any one of (3) or (4) would unblock the install script. (1) or (2) plus a service would also unblock it, just with worse UX (daemon-per-project still).

## Decision

Until at least one of (1), (2), (3), or (4) from the previous section lands in upstream tldr-code:

- **We do NOT ship `bin/install-daemon-service.sh`.**
- We do NOT ship `assets/com.tldr-code.daemon.plist.tmpl` or `assets/tldr-daemon.service.tmpl`.
- The `tldr-runtime` skill continues to point users at `tldr daemon start && tldr warm` as the manual setup; users who want always-on can copy our reasoning here and roll their own service files.
- The `tldr-setup-check` skill diagnoses the "no daemon running" case but does NOT recommend a service install; just `tldr daemon start` per project.

## When to revisit

Watch `UPSTREAM_WATCHLIST.md`'s tldr-code section. When any of the following lands, re-evaluate this decision:

- A commit touching `crates/tldr-cli/src/commands/daemon/` that adds a config-file loader
- A new flag appearing in `DaemonStartArgs` (especially `--idle-timeout` or `--global`)
- A CHANGELOG entry mentioning "service support", "always-on", "auto-start", "config file", "idle timeout", or "global daemon"
- Any upstream blog post or release notes describing a daemon-lifecycle improvement

When detected: re-run the verification probe from this document, update `02_KEY_FINDINGS.md` and `03_CONFIG_REFERENCE.md`, and revisit whether the install script is now buildable.

## Cross-references

- `01_RESEARCH_METHODOLOGY.md` — how we verified upstream claims against source
- `02_KEY_FINDINGS.md` — corrected daemon architecture (per-project, multi-daemon registry)
- `03_CONFIG_REFERENCE.md` — full DaemonConfig schema with "configurable today?" status per field
- `../UPSTREAM_WATCHLIST.md` — tracks the specific upstream changes we're waiting for
- `../07_SKILL_ARCHITECTURE_DECISION.md` — `tldr-runtime` and `tldr-setup-check` skills referenced above
