# Command: `tldr imports`

## Environment Pin

| Field | Value |
|---|---|
| `tldr --version` | 0.4.0 |
| Build features | `semantic` |
| Target repo | Stock-Monitor @ commit `e601869` |
| Upstream `tldr-code` pinned to | local clone @ `6c4011a` (release v0.4.0) |
| Daemon state at probe time | mixed (probe.sh cycles cold→warm; P16 cold, P17/P18/P19 warm) |
| OS | darwin 25.2.0 |
| Probe date | 2026-05-22 |

Re-run all evidence via [`imports.probes/probe.sh`](./imports.probes/probe.sh).
See also: [agent-oriented tool card](../../tool-cards/overview/imports.md).

---

## Ground Truth (`tldr imports --help`)

```text
Parse import statements from a file

Usage: tldr imports [OPTIONS] <FILE>

Arguments:
  <FILE>
          File to parse

Options:
  -l, --lang <LANG>
          Programming language (auto-detect if not specified)

      --legacy-array
          Emit the legacy bare-array JSON shape (`[ImportInfo, ...]`) instead of the canonical envelope object `{file, language, imports}`. Provided for backward compatibility with consumers that hard-coded `jq '.[]'` over the top level. New code should consume the envelope shape

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
| Default format | `json` (envelope shape since schema-unification-v1 BUG-18) |
| Formats that work | `json`, `text`, `compact` (P01, P06, P07) |
| Formats that error | `sarif`, `dot` (P05, P08: exit 1) |
| Typical output size | small (<1 KB for typical source files) |

**Top-level keys (JSON envelope, `ImportsEnvelope`):**
- `file` (`string`) — input file path as given
- `language` (`string`) — detected or specified language name (lowercase `python`, `typescript`, …)
- `imports` (`array<ImportInfo>`) — parsed import statements; **empty array, not omitted**, when none

**`ImportInfo` shape** (`tldr-core/src/types.rs:1350`):
- `module` (`string`) — module / package being imported (always present)
- `names` (`array<string>`, omitted when empty) — names from `from X import a, b`
- `is_from` (`bool`, default false) — whether this is a `from` import
- `alias` (`string`, omitted when None) — alias from `import X as Y`
- **NO `line` field** — `tldr imports` does NOT report line numbers. To get line numbers, use `tldr importers <MODULE> <PATH>` (which extracts them at the call site) or `tldr extract <FILE>` (which reports per-symbol locations).

**Legacy-array shape (`--legacy-array`, P11/P18):**
```json
[
  { "module": "abc", "names": ["ABC", "abstractmethod"], "is_from": true },
  { "module": "pandas", "is_from": false, "alias": "pd" }
]
```
Top-level is a bare array; no `file` / `language` wrapper. Both cold and warm-daemon paths honor the toggle.

**Empty / silent-miss shape (P12, P19):**
```json
{ "file": "backend/providers/base.py", "language": "typescript", "imports": [] }
```
A `.py` file with `-l typescript` returns `{ ..., imports: [] }` with exit 0 — **silent failure mode**. The TypeScript parser doesn't match Python imports; no warning is emitted.

**Error shapes (all stderr):**
- Missing FILE: clap-style `"error: the following required arguments were not provided: <FILE> …"` → exit **2**
- Path not found: `"Error: Path not found: /no/such/file.py"` → exit **2** (TldrError::PathNotFound, NOT clap)
- Format reject: `"Error: --format sarif not supported by imports. Use --format json. SARIF is only emitted by: vuln, clones."` → exit **1**
- Bad `--lang`: clap-style `"error: invalid value 'X' for '--lang <LANG>': Unknown language: X"` → exit **2**
- Directory / non-source FILE: `"Error: Unsupported language: Could not detect language for: <path>"` → exit **11** (TldrError::UnsupportedLanguage)

---

## Probe Matrix

| # | Probe | Type | Exit | Captured |
|---|-------|------|------|----------|
| P01 | `tldr imports backend/providers/base.py` | happy | 0 | [`01-happy.*`](./imports.probes/) |
| P02 | `tldr imports backend/providers/yahoo.py` | happy-scale | 0 | [`02-happy-scale.*`](./imports.probes/) |
| P03 | `tldr imports` *(no FILE)* | failure-missing-input | 2 | [`03-missing-arg.*`](./imports.probes/) |
| P04 | `tldr imports /no/such/file.py` | failure-badpath | 2 | [`04-badpath.*`](./imports.probes/) |
| P05 | `tldr imports ... -f sarif` | format-reject | 1 | [`05-format-reject-sarif.*`](./imports.probes/) |
| P06 | `tldr imports ... -f text` | format-text | 0 | [`06-format-text.*`](./imports.probes/) |
| P07 | `tldr imports ... -f compact` | format-compact | 0 | [`07-format-compact.*`](./imports.probes/) |
| P08 | `tldr imports ... -f dot` | format-reject-dot | 1 | [`08-format-reject-dot.*`](./imports.probes/) |
| P09 | `tldr imports ... -l python` | lang-python | 0 | [`09-lang-python.*`](./imports.probes/) |
| P10 | `tldr imports ... -l brainfuck` | bad-lang (clap) | 2 | [`10-bad-lang.*`](./imports.probes/) |
| P11 | `tldr imports ... --legacy-array` | legacy-array shape | 0 | [`11-legacy-array.*`](./imports.probes/) |
| P12 | `tldr imports backend/providers/base.py -l typescript` | lang-mismatch silent | 0 | [`12-lang-mismatch.*`](./imports.probes/) |
| P13 | `tldr imports backend` *(directory)* | unsupported-directory | 11 | [`13-directory-arg.*`](./imports.probes/) |
| P14 | `tldr imports README.md` | unsupported-md | 11 | [`14-non-source-md.*`](./imports.probes/) |
| P15 | `tldr imports ... -q` | quiet | 0 | [`15-quiet.*`](./imports.probes/) |
| P16 | `tldr imports backend/providers/yahoo.py` *(daemon stopped)* | cold-daemon | 0 | [`16-cold-daemon.*`](./imports.probes/) |
| P17 | `tldr imports backend/providers/yahoo.py` *(daemon warm)* | warm-daemon | 0 | [`17-warm-daemon.*`](./imports.probes/) |
| P18 | `tldr imports ... --legacy-array` *(daemon warm)* | warm-daemon-legacy | 0 | [`18-warm-daemon-legacy-array.*`](./imports.probes/) |
| P19 | `tldr imports backend/providers/base.py -l typescript` *(daemon warm)* | warm-daemon-lang-mismatch | 0 | [`19-warm-daemon-lang-mismatch.*`](./imports.probes/) |

### Observations

- **P01** — `base.py` returns 4 imports (`abc` from-import with 2 names, `datetime` from-import with 1 name, `typing` from-import with 4 names, `pandas as pd` plain import with alias). Output proves the `names`/`is_from`/`alias` field semantics: `import pandas as pd` emits `{ module: "pandas", is_from: false, alias: "pd" }` with NO `names` field (skip-if-empty); `from abc import ABC, abstractmethod` emits `{ module: "abc", names: ["ABC", "abstractmethod"], is_from: true }` with NO `alias` field.
- **P02** — `yahoo.py` returns 7 imports including `import math`, `from datetime import date`, `from backend.providers.base import Provider`. Output size ~700 bytes pretty-printed.
- **P03** — stderr `"error: the following required arguments were not provided: <FILE>"`, exit **2** (clap). `ImportsArgs.file` is `PathBuf` (not `Option<PathBuf>`) so clap enforces it.
- **P04** — stderr `"Error: Path not found: /no/such/file.py"`, exit **2** (NOT 5, NOT 1). **Cross-command divergence:** this is `TldrError::PathNotFound::exit_code() = 2` (`tldr-core/src/error.rs:317`). The CLI does NOT do upfront path validation (`imports.rs` has no `if !file.exists()` check); the error propagates from `get_imports` → `detect_or_parse_language`. Note: exit 2 is the SAME as clap missing-arg, so callers can't distinguish "no FILE given" from "FILE doesn't exist" by exit code alone — must parse stderr.
- **P05** — stderr `"Error: --format sarif not supported by imports. Use --format json. SARIF is only emitted by: vuln, clones."`, exit `1`.
- **P06** — Text format renders a bold filename header `backend/providers/base.py (4 imports)`, then a blank line, then one line per import (`from X: a, b`, `import X`, `import X as Y`). Progress message `"Parsing imports from backend/providers/base.py (Python)..."` on stderr.
- **P07** — Single-line minified JSON envelope.
- **P08** — stderr `"Error: --format dot not supported by imports. Use --format json. DOT is only emitted by: clones, deps, calls, impact, hubs, inheritance."`, exit `1`.
- **P09** — Explicit `-l python` produces output identical to auto-detect. Unlike `tldr explain` where `--lang` was inert on correctly-extensioned files, this command actually consults `--lang` via `detect_or_parse_language`.
- **P10** — clap-style: `"error: invalid value 'brainfuck' for '--lang <LANG>': Unknown language: brainfuck"`, exit `2`.
- **P11** — `--legacy-array` returns bare top-level array; the wrapper envelope is suppressed. **Both cold (P11) and warm-daemon (P18) honor the flag** (see P18). Useful when piping into `jq '.[]'`-style tools.
- **P12** — **Silent failure mode:** `-l typescript` on a `.py` file returns `{ ..., language: "typescript", imports: [] }` with exit 0. The TypeScript parser doesn't match Python `from X import Y` / `import X` syntax. **No warning emitted.** Agents that pass `--lang` defensively (e.g., "force Python") risk getting empty data when they mis-spell. Recovery: validate `imports.length > 0` OR omit `--lang` and let auto-detect run.
- **P13** — stderr `"Error: Unsupported language: Could not detect language for: backend"`, exit **11** (`TldrError::UnsupportedLanguage::exit_code() = 11`, `tldr-core/src/error.rs:329`). **Unique exit code for this command relative to definition/explain/importers** (which all collapse unsupported-language onto exit 1). Use exit 11 to distinguish "language detection failed" from "format rejected" (exit 1).
- **P14** — Same shape as P13: `"Error: Unsupported language: Could not detect language for: README.md"`, exit `11`.
- **P15** — `-q` suppresses stderr progress; stdout envelope unaffected.
- **P16** — Cold-daemon path for `yahoo.py` returns 7 imports (44 lines JSON).
- **P17** — Warm-daemon path returns byte-identical output to P16 (verified via `diff`).
- **P18** — Warm-daemon + `--legacy-array` returns bare top-level array. Confirms the daemon path also branches on the flag at `imports.rs:74-93`. Daemon-routed result is `Vec<ImportInfo>` (raw); the CLI applies the envelope OR array shape after deserializing.
- **P19** — Warm-daemon + `-l typescript` on a `.py` file returns `{ language: "typescript", imports: [] }`. **The `language` key in `params_with_file_lang` (`daemon_router.rs:179-186`) IS forwarded to the daemon** — contrast with `tldr importers` where the lang flag is dropped at the daemon boundary. The daemon honors the override and returns empty (no TS imports in a Python file).

---

## Source Code Reality

**Target file(s):**
- `crates/tldr-cli/src/commands/imports.rs` (135 lines — small, clean)
- `crates/tldr-core/src/validation.rs:101-116` (`detect_or_parse_language`)
- `crates/tldr-core/src/error.rs:314-358` (`TldrError::exit_code()`)
- `crates/tldr-core/src/types.rs:1350-1362` (`ImportInfo`)
- `crates/tldr-cli/src/commands/daemon_router.rs:179-186` (`params_with_file_lang`)
- `crates/tldr-cli/src/output.rs:113` (`validate_format_for_command`)

**Pinned to upstream commit:** `6c4011a` (release v0.4.0)

**Argument struct:**
```rust
// crates/tldr-cli/src/commands/imports.rs:38-53
#[derive(Debug, Args)]
pub struct ImportsArgs {
    /// File to parse
    pub file: PathBuf,
    /// Programming language (auto-detect if not specified)
    #[arg(long, short = 'l')]
    pub lang: Option<Language>,
    /// Emit the legacy bare-array JSON shape …
    #[arg(long = "legacy-array")]
    pub legacy_array: bool,
}
```
Reveals: `file` is required (`PathBuf`, not `Option<PathBuf>` → clap exit 2 on missing); `lang` is `Option<Language>` (clap pre-parses, bad values → exit 2). `--legacy-array` has NO short flag.

**No upfront path check:**
```rust
// imports.rs:55-96 (excerpt) — no `if !file.exists()` anywhere
pub fn run(&self, format: OutputFormat, quiet: bool) -> Result<()> {
    let writer = OutputWriter::new(format, quiet);
    let project = self.file.parent().unwrap_or(&self.file);
    if let Some(result) = try_daemon_route::<Vec<ImportInfo>>(
        project, "imports",
        params_with_file_lang(&self.file, self.lang.as_ref().map(|l| l.as_str())),
    ) { ... return Ok(()); }
    // Fallback:
    let language = detect_or_parse_language(self.lang.as_ref().map(|l| l.as_str()), &self.file)?;
    ...
    let result = get_imports(&self.file, language)?;  // <-- engine catches missing file
    ...
}
```
Reveals: missing file is caught by the **engine** (`get_imports` → `TldrError::PathNotFound`), not by the CLI. Hence exit code 2 (TldrError) instead of the typed-RemainingError 5 or anyhow 1.

**`detect_or_parse_language` decides language detection:**
```rust
// tldr-core/src/validation.rs:101-116
pub fn detect_or_parse_language(lang: Option<&str>, path: &Path) -> TldrResult<Language> {
    if let Some(lang_str) = lang {
        lang_str.parse()
            .map_err(|_| TldrError::UnsupportedLanguage(lang_str.to_string()))
    } else {
        Language::from_path(path).ok_or_else(|| {
            TldrError::UnsupportedLanguage(format!(
                "Could not detect language for: {}", path.display()
            ))
        })
    }
}
```
Reveals: when `--lang` is given, it's parsed via `lang_str.parse()` (the `FromStr` for `Language`). When `--lang` is omitted, `Language::from_path` checks extension. For a directory (P13), `from_path` returns None → exit 11. The function does NOT validate that the file exists — that's deferred to `get_imports`.

**Envelope vs legacy-array shape (BUG-18 schema unification):**
```rust
// imports.rs:74-93 (daemon branch — fallback branch is similar)
} else if self.legacy_array {
    writer.write(&result)?;
} else {
    let envelope = ImportsEnvelope {
        file: self.file.display().to_string(),
        language: self.lang.as_ref().map(|l| l.as_str().to_string()).unwrap_or_else(|| {
            detect_or_parse_language(None, &self.file)
                .map(|l| l.as_str().to_string())
                .unwrap_or_else(|_| "unknown".to_string())
        }),
        imports: result,
    };
    writer.write(&envelope)?;
}
```
Reveals: on the daemon path, the language field is best-effort — if detection fails post-daemon-return, the envelope shows `language: "unknown"` rather than failing. The cold path is unconditional (language is bound in the variable before this branch).

**Daemon route DOES forward language (contrast with importers):**
```rust
// daemon_router.rs:179-186
pub fn params_with_file_lang(file: &Path, lang: Option<&str>) -> serde_json::Value {
    let mut obj = serde_json::Map::new();
    obj.insert("file".to_string(), serde_json::json!(file));
    if let Some(l) = lang {
        obj.insert("language".to_string(), serde_json::json!(l));
    }
    serde_json::Value::Object(obj)
}
```
The comment block immediately preceding (lines 172-178) explicitly notes: *"JSON key is `\"language\"` to match the daemon handler's `ImportsRequest.language` field (handlers/ast.rs:L164) — there is no `#[serde(rename)]` on that field, so a `\"lang\"` key would be silently ignored and the bug would still ship."* This is the OPPOSITE of `tldr importers`, whose `params_with_module` does NOT pass lang.

