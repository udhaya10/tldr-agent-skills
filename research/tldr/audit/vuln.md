# Command: `tldr vuln`

## Environment Pin

| Field | Value |
|---|---|
| `tldr --version` | 0.4.0 |
| Build features | `semantic` (verified; vuln is taint-based, non-semantic) |
| Target repo | Stock-Monitor @ commit `e601869` |
| Upstream `tldr-code` pinned to | local clone @ `6c4011a` (release v0.4.0) |
| Daemon state at probe time | N/A — `tldr vuln` does **not** call `try_daemon_route` (verified by grep) |
| OS | darwin 25.2.0 |
| Probe date | 2026-05-22 |
| Scoping decision | Slow command per Journal 04 §5 — happy probes scoped to `backend/providers/` (4 files); P23 scanned full webui/src (156 files, 84 seconds) |

Re-run all evidence via [`vuln.probes/probe.sh`](./vuln.probes/probe.sh).

---

## Ground Truth (`tldr vuln --help`)

```text
Vulnerability scanning via taint analysis (SQL injection, XSS, command injection)

Usage: tldr vuln [OPTIONS] <PATH>

Arguments:
  <PATH>
          File or directory to analyze

Options:
  -l, --lang <LANG>
          Programming language to filter by (auto-detected if omitted)

      --severity <SEVERITY>          [possible values: critical, high, medium, low, info]
      --vuln-type <TYPE>             [possible values: sql_injection, xss, command_injection,
                                       ssrf, path_traversal, deserialization, unsafe_code,
                                       memory_safety, panic, xxe, open_redirect, ldap_injection,
                                       xpath_injection]
      --include-informational
      --include-smells               [opt-in; default suppresses .unwrap() emissions]
      --include-tests                [opt-in; default suppresses JS/TS test-file paths]
  -O, --output <OUTPUT>              [output file]
      --no-default-ignore            [walk node_modules/target/dist/...]

  -f, --format <FORMAT>              [json | text | compact | sarif (SUPPORTED) | dot (rejected)]
                                     [default: json]

  -q, --quiet  -v, --verbose  -h, --help
```

---

## Output Shape

| Aspect | Value |
|---|---|
| Default format | `json` |
| Formats that work | `json`, `text`, `compact`, **`sarif`** (P01, P06, P07, P08) |
| Formats that error | `dot` (P05: exit 1) |
| Typical output size | small (~11 lines pretty JSON for empty scan; grows with findings); SARIF ~17 lines |

**Top-level keys (JSON, `VulnReport`):**
- `findings` (`array<Finding>`) — taint-detected vulnerabilities
- `summary` (`object`) — `{ total_findings, by_severity, by_type, files_with_vulns }`
- `scan_duration_ms` (`u32`)
- `files_scanned` (`u32`)

**SARIF format (`-f sarif`):** Standard SARIF 2.1.0 schema:
```json
{
  "$schema": "https://raw.githubusercontent.com/oasis-tcs/sarif-spec/master/Schemata/sarif-schema-2.1.0.json",
  "version": "2.1.0",
  "runs": [{ "tool": { "driver": { "name": "tldr-vuln", "version": "0.4.0", ... } }, "results": [...] }]
}
```
**`tldr vuln` is one of only TWO commands in the suite emitting SARIF** (the other is `tldr clones`).

**Empty-result shape (most probes; engine rarely fires on real code):**
```json
{
  "findings": [],
  "summary": { "total_findings": 0, "by_severity": {}, "by_type": {}, "files_with_vulns": 0 },
  "scan_duration_ms": <N>,
  "files_scanned": <N>
}
```
Exit 0. **`scan_duration_ms` and `files_scanned` distinguish what actually ran.**

**Error shapes:**
- Missing PATH: clap-style → exit **2**
- File not found: `"Error: file not found: /no/such/dir"` → exit **5** (RemainingError::FileNotFound — matches `tldr secure`/`tldr dead-stores`)
- Bad `--severity`: clap-style with full list `[critical, high, medium, low, info]` → exit **2**
- Bad `--vuln-type`: clap-style with full list of 13 valid vuln types → exit **2**
- Format reject dot: `"Error: --format dot not supported by vuln. ..."` → exit **1**
- Bad `--lang`: clap-style → exit **2**

