# Command: `tldr hubs`

## Environment Pin

| Field | Value |
|---|---|
| `tldr --version` | 0.4.0 |
| Build features | `semantic` (verified; hubs itself is non-semantic) |
| Target repo | Stock-Monitor @ commit `e601869` |
| Upstream `tldr-code` pinned to | local clone @ `6c4011a` (release v0.4.0) |
| Daemon state at probe time | N/A — `tldr hubs` does **not** call `try_daemon_route` (verified) |
| OS | darwin 25.2.0 |
| Probe date | 2026-05-22 |

Re-run all evidence via [`hubs.probes/probe.sh`](./hubs.probes/probe.sh).
See also: [agent-oriented tool card](../../tool-cards/trace/hubs.md).

---

## Ground Truth (`tldr hubs --help`)

```text
Detect hub functions using centrality analysis

Usage: tldr hubs [OPTIONS] [PATH]

Arguments:
  [PATH]
          Project root directory (default: current directory)

          [default: .]

Options:
      --top <TOP>
          Number of top hubs to return

          [default: 10]

      --algorithm <ALGORITHM>
          Centrality algorithm to use

          Possible values:
          - all:         All algorithms: in_degree, out_degree, pagerank, betweenness
          - indegree:    In-degree only (fast)
          - outdegree:   Out-degree only (fast)
          - pagerank:    PageRank only
          - betweenness: Betweenness only (slow for large graphs)

          [default: all]

      --threshold <THRESHOLD>
          Minimum composite score threshold (0.0-1.0)

  -l, --lang <LANG>
          Programming language (auto-detect if not specified)

  -f, --format <FORMAT>
          Output format

          Supported by every command: json, text, compact.

          Command-specific formats (rejected at runtime by other commands): sarif  — only: vuln, clones dot    — only: calls, impact, hubs, inheritance, clones, deps

          cli-error-clarity-v2 (P2.BUG-5): possible values are hidden on the global help to avoid promising sarif/dot for every subcommand. Run `tldr <cmd> --help` to confirm what a specific command emits, and see `validate_format_for_command` in `output.rs` for the source of truth.

          [default: json]

  -q, --quiet
          Suppress progress output

  -v, --verbose
          Enable verbose/debug output

  -h, --help
          Print help (see a summary with '-h')
```

---

## Output Shape

| Aspect | Value |
|---|---|
| Default format | `json` |
| Formats that work | `json`, `text`, `compact`, **`dot`** (P01, P06, P07, P08) |
| Formats that error | `sarif` (P05: exit 1) |
| Typical output size | small (~1 KB for top-10 hubs on small scope) to heavy (~50 KB for top-100 on full project) |

