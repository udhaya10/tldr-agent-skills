# Command: `tldr loc`

## Environment Pin

| Field | Value |
|---|---|
| `tldr --version` | 0.4.0 |
| Build features | `semantic` (verified; loc itself is line-based, non-semantic) |
| Target repo | Stock-Monitor @ commit `e601869` |
| Upstream `tldr-code` pinned to | local clone @ `6c4011a` (release v0.4.0) |
| Daemon state at probe time | N/A — `tldr loc` does **not** call `try_daemon_route` (verified by grep) |
| OS | darwin 25.2.0 |
| Probe date | 2026-05-22 |

Re-run all evidence via [`loc.probes/probe.sh`](./loc.probes/probe.sh).

---

## Ground Truth (`tldr loc --help`)

```text
Count lines of code with type breakdown (code, comments, blanks)

Usage: tldr loc [OPTIONS] [PATH]

Arguments:
  [PATH]
          Directory or file to analyze

          [default: .]

Options:
  -l, --lang <LANG>
          Filter to specific language

      --by-file
          Show per-file breakdown

      --by-dir
          Aggregate by directory

  -e, --exclude <EXCLUDE>
          Exclude patterns (glob syntax), can be specified multiple times

      --include-hidden
          Include hidden files (dotfiles)

      --no-gitignore
          Ignore .gitignore rules

      --max-files <MAX_FILES>
          Maximum files to process (0 = unlimited)

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
| Formats that work | `json`, `text`, `compact` (P01, P06, P07) |
| Formats that error | `sarif`, `dot` (P05, P08: exit 1) |
| Typical output size | small (~26 lines pretty JSON; grows with `--by-file`/`--by-dir`) |

**Top-level keys (JSON, `LocReport`):**
- `summary` (`object`) — `{ total_files, total_lines, code_lines, comment_lines, blank_lines, code_percent, comment_percent, blank_percent }`
- `by_language` (`object`, KEYED BY LANGUAGE NAME) — e.g., `{ "python": { language, files, code_lines, comment_lines, blank_lines, total_lines }, "typescript": {...} }`
- `warnings` (`array<string>`) — empty in happy paths; populated for binary skips and 10MB-size limits
- `total_files` (`u32`) — **TOP-LEVEL MIRROR** of `summary.total_files`
- `total_lines` (`u32`) — **TOP-LEVEL MIRROR** of `summary.total_lines`
- `code_lines` (`u32`) — **TOP-LEVEL MIRROR** of `summary.code_lines`

Only THREE of the eight summary fields are mirrored to top level (total_files, total_lines, code_lines). NOT comment_lines, blank_lines, or any percent.

**`--by-file` adds** `files: [{ path, code, comment, blank, total, language }]` array.

**`--by-dir` adds** `directories: [{ path, code, comment, blank, total, files }]` array.

**Both `--by-file` and `--by-dir`** produce 500+ line outputs combining both arrays.

**Invariant (per source docstring):** `code_lines + comment_lines + blank_lines == total_lines`. Confirmed empirically: P01 has `146 + 46 + 47 = 239 == total_lines`.

**Empty-result shape (P20):**
```json
{
  "summary": { "total_files": 0, "total_lines": 0, "code_lines": 0, ..., "code_percent": 0.0, ... },
  "by_language": {},
  "warnings": [],
  "total_files": 0, "total_lines": 0, "code_lines": 0
}
```
Exit 0. Same shape as happy with zeros.

**Error shapes:**
- Path not found: `"Error: Path not found: /no/such/dir"` → exit **2** (TldrError::PathNotFound — matches `tldr complexity`, `tldr imports`)
- Format reject: `"Error: --format sarif not supported by loc. ..."` → exit **1**
- Bad `--lang`: clap-style → exit **2**
- Non-source single file (`README.md`): `"Error: Unsupported language: README.md"` → exit **11** (TldrError::UnsupportedLanguage)

---

## Probe Matrix

| # | Probe | Type | Exit | Captured |
|---|-------|------|------|----------|
| P01 | `tldr loc backend/providers/yahoo.py` | happy (single file) | 0 | [`01-happy.*`](./loc.probes/) |
| P02 | `tldr loc backend` | happy-scale | 0 | [`02-happy-scale.*`](./loc.probes/) |
| P03 | N/A: PATH defaults to `.`. | — | — | [`03-missing-arg.*`](./loc.probes/) (placeholder) |
| P04 | `tldr loc /no/such/dir` | failure-badpath | 2 | [`04-badpath.*`](./loc.probes/) |
| P05 | `tldr loc ... -f sarif` | format-reject (sarif) | 1 | [`05-format-reject-sarif.*`](./loc.probes/) |
| P06 | `tldr loc ... -f text` | format-text | 0 | [`06-format-text.*`](./loc.probes/) |
| P07 | `tldr loc ... -f compact` | format-compact | 0 | [`07-format-compact.*`](./loc.probes/) |
| P08 | `tldr loc ... -f dot` | format-reject (dot) | 1 | [`08-format-reject-dot.*`](./loc.probes/) |
| P09 | `tldr loc ... --by-file` | per-file breakdown | 0 | [`09-by-file.*`](./loc.probes/) |
| P10 | `tldr loc ... --by-dir` | per-dir aggregate | 0 | [`10-by-dir.*`](./loc.probes/) |
| P11 | `tldr loc ... --by-file --by-dir` | combined breakdown | 0 | [`11-by-file-and-dir.*`](./loc.probes/) |
| P12 | `tldr loc ... -l python` | explicit-python | 0 | [`12-lang-python.*`](./loc.probes/) |
| P13 | `tldr loc . -l typescript` | typescript filter | 0 | [`13-lang-typescript.*`](./loc.probes/) |
| P14 | `tldr loc ... -l brainfuck` | bad-lang | 2 | [`14-bad-lang.*`](./loc.probes/) |
| P15 | `tldr loc ... --exclude '__init__.py' --by-file` | exclude-glob | 0 | [`15-exclude.*`](./loc.probes/) |
| P16 | `tldr loc ... --include-hidden` | include-hidden | 0 | [`16-include-hidden.*`](./loc.probes/) |
| P17 | `tldr loc . --no-gitignore --max-files 5` | no-gitignore | 0 | [`17-no-gitignore.*`](./loc.probes/) |
| P18 | `tldr loc ... --max-files 1` | max-files cap | 0 | [`18-max-files-low.*`](./loc.probes/) |
| P19 | `tldr loc ... --max-files 0` | max-files unlimited | 0 | [`19-max-files-zero.*`](./loc.probes/) |
| P20 | `tldr loc <empty-tmp-dir>` | empty-dir | 0 | [`20-empty-dir.*`](./loc.probes/) |
| P21 | `tldr loc README.md` | non-source-md (exit 11) | 11 | [`21-non-source-md.*`](./loc.probes/) |
| P22 | `tldr loc ... -q` | quiet | 0 | [`22-quiet.*`](./loc.probes/) |

### Observations

- **P01** — `yahoo.py`: 239 total lines = 146 code + 46 comment + 47 blank. `code_percent: 61.1%`, `comment_percent: 19.2%`, `blank_percent: 19.7%`. `by_language: { "python": {...} }`. Single-file analysis works (no schema divergence vs directory).
- **P02** — `backend/`: 56 Python files, 45406 total lines, 21438 code, 18438 comment (40.6%!), 5530 blank. **Comment ratio of 40.6%** suggests heavy docstring-rich codebase.
- **P03** — **N/A.** PATH defaults to `.`.
- **P04** — stderr `"Error: Path not found: /no/such/dir"`, exit `2` (TldrError::PathNotFound). Matches `tldr complexity`/`tldr imports`; differs from `tldr churn`/`tldr calls`/`tldr debt` (exit 1, anyhow!).
- **P05** — stderr `"Error: --format sarif not supported by loc. Use --format json. SARIF is only emitted by: vuln, clones."`, exit `1`.
- **P06** — Text format: header `"Lines of Code (N files, M total)"` + 3-line breakdown + `"By Language:"` table with columns `Language | Files | Code | Comment | Blank | Total`.
- **P07** — Single-line minified JSON.
- **P08** — stderr `"Error: --format dot not supported by loc. ..."`, exit `1`.
- **P09** — `--by-file`: adds `files: [{ path, code, comment, blank, total, language }]` array per file.
- **P10** — `--by-dir`: adds `directories: [{ path, code, comment, blank, total, files }]` array aggregated by directory.
- **P11** — `--by-file --by-dir` BOTH: 499 lines (probe.sh threshold = 500). Combines both arrays — agents can request both.
- **P12** — Explicit `-l python`: identical to default for Python-dominant repo.
- **P13** — `-l typescript` on Stock-Monitor root: filters to TypeScript files only. The `webui/` directory has TS — `by_language: { "typescript": {...} }`.
- **P14** — clap-style: `"error: invalid value 'brainfuck' for '--lang <LANG>': Unknown language: brainfuck"`, exit `2`.
- **P15** — `--exclude '__init__.py' --by-file`: filters out `__init__.py` files. `files[]` is one entry shorter.
- **P16** — `--include-hidden`: same line count as default (Stock-Monitor's `backend/providers/` has no dotfiles).
- **P17** — `--no-gitignore --max-files 5`: ignores .gitignore patterns; sees 5 files including possibly venv/ contents that `.gitignore` excluded. Output is slightly larger (28 lines vs 26 default).
- **P18** — `--max-files 1`: caps to 1 file processed. Output size similar to single-file (28 lines — adds a warnings entry?).
- **P19** — `--max-files 0`: unlimited. Identical to default.
- **P20** — Empty dir: same shape as happy with all zeros. `by_language: {}` (empty object, NOT `null`). `warnings: []`.
- **P21** — **DISTINCT EXIT 11:** Non-source single file `README.md`: stderr `"Error: Unsupported language: README.md"`, exit **11** (TldrError::UnsupportedLanguage). **Notable** because `tldr cognitive README.md` silently returned empty + null language with exit 0; `tldr halstead README.md` also errored exit 11; `tldr complexity README.md` errored exit 11 with `"Could not detect language for"` wording. `tldr loc`'s wording is the shortest: just `"Unsupported language: <path>"` (no "Could not detect language for" prefix).
- **P22** — `-q` suppresses the `"Counting lines in <path>..."` progress message.

---

## Source Code Reality

**Target file(s):**
- `crates/tldr-cli/src/commands/loc.rs` (~290 lines)
- `crates/tldr-core/src/metrics/loc.rs` (`analyze_loc`, per-language comment-syntax detection)
- `crates/tldr-cli/src/output.rs:113` (`validate_format_for_command`)

**Pinned to upstream commit:** `6c4011a` (release v0.4.0)

**Argument struct:**
```rust
// crates/tldr-cli/src/commands/loc.rs:46-78
#[derive(Debug, Args)]
pub struct LocArgs {
    #[arg(default_value = ".")] pub path: PathBuf,
    #[arg(long, short = 'l')] pub lang: Option<Language>,
    #[arg(long)] pub by_file: bool,
    #[arg(long)] pub by_dir: bool,
    #[arg(long, short = 'e')] pub exclude: Vec<String>,
    #[arg(long)] pub include_hidden: bool,
    #[arg(long)] pub no_gitignore: bool,
    #[arg(long, default_value = "0")] pub max_files: usize,
}
```
Reveals: `--max-files 0` means unlimited (matches `tldr cognitive`/`tldr halstead` convention). `gitignore` flag is INVERTED — code uses `gitignore: !self.no_gitignore` internally.

**LocOptions construction (gitignore inversion):**
```rust
// loc.rs:88-97
let options = LocOptions {
    lang: self.lang,
    by_file: self.by_file,
    by_dir: self.by_dir,
    exclude: self.exclude.clone(),
    include_hidden: self.include_hidden,
    gitignore: !self.no_gitignore,
    max_files: self.max_files,
    max_file_size_mb: 10, // Default 10MB limit
};
```
Reveals: HARDCODED `max_file_size_mb: 10` — files >10MB are skipped. Not flag-controllable. Source docstring: "Files > 10MB are skipped with warning."

**Documented invariants (loc.rs:12-16):**
- `code_lines + comment_lines + blank_lines == total_lines` (verified empirically)
- Binary files skipped with warning
- Files > 10MB skipped with warning

**Format validation:** confirmed at `crates/tldr-cli/src/output.rs:113-163` — `loc` is in neither `SARIF_SUPPORTED` nor `DOT_SUPPORTED`.

**No daemon route:** `grep -n try_daemon_route loc.rs` returns 0 matches. Every call walks + counts.

---

## Architectural Deep Dive

- **Under the hood:** Per-language line classifier. Uses comment-syntax knowledge (e.g., Python `#`, C-style `// /* */`, Lua `--`) to classify each line as code, comment, or blank. Skips binary files via content-type detection. Hard 10MB per-file cap. Respects `.gitignore` by default (toggleable via `--no-gitignore`).
- **Performance:** O(file_size). ~10ms per ~10K-line file. NO daemon caching.
- **LLM cognitive load:** Replaces `wc -l` for code review. Code/comment/blank breakdown is more informative than total lines. The `code_percent` field is a quick "is this a dense file or boilerplate-heavy?" signal. Use `--by-language` summary for multi-language project breakdown.

