# Command: `tldr cache`

## Environment Pin

| Field | Value |
|---|---|
| `tldr --version` | 0.4.0 |
| Build features | `semantic` (verified; cache uses tokio runtime + SQLite, non-semantic) |
| Target repo | Stock-Monitor @ commit `e601869` (cache present with 3 files, 16.6 MB) |
| Upstream `tldr-code` pinned to | local clone @ `6c4011a` (release v0.4.0) |
| Daemon state at probe time | inactive (stats route falls back to filesystem scan) |
| OS | darwin 25.2.0 |
| Probe date | 2026-05-22 |

Re-run all evidence via [`cache.probes/probe.sh`](./cache.probes/probe.sh).
See also: [agent-oriented tool card](../../tool-cards/ops/cache.md).

**Omission note:** Per `05_OMITTED_COMMANDS_RATIONALE.md` §2, `tldr cache` is **SUPPRESSED from agent-facing skills**. Calling `tldr cache clear` while an agent is iterating wipes the daemon's analysis cache and causes ~10× slowdown on subsequent commands. This dossier exists for **research completeness** — agents should NOT be guided to invoke this command.

---

## Ground Truth (`tldr cache --help` + subcommands)

```text
Cache management commands (stats, clear)

Usage: tldr cache [OPTIONS] <COMMAND>

Commands:
  stats  Show cache statistics
  clear  Clear cache files
  help   Print this message or the help of the given subcommand(s)
```

```text
tldr cache stats:
  -p, --project <PROJECT>          [default: .]

tldr cache clear:
  -p, --project <PROJECT>          [default: .]
```

Both subcommands share: `-f, --format`, `-l, --lang`, `-q, --quiet`, `-v, --verbose`. **No --force / --confirm** on `clear` — it's silent and unconditional.

---

## Output Shape

| Aspect | Value |
|---|---|
| Default format | `json` |
| Formats that work | `json`, `text`, `compact` (P01, P06, P07) |
| Formats that error | `sarif`, `dot` (P05, P08: exit 1) |
| Typical output size | tiny (~7 lines for stats with cache; ~3 lines for no-cache; ~7 for clear result) |

**Top-level keys (JSON) — DIFFERS by subcommand:**

### `tldr cache stats`:
```json
{
  "salsa_stats": { ... } | null,    // only when daemon is RUNNING
  "cache_files": { "file_count": <N>, "total_bytes": <N>, "total_size_human": "16.6 MB" } | null,
  "message": "..." | null           // populated when cache absent
}
```
Fields are `Option` types — omitted when null (`#[serde(skip_serializing_if = "Option::is_none")]`).

### `tldr cache clear`:
```json
{
  "status": "ok",
  "files_removed": <N>,
  "bytes_freed": <N>,
  "size_freed_human": "0 B",
  "message": "..." | null     // populated when cache absent
}
```

**Empty-result shape (no cache exists — P17, also P04 bad path):**
- stats: `{ "message": "No cache directory found" }` — exit 0
- clear: `{ status: "ok", files_removed: 0, bytes_freed: 0, size_freed_human: "0 B", message: "No cache directory found" }` — exit 0

**Error shapes:**
- Missing subcommand: prints help to stderr + exit **2** (clap)
- Bogus subcommand (`tldr cache wat`): clap-style `"error: unrecognized subcommand 'wat'"` → exit **2**
- Bad `--project` for stats: exit **0** (no validation; returns `"No cache directory found"`)
- Bad `--project` for clear: exit **0** (no validation; returns `status: "ok", files_removed: 0`)
- Format reject sarif: `"Error: --format sarif not supported by cache stats. ..."` → exit **1**
- Bad `--lang`: clap-style → exit **2**

---

## Probe Matrix

