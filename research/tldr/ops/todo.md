# Command: `tldr todo`

## Environment Pin

| Field | Value |
|---|---|
| `tldr --version` | 0.4.0 |
| Build features | `semantic` (verified; todo orchestrates dead/complexity/cohesion/similar sub-analyses, non-semantic) |
| Target repo | Stock-Monitor @ commit `e601869` |
| Upstream `tldr-code` pinned to | local clone @ `6c4011a` (release v0.4.0) |
| Daemon state at probe time | N/A — `tldr todo` does **not** call `try_daemon_route` (verified by grep) |
| OS | darwin 25.2.0 |
| Probe date | 2026-05-22 |
| Scoping decision | All probes used `--quick` mode to skip the expensive similar-analysis |

Re-run all evidence via [`todo.probes/probe.sh`](./todo.probes/probe.sh).
See also: [agent-oriented tool card](../../tool-cards/ops/todo.md).

---

## Ground Truth (`tldr todo --help`)

```text
Aggregate improvement suggestions (dead code, complexity, cohesion, similar)

Usage: tldr todo [OPTIONS] <PATH>

Arguments:
  <PATH>                                       File or directory to analyze

Options:
      --detail <DETAIL>                        Show details for specific sub-analysis
      --quick                                  Skip similar analysis
      --max-items <MAX_ITEMS>                  [default: 20] (0 = show all)
  -O, --output <OUTPUT>                        Output file
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
| Typical output size | small (~41 lines pretty JSON for 4-file dir with --quick; ~194 lines for full backend) |

**Top-level keys (JSON, `TodoReport`):**
- `wrapper` (`string`) — always `"todo"`
- `path` (`string`) — input PATH (may be relative or canonical)
- `items` (`array<TodoItem>`) — aggregated improvement suggestions
- `summary` (`object`) — `{ dead_count, similar_pairs, low_cohesion_count, hotspot_count, equivalence_groups }`
- `total_elapsed_ms` (`f64`)

**`TodoItem` shape:**
- `category` (`string`) — observed: `"complexity"`, `"cohesion"`. Likely also: `"dead"`, `"similar"`.
- `priority` (`u32`) — observed `2` (complexity) and `3` (cohesion). Lower = higher priority? Or scale 1-5?
- `description` (`string`) — human-readable suggestion (e.g., `"High complexity in DhanProvider.fetch_intraday_chart: cyclomatic=12, consider refactoring"`)
- `file` (`string`) — project-relative path
- `line` (`u32`)
- `severity` (`string`) — `"medium"`, `"high"` observed (likely also `"low"`, `"critical"`)
- `score` (`float64`, 0.0–1.0) — actionability score

**Empty-result shape (P19 empty dir, P18 lang mismatch):**
```json
{
  "wrapper": "todo", "path": "<input>", "items": [],
  "summary": { "dead_count": 0, "similar_pairs": 0, "low_cohesion_count": 0, "hotspot_count": 0, "equivalence_groups": 0 },
  "total_elapsed_ms": 2.22
}
```
Exit 0.

**Error shapes:**
- Missing PATH: clap-style → exit **2**
- File not found: `"Error: file not found: /no/such/dir"` → exit **5** (RemainingError::FileNotFound — matches `tldr secure`/`tldr vuln`/`tldr dead-stores`/`tldr diff`)
- Non-source single file: `"Error: unsupported language: md"` → exit **1** (extension-only wording — matches `tldr patterns`/`tldr resources`)
- Format reject sarif: `"Error: --format sarif not supported by todo. ..."` → exit **1**
- Bad `--lang`: clap-style → exit **2**

---

## Probe Matrix

| # | Probe | Type | Exit | Captured |
|---|-------|------|------|----------|
| P01 | `tldr todo backend/providers --quick` | happy | 0 | [`01-happy.*`](./todo.probes/) |
| P02 | `tldr todo backend --quick` | happy-scale | 0 | [`02-happy-scale.*`](./todo.probes/) |
| P03 | `tldr todo` *(no PATH)* | failure-missing-input | 2 | [`03-missing-arg.*`](./todo.probes/) |
| P04 | `tldr todo /no/such/dir` | failure-badpath | 5 | [`04-badpath.*`](./todo.probes/) |
| P05 | `tldr todo ... -f sarif` | format-reject (sarif) | 1 | [`05-format-reject-sarif.*`](./todo.probes/) |
| P06 | `tldr todo ... -f text` | format-text | 0 | [`06-format-text.*`](./todo.probes/) |
| P07 | `tldr todo ... -f compact` | format-compact | 0 | [`07-format-compact.*`](./todo.probes/) |
| P08 | `tldr todo ... -f dot` | format-reject (dot) | 1 | [`08-format-reject-dot.*`](./todo.probes/) |
| P09 | `tldr todo ... --quick` | quick mode | 0 | [`09-quick.*`](./todo.probes/) |
| P10 | `tldr todo ... --detail dead` | detail-dead (adds dead-code block) | 0 | [`10-detail-dead.*`](./todo.probes/) |
| P11 | `tldr todo ... --detail complexity` | detail-complexity (adds complexity block) | 0 | [`11-detail-complexity.*`](./todo.probes/) |
| P12 | `tldr todo ... --detail wat` | bogus --detail (silent ignore) | 0 | [`12-detail-bogus.*`](./todo.probes/) |
| P13 | `tldr todo ... --max-items 1` | max-items 1 | 0 | [`13-max-items-low.*`](./todo.probes/) |
| P14 | `tldr todo ... --max-items 0` | max-items 0 = SHOW ALL (per --help) | 0 | [`14-max-items-zero.*`](./todo.probes/) |
| P15 | `tldr todo ... -O <tmp>` | output-to-file | 0 | [`15-output-file.*`](./todo.probes/) |
| P16 | `tldr todo ... -l brainfuck` | bad-lang | 2 | [`16-bad-lang.*`](./todo.probes/) |
| P17 | `tldr todo ... -l python` | explicit python | 0 | [`17-lang-python.*`](./todo.probes/) |
| P18 | `tldr todo ... -l typescript` | lang-mismatch (silent empty) | 0 | [`18-lang-mismatch.*`](./todo.probes/) |
| P19 | `tldr todo <empty-tmp-dir> --quick` | empty-dir | 0 | [`19-empty-dir.*`](./todo.probes/) |
| P20 | `tldr todo <file> --quick` | single file | 0 | [`20-single-file.*`](./todo.probes/) |
| P21 | `tldr todo README.md --quick` | non-source-md (exit 1) | 1 | [`21-non-source-md.*`](./todo.probes/) |
| P22 | `tldr todo ... -q` | quiet | 0 | [`22-quiet.*`](./todo.probes/) |

### Observations

- **P01** — `backend/providers/ --quick`: 3 items: 1 complexity (`fetch_intraday_chart` cyclomatic=12, severity: medium, score: 0.24) + 2 cohesion (DhanProvider, YahooProvider both LCOM4=5, severity: high, score: 1.0). `summary: { low_cohesion_count: 2, hotspot_count: 1 }`. Total elapsed 39.7ms.
- **P02** — Full backend with --quick: 194 lines. Many more items detected.
- **P03** — stderr `"error: the following required arguments were not provided: <PATH>"`, exit `2`.
- **P04** — stderr `"Error: file not found: /no/such/dir"`, exit **5** (RemainingError::FileNotFound). Matches `tldr secure`/`tldr vuln`/`tldr dead-stores`/`tldr diff`. Lowercase "file".
- **P05** — stderr `"Error: --format sarif not supported by todo. ..."`, exit `1`.
- **P06** — Text format: 23 lines, human-readable improvement-list summary.
- **P07** — Single-line minified JSON.
- **P08** — stderr `"Error: --format dot not supported by todo. ..."`, exit `1`.
- **P09** — `--quick` (already used in baseline): identical to P01.
- **P10** — `--detail dead`: 65 lines — adds a detail block for the dead-code sub-analysis (no dead code found in this scope).
- **P11** — `--detail complexity`: 259 lines — adds detailed complexity block with per-function metrics.
- **P12** — **`--detail wat` SILENTLY IGNORED:** exit 0 with same output as default (P01). The flag is `Option<String>` (no clap value_parser), so any value passes through and the engine ignores unknown detail names. Same anti-pattern as `tldr secure --detail`/`tldr verify --detail`.
- **P13** — `--max-items 1`: 23 lines — limits items[] to 1. Summary still shows total counts (3 cohesion+complexity items detected, but only 1 displayed).
- **P14** — `--max-items 0`: same as P01 (41 lines, all 3 items shown). **`0 = show all` HONORED per `--help`** — distinct from `tldr contracts --limit 0`/`tldr patterns --max-files 0`/`tldr surface --limit 0` which all mean "literally zero." Cross-command convention divergence — todo follows the `tldr cognitive --top 0` "all" convention.
- **P15** — `-O <tmp>` writes JSON to file; stdout EMPTY. Same pattern as `tldr vuln -O`/`tldr secure -o`. **Capital `-O`** short flag.
- **P16** — clap-style: `"error: invalid value 'brainfuck' for '--lang <LANG>': Unknown language: brainfuck"`, exit `2`.
- **P17** — Explicit `-l python`: identical to P01.
- **P18** — **SILENT LANG MISMATCH:** `-l typescript` on Python project: empty items, `summary: all_zeros`. Indistinguishable from empty-dir P19. NO warning.
- **P19** — Empty dir: same shape as P18.
- **P20** — Single Python file: 23 lines, smaller list.
- **P21** — **README.md** as PATH: stderr `"Error: unsupported language: md"`, exit `1`. **Extension-only error message** — matches `tldr patterns` and `tldr resources`. Distinct from `tldr loc`'s exit 11 with full path.
- **P22** — `-q quiet`: suppresses `"Analyzing <path> for improvements..."` progress.

---

## Source Code Reality

**Target file(s):**
- `crates/tldr-cli/src/commands/remaining/todo.rs` (~600+ lines)
- `crates/tldr-core/src/wrappers/todo.rs` (orchestrator)
- `crates/tldr-cli/src/output.rs:113` (`validate_format_for_command`)

**Pinned to upstream commit:** `6c4011a` (release v0.4.0)

**Argument struct:**
```rust
// crates/tldr-cli/src/commands/remaining/todo.rs:138-158
#[derive(Debug, Args)]
pub struct TodoArgs {
    pub path: PathBuf,
    #[arg(long)] pub detail: Option<String>,
    #[arg(long)] pub quick: bool,
    #[arg(long, default_value = "20")] pub max_items: usize,
    #[arg(long, short = 'O')] pub output: Option<PathBuf>,
}
```
Reveals: `--detail` is `Option<String>` (no clap value_parser) — silently accepts any value (P12). `--max-items` default `20` (NOT 1000 like patterns). `-O` (capital) for `--output`.

**Path validation:**
```rust
// todo.rs:177-179
if !self.path.exists() {
    return Err(RemainingError::file_not_found(&self.path).into());
}
```
Reveals: RemainingError → exit 5. Lowercase "file not found:" message.

**Sub-analyses orchestrated (per source error references at lines 329/377/419):**
- Dead-code analysis
- Complexity analysis
- Cohesion analysis
- Similar analysis (skipped with `--quick`)

Each errors map to `RemainingError::analysis_error(...)` if their sub-engine fails.

**Format validation:** confirmed at `crates/tldr-cli/src/output.rs:113-163` — `todo` is in neither `SARIF_SUPPORTED` nor `DOT_SUPPORTED`.

**No daemon route:** `grep -n try_daemon_route remaining/todo.rs` returns 0 matches.

---

## Architectural Deep Dive

- **Under the hood:** Orchestrator running 4 sub-analyses (dead-code, complexity, cohesion, similar) on a shared AST cache. Aggregates results into a single `items[]` list with per-item `score` (0.0-1.0 actionability) and `priority` (integer). `--quick` skips the expensive similar-analysis. `--detail <X>` adds a verbose block for that sub-analysis.
- **Performance:** `--quick` ~40ms on 4-file dir. Without `--quick` similar-analysis can take seconds.
- **LLM cognitive load:** **Best-in-class refactor checklist generator.** Pair this with `tldr hotspots` (churn × complexity priority) for full PR-prep audit. Each `items[].description` is LLM-consumable: include file:line + suggested action. For CI integration: filter `items[] | severity == "critical"` to surface only blocking issues.

---

## Intent & Routing

- **User/Agent Goal:** generate a unified "improvement TODO list" — what should I refactor next?
- **When to choose this over similar tools:**
  - Over `tldr smells`: smells finds INDIVIDUAL anti-patterns; todo aggregates 4 sub-analyses with priority/score.
  - Over `tldr health`: health is a metric SCORE; todo is an ACTION LIST.
  - Over `tldr hotspots`: hotspots is churn-driven; todo is structural.
  - Best: combine `tldr hotspots` (where to start) with `tldr todo <hotspot-file>` (what to do).
- **Prerequisites (composition):**
  - PATH must exist (exit 5 if not).
  - Use `--quick` for fast iteration; omit for full similar-analysis.
  - For non-Python/TS projects, pass `-l <lang>` (autodetect may pick the wrong language on mixed repos).

---

## Agent Synthesis

> **How to use `tldr todo`:**
> Unified refactor-suggestion aggregator. `tldr todo <PATH>` returns JSON `{ wrapper: "todo", path, items: [{ category, priority, description, file, line, severity, score }], summary: { dead_count, similar_pairs, low_cohesion_count, hotspot_count, equivalence_groups }, total_elapsed_ms }`. Default runs all 4 sub-analyses (dead, complexity, cohesion, similar); `--quick` skips similar. Default `--max-items 20` (0 = SHOW ALL — distinct from contracts/patterns/surface where 0 = literal zero!). Default JSON; `-f text` for human display; `-f compact` for one-line; `sarif`/`dot` rejected. `-O <file>` writes to file (stdout empty). Exit codes: 0 ok, 1 format-reject / non-source-file (`-mc unsupported language`), 2 missing PATH / bad-lang, 5 file-not-found.
>
> **Crucial Rules:**
> - **`--max-items 0` MEANS "SHOW ALL"** per `--help` (P14: verified). Cross-command convention divergence — matches `tldr cognitive --top 0`/`tldr coupling --top 0` but DIFFERS from `tldr contracts --limit 0`/`tldr patterns --max-files 0`/`tldr surface --limit 0` (all "literal zero"). For todo: 0 means unlimited.
> - **`--detail <bogus>` is SILENTLY IGNORED** (P12: `--detail wat` returns same output as default). The flag is `Option<String>` (no typed enum) — engine ignores unknown detail names. Same anti-pattern as `tldr secure --detail`/`tldr verify --detail`.
> - **File-not-found exit code is 5** (RemainingError::FileNotFound — matches `tldr secure`/`tldr vuln`/`tldr dead-stores`/`tldr diff`). Lowercase "file not found:".
> - **Non-source single file returns exit 1** with `"unsupported language: md"` (P21). Extension-only message — matches `tldr patterns` and `tldr resources`. Distinct from `tldr loc`'s exit 11.
> - **`-l <lang>` mismatch is SILENT** (P18: `-l typescript` on Python yields empty items + zero summary). Indistinguishable from empty dir P19. Verify PATH externally.
> - **`category` observed values:** `"complexity"`, `"cohesion"`. Per `--help` summary keys also include `"dead"`, `"similar"` (with `equivalence_groups` indicating similar-code groups). Filter `items[] | category == X` for sub-analysis focus.
> - **`severity` observed:** `"medium"`, `"high"`. Likely full scale `"low" | "medium" | "high" | "critical"`.
> - **`priority` is INTEGER** (observed 2 and 3). Sort `items | sort_by(.priority)` for top-priority-first ordering. Lower = higher priority appears to be the convention.
> - **`score` is FLOAT 0.0-1.0** — actionability score. Filter `items[] | score >= 0.5` for high-impact items.
> - **`-O` (capital) for `--output`** — matches `tldr vuln -O`/`tldr secure -O`/`tldr diff -O`/`tldr api-check -O`. When set, stdout is empty.
> - **NO daemon route.** Every call re-runs the 4 sub-analyses.
>
> **Command:** `tldr todo <PATH>`
>
> **With common flags:** `tldr todo <PATH> --quick -f compact | jq '.items | sort_by(.priority) | .[:10]'` (use for CI/code review: top-10 refactor candidates sorted by priority).
