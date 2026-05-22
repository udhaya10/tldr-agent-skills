# Command: `tldr fix diagnose`

## Environment Pin

| Field | Value |
|---|---|
| `tldr --version` | 0.4.0 |
| Build features | `semantic` (verified; fix diagnose is text-parser-based, non-semantic) |
| Target repo | N/A — fixture-driven (custom NameError fixture) |
| Fixtures | `research/fixtures/fix-diagnose/{buggy.py, error.txt}` |
| Upstream `tldr-code` pinned to | local clone @ `6c4011a` (release v0.4.0) |
| Daemon state at probe time | N/A — `tldr fix diagnose` does **not** call `try_daemon_route` (verified by grep) |
| OS | darwin 25.2.0 |
| Probe date | 2026-05-22 |

Re-run all evidence via [`fix-diagnose.probes/probe.sh`](./fix-diagnose.probes/probe.sh).

**Subcommand naming note:** CLI is `tldr fix diagnose` (space-separated); dossier filename uses `fix-diagnose.md`.

---

## Ground Truth (`tldr fix diagnose --help`)

```text
Parse error output and produce a structured diagnosis with optional fix

Usage: tldr fix diagnose [OPTIONS] --source <SOURCE>

Options:
  -s, --source <SOURCE>           Source file to analyze (required for tree-sitter analysis)
  -e, --error <ERROR>             Inline error text [conflicts_with: error-file]
      --error-file <ERROR_FILE>   File containing error text [conflicts_with: error]
      --stdin                     Read error text from stdin
      --api-surface <API_SURFACE> Path to API surface JSON for enhanced analysis
  -f, --format <FORMAT>           [default: json]
  -l, --lang <LANG>
  -q, --quiet  -v, --verbose  -h, --help
```

**Key difference from `tldr fix apply`:** `fix diagnose` ONLY parses + reports the diagnosis. It does NOT try to apply a fix. Therefore exit 0 when diagnosis succeeds (regardless of confidence level), exit 1 only when the error text is unparseable.

---

## Output Shape

| Aspect | Value |
|---|---|
| Default format | `json` |
| Formats that work | `json`, `compact` (P01, P07) |
| Format **bug** | **`-f text` produces JSON, NOT text** (P06: identical to default) |
| Formats that error | `sarif`, `dot` (P05, P08: exit 1) |
| Typical output size | small (~6 lines pretty JSON; ~10 with location field) |

**Top-level keys (JSON, `FixDiagnosis`) — SAME SCHEMA AS `tldr fix apply`:**
- `language` (`string`) — detected/specified language
- `error_code` (`string`) — parsed error type (e.g., `"NameError"`, `"TS2304"`)
- `message` (`string`) — human-readable diagnosis + suggested action
- `location` (`object`, OPTIONAL) — `{ file, line }` when error text contains parseable file:line
- `confidence` (`string`) — `"Low"`, `"Medium"`, `"High"`

**Empty-result shape (none — diagnose either succeeds with diagnosis OR exits 1):**
Unlike most commands, there's no "empty result with metadata" — diagnose is binary.

**Error shapes:**
- Missing `--source`: clap-style → exit **2**
- `--source` not found: `"Error: Failed to read source file '<path>': No such file or directory (os error 2)"` → exit **1** (raw OS-error wrap — same as `tldr fix apply` P04)
- No error input: `"Error: No error text provided. Use --error, --error-file, or pipe to stdin."` → exit **1**
- `--error` AND `--error-file`: clap-style `"the argument '--error <ERROR>' cannot be used with '--error-file <ERROR_FILE>'"` → exit **2**
- `--error-file` not found: `"Error: Failed to read error file '<path>': No such file or directory (os error 2)"` → exit **1**
- Format reject sarif: `"Error: --format sarif not supported by fix. ..."` (note `"by fix"` not `"by fix diagnose"`) → exit **1**
- Unparseable error / language-mismatch parse fail: `"Error: Could not parse or diagnose the error. The error format may not be supported yet."` → exit **1** (note `"yet"` suffix — differs from `tldr fix apply` which omits `"yet"`)
- Bad `--lang`: clap-style → exit **2**
- `--api-surface <path>` (any path, no validation): stderr note `"Note: API surface enrichment available from '<path>'"` → exit 0 (success path continues regardless of path validity)

---

## Probe Matrix