**Format validation:** confirmed at `crates/tldr-cli/src/output.rs:113-163` — `imports` is in neither `SARIF_SUPPORTED` nor `DOT_SUPPORTED`.

**ImportInfo has no line number:**
```rust
// tldr-core/src/types.rs:1350-1362
pub struct ImportInfo {
    pub module: String,
    #[serde(default, skip_serializing_if = "Vec::is_empty")]
    pub names: Vec<String>,
    #[serde(default)]
    pub is_from: bool,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub alias: Option<String>,
}
```
Reveals: NO `line` field. The sibling `tldr importers` command re-reads the file to extract line numbers (`importers.rs:80-83`) — `tldr imports` does not. Agents needing line numbers must either grep the file or pipe through `tldr importers <module>`.

---

## Architectural Deep Dive

- **Under the hood:** Single-file tree-sitter parse via `get_imports` (`tldr-core/src/ast/imports.rs`). Language-specific extractors recognize `import` / `from … import` (Python), `import …` / `import { } from …` (JS/TS), package paths (Go), use statements (Rust), etc. No call-graph, no project walk — purely file-scoped.
- **Performance:** Cold ~50ms per file (tree-sitter parse cost). Daemon cache yields effectively-free repeat queries because the per-file import list is small and serializes quickly. The "~35x speedup" docstring claim (`imports.rs:4`) is plausible for the warm path on cached files.
- **LLM cognitive load:** Replaces `head -30 <file>` + manual filtering of import statements. Returns typed JSON with module / names / is_from / alias — enables an agent to follow imports without reading the file body. Pair with `tldr importers <MODULE>` to traverse the import graph in both directions.

