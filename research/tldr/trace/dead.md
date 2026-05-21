# Command: `tldr dead`

## Environment Pin

| Field | Value |
|---|---|
| `tldr --version` | 0.4.0 |
| Build features | `semantic` (verified; dead itself is non-semantic) |
| Target repo | Stock-Monitor @ commit `e601869` |
| Upstream `tldr-code` pinned to | local clone @ `6c4011a` (release v0.4.0) |
| Daemon state at probe time | mixed (P17 cold, P18/P19 warm) |
| OS | darwin 25.2.0 |
| Probe date | 2026-05-22 |

Re-run all evidence via [`dead.probes/probe.sh`](./dead.probes/probe.sh).

---

## Ground Truth (`tldr dead --help`)

```text
Find dead (unreachable) code

Usage: tldr dead [OPTIONS] [PATH]

Arguments:
  [PATH]
          Project root directory (default: current directory)

          [default: .]

Options:
  -l, --lang <LANG>
          Programming language

  -e, --entry-points <ENTRY_POINTS>
          Custom entry point patterns (comma-separated)

      --max-items <MAX_ITEMS>
          Maximum number of dead functions to display

          [default: 100]

      --call-graph
          Use call-graph-based analysis instead of the default reference counting

      --no-default-ignore
          Walk vendored/build dirs (node_modules, target, dist, etc.) that would normally be skipped

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
| Formats that work | `json`, `text`, `compact` (P01, P06, P07) |
| Formats that error | `sarif`, `dot` (P05, P08: exit 1) |
| Typical output size | small (<2 KB for small subdir) to heavy (~50 KB for full project with truncation) |

**Top-level keys (JSON, `DeadCodeOutput` = `DeadCodeReport` flattened + `truncated`):**
- `dead_functions` (`array<DeadFunctionInfo>`) — definitively dead (zero references at all)
- `possibly_dead` (`array<DeadFunctionInfo>`) — single-reference functions (only their own definition site)
- `by_file` (`object<file, array<DeadFunctionInfo>>`) — same data grouped by file path
- `total_dead` (`usize`) — count of `dead_functions` (full count, NOT post-truncation)
- `total_possibly_dead` (`usize`) — count of `possibly_dead` (full count)
- `functions_analyzed` (`usize`) — total functions scanned
- `total_functions` (`usize`) — duplicate of `functions_analyzed` (legacy compat per schema-cleanup-v1)
- `dead_percentage` (`float64`) — `total_dead / total_functions × 100`, rounded to 2 dp
- `truncated` (`bool`, **only present when true**) — added at top-level by the CLI wrapper when `total_dead + total_possibly_dead > --max-items` (P09 only)

**`DeadFunctionInfo` shape:**
- `file` (`string`) — relative path
- `name` (`string`) — function name (qualified for methods)
- `line` (`u32`, 1-indexed)
- `signature` (`string`)
- `ref_count` (`usize`) — number of identifier references found across the scanned source (refcount mode only)
- `is_public` (`bool`) — visibility flag
- `is_test` (`bool`) — heuristic test detection
- `is_trait_method` (`bool`) — for Rust trait impls
- `has_decorator` (`bool`) — true when function has any decorator/annotation (skips false-positives like `@app.route`)

**Empty-result shape (P15, empty dir):**
```json
{
  "dead_functions": [],
  "possibly_dead": [],
  "by_file": {},
  "total_dead": 0,
  "total_possibly_dead": 0,
  "functions_analyzed": 0,
  "total_functions": 0,
  "dead_percentage": 0.0
}
```
Exit 0. NO `truncated` key when nothing was truncated.

**Error shapes:**
- Path not found: `"Error: Path not found: /no/such/dir"` → exit **1** (anyhow!)
- Format reject: `"Error: --format sarif not supported by dead. Use --format json. SARIF is only emitted by: vuln, clones."` → exit **1**
- Bad `--lang`: clap-style `"error: invalid value 'X' for '--lang <LANG>': Unknown language: X"` → exit **2**

---

## Probe Matrix

| # | Probe | Type | Exit | Captured |
|---|-------|------|------|----------|
| P01 | `tldr dead backend/providers -l python` | happy | 0 | [`01-happy.*`](./dead.probes/) |
| P02 | `tldr dead backend -l python` | happy-scale | 0 | [`02-happy-scale.*`](./dead.probes/) |
| P03 | N/A: PATH defaults to `.`, no required positional. | — | — | [`03-missing-arg.*`](./dead.probes/) (placeholder triple) |
| P04 | `tldr dead /no/such/dir` | failure-badpath | 1 | [`04-badpath.*`](./dead.probes/) |
| P05 | `tldr dead ... -f sarif` | format-reject (sarif) | 1 | [`05-format-reject-sarif.*`](./dead.probes/) |
| P06 | `tldr dead ... -f text` | format-text | 0 | [`06-format-text.*`](./dead.probes/) |
| P07 | `tldr dead ... -f compact` | format-compact | 0 | [`07-format-compact.*`](./dead.probes/) |
| P08 | `tldr dead ... -f dot` | format-reject (dot) | 1 | [`08-format-reject-dot.*`](./dead.probes/) |
| P09 | `tldr dead backend ... --max-items 1` | truncation | 0 | [`09-max-items-small.*`](./dead.probes/) |
| P10 | `tldr dead backend ... --max-items 99999` | no-truncation | 0 | [`10-max-items-large.*`](./dead.probes/) |
| P11 | `tldr dead ... --call-graph` | legacy-call-graph mode | 0 | [`11-call-graph-mode.*`](./dead.probes/) |
| P12 | `tldr dead ... --entry-points fetch_historical_data,fetch_quotes` | entry-points (no-op for this scope) | 0 | [`12-entry-points.*`](./dead.probes/) |
| P13 | `tldr dead ... --no-default-ignore` | walk-vendored | 0 | [`13-no-default-ignore.*`](./dead.probes/) |
| P14 | `tldr dead -l brainfuck` | bad-lang | 2 | [`14-bad-lang.*`](./dead.probes/) |
| P15 | `tldr dead <empty-tmp-dir>` | empty-dir | 0 | [`15-empty-dir.*`](./dead.probes/) |
| P16 | `tldr dead ... -q` | quiet | 0 | [`16-quiet.*`](./dead.probes/) |
| P17 | `tldr dead backend -l python` *(cold)* | cold-daemon | 0 | [`17-cold-daemon.*`](./dead.probes/) |
| P18 | `tldr dead backend -l python` *(warm)* | warm-daemon | 0 | [`18-warm-daemon.*`](./dead.probes/) |
| P19 | `tldr dead ... --call-graph` *(warm)* | warm-daemon-call-graph | 0 | [`19-warm-daemon-call-graph.*`](./dead.probes/) |

### Observations

- **P01** — `backend/providers/` (4 files): `functions_analyzed: 23`, `total_dead: 0`, `total_possibly_dead: 1` (`get_yahoo_provider` at `__init__.py:26`, ref_count=1). `dead_percentage: 0.0`. `by_file: {}` (empty because no truly dead functions in this small scope).
- **P02** — Full `backend/` (~56 Python files): `functions_analyzed: 1286`, `total_dead: 8`, `total_possibly_dead: 21`, `dead_percentage: 0.62`. ~346 lines stdout — `by_file` populated when there's at least one truly-dead function.
- **P03** — **N/A.** `DeadArgs.path` defaults to `.`, no required positional.
- **P04** — stderr `"Error: Path not found: /no/such/dir"`, exit `1` (anyhow!). Same convention as `tldr calls`.
- **P05** — stderr `"Error: --format sarif not supported by dead. Use --format json. SARIF is only emitted by: vuln, clones."`, exit `1`.
- **P06** — Text format renders a brief summary header. Progress messages on stderr: `"Scanning backend/providers (Python) with reference counting..."` and `"Analyzing dead code (refcount)..."`.
- **P07** — Single-line minified JSON, same schema as P01.
- **P08** — stderr `"Error: --format dot not supported by dead. Use --format json. DOT is only emitted by: clones, deps, calls, impact, hubs, inheritance."`, exit `1`. **Notable:** despite `dead` returning a graph-like result, it's NOT in `DOT_SUPPORTED` — only graph commands (`calls`, `impact`, `deps`, `hubs`, `inheritance`, `clones`) emit DOT.
- **P09** — `--max-items 1` produces `total_dead: 8`, `total_possibly_dead: 21`, **and a top-level `truncated: true` key** added by the CLI wrapper. The arrays are truncated, but `total_*` counts reflect the UNTRUNCATED totals.
- **P10** — `--max-items 99999` returns the full result, no `truncated` key.
- **P11** — `--call-graph` switches to legacy analysis. On the small `backend/providers/` scope, **byte-identical totals to refcount mode (P01)** (`total_possibly_dead: 1`, same get_yahoo_provider). On larger codebases the two modes can diverge (refcount is faster but less precise about indirect calls).
- **P12** — `--entry-points fetch_historical_data,fetch_quotes` produces output **identical to P01** in this scope because neither entry point was a "possibly_dead" candidate (those are class methods with multiple call sites). `--entry-points` only affects functions that would otherwise be marked dead. **Recovery hint:** to actually prune false-positives, pass the names of the symbols that DO appear in `possibly_dead` output (verified with separate test: `--entry-points get_yahoo_provider` removes it from possibly_dead).
- **P13** — `--no-default-ignore` produces output **identical to P01** for this Stock-Monitor scope because `backend/providers/` has no `__pycache__` or `node_modules`. The flag would diverge from default on larger codebases with vendored dirs.
- **P14** — clap-style: `"error: invalid value 'brainfuck' for '--lang <LANG>': Unknown language: brainfuck"`, exit `2`.
- **P15** — Empty dir: all zero counts, exit 0. Note: `language` field is NOT in the output schema (unlike `tldr calls` which exposes language: null for empty dirs). So **empty-dir results from `dead` cannot be distinguished from "0 dead functions in N files" just by the JSON shape** — you must inspect `functions_analyzed`.
- **P16** — `-q` suppresses stderr progress; stdout JSON unaffected.
- **P17, P18** — Cold (P17) and warm (P18) daemon outputs are **byte-identical** (same totals).
- **P19** — Warm daemon + `--call-graph`: produces the same output as P11 (cold + --call-graph) on this scope. **Important caveat:** `params_for_dead` (`daemon_router.rs:params_for_dead`) forwards `path` and `entry_points` but **NOT `call_graph`**. So in theory the daemon path may use whichever analysis mode it was configured with at startup, ignoring the CLI flag. For the small probe scope, both modes converge anyway. For larger codebases, `--call-graph` may NOT propagate to the daemon path — verify with absolute totals if precision matters.

---

## Source Code Reality

**Target file(s):**
- `crates/tldr-cli/src/commands/dead.rs` (535 lines)
- `crates/tldr-core/src/analysis/dead.rs` (refcount + call-graph analyzers)
- `crates/tldr-cli/src/commands/daemon_router.rs` (`params_for_dead`)
- `crates/tldr-core/src/types.rs` (`DeadCodeReport`, `DeadFunctionInfo`)
- `crates/tldr-cli/src/output.rs:113` (`validate_format_for_command`)

**Pinned to upstream commit:** `6c4011a` (release v0.4.0)

**Argument struct:**
```rust
// crates/tldr-cli/src/commands/dead.rs:33-58
#[derive(Debug, Args)]
pub struct DeadArgs {
    #[arg(default_value = ".")] pub path: PathBuf,
    #[arg(long, short = 'l')] pub lang: Option<Language>,
    #[arg(long, short = 'e', value_delimiter = ',')]
    pub entry_points: Vec<String>,
    #[arg(long, default_value = "100")] pub max_items: usize,
    #[arg(long)] pub call_graph: bool,
    #[arg(long)] pub no_default_ignore: bool,
}
```
Reveals: `entry_points` uses `value_delimiter = ','` so a single `--entry-points a,b,c` is parsed as 3 items. `call_graph` and `no_default_ignore` are simple boolean flags (no `=value` syntax — same gotcha as `tldr calls`'s `--respect-ignore`, but here the flags default to `false` so they're properly toggle-on).

**Path validation:**
```rust
// dead.rs:66-69
if !self.path.exists() {
    anyhow::bail!("Path not found: {}", self.path.display());
}
```
Same anyhow-bail pattern → exit 1.

**Language detection — same mixed-language pitfall:**
```rust
// dead.rs:72-74
let language = self
    .lang
    .unwrap_or_else(|| Language::from_directory(&self.path).unwrap_or(Language::Python));
