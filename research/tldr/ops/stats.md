# Command: `tldr stats`

## Environment Pin

| Field | Value |
|---|---|
| `tldr --version` | 0.4.0 |
| Build features | `semantic` (verified; stats is JSONL aggregator, non-semantic) |
| Target repo | N/A — stats reads `~/.tldr/stats.jsonl` (global, project-independent) |
| Upstream `tldr-code` pinned to | local clone @ `6c4011a` (release v0.4.0) |
| Daemon state at probe time | inactive (stats file empty — daemon never recorded) |
| OS | darwin 25.2.0 |
| Probe date | 2026-05-22 |

Re-run all evidence via [`stats.probes/probe.sh`](./stats.probes/probe.sh).
See also: [agent-oriented tool card](../../tool-cards/ops/stats.md).

---

## Ground Truth (`tldr stats --help`)

```text
Show TLDR usage statistics

Usage: tldr stats [OPTIONS]

Options:
  -f, --format <FORMAT>            [default: json]
  -l, --lang <LANG>
  -q, --quiet  -v, --verbose  -h, --help
```

**No positional args, no command-specific flags.** Reads `~/.tldr/stats.jsonl` (created by the daemon when commands are invoked) and aggregates totals.

---

## Output Shape

| Aspect | Value |
|---|---|
| Default format | `json` |
| Formats that work | `json`, `text` (P01, P06) |
| Format **bug** | **`-f compact` returns pretty JSON byte-identical to default** (P07: 372 bytes both) |
| Formats that error | `sarif`, `dot` (P05, P08: exit 1) |
| Typical output size | small (~12 lines pretty JSON for empty stats; populated stats would be ~6 lines) |

**Top-level keys (JSON) — DIFFERS based on stats presence:**

### Populated stats (per source `StatsOutput`):
```json
{
  "total_invocations": 1500,
  "estimated_tokens_saved": 4500000,
  "raw_tokens_total": 5000000,
  "tldr_tokens_total": 500000,
  "savings_percent": 90.0
}
```

### Empty stats (P01 observed, per source `low-cleanup-bundle-v1 L2` fix):
```json
{
  "message": "No usage recorded yet",
  "next_steps": [
    "tldr daemon start  # begin recording usage",
    "tldr <any-command> ...  # run a few commands while the daemon is up",
    "tldr stats  # rerun this command to see call counts and latencies"
  ],
  "requires": [
    "tldr daemon (run `tldr daemon start`)",
    "at least one daemon-tracked invocation"
  ]
}
```
**Best-in-class empty-result UX** — explicit `next_steps` and `requires` arrays per source comment fix.

**Text format for empty (P06):**
```text
No usage recorded yet

Usage tracking requires the tldr daemon. To begin recording:
  $ tldr daemon start  # begin recording usage
  $ tldr <any-command> ...  # run a few commands while the daemon is up
  $ tldr stats  # rerun this command to see call counts and latencies

Once the daemon has captured invocations, this command will display call counts, latencies, and most-used commands.
```

**Error shapes:**
- Format reject sarif: `"Error: --format sarif not supported by stats. ..."` → exit **1**
- Bad `--lang`: clap-style → exit **2**
- Extra positional: clap-style `"error: unexpected argument 'extra-positional' found"` → exit **2**

---

## Probe Matrix

| # | Probe | Type | Exit | Captured |
|---|-------|------|------|----------|
| P01 | `tldr stats` | happy (empty stats — best-in-class message) | 0 | [`01-happy.*`](./stats.probes/) |
| P02 | `tldr stats -f text` | happy-scale (text mode) | 0 | [`02-happy-scale.*`](./stats.probes/) |
| P03 | N/A: no required args. | — | — | [`03-missing-arg.*`](./stats.probes/) (placeholder) |
| P04 | N/A: no PATH arg. | — | — | [`04-badpath.*`](./stats.probes/) (placeholder) |
| P05 | `tldr stats -f sarif` | format-reject (sarif) | 1 | [`05-format-reject-sarif.*`](./stats.probes/) |
| P06 | `tldr stats -f text` | format-text | 0 | [`06-format-text.*`](./stats.probes/) |
| P07 | `tldr stats -f compact` | **format-compact BROKEN (pretty JSON)** | 0 | [`07-format-compact.*`](./stats.probes/) |
| P08 | `tldr stats -f dot` | format-reject (dot) | 1 | [`08-format-reject-dot.*`](./stats.probes/) |
| P09 | `tldr stats -f json` | explicit json | 0 | [`09-format-json.*`](./stats.probes/) |
| P10 | `tldr stats -l brainfuck` | bad-lang | 2 | [`10-bad-lang.*`](./stats.probes/) |
| P11 | `tldr stats -l python` | -l IGNORED (stats is lang-agnostic) | 0 | [`11-lang-python.*`](./stats.probes/) |
| P12 | `tldr stats -q` | quiet (NOT silent — same output) | 0 | [`12-quiet.*`](./stats.probes/) |
| P13 | `tldr stats -v` | verbose (no observable diff in empty case) | 0 | [`13-verbose.*`](./stats.probes/) |
| P14 | `cd <tmp> && tldr stats` | CWD-independent | 0 | [`14-from-tmp.*`](./stats.probes/) |
| P15 | `tldr stats extra-positional` | unexpected positional | 2 | [`15-extra-arg.*`](./stats.probes/) |