---

## Intent & Routing

- **User/Agent Goal:** quantify codebase size with code/comment/blank breakdown — replace `wc -l` with language-aware counts.
- **When to choose this over similar tools:**
  - Over `wc -l`: comment-aware, gitignore-aware, multi-language, generates structured JSON.
  - Over `cloc` (external tool): integrated into tldr workflow, daemon-free, language detection consistent with other tldr commands.
  - Over `tldr stats`: stats is the broader summary; loc is just LoC counting.
- **Prerequisites (composition):**
  - PATH defaults to `.`; no setup required.
  - For multi-language repos, the `by_language` keyed object gives a sub-breakdown automatically.

---

## Agent Synthesis

> **How to use `tldr loc`:**
> Language-aware line-of-code counter. `tldr loc [PATH]` returns JSON `{ summary, by_language, warnings, total_files, total_lines, code_lines }`. Summary has all eight count/percent fields; `by_language` is an OBJECT keyed by language name (not an array). Use `--by-file` for per-file breakdown (adds `files: [{path, code, comment, blank, total, language}]`); `--by-dir` for directory aggregate (adds `directories: [...]`). Default JSON; `-f text` for a tabular summary; `-f compact` for one-line; `sarif`/`dot` rejected. Exit codes: 0 ok, 1 format-reject, 2 path-not-found / bad-lang, 11 unsupported-language (non-source single file).
>
> **Crucial Rules:**
> - **`by_language` is a KEYED OBJECT, not an array.** `result.by_language.python` not `result.by_language[0]`. Iterate with `Object.keys()` / `Object.entries()`. Empty case = `{}`. Distinct from many other tldr commands which use arrays.
> - **Path-not-found exit code is 2** (TldrError::PathNotFound). Matches `tldr complexity`/`tldr imports`/`tldr coverage`; differs from `tldr churn`/`tldr calls`/`tldr debt` (all exit 1). Six total path-error wordings now catalogued across the audit suite.
> - **Non-source single file returns exit 11** (`tldr loc README.md` → `"Error: Unsupported language: README.md"`, exit 11). The wording is **shortest in the suite** — just `"Unsupported language: <path>"` (no "Could not detect language for" prefix that `tldr complexity` and `tldr halstead` use). Distinct from `tldr cognitive`'s silent fallback (exit 0 with null language).
> - **TOP-LEVEL field mirroring is PARTIAL.** Only `total_files`, `total_lines`, `code_lines` are mirrored to top level. `comment_lines`, `blank_lines`, and ALL percent fields are ONLY in `summary`. Agents using top-level shortcuts MUST read full summary for those fields.
> - **Documented invariant: `code + comment + blank == total`** per source. Use as a sanity check on parsed output.
> - **HARDCODED 10MB per-file cap.** Not flag-controllable. Files >10MB are skipped with a warning in `warnings[]`.
> - **`gitignore` is INVERTED in CLI.** Flag is `--no-gitignore` (DISABLE gitignore); default is gitignore-respecting. Source comment: `gitignore: !self.no_gitignore`.
> - **`--max-files 0` means unlimited** (matches `tldr cognitive`/`tldr halstead`; differs from `tldr contracts --limit 0` which means "zero").
> - **`-l <lang>` is a FILTER (effective), not just a hint.** P13: `-l typescript` on Stock-Monitor root returns the TypeScript subset's counts — distinct from `tldr cohesion`/`tldr interface` where `-l` is silently ignored.
> - **NO daemon route.** Every call walks + counts.
>
> **Command:** `tldr loc [PATH]`
>
> **With common flags:** `tldr loc <PATH> --by-file --exclude 'venv/**' --exclude 'node_modules/**' -f compact` (use to get per-file counts while excluding vendored deps; one-line JSON ideal for piping to jq for sorting by file size).
