# Key Findings — TLDR Daemon Architecture

## TL;DR

1. **The daemon is per-project, not global.** One daemon process per project root. Multi-daemon registry tracks all running daemons. Earlier project claim that it was "global / project-unaware" was WRONG.
2. **`--idle-timeout` CLI flag does NOT exist.** The TROUBLESHOOTING.md upstream doc that mentions it is wrong. The only `daemon start` flags are `--project` and `--foreground`.
3. **Config file loading is documented but NOT implemented in v0.4.0.** The `DaemonConfig` struct exists with 4 fields; `daemon start` calls `DaemonConfig::default()` and ignores any `.tldr/config.json` or `.claude/settings.json` files. Creating those files today is futile.
4. **The actual user-configurable surface is tiny.** Two CLI flags (`--project`, `--foreground`), one env var (`TLDR_DAEMON_REGISTRY_DIR`, for testing). Everything else is hardcoded defaults.
5. **"Always-on" still works via service auto-restart.** The 30-minute idle auto-shutdown can't be configured, but launchd `KeepAlive=true` / systemd `Restart=always` will restart the daemon immediately after auto-shutdown. Net effect: daemon cycles every 30 min but stays effectively always-up.

## The corrected daemon architecture

### Per-project, not global

Each project gets its own daemon process. Evidence:

```rust
// crates/tldr-cli/src/commands/daemon/start.rs:3
// CLI command: `tldr daemon start [--project PATH] [--foreground]`
// ...
// This module handles starting the TLDR daemon process with:
// - PID file locking to ensure single instance per project
```

The `daemon start` command takes a `--project` flag (defaults to `.`), and the PID lock is *per-project*. Two different projects can have two separate daemons running simultaneously, each on their own Unix socket, each managing their own in-memory cache.

### Multi-daemon registry (v0.3.0+)

There's a registry tracking all running daemons on the machine:

```rust
// crates/tldr-cli/src/commands/daemon/start.rs:144-154
// VAL-003 (v0.3.0): register the daemon in the multi-daemon
// registry. Replaces v0.2.x's single-slot daemon-active.json.
// ...
if let Err(e) = add_entry(project, our_pid, &socket_path) {
    eprintln!("warning: could not register daemon in registry: {}", e);
}
```

And `daemon stop --all` exists to:

> "Stop ALL running daemons known to the v0.3.0 multi-daemon registry. Mutually exclusive with `--project`. Iterates the registry, sends shutdown to each daemon, and removes the entry on success."

So the architecture is explicitly multi-daemon. The user's earlier question — "can the daemon be project-unaware and run as one global process?" — has the answer **no, not by design**.

### Workaround: pseudo-global daemon via a parent path

While the daemon is per-project, the concept of "project" is just "any directory passed to `--project`." So you can:

```bash
tldr daemon start --project ~/Workspace
```

This starts ONE daemon rooted at `~/Workspace`. Any query made from within `~/Workspace/project-A/` or `~/Workspace/project-B/` resolves up to that parent daemon if it's the closest registered project root. **This gives a "one daemon for many projects" experience without the daemon being technically global.**

Caveats:
- The PID lock and socket are tied to `~/Workspace`, not to each sub-project
- Cache may be stored at `~/Workspace/.tldr/` (if you create that dir) or `~/.cache/tldr/` (fallback)
- Queries from outside `~/Workspace` won't be served by this daemon; they'd need their own
- Whether queries from sub-projects actually route to the parent daemon needs empirical verification (depends on how the CLI discovers the right socket)

### Cache locations (corrected understanding)

Per upstream SETUP.md, the cache lives in one of two places:

| Path | When used |
|------|-----------|
| `<project>/.tldr/` | Project-local — if the directory exists in the project root |
| `~/.cache/tldr/` | Global fallback — used when no project-local `.tldr/` dir exists |

The cache itself is content-addressed (SalsaDB-style memoization keyed by file content hashes), so it's largely path-independent at the data layer. The directory location just controls *where the persisted state lives on disk*.

### Idle timeout — fixed at 30 minutes in v0.4.0

The constant in `crates/tldr-cli/src/commands/daemon/types.rs:17-21`:

```rust
/// Idle timeout before daemon auto-shutdown (30 minutes)
pub const IDLE_TIMEOUT: Duration = Duration::from_secs(30 * 60);

/// Idle timeout in seconds for serialization
pub const IDLE_TIMEOUT_SECS: u64 = 30 * 60;
```

And the daemon enforces it in `daemon.rs`:

```rust
let idle_timeout = std::time::Duration::from_secs(self.config.idle_timeout_secs);
// ... in event loop ...
if idle_elapsed >= idle_timeout {
    info!("No client activity for {}s, shutting down", self.config.idle_timeout_secs);
    break;
}
```

