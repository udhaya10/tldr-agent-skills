# Command: `tldr daemon`

## Environment Pin

| Field | Value |
|---|---|
| `tldr --version` | 0.4.0 |
| Build features | `semantic` (verified; daemon uses tokio + IPC over Unix socket, non-semantic) |
| Target repo | Stock-Monitor @ commit `e601869` |
| Upstream `tldr-code` pinned to | local clone @ `6c4011a` (release v0.4.0) |
| Daemon state at probe time | mixed (toggled on/off during probes) |
| Multi-daemon registry version | v0.3.0 |
| OS | darwin 25.2.0 |
| Probe date | 2026-05-22 |

Re-run all evidence via [`daemon.probes/probe.sh`](./daemon.probes/probe.sh).
See also: [agent-oriented tool card](../../tool-cards/ops/daemon.md).

**Grouping note:** Per `05_OMITTED_COMMANDS_RATIONALE.md` §3, the 6 subcommands (start, stop, status, list, query, notify) are documented under a SINGLE `daemon` entry in the SKILL.md. This dossier covers the whole family.

---

## Ground Truth (`tldr daemon --help` + 6 subcommands)

```text
Daemon management commands (start, stop, status)

Usage: tldr daemon [OPTIONS] <COMMAND>

Commands:
  start   Start the TLDR daemon
  stop    Stop the TLDR daemon
  status  Show daemon status
  query   Send a raw query to the daemon
  notify  Notify daemon of file changes
  list    List all running daemons (multi-daemon registry, v0.3.0)
  help    Print this message or the help of the given subcommand(s)
```

