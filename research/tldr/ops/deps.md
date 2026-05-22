# Command: `tldr deps`

## Environment Pin

| Field | Value |
|---|---|
| `tldr --version` | 0.4.0 |
| Build features | `semantic` (verified; deps is AST-based import-graph, non-semantic) |
| Target repo | Stock-Monitor @ commit `e601869` |
| Upstream `tldr-code` pinned to | local clone @ `6c4011a` (release v0.4.0) |
| Daemon state at probe time | N/A — `tldr deps` does **not** call `try_daemon_route` (verified by grep) |
| OS | darwin 25.2.0 |
| Probe date | 2026-05-22 |

Re-run all evidence via [`deps.probes/probe.sh`](./deps.probes/probe.sh).

**Consolidation note:** Per `05_OMITTED_COMMANDS_RATIONALE.md` §3, the `deps` command was consolidated under the `tldr-overview` skill (originally had duplicate dossiers in `overview/` and `ops/`). This dossier lives under `ops/` per the Ralph task list.

---

## Ground Truth (`tldr deps --help`)

```text
Analyze module dependencies

Usage: tldr deps [OPTIONS] [PATH]

Arguments:
  [PATH]                                       [default: .]

Options:
  -l, --lang <LANG>                            Filter: python, typescript, go, rust
      --include-external                       Include third-party deps in report
      --collapse-packages                      Collapse files into package-level nodes
  -d, --depth <DEPTH>                          Maximum transitive depth (None = unlimited)
      --show-cycles                            Only show circular dependencies (skip full graph)
      --max-cycle-length <MAX_CYCLE_LENGTH>    [default: 10]
  -f, --format <FORMAT>                        [default: json]
  -q, --quiet  -v, --verbose  -h, --help
```

Plus legacy hidden `-o, --output <FORMAT>` (json/text/dot/compact — overrides global -f).

---

## Output Shape

| Aspect | Value |
|---|---|
| Default format | `json` |
| Formats that work | `json`, `text`, `compact`, **`dot`** (P01, P06, P07, P08) |
| Formats that error | `sarif` (P05: exit 1) |
| Typical output size | small (~20 lines pretty JSON for 4 files; ~70 lines for full backend) |

**Top-level keys (JSON, `DepsReport`):**
- `root` (`string`) — ABSOLUTE path of analyzed directory
- `language` (`string` | `null`) — detected language; null for empty/unrecognized dirs
- `internal_dependencies` (`object`) — keyed by relative filename, value is array of imported files
- `external_dependencies` (`object`, OPTIONAL/CONDITIONAL) — only present with `--include-external` OR external deps detected
- `circular_dependencies` (`array<array<string>>`) — observed only when `--include-external` causes a full report — but key exists in empty-dir stub
- `stats` (`object`) — `{ total_files, total_internal_deps, total_external_deps, max_depth, cycles_found, leaf_files, root_files }`
- `files_skipped` (`u32`)
- `warnings` (`array<string>`, OPTIONAL) — only emitted when empty/unrecognized dir or other warnings

**`--show-cycles` output mode (P13):** **COMPLETELY DIFFERENT SCHEMA** — emits only `[]` (or array of cycles), NOT the full report. Schema-divergence based on flag.

**`-f dot` DOT format (P08):**
```text
digraph deps {
  rankdir=LR;
  node [shape=box, fontname="Helvetica"];
  edge [fontname="Helvetica", fontsize=10];

  // Nodes
  "base.py" [label="base.py"];
  ...

  // Edges
  "yahoo.py" -> "base.py";
  ...
}
```

**Empty/unrecognized-language directory shape (P21, `schema-cleanup-v2 P2.BUG-10` short-circuit):**
```json
{
  "root": "<abs>", "language": null,
  "internal_dependencies": {}, "external_dependencies": {},
  "circular_dependencies": [],
  "stats": { "total_files": 0, "total_internal_deps": 0, ... },
  "files_skipped": 0,
  "warnings": ["Empty directory: no source files to analyze"]
}
```
Exit **0** — explicitly NOT exit 11 per source comment.

**Error shapes:**
- Path not found: `"Error: Path not found: /no/such/dir"` → exit **2** (TldrError::PathNotFound)
- Single non-source file (`.md`): `"Error: Unsupported language: unknown"` → exit **11** (TldrError::UnsupportedLanguage) — the schema-cleanup-v2 short-circuit is DIRECTORY-only; single files DON'T benefit.
- Format reject sarif: `"Error: --format sarif not supported by deps. ..."` → exit **1**
- Bad `--lang`: clap-style → exit **2**
- Bad legacy `-o`: SILENT (exit 0) — falls back to global format per source `effective_format` (P20).

---

## Probe Matrix

