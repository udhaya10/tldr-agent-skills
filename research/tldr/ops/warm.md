# Command: `tldr warm`

## Environment Pin

| Field | Value |
|---|---|
| `tldr --version` | 0.4.0 |
| Build features | `semantic` (verified; warm builds the call graph index, non-semantic for the index itself) |
| Target repo | Stock-Monitor @ commit `e601869` (866 files, 38383 edges, 3 languages) |
| Upstream `tldr-code` pinned to | local clone @ `6c4011a` (release v0.4.0) |
| Daemon state at probe time | mixed (P01-P10 cold; P11 with daemon running) |
| OS | darwin 25.2.0 |
| Probe date | 2026-05-22 |

Re-run all evidence via [`warm.probes/probe.sh`](./warm.probes/probe.sh).
See also: [agent-oriented tool card](../../tool-cards/ops/warm.md).

---

## Ground Truth (`tldr warm --help`)

```text
Pre-warm call graph cache for faster subsequent queries

Usage: tldr warm [OPTIONS] [PATH]

Arguments:
  [PATH]                                       [default: .]

Options:
  -b, --background                             Run warming in background process
  -f, --format <FORMAT>                        [default: json]
  -l, --lang <LANG>
  -q, --quiet  -v, --verbose  -h, --help
```

---

## Output Shape

| Aspect | Value |
|---|---|
| Default format | `json` |
| Formats that work | `json`, `text`, `compact` (P01, P06, P07) |
| Formats that error | `sarif`, `dot` (P05, P08: exit 1) |
| Typical output size | tiny (~11 lines pretty JSON for cold; ~4 lines for background/daemon-route) |

**THREE DISTINCT OUTPUT SCHEMAS based on run mode:**

### Cold mode (no daemon, no --background — P01, P02):
```json
{
  "status": "ok",
  "files": <N>,
  "edges": <N>,
  "languages": ["python", "typescript", ...],
  "cache_path": ".tldr/cache/call_graph.json"
}
```

### `--background` mode (P09):
```json
{ "status": "ok", "message": "Warming cache in background..." }
```
Spawns a child process and returns immediately.

### Daemon-route mode (daemon running — P11):
```json
{ "status": "ok", "message": "Warmed: call_graph, structure, file_tree, semantic_index" }
```
**WARMS FOUR CACHES, not just call graph** — uses the daemon's broader warmup capability.

**Empty-result shape (P15 empty dir):**
```json
{ "status": "ok", "files": 0, "edges": 0, "languages": ["unknown"], "cache_path": ".tldr/cache/call_graph.json" }
```
Exit 0. **`languages: ["unknown"]`** sentinel for empty/unrecognized dirs.

**Error shapes:**
- Bad path (e.g., `/no/such/dir`): `"Error: Read-only file system (os error 30)"` → exit **1** (BIZARRE — canonicalize fallback leads to write attempt on `/`)
- Non-source single file: `"Error: Not a directory (os error 20)"` → exit **1** (raw OS error — same anti-pattern as `tldr resources`/`tldr taint`)
- File as PATH: same as non-source — `"Error: Not a directory (os error 20)"` exit **1**
- Format reject: `"Error: --format sarif not supported by warm. ..."` → exit **1**
- Bad `--lang`: clap-style → exit **2**

---

## Probe Matrix