| # | Probe | Type | Exit | Captured |
|---|-------|------|------|----------|
| P01 | `tldr cache stats` | happy (current dir cache: 3 files, 16.6 MB) | 0 | [`01-happy.*`](./cache.probes/) |
| P02 | `tldr cache stats --project .` | happy-scale | 0 | [`02-happy-scale.*`](./cache.probes/) |
| P03 | `tldr cache` *(no subcommand)* | failure-missing-subcommand | 2 | [`03-missing-arg.*`](./cache.probes/) |
| P04 | `tldr cache stats --project /no/such/dir` | bad path (silent: "No cache directory found") | 0 | [`04-badpath.*`](./cache.probes/) |
| P05 | `tldr cache stats -f sarif` | format-reject (sarif) | 1 | [`05-format-reject-sarif.*`](./cache.probes/) |
| P06 | `tldr cache stats -f text` | format-text | 0 | [`06-format-text.*`](./cache.probes/) |
| P07 | `tldr cache stats -f compact` | format-compact | 0 | [`07-format-compact.*`](./cache.probes/) |
| P08 | `tldr cache stats -f dot` | format-reject (dot) | 1 | [`08-format-reject-dot.*`](./cache.probes/) |
| P09 | `tldr cache stats -p .` | -p shorthand for --project | 0 | [`09-stats-p-short.*`](./cache.probes/) |
| P10 | `tldr cache clear --project <tmp>` | clear (destructive; tmp dir) | 0 | [`10-clear-tmp.*`](./cache.probes/) |
| P11 | `tldr cache clear --project /no/such/dir` | clear bad path (silent: 0 files removed) | 0 | [`11-clear-badpath.*`](./cache.probes/) |
| P12 | `tldr cache help` | help subcommand | 0 | [`12-help-subcommand.*`](./cache.probes/) |
| P13 | `tldr cache wat` | bogus subcommand | 2 | [`13-subcommand-bogus.*`](./cache.probes/) |
| P14 | `tldr cache stats -l brainfuck` | bad-lang | 2 | [`14-bad-lang.*`](./cache.probes/) |
| P15 | `tldr cache stats -l python` | explicit python (lang flag ignored?) | 0 | [`15-lang-python.*`](./cache.probes/) |
| P16 | `tldr cache stats -q` | quiet (TRULY suppresses output) | 0 | [`16-quiet.*`](./cache.probes/) |
| P17 | `tldr cache stats --project <fresh-tmp>` | no cache present | 0 | [`17-stats-no-cache.*`](./cache.probes/) |

### Observations

- **P01** — Stock-Monitor root has an existing cache: `{ "cache_files": { "file_count": 3, "total_bytes": 17452198, "total_size_human": "16.6 MB" } }`. **No `salsa_stats`** because daemon is not running (only filesystem scan).
- **P02** — Same as P01 (`--project .` = default).
- **P03** — Prints `--help` to stderr, exit `2`. Same pattern as `tldr bugbot`.
- **P04** — **SILENT BAD PATH:** `--project /no/such/dir` returns exit 0 with `{ "message": "No cache directory found" }`. **No upfront path validation.** Same shape as "no cache exists" — agents cannot distinguish "path missing" from "no cache yet."
- **P05** — stderr `"Error: --format sarif not supported by cache stats. ..."`, exit `1`. Note message says `"by cache stats"` (the subcommand, not parent `cache`).
- **P06** — Text format: `"Cache Statistics\n================\n\nCache Files:\n  Count: 3 files\n  Size:  16.6 MB"`. Clean tabular output.
- **P07** — Single-line minified JSON.
- **P08** — stderr `"Error: --format dot not supported by cache stats. ..."`, exit `1`.
- **P09** — `-p .` shorthand: identical to `--project .` (P02).
- **P10** — **DESTRUCTIVE on tmp dir:** `{ status: "ok", files_removed: 0, bytes_freed: 0, size_freed_human: "0 B", message: "No cache directory found" }`. Exit 0. Safe because tmp dir had no cache. **WARNING:** `tldr cache clear` on Stock-Monitor would have wiped 16.6 MB of cache and triggered the 10x slowdown per `05_OMITTED_RATIONALE.md`.
- **P11** — `clear --project /no/such/dir`: same shape as P10. **No path validation, no confirmation prompt.** Silent destructive operation (though here no files exist to remove).
- **P12** — `tldr cache help`: prints help text (32 lines). Same as `tldr cache --help`.
- **P13** — stderr `"error: unrecognized subcommand 'wat'"`, exit `2`.
- **P14** — clap-style: `"error: invalid value 'brainfuck' for '--lang <LANG>': Unknown language: brainfuck"`, exit `2`.
- **P15** — Explicit `-l python`: identical to default. **`--lang` flag is parsed but has no observable effect on cache commands** — caching is language-agnostic.
- **P16** — `-q quiet`: **TRULY suppresses output** (0 lines stdout). Confirmed quiet behavior — unlike many commands where `-q` only suppresses progress.
- **P17** — Fresh tmp dir with no cache: `{ "message": "No cache directory found" }`. Exit 0. Same shape as P04 bad path.