---

## Probe Matrix

| # | Probe | Type | Exit | Captured |
|---|-------|------|------|----------|
| P01 | `tldr vuln backend/providers` | happy | 0 | [`01-happy.*`](./vuln.probes/) |
| P02 | `tldr vuln <taint-fixture-sinks.py>` | happy-scale (known SQL/shell sinks) | 0 | [`02-happy-scale.*`](./vuln.probes/) |
| P03 | `tldr vuln` *(no PATH)* | failure-missing-input | 2 | [`03-missing-arg.*`](./vuln.probes/) |
| P04 | `tldr vuln /no/such/dir` | failure-badpath | 5 | [`04-badpath.*`](./vuln.probes/) |
| P05 | `tldr vuln ... -f dot` | format-reject (dot) | 1 | [`05-format-reject-dot.*`](./vuln.probes/) |
| P06 | `tldr vuln ... -f text` | format-text | 0 | [`06-format-text.*`](./vuln.probes/) |
| P07 | `tldr vuln ... -f compact` | format-compact | 0 | [`07-format-compact.*`](./vuln.probes/) |
| P08 | `tldr vuln ... -f sarif` | format-SARIF (SUPPORTED!) | 0 | [`08-format-sarif.*`](./vuln.probes/) |
| P09 | `tldr vuln ... --severity critical` | severity-critical filter | 0 | [`09-severity-critical.*`](./vuln.probes/) |
| P10 | `tldr vuln ... --severity info` | severity-info | 0 | [`10-severity-info.*`](./vuln.probes/) |
| P11 | `tldr vuln ... --severity wat` | bad-severity | 2 | [`11-severity-bogus.*`](./vuln.probes/) |
| P12 | `tldr vuln ... --vuln-type sql_injection` | vuln-type filter | 0 | [`12-vuln-type-sql.*`](./vuln.probes/) |
| P13 | `tldr vuln ... --vuln-type wat` | bad-vuln-type (full list shown) | 2 | [`13-vuln-type-bogus.*`](./vuln.probes/) |
| P14 | `tldr vuln ... --vuln-type sql_injection --vuln-type command_injection` | multi-vuln-type | 0 | [`14-vuln-type-multi.*`](./vuln.probes/) |
| P15 | `tldr vuln ... --include-informational` | include-informational | 0 | [`15-include-informational.*`](./vuln.probes/) |
| P16 | `tldr vuln ... --include-smells` | include-smells | 0 | [`16-include-smells.*`](./vuln.probes/) |
| P17 | `tldr vuln ... --include-tests` | include-tests | 0 | [`17-include-tests.*`](./vuln.probes/) |
| P18 | `tldr vuln ... -O <tmp>` | output-to-file | 0 | [`18-output-file.*`](./vuln.probes/) |
| P19 | `tldr vuln ... --no-default-ignore` | walk vendored | 0 | [`19-no-default-ignore.*`](./vuln.probes/) |
| P20 | `tldr vuln ... -l brainfuck` | bad-lang | 2 | [`20-bad-lang.*`](./vuln.probes/) |
| P21 | `tldr vuln ... -l python` | explicit python | 0 | [`21-lang-python.*`](./vuln.probes/) |
| P22 | `tldr vuln ... -l typescript` | lang-mismatch (silent) | 0 | [`22-lang-mismatch.*`](./vuln.probes/) |
| P23 | `tldr vuln webui/src` | autodetect non-native (VAL-006 did NOT fire) | 0 | [`23-autodetect-non-native.*`](./vuln.probes/) |
| P24 | `tldr vuln <empty-tmp-dir>` | empty-dir | 0 | [`24-empty-dir.*`](./vuln.probes/) |
| P25 | `tldr vuln README.md` | non-source-md (silent) | 0 | [`25-non-source-md.*`](./vuln.probes/) |
| P26 | `tldr vuln ... -q` | quiet | 0 | [`26-quiet.*`](./vuln.probes/) |