The field is *read from config*, but the config is `DaemonConfig::default()` (1800 seconds), and no override mechanism is wired up. So in v0.4.0, **the idle timeout is effectively a hardcoded constant**.

## Corrections to prior project claims

Several claims in earlier project documents (chat logs, README versions, the `tldr-setup-check` SKILL.md) were wrong. Recording them here for the record:

| Earlier claim | Correct fact | Where the wrong claim appeared |
|---------------|--------------|-------------------------------|
| "The daemon is a singleton; one process per user" | One process per *project*; multi-daemon registry | Multiple chat-thread explanations during setup-check skill design |
| "`--idle-timeout` flag is supported on `daemon start`" | No such flag; doc was wrong | Multiple chat-thread explanations, citing upstream TROUBLESHOOTING.md |
| "Default idle timeout is 300 seconds" | 1800 seconds (30 min) | Same |
| "Default semantic model is `arctic-m`" | `bge-large-en-v1.5` | `tldr-setup-check` SKILL.md and chat references |
| "Config files at `.tldr/config.json` or `.claude/settings.json` let you override anything" | The struct exists; the loading code does NOT. Files are ignored in v0.4.0. | Multiple chat explanations |

**Action**: when a v0.5+ release lands, re-verify config-loading status. If it's implemented, update the skill files and chat-derived docs to reflect the new override surface. Until then, treat all 4 `DaemonConfig` fields as effectively constants.

## Implications for the always-on install design

Given the per-project daemon and no idle-timeout override, the design space is:

### Design A — One daemon, one parent path (recommended for most users)

Run one daemon rooted at a common parent of all your work:

```bash
tldr daemon start --project ~/Workspace
```

- Service definition: launchd plist or systemd unit calls this
- `KeepAlive=true` (launchd) / `Restart=always` (systemd) — restarts daemon when it auto-shuts after 30 min
- Cache persists on disk between restarts (Salsa store at `~/Workspace/.tldr/` or `~/.cache/tldr/`)
- Net effect: daemon cycles every 30 min idle, but service brings it back immediately

**Open question** for empirical verification: when running `tldr search "foo"` from `~/Workspace/sub-project/`, does the CLI find and use the parent daemon at `~/Workspace`, or does it start a NEW daemon for `sub-project`? Needs probe.

### Design B — One daemon per project (if you only work on one project)

Standard usage: `tldr daemon start` in the project root. Service can pin to that project.

- Simpler if you only have one project that benefits from daemon caching
- Doesn't scale if you context-switch between many projects

### Design C — Multi-daemon registry, no service

Don't install a service. Let daemons start on-demand (some hooks in `ContinuousClaudeV4.7` could do this), and rely on the registry + `daemon stop --all` for cleanup.

- Lazy, no always-on overhead
- But pays cold-start cost frequently
- Hard to keep state warm

### What we'd ship for Design A (the recommended path)

1. `bin/install-daemon-service.sh` — interactive installer that:
   - Asks the user for the "parent project path" (default: `~/Workspace`)
   - Detects OS (darwin/linux)
   - Installs the appropriate plist/unit file with the chosen path baked in
   - Enables auto-start at login and KeepAlive on graceful exit
   - Verifies daemon is running after install
2. `assets/com.tldr-code.daemon.plist.tmpl` (macOS) with `{{WARM_PATH}}` placeholder
3. `assets/tldr-daemon.service.tmpl` (Linux) with same placeholder
4. `bin/uninstall-daemon-service.sh` — cleanly remove
5. Update `tldr-setup-check` SKILL.md to add a check: "is the service installed and the daemon registered for the chosen path?"

The 30-min idle cycle is acceptable because the service brings the daemon back automatically, and cache persistence means restart cost is small.

### Net effect for the user

- Daemon comes back up at login, stays effectively always-on (cycles every ~30 min idle but auto-restarts)
- One installation script, one config decision (which parent path?), then forget it
- When tldr-code v0.5 lands config file loading, we can update the install script to also drop a `.tldr/config.json` with extended `idle_timeout_secs` so the cycling stops entirely

## What this doesn't fix

- **Multi-project workflow**: if you work across projects that aren't under one parent dir, you'll either run multiple daemons or accept that some projects pay cold-start cost
- **Cross-machine sync**: each machine has its own daemon registry and cache; no remote/shared mode exists
- **Restart visibility**: when the daemon cycles every 30 min, the user has no UI signal; only `tldr daemon status` shows current state

These are gaps in the upstream tool itself, not things our install script can address. Worth flagging in the `tldr-setup-check` skill so users aren't surprised.
