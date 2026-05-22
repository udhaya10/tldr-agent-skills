# Command: `tldr extract`

## Environment Pin

| Field | Value |
|---|---|
| `tldr --version` | 0.4.0 |
| Build features | `semantic` (verified via runtime probe on 2026-05-21) |
| Target repo | Stock-Monitor @ commit `e601869` |
| Upstream `tldr-code` pinned to | `6c4011a` (release v0.4.0, 2026-05-11) |
| Daemon state at probe time | warm (project = Stock-Monitor; cache cycled mid-probe for P12/P13) |
| OS | darwin 25.2.0 |
| Probe date | 2026-05-22 |

Re-run all evidence via [`extract.probes/probe.sh`](./extract.probes/probe.sh).
See also: [agent-oriented tool card](../../tool-cards/overview/extract.md).

---

## Ground Truth (`tldr extract --help`)

```text
Extract complete module info from a file

Usage: tldr extract [OPTIONS] <FILE>

Arguments:
  <FILE>
          File to extract

Options:
  -l, --lang <LANG>
          Programming language (auto-detected from file extension if not specified)

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
| Formats that work | `json`, `text`, `compact` (P01, P06, P09) |
| Formats that error | `sarif`, `dot` (P05: exit 1) |
| Typical output size | medium (1–50KB) for a 200-line file; **heavy (>50KB)** for `backend/api.py`-scale files (P02: ~4k lines pre-truncation) |

**Top-level keys (JSON):**
- `file_path` (`string`) — repo-relative path of the analyzed file
- `language` (`string`) — detected/specified language (e.g. `"python"`, `"rust"`)
- `imports` (`array<ImportInfo>`) — module imports with `{module, is_from, names?}`
- `functions` (`array<FunctionInfo>`) — top-level functions with signatures, line numbers, bodies
- `classes` (`array<ClassInfo>`) — class definitions and their methods
- `call_graph` (`{calls: object, called_by: object}`) — per-function intra-file call graph

**Import shape (`imports[]`):**
- `module` (`string`) — imported module name (e.g. `"sqlite3"`, `"datetime"`)
- `is_from` (`bool`) — `true` for `from X import Y` style; `false` for `import X`
- `names` (`array<string>`, optional) — present when `is_from: true`, lists the imported symbols

**Call graph shape:** `calls` maps `caller → [callee...]`, `called_by` maps `callee → [caller...]`. Intra-file only — cross-file calls require `tldr calls` or `tldr impact`.

**Text format (P06):** Human-readable hierarchy with function signatures, line numbers, and import lists.

**Compact format (P09):** Single-line JSON, all whitespace stripped.

**Lang-mismatch result (P08):** Returns a structurally valid response with the requested language and **empty everything** — `imports: []`, `functions: []`, `classes: []`, empty `call_graph`. **Silent failure**, exit 0.

**Error shapes — `extract` has THREE distinct exit codes:**
- **Exit 1** — format validator rejection (P05): `Error: --format sarif not supported by extract. Use --format json. SARIF is only emitted by: vuln, clones.`
- **Exit 2** — input problem:
  - Missing required arg (P03): clap-level error `error: the following required arguments were not provided: <FILE>` with `Usage:` hint
  - Bad path (P04): `Error: Path not found: <path>`
- **Exit 11** — unsupported language (P10, P11):
  - Non-source file (`README.md`): `Error: Unsupported language: md`
  - Directory passed instead of file: `Error: Unsupported language: unknown`

> **Three distinct exit codes** make agent recovery clean: 1 → swap format; 2 → fix path/arg; 11 → check file extension or that target is a source file.

---

## Probe Matrix

Slug convention: `NN-<token>[-<modifier>]`. The audit script globs by ID, so modifiers are safe.

| # | Probe | Type | Exit | Captured |
|---|-------|------|------|----------|
| P01 | `tldr extract backend/db.py` | happy | 0 | [`01-happy.*`](./extract.probes/) |
| P02 | `tldr extract backend/api.py` | happy-scale | 0 | [`02-happy-scale.*`](./extract.probes/) |
| P03 | `tldr extract` *(no args)* | failure-missing-arg | 2 | [`03-missing-arg.*`](./extract.probes/) |
| P04 | `tldr extract /no/such/file.py` | failure-badpath | 2 | [`04-badpath.*`](./extract.probes/) |
| P05 | `tldr extract backend/db.py -f sarif` | format-reject | 1 | [`05-format-reject-sarif.*`](./extract.probes/) |
| P06 | `tldr extract backend/db.py -f text` | format-text | 0 | [`06-format-text.*`](./extract.probes/) |
| P07 | `tldr extract backend/db.py -l python` | flag-lang-explicit | 0 | [`07-lang-python.*`](./extract.probes/) |
| P08 | `tldr extract backend/db.py -l rust` | flag-lang-mismatch | 0 | [`08-lang-mismatch.*`](./extract.probes/) |
| P09 | `tldr extract backend/db.py -f compact` | format-compact | 0 | [`09-format-compact.*`](./extract.probes/) |
| P10 | `tldr extract README.md` | boundary-non-source | 11 | [`10-non-source-md.*`](./extract.probes/) |
| P11 | `tldr extract backend` | boundary-directory | 11 | [`11-directory-arg.*`](./extract.probes/) |
| P12 | `tldr extract backend/db.py` *(daemon stopped)* | env-cold-daemon | 0 | [`12-cold-daemon.*`](./extract.probes/) |
| P13 | `tldr extract backend/db.py` *(after `tldr warm`)* | env-warm-daemon | 0 | [`13-warm-daemon.*`](./extract.probes/) |

### Observations

- **P01 (small file, 260 lines):** Returns `{file_path, language, imports, functions, classes, call_graph}`. The `call_graph` map is intra-file only.
- **P02 (large file, 4,158 lines):** Output exceeded the 500-line cap and was truncated per protocol §5. `backend/api.py` is the FastAPI router with ~300 routes — extraction returns every function definition and its intra-file call relationships.
- **P03 (missing required arg):** stderr is a **clap-level error** (not anyhow): `error: the following required arguments were not provided: <FILE>`, exit `2`. Includes the `Usage:` hint. **Recovery hint:** must pass a `<FILE>` positional.
- **P04 (bad path):** stderr `Error: Path not found: <path>`, exit `2`. The runtime path check produces the same exit code as the clap validation, but the message format differs.
- **P05 (sarif rejection):** exit `1` with the standard validator error. Format validator path is shared across all commands.
- **P06 (text format, 52 lines):** Human-readable; useful for chat output but harder to parse.
- **P07 (explicit `-l python`):** Output **byte-identical** to P01 (auto-detect). Explicit flag is redundant when detection succeeds — but it does suppress the sibling-aware widening described in `extract.rs:35-41`.
- **P08 (`-l rust` mismatch):** **Silent failure**, same pattern as `structure`. Exit 0, valid JSON shape, all extraction arrays empty. Agent must check whether `functions`/`classes`/`imports` are unexpectedly empty.
- **P09 (compact, 1 line / ~4KB):** Same content as P01, all whitespace stripped.
- **P10 (non-source file, `README.md`):** stderr `Error: Unsupported language: md`, exit `11`. **`.md` is not in the supported-language list.** Agent recovery: don't pipe non-source paths into `extract`.
- **P11 (directory):** stderr `Error: Unsupported language: unknown`, exit `11`. Despite no path-existence check in `extract.rs`, the underlying parser refuses non-file targets. **Use `tldr structure <dir>` for directory-level analysis instead.**
- **P12 (cold daemon, 260 lines):** Daemon stopped; output byte-identical to P13.
- **P13 (warm daemon, after `tldr warm`):** Cache populated; exit 0, 260 lines. Byte-identical to P12. As with `structure`, the speedup is timing-only on small inputs — output is invariant.

---

## Source Code Reality

**Target file:** `crates/tldr-cli/src/commands/extract.rs` (pinned to upstream commit `6c4011a`).

**Argument definition (`extract.rs:18-26`):**
```rust
#[derive(Debug, Args)]
pub struct ExtractArgs {
    /// File to extract
    pub file: PathBuf,