### Observations

- **P01** — `backend/providers/`: 0 findings. `scan_duration_ms: 101, files_scanned: 4`. Empty result — Stock-Monitor backend has no taint-detectable vulnerabilities matching vuln's rule set.
- **P02** — `sinks.py` (deliberate SQL/shell sinks): **STILL 0 findings.** `scan_duration_ms: 5, files_scanned: 1`. Same engine limitation as `tldr taint` — function parameters are NOT treated as taint sources. The same code that `tldr taint` flagged sinks on, `tldr vuln` produces 0 findings. **Both commands have the same "parameters-aren't-tainted" limitation.**
- **P03** — stderr `"error: the following required arguments were not provided: <PATH>"`, exit `2`.
- **P04** — stderr `"Error: file not found: /no/such/dir"`, exit **5** (RemainingError::FileNotFound — matches `tldr secure`/`tldr dead-stores`). Lowercase "file".
- **P05** — stderr `"Error: --format dot not supported by vuln. Use --format json. DOT is only emitted by: clones, deps, calls, impact, hubs, inheritance."`, exit `1`.
- **P06** — Text format: 10 lines, human-readable summary.
- **P07** — Single-line minified JSON (actually compact, unlike `tldr resources`/`tldr taint`).
- **P08** — **SARIF supported!** Output is proper SARIF 2.1.0 schema: `$schema, version, runs: [{ tool: { driver: { name: "tldr-vuln", version: "0.4.0", informationUri, rules } }, results }]`. Empty `results` here because no findings. **Best CI integration in the audit suite** — SARIF is consumable by GitHub Code Scanning, Azure DevOps, etc.
- **P09** — `--severity critical`: same as default (0 findings to filter).
- **P10** — `--severity info`: same. The flag filters findings at or above the level.
- **P11** — clap-style with valid-values list inline: `"error: invalid value 'wat' for '--severity <SEVERITY>' [possible values: critical, high, medium, low, info]"`, exit `2`.
- **P12** — `--vuln-type sql_injection`: same empty result.
- **P13** — **BEST-IN-CLASS ERROR:** clap-style with ALL 13 vuln types listed inline: `"[possible values: sql_injection, xss, command_injection, ssrf, path_traversal, deserialization, unsafe_code, memory_safety, panic, xxe, open_redirect, ldap_injection, xpath_injection]"`, exit `2`. Discoverable.
- **P14** — Multiple `--vuln-type` (repeated): both filters combined.
- **P15** — `--include-informational`: should add lower-severity findings; same result here (none exist).
- **P16** — `--include-smells`: restores legacy `.unwrap()` panic emissions; same (Python project has no unwraps).
- **P17** — `--include-tests`: includes JS/TS test-file findings; same.
- **P18** — `-O <tmp>` writes JSON to file. stdout EMPTY (0 lines). File contains the same JSON. **Capital `-O`** short flag (differs from `tldr explain -o` lowercase and `tldr coverage -R` for `--report-format`).
- **P19** — `--no-default-ignore`: walks vendored dirs (`node_modules`, `target`, etc.). Same result on backend/providers/ (no vendored dirs there).
- **P20** — clap-style: `"error: invalid value 'brainfuck' for '--lang <LANG>': Unknown language: brainfuck"`, exit `2`.
- **P21** — Explicit `-l python`: identical to default (Python auto-detected).
- **P22** — `-l typescript` on Python: 0 findings. **Silent filter** — same anti-pattern as elsewhere.
- **P23** — **SOURCE-COMMENT DRIFT (or partial fix):** Per source comment VAL-006: "if the autodetected language lies outside the native-analysis set {Python, Rust}, error out early with exit code 2". On `webui/src` (TypeScript-only): exit **0**, scanned 156 files in 84 SECONDS, 0 findings. **VAL-006 did NOT fire.** Possible explanations: (a) autodetect returned None instead of Some(TypeScript) — but files_scanned: 156 means files WERE walked; (b) the engine accepted TypeScript but silently produces no findings; (c) the VAL-006 fix is incomplete. Document as observed.
- **P24** — Empty dir: same empty shape with `files_scanned: 0`.
- **P25** — README.md: same shape with `files_scanned: 1`. **Silent acceptance** of non-source.
- **P26** — `-q` suppresses progress (none observed for this scope).