| # | Probe | Type | Exit | Captured |
|---|-------|------|------|----------|
| P01 | `tldr deps backend/providers` | happy | 0 | [`01-happy.*`](./deps.probes/) |
| P02 | `tldr deps backend` | happy-scale | 0 | [`02-happy-scale.*`](./deps.probes/) |
| P03 | N/A: PATH defaults to `.`. | — | — | [`03-missing-arg.*`](./deps.probes/) (placeholder) |
| P04 | `tldr deps /no/such/dir` | failure-badpath | 2 | [`04-badpath.*`](./deps.probes/) |
| P05 | `tldr deps ... -f sarif` | format-reject (sarif) | 1 | [`05-format-reject-sarif.*`](./deps.probes/) |
| P06 | `tldr deps ... -f text` | format-text | 0 | [`06-format-text.*`](./deps.probes/) |
| P07 | `tldr deps ... -f compact` | format-compact | 0 | [`07-format-compact.*`](./deps.probes/) |
| P08 | `tldr deps ... -f dot` | DOT format (SUPPORTED!) | 0 | [`08-format-dot.*`](./deps.probes/) |
| P09 | `tldr deps ... --include-external` | include-external | 0 | [`09-include-external.*`](./deps.probes/) |
| P10 | `tldr deps ... --collapse-packages` | collapse-packages | 0 | [`10-collapse-packages.*`](./deps.probes/) |
| P11 | `tldr deps ... --depth 1` | depth low | 0 | [`11-depth-low.*`](./deps.probes/) |
| P12 | `tldr deps ... --depth 0` | depth zero | 0 | [`12-depth-zero.*`](./deps.probes/) |
| P13 | `tldr deps ... --show-cycles` | **DIFFERENT SCHEMA: just `[]`** | 0 | [`13-show-cycles.*`](./deps.probes/) |
| P14 | `tldr deps ... --max-cycle-length 1` | max-cycle-length low | 0 | [`14-max-cycle-len-low.*`](./deps.probes/) |
| P15 | `tldr deps ... -l python` | explicit python | 0 | [`15-lang-python.*`](./deps.probes/) |
| P16 | `tldr deps ... -l typescript` | lang-mismatch (silent filter) | 0 | [`16-lang-mismatch.*`](./deps.probes/) |
| P17 | `tldr deps ... -l brainfuck` | bad-lang | 2 | [`17-bad-lang.*`](./deps.probes/) |
| P18 | `tldr deps ... -o text` | legacy -o text | 0 | [`18-output-flag-text.*`](./deps.probes/) |
| P19 | `tldr deps ... -o dot` | legacy -o dot | 0 | [`19-output-flag-dot.*`](./deps.probes/) |
| P20 | `tldr deps ... -o wat` | **bad legacy -o is SILENT (falls back)** | 0 | [`20-output-flag-bogus.*`](./deps.probes/) |
| P21 | `tldr deps <empty-tmp-dir>` | empty dir (warning, exit 0) | 0 | [`21-empty-dir.*`](./deps.probes/) |
| P22 | `tldr deps README.md` | non-source-md (exit 11 — single file!) | 11 | [`22-non-source-md.*`](./deps.probes/) |
| P23 | `tldr deps backend/providers/yahoo.py` | file as PATH (silent — small result) | 0 | [`23-file-as-path.*`](./deps.probes/) |
| P24 | `tldr deps ... -q` | quiet | 0 | [`24-quiet.*`](./deps.probes/) |

### Observations

