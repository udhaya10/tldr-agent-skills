# Command: `tldr calls`

## Environment Pin

| Field | Value |
|---|---|
| `tldr --version` | 0.4.0 |
| Build features | `semantic` (verified; calls itself is non-semantic) |
| Target repo | Stock-Monitor @ commit `e601869` |
| Upstream `tldr-code` pinned to | local clone @ `6c4011a` (release v0.4.0) |
| Daemon state at probe time | mixed (P16 cold, P17/P18/P19 warm) |
| OS | darwin 25.2.0 |
| Probe date | 2026-05-22 |

Re-run all evidence via [`calls.probes/probe.sh`](./calls.probes/probe.sh).
See also: [agent-oriented tool card](../../tool-cards/trace/calls.md).

---

## Ground Truth (`tldr calls --help`)

```text
Build cross-file call graph

Usage: tldr calls [OPTIONS] [PATH]

Arguments:
  [PATH]
          Project root directory (default: current directory)

          [default: .]

Options:
  -l, --lang <LANG>
          Programming language (auto-detected if not specified)

      --respect-ignore
          Respect .gitignore and .tldrignore patterns

      --max-items <MAX_ITEMS>
          Maximum items (edges) to include in output (default: 200)

          [default: 200]

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
| Typical output size | medium (~50 KB JSON for ~100 edges) to heavy (~600 KB for ~2400 edges) |

**Top-level keys (JSON, `CallGraphOutput`):**
- `root` (`string`) — the input PATH (NOT canonicalized in the JSON; canonicalization happens internally for strip_prefix only)
- `language` (`string` OR `null`) — auto-detected or specified language. **`null` when `Language::from_directory` finds no analyzable files** (P13) — distinct from "python" default. (schema-cleanup-v2 P2.BUG-10)
- `nodes` (`array<string>`) — unique `"file:func"` strings, including BOTH endpoints of every edge AND every defined function in the project (so single-language inventory is faithful even when functions have no call edges)
- `edges` (`array<EdgeOutput>`) — call edges, truncated to `--max-items`
- `truncated` (`bool`) — always emitted, even when false (path-and-schema-cleanup-v3 P3.BUG-N5)
- `total_edges` (`usize`) — full count BEFORE truncation
- `shown_edges` (`usize`) — count of `edges` array AFTER truncation

**`EdgeOutput` shape:**
- `src_file`, `dst_file` (`string`) — project-relative paths (root prefix stripped)
- `src_func`, `dst_func` (`string`) — function names; method calls show `Class.method` qualified form for the `dst_func`
- `call_type` (`string` enum) — `"direct"`, `"method"`, plus other CallType variants (`"Direct"` / `"Method"` capitalized in DOT label format)

**Empty-dir shape (P13):**
```json
{
  "root": "/tmp/...",
  "language": null,
  "nodes": [],
  "edges": [],
  "truncated": false,
  "total_edges": 0,
  "shown_edges": 0
}
```
Exit 0 — empty result is success; `language: null` is the explicit "couldn't detect" sentinel.

**DOT output (P08):**
```dot
digraph calls {
    rankdir=LR;
    node [shape=box, fontname="Helvetica"];
    edge [fontname="Helvetica", fontsize=10];

    "src.py:func_a" -> "dst.py:Class.func_b" [label="Direct"];
    ...
}
```

**Error shapes:**
- Path not found: `"Error: Path not found: /no/such/dir"` → exit **1** (anyhow!)
- Format-reject sarif: `"Error: --format sarif not supported by calls. Use --format json. SARIF is only emitted by: vuln, clones."` → exit **1**
- `--respect-ignore=value` provided: clap-style `"error: unexpected value 'false' for '--respect-ignore' found; no more were expected"` → exit **2**
- Bad `--lang`: clap-style `"error: invalid value 'X' for '--lang <LANG>': Unknown language: X"` → exit **2**

---

## Probe Matrix

| # | Probe | Type | Exit | Captured |
|---|-------|------|------|----------|
| P01 | `tldr calls backend/providers -l python` | happy (small subdir) | 0 | [`01-happy.*`](./calls.probes/) |
| P02 | `tldr calls backend -l python` | happy-scale | 0 | [`02-happy-scale.*`](./calls.probes/) |
| P03 | N/A: PATH defaults to `.`, no required positional. | — | — | [`03-missing-arg.*`](./calls.probes/) (placeholder triple) |
| P04 | `tldr calls /no/such/dir` | failure-badpath | 1 | [`04-badpath.*`](./calls.probes/) |
| P05 | `tldr calls ... -f sarif` | format-reject (sarif) | 1 | [`05-format-reject-sarif.*`](./calls.probes/) |
| P06 | `tldr calls ... -f text` | format-text | 0 | [`06-format-text.*`](./calls.probes/) |
| P07 | `tldr calls ... -f compact` | format-compact | 0 | [`07-format-compact.*`](./calls.probes/) |
| P08 | `tldr calls ... -f dot` | format-dot (supported!) | 0 | [`08-format-dot.*`](./calls.probes/) |
| P09 | `tldr calls backend ... --max-items 5` | truncation-small | 0 | [`09-max-items-small.*`](./calls.probes/) |
| P10 | `tldr calls backend ... --max-items 99999` | no-truncation | 0 | [`10-max-items-large.*`](./calls.probes/) |
| P11 | `tldr calls ... --respect-ignore=false` | respect-ignore-bug | 2 | [`11-no-respect-ignore.*`](./calls.probes/) |
| P12 | `tldr calls ... -l brainfuck` | bad-lang (clap) | 2 | [`12-bad-lang.*`](./calls.probes/) |
| P13 | `tldr calls <empty-tmp-dir>` | empty-dir (language: null) | 0 | [`13-empty-dir.*`](./calls.probes/) |
| P14 | `tldr calls . -l python --max-items 50` | mixed-root-python | 0 | [`14-mixed-root-python.*`](./calls.probes/) |
| P15 | `tldr calls ... -q` | quiet | 0 | [`15-quiet.*`](./calls.probes/) |
| P16 | `tldr calls backend -l python` *(cold daemon)* | cold-daemon | 0 | [`16-cold-daemon.*`](./calls.probes/) |
| P17 | `tldr calls backend -l python` *(warm daemon)* | warm-daemon | 0 | [`17-warm-daemon.*`](./calls.probes/) |
| P18 | `tldr calls backend -l python -f dot` *(warm)* | warm-daemon-dot | 0 | [`18-warm-daemon-dot.*`](./calls.probes/) |
| P19 | `tldr calls backend -l python -f text` *(warm)* | warm-daemon-text | 0 | [`19-warm-daemon-text.*`](./calls.probes/) |

### Observations

- **P01** — `backend/providers/` (4 files) reports `total_edges: 11`, `shown_edges: 11`, `truncated: false`, `language: "python"`. Edges include `Direct` and `Method` call types. Self-edges (function calling itself) NOT present.
- **P02** — Full `backend/` (~56 Python files): `total_edges: ~2400`, `shown_edges: 200` (default `--max-items: 200`), `truncated: true`. Output stdout ~2748 lines because `nodes` is NOT truncated — every defined function appears.
- **P03** — **N/A.** `ImportersArgs.path` defaults to `.`, no required positional. Marked as N/A in matrix per Journal 04 §4.2 guidance.
- **P04** — stderr `"Error: Path not found: /no/such/dir"`, exit `1` (anyhow!). Matches `tldr importers` convention; diverges from `tldr definition` (exit 5) and `tldr context` (exit 2).
- **P05** — stderr `"Error: --format sarif not supported by calls. Use --format json. SARIF is only emitted by: vuln, clones."`, exit `1`. **Note:** calls IS in `DOT_SUPPORTED` (P08) but NOT in `SARIF_SUPPORTED` — asymmetric format support.
- **P06** — Text format: `"Call Graph for <path> (<lang>)"` header, `"Edges: N"` row, then one line per edge as `src_file:src_func -> dst_file:dst_func`. Language label is lowercased here (`"python"` not `"Python"`).
- **P07** — Single-line minified JSON, same schema as P01.
- **P08** — DOT format produces `digraph calls { ... }` with `rankdir=LR`, `node [shape=box]`, and one `"src" -> "dst" [label="<CallType>"]` line per edge. Labels are capitalized (`"Direct"`, `"Method"`) — capitalized differently from JSON's lowercase `"direct"`/`"method"`. **Schema inconsistency** between formats.
- **P09** — `--max-items 5` produces `shown_edges: 5`, `total_edges: 2400`, `truncated: true`. Edges are sorted by `src_file:src_func` (alphabetic) BEFORE truncation, so truncated output is reproducible across runs. **The `nodes` array is NOT truncated** — it still has 1300+ entries because all defined functions are unioned in.
- **P10** — `--max-items 99999` returns the full edge list (~2400 edges), `truncated: false`. Output is 18171 lines.
- **P11** — **`--respect-ignore=false` is REJECTED:** stderr `"error: unexpected value 'false' for '--respect-ignore' found; no more were expected"`, exit `2`. The source declares `#[arg(long, default_value = "true")]` for a `bool` field; clap interprets this as a `SetTrue` action (boolean toggle, no value accepted), so the `=false` syntax is invalid. **`--respect-ignore` is effectively always-on; you CANNOT turn it off via CLI.** Source-comment drift: the field's purpose ("Respect .gitignore") implies it's opt-in, but the implementation has it default-true AND non-toggleable.
- **P12** — clap-style: `"error: invalid value 'brainfuck' for '--lang <LANG>': Unknown language: brainfuck"`, exit `2`.
- **P13** — Empty directory: `language: null` (NOT `"python"`!), `nodes: []`, `edges: []`. Exit 0. Confirms the P2.BUG-10 fix: empty-dir no longer misreports as `"python"` with 0 edges.
- **P14** — `tldr calls . -l python` on the mixed-language project root (Python + TypeScript webui): finds Python edges across the whole project, `total_edges` ~tens-of-thousands (output truncated to 50). The `-l python` override prevents the language detector from picking TypeScript on the mixed root.
- **P15** — `-q` suppresses stderr progress; stdout JSON unaffected.
- **P16, P17** — Cold (P16) and warm (P17) daemon outputs are **byte-identical** (verified via diff). Same `total_edges`, same edge ordering, same JSON.
- **P18** — Daemon route's DOT branch (calls.rs:145-171, gated by `surface-gaps-v1 BUG-19`) produces the same `digraph calls { ... }` shape as the direct-compute path. **No DOT support gap between cold and warm.**
- **P19** — Daemon route's text branch produces same text shape as direct-compute. Edge count matches P02/P16/P17.

