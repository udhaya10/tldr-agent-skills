# Command: `tldr impact`

## Environment Pin

| Field | Value |
|---|---|
| `tldr --version` | 0.4.0 |
| Build features | `semantic` (verified via runtime probe on 2026-05-21) |
| Target repo | Stock-Monitor @ commit `e601869` |
| Upstream `tldr-code` pinned to | local clone at `/Users/udhayakumar/Workspace/03-Parcadei-Ecosystem/tldr-code` @ `6c4011a` (release v0.4.0) |
| Daemon state at probe time | warm (cycled mid-probe for P15/P16) |
| OS | darwin 25.2.0 |
| Probe date | 2026-05-22 |

Re-run all evidence via [`impact.probes/probe.sh`](./impact.probes/probe.sh).
See also: [agent-oriented tool card](../../tool-cards/trace/impact.md).

---

## Ground Truth (`tldr impact --help`)

```text
Analyze impact of changing a function

Usage: tldr impact [OPTIONS] <FUNCTION> [PATH]

Arguments:
  <FUNCTION>
          Function name to analyze

  [PATH]
          Project root directory (default: current directory)
          
          [default: .]

Options:
  -l, --lang <LANG>
          Programming language

  -d, --depth <DEPTH>
          Maximum traversal depth
          
          [default: 5]

      --file <FILE>
          Filter by file path

      --type-aware
          Enable type-aware method resolution (resolves self.method() to ClassName.method)

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
| Formats that work | `json`, `text`, `compact`, **`dot`** (P07 — impact IS in `DOT_SUPPORTED`) |
| Formats that error | `sarif` (P05: exit 1) |
| Typical output size | medium (1–50KB) for one function with ≤10 callers |

**Top-level keys (JSON):**
- `targets` (`map<string, TargetInfo>`) — key is `"<file>:<function>"` (e.g., `"db.py:get_db_connection"`). Multiple targets are possible when the function name resolves in multiple files.
- `type_resolution` (object, present only when `--type-aware` is passed; see Type-Aware caveat below)

**Per-target shape (`targets[<key>]`):**
- `function` (`string`) — function name as queried
- `file` (`string`) — file where the function is defined
- `caller_count` (`int`) — number of callers found
- `callers` (`array<Caller>`) — recursive list (each caller is itself a `Caller` with its own callers)
- `truncated` (`bool`) — whether the result was capped (depth or reference limit)
- `note` (`string`, optional) — annotation, e.g. `"caller_count derived from references enrichment (call graph missing cross-file edges)"`

**Per-caller shape (`callers[]`):**
- `function`, `file`, `caller_count`, `callers[]` (recursive)
- `truncated` (`bool`)
- `note` (`string`, optional) — e.g. `"Discovered via references at line 172 (call graph missing edge)"`. **This is the marker for references-enrichment fallback.**

**DOT format (P07):** Graphviz `digraph` with `rankdir=RL` (right-to-left for reverse call graph). Each edge is `"caller-file:caller-fn" -> "callee-file:callee-fn"`. Suitable for rendering or feeding into other Graphviz tooling.

**Text format (P06):** Indented tree with `(N callers)` annotations and `Note:` lines exposing the references-enrichment provenance.

**Compact format (P14):** Single-line JSON.

**Error shapes — `impact` has FOUR distinct exit codes:**
- **Exit 1** — anyhow-style runtime errors:
  - Bad path (P04): `Error: Path not found: <path>`
  - File passed as PATH (P13): `Error: impact requires a directory; got file '<path>'. Pass the project root or omit the argument to use the current directory.` — clear and actionable.
  - Format rejection (P05): `Error: --format sarif not supported by impact. ...`
- **Exit 2** — clap validation:
  - Missing `<FUNCTION>` (P03): clap error with `Usage:` hint.
- **Exit 20** — function not found (P10, P12):
  - Without `--file`: `Error: Function not found: <name>`
  - With `--file`: `Error: Function not found: <name> in <file>`. **Includes "Did you mean:" suggestions when there are close matches.**
- **Exit 0** — success, including empty results (`targets: {}` is valid).

> **Exit 20 with "Did you mean" suggestions** is a unique recovery affordance — agents can parse these and retry with the suggested name.

---

## Probe Matrix

Slug convention: `NN-<token>[-<modifier>]`. The audit script globs by ID, so modifiers are safe.

| # | Probe | Type | Exit | Captured |
|---|-------|------|------|----------|
| P01 | `tldr impact get_db_connection backend` | happy | 0 | [`01-happy.*`](./impact.probes/) |
| P02 | `tldr impact get_db_connection .` | happy-scale | 0 | [`02-happy-scale.*`](./impact.probes/) |
| P03 | `tldr impact` *(no args)* | failure-missing-arg | 2 | [`03-missing-arg.*`](./impact.probes/) |
| P04 | `tldr impact get_db_connection /no/such/path` | failure-badpath | 1 | [`04-badpath.*`](./impact.probes/) |
| P05 | `tldr impact get_db_connection backend -f sarif` | format-reject | 1 | [`05-format-reject-sarif.*`](./impact.probes/) |
| P06 | `tldr impact get_db_connection backend -f text` | format-text | 0 | [`06-format-text.*`](./impact.probes/) |
| P07 | `tldr impact get_db_connection backend -f dot` | format-dot | 0 | [`07-format-dot.*`](./impact.probes/) |
| P08 | `tldr impact get_db_connection backend -d 1` | flag-depth-shallow | 0 | [`08-depth-1.*`](./impact.probes/) |
| P09 | `tldr impact get_db_connection backend -d 10` | flag-depth-deep | 0 | [`09-depth-10.*`](./impact.probes/) |
| P10 | `tldr impact get_db_connection backend --file backend/api.py` | flag-file-filter | 20 | [`10-file-filter.*`](./impact.probes/) |
| P11 | `tldr impact get_db_connection backend --type-aware` | flag-type-aware | 0 | [`11-type-aware.*`](./impact.probes/) |
| P12 | `tldr impact zzz_nonexistent_function backend` | failure-fn-not-found | 20 | [`12-function-not-found.*`](./impact.probes/) |
| P13 | `tldr impact get_db_connection backend/db.py` | failure-file-as-path | 1 | [`13-file-as-path.*`](./impact.probes/) |
| P14 | `tldr impact get_db_connection backend -f compact` | format-compact | 0 | [`14-format-compact.*`](./impact.probes/) |
| P15 | `tldr impact get_db_connection backend` *(daemon stopped)* | env-cold-daemon | 0 | [`15-cold-daemon.*`](./impact.probes/) |
| P16 | `tldr impact get_db_connection backend` *(after `tldr warm`)* | env-warm-daemon | 0 | [`16-warm-daemon.*`](./impact.probes/) |

### Observations

- **P01 (small scope, 70 lines):** 7 callers found in `backend/`. **All 7 callers carry the note `"Discovered via references at line N (call graph missing edge)"`** — meaning the Python call graph builder missed every cross-file edge, and `enrich_impact_with_references` recovered them via the references engine. This is the dominant code path for Python projects.
- **P02 (full repo `.`, 141 lines):** 8 callers (one extra: `backfill_nse_history.py` outside `backend/`). Some callers also have `caller_count > 0`, meaning their own callers were resolved at the next level.
- **P03 (missing `<FUNCTION>`):** clap error, exit `2`. `Usage: tldr impact <FUNCTION> [PATH]` in the hint — order matters.
- **P04 (bad path):** stderr `Error: Path not found: <path>`, exit `1`. From `require_directory` in `impact.rs:46`.
- **P05 (sarif rejection):** standard validator error, exit `1`.
- **P07 (`-f dot`, 14 lines):** Real Graphviz output with `rankdir=RL` and one edge per caller. **`impact` is one of 6 commands that accept `-f dot`** (per `output.rs::DOT_SUPPORTED`). Useful for piping into `dot -Tpng`.
- **P08 vs P09 (depth 1 vs 10): IDENTICAL OUTPUT.** Verified via `diff` — byte-for-byte the same. **Why:** in this Python codebase, all callers came via the references-enrichment fallback (`enrich_impact_with_references` at `impact.rs:484` in `tldr-core`), which does **not** honor `--depth`. The depth flag governs the call-graph traversal in the primary path, but if the call graph misses cross-file edges (as it does for Python here), the enrichment path adds level-1 callers only and stops. **Agents must understand: `--depth` may be a no-op on Python and on languages flagged in the source comment (C# field-typed, Kotlin/Scala/OCaml functors, Lua qualified names).**
- **P10 (`--file backend/api.py`):** exit `20` with `Error: Function not found: get_db_connection in backend/api.py` — `get_db_connection` is defined in `db.py`, not `api.py`. The `--file` filter restricts where the *target function* is searched, not where its callers are reported. The error **includes "Did you mean:" suggestions** (`get_db_connection`, `open_db_connection`) — agents can parse these for self-recovery.
- **P11 (`--type-aware`):** Exit `0`, output adds a `type_resolution` object with **all zeros**: `enabled: true, resolved_high_confidence: 0, resolved_medium_confidence: 0, fallback_used: 0, total_call_sites: 0`. **Confirms the source comment that this flag is registered but full implementation is pending.** Currently a placeholder — agents should not rely on type-aware results.
- **P12 (fake function name):** exit `20`, `Error: Function not found: zzz_nonexistent_function`. No "Did you mean:" because no close matches.
- **P13 (file passed as PATH):** exit `1`, **very clear error message**: `Error: impact requires a directory; got file 'backend/db.py'. Pass the project root or omit the argument to use the current directory.` This is `require_directory` in `impact.rs:46`, attributed to the `cli-error-clarity-v2 (P2.BUG-4)` upstream improvement.
- **P14 (compact):** single-line JSON, ~3KB.
- **P15 (cold daemon, 70 lines):** Output byte-identical to P01 and P16. Cold-boot fallback in `impact.rs:73-94` rebuilds the call graph from scratch — slower wall-clock time but identical output.
- **P16 (warm daemon, after `tldr warm`):** byte-identical to P15. The daemon route serves the same cached result; the references-enrichment runs over the cached `ImpactReport` in the same way.

---

## Source Code Reality

**Target file:** `crates/tldr-cli/src/commands/impact.rs` (pinned to local clone at `6c4011a`).

**Argument struct (`impact.rs:18-43`):**
```rust
pub struct ImpactArgs {
    pub function: String,                       // required
    #[arg(default_value = ".")]
    pub path: PathBuf,                          // defaults to .
    #[arg(long, short = 'l')]
    pub lang: Option<Language>,
    #[arg(long, short = 'd', default_value = "5")]
    pub depth: usize,                           // default 5
    #[arg(long)]
    pub file: Option<PathBuf>,
    #[arg(long)]
    pub type_aware: bool,
}
```

**Directory enforcement (`impact.rs:46`):**
```rust
require_directory(&self.path, "impact")?;
```
This is the source of P13's clear "requires a directory; got file..." error. The helper lives in `crates/tldr-cli/src/path_validation.rs` and produces the same friendly message for any command that calls it.

**Daemon route (`impact.rs:54-71`):**
```rust
if let Some(report) = try_daemon_route::<ImpactReport>(
    &self.path,
    "impact",
    params_with_func_depth(&self.function, Some(self.depth)),
) { ... }
```
Cache key includes function + depth. **But the enrichment runs only in the direct-compute branch** (lines 88-92) — when the daemon returns a cached `ImpactReport`, the agents see whatever was cached at warm-time. P15 and P16 produced identical output because the cached report itself was constructed from the same compute path.

**References enrichment (when needed, opened to confirm depth hypothesis):**
File: `crates/tldr-core/src/analysis/impact.rs:440-510`
```rust
pub fn enrich_impact_with_references(
    report: &mut ImpactReport,
    project_root: &Path,
    target_func: &str,
    language: Language,
) {
    ...
    let mut options = ReferencesOptions::new();
    options.kinds = Some(vec![ReferenceKind::Call]);
    options.language = Some(language.as_str().to_string());
    options.limit = Some(500);
    ...
}
```
**Hardcoded limit:** 500 references max. **No depth parameter** — this function adds level-1 callers only. Confirms P08/P09 observation: `--depth` is silently bypassed when callers come from the references fallback. The source even notes the languages most affected: Python (cross-file), C# (field-typed methods), Kotlin/Scala/OCaml (functor wrappers), Lua/Luau (qualified names).

**Type-aware placeholder (`impact.rs:99-107`):**
```rust
if self.type_aware {
    report.type_resolution = Some(tldr_core::types::TypeResolutionStats {
        enabled: true,
        resolved_high_confidence: 0,
        resolved_medium_confidence: 0,
        fallback_used: 0,
        total_call_sites: 0,
    });
}
```
**Confirms P11:** the flag injects a placeholder stats object but performs no actual type resolution. The CLI comment says: *"TODO: When type_aware is true, use type-aware call graph building. For now, this flag is registered but type resolution is pending full implementation."*

**Format validator** confirmed at `crates/tldr-cli/src/output.rs::validate_format_for_command` — `impact` is in `DOT_SUPPORTED`, so `-f dot` works (P07 verified).

---

## Architectural Deep Dive

- **Engine:** `build_project_call_graph` constructs a project-wide reverse call graph (callee → callers). `impact_analysis_with_ast_fallback` traverses backward from the target function up to `--depth` levels. **For languages whose call graph builder under-reports cross-file edges (Python, C#, Kotlin, Scala, OCaml, Lua/Luau), the analysis is augmented post-hoc by `enrich_impact_with_references`** — a references-engine lookup that finds call sites the AST traversal missed.
- **Cache layer:** Daemon-backed, keyed on `(path, function, depth)`. Cache invalidation is correct on `--depth` change, but in practice the enrichment fallback often produces identical output across depths anyway.
- **Hardcoded limits:** references-enrichment capped at 500 results per query.
- **Depth semantics:** `--depth N` controls how many levels the call-graph traversal walks. **It does not affect the references-enrichment fallback** (no recursion there). For Python, this often means depth is a no-op.
- **`--type-aware`:** REGISTERED BUT NOT IMPLEMENTED. The flag injects a placeholder `type_resolution` stats object with all zeros. No actual type resolution occurs.
- **LLM cognitive load:** Replaces `grep -rn "func_name(" --include="*.py"` plus manual filtering for actual call-sites vs definitions. Returns structured callers with their own call counts, so the agent can plan a multi-step refactor or assess blast radius before changing a signature.

---

## Intent & Routing

- **User/Agent Goal:** Find all callers of a function (reverse call graph) before changing it — assess blast radius.
- **When to choose this over similar tools:**
  - Use *over* `tldr references <func>` when you want a structured reverse graph (callers of callers), not just a flat list of call sites.
  - Use *over* `tldr calls <func>` — `calls` is the forward direction (what *this* function calls), `impact` is the reverse (what calls *this*).
  - Use *before* changing a function's signature, return type, or removing it.
  - Use *with* `-f dot | dot -Tpng > impact.png` for visualization.
- **Prerequisites:**
  - Function name must be known. Use `tldr extract <file>`, `tldr search <term>`, or `tldr structure <dir>` first to discover it.
  - PATH must be a directory (project root). Files are explicitly rejected with a clear error.
- **Composes well with:**
  - `tldr search "concept"` → pick a function → `tldr impact <func> <dir>` to assess blast radius.
  - `tldr impact <func>` → for each caller in the report, optionally `tldr extract <caller-file>` to see the call site context.

---

## Agent Synthesis

> **How to use `tldr impact`:**
> Use to find all callers of a function (reverse call graph) before changing it. Returns a `targets` map keyed by `"file:function"`, with recursive `callers[]` for each level up to `--depth`. For Python (and several other languages), the underlying call-graph builder misses cross-file edges; `impact` automatically runs a references-enrichment fallback to recover them. Watch for the `"Discovered via references"` note in the output — it tells you which language path was used.
>
> **Crucial Rules:**
> - **`<FUNCTION>` is REQUIRED** — clap error (exit 2) when omitted.
> - **PATH must be a directory.** Passing a file produces a clear error (exit 1): `"impact requires a directory; got file '...'. Pass the project root or omit the argument..."`.
> - **Four distinct exit codes for failures:**
>   - `1` = bad path / file-as-path / format reject
>   - `2` = missing function arg
>   - `20` = function not found (with optional "Did you mean:" suggestions to parse for recovery)
> - **`--depth` may be a no-op on Python and several other languages.** If callers are discovered via references-enrichment (look for the `"Discovered via references"` note), depth is ignored — only level-1 callers are added. The flag still helps on languages with reliable call graphs (Rust, Go, TypeScript).
> - **`--type-aware` is NOT IMPLEMENTED.** It injects a placeholder `type_resolution` stats object with all zeros but performs no actual type resolution. Don't rely on its output. Source: `impact.rs:99-107` (TODO comment).
> - **`--file <path>` filters where the target function is *defined*, not where callers are reported.** If the function is in `db.py` but you pass `--file api.py`, you'll get "Function not found in api.py" (exit 20).
> - **Function-not-found errors include "Did you mean:" suggestions** for close matches — agents should parse these.
> - **`-f dot` is supported** (one of 6 commands that emit Graphviz output). Pipe to `dot -Tpng` for visualization.
> - **DOT output uses `rankdir=RL`** (right-to-left) since this is a reverse call graph.
> - **References-enrichment is capped at 500 results per query** (`impact.rs:457` in `tldr-core`). Functions with massive caller counts may be truncated.
> - **Empty `targets: {}` is exit 0** (legitimate "no callers found").
>
> **Commands:**
> - Default: `tldr impact <function> <dir>`
> - Visualize: `tldr impact <function> <dir> -f dot | dot -Tpng > impact.png`
> - Text-pretty: `tldr impact <function> <dir> -f text`
> - Restricted to a file (function defined there): `tldr impact <function> <dir> --file <path>`
> - Compose: `tldr extract <file>` → pick a function → `tldr impact <function> <dir>` for blast radius