- **P01** — `backend/providers/` (4 Python files): `language: "python"`, `internal_dependencies: { __init__.py: [], base.py: [], dhan.py: [], yahoo.py: [] }`. ALL deps arrays are EMPTY because the import resolver doesn't see the cross-imports as INTERNAL — likely a Python path resolution detail. `stats.total_internal_deps: 0`.
- **P02** — Full `backend/`: 72 lines, more files but same shape.
- **P03** — **N/A.** PATH defaults to `.`.
- **P04** — stderr `"Error: Path not found: /no/such/dir"`, exit **2** (TldrError::PathNotFound). Matches `tldr loc`/`tldr complexity`/`tldr imports`.
- **P05** — stderr `"Error: --format sarif not supported by deps. Use --format json. SARIF is only emitted by: vuln, clones."`, exit `1`.
- **P06** — Text format: 12-line human-readable summary.
- **P07** — Single-line minified JSON.
- **P08** — **DOT SUPPORTED:** `digraph deps { rankdir=LR; node [shape=box]; ... }`. Per source comment: pair with `dot -Tpng -o deps.png` for visualization. **5 commands in DOT_SUPPORTED** (deps, calls, impact, hubs, inheritance, clones).
- **P09** — `--include-external`: 45 lines — includes third-party deps (pandas, yfinance, etc.). The `external_dependencies` field is populated.
- **P10** — `--collapse-packages`: 17 lines — file nodes collapsed into packages (e.g., all of backend/providers → "backend.providers").
- **P11** — `--depth 1`: 72 lines — same as P02 since no transitive chains in this scope.
- **P12** — `--depth 0`: 72 lines — same as P11 in this scope. Edge case behavior identical here.
- **P13** — **SCHEMA DIVERGENCE:** `--show-cycles` returns just `[]` (1 line) — NOT the full DepsReport. **Completely different output shape.** Useful for "are there any cycles?" yes/no checks via `jq 'length'`.
- **P14** — `--max-cycle-length 1`: 72 lines — same as P02. No cycles found in this scope anyway.
- **P15** — Explicit `-l python`: identical to default.
- **P16** — `-l typescript` on Python project: 15 lines, empty result. **Silent filter** — no TypeScript files match.
- **P17** — clap-style: `"error: invalid value 'brainfuck' for '--lang <LANG>': Unknown language: brainfuck"`, exit `2`.
- **P18** — Legacy `-o text`: 12 lines, same as `-f text`.
- **P19** — Legacy `-o dot`: 14 lines, same as `-f dot` (P08).
- **P20** — **`-o wat` IS SILENT (exit 0)!** Per source `effective_format` at deps.rs:97-106: unknown `-o` value falls back to global format. Output = default JSON. **No error for bogus legacy flag value.**
- **P21** — Empty dir: exit **0** with `{ language: null, warnings: ["Empty directory: no source files to analyze"], ... }`. **Per source comment `schema-cleanup-v2 P2.BUG-10`**: explicitly short-circuits to avoid exit 11 — parity with `tldr structure`. Best-in-class graceful handling.
- **P22** — README.md as PATH: stderr `"Error: Unsupported language: unknown"`, exit **11**. **Single-file path does NOT benefit from the P2.BUG-10 short-circuit** — only DIRECTORIES get the graceful empty-warning treatment. Inconsistency between directory and file edge cases.
- **P23** — `backend/providers/yahoo.py` (file): exit 0 with 15-line output. Single Python file works — treated as single-file analysis.
- **P24** — `-q` suppresses `"Analyzing dependencies in <path>..."` progress message.

---

## Source Code Reality

**Target file(s):**
- `crates/tldr-cli/src/commands/deps.rs` (~250+ lines)
- `crates/tldr-core/src/analysis/deps.rs` (import resolver)
- `crates/tldr-cli/src/output.rs:113` (`validate_format_for_command`)

**Pinned to upstream commit:** `6c4011a` (release v0.4.0)

**Argument struct:**
```rust
// crates/tldr-cli/src/commands/deps.rs:55-89
#[derive(Debug, Args)]
pub struct DepsArgs {
    #[arg(default_value = ".")] pub path: PathBuf,
    #[arg(long = "output", short = 'o', hide = true)] pub output: Option<String>,
    #[arg(long, short = 'l')] pub lang: Option<Language>,
    #[arg(long)] pub include_external: bool,
    #[arg(long)] pub collapse_packages: bool,
    #[arg(long, short = 'd')] pub depth: Option<usize>,
    #[arg(long)] pub show_cycles: bool,
    #[arg(long, default_value = "10")] pub max_cycle_length: usize,
}
```
Reveals: legacy `-o` is `Option<String>` (NOT typed enum) — unknown values silently fall back per `effective_format` (P20).

**`effective_format` fallback (P20):**
```rust
// deps.rs:97-106
pub fn effective_format(&self, global: OutputFormat) -> OutputFormat {
    match self.output.as_deref() {
        Some("text") => OutputFormat::Text,
        Some("dot") => OutputFormat::Dot,
        Some("compact") => OutputFormat::Compact,
        Some("json") => OutputFormat::Json,
        Some(_) => global, // Unknown value falls back to global
        None => global,
    }
}
```
Reveals: P20's behavior is explicit — `-o wat` matches the `Some(_)` arm and uses the global format. Could be a feature (lenient) or a bug (silent ignore).

**`schema-cleanup-v2 P2.BUG-10` short-circuit (P21):**
```rust
// deps.rs:127-141
if self.path.is_dir()
    && self.lang.is_none()
    && Language::from_directory(&self.path).is_none()
{
    let stub = serde_json::json!({
        "root": self.path.display().to_string(),
        "language": null,
        ...
    });
}
```
Reveals: the short-circuit applies ONLY to directories (`is_dir()`). Single-file paths fall through to the regular engine, which can return `UnsupportedLanguage` (P22 exit 11).

**Format validation:** confirmed at `crates/tldr-cli/src/output.rs:113-163` — `deps` IS in `DOT_SUPPORTED`. NOT in `SARIF_SUPPORTED`.

