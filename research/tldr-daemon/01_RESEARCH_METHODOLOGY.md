# Research Methodology — TLDR Daemon Lifecycle

## Purpose

When planning an always-on daemon installation (launchd/systemd service) for the `tldr-code` CLI, several earlier claims in this project's documentation turned out to be wrong. This research folder captures the correct daemon architecture, configuration surface, and lifecycle constraints — derived from reading the actual source code at commit `6c4011a` (v0.4.0) rather than from upstream docs alone.

## Why we couldn't just trust the docs

Two upstream documents are unreliable on daemon specifics:

| Document | What it claims | What's actually true |
|----------|---------------|---------------------|
| `docs/SETUP.md` | "Default idle timeout: 300 seconds" | Default is **1800 seconds** (30 min) per `IDLE_TIMEOUT_SECS` constant in `crates/tldr-cli/src/commands/daemon/types.rs:21` |
| `docs/SETUP.md` | "Default semantic model: arctic-m" | Default is **`bge-large-en-v1.5`** per `DaemonConfig::default()` |
| `docs/TROUBLESHOOTING.md` | `tldr daemon start --idle-timeout 600` is a valid command | **No `--idle-timeout` flag exists** on `daemon start` in v0.4.0; only `--project` and `--foreground` |
| `crates/tldr-cli/src/commands/daemon/types.rs` doc comment | "Daemon configuration loaded from `.tldr/config.json` or `.claude/settings.json`" | **Config files are NOT loaded** in v0.4.0; `daemon start` calls `DaemonConfig::default()` directly with no file I/O |

The pattern is consistent: upstream docs describe features as if implemented, but several are aspirational. The source code is the only reliable record of v0.4.0 behavior.

> **Rule of thumb**: For tldr-code daemon questions, **trust the source, not the docs**. Re-verify any doc claim against `crates/tldr-cli/src/commands/daemon/` before designing around it.

## How this research was conducted

### Sources

| Source | Where | Authority |
|--------|-------|-----------|
| Local clone | `/Users/udhayakumar/Workspace/03-Parcadei-Ecosystem/tldr-code` @ commit `6c4011a` (v0.4.0) | Highest — actual Rust source code |
| Upstream docs (scraped 2026-05-22) | `references/upstream-SETUP.md`, `upstream-INSTALL.md`, `upstream-TROUBLESHOOTING.md` | Lower — known to contain stale claims |
| Source-level spec | `crates/tldr-cli/src/commands/daemon/spec.md` (1406 lines in the clone) | Medium — documentation of intent; some described features not yet shipped |

### Verification probes used

For each claim about the daemon, the investigation:

1. **Read the source struct definitions** — e.g., `DaemonStartArgs` in `start.rs` to enumerate actual CLI flags
2. **Searched for the field's read sites** — e.g., `grep "self.config.idle_timeout_secs"` in `daemon.rs` to confirm the field is actually used at runtime
3. **Searched for config file I/O** — `grep "config.json\|settings.json"` across `crates/` to find where (if anywhere) config files are loaded
4. **Searched for env var reads** — `grep "std::env::var"` to find any environment-variable-based overrides
5. **Read the `Default` impl** — to know what values are used when no config file is provided

This is the same "Zero Trust in Documentation" principle from Journal 03, applied to a different tool. The upstream docs are useful for context but cannot be trusted for behavioral claims about specific flags or features.

## Where the findings live

| File | Content |
|------|---------|
| `02_KEY_FINDINGS.md` | The corrected daemon architecture (per-project, multi-daemon registry), explicit list of corrections from prior project claims, implications for always-on install |
| `03_CONFIG_REFERENCE.md` | Exhaustive reference for the `DaemonConfig` schema (all 4 fields), the loading-not-implemented gap, sample config files for forward-compatibility |
| `references/upstream-SETUP.md` | Scraped upstream SETUP.md (2026-05-22) |
| `references/upstream-INSTALL.md` | Local copy of upstream INSTALL.md |
| `references/upstream-TROUBLESHOOTING.md` | Local copy of upstream TROUBLESHOOTING.md |

## Re-running this research

When `tldr-code` releases a new version (currently 0.4.0):

```bash
# Update the local clone
cd /Users/udhayakumar/Workspace/03-Parcadei-Ecosystem/tldr-code
git pull
git log -1 --oneline  # Capture the new commit SHA

# Re-verify the four key facts:
# 1. Idle timeout default
grep "IDLE_TIMEOUT_SECS" crates/tldr-cli/src/commands/daemon/types.rs

# 2. DaemonConfig defaults
grep -A8 "impl Default for DaemonConfig" crates/tldr-cli/src/commands/daemon/types.rs

# 3. daemon start CLI flags
grep -A2 "#\[arg" crates/tldr-cli/src/commands/daemon/start.rs

# 4. Is config file loading wired up?
grep -rE "\\.tldr/config\\.json|\\.claude/settings\\.json" crates/ --include="*.rs" | grep -v test

# Update 02_KEY_FINDINGS.md and 03_CONFIG_REFERENCE.md with any deltas
# Re-scrape upstream docs into references/ with the new commit SHA in their headers
```

When new claims about daemon behavior surface (in our skills, install scripts, or docs), validate them against these source files before shipping.
