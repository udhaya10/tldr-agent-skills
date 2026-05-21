# Command: `tldr interface`

## Environment Pin

| Field | Value |
|---|---|
| `tldr --version` | 0.4.0 |
| Build features | `semantic` (verified; interface is AST-based, non-semantic) |
| Target repo | Stock-Monitor @ commit `e601869` |
| Upstream `tldr-code` pinned to | local clone @ `6c4011a` (release v0.4.0) |
| Daemon state at probe time | N/A — `tldr interface` does **not** call `try_daemon_route` (verified by grep) |
| OS | darwin 25.2.0 |
| Probe date | 2026-05-22 |

Re-run all evidence via [`interface.probes/probe.sh`](./interface.probes/probe.sh).

---

## Ground Truth (`tldr interface --help`)

```text
Extract interface contracts (public API signatures, contracts)

Usage: tldr interface [OPTIONS] <PATH>

Arguments:
  <PATH>
          File or directory to analyze

Options:
      --project-root <PROJECT_ROOT>
          Project root for path validation

  -f, --format <FORMAT>
          Output format

          Supported by every command: json, text, compact.

          Command-specific formats (rejected at runtime by other commands): sarif  — only: vuln, clones dot    — only: calls, impact, hubs, inheritance, clones, deps

          cli-error-clarity-v2 (P2.BUG-5): possible values are hidden on the global help to avoid promising sarif/dot for every subcommand. Run `tldr <cmd> --help` to confirm what a specific command emits, and see `validate_format_for_command` in `output.rs` for the source of truth.

          [default: json]

  -l, --lang <LANG>
          Programming language (auto-detect if not specified)

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
| Typical output size | medium (~90 lines pretty JSON for one file; ~200 for a 4-file dir) |

**OUTPUT SHAPE DEPENDS ON PATH TYPE — schema diverges:**

### Single file mode (file PATH or non-source file like `.md`):
```json
{
  "file": "<path>",
  "all_exports": [string, ...],
  "functions": [FunctionInterface, ...],
  "classes": [ClassInterface, ...]
}
```
Top-level is an OBJECT.

### Directory mode:
```json
[
  { "file": ..., "all_exports": [...], "functions": [...], "classes": [...] },
  ...
]
```
Top-level is an ARRAY of file-objects.

### Empty-dir special case (P13):
```json
[]
```
Just an empty array — distinguishable from "directory with no exports" by shape.

**`FunctionInterface` shape:** `{ name, signature, lineno, docstring?, decorators?, is_async?, ... }`.

**`ClassInterface` shape:** `{ name, lineno, bases: [string], methods: [MethodInterface], decorators? }`.

**Error shapes:**
- Missing PATH: clap-style → exit **2** (PATH is required, no default)
- File not found: `"Error: file not found: /no/such/dir"` → exit **1** (lowercase "file" — matches `tldr chop`/`tldr cohesion`)
- Format reject: `"Error: --format sarif not supported by interface. ..."` → exit **1**
- Bad `--lang`: clap-style → exit **2**

---

## Probe Matrix

| # | Probe | Type | Exit | Captured |
|---|-------|------|------|----------|
| P01 | `tldr interface backend/providers/base.py` | happy (single file, OBJECT shape) | 0 | [`01-happy.*`](./interface.probes/) |
| P02 | `tldr interface backend/providers` | happy-scale (directory, ARRAY shape) | 0 | [`02-happy-scale.*`](./interface.probes/) |
| P03 | `tldr interface` *(no PATH)* | failure-missing-input | 2 | [`03-missing-arg.*`](./interface.probes/) |
| P04 | `tldr interface /no/such/dir` | failure-badpath | 1 | [`04-badpath.*`](./interface.probes/) |
| P05 | `tldr interface ... -f sarif` | format-reject (sarif) | 1 | [`05-format-reject-sarif.*`](./interface.probes/) |
| P06 | `tldr interface ... -f text` | format-text | 0 | [`06-format-text.*`](./interface.probes/) |
| P07 | `tldr interface ... -f compact` | format-compact | 0 | [`07-format-compact.*`](./interface.probes/) |
| P08 | `tldr interface ... -f dot` | format-reject (dot) | 1 | [`08-format-reject-dot.*`](./interface.probes/) |
| P09 | `tldr interface yahoo.py --project-root backend` | project-root | 0 | [`09-project-root.*`](./interface.probes/) |
| P10 | `tldr interface ... -l brainfuck` | bad-lang | 2 | [`10-bad-lang.*`](./interface.probes/) |
| P11 | `tldr interface ... -l python` | lang-python explicit | 0 | [`11-lang-python.*`](./interface.probes/) |
| P12 | `tldr interface ... -l typescript` | lang-mismatch IGNORED | 0 | [`12-lang-mismatch.*`](./interface.probes/) |
| P13 | `tldr interface <empty-tmp-dir>` | empty-dir (empty array) | 0 | [`13-empty-dir.*`](./interface.probes/) |
| P14 | `tldr interface README.md` | non-source-md (single-file shape, empty) | 0 | [`14-non-source-md.*`](./interface.probes/) |
| P15 | `tldr interface ... -q` | quiet | 0 | [`15-quiet.*`](./interface.probes/) |

### Observations

- **P01** — `base.py` (single file): top-level is **OBJECT** with `{ file, all_exports, functions, classes }`. 5 classes (`HistoricalDataProvider`, `IntradayChartProvider`, `MetadataProvider`, `Provider`, `QuoteProvider`), no top-level functions. `all_exports` is a sorted list of public class names.
- **P02** — `backend/providers/` (directory): top-level is **ARRAY** of file-objects. 4 entries (one per `.py` file). Each entry has the same single-file shape from P01.
- **P03** — stderr `"error: the following required arguments were not provided: <PATH>"`, exit `2`. PATH is required (no default).
- **P04** — stderr `"Error: file not found: /no/such/dir"`, exit `1`. Lowercase "file" — matches `tldr chop`/`tldr dead-stores`/`tldr cohesion`.
- **P05** — stderr `"Error: --format sarif not supported by interface. ..."`, exit `1`.
- **P06** — Text format: human-readable `"File: <path>\nExports:\n  ClassA\n  ...\nFunctions:\n  def f() -> T  [line N]\n      \"docstring\"\nSummary: N functions, M classes, K public methods\n  class ClassA(Base)  [line N]\n    def method(...) -> T"`. Clean API documentation.
- **P07** — Single-line minified JSON.
- **P08** — stderr `"Error: --format dot not supported by interface. ..."`, exit `1`.
- **P09** — `--project-root backend` with file `yahoo.py`: 44 lines. Shows one file's interface; project-root supplied for path validation.
- **P10** — clap-style: `"error: invalid value 'brainfuck' for '--lang <LANG>': Unknown language: brainfuck"`, exit `2`.
- **P11** — Explicit `-l python`: identical to default auto-detect (Python is auto-detected).
- **P12** — **`-l typescript` is IGNORED:** Output identical to P02 (4 Python files processed). The `--lang` flag is parsed but the engine doesn't filter files by language. Same anti-pattern as `tldr cohesion`, `tldr coupling`.
- **P13** — Empty dir: top-level is `[]` (empty array — NOT empty object). Distinguishable from "non-empty dir with no exports" (which would be array of file objects with empty inner arrays).
- **P14** — `README.md` (non-source file): top-level is **OBJECT** `{ file: "README.md", all_exports: [], functions: [], classes: [] }` — treated as a single file with no extractable content. **No "unsupported language" error.** Silent acceptance with empty arrays.
- **P15** — `-q` quiet: no progress message in this command, identical output to default.

---

## Source Code Reality

**Target file(s):**
- `crates/tldr-cli/src/commands/patterns/interface.rs` (2200+ lines — large because of per-language AST configs)
- `crates/tldr-core/src/interface/...` (per-language interface extractors)
- `crates/tldr-cli/src/output.rs:113` (`validate_format_for_command`)

**Pinned to upstream commit:** `6c4011a` (release v0.4.0)

**Argument struct:**
```rust
// crates/tldr-cli/src/commands/patterns/interface.rs:44-52
#[derive(Debug, Clone, Args)]
pub struct InterfaceArgs {
    #[arg(required = true)] pub path: PathBuf,
    #[arg(long)] pub project_root: Option<PathBuf>,
}
```
Reveals: minimal struct. PATH is `required = true` explicitly (no default). Only flag beyond globals is `--project-root`.

**Per-language node-kind configs:** The source defines language-specific tree-sitter node kinds for:
- `function_node_kinds(lang)` — function definitions per language
- `class_node_kinds(lang)` — class/struct/trait/interface definitions
- `method_node_kinds(lang)` — methods inside classes
- `decorator_node_kinds(lang)` — decorators/annotations

Supports 18 languages (Python, Rust, Go, Java, TS/JS, C/C++, Ruby, C#, Scala, PHP, Lua, Luau, Elixir, OCaml, Kotlin, Swift).

**`--lang` ignored (P12 root cause):**
The engine walks ALL supported source extensions; the explicit `--lang` flag is accepted at clap level but the directory walker doesn't filter by it. (The flag IS used internally for parser selection, but the file enumeration runs over all language extensions in scope.)

**Format validation:** confirmed at `crates/tldr-cli/src/output.rs:113-163` — `interface` is in neither `SARIF_SUPPORTED` nor `DOT_SUPPORTED`.

**No daemon route:** `grep -n try_daemon_route patterns/interface.rs` returns 0 matches.

---

## Architectural Deep Dive

- **Under the hood:** Per-file tree-sitter parse. Walks the AST extracting top-level functions, top-level classes, and methods inside classes. Captures decorators/annotations, signatures, docstrings. Resolves base classes by name (no cross-file resolution by default).
- **Performance:** Cold ~1-2ms per file. NO daemon caching.
- **LLM cognitive load:** Distills a file/project to its public API surface — what an external consumer would see. Useful for API documentation, contract verification before refactoring, comparing two versions of a module. Pair with `tldr api-check` (which flags misuse patterns) for full API audit.

---

## Intent & Routing

- **User/Agent Goal:** extract the public-surface contract of a file or directory — class names, function signatures, method signatures, decorators, docstrings.
- **When to choose this over similar tools:**
  - Over `tldr extract`: `extract` lists EVERY function (including private); `interface` filters to public-surface candidates and adds decorators/bases.
  - Over `tldr structure`: `structure` is the high-level dir tree; `interface` is per-file API extraction.
  - Over `tldr api-check`: `api-check` looks for MISUSE patterns; `interface` extracts the surface itself.
- **Prerequisites (composition):**
  - PATH must exist. Single file → object shape; directory → array shape. Branch on this in downstream code.
  - For non-source files (`.md`), expect the single-file shape with empty arrays — no error.

---

## Agent Synthesis

> **How to use `tldr interface`:**
> Public-API surface extractor. `tldr interface <PATH>` returns one of two shapes depending on input: **single file → OBJECT** `{ file, all_exports, functions, classes }`; **directory → ARRAY** of those objects. Each `ClassInterface` includes `name, lineno, bases, methods` (with signatures + decorators); each `FunctionInterface` includes signature and docstring. Default JSON; `-f text` for human-readable API docs; `-f compact` for one-line; `sarif`/`dot` rejected. Exit codes: 0 ok (including silent-empty for non-source files), 1 file-not-found / format-reject, 2 missing PATH / bad-lang.
>
> **Crucial Rules:**
> - **OUTPUT SHAPE DIVERGES based on PATH type.** Single file (or non-source file like `.md`) → OBJECT at top level. Directory → ARRAY of file-objects. **Agents must branch on this** when consuming JSON: `if (Array.isArray(result)) { /* directory mode */ } else { /* single-file mode */ }`. Empty directory returns `[]` (NOT an empty object). Best detection: check `Array.isArray()`.
> - **Non-source file (`README.md`) returns single-file OBJECT shape with empty arrays.** P14: `{ file: "README.md", all_exports: [], functions: [], classes: [] }` — silently treated as a valid empty file. NO "unsupported language" error. Distinct from `tldr halstead` which errors with exit 11 for the same input.
> - **`-l <lang>` is silently IGNORED.** P12: `-l typescript` on Python project returns the same Python output as default. The flag is accepted by clap but the engine walks ALL supported extensions. Same anti-pattern as `tldr cohesion`/`tldr coupling`. To restrict to one language, scope PATH to a single-language subdirectory.
> - **`all_exports` is a sorted list of public class + function names** at the top level of the file. Used for `__all__` / module-public-surface introspection.
> - **PATH is REQUIRED — no default.** Unlike most audit commands which default to `.`, `tldr interface` mandates an explicit path (P03 → clap exit 2).
> - **File-not-found uses lowercase "file not found:"** (matches `tldr chop`/`tldr dead-stores`/`tldr cohesion`).
> - **18 languages supported via per-language AST configs** (Python, Rust, Go, Java, TS/JS, C/C++, Ruby, C#, Scala, PHP, Lua/Luau, Elixir, OCaml, Kotlin, Swift). Coverage may vary by language.
> - **NO daemon route.** Every call re-parses.
>
> **Command:** `tldr interface <PATH>`
>
> **With common flags:** `tldr interface <PATH> -f text` (use for human-readable API documentation — produces formatted "File: ... Exports: ... Functions: ... class X(Base) ... def method(...)" output ideal for generating docs).