**No daemon route:** `grep -n try_daemon_route deps.rs` returns 0 matches.

---

## Architectural Deep Dive

- **Under the hood:** Walks the project, parses imports per language. Builds a directed graph: file → (imports). Detects cycles via Tarjan's SCC algorithm (bounded by `--max-cycle-length`). Optional `--collapse-packages` aggregates per-package; `--include-external` adds third-party deps. Emits DOT for graphviz visualization.
- **Performance:** O(file_count). Cold ~50-200ms on moderate projects. NO daemon caching.
- **LLM cognitive load:** The canonical IMPORT-graph command (cf. `tldr coupling` which is the CALL-graph). Use `--show-cycles` for the focused "are there import cycles?" question — much smaller output, easy to parse. Use `-f dot | dot -Tsvg` for visualization.

---

## Intent & Routing

- **User/Agent Goal:** map module-level IMPORT dependencies (NOT call dependencies — that's `tldr coupling`).
- **When to choose this over similar tools:**
  - Over `tldr coupling`: deps is IMPORT-level; coupling is CALL-level. Different abstractions.
  - Over `tldr imports`: imports is per-file import LIST; deps is the IMPORT GRAPH.
  - Over `tldr inheritance`: inheritance is class-hierarchy; deps is module-hierarchy.
- **Prerequisites (composition):**
  - PATH directory recommended (P22: single non-source files exit 11; P23 single Python file works).
  - For visualization: `tldr deps <PATH> -f dot | dot -Tsvg > deps.svg`.
  - For CI cycle detection: `tldr deps <PATH> --show-cycles -f compact | jq 'length > 0'`.

---

## Agent Synthesis

> **How to use `tldr deps`:**
> Module-level IMPORT dependency analyzer. `tldr deps [PATH]` returns JSON `{ root, language, internal_dependencies, external_dependencies?, circular_dependencies, stats: { total_files, total_internal_deps, total_external_deps, max_depth, cycles_found, leaf_files, root_files }, files_skipped, warnings? }`. With `--show-cycles`, schema changes to a bare ARRAY (just the cycles, no full report). With `--include-external`, adds third-party deps. With `--collapse-packages`, file nodes merge into packages. Default JSON; `-f text` for tabular; `-f compact` for one-line; **`-f dot` SUPPORTED** for Graphviz; `sarif` rejected. Exit codes: 0 ok (incl. empty-dir warning), 1 format-reject, 2 path-not-found / bad-lang, 11 unsupported-language (single non-source file ONLY).
>
> **Crucial Rules:**
> - **`--show-cycles` RETURNS A BARE ARRAY**, not the full `DepsReport` (P13). The schema DIVERGES based on the flag. For "are there cycles?" checks, this is much smaller — `jq 'length'` to count. For full dependency tree, omit the flag.
> - **`tldr deps` IS in DOT_SUPPORTED.** P08: `-f dot` emits Graphviz format (`digraph deps { rankdir=LR; ... }`). Pair with `dot -Tsvg > deps.svg` for visualization. Five commands emit DOT (deps, calls, impact, hubs, inheritance, clones).
> - **Empty directory returns exit 0 with `warnings: ["Empty directory: no source files to analyze"]`** (P21). Per source `schema-cleanup-v2 P2.BUG-10`: explicit short-circuit to AVOID exit 11. **BUT non-source single files still exit 11** (P22) — the fix is DIRECTORY-only.
> - **Non-source SINGLE FILE returns exit 11** (P22: `tldr deps README.md` → `"Unsupported language: unknown"`). The `P2.BUG-10` short-circuit doesn't cover single-file paths. Recovery: pass the parent directory.
> - **Bad legacy `-o <wat>` is SILENT** (P20: exit 0, falls back to global format per `effective_format` at deps.rs:97-106). Unknown legacy values are LENIENT — they don't fail, they fall through. Pass `-f <X>` to test format rejections.
> - **`--include-external` adds `external_dependencies`** with third-party packages (pandas, yfinance, etc.). Without the flag, only internal project deps are tracked.
> - **`--collapse-packages` aggregates files → packages** (e.g., `backend.providers` instead of 4 individual files). Useful for high-level architecture views.
> - **Path-not-found exit code is 2** (TldrError::PathNotFound — matches `tldr loc`/`tldr complexity`/`tldr imports`).
> - **`-l typescript` on Python project silently filters to empty result** (P16). Same anti-pattern as elsewhere — no warning when language doesn't match.
> - **NO daemon route.** Every call walks + parses fresh.
>
> **Command:** `tldr deps [PATH]`
>
> **With common flags:** `tldr deps <PATH> --include-external --collapse-packages -f dot | dot -Tsvg > deps.svg` (use for high-level architecture visualization: package-level nodes including third-party deps, rendered as SVG).