    /// Programming language (auto-detected from file extension if not specified)
    #[arg(long, short = 'l')]
    pub lang: Option<Language>,
}
```
**Critical:** `file` is **required** — no `default_value`. This is the first command in the suite where P03 (missing-input) produces a real clap error (exit 2) instead of an N/A marker. No `--max-results` here; `extract` operates on a single file only.

**Sibling-aware language resolution (`extract.rs:35-41`):**
```rust
// cross-command-consistency-v3 (P5.BUG-N1): resolve the language hint
// BEFORE choosing a route. The user's explicit `--lang` wins over any
// detection. When the user did not pass `--lang`, apply the
// sibling-aware widening so `.h` files in C++ projects parse as C++
// (otherwise the C grammar mis-classifies `class Foo` as a function
// with `return_type: "class"` and emits zero classes).
let resolved_lang: Option<Language> = match self.lang {
    Some(l) => Some(l),
    None => Language::from_path_with_siblings(&self.file),
};
```
**Reveals:** when `--lang` is *not* passed, `extract` checks sibling files in the same directory to disambiguate. `.h` in a directory full of `.cpp` files parses as C++; in a directory full of `.c` files it parses as C. Passing `--lang` **bypasses this smart widening** — explicit flags win.

**Daemon-route project root (`extract.rs:43-53`):**
```rust
// Try daemon first for cached result (use file's parent as project root)
let project = self.file.parent().unwrap_or(&self.file);
if let Some(result) = try_daemon_route::<ModuleInfo>(
    project,
    "extract",
    params_with_file_lang(&self.file, resolved_lang.as_ref().map(|l| l.as_str())),
) { ... }
```
**Hidden constraint:** the daemon's cache is keyed on `(parent_dir, file, language)`. Different daemons (e.g., one for `backend/`, one for `webui/`) maintain separate caches. The cache key correctly partitions on language, so `-l rust` and no `-l` flag produce separate cache entries.

**Fallback compute (`extract.rs:62-67`):**
```rust
// Extract module info, propagating the resolved language hint so the
// parser pool honors it instead of falling back to extension-based
// detection (which breaks `.h` for C++ and any extensionless file
// with `--lang`).
let result = extract_file_with_lang(&self.file, None, resolved_lang)?;
```
This is where the `Unsupported language` error (exit 11) originates — the parser pool rejects unknown extensions and unsupported language values.

**No path-existence check.** Unlike `structure.rs` which has an explicit `if !self.path.exists() { ... }` guard, `extract.rs` lets the underlying `extract_file_with_lang` propagate the path error. This produces the same exit code (2) but a different code path. (Could behave differently if a future change adds early validation.)

**Format validator** confirmed at `crates/tldr-cli/src/output.rs::validate_format_for_command` — `extract` is in neither `SARIF_SUPPORTED` nor `DOT_SUPPORTED`.

---

## Architectural Deep Dive

- **Engine:** Tree-sitter AST parser, same per-language parser pool used by `structure`. Additional: builds an intra-file call graph by walking the AST for call expressions.
- **Cache layer:** Daemon-backed, keyed on `(parent_dir, file, language)`. ~35x source-stated speedup on warm cache. Cache invalidates when language hint changes.
- **Language resolution:** **More sophisticated than `structure`.** Cascade is `explicit -l → from_path_with_siblings(file)`. Sibling-aware: `.h` in a C++ codebase parses as C++. Passing `--lang` bypasses this widening.
- **Call graph:** Intra-file only. For cross-file call graphs, use `tldr calls` or `tldr impact`.
- **LLM cognitive load:** Replaces "read this 1000-line file to find the function definition I need." Agents use `extract` to:
  1. Get exact line numbers before invoking `slice`/`reaching-defs`.
  2. See intra-file `call_graph` to understand local function dependencies.
  3. Get import context to determine which external modules the file depends on.

---

## Intent & Routing

- **User/Agent Goal:** Get a complete dump of a single file's structure: functions (with bodies), classes, imports, and intra-file call graph.
- **When to choose this over similar tools:**
  - Use *instead of* `cat <file>` when you only need to know what functions exist and their line numbers.
  - Use *before* `tldr slice` / `tldr reaching-defs` — both need a specific `<line_number>`, and `extract` produces line numbers for every function.
  - Use *before* `tldr impact <function>` if you don't know the function name yet — extract gives you the function inventory.
  - Use *over* `tldr structure <file>` when you need intra-file call relationships, not just the API roster.
- **Prerequisites:** None.
- **Composes well with:**
  - `tldr structure <dir>` → identify file of interest → `tldr extract <file>` for the call graph → `tldr slice <file> <function> <line>` for the data flow.
  - `tldr extract` → pick a function → `tldr impact <function>` for cross-file blast radius.

---

## Agent Synthesis

> **How to use `tldr extract`:**
> Use to dump a single file's complete structure — every function with line numbers, every import, every class, plus the intra-file call graph. The line numbers in the output are the key value: they unblock `tldr slice`, `tldr reaching-defs`, and other commands that require explicit `<line>` arguments.
>
> **Crucial Rules:**
> - **`<FILE>` is REQUIRED.** Omitting it produces a clap error (exit 2) with a `Usage:` hint. This is not like `tree`/`structure` where the path defaults to `.`.
> - **Pass a file, not a directory.** Passing a directory (P11) returns `Error: Unsupported language: unknown`, exit 11. Use `tldr structure <dir>` for directory-level analysis.
> - **Pass a source file, not docs/config.** `README.md`, `.json`, `.toml`, etc. return `Error: Unsupported language: <ext>`, exit 11.
> - **Three distinct exit codes for failures:**
>   - `1` = format validator rejection (swap `-f`)
>   - `2` = missing arg or bad path (fix the input)
>   - `11` = unsupported language (target is not a parseable source file)
> - **Do NOT pass `-l <lang>` unless you have verified the file's actual language.** Mismatched language silently returns empty extraction (P08), same pattern as `structure`. Worse: passing `-l` *bypasses* the sibling-aware widening that makes `.h` files parse correctly in C++ codebases (`extract.rs:35-41`).
> - **The `call_graph` is intra-file only.** For cross-file calls, use `tldr calls` or `tldr impact`.
> - **Empty extraction arrays are the red flag.** If you get exit 0 but `functions: []`, `classes: []`, `imports: []`, you probably passed a wrong `-l` flag — drop it and let auto-detection run.
>
> **Commands:**
> - Default: `tldr extract <file>`
> - Human-readable: `tldr extract <file> -f text`
> - Single-line for piping: `tldr extract <file> -f compact`
> - Then drive subsequent calls: e.g. `tldr slice <file> <function-name> <line-from-extract>`