### Observations

- **P01** — `tldr stats` (empty stats): returns the empty-result message with `next_steps[]` and `requires[]` arrays. **Best UX in the audit suite for empty state** — explicit guidance on what to do per source `low-cleanup-bundle-v1 L2` fix.
- **P02** — `-f text` (same as P06): 8-line human-readable instructional message.
- **P03** — **N/A.** No required args.
- **P04** — **N/A.** No PATH arg.
- **P05** — stderr `"Error: --format sarif not supported by stats. Use --format json. SARIF is only emitted by: vuln, clones."`, exit `1`.
- **P06** — Text format: 8 lines instructional. Same as P02.
- **P07** — **`-f compact` IS BROKEN:** byte-identical to default JSON (372 bytes both). Single-line minified output is NOT produced. Same bug class as `tldr resources`/`tldr taint`/`tldr temporal`/`tldr diff`. Workaround: `jq -c`.
- **P08** — stderr `"Error: --format dot not supported by stats. ..."`, exit `1`.
- **P09** — Explicit `-f json`: identical to P01 default.
- **P10** — clap-style: `"error: invalid value 'brainfuck' for '--lang <LANG>': Unknown language: brainfuck"`, exit `2`.
- **P11** — `-l python`: same output as default. **`--lang` IGNORED** for stats (which is lang-agnostic — it counts invocations, not parses code).
- **P12** — `-q quiet`: same 12 lines as default. NOT silent.
- **P13** — `-v verbose`: same output as default. No observable diff in empty-stats case.
- **P14** — Run from `/tmp/...`: identical output. **Stats is CWD-independent** — reads `~/.tldr/stats.jsonl` regardless of working directory.
- **P15** — clap-style: `"error: unexpected argument 'extra-positional' found"`, exit `2`. Stats accepts NO positional arg.

---

## Source Code Reality

**Target file(s):**
- `crates/tldr-cli/src/commands/daemon/stats.rs` (~200+ lines)
- `~/.tldr/stats.jsonl` (runtime data file written by daemon)
- `crates/tldr-cli/src/output.rs:113` (`validate_format_for_command`)

**Pinned to upstream commit:** `6c4011a` (release v0.4.0)

**Argument struct:**
```rust
// crates/tldr-cli/src/commands/daemon/stats.rs:45-48
#[derive(Debug, Clone, Args)]
pub struct StatsArgs {
    // Stats command uses the global --format flag, no local format arg needed
}
```
Reveals: **ZERO local fields!** All flags are global. Even simpler than `tldr doctor`.