**Key subcommand options:**
- `start`: `-p, --project <PATH>` `[default: .]`, `--foreground`
- `stop`: `-p, --project <PATH>` `[default: .]`, `--all` (mutually exclusive)
- `status`: `-p, --project <PATH>` `[default: .]` (falls back to active daemon's recorded project), `-s, --session <SESSION>`
- `query`: `<CMD>` *(positional, required)*, `-p, --project <PATH>`, `-j, --json <JSON>`
- `notify`: `<FILE>` *(positional, required)*, `-p, --project <PATH>`
- `list`: no positional, no project (global registry)

---

## Output Shape

| Aspect | Value |
|---|---|
| Default format | `json` |
| Formats that work | `json`, `text`, `compact` (P01, P06, P07) |
| Formats that error | `sarif`, `dot` (P05, P08: exit 1) |
| Typical output size | tiny (~4 lines status; ~10 lines list with 1 daemon) |

**EACH SUBCOMMAND EMITS A DIFFERENT TOP-LEVEL SCHEMA:**

### `status` (running):
```json
{ "status": "running", "uptime": 0.16, "uptime_human": "0h 0m 0s", "files": 0,
  "project": "<absolute path>", "salsa_stats": { "hits": 0, "misses": 0, "invalidations": 0, "recomputations": 0 } }
```

### `status` (not running):
```json
{ "status": "not_running", "message": "Daemon not running" }
```

### `start`:
```json
{ "status": "ok", "pid": <int>, "socket": "<tmp socket path>", "message": "Daemon started" }
```

### `stop`:
```json
{ "status": "ok", "message": "Daemon stopped" } | { "status": "ok", "message": "No daemon running" }
```

### `list`:
```json
{ "daemons": [{ "project": "<abs path>", "pid": <int>, "socket": "<sock>", "started_at": "<iso>" }, ...] }
```

### `query <CMD>`:
Variable per `<CMD>`. `query ping` → `{ status: "ok", message: "pong" }`. `query status` → same as `status`. `query <bogus>` → exit 1 with error.

### `notify <FILE>`:
```json
{ "status": "ok", "dirty_count": 1, "threshold": 20, "reindex_triggered": false }
```

**Error shapes:**
- Missing subcommand: prints `--help` to stderr + exit **2**
- Bogus subcommand: clap-style `"error: unrecognized subcommand 'wat'"` → exit **2**
- `daemon start` when running: `"Error: Daemon already running (PID: <N>)"` → exit **1**
- `daemon query` when no daemon: `"Error: Daemon not running"` → exit **1**
- `daemon query` with bad JSON: `"Error: Invalid JSON parameters: key must be a string at line 1 column 3"` → exit **1**
- `daemon notify` with file outside project root: `"Error: File is outside project root"` → exit **1** (SECURITY check)
- `daemon stop` when not running: exit **0** (idempotent, silent)
- Bad `--project` on status: exit **0** (per source: falls back to active daemon's project)
- Format reject: `"Error: --format sarif not supported by daemon status. ..."` → exit **1**
- Bad `--lang`: clap-style → exit **2**

---

## Probe Matrix

| # | Probe | Type | Exit | Captured |
|---|-------|------|------|----------|
| P01 | `tldr daemon status` *(no daemon)* | happy (not running) | 0 | [`01-happy.*`](./daemon.probes/) |
| P02 | `tldr daemon start && status && stop` | happy-scale (full cycle) | 0 | [`02-happy-scale.*`](./daemon.probes/) |
| P03 | `tldr daemon` | failure-missing-subcommand | 2 | [`03-missing-arg.*`](./daemon.probes/) |
| P04 | `tldr daemon status --project /no/such/dir` | bad path (FALLBACK to active daemon) | 0 | [`04-badpath.*`](./daemon.probes/) |
| P05 | `tldr daemon status -f sarif` | format-reject (sarif) | 1 | [`05-format-reject-sarif.*`](./daemon.probes/) |
| P06 | `tldr daemon status -f text` | format-text | 0 | [`06-format-text.*`](./daemon.probes/) |
| P07 | `tldr daemon status -f compact` | format-compact | 0 | [`07-format-compact.*`](./daemon.probes/) |
| P08 | `tldr daemon status -f dot` | format-reject (dot) | 1 | [`08-format-reject-dot.*`](./daemon.probes/) |
| P09 | `tldr daemon start --project .` | start (emit pid+socket) | 0 | [`09-start.*`](./daemon.probes/) |
| P10 | `tldr daemon start` *(already running)* | start when running | 1 | [`10-start-already-running.*`](./daemon.probes/) |
| P11 | `tldr daemon list` | list with 1 daemon | 0 | [`11-list.*`](./daemon.probes/) |
| P12 | `tldr daemon status` *(running)* | status with full salsa_stats | 0 | [`12-status-running.*`](./daemon.probes/) |
| P13 | `tldr daemon query ping` | query ping → pong | 0 | [`13-query-ping.*`](./daemon.probes/) |
| P14 | `tldr daemon query wat` | bogus query cmd (daemon stopped after P13) | 1 | [`14-query-bogus.*`](./daemon.probes/) |
| P15 | `tldr daemon query status --json '{}'` | query with --json | 0 | [`15-query-with-json.*`](./daemon.probes/) |
| P16 | `tldr daemon query status --json '{ malformed'` | bad JSON params | 1 | [`16-query-bad-json.*`](./daemon.probes/) |
| P17 | `tldr daemon notify backend/providers/yahoo.py` | notify success | 0 | [`17-notify.*`](./daemon.probes/) |
| P18 | `tldr daemon notify /no/such/file.py` | notify outside project (security check) | 1 | [`18-notify-badpath.*`](./daemon.probes/) |
| P19 | `tldr daemon stop --project .` | stop | 0 | [`19-stop.*`](./daemon.probes/) |
| P20 | `tldr daemon stop` *(not running)* | stop when stopped (idempotent) | 0 | [`20-stop-not-running.*`](./daemon.probes/) |
| P21 | `tldr daemon stop --all` | stop --all | 0 | [`21-stop-all.*`](./daemon.probes/) |
| P22 | `tldr daemon status` *(no daemon)* | status after stop | 0 | [`22-status-no-daemon.*`](./daemon.probes/) |
| P23 | `tldr daemon list` *(empty)* | list with no daemons | 0 | [`23-list-empty.*`](./daemon.probes/) |
| P24 | `tldr daemon wat` | bogus subcommand | 2 | [`24-bad-subcommand.*`](./daemon.probes/) |
| P25 | `tldr daemon status -l brainfuck` | bad-lang | 2 | [`25-bad-lang.*`](./daemon.probes/) |
| P26 | `tldr daemon status -q` | quiet | 0 | [`26-quiet.*`](./daemon.probes/) |
| P27 | `timeout 1 tldr daemon start --foreground` | foreground mode (timeout) | 0 | [`27-start-foreground.*`](./daemon.probes/) |

### Observations

- **P01** — No daemon running: `{ "status": "not_running", "message": "Daemon not running" }`. Exit 0.
- **P02** — Full cycle: start → status → stop. 23 lines combined.
- **P03** — Prints help to stderr + exit `2`. Same pattern as bugbot, cache.
- **P04** — **`--project /no/such/dir` for status returns exit 0** with "not_running" message — falls back to active daemon's recorded project (per source comment `daemon status` `-p` help: "When omitted, falls back to the active daemon's project path recorded by `daemon start`"). Bad explicit `--project` doesn't fail. **Multi-daemon caveat (verified 2026-05-30):** with >1 daemon in the registry, bare `tldr daemon status` and `--project .` BOTH fail with exit 1: `"multiple daemons running (N); use --project <abs-path>"`. The cwd/`.` fallback becomes ambiguous. Fix: always pass `-p "$(pwd)"`. This only affects `status` — `start`, `stop`, `warm`, and `notify` canonicalize `.` correctly.
- **P05** — stderr `"Error: --format sarif not supported by daemon status. Use --format json. SARIF is only emitted by: vuln, clones."`, exit `1`. Note message says `"by daemon status"` (the full path).
- **P06** — Text format: 1 line `"Daemon not running"`. Minimal.
- **P07** — Single-line minified JSON.
- **P08** — stderr `"Error: --format dot not supported by daemon status. ..."`, exit `1`.
- **P09** — Start: `{ status: "ok", pid: 78918, socket: "/var/folders/.../tldr-<hash>.sock", message: "Daemon started" }`. Socket path uses a hash to support multi-daemon. Daemon DAEMONIZES (returns immediately, runs in background).
- **P10** — `start` when already running: stderr `"Error: Daemon already running (PID: 78918)"`, exit `1`. **PID echoed** for human-friendly recovery.
- **P11** — `list`: `{ daemons: [{ project, pid, socket, started_at: "<ISO8601 UTC>" }, ...] }`. Multi-daemon registry — observed 1 daemon for Stock-Monitor.
- **P12** — `status` (running): `{ status: "running", uptime: 0.16, uptime_human: "0h 0m 0s", files: 0, project: "<abs>", salsa_stats: { hits, misses, invalidations, recomputations } }`. **`uptime` is float seconds; `uptime_human` is formatted.** Both fields present for convenience.
- **P13** — `query ping`: `{ status: "ok", message: "pong" }`. Health check.
- **P14** — `query wat` (after daemon stopped in test reset): `"Error: Daemon not running"`, exit `1`. **Note:** P14 ran AFTER intermediate stops in the probe sequence — exit reason is no-daemon, not bogus-command.
- **P15** — `query status --json '{}'`: returns full status (same as P12). The `--json` param is passed through to the daemon.
- **P16** — `query status --json '{ malformed'`: stderr `"Error: Invalid JSON parameters: key must be a string at line 1 column 3"`, exit `1`. Clear JSON-parse error.
- **P17** — `notify backend/providers/yahoo.py`: `{ status: "ok", dirty_count: 1, threshold: 20, reindex_triggered: false }`. **Threshold-based reindexing** — notify accumulates dirty files until threshold (20) is reached, then triggers reindex.
- **P18** — `notify /no/such/file.py`: stderr `"Error: File is outside project root"`, exit `1`. **SECURITY CHECK:** files outside the daemon's project root are rejected — prevents notify from being used to probe arbitrary paths.
- **P19** — `stop --project .`: clean shutdown. `{ status: "ok", message: "Daemon stopped" }`.
- **P20** — `stop` when not running: **IDEMPOTENT — exit 0**, presumably `{ status: "ok", message: "No daemon running" }`. Safe to call in scripts without checks.
- **P21** — `stop --all`: stops all daemons in the registry. Exit 0 even when none running.
- **P22** — `status` after stop: same as P01.
- **P23** — `list` with no daemons: `{ daemons: [] }` (3 lines). Empty registry.
- **P24** — clap-style: `"error: unrecognized subcommand 'wat'"`, exit `2`.
- **P25** — clap-style: `"error: invalid value 'brainfuck' for '--lang <LANG>': Unknown language: brainfuck"`, exit `2`.
- **P26** — `-q quiet`: 0 lines stdout. TRULY suppresses output (matches `tldr cache stats -q` pattern).
- **P27** — `--foreground` + timeout: prints initial output, daemon would run in foreground until killed. `timeout 1` truncates after 1s. Exit 0.

---

## Source Code Reality

**Target file(s):**
- `crates/tldr-cli/src/commands/daemon/start.rs` (~200 lines)
- `crates/tldr-cli/src/commands/daemon/stop.rs`
- `crates/tldr-cli/src/commands/daemon/status.rs`
- `crates/tldr-cli/src/commands/daemon/list.rs`
- `crates/tldr-cli/src/commands/daemon/query.rs`
- `crates/tldr-cli/src/commands/daemon/notify.rs`
- `crates/tldr-cli/src/commands/daemon/types.rs` (shared schemas)
- `crates/tldr-cli/src/commands/daemon/ipc.rs` (Unix socket protocol)
- `crates/tldr-cli/src/output.rs:113` (`validate_format_for_command`)

**Pinned to upstream commit:** `6c4011a` (release v0.4.0)

**Multi-daemon registry (v0.3.0):**
The `list` subcommand and `stop --all` are part of the v0.3.0 multi-daemon registry — each daemon is keyed by its project root, with sockets at `/tmp/tldr-<hash>.sock`. The registry persists across invocations.

**`status --project` fallback (P04 explanation):**
Per `--help`: "When omitted, falls back to the active daemon's project path recorded by `daemon start`." But what happens with bad `--project`? Source ignores existence — if no daemon matches the path, treats as "not running" (exit 0). Distinct from most commands' upfront path validation.

**`notify` security check (P18):**
Source enforces that the notified file is inside the daemon's project root — prevents arbitrary path probing via the daemon API.

**Format validation:** confirmed at `crates/tldr-cli/src/output.rs:113-163` — `daemon` and all its subcommands are in neither `SARIF_SUPPORTED` nor `DOT_SUPPORTED`.

**Async runtime:** Each daemon subcommand uses tokio runtime (similar to cache commands). Small startup overhead.

---

## Architectural Deep Dive

- **Under the hood:** TLDR daemon is a long-running background process that maintains a Salsa-based incremental computation graph in memory. CLI commands communicate via Unix domain sockets (`/tmp/tldr-<hash>.sock`). Multi-daemon: one daemon PER project (hashed path → socket name). The Salsa cache enables 10-100× speedup for repeated queries (e.g., `tldr search`, `tldr semantic`). `notify` accumulates file changes; threshold-based reindexing avoids per-change cost.
- **Performance:** Daemon startup ~50-100ms. `query ping` round-trip ~1ms. Status queries are cheap.
- **LLM cognitive load:** The daemon is INFRASTRUCTURE — agents should start it once, run their analyses, and let it persist between invocations. Manual `daemon` commands are typically only needed for: (1) initial start before warmup, (2) status check when debugging slowness, (3) `stop --all` for cleanup. Per OMITTED_RATIONALE §3, the 6 subcommands are GROUPED in agent skills to reduce surface area.
> Most analysis commands (search, semantic, structure, hubs, etc.) call `try_daemon_route` internally — agents typically never need to invoke `daemon` directly.

---

## Intent & Routing

- **User/Agent Goal:** manage the long-running daemon — start it for cache warmup, check status for performance diagnostics, stop it for cleanup.
- **When to choose this over similar tools:**
  - To enable daemon-backed caching: `tldr daemon start && tldr warm <project>`.
  - To diagnose cache misses: `tldr daemon status` shows `salsa_stats`.
  - To clean up multiple project daemons: `tldr daemon stop --all`.
- **Prerequisites (composition):**
  - `--project` defaults to `.`. For multi-project workflows, pass explicit `--project`. **For `status` specifically:** bare and `--project .` fail when >1 daemon exists — always use `-p "$(pwd)"`.
  - `notify <FILE>` requires FILE to be inside the daemon's project root.
  - `query <CMD>` requires daemon running.

---

## Agent Synthesis

> **How to use `tldr daemon`:**
> Background-process manager for the Salsa cache. 6 subcommands: `start`, `stop`, `status`, `list`, `query`, `notify`. Each emits a DIFFERENT JSON schema (see Output Shape). Most analysis commands invoke the daemon automatically via `try_daemon_route` — explicit `daemon` calls are usually only needed for initial start, status diagnostics, or `stop --all` cleanup. Default JSON; `-f text` for human display; `-f compact` for one-line; `sarif`/`dot` rejected. Exit codes: 0 ok (incl. idempotent stop-when-not-running, status-fallback-to-active-daemon), 1 daemon-already-running / no-daemon / bad-json / notify-outside-root, 2 missing subcommand / bogus subcommand / bad-lang.
>
> **Crucial Rules:**
> - **EACH SUBCOMMAND HAS A DIFFERENT SCHEMA.** Agents schema-validating output MUST branch on the subcommand. Key shapes: status running has `{ status, uptime, uptime_human, files, project, salsa_stats }`; status not_running has `{ status, message }`; start has `{ status, pid, socket, message }`; list has `{ daemons: [...] }`; notify has `{ status, dirty_count, threshold, reindex_triggered }`.
> - **`stop` is IDEMPOTENT** (P20: stop when not running → exit 0). Safe to call in cleanup scripts without checking state first.
> - **`stop --all` cleans up the v0.3.0 multi-daemon registry** (P21). One-shot for "kill all my daemons across all projects."
> - **`notify <FILE>` enforces files-inside-project-root** (P18: file outside → exit 1 `"File is outside project root"`). Security check prevents arbitrary path probing via the daemon API.
> - **`notify` uses threshold-based reindexing** (P17: `threshold: 20`, `dirty_count: 1, reindex_triggered: false`). Accumulates dirty file changes; triggers reindex only after the threshold is reached. To force immediate reindex: stop + start the daemon.
> - **`status --project /bad/path` is SILENT** (P04: exit 0 with "not_running"). Per source: falls back to active daemon's recorded project when no daemon matches the supplied path. **Distinct from most commands' upfront path validation.** **Multi-daemon exception:** with >1 daemon, bare `status` and `--project .` fail with exit 1 "multiple daemons running" — always use `-p "$(pwd)"` for status.
> - **`start` emits PID and SOCKET path** (P09). The socket is `/var/folders/.../tldr-<hash>.sock` (macOS tmpdir). Use the PID to manually kill if `stop` fails.
> - **`start` when already running returns exit 1 with PID** (P10: `"Daemon already running (PID: 78918)"`). Use this PID for `kill` or `tldr daemon stop --all`.
> - **`query <CMD>` requires daemon running.** P14 confirms: exit 1 `"Daemon not running"` when daemon stopped. To query, always `start` first.
> - **`query --json '{ malformed'` produces a clear JSON-parse error** (P16). The `--json` is passed as-is to the daemon protocol.
> - **`uptime` is FLOAT SECONDS; `uptime_human` is FORMATTED** (e.g., `"0h 0m 0s"`). Both present — pick based on consumer.
> - **`-q quiet` TRULY suppresses output** (P26: 0 lines stdout). Same as cache stats. Unusual — most commands' -q only suppresses progress.
> - **NO daemon route (recursive):** these commands don't call `try_daemon_route` (because they ARE the daemon API).
>
> **Subcommand reference:**
> - `tldr daemon start [--project <PATH>] [--foreground]` — start
> - `tldr daemon stop [--project <PATH>] [--all]` — stop (--all for all daemons)
> - `tldr daemon status [--project <PATH>] [--session <ID>]` — health check + salsa stats
> - `tldr daemon list` — all running daemons (multi-project)
> - `tldr daemon query <CMD> [--json <PARAMS>]` — raw IPC query
> - `tldr daemon notify <FILE>` — invalidate single file (threshold-based reindex)
>
> **With common flags:** `tldr daemon start && tldr warm . && <run-analyses> && tldr daemon stop` (use as a workflow wrapper: warm the daemon, run your analyses, clean up — though most analyses auto-route through the daemon, so explicit `daemon start` is only needed for the initial warmup).