---

## Source Code Reality

**Target file(s):**
- `crates/tldr-cli/src/commands/calls.rs` (329 lines)
- `crates/tldr-core/src/callgraph/cross_file_v2.rs` (`build_project_call_graph_v2`)
- `crates/tldr-cli/src/commands/daemon_router.rs:157` (`params_with_path`)
- `crates/tldr-cli/src/output.rs:113` (`validate_format_for_command`)

**Pinned to upstream commit:** `6c4011a` (release v0.4.0)

**Argument struct:**
```rust
// crates/tldr-cli/src/commands/calls.rs:20-37
#[derive(Debug, Args)]
pub struct CallsArgs {
    #[arg(default_value = ".")] pub path: PathBuf,
    #[arg(long, short = 'l')] pub lang: Option<Language>,
    #[arg(long, default_value = "true")] pub respect_ignore: bool,  // ← see Crucial Rules
    #[arg(long, default_value = "200")] pub max_items: usize,
}
```
Reveals: `respect_ignore` uses `default_value = "true"` on a `bool`, which clap interprets as a boolean flag (no `=value` accepted). The intent appears to be "default-true toggle", but the implementation forbids explicit `=false` (P11). To actually disable, the field would need `default_value_t = true, action = clap::ArgAction::Set` (the same pattern `tldr definition`'s `--workspace` uses).

**Path validation:**
```rust
// calls.rs:93-96
if !self.path.exists() {
    anyhow::bail!("Path not found: {}", self.path.display());
}
```
Reveals: same upfront-bail pattern as `tldr importers`. Exit 1 via anyhow!. No `is_file()` check, but `.` defaulting + project-walker means a file argument would proceed and then fail differently.

**Language detection (the empty-dir fix):**
```rust
// calls.rs:108-111
let detected_language = self
    .lang
    .or_else(|| Language::from_directory(&self.path));
let language = detected_language.unwrap_or(Language::Python);
```
Reveals: `detected_language` is `Option<Language>` — preserved in the JSON `language` field. The `unwrap_or(Language::Python)` fallback is used ONLY for the call-graph builder which requires a language; the JSON correctly reports `null` for empty dirs (P13).

**Node-set derivation (Phase-12 fix):**
```rust
// calls.rs:240-258
let mut node_set = std::collections::BTreeSet::new();
for edge in &edges { node_set.insert(...); node_set.insert(...); }
for (file_path, file_ir) in &ir.files {
    ...
    for func in &file_ir.funcs {
        let qualified = if let Some(class) = &func.class_name {
            format!("{}.{}", class, func.name)
        } else { func.name.clone() };
        node_set.insert(format!("{}:{}", rel.display(), qualified));
    }
}
```
Reveals: the node-set is the UNION of edge endpoints AND every defined function. **This is why `nodes` is much larger than `2 × edges`** — the fix at BUG-AGG12-4 (`dag.ml` reporting nodes=2 with 19 actual functions) added the file-walk so single-language inventory is faithful. Side effect: `--max-items` truncates edges only; `nodes` always includes the full project inventory, making the JSON large even with low `--max-items`.

**Edge sort + truncate:**
```rust
// calls.rs:214-227
let total_edges = edges.len();
let truncated = total_edges > self.max_items;
if edges.len() > self.max_items {
    edges.sort_by(|a, b| { format!("{}:{}", ...).cmp(&format!("{}:{}", ...)) });
    edges.truncate(self.max_items);
}
let shown_edges = edges.len();
```
Reveals: edges sorted alphabetically by `src_file:src_func` BEFORE truncation. So with `--max-items 5`, you get the alphabetically-first 5 src functions, not the "most important" 5. Cross-call-edge importance scoring is not implemented.

**DOT formatter:**
```rust
// calls.rs:272-298 (direct-compute), 145-171 (daemon)
let labels: Vec<String> = output.edges.iter()
    .map(|e| format!("{:?}", e.call_type)).collect();  // <-- Debug, not Display
```
Reveals: DOT labels use Rust `Debug` format (`{:?}`) of the `CallType` enum, which yields the capitalized variant name (`"Direct"`, `"Method"`). JSON serialization uses serde's lowercase derive (`"direct"`, `"method"`). **Asymmetric capitalization between JSON and DOT formats.**

**Format validation:** confirmed at `crates/tldr-cli/src/output.rs:113-163` — `calls` is in `DOT_SUPPORTED` (`["clones", "deps", "calls", "impact", "hubs", "inheritance"]`) but NOT in `SARIF_SUPPORTED`.

**Daemon route:**
```rust
// calls.rs:113-176
if let Some(output) = try_daemon_route::<CallGraphOutput>(
    &self.path, "calls",
    params_with_path(Some(&self.path)),
) { ... return Ok(()); }
```
Reveals: daemon path is fully implemented for json, text, AND dot (surface-gaps-v1 BUG-19). Same output shape on both paths.

---

## Architectural Deep Dive

- **Under the hood:** `build_project_call_graph_v2(path, BuildConfig)` walks the project, parses each source file with tree-sitter, resolves cross-file calls via type-resolution (`use_type_resolution: true` by default). The graph builder is the canonical "V2" implementation; legacy V1 was retired. Output is unified `FileIR` plus an edge list.
- **Performance:** Cold ~2-5s on Stock-Monitor backend (56 files); warm sub-200ms via daemon. The 35x speedup claim in the source docstring (`calls.rs:4`) is in the ballpark for repeat queries.
- **LLM cognitive load:** This is the project-wide answer to "who calls whom?". Use it for blast-radius analysis (combined with `tldr impact <fn>`), pattern detection ("which functions are called everywhere?"), or to feed downstream graph tools (DOT → Graphviz → SVG).

---

## Intent & Routing

- **User/Agent Goal:** enumerate cross-file call edges across an entire project as a single typed graph, suitable for piping into DOT visualizers or downstream impact analyses.
- **When to choose this over similar tools:**
  - Over `tldr impact <fn>`: `impact` answers "what calls or is reached from THIS function?"; `calls` gives the WHOLE graph upfront. Use `calls -f dot` for a visual map.
  - Over `tldr references <fn>`: `references` gives use-sites for one symbol; `calls` enumerates function-to-function relationships project-wide.
  - Over `tldr context <fn>`: `context` is depth-limited and centered on one entry; `calls` is the full graph with no depth limit.
- **Prerequisites (composition):**
  - For mixed-language project roots, pass explicit `-l <lang>` — the empty-dir fix means `language: null` for empty dirs, but `Language::from_directory` may still pick the wrong dominant language on mixed roots.
  - `--max-items` only truncates edges; `nodes` always includes the full function inventory.
  - To visualize: `tldr calls <path> -f dot | dot -Tsvg > graph.svg`.

---

## Agent Synthesis

> **How to use `tldr calls`:**
> Project-wide cross-file call graph. `tldr calls [PATH]` returns a JSON object `{ root, language, nodes, edges, truncated, total_edges, shown_edges }`. `edges` is truncated to `--max-items` (default 200); `nodes` is the union of edge endpoints AND every defined function (always full). `language` is `null` for empty dirs (NOT `"python"`). Default format is JSON; supports `text`, `compact`, `dot` (DOT is in the supported set for this command). Daemon path is fully implemented for all four formats. Exit codes: 0 ok (including empty-dir with `language: null`), 1 path-not-found / format-reject (sarif), 2 bad `--lang` / `--respect-ignore=value` (clap).
>
> **Crucial Rules:**
> - **`--respect-ignore=false` is REJECTED with exit 2.** The CLI uses `#[arg(long, default_value = "true")]` on a `bool` field which clap parses as a boolean flag (no `=value` accepted). The flag is **effectively always-on** — you CANNOT turn off gitignore/.tldrignore filtering via the CLI (P11). `respect-ignore` is misleadingly named for an opt-in flag that is default-on and non-toggleable.
> - **`language: null` is a typed sentinel for "no analyzable files."** Empty dirs and language-mismatched dirs report `null` (NOT `"python"`) — fix from P2.BUG-10. Downstream tools should branch on `language === null` instead of parsing English error strings.
> - **`nodes` is NOT truncated by `--max-items`.** It's the union of edge endpoints AND every defined function. With `--max-items 5` on a 2400-edge project, you get 5 edges but still ~1300+ nodes. The JSON size scales with project size regardless of edge cap.
> - **Edges are alphabetically sorted BEFORE truncation.** With `--max-items N`, you get the first-N alphabetically by `src_file:src_func` — NOT the N most-important. No importance ranking is implemented (P09).
> - **CallType capitalization differs between JSON and DOT.** JSON uses serde lowercase (`"direct"`, `"method"`); DOT uses Rust Debug format with capitalization (`"Direct"`, `"Method"`). When matching call_type fields, normalize case.
> - **Path-not-found exit code is 1** (anyhow!). Cross-command convention — definition=5, importers=1, context=2, imports=2, dice=1, similar=1, calls=1. Six different conventions across the CLI for the same error.
> - **calls IS in DOT_SUPPORTED but NOT in SARIF_SUPPORTED.** Asymmetric format set: `tldr calls -f dot` works; `tldr calls -f sarif` returns exit 1.
> - **Daemon and direct-compute outputs are byte-identical** (verified via diff on P16 vs P17). Use `tldr daemon start && tldr warm` before running multiple `calls` queries — sub-200ms warm vs ~2-5s cold.
>
> **Command:** `tldr calls [PATH]`
>
> **With common flags:** `tldr calls <PATH> -l <lang> --max-items 0 -f dot | dot -Tsvg > graph.svg` (use to visualize; `--max-items 0` means default 200, NOT unlimited — pass a large number like `99999` for the full graph).