---

## Source Code Reality

**Target file(s):**
- `crates/tldr-cli/src/commands/daemon/cache_stats.rs` (~150+ lines)
- `crates/tldr-cli/src/commands/daemon/cache_clear.rs` (~150+ lines)
- `crates/tldr-cli/src/output.rs:113` (`validate_format_for_command`)

**Pinned to upstream commit:** `6c4011a` (release v0.4.0)

**Argument structs (both subcommands):**
```rust
// cache_stats.rs:32-36, cache_clear.rs:35-39
#[derive(Debug, Clone, Args)]
pub struct CacheStatsArgs {
    #[arg(long, short = 'p', default_value = ".")] pub project: PathBuf,
}
// Same for CacheClearArgs.
```
Reveals: BOTH have `--project -p` with default `"."`. NO other flags beyond globals. **NO `--force` / `--confirm`** on clear — destructive operation is silent.

**Daemon-first stats lookup:**
```rust
// cache_stats.rs:78-95
let cmd = DaemonCommand::Status { session: None };
match send_command(&project, &cmd).await {
    Ok(DaemonResponse::FullStatus { salsa_stats, .. }) => {
        // Daemon is running, use its stats
        let cache_files = scan_cache_files(&project)?;
        ...
    }
    // Falls through to filesystem-only scan when daemon not running
}
```
Reveals: stats first tries the daemon. If daemon returns `FullStatus`, both `salsa_stats` (in-memory Salsa cache) AND `cache_files` (on-disk) are populated. If daemon absent: only `cache_files`. **This explains why P01 has no `salsa_stats` in output** — daemon was stopped at probe time.

**Tokio runtime overhead:**
```rust
// cache_stats.rs:62-66
pub fn run(&self, format: OutputFormat, quiet: bool) -> anyhow::Result<()> {
    let runtime = tokio::runtime::Runtime::new()?;
    runtime.block_on(self.run_async(format, quiet))
}
```
Reveals: spawns a new tokio runtime per invocation. Small overhead (~10ms) but distinct from other tldr commands which are sync.

**Format validation:** confirmed at `crates/tldr-cli/src/output.rs:113-163` — `cache stats` is in neither `SARIF_SUPPORTED` nor `DOT_SUPPORTED`.

**No daemon route via try_daemon_route:** (different mechanism — direct `send_command` to daemon for stats only.)

---

## Architectural Deep Dive

- **Under the hood:** Cache management has TWO components: (1) **Salsa cache** (in-memory query cache held by the daemon — survives only while daemon runs), (2) **On-disk cache files** (SQLite/JSON files at the project's cache directory). `stats` queries both; `clear` deletes only the on-disk files (the daemon's Salsa cache is unaffected unless the daemon is also restarted).
- **Performance:** Cache stats lookup ~10-50ms. Cache clear deletes O(N) files but the operation is fast.
- **LLM cognitive load:** **CAUTION: AGENTS SHOULD NOT INVOKE THIS COMMAND.** Per `05_OMITTED_RATIONALE.md` §2: `tldr cache clear` invalidates the daemon's analysis cache. Subsequent commands (e.g., `tldr search`, `tldr semantic`) will be ~10× slower until the cache rebuilds. The OMISSION from agent-facing skills is INTENTIONAL — clearing the cache while iterating is anti-productive.

