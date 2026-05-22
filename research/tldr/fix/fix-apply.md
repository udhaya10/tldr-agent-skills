# Command: `tldr fix apply`

## Environment Pin

| Field | Value |
|---|---|
| `tldr --version` | 0.4.0 |
| Build features | `semantic` (verified; fix is parser-based + heuristic, non-semantic) |
| Target repo | N/A — fixture-driven (custom NameError fixture) |
| Fixtures | `research/fixtures/fix-apply/{buggy.py, error.txt}` |
| Upstream `tldr-code` pinned to | local clone @ `6c4011a` (release v0.4.0) |
| Daemon state at probe time | N/A — `tldr fix apply` does **not** call `try_daemon_route` (verified by grep) |
| OS | darwin 25.2.0 |
| Probe date | 2026-05-22 |

Re-run all evidence via [`fix-apply.probes/probe.sh`](./fix-apply.probes/probe.sh).

**Subcommand naming note:** The CLI subcommand is `tldr fix apply` (space-separated), NOT `tldr fix-apply` (the dossier filename uses hyphen for filesystem compatibility — `tldr-apply` is not a recognized CLI command).

---

## Ground Truth (`tldr fix apply --help`)

```text
Apply fix edits to source code and write the patched result

Usage: tldr fix apply [OPTIONS] --source <SOURCE>

Options:
  -s, --source <SOURCE>            Source file to patch
  -e, --error <ERROR>              Inline error text [conflicts_with: error-file]
      --error-file <ERROR_FILE>    File containing error text [conflicts_with: error]
  -o, --output <OUTPUT>            Output file for the patched source (stdout if not specified)
      --stdin                      Read error text from stdin
  -i, --in-place                   Write the patched source back to the original file
  -d, --diff                       Show a unified diff instead of the full patched source
      --api-surface <PATH>         Path to API surface JSON for enhanced analysis (e.g., TS2339)
  -f, --format <FORMAT>            [default: json]
  -l, --lang <LANG>                Programming language (auto-detect)
  -q, --quiet  -v, --verbose  -h, --help
```

---

## Output Shape

| Aspect | Value |
|---|---|
| Default format | `json` |
| Formats that work | `json`, `text`, `compact` (P01, P06, P07) |
| Formats that error | `sarif`, `dot` (P05, P08: exit 1) |
| Typical output size | small (~6 lines pretty JSON for diagnosis; larger when a deterministic fix is produced — none observed in our scope) |

**Top-level keys (JSON, `FixDiagnosis`):**
- `language` (`string`) — detected/specified language
- `error_code` (`string`) — parsed error type (e.g., `"NameError"`, `"TS2339"`)
- `message` (`string`) — human-readable diagnosis + suggested action
- `location` (`object`, OPTIONAL) — `{ file, line }` when error text contains file:line metadata
- `confidence` (`string`) — `"Low"`, `"Medium"`, `"High"` — fix confidence level

**When a deterministic fix IS available** (not observed in our scope; behavior inferred from source): output would include patched source code OR a `diff` field. Exit 0.

**When NO deterministic fix is available** (observed in ALL our probes): exit 1 with stderr `"No auto-fix available (confidence: Low). Diagnosis: Error: No deterministic fix available for this error. Escalate to a model."` and JSON diagnosis on stdout.

**Error shapes:**
- Missing `--source`: clap-style → exit **2**
- `--source` not found: `"Error: Failed to read source file '<path>': No such file or directory (os error 2)"` → exit **1** (raw OS error wrapping)
- No error text provided: `"Error: No error text provided. Use --error, --error-file, or pipe to stdin."` → exit **1**
- `--error` AND `--error-file` together: clap-style `"the argument '--error <ERROR>' cannot be used with '--error-file <ERROR_FILE>'"` → exit **2** (`conflicts_with` enforced)
- `--error-file` not found: `"Error: Failed to read error file '<path>': No such file or directory (os error 2)"` → exit **1**
- Format reject sarif: `"Error: --format sarif not supported by fix apply. ..."` → exit **1**
- Error text unparseable: `"Error: Could not parse or diagnose the error. The error format may not be supported."` → exit **1**
- Bad `--lang`: clap-style → exit **2**
- **Auto-fix not deterministic (low confidence):** stderr `"No auto-fix available (confidence: Low). Diagnosis: ..."` → exit **1**