| # | Probe | Type | Exit | Captured |
|---|-------|------|------|----------|
| P01 | `tldr fix diagnose -s buggy.py -e "<NameError>"` | happy | 0 | [`01-happy.*`](./fix-diagnose.probes/) |
| P02 | `tldr fix diagnose -s buggy.py --error-file error.txt` | happy-scale (with location) | 0 | [`02-happy-scale.*`](./fix-diagnose.probes/) |
| P03 | `tldr fix diagnose -e "<text>"` *(no --source)* | failure-missing-input | 2 | [`03-missing-arg.*`](./fix-diagnose.probes/) |
| P04 | `tldr fix diagnose -s /no/such/file.py -e <text>` | bad source path | 1 | [`04-badpath.*`](./fix-diagnose.probes/) |
| P05 | `tldr fix diagnose ... -f sarif` | format-reject (sarif) | 1 | [`05-format-reject-sarif.*`](./fix-diagnose.probes/) |
| P06 | `tldr fix diagnose ... -f text` | format-text (BUG: JSON emitted) | 0 | [`06-format-text.*`](./fix-diagnose.probes/) |
| P07 | `tldr fix diagnose ... -f compact` | format-compact (works) | 0 | [`07-format-compact.*`](./fix-diagnose.probes/) |
| P08 | `tldr fix diagnose ... -f dot` | format-reject (dot) | 1 | [`08-format-reject-dot.*`](./fix-diagnose.probes/) |
| P09 | `cat error.txt \| tldr fix diagnose -s buggy.py --stdin` | stdin input | 0 | [`09-stdin.*`](./fix-diagnose.probes/) |
| P10 | `tldr fix diagnose -s buggy.py < /dev/null` | no error input | 1 | [`10-no-error-input.*`](./fix-diagnose.probes/) |
| P11 | `tldr fix diagnose ... -e <X> --error-file <Y>` | conflicts_with | 2 | [`11-conflicts.*`](./fix-diagnose.probes/) |
| P12 | `tldr fix diagnose ... --error-file /no/such/file` | bad error-file path | 1 | [`12-error-file-bad.*`](./fix-diagnose.probes/) |
| P13 | `tldr fix diagnose ... --api-surface /no/such/api.json` | bad api-surface (note in stderr, exit 0) | 0 | [`13-api-surface.*`](./fix-diagnose.probes/) |
| P14 | `tldr fix diagnose ... -l brainfuck` | bad-lang | 2 | [`14-bad-lang.*`](./fix-diagnose.probes/) |
| P15 | `tldr fix diagnose ... -l python` | explicit python | 0 | [`15-lang-python.*`](./fix-diagnose.probes/) |
| P16 | `tldr fix diagnose ... -l typescript` | lang-mismatch (parse fail) | 1 | [`16-lang-mismatch.*`](./fix-diagnose.probes/) |
| P17 | `tldr fix diagnose ... -e 'random garbage'` | unparseable | 1 | [`17-unparseable.*`](./fix-diagnose.probes/) |
| P18 | `tldr fix diagnose ... --error-file error.txt -f text` | text with location | 0 | [`18-error-with-location.*`](./fix-diagnose.probes/) |
| P19 | `tldr fix diagnose ... -q` | quiet | 0 | [`19-quiet.*`](./fix-diagnose.probes/) |

### Observations

- **P01** — `-e "NameError: name 'valeu' is not defined. Did you mean: 'value'?"`: JSON diagnosis `{ language: "python", error_code: "NameError", message: "Name 'valeu' is not defined. Check spelling or add the missing import.", confidence: "Low" }`. **Exit 0** — DIAGNOSE SUCCEEDS even with Low confidence (different from `tldr fix apply` which exits 1).
- **P02** — `--error-file error.txt`: adds `location: { file: "buggy.py", line: 5 }` — the file:line from the traceback is parsed and surfaced. Exit 0.
- **P03** — stderr `"error: the following required arguments were not provided: --source <SOURCE>"`, exit `2`.
- **P04** — stderr `"Error: Failed to read source file '/no/such/file.py': No such file or directory (os error 2)"`, exit `1`. **Raw OS-error wrap** — same anti-pattern as `tldr fix apply` P04. Source file MUST exist (`std::fs::read_to_string`).
- **P05** — stderr `"Error: --format sarif not supported by fix. Use --format json. SARIF is only emitted by: vuln, clones."`, exit `1`. **Note `"by fix"` not `"by fix diagnose"`** — keyed on parent.
- **P06** — **`-f text` is BROKEN:** output is identical to default JSON (6 lines). Same bug as `tldr fix check` P06.
- **P07** — `-f compact`: single-line minified JSON. Works.
- **P08** — stderr `"Error: --format dot not supported by fix. ..."`, exit `1`.
- **P09** — `cat error.txt | tldr fix diagnose -s buggy.py --stdin`: same as P02 (10 lines with location). Exit 0.
- **P10** — `< /dev/null`: stderr `"Error: No error text provided. Use --error, --error-file, or pipe to stdin."`, exit `1`.
- **P11** — clap-style `conflicts_with`: `"the argument '--error <ERROR>' cannot be used with '--error-file <ERROR_FILE>'"`, exit `2`.
- **P12** — stderr `"Error: Failed to read error file '/no/such/error.txt': No such file or directory (os error 2)"`, exit `1`. Raw OS-error wrap.
- **P13** — **NO VALIDATION of `--api-surface`:** `--api-surface /no/such/api.json` writes stderr note `"Note: API surface enrichment available from '/no/such/api.json'"` and continues. Exit **0**. The note is emitted unconditionally (source: fix.rs:228-232) — there's NO file-existence check. **Cosmetic-only note.**
- **P14** — clap-style: `"error: invalid value 'brainfuck' for '--lang <LANG>': Unknown language: brainfuck"`, exit `2`.
- **P15** — Explicit `-l python`: identical to P01.
- **P16** — `-l typescript` on Python error: stderr `"Error: Could not parse or diagnose the error. The error format may not be supported yet."`, exit `1`. **NOTE `"yet"` suffix** — differs from `tldr fix apply`'s P19 which says `"may not be supported."` (no "yet"). Subtle wording inconsistency.
- **P17** — `-e "some random garbage text"`: same error as P16. Exit `1`.
- **P18** — `--error-file --format text`: identical to P02 (text format bug — JSON emitted instead). 10 lines with location.
- **P19** — `-q quiet`: same output.