---

## Intent & Routing

- **User/Agent Goal:** (HUMAN OPERATORS ONLY) inspect cache footprint OR forcibly invalidate stale cache. Agents should NEVER need this.
- **When to choose this over similar tools:**
  - For agents: **NEVER.** Restart the daemon (`tldr daemon stop && tldr daemon start`) if you genuinely suspect stale cache.
  - For humans: `tldr cache stats` to see disk usage; `tldr cache clear` to reclaim space.
- **Prerequisites (composition):**
  - Project directory (default `.`). No actual file required.
  - Daemon NOT required for stats (falls through to filesystem scan).

---

## Agent Synthesis

> **How to use `tldr cache`:**
> **DO NOT USE.** This command is suppressed from agent-facing skills per `05_OMITTED_COMMANDS_RATIONALE.md` §2 because `tldr cache clear` invalidates the daemon's Salsa cache and causes ~10× slowdown on subsequent commands. For research completeness only: `tldr cache stats` returns JSON `{ salsa_stats?, cache_files: { file_count, total_bytes, total_size_human }?, message? }`; `tldr cache clear` returns `{ status: "ok", files_removed, bytes_freed, size_freed_human, message? }`. Both accept `--project -p` (default `.`). Default JSON; `-f text` for human display; `-f compact` for one-line; `sarif`/`dot` rejected. Exit codes: 0 ok (including silent bad-path / no-cache), 1 format-reject, 2 missing subcommand / bogus subcommand / bad-lang.
>
> **Crucial Rules:**
> - **AGENTS: DO NOT INVOKE.** Suppressed per OMITTED_RATIONALE §2. If stale cache is genuinely suspected, restart the daemon via `tldr daemon stop && tldr daemon start` — never `tldr cache clear`.
> - **`tldr cache clear` is SILENT AND UNCONDITIONAL.** No `--force` / `--confirm` flag. P10 confirms — deletes immediately. **HUMAN OPERATORS:** verify `--project` is the right directory before running.
> - **Bad `--project` is SILENT — exit 0 with `"No cache directory found"`.** P04 (stats), P11 (clear). Indistinguishable from "no cache yet" by output alone. Verify path externally.
> - **`salsa_stats` is only populated when daemon is RUNNING.** P01: daemon stopped → no `salsa_stats` field (omitted via serde). Run `tldr daemon start` first if you need in-memory cache stats.
> - **`--lang` flag is parsed but IGNORED** (P15: same output as default). Caching is language-agnostic.
> - **`-q quiet` TRULY suppresses output** (P16: 0 lines stdout). Unusual — most tldr commands' `-q` only suppresses progress messages. Use for scripting when you need just the exit code.
> - **Both subcommands use tokio async runtime** (source: `tokio::runtime::Runtime::new()` per invocation). Small startup overhead vs sync commands.
> - **`stats` falls back gracefully when daemon absent** — returns disk-cache scan only. Distinct from `tldr daemon status` which requires daemon running.
> - **Bogus subcommand returns clap exit 2** with `"error: unrecognized subcommand 'wat'"` — discoverable.
> - **No `try_daemon_route` integration** — uses direct `send_command` mechanism. Cache commands DON'T contribute to or benefit from the standard daemon route caching pattern.
>
> **Command:** `tldr cache stats` (read-only, safe) — `tldr cache clear` (destructive, agents AVOID).
>
> **With common flags:** `tldr cache stats --project <DIR> -f compact | jq '.cache_files.total_size_human'` (HUMAN-only use: quickly check on-disk cache size for a project. Agents should NOT run this in their tool loop.).