---

## Source Code Reality

**Target file(s):**
- `crates/tldr-cli/src/commands/remaining/vuln.rs` (~250+ lines)
- `crates/tldr-core/src/security/vuln.rs` (taint-driven vuln engine)
- `crates/tldr-cli/src/output.rs:113` (`validate_format_for_command`)

**Pinned to upstream commit:** `6c4011a` (release v0.4.0)

**Argument struct (key flags):**
```rust
// crates/tldr-cli/src/commands/remaining/vuln.rs:74-115
#[derive(Debug, Args)]
pub struct VulnArgs {
    pub path: PathBuf,
    #[arg(long, short = 'l')] pub lang: Option<Language>,
    #[arg(long)] pub severity: Option<Severity>,
    #[arg(long, value_name = "TYPE")] pub vuln_type: Option<Vec<VulnType>>,
    #[arg(long)] pub include_informational: bool,
    #[arg(long)] pub include_smells: bool,
    #[arg(long)] pub include_tests: bool,
    #[arg(long, short = 'O')] pub output: Option<PathBuf>,
    #[arg(long)] pub no_default_ignore: bool,
}
```
Reveals: `--vuln-type` is `Option<Vec<VulnType>>` — accepts repeated flag (P14). `--severity` and `--vuln-type` are clap-typed enums with possible-values enforcement. `-O` (capital) for `--output` is uncommon — most tldr commands use lowercase `-o`.

**Path validation:**
```rust
// vuln.rs:127-129
if !self.path.exists() {
    return Err(RemainingError::file_not_found(&self.path).into());
}
```
Reveals: RemainingError → exit 5 (matches `tldr secure`/`tldr dead-stores`; differs from ContractsError exit 1 and TldrError exit 2).

**VAL-006 source comment (autodetect outside native set):**
The source comment block at vuln.rs:142-148 claims: "if the autodetected language lies outside the native-analysis set {Python, Rust}, error out early with exit code 2 and a message that points the user at an explicit --lang flag." **However, P23 shows this does NOT fire** for `webui/src` (TypeScript-only). Possible source-comment drift OR autodetect returns None for that path.

**SARIF support:** confirmed at `crates/tldr-cli/src/output.rs:113-163` — `vuln` IS in `SARIF_SUPPORTED` (alongside `clones`). NOT in `DOT_SUPPORTED`.

**No daemon route:** `grep -n try_daemon_route remaining/vuln.rs` returns 0 matches.

---

## Architectural Deep Dive

- **Under the hood:** Taint-based vulnerability scanner. For each function: identifies external sources (request input, file reads, env vars), traces taint flow through CFG, flags reaching sinks (SQL execute, shell exec, eval, file open, etc.). Emits findings categorized by 13 vuln types and 5 severity levels. **Same engine limitation as `tldr taint`**: function parameters are NOT treated as sources.
- **Performance:** Cold ~100ms per 4 files (Python); larger projects 1-30s. NO daemon caching. Slow command per protocol — use `--quick` analog via PATH scoping.
- **LLM cognitive load:** CI-friendly security scanner. SARIF format makes it pipe directly into GitHub Code Scanning. Pair with `tldr secure` (broader analysis) and `tldr taint` (per-function deep-dive). For mature Python codebases, expect mostly 0 findings — the engine is conservative and parameters aren't auto-tainted.

---

## Intent & Routing

- **User/Agent Goal:** scan a project for known vulnerability classes (SQL injection, XSS, command injection, etc.) and emit findings in SARIF for CI integration.
- **When to choose this over similar tools:**
  - Over `tldr taint`: taint is per-function deep-dive; vuln is project-wide categorized scan with SARIF.
  - Over `tldr secure`: secure aggregates multiple analyses; vuln focuses on the taint-based vuln engine.
  - Over external SAST tools: integrated tldr workflow, SARIF-compatible.
