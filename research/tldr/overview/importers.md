# Command: `tldr importers`

## Environment Pin

| Field | Value |
|---|---|
| `tldr --version` | 0.4.0 |
| Build features | `semantic` |
| Target repo | Stock-Monitor @ commit `e601869` (mixed Python + TypeScript webui) |
| Upstream `tldr-code` pinned to | local clone @ `6c4011a` (release v0.4.0) |
| Daemon state at probe time | mixed (probe.sh cycles cold→warm; P16/P19 cold, P17/P18/P21 warm) |
| OS | darwin 25.2.0 |
| Probe date | 2026-05-22 |

Re-run all evidence via [`importers.probes/probe.sh`](./importers.probes/probe.sh).

---

## Ground Truth (`tldr importers --help`)

```text
Find files that import a given module

Usage: tldr importers [OPTIONS] <MODULE> [PATH]

Arguments:
  <MODULE>
          Module name to search for

  [PATH]
          Directory to search (default: current directory)

          [default: .]

Options:
  -l, --lang <LANG>
          Programming language (auto-detected from directory if not specified)

  -m, --limit <LIMIT>
          Maximum number of importing files to show (0 = unlimited)

          [default: 50]

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
| Formats that work | `json`, `text`, `compact` (P02, P06, P07) |
| Formats that error | `sarif`, `dot` (P05, P08: exit 1) |
| Typical output size | small (<1 KB empty result; ~3–10 KB for popular modules) |

**Top-level keys (JSON, `ImportersReport`):**
- `module` (`string`) — echoes the queried MODULE name verbatim
- `importers` (`array<ImporterInfo>`) — files that import the module, truncated client-side to `--limit` entries (default 50)
- `total` (`usize`) — **count BEFORE `--limit` truncation** (P09 proves: `--limit 1` returns 1 importer but `total: 21`)

**`ImporterInfo` shape:** `{ file: string (path), line: u32 (1-indexed), import_statement: string (verbatim line from source) }`.

**Empty-result shape (P13):**
```json
{
  "module": "absolutely_no_such_module",
  "importers": [],
  "total": 0
}
```
Exit code is **0** — "no importers" is a successful empty result, not an error.

**Error shapes (all stderr):**
- Missing MODULE: clap-style `"error: the following required arguments were not provided: <MODULE> …"` → exit **2**
- Path not found: `"Error: Path not found: /no/such/dir"` → exit **1** (uses `anyhow::bail!`, NOT a typed FileNotFound — so NO exit 5 like `definition`/`explain`)
- Format reject: `"Error: --format sarif not supported by importers. Use --format json. SARIF is only emitted by: vuln, clones."` → exit **1**
- Bad `--lang`: clap-style `"error: invalid value 'X' for '--lang <LANG>': Unknown language: X"` → exit **2**

---

## Probe Matrix

| # | Probe | Type | Exit | Captured |
|---|-------|------|------|----------|
| P01 | `tldr importers backend.providers.base` *(default PATH=`.`)* | happy (silent miss — see P19) | 0 | [`01-happy.*`](./importers.probes/) |
| P02 | `tldr importers pandas backend` | happy-scale | 0 | [`02-happy-scale.*`](./importers.probes/) |
| P03 | `tldr importers` *(no MODULE)* | failure-missing-input | 2 | [`03-missing-arg.*`](./importers.probes/) |
| P04 | `tldr importers pandas /no/such/dir` | failure-badpath | 1 | [`04-badpath.*`](./importers.probes/) |
| P05 | `tldr importers ... -f sarif` | format-reject | 1 | [`05-format-reject-sarif.*`](./importers.probes/) |
| P06 | `tldr importers ... -f text` | format-text | 0 | [`06-format-text.*`](./importers.probes/) |
| P07 | `tldr importers ... -f compact` | format-compact | 0 | [`07-format-compact.*`](./importers.probes/) |
| P08 | `tldr importers ... -f dot` | format-reject-dot | 1 | [`08-format-reject-dot.*`](./importers.probes/) |
| P09 | `tldr importers ... --limit 1` | limit-truncate | 0 | [`09-limit-1.*`](./importers.probes/) |
| P10 | `tldr importers ... --limit 0` | limit-unlimited | 0 | [`10-limit-zero.*`](./importers.probes/) |
| P11 | `tldr importers pandas backend -l typescript` *(cold)* | lang-override-empty | 0 | [`11-lang-override.*`](./importers.probes/) |
| P12 | `tldr importers ... -l brainfuck` | bad-lang (clap) | 2 | [`12-bad-lang.*`](./importers.probes/) |
| P13 | `tldr importers absolutely_no_such_module backend` | empty-result | 0 | [`13-empty-result.*`](./importers.probes/) |
| P14 | `tldr importers backend.providers.base` *(no PATH)* | dotted-module | 0 | [`14-dotted-module.*`](./importers.probes/) |
| P15 | `tldr importers pandas backend -q` | quiet | 0 | [`15-quiet.*`](./importers.probes/) |
| P16 | `tldr importers pandas backend` *(daemon stopped)* | cold-daemon | 0 | [`16-cold-daemon.*`](./importers.probes/) |
| P17 | `tldr importers pandas backend` *(daemon warm)* | warm-daemon | 0 | [`17-warm-daemon.*`](./importers.probes/) |
| P18 | `tldr importers pandas backend -l typescript` *(daemon warm)* | warm-daemon-lang-ignored | 0 | [`18-warm-daemon-lang-override.*`](./importers.probes/) |
| P19 | `tldr importers backend.providers.base` *(cold, default PATH)* | default-path-bug | 0 | [`19-default-path-bug.*`](./importers.probes/) |
| P20 | `tldr importers backend.providers.base -l python` *(cold, default PATH)* | default-path-lang-fix | 0 | [`20-default-path-lang-python.*`](./importers.probes/) |
| P21 | `tldr importers backend.providers.base` *(warm, default PATH)* | default-path-warm-fix | 0 | [`21-default-path-warm-daemon.*`](./importers.probes/) |

### Observations

- **P01** — Returns 0 importers for `backend.providers.base` from default PATH=`.` even though three files (`backend/providers/__init__.py`, `backend/providers/dhan.py`, `backend/providers/yahoo.py`) import it. The cold direct-compute path silently picks a non-Python language from the mixed-language project root via `Language::from_directory(".")`. See P19/P20/P21 for the diagnostic triad.
- **P02** — `pandas` imported from `backend/` (subdirectory) finds 21 importers (`total: 21`). Same data via cold (P02, P16) and warm (P17) — direct-compute and daemon route agree when PATH is unambiguous and Python is auto-detected correctly.
- **P03** — stderr `"error: the following required arguments were not provided: <MODULE>"`, exit `2`. clap enforces MODULE because `ImportersArgs.module` is `String` (not `Option<String>`).
- **P04** — stderr `"Error: Path not found: /no/such/dir"`, exit `1`. **Notable divergence from `tldr definition`/`tldr explain`:** uses `anyhow::bail!` (`importers.rs:45`) rather than the typed `RemainingError::FileNotFound`, so it does NOT get the standardized exit code **5**. Path-validation exit semantics are command-specific.
- **P05** — stderr `"Error: --format sarif not supported by importers. Use --format json. SARIF is only emitted by: vuln, clones."`, exit `1`.
- **P06** — Text format renders a bold header (`"pandas" imported by 21 files`) plus per-file lines via `format_importers_text`. Progress message `"Finding files that import 'pandas' in backend (Python)..."` is on stderr — language name is echoed (capitalized!) in the progress banner.
- **P07** — Single-line minified JSON, identical schema to P02.
- **P08** — stderr `"Error: --format dot not supported by importers. Use --format json. DOT is only emitted by: clones, deps, calls, impact, hubs, inheritance."`, exit `1`.
- **P09** — `--limit 1` truncates the `importers` array to 1 entry but **`total: 21` is preserved** (unfiltered count). Agents can detect truncation by comparing `importers.length` to `total`.
- **P10** — `--limit 0` skips truncation entirely (full list); `total` is the same 21 — identical bytes to P02 because pandas has fewer than 50 importers.
- **P11** — Cold path with `-l typescript` for a Python-only query: 0 importers (TS files don't import `pandas`). Exit 0 — typed empty result, not an error.
- **P12** — clap-style: `"error: invalid value 'brainfuck' for '--lang <LANG>': Unknown language: brainfuck"`, exit `2`.
- **P13** — Empty result is a typed JSON `{ module, importers: [], total: 0 }`, exit 0 — same shape as a legitimate zero-importer module like a top-level CLI script.
- **P14** — Same as P01 (PATH defaults to `.`); confirms the dotted-module + default-path miss.
- **P15** — `-q` suppresses stderr progress; stdout JSON unaffected.
- **P16** — Cold-daemon for `pandas backend` returns 21 importers (111 lines stdout).
- **P17** — Warm-daemon for `pandas backend` returns 21 importers — **byte-identical** to P16/P02 (verified via `diff`). The daemon and direct-compute paths agree when language detection agrees.
- **P18** — Warm-daemon with `-l typescript` returns 0 importers. **The CLI `--lang` flag is NOT forwarded to the daemon** — `params_with_module` (`daemon_router.rs:216-223`) only emits `module` and `path` keys; there is no `language` field. The empty result occurs because either (a) the daemon's typescript-language importers cache is empty for `pandas`, or (b) the daemon route returned None and fell through to direct-compute which honored `-l typescript`. Either way, agents must not rely on `-l` to disambiguate via the daemon path.
- **P19** — **Bug reproduced:** cold direct-compute with default PATH=`.` returns 0 importers for `backend.providers.base`. `Language::from_directory(".")` for a mixed-language project root (Stock-Monitor has `webui/` TypeScript) picks a non-Python language, and find_importers walks only `.ts`/`.tsx` files, missing the `.py` matches entirely. **The `unwrap_or(Language::Python)` fallback only fires when `from_directory` returns None**, not when it returns a wrong-language guess (`importers.rs:60-62`).
- **P20** — Workaround for P19: explicit `-l python` on the same query finds all 3 importers. Exit 0, `total: 3`.
- **P21** — Workaround for P19: warm-daemon (with the project indexed) on the same query finds all 3. Daemon path bypasses the buggy directory-level language guess.

---

## Source Code Reality

**Target file(s):**
- `crates/tldr-cli/src/commands/importers.rs` (115 lines — small, focused)
- `crates/tldr-core/src/analysis/importers.rs` (200+ lines — the actual matcher logic)
- `crates/tldr-cli/src/commands/daemon_router.rs:216-223` (`params_with_module`)
- `crates/tldr-cli/src/output.rs:113` (`validate_format_for_command`)

**Pinned to upstream commit:** `6c4011a` (release v0.4.0)

**Argument struct:**
```rust
// crates/tldr-cli/src/commands/importers.rs:19-35
#[derive(Debug, Args)]
pub struct ImportersArgs {
    /// Module name to search for
    pub module: String,
    /// Directory to search (default: current directory)
    #[arg(default_value = ".")]
    pub path: PathBuf,
    /// Programming language (auto-detected from directory if not specified)
    #[arg(long, short = 'l')]
    pub lang: Option<Language>,
    /// Maximum number of importing files to show (0 = unlimited)
    #[arg(long, short = 'm', default_value = "50")]
    pub limit: usize,
}
```
Reveals: `module` is required (`String`, not `Option<String>` → clap exit 2); `path` defaults to `.`; `lang` is `Option<Language>` (clap pre-parses to the enum, so bad values → exit 2). `--limit` short flag is **`-m`** (uncommon — most tldr commands use `--limit` long-only).

**Path validation:**
```rust
// importers.rs:43-46
if !self.path.exists() {
    anyhow::bail!("Path not found: {}", self.path.display());
}
```
Reveals: `anyhow::bail!` produces exit code **1**, not the typed-error exit **5** used by `tldr definition`/`tldr explain`. The path-not-found message also begins with capital "P" (`"Path not found"`), not lowercase like `RemainingError::FileNotFound`'s `"file not found"`. **Cross-command exit-code inconsistency.**

**Default language detection (the P19 root cause):**
```rust
// importers.rs:59-62
let language = self
    .lang
    .unwrap_or_else(|| Language::from_directory(&self.path).unwrap_or(Language::Python));