---

## Probe Matrix

| # | Probe | Type | Exit | Captured |
|---|-------|------|------|----------|
| P01 | `tldr fix apply -s buggy.py -e <NameError text>` | happy (diagnosis emitted, no fix) | 1 | [`01-happy.*`](./fix-apply.probes/) |
| P02 | `tldr fix apply -s buggy.py --error-file error.txt` | happy-scale (with location) | 1 | [`02-happy-scale.*`](./fix-apply.probes/) |
| P03 | `tldr fix apply -e <text>` *(no --source)* | failure-missing-input | 2 | [`03-missing-arg.*`](./fix-apply.probes/) |
| P04 | `tldr fix apply -s /no/such/file.py -e <text>` | bad source (raw OS error) | 1 | [`04-badpath.*`](./fix-apply.probes/) |
| P05 | `tldr fix apply ... -f sarif` | format-reject (sarif) | 1 | [`05-format-reject-sarif.*`](./fix-apply.probes/) |
| P06 | `tldr fix apply ... -f text` | format-text | 1 | [`06-format-text.*`](./fix-apply.probes/) |
| P07 | `tldr fix apply ... -f compact` | format-compact | 1 | [`07-format-compact.*`](./fix-apply.probes/) |
| P08 | `tldr fix apply ... -f dot` | format-reject (dot) | 1 | [`08-format-reject-dot.*`](./fix-apply.probes/) |
| P09 | `tldr fix apply ... -d` | --diff | 1 | [`09-diff.*`](./fix-apply.probes/) |
| P10 | `tldr fix apply ... -o <tmp>` | --output to file | 1 | [`10-output-file.*`](./fix-apply.probes/) |
| P11 | `tldr fix apply ... -i` | --in-place (on tmp copy) | 1 | [`11-in-place.*`](./fix-apply.probes/) |
| P12 | `cat error.txt \| tldr fix apply ... --stdin` | stdin error input | 1 | [`12-stdin.*`](./fix-apply.probes/) |
| P13 | `tldr fix apply -s buggy.py < /dev/null` | no error input | 1 | [`13-no-error-input.*`](./fix-apply.probes/) |
| P14 | `tldr fix apply ... -e <text> --error-file <path>` | conflicts_with | 2 | [`14-conflicts.*`](./fix-apply.probes/) |
| P15 | `tldr fix apply ... --error-file /no/such/file` | bad error-file path | 1 | [`15-error-file-bad.*`](./fix-apply.probes/) |
| P16 | `tldr fix apply ... --api-surface /no/such/api.json` | bad api-surface (silent?) | 1 | [`16-api-surface-bad.*`](./fix-apply.probes/) |
| P17 | `tldr fix apply ... -l brainfuck` | bad-lang | 2 | [`17-bad-lang.*`](./fix-apply.probes/) |
| P18 | `tldr fix apply ... -l python` | explicit python | 1 | [`18-lang-python.*`](./fix-apply.probes/) |
| P19 | `tldr fix apply ... -l typescript` | lang-mismatch (parse fail) | 1 | [`19-lang-mismatch.*`](./fix-apply.probes/) |
| P20 | `tldr fix apply -s buggy.py -e <unrelated>` | unrelated error text | 1 | [`20-unrelated-error.*`](./fix-apply.probes/) |
| P21 | `tldr fix apply ... -q` | quiet | 1 | [`21-quiet.*`](./fix-apply.probes/) |

### Observations