| # | Probe | Type | Exit | Captured |
|---|-------|------|------|----------|
| P01 | `tldr warm` | happy (cold, root) — 866 files, 38383 edges, 3 langs | 0 | [`01-happy.*`](./warm.probes/) |
| P02 | `tldr warm backend` | happy-scale (Python-only subset) | 0 | [`02-happy-scale.*`](./warm.probes/) |
| P03 | N/A: PATH defaults to `.`. | — | — | [`03-missing-arg.*`](./warm.probes/) (placeholder) |
| P04 | `tldr warm /no/such/dir` | bad-path (BIZARRE "Read-only fs" error) | 1 | [`04-badpath.*`](./warm.probes/) |
| P05 | `tldr warm -f sarif` | format-reject (sarif) | 1 | [`05-format-reject-sarif.*`](./warm.probes/) |
| P06 | `tldr warm -f text` | format-text | 0 | [`06-format-text.*`](./warm.probes/) |
| P07 | `tldr warm -f compact` | format-compact | 0 | [`07-format-compact.*`](./warm.probes/) |
| P08 | `tldr warm -f dot` | format-reject (dot) | 1 | [`08-format-reject-dot.*`](./warm.probes/) |
| P09 | `tldr warm --background` | background mode (different schema!) | 0 | [`09-background.*`](./warm.probes/) |
| P10 | `tldr warm -b` | -b shorthand for --background | 0 | [`10-background-short.*`](./warm.probes/) |
| P11 | `tldr warm` *(daemon running)* | **DAEMON ROUTE: warms 4 caches!** | 0 | [`11-warm-with-daemon.*`](./warm.probes/) |
| P12 | `tldr warm -l brainfuck` | bad-lang | 2 | [`12-bad-lang.*`](./warm.probes/) |
| P13 | `tldr warm -l python backend/providers` | explicit python | 0 | [`13-lang-python.*`](./warm.probes/) |
| P14 | `tldr warm -l typescript backend/providers` | lang-mismatch (silent, same schema) | 0 | [`14-lang-mismatch.*`](./warm.probes/) |
| P15 | `tldr warm <empty-tmp-dir>` | empty dir (languages: ["unknown"]) | 0 | [`15-empty-dir.*`](./warm.probes/) |
| P16 | `tldr warm README.md` | non-source-md (raw "Not a directory" OS error) | 1 | [`16-non-source-md.*`](./warm.probes/) |
| P17 | `tldr warm <file>` | file as PATH (raw OS error) | 1 | [`17-file-as-path.*`](./warm.probes/) |
| P18 | `tldr warm -q backend/providers` | quiet | 0 | [`18-quiet.*`](./warm.probes/) |

### Observations

