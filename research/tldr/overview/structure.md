# Command: `tldr structure`

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

Re-run all evidence via [`structure.probes/probe.sh`](./structure.probes/probe.sh).
See also: [agent-oriented tool card](../../tool-cards/overview/structure.md).

---

## Ground Truth (`tldr structure --help`)

```text
Extract code structure (functions, classes, imports)

Usage: tldr structure [OPTIONS] [PATH]

Arguments:
  [PATH]
          Directory to scan (default: current directory)
          
          [default: .]

Options:
  -l, --lang <LANG>
          Programming language (auto-detected if not specified)

  -m, --max-results <MAX_RESULTS>
          Maximum number of files to process (0 = unlimited)
          
          [default: 0]

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
| Formats that work | `json`, `text`, `compact` (P01, P06, P10) |
| Formats that error | `sarif`, `dot` (P05: exit 1) |
| Typical output size | small (<5KB) for one file; **heavy (>50KB)** for a multi-file directory (P02: ~18k lines pre-truncation) |

**Top-level keys (JSON):**
- `root` (`string`) — the path that was scanned (file or dir)
- `language` (`string \| null`) — detected/specified language; `null` if no source files found
- `files` (`array<FileStructure>`) — one entry per analyzed source file
- `warnings` (`array<string>`, optional) — present when something was non-fatal but worth surfacing (e.g., empty dir; see P11)

**Per-file shape (`files[]`):**
- `path` (`string`) — repo-relative path of the file
- `classes` (`array<ClassInfo>`) — class definitions with their methods
- `method_infos` (`array`) — methods detached from classes (top-level or module-level)
- `imports` (`array<{module, is_from}>`) — `module` is the imported name; `is_from: true` means `from X import Y`, `false` means `import X`
- `definitions` (`array`) — top-level function/variable definitions

**Empty result (P11, empty dir):**
```json
{
  "root": "<path>",
  "language": null,
  "files": [],
  "warnings": ["No source files found in directory"]
}
```
Exit 0 — empty results are *not* an error.

**Text format (P06):** Human-readable hierarchy with function signatures and line numbers (`L:12`).

**Compact format (P10):** Single-line JSON, all whitespace stripped.

**Error shapes:**
- Bad path (P04): stderr `Error: Path not found: <path>`, exit `1`. **Differs from `tree`** (which exits 2) — `structure.rs` uses `anyhow::bail!` whose default is exit 1, while `tree` returns through a different path.
- Format rejection (P05): stderr `Error: --format sarif not supported by structure. Use --format json. SARIF is only emitted by: vuln, clones.`, exit `1`.

> **Silent failure mode (P09):** Passing `-l rust` against a Python file produces a valid JSON response with `"language": "rust"` and empty `imports`/`definitions` — the Rust parser couldn't read Python but no error is raised. **Agents must trust the detected language**: do not pass an explicit `-l` flag unless you have verified the file's actual language; otherwise the tool will quietly return empty structure.

---

## Probe Matrix

Slug convention: `NN-<token>[-<modifier>]`. The audit script globs by ID, so modifiers are safe.

| # | Probe | Type | Exit | Captured |
|---|-------|------|------|----------|
| P01 | `tldr structure backend/db.py` | happy | 0 | [`01-happy.*`](./structure.probes/) |
| P02 | `tldr structure backend` | happy-scale | 0 | [`02-happy-scale.*`](./structure.probes/) |
| P03 | N/A: all inputs optional — `[PATH]` defaults to `.` (verified at `structure.rs:21`). | — | — | — |
| P04 | `tldr structure /no/such/path/...` | failure-badpath | 1 | [`04-badpath.*`](./structure.probes/) |
| P05 | `tldr structure backend/db.py -f sarif` | format-reject | 1 | [`05-format-reject-sarif.*`](./structure.probes/) |
| P06 | `tldr structure backend/db.py -f text` | format-text | 0 | [`06-format-text.*`](./structure.probes/) |
| P07 | `tldr structure backend -m 5` | flag-max-results | 0 | [`07-max-results-5.*`](./structure.probes/) |
| P08 | `tldr structure backend/db.py -l python` | flag-lang-explicit | 0 | [`08-lang-python.*`](./structure.probes/) |
| P09 | `tldr structure backend/db.py -l rust` | flag-lang-mismatch | 0 | [`09-lang-mismatch.*`](./structure.probes/) |
| P10 | `tldr structure backend/db.py -f compact` | format-compact | 0 | [`10-format-compact.*`](./structure.probes/) |
| P11 | `tldr structure /tmp/tldr-structure-empty` | boundary-empty-dir | 0 | [`11-empty-dir.*`](./structure.probes/) |
| P12 | `tldr structure backend/db.py` *(daemon stopped)* | env-cold-daemon | 0 | [`12-cold-daemon.*`](./structure.probes/) |
| P13 | `tldr structure backend/db.py` *(after `tldr warm`)* | env-warm-daemon | 0 | [`13-warm-daemon.*`](./structure.probes/) |

### Observations

- **P01 (file target, 121 lines):** Returns `{root, language, files[]}`. The `root` echoes the passed path; `files[].path` is relative to the root. Confirms `structure` accepts a single file, despite the `--help` text saying "Directory to scan."
- **P02 (directory, 18,151 lines pre-truncation):** Output exceeded the 500-line cap and was truncated per protocol §5. Stock-Monitor's `backend/` contains ~56 Python files; the JSON aggregates every function, class, and import across all of them.
- **P04 (bad path):** stderr `Error: Path not found: <path>`, exit **1** (note: differs from `tree`'s exit 2). Source: `structure.rs:38-40` uses `anyhow::bail!`. **Recovery hint:** validate path exists before invoking, or use `tldr tree <ancestor>` to discover valid paths.
- **P05 (sarif rejection):** stderr `Error: --format sarif not supported by structure. Use --format json. SARIF is only emitted by: vuln, clones.`, exit 1. Same validator path as `tree`.
- **P06 (text format, 16 lines):** Pretty-printed hierarchy with `(L:NN)` line annotations for each function — very chat-friendly but harder to parse.
- **P07 (`-m 5`, 556 lines):** Cap honored — only 5 files in the `files[]` array, though stdout was longer because of nested structure detail. `-m 0` (default) is unlimited.
- **P08 (`-l python` explicit):** Output **identical** to P01 (which auto-detected). Explicit flag is redundant when detection succeeds.
- **P09 (`-l rust` mismatch):** **Silent failure.** Exit 0, JSON returns `"language": "rust"` with empty `imports`/`definitions`. The Rust tree-sitter parser ran against Python source and extracted nothing. No warning. **This is the most important agent-facing constraint of this command.**
- **P10 (compact, 1 line / ~4KB):** Same content as P01, all whitespace stripped.
- **P11 (empty dir):** Exit 0. Output `{root, language: null, files: [], warnings: ["No source files found in directory"]}`. Warnings array is part of the JSON contract — agents should check it.
- **P12 (cold daemon):** Stopped daemon first; exit 0, 121 lines. Identical to P13.
- **P13 (warm daemon, after `tldr warm`):** Cache populated; exit 0, 121 lines. Output byte-identical to P12. For a single-file target on a small project, the daemon route is fast either way; expect a more measurable cold/warm difference on directory-scale calls — see Architectural Deep Dive.

---

## Source Code Reality

**Target file:** `crates/tldr-cli/src/commands/structure.rs` (pinned to upstream commit `6c4011a`).

**Argument definition (`structure.rs:18-32`):**
```rust
#[derive(Debug, Args)]
pub struct StructureArgs {
    /// Directory to scan (default: current directory)
    #[arg(default_value = ".")]
    pub path: PathBuf,