**Top-level keys (JSON, `HubReport`):**
- `hubs` (`array<HubEntry>`) — ranked top-N hubs, truncated by `--top` and filtered by `--threshold`
- `total_nodes` (`usize`) — total functions in the call graph
- `hub_count` (`usize`) — count of returned hubs (post-filter)
- `measures_used` (`array<string>`) — algorithm names actually run (`["in_degree", "out_degree", "pagerank", "betweenness"]` for default `--algorithm all`, OR `[]` for empty graph)
- `pagerank_info` (`object`, omitted when --algorithm doesn't include pagerank) — `{ iterations_used: usize, converged: bool }` for the PageRank pass
- `explanation` (`string`, only present when graph is empty) — sentinel text like `"Empty call graph - no functions found."`

**`HubEntry` shape:**
- `function_ref` (`{ file, name, line, is_public, is_test, is_trait_method, has_decorator }`)
- `composite_score` (`float64`, 0.0–1.0) — normalized blend of in/out/pagerank/betweenness
- `in_degree`, `out_degree` (`usize`)
- `pagerank` (`float64`, omitted unless algorithm includes it)
- `betweenness` (`float64`, omitted unless algorithm includes it)
- `risk_level` (`string`) — `"LOW"`, `"MEDIUM"`, `"HIGH"`, `"CRITICAL"` bucket derived from composite_score

**Text format (P06):** Compact table with columns `# | Risk | Function | File | Score | In | Out`.

**DOT format (P08):** Node-only digraph (`digraph hubs`) with `[style=invis]` edges chaining the top hubs sequentially to force a vertical Graphviz layout. Each node has a `[label="<name> (score=<X>)"]`. NO actual call edges in the DOT — purely a labeled-node listing.

**Empty result (P21, empty dir):**
```json
{
  "hubs": [],
  "total_nodes": 0,
  "hub_count": 0,
  "measures_used": [],
  "explanation": "Empty call graph - no functions found."
}
```
Exit 0. `measures_used` is empty `[]` (NOT the algorithm list); `explanation` IS present.

**Threshold-empty result (P15/P16, threshold above all scores):**
```json
{
  "hubs": [],
  "total_nodes": 1308,
  "hub_count": 0,
  "measures_used": ["in_degree", "out_degree", "pagerank", "betweenness"],
  "pagerank_info": { "iterations_used": 24, "converged": true }
}
```
Exit 0. `total_nodes` is populated; `measures_used` is the FULL algorithm list. NO `explanation` field (the graph wasn't empty; it just had no hubs above threshold).

**Error shapes:**
- Path not found: `"Error: Path not found: /no/such/dir"` → exit **1** (anyhow!)
- Path is a file: `"Error: hubs requires a directory; got file 'X'. Pass the project root or omit the argument to use the current directory."` → exit **1** (`require_directory` helper)
- Threshold out-of-range (>1.0 or via `=` syntax): `"Error: Threshold must be between 0.0 and 1.0, got 1.5"` → exit **1** (anyhow!)
- Threshold negative (without `=`): clap parses `-0.1` as a new flag — `"error: unexpected argument '-0' found"` → exit **2**
- Bad `--algorithm`: clap-style with valid-values list → exit **2**
- Bad `--lang`: clap-style → exit **2**
- Format reject: standard sarif-not-supported → exit **1**

---

## Probe Matrix

| # | Probe | Type | Exit | Captured |
|---|-------|------|------|----------|
| P01 | `tldr hubs backend/providers -l python` | happy (small scope) | 0 | [`01-happy.*`](./hubs.probes/) |
| P02 | `tldr hubs backend -l python` | happy-scale | 0 | [`02-happy-scale.*`](./hubs.probes/) |
| P03 | N/A: PATH defaults to `.`, no required positional. | — | — | [`03-missing-arg.*`](./hubs.probes/) (placeholder) |
| P04 | `tldr hubs /no/such/dir` | failure-badpath | 1 | [`04-badpath.*`](./hubs.probes/) |
| P05 | `tldr hubs ... -f sarif` | format-reject (sarif) | 1 | [`05-format-reject-sarif.*`](./hubs.probes/) |
| P06 | `tldr hubs ... -f text` | format-text (table) | 0 | [`06-format-text.*`](./hubs.probes/) |
| P07 | `tldr hubs ... -f compact` | format-compact | 0 | [`07-format-compact.*`](./hubs.probes/) |
| P08 | `tldr hubs ... -f dot` | format-dot (node-only) | 0 | [`08-format-dot.*`](./hubs.probes/) |
| P09 | `tldr hubs ... --top 1` | top-one | 0 | [`09-top-one.*`](./hubs.probes/) |
| P10 | `tldr hubs ... --top 100` | top-hundred | 0 | [`10-top-hundred.*`](./hubs.probes/) |
| P11 | `tldr hubs ... --algorithm indegree` | algo-indegree | 0 | [`11-algo-indegree.*`](./hubs.probes/) |
| P12 | `tldr hubs ... --algorithm pagerank` | algo-pagerank | 0 | [`12-algo-pagerank.*`](./hubs.probes/) |
| P13 | `tldr hubs ... --algorithm betweenness` | algo-betweenness | 0 | [`13-algo-betweenness.*`](./hubs.probes/) |
| P14 | `tldr hubs ... --algorithm wat` | bad-algorithm (clap) | 2 | [`14-algo-bogus.*`](./hubs.probes/) |
| P15 | `tldr hubs ... --threshold 0.5` | threshold-mid (empty result) | 0 | [`15-threshold-mid.*`](./hubs.probes/) |
| P16 | `tldr hubs ... --threshold 0.99` | threshold-high (empty result) | 0 | [`16-threshold-high.*`](./hubs.probes/) |
| P17 | `tldr hubs ... --threshold 1.5` | threshold-oor (runtime) | 1 | [`17-threshold-oor.*`](./hubs.probes/) |
| P18 | `tldr hubs ... --threshold -0.1` | threshold-negative (clap rejection) | 2 | [`18-threshold-negative.*`](./hubs.probes/) |
| P19 | `tldr hubs ... -l brainfuck` | bad-lang | 2 | [`19-bad-lang.*`](./hubs.probes/) |
| P20 | `tldr hubs backend/providers/base.py` | file-as-path (clear error) | 1 | [`20-file-arg.*`](./hubs.probes/) |
| P21 | `tldr hubs <empty-tmp-dir>` | empty-dir | 0 | [`21-empty-dir.*`](./hubs.probes/) |
| P22 | `tldr hubs ... -q` | quiet | 0 | [`22-quiet.*`](./hubs.probes/) |

### Observations

- **P01** — `backend/providers/` (4 files): `total_nodes: 13`, 10 hubs returned (all `LOW` risk, scores 0.077–0.263). `_to_finite_float` tops the list with in_degree=3. `pagerank_info: { iterations_used: 24, converged: true }`.
- **P02** — Full `backend/`: `total_nodes: 1308`, 10 hubs (--top default), still `LOW` risk band. Scores generally lower because composite is normalized over a larger graph.
- **P03** — **N/A.** PATH defaults to `.`, no required positional.
- **P04** — stderr `"Error: Path not found: /no/such/dir"`, exit `1` (anyhow!). Same convention as `tldr calls`/`tldr dead`.
- **P05** — stderr `"Error: --format sarif not supported by hubs. Use --format json. SARIF is only emitted by: vuln, clones."`, exit `1`.
- **P06** — Text format renders a tabular display with columns `# | Risk | Function | File | Score | In | Out`. Progress messages on stderr: `"Building call graph for..."` and `"Computing hub centrality metrics..."`.
- **P07** — Single-line minified JSON.
- **P08** — DOT format: **node-only graph** with composite scores in labels. Edges are `[style=invis]` placeholders that chain hubs sequentially to force Graphviz vertical layout. **There are NO actual call edges in the DOT** — purely a labeled list. Contrast with `tldr calls -f dot` which emits real edges.
- **P09** — `--top 1` returns the single highest-scoring hub. Schema identical to P01.
- **P10** — `--top 100`: returns up to 100 hubs (capped at total_nodes which is 1308). Output ~10524 lines.
- **P11** — `--algorithm indegree` only: `measures_used: ["in_degree"]`, `pagerank_info` ABSENT (only present when pagerank participated). Composite score is just normalized in_degree.
- **P12** — `--algorithm pagerank`: `measures_used: ["pagerank"]`, `pagerank_info: { iterations_used: N, converged: true }` IS present. Composite score = normalized pagerank.
- **P13** — `--algorithm betweenness`: `measures_used: ["betweenness"]`. Slowest mode (O(n³) for unweighted graph). On Stock-Monitor backend runs in a few seconds.
- **P14** — clap-style: `"error: invalid value 'wat' for '--algorithm <ALGORITHM>' [possible values: all, indegree, outdegree, pagerank, betweenness]"`, exit `2`. Typed enum with full possible-values list — better UX than untyped flags like `tldr dice`'s `--normalize`.
- **P15, P16** — `--threshold 0.5` and `--threshold 0.99` on full backend both return `hubs: []` with `hub_count: 0` but `total_nodes: 1308` and `measures_used` populated. No `explanation` field (graph wasn't empty; just no hubs above threshold). Exit 0 — typed empty result.
- **P17** — stderr `"Error: Threshold must be between 0.0 and 1.0, got 1.5"`, exit `1` (anyhow!). The runtime range check at `hubs.rs:97-101` catches this.
- **P18** — **clap-level rejection BEFORE runtime validation:** stderr `"error: unexpected argument '-0' found / tip: to pass '-0' as a value, use '-- -0'"`, exit `2`. **clap parses `-0.1` as a new flag** because it starts with `-`. The runtime range check never runs. **Recovery hint:** use `--threshold=-0.1` (with `=` sign) OR `-- -0.1`. The hidden negative-threshold rejection is via a different code path than positive-out-of-range.
- **P19** — clap-style: `"error: invalid value 'brainfuck' for '--lang <LANG>': Unknown language: brainfuck"`, exit `2`.
- **P20** — **Best-in-class error message** (P2.BUG-4 cli-error-clarity-v2): stderr `"Error: hubs requires a directory; got file 'backend/providers/base.py'. Pass the project root or omit the argument to use the current directory."`, exit `1`. Tells the user EXACTLY what's wrong AND how to fix it. Compare with `tldr explain backend` (P17 in explain dossier) which yields the cryptic `"parse error in backend: Unsupported language"`.
- **P21** — Empty directory: `total_nodes: 0`, `hubs: []`, `measures_used: []` (empty array, NOT the full algorithm list), AND `explanation: "Empty call graph - no functions found."` field IS present. Exit 0. **Distinguishable from threshold-empty (P15/P16) by `measures_used` length and presence of `explanation`.**
- **P22** — `-q` suppresses stderr progress; stdout JSON identical to P01 (verified via MD5).

---

## Source Code Reality

**Target file(s):**
- `crates/tldr-cli/src/commands/hubs.rs` (157 lines)
- `crates/tldr-core/src/analysis/hubs.rs` (`compute_hub_report_with_lines`, `enumerate_function_lines`)
- `crates/tldr-cli/src/path_validation.rs` (`require_directory`)
- `crates/tldr-cli/src/output.rs:113` (`validate_format_for_command`)

**Pinned to upstream commit:** `6c4011a` (release v0.4.0)

**Argument struct:**
```rust
// crates/tldr-cli/src/commands/hubs.rs:62-83
#[derive(Debug, Args)]
pub struct HubsArgs {
    #[arg(default_value = ".")] pub path: PathBuf,
    #[arg(long, default_value = "10")] pub top: usize,
    #[arg(long, value_enum, default_value = "all")] pub algorithm: AlgorithmArg,
    #[arg(long)] pub threshold: Option<f64>,
    #[arg(long, short = 'l')] pub lang: Option<Language>,
}
```
Reveals: `algorithm` is a clap `ValueEnum` (clean rejection with valid-values list); `threshold` is `Option<f64>` (no clap-level range check; runtime validation only). Notably, **`--top` has NO short flag** — unlike `similar` (`-n`) or `importers` (`-m`).

**Path validation via shared helper:**
```rust
// hubs.rs:94
require_directory(&self.path, "hubs")?;
```
Reveals: uses the `cli-error-clarity-v2` shared helper (`path_validation.rs`) which prints `"hubs requires a directory; got file 'X'. Pass the project root or omit the argument to use the current directory."` This is a quality-of-life improvement over the older `anyhow!("Path not found")` pattern used by `tldr calls`/`tldr dead`.

**Threshold validation:**
```rust
// hubs.rs:97-101
if let Some(thresh) = self.threshold {
    if !(0.0..=1.0).contains(&thresh) {
        anyhow::bail!("Threshold must be between 0.0 and 1.0, got {}", thresh);
    }
}
```
Reveals: runtime check rejects out-of-range with exit 1. **But** this only runs for values clap accepts — negative values starting with `-` are pre-rejected by clap (P18).

**Algorithm enum mapping:**
```rust
// hubs.rs:34-59
#[derive(Debug, Clone, Copy, Default, ValueEnum)]
pub enum AlgorithmArg { All, Indegree, Outdegree, Pagerank, Betweenness }
impl From<AlgorithmArg> for HubAlgorithm { ... }
```
Reveals: CLI-side ValueEnum mirrors the core `HubAlgorithm`. The `From` impl bridges them. This is the cleanest enum-flag pattern in the CLI.

**Graph construction:**
```rust
// hubs.rs:115
let graph = build_project_call_graph(&self.path, language, None, true)?;
```
Reveals: uses the V1 call-graph builder (via `tldr_core::build_project_call_graph`). NOT the V2 builder (`build_project_call_graph_v2`) used by `tldr calls`. Different code path — may yield slightly different node counts for the same input.

**Function line enumeration (hubs-line-population-v1 fix):**
```rust
// hubs.rs:124-129
let function_lines = enumerate_function_lines(&self.path, language);
let report = compute_hub_report_with_lines(
    &nodes, &forward, &reverse,
    self.algorithm.into(), self.top, self.threshold,
    Some(&function_lines),
);
```
Reveals: the V1 graph builder constructs FunctionRefs with `line: 0` placeholders. The CLI explicitly re-enumerates function definition lines via tree-sitter so the JSON output has real line numbers. **Without this, hubs JSON would have `line: 0` for every entry.**

**DOT formatter (P08 root cause):**
```rust
// hubs.rs:146-150
} else if writer.is_dot() {
    let dot = format_hubs_dot(&report);
    writer.write_text(&dot)?;
}
```
The `format_hubs_dot` helper outputs nodes-only + invisible chaining edges. Source comment: *"hubs DOT — node-only graph of top hubs labeled with their composite scores."* So hubs DOT is intentionally NOT a call graph; it's a vertical list of labeled boxes.

**Format validation:** confirmed at `crates/tldr-cli/src/output.rs:113-163` — `hubs` IS in `DOT_SUPPORTED` (with `calls`, `clones`, `deps`, `impact`, `inheritance`), but NOT in `SARIF_SUPPORTED`.

**No daemon route:** `grep -n try_daemon_route hubs.rs` returns 0 matches. Every call rebuilds the call graph from scratch — `tldr warm` is a no-op for this command.

---

## Architectural Deep Dive

- **Under the hood:** Builds the V1 cross-file call graph, then runs four centrality algorithms over it (in/out-degree, PageRank with damping factor 0.85, betweenness via Brandes' algorithm). Composite score is a weighted blend of normalized rankings. Risk bucketing thresholds (LOW/MEDIUM/HIGH/CRITICAL) are baked into the engine.
- **Performance:** Cold ~2-4s on Stock-Monitor backend (1308 nodes). Betweenness is the slowest pass (O(n³)). `--algorithm indegree` or `--algorithm outdegree` is the fastest single mode. NO daemon route — every call rebuilds.
- **LLM cognitive load:** Replaces "which functions, if I changed them, would cause the most breakage?" Combine with `tldr impact <fn>` for blast-radius verification on each named hub. The composite score and risk label give agents a direct prioritization signal for refactoring or test prioritization.

---

## Intent & Routing

- **User/Agent Goal:** identify high-centrality "hub" functions whose modification ripples through the codebase. Use for risk-based test prioritization, refactor prioritization, or finding architectural choke points.
- **When to choose this over similar tools:**
  - Over `tldr calls`: `calls` returns the full graph; `hubs` returns the top-N most-connected nodes by centrality. Use `hubs` for the executive summary, `calls -f dot` for the picture.
  - Over `tldr complexity`: `complexity` ranks by cyclomatic; `hubs` ranks by network position. A simple function called everywhere is a hub even with cyclomatic=1.
  - Over `tldr impact <fn>`: `impact` requires a known function name; `hubs` DISCOVERS candidate names. Pipe `tldr hubs <path> -f compact | jq '.hubs[].function_ref.name' | head | xargs -I{} tldr impact {}`.
- **Prerequisites (composition):**
  - PATH must be a directory (the `require_directory` helper rejects regular files with a clear error — P20).
  - For mixed-language roots, supply `-l <lang>` (the `Language::from_directory(...).unwrap_or(Language::Python)` fallback can silently pick wrong on mixed roots — same gotcha as `tldr importers`/`tldr dead`).
  - For exploratory work, use `--algorithm all` (default); for speed, use `indegree` or `outdegree`; for caller-importance-weighted rankings, use `pagerank`; for bottleneck detection, use `betweenness`.

---

## Agent Synthesis

> **How to use `tldr hubs`:**
> Centrality-based hub detection. `tldr hubs [PATH]` builds a call graph then returns the top-N functions by composite-score (normalized blend of in-degree, out-degree, PageRank, betweenness). Default `--top 10`, default `--algorithm all`. Output JSON `{ hubs, total_nodes, hub_count, measures_used, pagerank_info? }`. Use `--threshold 0.0-1.0` to filter low-score noise. Default format is JSON; `text` (table), `compact`, `dot` (node-only, with invis chaining edges to force vertical Graphviz layout) all supported. Exit codes: 0 ok (including hubs:[] under threshold), 1 path-not-found / path-is-file / format-reject / threshold-out-of-range, 2 bad `--algorithm` / `--lang` / negative threshold rejected by clap.
>
> **Crucial Rules:**
> - **`--threshold=-0.1` is required for negative values; bare `--threshold -0.1` is rejected by clap.** clap interprets `-0.1` as a new flag because it starts with `-`. The runtime range check at `hubs.rs:97-101` never runs (P18). **Fix:** use `--threshold=-0.1` (with the equals sign) — OR don't bother, negative thresholds are clamped to 0 anyway since composite_score ∈ [0, 1].
> - **`tldr hubs` has the best path-error UX in the CLI.** `require_directory` (cli-error-clarity-v2 P2.BUG-4) tells the user EXACTLY what's wrong: `"hubs requires a directory; got file 'X'. Pass the project root or omit the argument to use the current directory."` Unlike `tldr explain` which yields cryptic "parse error: Unsupported language" for the same mistake.
> - **DOT format is NOT a call graph.** `tldr hubs -f dot` emits nodes-only with invisible chaining edges (`[style=invis]`) to force a vertical Graphviz layout. The hubs are presented as a labeled list, NOT linked by call relationships. For a real call graph DOT, use `tldr calls -f dot` (P08).
> - **Empty-graph vs threshold-empty are distinguishable.** Empty graph: `measures_used: []` AND `explanation: "Empty call graph..."` field present. Threshold-empty: `measures_used` is the full algorithm list AND no `explanation` field. Branch on `explanation` presence (P21 vs P15/P16).
> - **NO daemon route.** Every call rebuilds the V1 call graph from scratch. `tldr warm` does nothing for this command. Cold-only performance ~2-4s on Stock-Monitor backend.
> - **Uses V1 call graph, not V2.** `tldr hubs` calls `build_project_call_graph` (V1) while `tldr calls` uses `build_project_call_graph_v2` (V2). Node counts may differ slightly between the two commands on the same input.
> - **`line: 0` would be a regression.** `enumerate_function_lines` is explicitly run to populate real line numbers (V1 builder returns 0 placeholders). If you ever see `line: 0` in hubs output, that's a regression of `hubs-line-population-v1` (see hubs.rs:124-129).
> - **`measures_used` is the algorithm trace.** With `--algorithm indegree`, you get `measures_used: ["in_degree"]` AND no `pagerank_info` field. With `--algorithm all`, you get all four AND pagerank_info IS populated. Use `measures_used` to verify which algorithms actually ran.
> - **Path-not-found exit code is 1** (anyhow!). Cross-command convention.
>
> **Command:** `tldr hubs [PATH] -l <lang>`
>
> **With common flags:** `tldr hubs <PATH> -l <lang> --top 20 --algorithm pagerank --threshold 0.1 -f compact` (use for caller-importance-weighted top-20 with a low cutoff to surface meaningful hubs; pipe to jq for downstream analysis).