---

## Source Code Reality

**Target file(s):**
- `crates/tldr-cli/src/commands/fix.rs` (combined diagnose/apply/check)
- `crates/tldr-core/src/fix/diagnose.rs` (parser registry)
- `crates/tldr-cli/src/output.rs:113` (`validate_format_for_command`)

**Pinned to upstream commit:** `6c4011a` (release v0.4.0)

**Argument struct:**
```rust
// crates/tldr-cli/src/commands/fix.rs:82-103
#[derive(Debug, Args)]
pub struct FixDiagnoseArgs {
    #[arg(long, short = 's')] pub source: PathBuf,
    #[arg(long, short = 'e', conflicts_with = "error_file")] pub error: Option<String>,
    #[arg(long, conflicts_with = "error")] pub error_file: Option<PathBuf>,
    #[arg(long)] pub stdin: bool,
    #[arg(long)] pub api_surface: Option<PathBuf>,
}
```
Reveals: **NO `-d/--diff`, NO `-o/--output`, NO `-i/--in-place`** flags (those are on `fix apply`). diagnose is read-only.

**`run_diagnose` body:**
```rust
// fix.rs:225-255
fn run_diagnose(args: &FixDiagnoseArgs, format: OutputFormat, lang: Option<&str>) -> Result<()> {
    let error_text = read_error_text(&args.error, &args.error_file, args.stdin)?;

    if let Some(surface_path) = &args.api_surface {
        eprintln!("Note: API surface enrichment available from '{}'", surface_path.display());
    }

    let source = std::fs::read_to_string(&args.source).map_err(|e| {
        anyhow!("Failed to read source file '{}': {}", args.source.display(), e)
    })?;

    let diagnosis = fix::diagnose(&error_text, &source, lang, None);

    match diagnosis {
        Some(diag) => { writer.write(&diag)?; Ok(()) }
        None => Err(anyhow!("Could not parse or diagnose the error. The error format may not be supported yet.")),
    }
}
```
Reveals: 
1. `--api-surface` is ONLY validated when passed (note emitted), NOT checked for existence — P13 confirms.
2. The error message includes `"yet"` (line 252) — distinct from `tldr fix apply`'s wording.
3. `fix::diagnose()` returns `Option<FixDiagnosis>` — None means unparseable, Some means success regardless of confidence.

**Format validation:** confirmed at `crates/tldr-cli/src/output.rs:113-163` — `fix` is in neither `SARIF_SUPPORTED` nor `DOT_SUPPORTED`.

**No daemon route:** verified.

---

## Architectural Deep Dive

- **Under the hood:** Parses error text through a language-specific registry (Python tracebacks, Rust E0xxx, TS2xxx, gcc/clang, jest/mocha, eslint, ruff). Extracts `error_code`, `message`, optional `location: { file, line }`. Returns the structured diagnosis. Does NOT try to apply a fix.
- **Performance:** Very fast (~10ms). Pure parser. NO daemon caching.
- **LLM cognitive load:** The "structured input for an LLM fixer" command. Pair: `<runtime> 2>&1 | tldr fix diagnose -s file.py --stdin | <LLM prompt>`. Exit 0 means "diagnosis ready"; exit 1 means "even diagnosis failed — error format truly unknown."