---

## Intent & Routing

- **User/Agent Goal:** answer "what does this file depend on?" — enumerate the imports of a single file in a typed shape.
- **When to choose this over similar tools:**
  - Over `head <file>`: handles multi-line imports (parenthesized `from X import (\n  a, b,\n)`), aliases, and language-specific syntax.
  - Over `tldr importers`: `imports` is the **reverse direction** — "what does THIS file import" vs "who imports THAT module". Use both together to traverse the import graph.
  - Over `tldr extract`: `extract` lists functions/classes per file; `imports` lists only the import statements. Pair them when building a full module summary.
- **Prerequisites (composition):**
  - For line numbers: pipe through `tldr importers <module> <project-path>` after extracting each module name; `tldr imports` itself does not emit line numbers.
  - For repeated queries on the same project: `tldr daemon start --project <ROOT>` to warm the cache; the daemon route forwards `--lang` correctly (P19) unlike `tldr importers`.

---

## Agent Synthesis

> **How to use `tldr imports`:**
> Single-file import lister. `tldr imports <FILE>` returns a JSON envelope `{ file, language, imports: [ImportInfo, ...] }`. Each `ImportInfo` has `module`, optional `names` (for `from X import Y`), `is_from` flag, and optional `alias`. **No line numbers** — that's `tldr importers`'s job. Default JSON; `-f text` for human display; `-f compact` for one-line. Exit codes: 0 ok (including empty-imports result from a wrong --lang), 1 format-reject, 2 missing FILE / bad --lang / file-not-found (three failure modes share exit 2!), 11 unsupported language (directory or non-source file). Auto-routes through the daemon for repeat queries; daemon path honors both `--lang` and `--legacy-array`.
>
> **Crucial Rules:**
> - **`-l <LANG>` mismatch is a SILENT empty-array failure.** `tldr imports file.py -l typescript` returns `{ language: "typescript", imports: [] }` with exit 0 (P12, P19). Both cold and warm-daemon paths share this behavior. Validate `imports.length > 0` defensively, OR omit `--lang` so auto-detect picks the right parser.
> - **Three failure modes collapse onto exit 2: missing FILE, bad path, bad --lang.** clap missing-arg, `TldrError::PathNotFound` (no upfront CLI check — engine catches it), and clap invalid-lang all return 2. Callers cannot distinguish them by exit code alone — must parse stderr. (P03 vs P04 vs P10.)
> - **Exit 11 is unique to `tldr imports` (and other engine-routed commands) for "unsupported language."** A directory or non-source file (`.md`, `.txt`) returns `"Error: Unsupported language: Could not detect language for: <path>"` with exit 11 (`tldr-core/src/error.rs:329`). Distinguishes "couldn't even start parsing" from generic-error exit 1.
> - **No `line` field on `ImportInfo`.** `tldr imports` does NOT emit line numbers. If you need them, pipe through `tldr importers <MODULE> <PROJECT>` per-module (it extracts line via re-reading the file at `importers.rs:80-83`).
> - **Daemon route DOES forward `--lang` (contrast with `tldr importers` which drops it).** `params_with_file_lang` (`daemon_router.rs:179-186`) emits the `language` JSON key explicitly because the daemon handler `ImportsRequest.language` field has no `#[serde(rename)]`. Source-code comment block confirms.
> - **`--legacy-array` works on both cold and warm-daemon paths.** Both branches at `imports.rs:74` and `imports.rs:121` check the flag. Safe to use without worrying about daemon state (P11 vs P18).
> - **Empty fields are omitted from JSON.** `import X` emits `{ module, is_from: false }` (no `names`, no `alias`); `import X as Y` emits `{ module, is_from: false, alias: "Y" }`; `from X import a, b` emits `{ module, names: ["a","b"], is_from: true }`. Use `serde_json::Value::get` defensively — `obj["names"]` may be `null`.
> - **Envelope language field can read `"unknown"` on the daemon path.** When `--lang` is omitted, the envelope re-runs `detect_or_parse_language` post-daemon-return; if that fails, `language: "unknown"` instead of bailing (`imports.rs:82-90`).
>
> **Command:** `tldr imports <FILE>`
>
> **With common flags:** `tldr imports <FILE> -f compact` (one-line JSON for piping); `tldr imports <FILE> --legacy-array` (bare-array shape for `jq '.[]'` consumers); `tldr imports <FILE> -l <lang>` (force language — but check the result isn't silently empty).