```
Reveals: when `--lang` is not passed, `Language::from_directory(<path>)` runs. The `unwrap_or(Language::Python)` fallback **only fires when `from_directory` returns `None`**, not when it returns a non-Python language. For a mixed-language project root, `from_directory` picks the dominant extension and never returns `None`. Hence the silent miss in P19.

**Truncation preserves total:**
```rust
// importers.rs:80-84
fn apply_limit(&self, report: &mut ImportersReport) {
    if self.limit > 0 && report.importers.len() > self.limit {
        report.importers.truncate(self.limit);  // mutates importers only
    }
}
```
Reveals: `apply_limit` truncates the `importers` Vec but never touches `report.total`, which was set by `find_importers` (`tldr-core/src/analysis/importers.rs:57`) to the unfiltered length. P09 proves: with `--limit 1`, `importers.len() == 1` but `total == 21`.

**Daemon route ignores --lang:**
```rust
// importers.rs:49-57
if let Some(mut result) = try_daemon_route::<ImportersReport>(
    &self.path,
    "importers",
    params_with_module(&self.module, Some(&self.path)),  // no lang
) {
    self.apply_limit(&mut result);
    self.output_result(&writer, &result)?;
    return Ok(());
}
```
And `params_with_module` (`daemon_router.rs:216-223`) emits only `module` and `path` — no `language` key. **The daemon route is language-agnostic from the CLI's perspective.**

**Format validation:** confirmed at `crates/tldr-cli/src/output.rs:113-163` — `importers` is in neither `SARIF_SUPPORTED` nor `DOT_SUPPORTED`.

**`module_matches` uses Python's submodule-bidirectional rule** (`tldr-core/src/analysis/importers.rs:112-131`):
- Exact match (`backend.providers.base == backend.providers.base`)
- Submodule (`backend.providers.base.utils` matches query `backend.providers.base`)
- Reverse submodule (query `backend.providers.base` matches `backend` import)
- Relative-import normalization (strip leading dots both sides)

Same bidirectional rule extends to Scala/Kotlin/Java (per `language-specific-bugs-v1` P14.AGG14-11 comment block).

---

## Architectural Deep Dive

- **Under the hood:** Two-stage pipeline. (1) `get_file_tree` walks PATH filtering by `Language::extensions()`; (2) for each file, `get_imports` parses via tree-sitter to produce `Vec<ImportInfo>`, and `module_matches` applies language-specific module-matching rules. The daemon caches a `module → importing files` index per language; cold-path direct-compute rebuilds this on every call.
- **Performance:** Cold ~1s on Stock-Monitor `backend/` (~56 Python files); warm sub-100ms because the daemon serves from cache. The "auto-route through daemon for ~35x speedup" claim in the source docstring (`importers.rs:4`) is in the ballpark for repeated queries on warm caches.
- **LLM cognitive load:** Replaces `grep -rn 'from X' .` for finding consumers of a module. Returns structured JSON with line numbers + the verbatim import statement, so an agent can directly cite call sites without re-reading files. Schema is small (3 keys), feeds easily into follow-on tools like `tldr explain` on the importing files.

---

## Intent & Routing

- **User/Agent Goal:** answer "who depends on this module?" — the reverse of `tldr imports`. Use before refactoring or deleting a module to enumerate consumers.
- **When to choose this over similar tools:**
  - Over `grep`: returns structured JSON with line numbers, handles language-specific import syntax (Python `from X import Y`, TS `import X from "Y"`, Go package paths, Scala dotted FQCNs).
  - Over `tldr deps`: `deps` gives a directional dependency graph between files/modules; `importers` is reverse single-module lookup.
  - Over `tldr references`: `references` finds usages of a SYMBOL; `importers` finds usages of a MODULE (a coarser unit).
- **Prerequisites (composition):**
  - When the project root has mixed languages, pass explicit `-l <lang>` or scope PATH to a single-language subdirectory — auto-detect on a mixed root silently picks wrong (P19).
  - For warm/cached results, run `tldr daemon start --project <ROOT> && tldr warm <ROOT>` first.
  - The MODULE argument should match the import-site syntax: Python uses dotted paths (`backend.providers.base`), TS/JS uses module specifiers (`react`, `./utils`), Go uses package paths.

---

## Agent Synthesis

> **How to use `tldr importers`:**
> Reverse module-lookup. `tldr importers <MODULE> [PATH]` finds every file in PATH that imports MODULE. Default PATH is `.`; default `--limit` is 50; `--limit 0` is unlimited. Default format is JSON; text format adds a bold header line. Exit codes: 0 ok (including empty-importers result), 1 path-not-found / format-reject (note: NOT exit 5 like other commands — uses anyhow::bail!), 2 missing MODULE / bad `--lang`. Auto-routes through the daemon when running for ~35x speedup on repeat queries; falls back to direct-compute otherwise.
>
> **Crucial Rules:**
> - **Language auto-detect from a mixed-language project root silently picks wrong.** `Language::from_directory(".")` on Stock-Monitor (Python + TypeScript) selects a non-Python language and returns 0 importers for a Python module. The `unwrap_or(Language::Python)` fallback (`importers.rs:60-62`) fires ONLY when `from_directory` returns None, not when it picks wrong. **Fix:** pass `-l python` explicitly OR scope PATH to a single-language subdirectory (P19 vs P20/P21).
> - **`-l <LANG>` is ignored by the daemon route.** `params_with_module` (`daemon_router.rs:216-223`) does not forward the lang flag. To force the language-aware code path: stop the daemon (`tldr daemon stop`) and supply `-l` to the cold path. The daemon path uses its own per-language index regardless of CLI flag.
> - **Path-not-found exit code is 1, NOT 5.** Cross-command divergence — `tldr definition` and `tldr explain` use typed `FileNotFound→5`, but `importers` uses `anyhow::bail!` (`importers.rs:45`) which collapses to 1.
> - **`--limit` preserves `total`.** With `--limit 1`, `importers` has one entry but `total` shows the unfiltered count (P09: `total: 21`, `importers.length: 1`). Compare `importers.length` to `total` to detect truncation. Default `--limit 50` may silently truncate widely-imported modules; use `--limit 0` for complete enumeration.
> - **MODULE matching is bidirectional for Python (and Scala/Kotlin/Java).** Query `backend.providers.base` matches `backend.providers.base.utils` (descendant) AND a `backend` import in a file (ancestor) — see `module_matches` (`tldr-core/src/analysis/importers.rs:112-131`). A deep dotted-path query may surface surprising matches at upper levels of the import tree.
> - **Empty importers is a normal success (exit 0).** `{ module, importers: [], total: 0 }` is the typed empty result for "queried module exists but nothing imports it" — same JSON shape as "queried module is fake" (P13). Treat exit 0 + empty as "no consumers"; don't conflate with errors.
> - **The `-m` short flag for `--limit` is unusual.** Most tldr commands use `--limit` long-only; this command has `-m`. (`importers.rs:33-34`.)
>
> **Command:** `tldr importers <MODULE> [PATH]`
>
> **With common flags:** `tldr importers <MODULE> <PATH> -l <lang> --limit 0 -f compact` (use when you need a complete, language-specific count for downstream tooling on a mixed-language project).