```
Reveals: `unwrap_or(Language::Python)` fires only when `from_directory` returns None. On mixed-language roots, `from_directory` may pick the wrong language silently. Same issue as `tldr importers` (P19/P20).

**Two analysis modes:**
```rust
// dead.rs:120-154 (excerpt)
let report = if self.call_graph {
    // Legacy call-graph analysis
    let graph = build_project_call_graph(&self.path, language, None, true)?;
    let module_infos = collect_module_infos(&self.path, language, self.no_default_ignore);
    let all_functions: Vec<FunctionRef> = collect_all_functions(&module_infos);
    dead_code_analysis(&graph, &all_functions, entry_points_for_analysis.as_deref())?
} else {
    // Default: reference counting
    let (module_infos, merged_ref_counts) =
        collect_module_infos_with_refcounts(&self.path, language, self.no_default_ignore);
    let all_functions: Vec<FunctionRef> = collect_all_functions(&module_infos);
    dead_code_analysis_refcount(&all_functions, &merged_ref_counts,
        entry_points_for_analysis.as_deref())?
};
```
Reveals: refcount is now the default (single-pass identifier count); call-graph is legacy (builds project graph first, more precise but slower). Both apply the same `--entry-points` filter.

**Framework-directive opt-out:**
```rust
// dead.rs:184-213 (excerpt)
fn source_has_framework_directive(source: &str, ext: &str) -> bool {
    if !matches!(ext, "ts" | "tsx" | "js" | "jsx" | "mjs") { return false; }
    for line in source.lines().take(5) {
        let trimmed = line.trim();
        if trimmed == r#""use server""# || ... { return true; }
        ...
    }
    false
}
```
Reveals: JS/TS files with `'use server'`/`'use client'` directives have ALL their functions/methods tagged with `use_server_directive` decorator, which the analyzer treats as a Next.js/Server-Action entry point. Otherwise these functions (only called by the framework, never by other source code) would falsely appear dead.

**TypeScript declaration-file skip:**
```rust
// dead.rs:246-248
fn is_typescript_declaration_file(path: &Path) -> bool {
    path.to_string_lossy().to_ascii_lowercase().ends_with(".d.ts")
}
```
Reveals: `.d.ts` files contain only ambient declarations, not executable code. Including them caused false "possibly_dead" for every declared symbol (M6 fix from inheritance-and-dead-cleanup-v1).

**`MAX_FILES = 10_000` guardrail:**
```rust
// dead.rs:14-18
const MAX_FILES: usize = 10_000;
```
Reveals: prevents runaway scans on massive monorepos. The walker stops at this cap (so dead-code analysis on giant projects may be incomplete).

**Daemon route forwards entry_points but NOT call_graph:**
```rust
// dead.rs:83-86
if let Some(report) = try_daemon_route::<DeadCodeReport>(
    &self.path, "dead",
    params_for_dead(Some(&self.path), entry_points.as_deref()),  // <-- no call_graph
) { ... }
```
Reveals: the daemon path is invoked with `path` + `entry_points` only. The daemon decides analysis mode internally (probably defaults to whichever was configured). `--call-graph` on a warm-daemon call may NOT propagate.

**Format validation:** confirmed at `crates/tldr-cli/src/output.rs:113-163` — `dead` is in neither `SARIF_SUPPORTED` nor `DOT_SUPPORTED`.

---

## Architectural Deep Dive

- **Under the hood:** Two analyzers. (1) **Refcount (default):** count identifier occurrences across all source files; functions with 1 reference (their own definition) → `possibly_dead`; 0 references → `dead_functions`. (2) **Call-graph:** build the project call graph; functions not reachable from entry points → dead. Refcount is single-pass and fast; call-graph is more precise but builds the full graph (~10x slower).
- **Performance:** Cold ~3-5s on Stock-Monitor backend; warm sub-200ms via daemon. The MAX_FILES=10_000 cap is the safety net for runaway scans.
- **LLM cognitive load:** Replaces "find functions never called" — particularly useful for refactoring (delete safely) and onboarding (identify legacy code paths). The `possibly_dead`/`dead_functions` distinction is crucial: `possibly_dead` may be export-only API or called via reflection; `dead_functions` are zero-reference (excluding heuristic entry points).

---

## Intent & Routing

- **User/Agent Goal:** "what code can I safely delete?" — enumerate functions that appear unused project-wide.
- **When to choose this over similar tools:**
  - Over `tldr references <fn>`: `references` answers "who calls X?"; `dead` flips the question to "what isn't called?". Use `dead` to discover candidates, `references` to verify.
  - Over `tldr calls`: `calls` returns the full graph; `dead` extracts the unreachable subset. Both modes share the engine.
  - Over manual `grep`: handles entry-point heuristics, framework-directive opt-outs (`'use server'`), `.d.ts` skip, decorators that mark "not actually dead" (e.g. `@app.route`).
- **Prerequisites (composition):**
  - For false-positive pruning, pass `--entry-points <fn1>,<fn2>,...` for symbols called externally (e.g., main scripts, CLI handlers, plugin entry points).
  - For mixed-language roots, supply `-l <lang>` (auto-detect can pick the wrong language on Python+TS projects).
  - For confirmation of "possibly_dead": pass each name to `tldr references <fn>` to see actual call sites.

---

## Agent Synthesis

> **How to use `tldr dead`:**
> Project-wide unreachable-code detector. `tldr dead [PATH]` returns JSON with `dead_functions` (zero refs), `possibly_dead` (single ref = definition only), `by_file`, totals, and `dead_percentage`. Default mode is refcount (single-pass identifier counting); `--call-graph` switches to graph-based reachability (slower, more precise). `--entry-points name1,name2,...` marks names as never-dead (comma-delimited). `--max-items` truncates the displayed lists; truncation adds a `truncated: true` top-level key. Exit codes: 0 ok (including 0-dead result), 1 path-not-found / format-reject, 2 bad `--lang` / `--max-items` clap rejection.
>
> **Crucial Rules:**
> - **`possibly_dead` ≠ definitively dead.** It means "exactly one identifier reference found in the codebase" — that one reference is the function's own definition. Public API exports, reflection-called code, framework callbacks, and decorated functions may legitimately have ref_count=1. Always verify with `tldr references <name>` before deleting.
> - **`--entry-points` accepts exact NAME matches, NOT regex/glob.** Passing `--entry-points main,handler` whitelists symbols literally named `main` or `handler`. For the change to be visible, the names must ALREADY appear in `possibly_dead`/`dead_functions` output. P12 was a no-op because the passed names weren't in the dead set.
> - **`'use server'` / `'use client'` directives auto-pin all functions in the file.** `.ts/.tsx/.js/.jsx/.mjs` files with these directives in the first 5 lines have every function/method tagged with `use_server_directive`, making them entry points. Don't be surprised when Next.js server actions are missing from dead-code results.
> - **`.d.ts` files are silently skipped** (M6 fix). Declarations don't count as definitions. If you need to audit them, use `tldr extract <file.d.ts>` directly.
> - **`MAX_FILES = 10_000` is a hard cap.** Massive monorepos may have incomplete dead-code results; the walker stops at 10k files. Scope analysis to subdirs for full coverage on giant projects.
> - **Daemon path may ignore `--call-graph`.** `params_for_dead` forwards `path` and `entry_points` only — analysis mode is decided daemon-side. To force a specific mode reliably, stop the daemon (`tldr daemon stop`) and let direct-compute run.
> - **`truncated` is only present when true.** Default-100 max-items is usually fine, but with `--max-items 1` you'll see `truncated: true` added to the top-level. `total_dead`/`total_possibly_dead` always reflect the UNTRUNCATED totals — use them for accurate counts.
> - **Empty dir vs "0 dead" indistinguishable from shape alone.** `dead` doesn't expose `language: null` like `calls` does. Inspect `functions_analyzed`: 0 means empty dir / wrong language detection; >0 means clean codebase.
> - **`--no-default-ignore` walks vendored dirs.** `node_modules`, `target`, `dist`, etc. Useful for auditing third-party code in your repo; usually NOT what you want for refactoring.
>
> **Command:** `tldr dead [PATH] -l <lang>`
>
> **With common flags:** `tldr dead <PATH> -l <lang> --entry-points main,handler,plugin_init --max-items 200 -f compact` (use to filter known entry points; then pipe to `jq '.possibly_dead[]'` for review).