- **P01** — Cold warm at Stock-Monitor root: `files: 866, edges: 38383, languages: ["javascript", "python", "typescript"], cache_path: ".tldr/cache/call_graph.json"`. Exit 0. Builds the full call graph index. **PERFORMANCE:** ~10-15s on Stock-Monitor.
- **P02** — `tldr warm backend`: `files: 56, edges: 9116, languages: ["python"]`. Scoped to backend (Python only).
- **P03** — **N/A.** PATH defaults to `.`.
- **P04** — **BIZARRE ERROR:** `tldr warm /no/such/dir` → stderr `"Error: Read-only file system (os error 30)"`, exit `1`. **Source-comment note (warm.rs:110-115):** when path canonicalize fails, falls back to `cwd().join(self.path)`, which may resolve to a write-attempt at `/` (read-only). **Recovery hint:** verify PATH exists externally — the error is misleading.
- **P05** — stderr `"Error: --format sarif not supported by warm. Use --format json. SARIF is only emitted by: vuln, clones."`, exit `1`.
- **P06** — Text format: 4 lines: `"Warming call graph cache...\nIndexed 866 files, found 38383 edges\nLanguages: javascript, python, typescript\nCache written to: .tldr/cache/call_graph.json"`.
- **P07** — Single-line minified JSON.
- **P08** — stderr `"Error: --format dot not supported by warm. ..."`, exit `1`.
- **P09** — **DIFFERENT SCHEMA:** `--background` returns `{ status: "ok", message: "Warming cache in background..." }`. Spawns subprocess; CLI returns immediately. No `files`/`edges` reported.
- **P10** — `-b` shorthand: identical to P09.
- **P11** — **DAEMON ROUTE: warms 4 caches!** When daemon is running, warm goes through IPC: `{ status: "ok", message: "Warmed: call_graph, structure, file_tree, semantic_index" }`. **Daemon-route warms FOUR caches, not just call_graph** — broader warmup. Use this pattern: `tldr daemon start && tldr warm` to populate all caches.
- **P12** — clap-style: `"error: invalid value 'brainfuck' for '--lang <LANG>': Unknown language: brainfuck"`, exit `2`.
- **P13** — `-l python backend/providers`: scopes warming to Python files. `files: 4, edges: <N>, languages: ["python"]`.
- **P14** — `-l typescript backend/providers` on Python project: 9 lines, SAME shape as default — `--lang` filter doesn't seem to change behavior for warm. Or it might filter; need verification on richer multi-lang dirs.
- **P15** — Empty dir: `{ status: "ok", files: 0, edges: 0, languages: ["unknown"], cache_path: ".tldr/cache/call_graph.json" }`. **`languages: ["unknown"]`** sentinel for empty/unrecognized.
- **P16** — README.md as PATH: stderr `"Error: Not a directory (os error 20)"`, exit `1`. **Raw OS error** — same anti-pattern as `tldr resources` P23/`tldr taint` P20.
- **P17** — File as PATH: same shape as P16. Both single-file and non-source-file failures produce the raw stdlib error.
- **P18** — `-q quiet`: same 9-line JSON output (NOT silent — warm's "real" output is the cache stats).

---

## Source Code Reality

**Target file(s):**
- `crates/tldr-cli/src/commands/daemon/warm.rs` (~300+ lines)
- `crates/tldr-core/src/...` (call graph builder reused by other commands)
- `crates/tldr-cli/src/output.rs:113` (`validate_format_for_command`)

**Pinned to upstream commit:** `6c4011a` (release v0.4.0)

**Argument struct:**
```rust
// crates/tldr-cli/src/commands/daemon/warm.rs:49-58
#[derive(Debug, Clone, Args)]
pub struct WarmArgs {
    #[arg(default_value = ".")] pub path: PathBuf,
    #[arg(long, short = 'b')] pub background: bool,
}
```
Reveals: minimal struct. PATH (default `.`) + `--background -b`. `--lang` is global. No `--force` or `--clear-existing` — warm always appends to or rewrites the cache.

**Three execution paths (source comment at warm.rs:117+):**
```rust
if self.background {
    self.run_background(&project, format, quiet).await
} else {
    if check_socket_alive(&project).await {
        self.run_via_daemon(&project, format, quiet).await
    } else {
        self.run_in_process(&project, format, quiet).await
    }
}
```
Reveals: priority is `--background` > daemon-running > in-process. Three distinct schemas confirmed.

**Bad-path canonicalize fallback (P04 root cause):**
```rust
// warm.rs:110-115
let project = self.path.canonicalize().unwrap_or_else(|_| {
    std::env::current_dir()
        .unwrap_or_else(|_| PathBuf::from("."))
        .join(&self.path)
});
```
Reveals: when canonicalize fails (bad path), falls back to `cwd().join(self.path)`. For `/no/such/dir`, the join becomes `/no/such/dir` (absolute → cwd ignored), then the engine tries to write `.tldr/cache/...` relative to `/` which is read-only. **Misleading error chain.**

**Format validation:** confirmed at `crates/tldr-cli/src/output.rs:113-163` — `warm` is in neither `SARIF_SUPPORTED` nor `DOT_SUPPORTED`.

**No `try_daemon_route`:** but warm has its OWN daemon-route logic (`check_socket_alive` + `run_via_daemon`). Different mechanism from the standard `try_daemon_route` used by analysis commands.

---

## Architectural Deep Dive

- **Under the hood:** Three modes:
  1. **In-process (cold):** Walks the project tree, builds call graph (function → function edges), writes to `.tldr/cache/call_graph.json`.
  2. **--background:** Forks a subprocess that runs in-process logic; returns immediately.
  3. **Daemon-running:** Sends IPC `WarmCommand` to the daemon, which builds the call graph AND warms 3 additional caches (structure, file_tree, semantic_index).
- **Performance:** Cold ~10-15s on Stock-Monitor (866 files). Background returns instantly. Daemon mode similar to cold but populates more caches.
- **LLM cognitive load:** **The canonical "prep step" before running multiple tldr queries.** Pair: `tldr daemon start && tldr warm` populates ALL caches; subsequent `tldr search`/`semantic`/etc. are 10-100× faster. Without warm, the first query is slow (cold) and subsequent queries vary.

---

## Intent & Routing

- **User/Agent Goal:** populate the call graph cache (and optionally other caches via daemon) BEFORE running analysis queries, for predictable fast subsequent operations.
- **When to choose this over similar tools:**
  - Before running multiple analyses: `tldr daemon start && tldr warm` warms 4 caches.
  - For CI pre-step: `tldr warm --background` to pre-build cache while other CI steps run.
  - For single one-shot queries: skip warm; the underlying commands cold-build their own caches as needed.
- **Prerequisites (composition):**
  - PATH must be a directory (P16/P17 reject single files with raw OS error).
  - For full multi-cache warming, start daemon first (`tldr daemon start && tldr warm`).
  - For CI: use `--background` to overlap with other prep steps.

---

## Agent Synthesis

> **How to use `tldr warm`:**
> Call-graph cache pre-warmer. `tldr warm [PATH]` returns JSON in one of THREE schemas based on mode: **Cold** (no daemon): `{ status, files, edges, languages, cache_path }`. **`--background`**: `{ status, message: "Warming cache in background..." }` and spawns subprocess. **Daemon-running**: `{ status, message: "Warmed: call_graph, structure, file_tree, semantic_index" }` — IPC route that warms FOUR caches, not just call_graph! Default JSON; `-f text` for human display; `-f compact` for one-line; `sarif`/`dot` rejected. Exit codes: 0 ok, 1 path-not-found (BIZARRE "Read-only file system" error) / single-file / format-reject, 2 bad-lang.
>
> **Crucial Rules:**
> - **THREE DISTINCT OUTPUT SCHEMAS based on run mode.** Cold (full WarmOutput with files/edges/languages/cache_path); `--background` (just `{ status, message }`); daemon-running (IPC route, `{ status, message: "Warmed: ..." }`). **Agents schema-validating must branch on mode.**
> - **DAEMON ROUTE WARMS 4 CACHES** (P11): not just call_graph. The IPC `WarmCommand` populates `call_graph, structure, file_tree, semantic_index`. **For maximum warming, start daemon first:** `tldr daemon start && tldr warm`. Without daemon, only call_graph is warmed.
> - **BAD PATH PRODUCES BIZARRE "READ-ONLY FILE SYSTEM" ERROR** (P04). Source root cause (warm.rs:110-115): canonicalize fallback → `cwd().join(bad-absolute-path)` → engine tries to write `.tldr/cache/...` relative to `/` (which is RO). **Misleading error chain — verify PATH exists externally before invoking warm.**
> - **PATH MUST BE A DIRECTORY** (P16, P17). Single files / non-source files produce raw stdlib `"Not a directory (os error 20)"`. Same anti-pattern as `tldr resources`/`tldr taint`.
> - **`languages: ["unknown"]` sentinel** for empty / unrecognized-language dirs (P15). NOT an error — just an explicit "couldn't detect any supported language."
> - **`--background` returns IMMEDIATELY** (P09): the subprocess does the work async. Use for CI overlap with other steps. **Side effect:** if the subprocess fails, the caller never knows — there's no follow-up status check via `tldr warm`.
> - **`-q quiet` does NOT silence output** (P18: same 9 lines). Warm's "real" output is the cache stats, not progress.
> - **NO `--force` flag.** Warm always rebuilds — there's no explicit "use existing cache" option. To clear: use `tldr daemon stop && rm -rf .tldr/cache && tldr warm`.
> - **`cache_path` is RELATIVE** (`.tldr/cache/call_graph.json`). Resolved against PATH.
> - **Three execution paths use distinct schemas** but ALL emit `"status": "ok"` as the first field. Agents detecting success can use `.status == "ok"` consistently.
>
> **Command:** `tldr warm [PATH]` — or `tldr daemon start && tldr warm` for full multi-cache warming.
>
> **With common flags:** `tldr daemon start && tldr warm && tldr search <query>` (canonical workflow: warm daemon-backed caches once, then run many fast queries).