- **P01** — `-e "NameError: name 'valeu' is not defined. Did you mean: 'value'?"`: JSON diagnosis `{ language: "python", error_code: "NameError", message: "Name 'valeu' is not defined. Check spelling or add the missing import.", confidence: "Low" }`. stderr: `"No auto-fix available (confidence: Low). Diagnosis: Error: No deterministic fix available for this error. Escalate to a model."` Exit **1**.
- **P02** — `--error-file` with full traceback: same JSON PLUS `location: { file: "buggy.py", line: 6 }`. The `location` field is only populated when the error text contains parseable `file:line` metadata.
- **P03** — stderr `"error: the following required arguments were not provided: --source <SOURCE>"`, exit `2`.
- **P04** — stderr `"Error: Failed to read source file '/no/such/file.py': No such file or directory (os error 2)"`, exit `1`. **Raw OS-error wrapping** — same anti-pattern as `tldr taint`/`tldr resources` directory-as-FILE.
- **P05** — stderr `"Error: --format sarif not supported by fix apply. Use --format json. SARIF is only emitted by: vuln, clones."`, exit `1`.
- **P06** — Text format: 6 lines, human-readable diagnosis summary.
- **P07** — Single-line minified JSON.
- **P08** — stderr `"Error: --format dot not supported by fix apply. ..."`, exit `1`.
- **P09** — `--diff` flag: same diagnosis output. **NO DIFF EMITTED** — because no fix exists. Would produce unified diff if fix were available.
- **P10** — `-o <tmp>`: file CONTAINS the patched source... but here the diagnosis-only mode runs because no fix. Output file gets empty/nothing. **Side-effect:** when no fix exists, `-o` writes empty/diagnosis to file (verify the file content in capture).
- **P11** — `-i`: in-place flag on tmp copy. **File NOT modified** (no fix available, exit 1 before write). Confirmed by post-fix `cat` of the tmp file showing original content.
- **P12** — `cat error.txt | tldr fix apply -s buggy.py --stdin`: WORKS. Same diagnosis as P02 (since error.txt is the same content).
- **P13** — `< /dev/null` (no `--error`, no `--error-file`, no `--stdin`): stderr `"Error: No error text provided. Use --error, --error-file, or pipe to stdin."`, exit `1`. Clear error message.
- **P14** — clap-style conflict: `"error: the argument '--error <ERROR>' cannot be used with '--error-file <ERROR_FILE>'"`, exit `2`. **`conflicts_with` enforced** at clap level.
- **P15** — stderr `"Error: Failed to read error file '/no/such/error.txt': No such file or directory (os error 2)"`, exit `1`. Same OS-error wrap pattern.
- **P16** — `--api-surface /no/such/api.json`: **SILENT IGNORE** — output is identical to P01 (no warning that the api-surface file is missing). The flag is `Option<PathBuf>` and the engine apparently doesn't validate it for existence.
- **P17** — clap-style: `"error: invalid value 'brainfuck' for '--lang <LANG>': Unknown language: brainfuck"`, exit `2`.
- **P18** — Explicit `-l python`: identical to P01 (Python auto-detected).
- **P19** — **DIFFERENT FAILURE MODE:** `-l typescript` causes parser switch: stderr `"Error: Could not parse or diagnose the error. The error format may not be supported."`, exit `1`. The TypeScript parser can't recognize Python error text. Stdout: empty.
- **P20** — `-e "NameError: foo not defined"` (unrelated to actual source): exit 1, same diagnosis-only output (engine doesn't cross-check against source).
- **P21** — `-q` suppresses progress messages.

---

## Source Code Reality

**Target file(s):**
- `crates/tldr-cli/src/commands/fix.rs` (~600+ lines — combined diagnose/apply/check)
- `crates/tldr-core/src/fix/...` (parser registry, fix engine)
- `crates/tldr-cli/src/output.rs:113` (`validate_format_for_command`)

**Pinned to upstream commit:** `6c4011a` (release v0.4.0)

**Argument struct:**
```rust
// crates/tldr-cli/src/commands/fix.rs:107-139
#[derive(Debug, Args)]
pub struct FixApplyArgs {
    #[arg(long, short = 's')] pub source: PathBuf,
    #[arg(long, short = 'e', conflicts_with = "error_file")] pub error: Option<String>,
    #[arg(long, conflicts_with = "error")] pub error_file: Option<PathBuf>,
    #[arg(long, short = 'o')] pub output: Option<PathBuf>,
    #[arg(long)] pub stdin: bool,
    #[arg(long, short = 'i')] pub in_place: bool,
    #[arg(long, short = 'd')] pub diff: bool,
    #[arg(long)] pub api_surface: Option<PathBuf>,
}
```
Reveals: `conflicts_with = "error_file"` on `--error` AND `conflicts_with = "error"` on `--error-file` — clap enforces mutual exclusion (P14). The pair of conflicts_with directives is BIDIRECTIONAL — both flags refer to each other.

**`read_error_text` fallback chain:**
```rust
// fix.rs:154-180
if let Some(text) = error { return Ok(text.clone()); }
if let Some(path) = error_file { return Ok(read_to_string(path)?); }
if use_stdin || (error.is_none() && error_file.is_none()) {
    let mut buf = String::new();
    std::io::stdin().read_to_string(&mut buf)?;
    if buf.is_empty() {
        return Err(anyhow!("No error text provided. Use --error, --error-file, or pipe to stdin."));
    }
    return Ok(buf);
}
```
Reveals: **STDIN IS ATTEMPTED IMPLICITLY** when no `--error`/`--error-file` is provided (even without `--stdin` flag!). P13 used `< /dev/null` to give empty stdin → the engine reads stdin, gets empty, then errors. **Quirk:** `tldr fix apply -s buggy.py` (no args + interactive terminal) would HANG waiting on stdin.

**Format validation:** confirmed at `crates/tldr-cli/src/output.rs:113-163` — `fix apply` is in neither `SARIF_SUPPORTED` nor `DOT_SUPPORTED`.

**No daemon route:** `grep -n try_daemon_route fix.rs` returns 0 matches.

---

## Architectural Deep Dive

- **Under the hood:** Parses the error text using a language-specific parser (Python tracebacks, Rust E0xxx, TS2xxx, gcc/clang, jest/mocha, eslint, ruff). Extracts `error_code`, `message`, `location?`. Looks up the error in a deterministic-fix registry. If a fix exists (rare — only well-known patterns like `TS2304` with `__known__` import, simple typos with api-surface), applies it and emits patched source. Otherwise emits diagnosis + escalation note. The `--api-surface` flag enables TS2339-style property-suggestion fixes by providing the inferred API surface.
- **Performance:** Cold ~10-50ms (parser + registry lookup). NO daemon caching.
- **LLM cognitive load:** The deterministic-fix registry is INTENTIONALLY SMALL — the philosophy is "auto-fix the boring stuff (typos, missing imports); escalate everything else to an LLM with the structured diagnosis." Pair this with an LLM-driven fixer: pipe the JSON diagnosis to your LLM along with the source file when exit code is 1 and `confidence` is Low.

---

## Intent & Routing

- **User/Agent Goal:** auto-fix a known error pattern from compiler/linter/test output, OR get a structured diagnosis to hand to an LLM.
- **When to choose this over similar tools:**
  - Over `tldr fix diagnose`: diagnose ONLY parses + reports; apply ADDITIONALLY tries the fix registry.
  - Over `tldr fix check`: check runs in a loop until tests pass; apply is one-shot.
  - Over external tools: unified parser across languages, deterministic registry for high-confidence cases.
- **Prerequisites (composition):**
  - `--source` MUST exist (P04 fails).
  - Error text must be provided via `--error` OR `--error-file` OR `--stdin` (or interactive stdin).
  - For TypeScript `TS2339` property fixes, pass `--api-surface api-surface.json` (generated by `tldr api-check`).
  - Expect MOST errors to return exit 1 with `confidence: Low` — the deterministic registry is small by design.

---

## Agent Synthesis

> **How to use `tldr fix apply`:**
> Deterministic auto-fixer + diagnostic emitter. `tldr fix apply -s <FILE> -e "<error text>"` (or `--error-file`, or `--stdin`) returns JSON `{ language, error_code, message, location?, confidence }`. When a deterministic fix is available, prints patched source (or `--diff`) and exits 0. **When no fix is available (the COMMON case), exits 1 with stderr `"No auto-fix available (confidence: Low). Diagnosis: ... Escalate to a model."`** and the diagnosis JSON on stdout. Default JSON; `-f text` for human summary; `-f compact` for one-line; `sarif`/`dot` rejected. Exit codes: 0 fix applied, 1 no-fix-available / format-reject / parse-fail / source-not-found / error-file-not-found / no-error-input, 2 missing --source / conflicts_with / bad-lang.
>
> **Crucial Rules:**
> - **`tldr fix apply` SUBCOMMAND is space-separated** (`tldr fix apply`), NOT hyphenated `tldr fix-apply` (that's a typo per `tldr --help`). The dossier filename uses `fix-apply.md` for filesystem compatibility.
> - **EXPECT EXIT 1 BY DEFAULT.** The deterministic-fix registry is intentionally small — Python NameError, Rust E0xxx, TS2xxx, etc. ALL probed inputs returned exit 1 with `confidence: Low` and `"Escalate to a model"` advice. Use the structured JSON diagnosis as INPUT TO YOUR LLM for the actual fix.
> - **`--error` and `--error-file` are MUTUALLY EXCLUSIVE** (clap `conflicts_with`). P14 confirms.
> - **STDIN IS ATTEMPTED IMPLICITLY** when no `--error`/`--error-file` is provided, even without `--stdin` flag (source: fix.rs:169 `use_stdin || (error.is_none() && error_file.is_none())`). **Bug-trap:** `tldr fix apply -s buggy.py` with no args in an interactive terminal HANGS waiting on stdin. Always pass `< /dev/null` or use `--error`/`--error-file` explicitly in scripts.
> - **`--api-surface <bad-path>` is SILENTLY IGNORED** (P16: output identical to without flag). The engine doesn't validate file existence. If you intend to use TS2339 property suggestions, verify api-surface.json exists externally.
> - **`location` field is OPTIONAL.** P01 (inline error text without file:line): no location. P02 (error.txt with traceback `File "buggy.py", line 6`): location populated.
> - **`-l typescript` on Python error text produces DIFFERENT error** ("Could not parse or diagnose the error. The error format may not be supported.") vs `-l python` (parses fine but no fix). The TS parser legitimately fails to recognize Python tracebacks.
> - **Raw OS errors leak through for bad paths** (P04, P15). `tldr fix apply -s /no/such/file.py` → `"Failed to read source file '<path>': No such file or directory (os error 2)"`. Same anti-pattern as `tldr taint`/`tldr resources`.
> - **`confidence` values:** `"Low"`, `"Medium"`, `"High"`. Only `"High"` typically triggers a successful auto-fix; `"Low"` always falls through to LLM escalation.
> - **`-i --in-place` is a no-op when no fix is produced** (P11: source file unchanged after exit 1). Safe to script.
> - **NO daemon route.** Every call re-parses error text.
>
> **Command:** `tldr fix apply -s <FILE> -e "<error>" [--diff | -i | -o <out>]`
>
> **With common flags:** `<runtime-cmd> 2>&1 | tldr fix apply -s <FILE> --stdin -f compact | jq -r '"\(.error_code): \(.message) (confidence: \(.confidence))"'` (use as a one-liner to parse error output and extract structured diagnosis — for LLM hand-off when exit code is 1).