    /// Programming language (auto-detected if not specified)
    #[arg(long, short = 'l')]
    pub lang: Option<Language>,

    /// Maximum number of files to process (0 = unlimited)
    #[arg(long, short = 'm', default_value = "0")]
    pub max_results: usize,
}
```
Confirms: `path` defaults to `.`, `lang` is optional, `max_results` defaults to 0 (unlimited).

**Path validation (`structure.rs:38-41`):**
```rust
// Validate path exists BEFORE language detection / progress banner
// (lang-detect-default-v1: avoid printing misleading "(Python)" banner
// when the path doesn't exist and from_directory silently returns None.)
if !self.path.exists() {
    anyhow::bail!("Path not found: {}", self.path.display());
}
```
**Reveals:** path validation happens *before* the language banner — a fix for an upstream bug where `Path not found` errors used to print `(Python)` first. Also explains P04's exit code (1) via `anyhow::bail!`.

**Language defaulting cascade (`structure.rs:43-46`):**
```rust
let language = self
    .lang
    .unwrap_or_else(|| Language::from_directory(&self.path).unwrap_or(Language::Python));
```
**Critical hidden constraint:** the cascade is `explicit -l flag → Language::from_directory(path) → Language::Python fallback`. If auto-detection fails (e.g., empty dir, mixed-language repo), **Python is the silent default**. Combined with P09's finding, this means **mis-typed extension-less files in non-Python codebases may be analyzed as Python silently**.

**Daemon-route shortcut (`structure.rs:49-62`):**
```rust
if let Some(structure) = try_daemon_route::<CodeStructure>(
    &self.path,
    "structure",
    params_with_path_lang(&self.path, Some(language.as_str())),
) { ... }
```
The cache key includes language (`params_with_path_lang`), so changing `-l` between calls invalidates cache and forces recompute. Unlike `tree`, where the cached `FileTree` ignores filter flags, `structure`'s cache properly partitions on language.

**Fallback compute (`structure.rs:65-80`):**
```rust
let structure = get_code_structure(
    &self.path,
    language,
    self.max_results,
    Some(&IgnoreSpec::default()),
)?;
```
`--max-results` only applies in the fallback path. When the daemon serves a cached result, the cap is ignored. **For deterministic capping, run against a cold daemon or accept that the cached full extraction is returned.**

**Format validator** confirmed at `crates/tldr-cli/src/output.rs::validate_format_for_command` — `structure` is in neither `SARIF_SUPPORTED` nor `DOT_SUPPORTED`, so `-f sarif`/`-f dot` reject as observed in P05.

**Module-level comment (`structure.rs:1-4`):**
```rust
//! Structure command - Show code structure
//! Auto-routes through daemon when available for ~35x speedup.
```

---

## Architectural Deep Dive

- **Engine:** Tree-sitter AST parser per language. Extracts function/class/import declarations from the AST and serializes to `CodeStructure`.
- **Cache layer:** Daemon-backed SQLite cache keyed by `(path, language)`. Cache invalidation is correct on language change; not on `--max-results` change. ~35x source-stated speedup on warm cache.
- **Language detection:** Cascade in `structure.rs:43-46`. Fallback is **always Python**. Single files use extension-based detection; directories use file-count heuristics.
- **Filter timing:** `--max-results` only applies on the fallback compute path. Cached results are returned unfiltered.
- **LLM cognitive load:** Replaces "read 50 files to figure out what functions exist." One JSON call gives the agent the full function signature inventory + line numbers, which it can then feed into `tldr extract`, `tldr impact`, or `tldr slice` for deeper analysis.

---

## Intent & Routing

- **User/Agent Goal:** Get a function/class/import inventory of a file or directory, with line numbers for follow-up commands.
- **When to choose this over similar tools:**
  - Use *instead of* `grep "^def\|^class"` to get structured output with line numbers and import context.
  - Use *instead of* reading file contents when you only need to know what's defined.
  - Use *before* `tldr extract <file>` if you need a roster across multiple files; use `extract` if you need full bodies of one file.
- **Prerequisites:** None.
- **Composes well with:**
  - `tldr tree` → discover files → `tldr structure <file>` to learn its API → `tldr extract <file>` to see function bodies.
  - `tldr structure <dir>` → identify high-value files → `tldr impact <function>` to assess blast radius.

---

## Agent Synthesis

> **How to use `tldr structure`:**
> Use to get the function/class/import inventory of a file or directory, with line numbers for follow-up calls. Returns JSON with a `files[]` array; each file lists its `classes`, `method_infos`, `imports`, and `definitions`. Despite the `--help` saying "Directory to scan," it accepts a single file path too.
>
> **Crucial Rules:**
> - **`[PATH]` is optional** — defaults to `.`.
> - **Do NOT pass `-l <lang>` unless you have verified the target's actual language.** A mismatched language silently produces a valid-looking but empty extraction (P09). Auto-detection is reliable; trust it.
> - **Language fallback is Python.** If auto-detection fails (unknown extension, mixed-language dir), the parser silently treats the input as Python. Verify the `language` field in the response.
> - **`-f sarif` and `-f dot` are rejected** (exit 1). Stick to `json` (default), `text`, or `compact`.
> - **Bad path returns exit 1** (different from `tree` which exits 2 — `structure` uses `anyhow::bail!`).
> - **`--max-results` (`-m N`) caps the number of files processed in the fallback compute path** — but does **not** filter cached daemon results. For deterministic capping, run against a cold daemon.
> - **Empty directories are not errors.** Returns `files: []` and `warnings: ["No source files found in directory"]`, exit 0. Agents should check the `warnings` array.
> - **Output can be huge** on directory targets — Stock-Monitor's `backend/` is ~18k lines of JSON. Use a single file or `-m N` to bound output.
>
> **Commands:**
> - Single file: `tldr structure <file>`
> - Directory inventory: `tldr structure <dir>`
> - Capped: `tldr structure <dir> -m 10`
> - Human-readable: `tldr structure <file> -f text`
> - Single-line for piping: `tldr structure <file> -f compact`