---

## Intent & Routing

- **User/Agent Goal:** turn raw compiler/runtime error text into a structured diagnosis JSON for downstream LLM consumption or filtering.
- **When to choose this over similar tools:**
  - Over `tldr fix apply`: apply tries to FIX; diagnose ONLY parses. Diagnose exits 0 on Low-confidence (apply exits 1).
  - Over `tldr fix check`: check is a loop with retries; diagnose is single-shot.
  - Over external error parsers: unified schema across 7+ language tools.
- **Prerequisites (composition):**
  - `--source` MUST exist (P04 fails).
  - Error text via `--error`/`--error-file`/`--stdin`. Same `read_error_text` chain as `fix apply`.
  - For TS2339 enhancement, pass `--api-surface api-surface.json` (must exist OR be valid; engine doesn't verify but downstream may).

---

## Agent Synthesis

> **How to use `tldr fix diagnose`:**
> Error-text parser → structured JSON diagnosis. `tldr fix diagnose -s <FILE> -e "<error>"` (or `--error-file`, or `--stdin`) returns JSON `{ language, error_code, message, location?, confidence }`. **Exit 0 when diagnosis succeeds (regardless of confidence)**; exit 1 only when error text is UNPARSEABLE. Same schema as `tldr fix apply` output. Default JSON; **`-f text` is BROKEN (emits JSON)**; `-f compact` works; `sarif`/`dot` rejected. Exit codes: 0 diagnosis-succeeded, 1 source-not-found / unparseable-error / format-reject / error-file-not-found / no-error-input, 2 missing --source / conflicts_with / bad-lang.
>
> **Crucial Rules:**
> - **EXIT 0 ON LOW CONFIDENCE.** Unlike `tldr fix apply` (which exits 1 when no deterministic fix exists), `tldr fix diagnose` exits 0 as long as the error PARSED — even at `confidence: Low`. **Use this command FIRST in LLM-fix workflows:** diagnose returns a parseable structure regardless of fixability; pipe its JSON to your LLM.
> - **`-f text` is BROKEN** (P06: emits JSON, same bug as `tldr fix check` P06). Same root cause — text-mode renderer not implemented for fix subcommands. Workaround: parse JSON.
> - **`--api-surface <bad-path>` writes a NOTE to stderr but DOES NOT FAIL.** P13: `--api-surface /no/such/api.json` emits stderr `"Note: API surface enrichment available from '/no/such/api.json'"` (source: fix.rs:228-232) and continues with exit 0. **The note is COSMETIC** — no file-existence check. Agents shouldn't trust the note as confirmation.
> - **Error message uses `"yet"` suffix:** `"Could not parse or diagnose the error. The error format may not be supported yet."` Subtle wording diff from `tldr fix apply` which omits `"yet"` (says `"may not be supported."`). Both reach via the same parse-fail path but emit different text. Cosmetic inconsistency.
> - **Format-reject message keyed on PARENT** (P05: `"by fix"` not `"by fix diagnose"`).
> - **Source file MUST exist** — `--source` is opened via `std::fs::read_to_string` and propagates raw OS errors (P04: `"Failed to read source file ... os error 2"`). Verify path externally.
> - **`--error` AND `--error-file` are MUTUALLY EXCLUSIVE** (clap `conflicts_with`). P11.
> - **STDIN IS ATTEMPTED IMPLICITLY** when no `--error`/`--error-file` provided (source: `read_error_text` shared with fix apply). Same bug-trap: in interactive terminal, the command HANGS waiting on stdin. Always pass `< /dev/null` or use explicit `--error`/`--error-file`.
> - **`location` field is OPTIONAL** — populated when error text contains parseable `file:line` (full Python tracebacks, Rust file:line:col, TS file(line,col)). Inline error WITHOUT location → no location field. P01 vs P02.
> - **Same schema as `tldr fix apply`** — agents can switch between them without changing JSON parsing. Choose based on whether you want to TRY THE FIX (apply) or just GET THE DIAGNOSIS (diagnose).
> - **NO daemon route.** Pure text parser.
>
> **Command:** `tldr fix diagnose -s <FILE> -e "<error>"`
>
> **With common flags:** `<runtime-cmd> 2>&1 | tldr fix diagnose -s <FILE> --stdin -f compact | jq -r '"\(.error_code): \(.message)\nFile: \(.location.file // "n/a"):\(.location.line // 0)"'` (use as the FIRST step of an LLM-driven fix pipeline: extract structured error info; if exit 0, hand to LLM; if exit 1, the error format is unknown).