- **Prerequisites (composition):**
  - PATH required (no default).
  - For non-Python/Rust projects, expect 0 findings (engine native set is Python + Rust per VAL-006 comment).
  - For CI integration, use `-f sarif -O findings.sarif` and upload to your scanning service.

---

## Agent Synthesis

> **How to use `tldr vuln`:**
> Vulnerability scanner (taint-driven). `tldr vuln <PATH>` returns JSON `{ findings, summary, scan_duration_ms, files_scanned }`. `summary: { total_findings, by_severity, by_type, files_with_vulns }`. Filter by `--severity {critical,high,medium,low,info}` and/or `--vuln-type <type>` (repeatable; 13 types). Default suppresses smells and JS/TS test-file findings — pass `--include-smells` / `--include-tests` to restore. Default JSON; `-f text` for report; `-f compact` for one-line; **`-f sarif` SUPPORTED** (SARIF 2.1.0 schema for CI consumption); `dot` rejected. `-O <file>` writes to file (stdout empty). Exit codes: 0 ok (including 0-findings empty), 1 format-reject, 2 missing PATH / bad-severity / bad-vuln-type / bad-lang, 5 file-not-found.
>
> **Crucial Rules:**
> - **Function PARAMETERS are NOT taint sources** (P02: `sinks.py` with explicit SQL injection patterns yields 0 findings). Same limitation as `tldr taint`. The engine requires EXPLICIT external sources (file_read, request input). For maximum coverage, manually annotate inputs or use external SAST.
> - **`tldr vuln` is one of only TWO commands emitting SARIF** (the other is `tldr clones`). Use `-f sarif -O findings.sarif` for direct CI upload to GitHub Code Scanning. Output is SARIF 2.1.0 — `tool.driver.name: "tldr-vuln"`, `tool.driver.version: "0.4.0"`, `results: []`.
> - **VAL-006 source-comment drift:** Source claims autodetected non-native language (outside {Python, Rust}) errors with exit 2 and a `--lang` hint. P23: `tldr vuln webui/src` (TypeScript-only) returns exit 0 with `files_scanned: 156, findings: [], scan_duration_ms: 84812` — VAL-006 did NOT fire. Either the autodetect returns None for that path OR the fix is incomplete. **Recovery hint:** for non-Python/Rust projects, expect 0 findings regardless; use `tldr secure` for broader analysis.
> - **File-not-found exit code is 5** (RemainingError::FileNotFound — matches `tldr secure`/`tldr dead-stores`). Distinct from ContractsError (exit 1) and TldrError (exit 2).
> - **Bad `--vuln-type` error lists ALL 13 valid types inline** (P13). Best-in-class CLI affordance for discoverability.
> - **`-O` (capital) for `--output`** — unique short flag among audit commands (`tldr explain -o`, `tldr coverage -R`, `tldr cognitive`/etc. use lowercase). Pattern matches `tldr api-check -O`.
> - **`--vuln-type` is REPEATABLE** (P14). Use multiple `--vuln-type X --vuln-type Y` to combine.
> - **README.md is SILENTLY ACCEPTED with `files_scanned: 1, findings: []`.** Distinct from `tldr loc`/`tldr halstead`/`tldr patterns` exit 11 and `tldr resources` exit 1.
> - **`-l typescript` on Python project silently produces 0 findings** (P22). Same anti-pattern as elsewhere. The engine doesn't warn about lang mismatch.
> - **Severity values:** `critical, high, medium, low, info`. Vuln type list (13): `sql_injection, xss, command_injection, ssrf, path_traversal, deserialization, unsafe_code, memory_safety, panic, xxe, open_redirect, ldap_injection, xpath_injection`.
> - **NO daemon route.** Slow on large projects (84s on 156-file TypeScript repo).
>
> **Command:** `tldr vuln <PATH>`
>
> **With common flags:** `tldr vuln <PATH> -f sarif -O findings.sarif --severity high --include-tests` (use for CI: SARIF output to file for upload, only high/critical findings, including test-file findings if you actually want to inspect them).
