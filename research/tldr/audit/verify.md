# Command: `tldr verify`

## Environment Pin

| Field | Value |
|---|---|
| `tldr --version` | 0.4.0 |
| Build features | `semantic` (verified; verify aggregates AST-based sub-analyses, non-semantic) |
| Target repo | Stock-Monitor @ commit `e601869` |
| Upstream `tldr-code` pinned to | local clone @ `6c4011a` (release v0.4.0) |
| Daemon state at probe time | N/A — `tldr verify` does **not** call `try_daemon_route` (verified by grep) |
| OS | darwin 25.2.0 |
| Probe date | 2026-05-22 |
| Scoping decision | All probes used `--quick` mode to skip expensive invariants/patterns sub-analyses |

Re-run all evidence via [`verify.probes/probe.sh`](./verify.probes/probe.sh).
See also: [agent-oriented tool card](../../tool-cards/audit/verify.md).

---

## Ground Truth (`tldr verify --help`)

```text
Aggregated verification dashboard combining multiple analyses

Usage: tldr verify [OPTIONS] [PATH]

Arguments:
  [PATH]
          Directory to analyze (defaults to current directory)

          [default: .]

Options:
  -l, --lang <LANG>
          Programming language override (auto-detected if not specified)

      --detail <DETAIL>
          Show specific sub-analysis detail

      --quick
          Quick mode - skip expensive analyses (invariants, patterns)

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
| Typical output size | medium-heavy (~625 lines for 4-file dir; ~40000 for full backend) |

**Top-level keys (JSON, `VerifyReport`):**
- `path` (`string`) — CANONICAL absolute path (canonicalized via `std::fs::canonicalize`)
- `sub_results` (`object`, KEYED by sub-analysis name) — `{ contracts: {...}, specs: {...}, invariants?: {...}, patterns?: {...} }`
- `summary` (`object`) — aggregated counts (see below)
- `total_elapsed_ms` (`u32`)
- `files_analyzed` (`u32`)
- `files_failed` (`u32`)
- `partial_results` (`bool`) — true when any sub-analysis failed

**`sub_result` shape (per sub-analysis):**
- `name` (`string`) — e.g., `"contracts"`, `"specs"`, `"invariants"`, `"patterns"`
- `status` (`string`) — `"success"`, `"failed"`
- `items_found` (`u32`)
- `elapsed_ms` (`u32`)
- `error` (`string` | `null`) — populated when `status: "failed"`
- `data` (`array` | `null`) — per-analysis-typed structured data; null on failure

**`summary` shape:**
```json
{
  "spec_count": <N>, "invariant_count": <N>, "contract_count": <N>,
  "annotated_count": <N>, "behavioral_count": <N>,
  "pattern_count": <N>, "pattern_high_confidence": <N>,
  "coverage": {
    "constrained_functions": <N>, "total_functions": <N>,
    "coverage_pct": <0.0-100.0>,
    "scope": "constraint-relevant functions (subset of all project functions; typically << structure/health total_functions)"
  }
}
```
**`coverage.scope` is a CONSTANT STRING** explaining the scoping caveat — coverage_pct is over constraint-relevant functions only, not all project functions.

**`--quick` mode**: omits `invariants` and `patterns` sub_results — only `contracts` and `specs` present.

**Empty-result shape (P15 empty dir, P14 lang-mismatch, P17 README.md):**
Same shape with `files_analyzed: 0` (P15) or `1` (P17), `partial_results: true`, summary all zeros, `coverage.coverage_pct: 0.0`. `specs.status: "failed"` with `error: "No test directory found"` — always (the engine looks for sibling `tests/` dir).

**Error shapes:**
- File not found: `"Error: file not found: /no/such/dir"` → exit **1** (ContractsError::FileNotFound — lowercase "file" matches `tldr contracts`/`tldr resources`/`tldr cohesion`)
- Bad `--lang`: clap-style → exit **2**
- Bad legacy `-o`: clap-style `"invalid value 'wat' for '--output-format <OUTPUT_FORMAT>' [possible values: json, text]"` → exit **2**
- Format reject: `"Error: --format sarif not supported by verify. ..."` → exit **1**

---

## Probe Matrix

| # | Probe | Type | Exit | Captured |
|---|-------|------|------|----------|
| P01 | `tldr verify backend/providers --quick` | happy | 0 | [`01-happy.*`](./verify.probes/) |
| P02 | `tldr verify backend --quick` | happy-scale | 0 | [`02-happy-scale.*`](./verify.probes/) |
| P03 | N/A: PATH defaults to `.`. | — | — | [`03-missing-arg.*`](./verify.probes/) (placeholder) |
| P04 | `tldr verify /no/such/dir` | failure-badpath | 1 | [`04-badpath.*`](./verify.probes/) |
| P05 | `tldr verify ... -f sarif` | format-reject (sarif) | 1 | [`05-format-reject-sarif.*`](./verify.probes/) |
| P06 | `tldr verify ... -f text` | format-text | 0 | [`06-format-text.*`](./verify.probes/) |
| P07 | `tldr verify ... -f compact` | format-compact | 0 | [`07-format-compact.*`](./verify.probes/) |
| P08 | `tldr verify ... -f dot` | format-reject (dot) | 1 | [`08-format-reject-dot.*`](./verify.probes/) |
| P09 | `tldr verify ... --quick` | quick mode | 0 | [`09-quick.*`](./verify.probes/) |
| P10 | `tldr verify ... --detail contracts` | detail-contracts | 0 | [`10-detail-contracts.*`](./verify.probes/) |
| P11 | `tldr verify ... --detail wat` | bogus --detail (silent ignore!) | 0 | [`11-detail-bogus.*`](./verify.probes/) |
| P12 | `tldr verify ... -l brainfuck` | bad-lang | 2 | [`12-bad-lang.*`](./verify.probes/) |
| P13 | `tldr verify ... -l python` | explicit-python | 0 | [`13-lang-python.*`](./verify.probes/) |
| P14 | `tldr verify ... -l typescript` | lang-mismatch (empty result) | 0 | [`14-lang-mismatch.*`](./verify.probes/) |
| P15 | `tldr verify <empty-tmp-dir> --quick` | empty-dir | 0 | [`15-empty-dir.*`](./verify.probes/) |
| P16 | `tldr verify backend/providers/yahoo.py --quick` | single-file | 0 | [`16-single-file.*`](./verify.probes/) |
| P17 | `tldr verify README.md --quick` | non-source-md (silent accept) | 0 | [`17-non-source-md.*`](./verify.probes/) |
| P18 | `tldr verify ... -o text` | legacy -o text | 0 | [`18-output-flag-text.*`](./verify.probes/) |
| P19 | `tldr verify ... -o wat` | bad legacy -o | 2 | [`19-output-flag-bogus.*`](./verify.probes/) |
| P20 | `tldr verify ... -q` | quiet | 0 | [`20-quiet.*`](./verify.probes/) |

### Observations

- **P01** — `backend/providers/ --quick`: 625 lines. `sub_results: { contracts: { status: success, items_found: 64, ... }, specs: { status: failed, error: "No test directory found" } }`. `summary: { contract_count: 64, ... coverage: { constrained_functions: 11, total_functions: 11, coverage_pct: 100.0 } }`. `partial_results: true` (specs failed). `path` field is the CANONICAL absolute path.
- **P02** — Full `backend/ --quick`: 39523 lines (heavily truncated by 500-line cap).
- **P03** — **N/A.** PATH defaults to `.`.
- **P04** — stderr `"Error: file not found: /no/such/dir"`, exit `1` (ContractsError::FileNotFound). Lowercase "file" — matches `tldr contracts`/`tldr resources`/`tldr cohesion`.
- **P05** — stderr `"Error: --format sarif not supported by verify. Use --format json. SARIF is only emitted by: vuln, clones."`, exit `1`.
- **P06** — Text format: 15 lines, human-readable header + 6-line counter block + Coverage block + "Errors: specs" trailer.
- **P07** — Single-line minified JSON. **`-f compact` ACTUALLY WORKS** for this command (unlike `tldr resources` / `tldr taint` / `tldr temporal` where compact returns pretty).
- **P08** — stderr `"Error: --format dot not supported by verify. ..."`, exit `1`.
- **P09** — `--quick`: same as P01 (which already uses --quick). Omits invariants + patterns sub_results.
- **P10** — `--detail contracts`: 625 lines, IDENTICAL output to P01. **The `--detail` flag does NOT visibly affect the JSON output.** Possibly only affects text-mode rendering or is silently a no-op.
- **P11** — **`--detail wat` SILENTLY IGNORED:** exit 0, IDENTICAL to P01. The flag is `Option<String>` (NOT typed enum) — clap accepts any string and engine silently ignores unknown values. Same anti-pattern as `tldr secure` P11.
- **P12** — clap-style: `"error: invalid value 'brainfuck' for '--lang <LANG>': Unknown language: brainfuck"`, exit `2`.
- **P13** — Explicit `-l python`: identical to default (Python auto-detected).
- **P14** — `-l typescript` on Python: 40 lines, empty result with `contract_count: 0`. **Silent filter** — no warning that the language mismatches.
- **P15** — Empty dir: 40 lines, same shape as P14. `files_analyzed: 0`. Indistinguishable from lang-mismatch by output alone.
- **P16** — Single file `yahoo.py`: 210 lines. Single-file analysis works — contracts sub-analysis runs on the file.
- **P17** — `README.md`: 40 lines, same empty shape. `files_analyzed: 1, files_failed: 0`. **Silent acceptance** — no error/warning that markdown isn't analyzable. Distinct from `tldr taint`/`tldr resources` which produce errors for non-source single files.
- **P18** — Legacy `-o text`: same output as `-f text`.
- **P19** — Bad legacy `-o wat`: clap-style with possible values inline: `"invalid value 'wat' for '--output-format <OUTPUT_FORMAT>' [possible values: json, text]"`, exit `2`. Legacy `-o` only supports `json`/`text`.
- **P20** — `-q` suppresses the `"Running verification on <path>..."` progress message.

---

## Source Code Reality

**Target file(s):**
- `crates/tldr-cli/src/commands/contracts/verify.rs` (~280 lines)
- `crates/tldr-core/src/contracts/verify/...` (sub-analysis orchestration)
- `crates/tldr-cli/src/output.rs:113` (`validate_format_for_command`)

**Pinned to upstream commit:** `6c4011a` (release v0.4.0)

**Argument struct:**
```rust
// crates/tldr-cli/src/commands/contracts/verify.rs:71-96
#[derive(Debug, Args)]
pub struct VerifyArgs {
    #[arg(default_value = ".")] pub path: PathBuf,
    #[arg(long = "output-format", short = 'o', hide = true, default_value = "json")]
    pub output_format: ContractsOutputFormat,
    #[arg(long, short = 'l')] pub lang: Option<Language>,
    #[arg(long)] pub detail: Option<String>,
    #[arg(long)] pub quick: bool,
}
```
Reveals: `--detail` is `Option<String>` (NOT typed enum). Clap accepts any value (P11 confirms silent ignore).

**Path validation with canonicalization:**
```rust
// verify.rs:104-111
let canonical_path = if self.path.exists() {
    std::fs::canonicalize(&self.path).unwrap_or_else(|_| self.path.clone())
} else {
    return Err(ContractsError::FileNotFound {
        path: self.path.clone(),
    }
    .into());
};
```
Reveals: path is CANONICALIZED (resolves symlinks, makes absolute). The `path` field in JSON output is the CANONICAL path — agents must compare against this, not the user input.

**Language detection (silent Python fallback):**
```rust
// verify.rs:119-125
let language = self.lang.unwrap_or_else(|| {
    if self.path.is_file() {
        Language::from_path(&self.path).unwrap_or(Language::Python)
    } else {
        Language::from_directory(&self.path).unwrap_or(Language::Python)
    }
});
```
Reveals: same silent Python fallback as `tldr taint` (taint.rs:60). For non-Python projects, MUST pass `--lang`. README.md falls through to Python (P17: silent empty).

**Format validation:** confirmed at `crates/tldr-cli/src/output.rs:113-163` — `verify` is in neither `SARIF_SUPPORTED` nor `DOT_SUPPORTED`.

**No daemon route:** `grep -n try_daemon_route contracts/verify.rs` returns 0 matches.

---

## Architectural Deep Dive

- **Under the hood:** Orchestrator that runs 4 sub-analyses on a single AST cache. Default: contracts + specs + invariants + patterns. `--quick`: only contracts + specs. Aggregates `summary` counts, computes coverage as `constrained_functions / total_functions` over "constraint-relevant" functions (a subset — see `coverage.scope`).
- **Performance:** `--quick` ~50-200ms per 4-file dir; full mode 1-10s on full backend. NO daemon caching.
- **LLM cognitive load:** Verification dashboard — single command for "do I have specs/contracts/invariants/patterns coverage?". The `summary.coverage.coverage_pct` is the headline metric. Pair with `tldr health` (broader metric dashboard) for full audit. The `partial_results: true` flag indicates which sub-analyses failed (often `specs` if no test directory present).

---

## Intent & Routing

- **User/Agent Goal:** check the overall constraint/specification coverage of a codebase — how many functions have inferred contracts, behavioral specs, invariants, patterns?
- **When to choose this over similar tools:**
  - Over individual `tldr contracts` / `tldr specs` / `tldr invariants` / `tldr patterns`: verify aggregates them with coverage metric.
  - Over `tldr secure --quick`: secure focuses on SECURITY findings; verify focuses on SPECIFICATION coverage.
  - Over `tldr health`: health is the broader code-quality metric dashboard; verify is constraint-coverage focused.
- **Prerequisites (composition):**
  - PATH defaults to `.`. Single file or directory both work.
  - Use `--quick` to skip expensive invariants/patterns (saves 5-10x time).
  - For non-Python projects, MUST pass `-l <lang>` — otherwise silent Python fallback yields empty results.
  - `specs` sub-analysis ALWAYS fails on projects without a sibling `tests/` directory — this is expected; check `partial_results: true` and the specific `error` field.

---

## Agent Synthesis

> **How to use `tldr verify`:**
> Aggregated constraint-coverage dashboard. `tldr verify [PATH]` returns JSON `{ path, sub_results, summary, total_elapsed_ms, files_analyzed, files_failed, partial_results }`. `sub_results` is a KEYED object — `{ contracts: {...}, specs: {...}, invariants?: {...}, patterns?: {...} }`. Each sub_result has `{ name, status, items_found, elapsed_ms, error, data }`. `summary` includes `spec_count, invariant_count, contract_count, annotated_count, behavioral_count, pattern_count, pattern_high_confidence, coverage: { constrained_functions, total_functions, coverage_pct, scope }`. `--quick` mode omits invariants + patterns. Default JSON; `-f text` for human dashboard; `-f compact` for one-line (actually works!); `sarif`/`dot` rejected. Exit codes: 0 ok (including silent empties), 1 file-not-found / format-reject, 2 bad-lang / bad legacy -o.
>
> **Crucial Rules:**
> - **`--detail <X>` IS SILENTLY IGNORED** (P10/P11). `--detail contracts`, `--detail wat`, OR omitting the flag ALL produce byte-identical output. The flag is `Option<String>` (NOT typed enum) — clap accepts any value and the engine doesn't visibly use it. Possible engine no-op or text-mode-only effect. Skip the flag for now.
> - **Silent Python fallback** (verify.rs:121, 123): `Language::from_path/from_directory(...).unwrap_or(Language::Python)`. README.md and lang-mismatched dirs are silently empty (P14, P17 both 40 lines). For non-Python projects, MUST pass `-l <lang>`.
> - **`path` field in JSON is CANONICAL** (resolves symlinks via `std::fs::canonicalize`). Agents comparing against user input must canonicalize first OR trust the JSON `path` field. P15: tmp dir was `/var/folders/...`, JSON shows `/private/var/folders/...` (macOS canonical).
> - **`specs` sub-analysis ALWAYS FAILS** without a sibling `tests/` directory: `error: "No test directory found"`. Expected on most production code. Check `partial_results: true` flag; only treat it as bug if `contracts` also failed.
> - **`coverage.scope` is a CONSTANT STRING explaining the scoping caveat:** `"constraint-relevant functions (subset of all project functions; typically << structure/health total_functions)"`. The `coverage_pct` is NOT % of all functions — it's % of constraint-relevant functions. For full-project coverage, divide by `tldr structure`'s `total_functions` instead.
> - **`-f compact` WORKS** (unlike `tldr resources`/`tldr taint`/`tldr temporal` where compact returns pretty JSON). Single-line minified JSON properly produced.
> - **`sub_results` is a KEYED OBJECT, not array** — `result.sub_results.contracts` not `result.sub_results[0]`. Same convention as `tldr loc.by_language`/`tldr smells.by_file`.
> - **`partial_results: true` doesn't mean ERROR** — it means at least one sub-analysis failed. Inspect each `sub_results.<name>.status` to identify failures. `specs` failing is normal; `contracts` failing is a bug.
> - **Three indistinguishable empty results:** lang-mismatch (P14), empty-dir (P15), non-source-md (P17) all return 40 lines with same shape. Check `files_analyzed` vs `path` externally to disambiguate.
> - **File-not-found exit code is 1**, lowercase `"file not found:"` (ContractsError — matches `tldr contracts`/`tldr cohesion`/`tldr resources`).
> - **NO daemon route.** Every call re-runs 2 (quick) or 4 (default) sub-analyses.
>
> **Command:** `tldr verify [PATH]`
>
> **With common flags:** `tldr verify <PATH> --quick -f compact | jq '{ coverage_pct: .summary.coverage.coverage_pct, failures: [ .sub_results | to_entries[] | select(.value.status == "failed") | .key ] }'` (use for CI dashboard: extract just coverage% and list of failed sub-analyses).