**Empty-message shape (per source `low-cleanup-bundle-v1 L2`):**
```rust
// stats.rs:93-100 (source comment)
/// low-cleanup-bundle-v1 (L2): the previous shape `{"message": "No usage
/// recorded"}` was opaque — users had no idea what "usage" meant or how to
/// produce it. We now include a `next_steps` hint that names the daemon and
/// the exact command to run, plus a `requires` field listing prerequisites
/// for programmatic consumers.
```
Reveals: explicit premortem-driven fix. The previous opaque `{"message": "..."}` was replaced with the actionable structure (P01).

**Populated stats schema (per source doc-comment, not directly probed):**
```rust
// stats.rs:74-91
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct StatsOutput {
    pub total_invocations: u64,
    pub estimated_tokens_saved: i64,
    pub raw_tokens_total: u64,
    pub tldr_tokens_total: u64,
    pub savings_percent: f64,
}
```
Reveals: 5-field tokens-saved schema. To populate, need to: (1) start the daemon, (2) run commands while daemon is up — the daemon writes JSONL entries to `~/.tldr/stats.jsonl`. We didn't probe a populated state (would require running many commands first).

**Stats source:**
- Reads `~/.tldr/stats.jsonl` line-by-line (one `StatsEntry` per line)
- Aggregates `raw_tokens`, `tldr_tokens`, `requests` across all entries
- Computes `estimated_tokens_saved = raw_tokens_total - tldr_tokens_total`
- Computes `savings_percent = (saved / raw_tokens_total) * 100`

**Format validation:** confirmed at `crates/tldr-cli/src/output.rs:113-163` — `stats` is in neither `SARIF_SUPPORTED` nor `DOT_SUPPORTED`.

**No daemon route:** `grep -n try_daemon_route stats.rs` returns 0 matches. Stats READS from a file the daemon writes; doesn't query the daemon directly.

---

## Architectural Deep Dive

- **Under the hood:** Read `~/.tldr/stats.jsonl` (file written by the daemon when commands are invoked). Aggregate per-session metrics. Emit either populated stats (5 fields) or empty-message with `next_steps` + `requires` hints.
- **Performance:** Fast (~10ms — file read + JSON parse).
- **LLM cognitive load:** Self-monitoring command. Useful for "how much did tldr save me this session?" reflection. Per `low-cleanup-bundle-v1 L2` fix, the empty case is now self-documenting — agents seeing empty stats can follow `next_steps` to populate.

---

## Intent & Routing

- **User/Agent Goal:** view aggregate TLDR usage statistics across all sessions — token savings, invocation counts.
- **When to choose this over similar tools:**
  - Over `tldr daemon status`: status is per-daemon-instance; stats is historical aggregate across sessions.
  - Over `tldr cache stats`: cache stats is disk/Salsa cache; stats is token-savings metrics.
- **Prerequisites (composition):**
  - The daemon must have run and recorded invocations to populate `~/.tldr/stats.jsonl`.
  - Empty case is graceful: `tldr stats` self-documents with `next_steps`.

---

## Agent Synthesis

> **How to use `tldr stats`:**
> Self-monitoring summary. `tldr stats` reads `~/.tldr/stats.jsonl` (written by daemon) and returns aggregate metrics. **Two output shapes:** populated stats `{ total_invocations, estimated_tokens_saved, raw_tokens_total, tldr_tokens_total, savings_percent }` (5 fields); empty-message `{ message, next_steps, requires }` when no stats recorded. Default JSON; `-f text` for human-readable; **`-f compact` BROKEN (returns pretty JSON)**; `sarif`/`dot` rejected. Exit codes: 0 ok (incl. empty), 1 format-reject, 2 bad-lang / extra positional.
>
> **Crucial Rules:**
> - **TWO DISTINCT SCHEMAS** based on stats presence. Empty case: `{ message, next_steps, requires }`. Populated case: `{ total_invocations, estimated_tokens_saved, raw_tokens_total, tldr_tokens_total, savings_percent }`. Agents schema-validating output must detect by checking for `message` field OR for `total_invocations`.
> - **Empty-message includes `next_steps` and `requires` arrays** (P01, per source `low-cleanup-bundle-v1 L2` premortem-driven fix). Best-in-class actionable empty-state UX in the audit suite. The previous opaque `{"message": "No usage recorded"}` was replaced.
> - **`-f compact` IS BROKEN** (P07: byte-identical to default pretty JSON, 372 bytes both). Same bug class as `tldr resources`/`taint`/`temporal`/`diff`. Workaround: `jq -c`.
> - **STATS IS CWD-INDEPENDENT** (P14). Reads `~/.tldr/stats.jsonl` regardless of where it's invoked from. Run from anywhere — no project context needed.
> - **`--lang <X>` is IGNORED** (P11: same output). Stats is language-agnostic.
> - **`-q quiet` does NOT silence output** (P12: same 12 lines as default). Stats's "real" output is the data itself, not progress.
> - **`StatsArgs` has ZERO local fields** (source: `StatsArgs {}`). All flags are global. Simpler arg struct than any other command.
> - **NO positional args** (P15: extra positional → clap exit 2 `"unexpected argument"`).
> - **POPULATION requires the daemon.** `next_steps` literally says `"tldr daemon start"` then run commands. Without daemon, stats stays empty forever.
> - **NO daemon route.** Stats reads a FILE — doesn't query the daemon process.
>
> **Command:** `tldr stats`
>
> **With common flags:** `tldr stats -f json | jq '.savings_percent // "no stats yet"'` (use for self-monitoring dashboards: emit savings percent if populated, fallback string if empty).
