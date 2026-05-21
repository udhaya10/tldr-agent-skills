# Command: `tldr inheritance`

## Environment Pin

| Field | Value |
|---|---|
| `tldr --version` | 0.4.0 |
| Build features | `semantic` (verified; inheritance itself is AST-based, non-semantic) |
| Target repo | Stock-Monitor @ commit `e601869` |
| Upstream `tldr-code` pinned to | local clone @ `6c4011a` (release v0.4.0) |
| Daemon state at probe time | N/A — `tldr inheritance` does **not** call `try_daemon_route` (verified by grep) |
| OS | darwin 25.2.0 |
| Probe date | 2026-05-22 |

Re-run all evidence via [`inheritance.probes/probe.sh`](./inheritance.probes/probe.sh).

---

## Ground Truth (`tldr inheritance --help`)

```text
Extract class inheritance hierarchies

Usage: tldr inheritance [OPTIONS] [PATH]

Arguments:
  [PATH]
          Path to file or directory to analyze (default: current directory)

          [default: .]

Options:
  -l, --lang <LANG>
          Programming language (auto-detect if not specified)

  -c, --class <CLASS>
          Focus on specific class (shows ancestors + descendants)

  -d, --depth <DEPTH>
          Limit traversal depth (requires --class)

      --no-patterns
          Skip ABC/Protocol/mixin/diamond detection

      --no-external
          Skip external base resolution

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
| Typical output size | medium (~200 lines pretty JSON for a Provider hierarchy) |

**Top-level keys (JSON, `InheritanceReport`):**
- `edges` (`array<Edge>`) — parent→child relationships
- `nodes` (`array<Node>`) — class definitions
- `roots` (`array<string>`) — top-level classes (no parent in scope)
- `leaves` (`array<string>`) — classes with no descendants
- `count` (`u32`) — total classes found
- `languages` (`array<string>`) — detected languages
- `root` (`string`) — input PATH echoed
- `scan_time_ms` (`u32`)

**`Edge` shape:**
- `child` (`string`) — child class name
- `parent` (`string`) — parent class name
- `child_file`, `child_line` (`string`, `u32`)
- `parent_file` (`string` | `null`), `parent_line` (`u32` | `null`) — null for external bases
- `kind` (`string`) — `"extends"`, `"implements"`, `"embeds"` (Go struct embedding)
- `external` (`bool`) — true for external (stdlib/library) bases like `ABC`
- `resolution` (`string`) — `"project"`, `"stdlib"`, `"external"`, `"unresolved"`

**DOT format (`-f dot` or `-o dot`):** `digraph inheritance { rankdir=BT; ... }` with `<<abstract>>` labels for ABC-derived classes, external nodes in lightblue ellipses with dashed-line edges. **Bottom-to-top layout** (child below parent).

**Silent-empty shape (P04, P17, P20, P21):**
```json
{
  "edges": [], "nodes": [], "roots": [], "leaves": [], "count": 0,
  "languages": [], "root": "<input>", "scan_time_ms": 0
}
```
Exit 0. **FOUR distinct failure modes produce IDENTICAL output:** bad path, lang mismatch, empty dir, non-source file. **Cannot distinguish from output alone.**

**Error shapes:**
- Format reject sarif: `"Error: --format sarif not supported by inheritance. ..."` → exit **1**
- Class not found: `"Error: class not found: <name>"` → exit **24** (TldrError::NotFound — distinct from FunctionNotFound's exit 20)
- `--depth` without `--class`: `"Error: Invalid argument --depth: --depth requires --class. Use --class <NAME> --depth N to limit traversal depth.\n\nHint: To scan entire project without depth limit, omit --depth."` → exit **25** (TldrError::InvalidArgs)
- Bad `--lang`: clap-style → exit **2**
- Bad `-o <value>`: clap-style with custom message `"Invalid format 'wat'. Expected: json, text, or dot"` → exit **2**

---

## Probe Matrix

| # | Probe | Type | Exit | Captured |
|---|-------|------|------|----------|
| P01 | `tldr inheritance backend/providers` | happy | 0 | [`01-happy.*`](./inheritance.probes/) |
| P02 | `tldr inheritance backend` | happy-scale | 0 | [`02-happy-scale.*`](./inheritance.probes/) |
| P03 | N/A: PATH defaults to `.`. | — | — | [`03-missing-arg.*`](./inheritance.probes/) (placeholder) |
| P04 | `tldr inheritance /no/such/dir` | bad-path (silent empty!) | 0 | [`04-badpath.*`](./inheritance.probes/) |
| P05 | `tldr inheritance ... -f sarif` | format-reject (sarif) | 1 | [`05-format-reject-sarif.*`](./inheritance.probes/) |
| P06 | `tldr inheritance ... -f text` | format-text | 0 | [`06-format-text.*`](./inheritance.probes/) |
| P07 | `tldr inheritance ... -f compact` | format-compact | 0 | [`07-format-compact.*`](./inheritance.probes/) |
| P08 | `tldr inheritance ... -f dot` | format-dot (supported) | 0 | [`08-format-dot.*`](./inheritance.probes/) |
| P09 | `tldr inheritance ... --class YahooProvider` | class-focus | 0 | [`09-class-focus.*`](./inheritance.probes/) |
| P10 | `tldr inheritance ... --class NoSuchClass` | class-not-found | 24 | [`10-class-not-found.*`](./inheritance.probes/) |
| P11 | `tldr inheritance ... --depth 2` *(no --class)* | depth-without-class | 25 | [`11-depth-without-class.*`](./inheritance.probes/) |
| P12 | `tldr inheritance ... --class YahooProvider --depth 1` | depth-with-class | 0 | [`12-depth-with-class.*`](./inheritance.probes/) |
| P13 | `tldr inheritance ... --no-patterns` | no-patterns | 0 | [`13-no-patterns.*`](./inheritance.probes/) |
| P14 | `tldr inheritance ... --no-external` | no-external | 0 | [`14-no-external.*`](./inheritance.probes/) |
| P15 | `tldr inheritance ... -l brainfuck` | bad-lang | 2 | [`15-bad-lang.*`](./inheritance.probes/) |
| P16 | `tldr inheritance ... -l python` | lang-python explicit | 0 | [`16-lang-python.*`](./inheritance.probes/) |
| P17 | `tldr inheritance ... -l typescript` | lang-mismatch (silent empty) | 0 | [`17-lang-mismatch.*`](./inheritance.probes/) |
| P18 | `tldr inheritance ... -o dot` | legacy -o dot | 0 | [`18-legacy-output-dot.*`](./inheritance.probes/) |
| P19 | `tldr inheritance ... -o wat` | bad legacy -o | 2 | [`19-legacy-output-bogus.*`](./inheritance.probes/) |
| P20 | `tldr inheritance <empty-tmp-dir>` | empty-dir (silent empty) | 0 | [`20-empty-dir.*`](./inheritance.probes/) |
| P21 | `tldr inheritance README.md` | non-source-md (silent empty) | 0 | [`21-non-source-md.*`](./inheritance.probes/) |
| P22 | `tldr inheritance backend/providers/base.py` | single-file | 0 | [`22-single-file.*`](./inheritance.probes/) |
| P23 | `tldr inheritance ... -q` | quiet | 0 | [`23-quiet.*`](./inheritance.probes/) |

### Observations

- **P01** — `backend/providers/` (4 files): 7 classes found in 1ms. Edges include `Provider → HistoricalDataProvider/IntradayChartProvider/QuoteProvider/MetadataProvider` (multiple inheritance, marked `<<abstract>>` for ABC-derived). External bases (`ABC`) appear as nodes with `external: true`, `resolution: "stdlib"`.
- **P02** — Full `backend/` directory: 1195 lines stdout — many more classes detected. Same schema.
- **P03** — **N/A.** PATH defaults to `.`.
- **P04** — **SILENT FAILURE:** `tldr inheritance /no/such/dir` returns exit 0 with `{ count: 0, ... }` and `root: "/no/such/dir"` echoed. **No "Path not found" error.** Indistinguishable from empty-dir / non-source-file / lang-mismatch.
- **P05** — stderr `"Error: --format sarif not supported by inheritance. Use --format json. SARIF is only emitted by: vuln, clones."`, exit `1`.
- **P06** — Text format: human-readable tree. Progress + summary on stderr: `"Found 7 classes in 1ms"` (BUG-18 fix moved this from stderr-contamination of JSON path to text-only mode).
- **P07** — Single-line minified JSON.
- **P08** — **DOT supported:** `digraph inheritance { rankdir=BT; ... }` with `<<abstract>>` labels (ABC-derived = lightyellow boxes), external nodes (lightblue ellipses, dashed edges). Bottom-to-top layout — child below parent. The canonical class-hierarchy DOT use case per source comment `surface-gaps-v1 BUG-19`.
- **P09** — `--class YahooProvider`: shows YahooProvider's ancestors + descendants. Output focused on that class.
- **P10** — stderr `"Error: class not found: NoSuchClass"`, exit **24** (TldrError::NotFound). **Distinct from FunctionNotFound's exit 20** — this command uses TldrError::NotFound for class-level lookups.
- **P11** — **Best-in-class error message:** stderr `"Error: Invalid argument --depth: --depth requires --class. Use --class <NAME> --depth N to limit traversal depth.\n\nHint: To scan entire project without depth limit, omit --depth."`, exit **25** (TldrError::InvalidArgs). Includes BOTH the rule AND a recovery hint as separate paragraphs.
- **P12** — `--class --depth 1`: limits traversal depth. 53 lines stdout — smaller than P09 (190).
- **P13** — `--no-patterns`: skips ABC/Protocol/mixin/diamond detection. Output same line count as default (212) — likely no patterns detected in this scope.
- **P14** — `--no-external`: skips external base resolution (e.g., `ABC` not resolved). Output similar to default but external nodes would be omitted or marked differently.
- **P15** — clap-style: `"error: invalid value 'brainfuck' for '--lang <LANG>': Unknown language: brainfuck"`, exit `2`.
- **P16** — Explicit `-l python`: identical to default.
- **P17** — **SILENT FAILURE:** `-l typescript` on Python project: empty result, exit 0. No warning. Same shape as bad-path (P04).
- **P18** — Legacy `-o dot`: produces DOT output. Same as `-f dot` (P08). Both flag paths work.
- **P19** — Legacy `-o wat`: clap-style error with CUSTOM message from `parse_inheritance_format`: `"error: invalid value 'wat' for '--output <OUTPUT>': Invalid format 'wat'. Expected: json, text, or dot"`, exit `2`. Custom value_parser injects the help text into the clap error.
- **P20** — **SILENT FAILURE:** Empty dir → empty result, exit 0. Same shape as bad-path.
- **P21** — **SILENT FAILURE:** README.md → empty result, exit 0. Same shape. Markdown silently produces no classes.
- **P22** — Single Python file (`base.py`): 169 lines stdout. Detects all classes defined in the file plus external references.
- **P23** — `-q` suppresses both `"Analyzing inheritance in..."` AND `"Found N classes in Mms"` summary messages (BUG-18 fix).

---

## Source Code Reality

**Target file(s):**
- `crates/tldr-cli/src/commands/inheritance.rs` (194 lines)
- `crates/tldr-core/src/inheritance/...` (per-language extractors, diamond detection, formatters)
- `crates/tldr-cli/src/output.rs:113` (`validate_format_for_command`)

**Pinned to upstream commit:** `6c4011a` (release v0.4.0)

**Argument struct:**
```rust
// crates/tldr-cli/src/commands/inheritance.rs:36-64
#[derive(Debug, Args)]
pub struct InheritanceArgs {
    #[arg(default_value = ".")] pub path: PathBuf,
    #[arg(long, short = 'l')] pub lang: Option<Language>,
    #[arg(long, short = 'c')] pub class: Option<String>,
    #[arg(long, short = 'd')] pub depth: Option<usize>,
    #[arg(long)] pub no_patterns: bool,
    #[arg(long)] pub no_external: bool,
    #[arg(long = "output", short = 'o', hide = true, value_parser = parse_inheritance_format)]
    pub output: Option<InheritanceFormat>,
}
```
Reveals: `--output` (legacy `-o`) has a CUSTOM `value_parser` (`parse_inheritance_format`) that emits clap-friendly error text. clap rejects bad values via the custom parser's `Err(format!(...))`. Hidden via `hide = true`.

**Path-validation fallthrough (P04 root cause):**
The CLI does NOT validate `path.exists()` upfront. The engine (`extract_inheritance`) walks the path; non-existent / empty / wrong-language paths simply produce no classes. **No error propagated** — agents must check `count > 0`.

**Class-not-found and depth-validation error codes:**
- `TldrError::NotFound { kind: "class", name: ... }` → exit 24 (class-not-found)
- `TldrError::InvalidArgs { ... }` → exit 25 (depth-without-class) — see `tldr-core/src/error.rs`

**stderr-hygiene fix (BUG-18 / determinism-and-stderr-hygiene-v1):**
Per source comment at line 137: the summary "Found N classes in Mms" and diamond warnings were unconditionally written to stderr, contaminating the JSON-mode contract for `tldr inheritance <path> 2>/dev/null`. Now they only print in text/quiet-aware mode.

**Format validation:** confirmed at `crates/tldr-cli/src/output.rs:113-163` — `inheritance` IS in `DOT_SUPPORTED` (alongside `calls`, `clones`, `deps`, `hubs`, `impact`). NOT in `SARIF_SUPPORTED`.

**No daemon route:** `grep -n try_daemon_route inheritance.rs` returns 0 matches. Every call walks the AST.

---

## Architectural Deep Dive

- **Under the hood:** Walks each file's AST, extracts class definitions and their base-class lists. Resolves bases to in-project classes (matching by name) or external (stdlib, package). Optional pattern detection: ABC/Protocol classifiers, mixin detection, diamond inheritance (BFS + set intersection per A2 mitigation), metaclass tracking (A12). Supports Python class, TypeScript class extends/implements, Go struct embedding (modeled as inheritance), Rust trait impl blocks.
- **Performance:** Cold ~1ms per file (small AST walk). NO daemon caching.
- **LLM cognitive load:** Architectural overview command — visualize how classes relate. Pair with `tldr cohesion` (per-class LCOM4) for refactor planning. The `--class <NAME>` focus is the LLM-friendly mode (zooming into one hierarchy keeps context small).

---

## Intent & Routing

- **User/Agent Goal:** map class inheritance hierarchies — find ancestors, descendants, diamond patterns. Visualize via DOT.
- **When to choose this over similar tools:**
  - Over `tldr structure`: structure dumps everything; inheritance is the focused class-relationship view.
  - Over `tldr cohesion`: cohesion is per-class LCOM4; inheritance is inter-class.
  - For visualization: `tldr inheritance <path> -f dot | dot -Tsvg > hierarchy.svg`.
- **Prerequisites (composition):**
  - Always pass `--class <NAME>` when using `--depth` (P11 fails with helpful error).
  - For mixed-language projects, supply `-l <lang>` (P17 silently filters with no warning).
  - **Verify `count > 0` after every call** — bad path, empty dir, wrong language, non-source file ALL produce silent empty results (P04, P17, P20, P21).

---

## Agent Synthesis

> **How to use `tldr inheritance`:**
> Class-hierarchy extractor. `tldr inheritance [PATH]` returns JSON `{ edges, nodes, roots, leaves, count, languages, root, scan_time_ms }`. Each `Edge` has `child, parent, child_file, child_line, parent_file?, parent_line?, kind, external, resolution`. Default JSON; `-f text` for tree; `-f compact` for one-line; **`-f dot` SUPPORTED** for Graphviz visualization (rankdir=BT, abstract classes in lightyellow, external nodes in lightblue ellipses). Use `--class <NAME>` to focus on one class; `--depth N` requires `--class`. `--no-patterns` skips ABC/Protocol/mixin/diamond detection; `--no-external` skips stdlib base resolution. Exit codes: 0 ok (including FOUR silent-empty modes), 1 format-reject (sarif), 2 clap missing arg / bad-lang / bad legacy -o value, 24 class-not-found, 25 invalid args (depth-without-class).
>
> **Crucial Rules:**
> - **FOUR silent-empty failure modes produce IDENTICAL output:** bad path (P04), language mismatch (P17), empty directory (P20), non-source file (P21). All return exit 0 with `{ count: 0, edges: [], nodes: [], roots: [], leaves: [], languages: [], root: "<input>", scan_time_ms: 0 }`. **Cannot distinguish from output alone** — agents must verify the PATH exists externally AND check `count > 0`.
> - **`--depth` requires `--class`** with best-in-class error: `"Error: Invalid argument --depth: --depth requires --class. Use --class <NAME> --depth N to limit traversal depth.\n\nHint: To scan entire project without depth limit, omit --depth."` (exit 25). The hint paragraph is the most actionable error in the audit suite.
> - **`--class <NAME>` not found returns exit 24** (TldrError::NotFound), NOT exit 20 (FunctionNotFound) or exit 1. Class-level lookups use a distinct error variant. P10 returns exit code agents can use to disambiguate "class missing" from other failures.
> - **Inheritance IS in DOT_SUPPORTED.** Both `-f dot` (P08) and `-o dot` (P18, legacy) produce identical DOT. The DOT format is the canonical hierarchy visualization. Pipe through `dot -Tsvg` for SVG output.
> - **stderr is JSON-mode-clean** (BUG-18 / determinism-and-stderr-hygiene-v1 fix). The summary "Found N classes in Mms" and diamond warnings only fire in text/non-quiet mode now — JSON output stays uncontaminated when redirected.
> - **`-o <value>` uses a CUSTOM clap value_parser.** Bad values produce a clap-style error with the custom message `"Invalid format 'wat'. Expected: json, text, or dot"` (P19). Other commands typically use clap's default enum rejection.
> - **`kind` values:** `"extends"` (Python/TS class extends), `"implements"` (TS implements), `"embeds"` (Go struct embedding). All three normalize to inheritance edges.
> - **External bases get `resolution: "stdlib"` or `"external"`** with `parent_file: null, parent_line: null`. Use `--no-external` to omit them from the graph.
> - **NO daemon route.** Every call walks the AST.
>
> **Command:** `tldr inheritance [PATH]`
>
> **With common flags:** `tldr inheritance <PATH> -l <lang> --class <ClassName> --depth 3 -f dot | dot -Tsvg > hierarchy.svg` (use to visualize one class's ancestry tree limited to 3 levels deep, producing an SVG diagram).
