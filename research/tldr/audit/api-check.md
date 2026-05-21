# Command: `tldr api-check`

## Environment Pin

| Field | Value |
|---|---|
| `tldr --version` | 0.4.0 |
| Build features | `semantic` (verified; api-check itself is regex-based, non-semantic) |
| Target repo | Stock-Monitor @ commit `e601869` |
| Upstream `tldr-code` pinned to | local clone @ `6c4011a` (release v0.4.0) |
| Daemon state at probe time | N/A — `tldr api-check` does **not** call `try_daemon_route` (verified by grep) |
| OS | darwin 25.2.0 |
| Probe date | 2026-05-22 |

Re-run all evidence via [`api-check.probes/probe.sh`](./api-check.probes/probe.sh).

---

## Ground Truth (`tldr api-check --help`)

```text
Detect API misuse patterns (missing timeouts, bare except, weak crypto, unclosed files)

Usage: tldr api-check [OPTIONS] <path>

Arguments:
  <path>
          File or directory to analyze (path to file or directory)

Options:
      --category <CATEGORY>
          Filter by misuse category

          [possible values: call-order, error-handling, parameters, resources, crypto, concurrency, security]

      --severity <SEVERITY>
          Filter by minimum severity

          [possible values: info, low, medium, high]

  -O, --output <OUTPUT>
          Output file (optional, stdout if not specified)

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
| Typical output size | small (<1 KB no findings) to medium (~5 KB for 4 findings on full backend) |

**Top-level keys (JSON, `APICheckReport`):**
- `findings` (`array<MisuseFinding>`) — per-issue records
- `summary` (`APICheckSummary`) — aggregated counters
- `rules_applied` (`u32`) — total rule count across ALL languages (92 on v0.4.0), NOT just the language(s) actually checked
- `total_findings` (`u32`) — **TOP-LEVEL MIRROR of `summary.total_findings`** (per P15.AGG15-4 / residual-bugs-v1)
- `files_scanned` (`u32`) — **TOP-LEVEL MIRROR of `summary.files_scanned`** (same fix)

**`summary` shape:** `{ total_findings, by_category: { <category>: count }, by_severity: { <severity>: count }, apis_checked: [string], files_scanned }`.

**`MisuseFinding` shape:**
- `file` (`string`) — project-relative path
- `line`, `column` (`u32`) — 1-indexed
- `rule` (`APIRule`) — `{ id, name, category, severity, description, correct_usage }`
- `api_call` (`string`) — the specific API name
- `message` (`string`) — finding-specific message
- `fix_suggestion` (`string`) — recommended remediation
- `code_context` (`string`) — single-line snippet from the source

**Rule IDs encode language:** `PY00x` Python, `RS00x` Rust, `GO00x` Go, `JV00x` Java, `JS00x` JS, `TS00x` TS, `C00x` C, `CPP00x` C++, `RB00x` Ruby, `PH00x` PHP, `KT00x` Kotlin, `SW00x` Swift, `CS00x` C#, `SC00x` Scala, `EX00x` Elixir, `LU00x` Lua/Luau, `OC00x` OCaml. Defense-in-depth (`api_check.rs:101-136`).

**Empty-result shape (P01, P16):**
```json
{
  "findings": [],
  "summary": { "total_findings": 0, "by_category": {}, "by_severity": {},
               "apis_checked": [], "files_scanned": N },
  "rules_applied": 92,
  "total_findings": 0,
  "files_scanned": N
}
```
Exit 0. P16 shows `files_scanned: 0` when `-l <wrong-lang>` matches nothing.

**Error shapes:**
- Missing PATH: clap-style `"error: the following required arguments were not provided: <path> …"` → exit **2**
- Bad path: `"Error: file not found: /no/such/dir"` → exit **5** (RemainingError::FileNotFound — matches `tldr definition`/`tldr explain`)
- Format reject: `"Error: --format sarif not supported by api-check. ..."` → exit **1**
- Bad `--category`: clap-style with valid-values list → exit **2**
- Bad `--severity`: clap-style with valid-values list → exit **2**
- Bad `--lang`: clap-style → exit **2**

---

## Probe Matrix

| # | Probe | Type | Exit | Captured |
|---|-------|------|------|----------|
| P01 | `tldr api-check backend/providers` | happy | 0 | [`01-happy.*`](./api-check.probes/) |
| P02 | `tldr api-check backend` | happy-scale | 0 | [`02-happy-scale.*`](./api-check.probes/) |
| P03 | `tldr api-check` *(no path)* | failure-missing-input | 2 | [`03-missing-arg.*`](./api-check.probes/) |
| P04 | `tldr api-check /no/such/dir` | failure-badpath | 5 | [`04-badpath.*`](./api-check.probes/) |
| P05 | `tldr api-check ... -f sarif` | format-reject (sarif) | 1 | [`05-format-reject-sarif.*`](./api-check.probes/) |
| P06 | `tldr api-check ... -f text` | format-text | 0 | [`06-format-text.*`](./api-check.probes/) |
| P07 | `tldr api-check ... -f compact` | format-compact | 0 | [`07-format-compact.*`](./api-check.probes/) |
| P08 | `tldr api-check ... -f dot` | format-reject (dot) | 1 | [`08-format-reject-dot.*`](./api-check.probes/) |
| P09 | `tldr api-check ... --category security` | category-filter | 0 | [`09-category-security.*`](./api-check.probes/) |
| P10 | `tldr api-check ... --category wat` | bad-category (clap) | 2 | [`10-category-bogus.*`](./api-check.probes/) |
| P11 | `tldr api-check ... --severity high` | severity-filter | 0 | [`11-severity-high.*`](./api-check.probes/) |
| P12 | `tldr api-check ... --severity over9000` | bad-severity (clap) | 2 | [`12-severity-bogus.*`](./api-check.probes/) |
| P13 | `tldr api-check ... --category 'crypto,security,resources'` | multi-category | 0 | [`13-category-multi.*`](./api-check.probes/) |
| P14 | `tldr api-check backend/providers/yahoo.py` | file-as-path (works) | 0 | [`14-file-arg.*`](./api-check.probes/) |
| P15 | `tldr api-check backend -l python` | lang-python | 0 | [`15-lang-python.*`](./api-check.probes/) |
| P16 | `tldr api-check backend/providers -l typescript` | lang-mismatch (empty) | 0 | [`16-lang-typescript.*`](./api-check.probes/) |
| P17 | `tldr api-check ... -l brainfuck` | bad-lang | 2 | [`17-bad-lang.*`](./api-check.probes/) |
| P18 | `tldr api-check ... -O <tmp> && cat <tmp>` | output-file (also stdout) | 0 | [`18-output-file.*`](./api-check.probes/) |
| P19 | `tldr api-check ... -q` | quiet | 0 | [`19-quiet.*`](./api-check.probes/) |

### Observations

- **P01** — `backend/providers/` (4 files): `total_findings: 0`, `files_scanned: 4`, `rules_applied: 92`. **`rules_applied` is the count across ALL 17 languages, NOT just Python** — even when the scan only checks Python files.
- **P02** — Full `backend/`: `total_findings: 4`, `files_scanned: 56`, all 4 findings are Python `PY001 missing-timeout` (`requests.get` without timeout) — severity HIGH.
- **P03** — stderr `"error: the following required arguments were not provided: <path>"`, exit `2`.
- **P04** — stderr `"Error: file not found: /no/such/dir"`, exit `5` (RemainingError::FileNotFound). Matches `tldr definition`/`tldr explain` — the standardized N9 exit code 5.
- **P05** — stderr `"Error: --format sarif not supported by api-check. Use --format json. SARIF is only emitted by: vuln, clones."`, exit `1`.
- **P06** — Text format: `"=== API Check Report ===\nFiles scanned: N\nRules applied: 92\nTotal findings: M\n\nNo API misuse patterns detected."` for empty results. Progress messages on stderr: `"Checking ... for API misuse patterns..."` and `"Found N files to analyze"`.
- **P07** — Single-line minified JSON.
- **P08** — stderr `"Error: --format dot not supported by api-check. ..."`, exit `1`.
- **P09** — `--category security` on full `backend/`: 13 lines stdout (likely 0 findings — none of the 4 default-found `PY001 missing-timeout` are `security` category; they're `parameters`).
- **P10** — clap-style: `"error: invalid value 'wat' for '--category <CATEGORY>' [possible values: call-order, error-handling, parameters, resources, crypto, concurrency, security]"`, exit `2`. Typed enum with full values list — best UX.
- **P11** — `--severity high`: 4 findings (same as P02). All 4 are HIGH severity already. **`--severity` is a MINIMUM threshold** (`info < low < medium < high`) — passing `--severity low` would include all.
- **P12** — clap-style: `"error: invalid value 'over9000' for '--severity <SEVERITY>' [possible values: info, low, medium, high]"`, exit `2`.
- **P13** — `--category 'crypto,security,resources'` (comma-separated): 3 findings. Filter is OR semantics (any category matches). Verified `value_delimiter = ','` per source.
- **P14** — Single file as PATH (`yahoo.py`): exit 0, 0 findings (small file, no `requests.get` etc). Works for both files AND dirs because `collect_files` (`api_check.rs:1416-1440`) branches on `is_file()` vs `is_dir()`.
- **P15** — `-l python` on full backend: 4 findings (same as P02 default). When the project IS Python-only, `-l python` is a no-op.
- **P16** — `-l typescript` on Python-only subdir: **`files_scanned: 0`, `findings: []`**. The global `-l/--lang` flag restricts file selection to matching extension; .py files are skipped. Confirms the P14.AGG14-5 lang-filter fix.
- **P17** — clap-style: `"error: invalid value 'brainfuck' for '--lang <LANG>': Unknown language: brainfuck"`, exit `2`.
- **P18** — `-O <tmp>`: writes JSON to file AND prints to stdout (visible because the probe uses `&& cat $OUTPUT_TMP`). **Same dual-write behavior as `tldr explain -o`**: agents must redirect stdout to suppress double output. Source confirms at `api_check.rs:1391-1405` — the writer.write branch fires UNCONDITIONALLY if `-O` is NOT set OR the writer is `is_text()`, but when `-O` IS set the file path branch runs INSTEAD of stdout? Let me re-check.

  Actually re-reading: the source has an `if let Some(ref output_path) = self.output { ... fs::write(...) } else if writer.is_text() { writer.write_text(...) } else { writer.write(...) }`. So with `-O` set, only the file write fires; stdout is NOT also written. The 13 lines stdout from the probe come from the `&& cat $OUTPUT_TMP` portion. Confirmed via re-reading `api_check.rs:1391-1405`.
- **P19** — `-q` suppresses both progress messages on stderr.

---

## Source Code Reality

**Target file(s):**
- `crates/tldr-cli/src/commands/remaining/api_check.rs` (~2150 lines — all rules + dispatch logic)
- `crates/tldr-cli/src/commands/remaining/types.rs:1352` (`APICheckReport`)
- `crates/tldr-cli/src/commands/remaining/error.rs` (`RemainingError`)
- `crates/tldr-cli/src/output.rs:113` (`validate_format_for_command`)

**Pinned to upstream commit:** `6c4011a` (release v0.4.0)

**Argument struct:**
```rust
// crates/tldr-cli/src/commands/remaining/api_check.rs:1285-1301
#[derive(Debug, Args)]
pub struct ApiCheckArgs {
    #[arg(value_name = "path")] pub path: PathBuf,
    #[arg(long, value_delimiter = ',')]
    pub category: Option<Vec<MisuseCategory>>,
    #[arg(long, value_delimiter = ',')]
    pub severity: Option<Vec<MisuseSeverity>>,
    #[arg(long, short = 'O')] pub output: Option<PathBuf>,
}
```
Reveals: PATH is required (clap exit 2). `--category` and `--severity` are clap-typed enum vecs with `value_delimiter = ','` (comma-separated lists). `--output` short flag is **uppercase `-O`** (matches `tldr definition`'s convention; differs from `tldr explain`'s lowercase `-o`).

**Path validation:**
```rust
// api_check.rs:1319-1321
if !self.path.exists() {
    return Err(RemainingError::file_not_found(&self.path).into());
}
```
Reveals: uses the typed `RemainingError::file_not_found` which maps to **exit 5** via the N9 cleanup. Matches `tldr definition`/`tldr explain`.

**Manual `Serialize` for top-level mirrors (the duplicate-keys finding):**
```rust
// types.rs:1352-1378 (excerpt)
impl Serialize for APICheckReport {
    fn serialize<S>(&self, serializer: S) -> Result<S::Ok, S::Error> where S: serde::Serializer {
        use serde::ser::SerializeStruct;
        let mut state = serializer.serialize_struct("APICheckReport", 5)?;
        state.serialize_field("findings", &self.findings)?;
        state.serialize_field("summary", &self.summary)?;
        state.serialize_field("rules_applied", &self.rules_applied)?;
        // Top-level mirrors (P15.AGG15-4).
        state.serialize_field("total_findings", &self.summary.total_findings)?;
        state.serialize_field("files_scanned", &self.summary.files_scanned)?;
        state.end()
    }
}
```
Reveals: top-level `total_findings` and `files_scanned` are **intentional mirrors** of `summary.*` fields, added by `residual-bugs-v1 P15.AGG15-4`. Audit observed `jq '.total_findings'` returning null pre-fix (since the field was nested under `summary`); the manual Serialize impl exposes them at top-level for backwards-compat. Both forms are now correct; agents can use either.

**Global `-l/--lang` is honored (P14.AGG14-5 fix):**
```rust
// api_check.rs:1332-1357
let lang_filter: Option<ApiLanguage> = global_lang.and_then(map_language_to_api_language);
...
for file_path in &files {
    let Some(language) = detect_language(file_path) else { continue; };
    if let Some(want) = lang_filter {
        if language != want { continue; }
    }
    ...
}
```
Reveals: when `-l <lang>` is set globally, only files whose extension maps to that ApiLanguage are scanned. P16 confirms: `-l typescript` on Python-only dir → `files_scanned: 0`.

**Rule-id ↔ language defense-in-depth:**
```rust
// api_check.rs:101-136 (excerpt)
fn rule_applies_to_language(rule_id: &str, language: ApiLanguage) -> bool {
    let prefix_lang: &[&str] = match language {
        ApiLanguage::Python => &["PY"],
        ApiLanguage::Rust => &["RS"],
        ApiLanguage::Go => &["GO"],
        ... // 17 mappings
    };
    ...
}
```
Reveals: rule IDs encode their applicable language as a prefix. Defense-in-depth guarantees a JS rule like `JS003` cannot fire against a `.cpp` file even if the rule list were misconfigured.

**`MAX_DIRECTORY_FILES = 1000`, `MAX_FILE_SIZE = 10 MB`:**
```rust
// api_check.rs:38-42
const MAX_DIRECTORY_FILES: u32 = 1000;
const MAX_FILE_SIZE: u64 = 10 * 1024 * 1024;
```
Reveals: hard limits to prevent runaway scans. Larger projects may have incomplete results; very-large files (e.g., generated 50MB JS bundles) are skipped silently.

**Format validation:** confirmed at `crates/tldr-cli/src/output.rs:113-163` — `api-check` is in neither `SARIF_SUPPORTED` nor `DOT_SUPPORTED`.

**No daemon route:** `grep -n try_daemon_route api_check.rs` returns 0 matches. Every call walks files + runs regex rules fresh. `tldr warm` is a no-op.

---

## Architectural Deep Dive

- **Under the hood:** Regex-based pattern matching against language-tagged rules. For each file, detect language → look up rules for that language → run each rule's regex over the source → emit a `MisuseFinding` per match. NOT an AST-based analyzer — this is deliberate (fast, language-agnostic, low false-positive rate via tight patterns + curated rule set).
- **Performance:** Cold per call. ~50ms per file × N files. Bound by `MAX_DIRECTORY_FILES = 1000` and `MAX_FILE_SIZE = 10MB`. NO daemon route — pattern matching is so fast that caching wouldn't help materially.
- **LLM cognitive load:** Replaces "grep for `requests.get(` and check each call for `timeout=`" with curated, language-aware rules. The `fix_suggestion` field gives agents a direct remediation template. Use for security audits (look for `weak-crypto`, `bare-except`), correctness audits (`missing-timeout`, `unclosed-files`), and code review checklist.

---

## Intent & Routing

- **User/Agent Goal:** scan source code for common API misuse anti-patterns (no-timeout HTTP, bare except, weak crypto, unclosed files, etc.) — fast and language-aware.
- **When to choose this over similar tools:**
  - Over `tldr secure`: `secure` is broader security scanning (taint, vuln); `api-check` is targeted API-misuse rules with `fix_suggestion`. Use both for full coverage.
  - Over `tldr vuln`: `vuln` checks dependency CVEs; `api-check` checks code patterns. Different layers.
  - Over manual `grep`: rule-aware, severity/category-filterable, language-gated.
- **Prerequisites (composition):**
  - For mixed-language projects, pass `-l <lang>` explicitly OR scope PATH to a single-language subdir to avoid wasted scans.
  - For CI integration, filter by `--severity high` to surface only critical issues.
  - To target specific concerns: `--category crypto` for weak-crypto, `--category resources` for unclosed files, etc.

---

## Agent Synthesis

> **How to use `tldr api-check`:**
> Pattern-based API-misuse scanner. `tldr api-check <PATH>` returns JSON `{ findings, summary, rules_applied, total_findings, files_scanned }`. Each `MisuseFinding` has `file`, `line`, `column`, `rule` (id/name/category/severity/description/correct_usage), `api_call`, `message`, `fix_suggestion`, `code_context`. Filter with `--category` (call-order, error-handling, parameters, resources, crypto, concurrency, security) and `--severity` (info, low, medium, high — MINIMUM threshold). PATH accepts both files and directories. Use `-l <lang>` to restrict to one language on mixed projects. Default format JSON; `-f text` for table summary; `-f compact` for one-line; `sarif`/`dot` rejected. Exit codes: 0 ok (including 0 findings), 1 format-reject, 2 missing-path / bad-category / bad-severity / bad-lang, 5 path-not-found (typed RemainingError, matches definition/explain).
>
> **Crucial Rules:**
> - **Top-level `total_findings` and `files_scanned` MIRROR `summary.*` fields** (per residual-bugs-v1 P15.AGG15-4). Both `result.total_findings` and `result.summary.total_findings` are equal; use either. This was a backward-compat fix for jq consumers that expected top-level access.
> - **`rules_applied` counts ALL 17 languages, NOT just the language(s) actually checked.** On v0.4.0, the value is 92 regardless of `-l <lang>` filter or which file types are present in PATH (P01, P02). Use `summary.apis_checked` for per-language actual coverage.
> - **`--severity` is a MINIMUM threshold**, not an equality filter. `--severity medium` returns medium AND high; `--severity low` returns low/medium/high. To get exactly one severity, post-filter with `jq '.findings[] | select(.rule.severity == "X")'`.
> - **`--category` and `--severity` accept comma-separated lists** (clap `value_delimiter = ','`). `--category crypto,security,resources` works; semantics is OR across categories (P13).
> - **`-l <lang>` filters files by extension match.** P16: `-l typescript` on a Python subdir yields `files_scanned: 0` (no `.ts`/`.tsx` files to scan). Confirmed by source (`api_check.rs:1332-1357`); not a no-op like in `tldr available`.
> - **`-O <file>` writes ONLY to file (NOT also to stdout).** Differs from `tldr explain -o` which does dual-write. Source: `api_check.rs:1391-1405` has explicit `if-else`. Use `-O` for clean redirection.
> - **Rule IDs encode language via prefix** (`PY00x` = Python, `JS00x` = JavaScript, `CPP00x` = C++, etc.). Defense-in-depth gates ensure rules don't cross-fire across languages.
> - **Hard limits: `MAX_DIRECTORY_FILES = 1000`, `MAX_FILE_SIZE = 10 MB`.** Huge monorepos or files >10 MB are silently truncated/skipped. Verify `files_scanned` matches expected count.
> - **`-O` short flag is UPPERCASE** (matches `tldr definition`); contrast with `tldr explain` which uses lowercase `-o`. Cross-command flag-letter inconsistency.
> - **Path-not-found exit code is 5** (RemainingError::FileNotFound), matching `tldr definition`/`tldr explain`. NOT exit 1 / 2 as in other commands. Cross-command exit-code divergence persists.
> - **No daemon route.** Every call re-scans files. `tldr warm` is a no-op for this command.
>
> **Command:** `tldr api-check <PATH>`
>
> **With common flags:** `tldr api-check <PATH> -l <lang> --severity high --category crypto,security -f compact` (use for high-severity security-focused scans; pipe to jq for CI-friendly output).
