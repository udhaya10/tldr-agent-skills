# Command: `tldr temporal`

## Environment Pin

| Field | Value |
|---|---|
| `tldr --version` | 0.4.0 |
| Build features | `semantic` (verified; temporal is AST-based sequence mining, non-semantic) |
| Target repo | Stock-Monitor @ commit `e601869` |
| Upstream `tldr-code` pinned to | local clone @ `6c4011a` (release v0.4.0) |
| Daemon state at probe time | N/A — `tldr temporal` does **not** call `try_daemon_route` (verified by grep) |
| OS | darwin 25.2.0 |
| Probe date | 2026-05-22 |

Re-run all evidence via [`temporal.probes/probe.sh`](./temporal.probes/probe.sh).

---

## Ground Truth (`tldr temporal --help`)

```text
Mine temporal constraints (method call sequences)

Usage: tldr temporal [OPTIONS] <PATH>

Arguments:
  <PATH>
          Directory or file to analyze

Options:
      --min-support <MIN_SUPPORT>          [default: 2]
      --min-confidence <MIN_CONFIDENCE>    [default: 0.5]
      --query <QUERY>                      Filter for specific method
      --source-lang <SOURCE_LANG>          [default: python]
      --max-files <MAX_FILES>              [default: 1000]
      --include-trigrams                   Mine 3-method sequences
      --include-examples <INCLUDE_EXAMPLES>  [default: 3]
      --timeout <TIMEOUT>                  [default: 60]
      --project-root <PROJECT_ROOT>
  -l, --lang <LANG>                        Language filter
  -f, --format <FORMAT>                    [default: json]
  -q, --quiet  -v, --verbose  -h, --help
```

---

## Output Shape

| Aspect | Value |
|---|---|
| Default format | `json` |
| Formats that work | `json`, `text` (P01, P06) |
| Formats that error | `sarif`, `dot` (P05, P08: exit 1) |
| **Format quirk** | **`-f compact` returns pretty JSON, NOT single-line** (similar to taint/resources) |
| Typical output size | medium (~325 lines for 4-file dir; ~12000 for full backend; ~22000 with `--include-trigrams`) |

**Top-level keys (JSON, `TemporalReport`):**
- `constraints` (`array<Constraint>`) — 2-method sequences (bigrams) — pattern "method A called before method B"
- `trigrams` (`array<Trigram>`) — 3-method sequences (only populated with `--include-trigrams`)
- `metadata` (`object`) — `{ files_analyzed, sequences_extracted, min_support, min_confidence }`

**`Constraint` shape:**
- `before` (`string`) — first method in sequence (often qualified: `"yf.Ticker"`)
- `after` (`string`) — second method
- `support` (`u32`) — number of occurrences across the codebase
- `confidence` (`float64`) — 0.0–1.0; how often `before` is followed by `after`
- `examples` (`array<Example>`) — capped at `--include-examples N` (default 3). Each `Example`: `{ file (ABSOLUTE), line }`

**Empty-result shape (P10 min-support 999, P13 query no-match, P24 empty dir, P25 README.md):**
```json
{
  "constraints": [], "trigrams": [],
  "metadata": { "files_analyzed": <N>, "sequences_extracted": <N>, "min_support": <X>, "min_confidence": 0.5 }
}
```
Exit 0. `sequences_extracted` count DIFFERENTIATES failure modes: P10 (high threshold) shows `sequences_extracted: 276` (extraction worked, filter dropped all); P13 (bad query) also 276; P24 (empty dir) shows 0; P25 (non-source md) shows `files_analyzed: 1, sequences_extracted: 0`.

**Error shapes:**
- Missing PATH: clap-style → exit **2**
- File not found: `"Error: file not found: /no/such/dir"` → exit **1** (lowercase "file"; matches `tldr cohesion`/`tldr resources`)
- Format reject: `"Error: --format sarif not supported by temporal. ..."` → exit **1**
- Bad `--source-lang`: `"Error: unsupported language: wat"` → exit **1** (NOT clap — handled by the command's own parser since `--source-lang` is `String` not enum)
- Bad `--lang` (global): clap-style → exit **2**

---

## Probe Matrix

| # | Probe | Type | Exit | Captured |
|---|-------|------|------|----------|
| P01 | `tldr temporal backend/providers` | happy | 0 | [`01-happy.*`](./temporal.probes/) |
| P02 | `tldr temporal backend` | happy-scale | 0 | [`02-happy-scale.*`](./temporal.probes/) |
| P03 | `tldr temporal` *(no PATH)* | failure-missing-input | 2 | [`03-missing-arg.*`](./temporal.probes/) |
| P04 | `tldr temporal /no/such/dir` | failure-badpath | 1 | [`04-badpath.*`](./temporal.probes/) |
| P05 | `tldr temporal ... -f sarif` | format-reject (sarif) | 1 | [`05-format-reject-sarif.*`](./temporal.probes/) |
| P06 | `tldr temporal ... -f text` | format-text | 0 | [`06-format-text.*`](./temporal.probes/) |
| P07 | `tldr temporal ... -f compact` | format-compact (pretty JSON quirk) | 0 | [`07-format-compact.*`](./temporal.probes/) |
| P08 | `tldr temporal ... -f dot` | format-reject (dot) | 1 | [`08-format-reject-dot.*`](./temporal.probes/) |
| P09 | `tldr temporal ... --min-support 1` | min-support low (more results) | 0 | [`09-min-support-low.*`](./temporal.probes/) |
| P10 | `tldr temporal ... --min-support 999` | min-support high (empty) | 0 | [`10-min-support-high.*`](./temporal.probes/) |
| P11 | `tldr temporal ... --min-confidence 0.0` | min-conf zero | 0 | [`11-min-conf-zero.*`](./temporal.probes/) |
| P12 | `tldr temporal ... --min-confidence 1.0` | min-conf perfect | 0 | [`12-min-conf-perfect.*`](./temporal.probes/) |
| P13 | `tldr temporal ... --query <method>` | query filter (empty here) | 0 | [`13-query-method.*`](./temporal.probes/) |
| P14 | `tldr temporal ... --source-lang python` | explicit python | 0 | [`14-source-lang-python.*`](./temporal.probes/) |
| P15 | `tldr temporal ... --source-lang auto` | source-lang auto | 0 | [`15-source-lang-auto.*`](./temporal.probes/) |
| P16 | `tldr temporal ... --source-lang wat` | bad source-lang (engine error) | 1 | [`16-source-lang-bogus.*`](./temporal.probes/) |
| P17 | `tldr temporal backend --max-files 1` | max-files cap | 0 | [`17-max-files-low.*`](./temporal.probes/) |
| P18 | `tldr temporal backend --include-trigrams` | include-trigrams | 0 | [`18-include-trigrams.*`](./temporal.probes/) |
| P19 | `tldr temporal ... --include-examples 0` | zero examples per constraint | 0 | [`19-include-examples-zero.*`](./temporal.probes/) |
| P20 | `tldr temporal ... --timeout 1` | timeout short | 0 | [`20-timeout-short.*`](./temporal.probes/) |
| P21 | `tldr temporal ... --project-root <dir>` | project-root | 0 | [`21-project-root.*`](./temporal.probes/) |
| P22 | `tldr temporal ... -l brainfuck` | bad-lang (global) | 2 | [`22-bad-lang.*`](./temporal.probes/) |
| P23 | `tldr temporal ... -l python` | lang-python (global) | 0 | [`23-lang-python.*`](./temporal.probes/) |
| P24 | `tldr temporal <empty-tmp-dir>` | empty-dir | 0 | [`24-empty-dir.*`](./temporal.probes/) |
| P25 | `tldr temporal README.md` | non-source-md (silent empty) | 0 | [`25-non-source-md.*`](./temporal.probes/) |
| P26 | `tldr temporal ... -q` | quiet | 0 | [`26-quiet.*`](./temporal.probes/) |

### Observations

- **P01** — `backend/providers/`: rich constraint list. Example: `{ before: "yf.Ticker", after: "_to_finite_float", support: 3, confidence: 1.0, examples: [3 file:line entries] }`. 327 lines.
- **P02** — Full `backend/`: 12691 lines (severely truncated by probe.sh 500-line cap).
- **P03** — stderr `"error: the following required arguments were not provided: <PATH>"`, exit `2`.
- **P04** — stderr `"Error: file not found: /no/such/dir"`, exit `1`. Lowercase "file" — matches `tldr cohesion`/`tldr resources`/`tldr contracts`.
- **P05** — stderr `"Error: --format sarif not supported by temporal. ..."`, exit `1`.
- **P06** — Text format: 133 lines, human-readable constraint report.
- **P07** — **`-f compact` returns PRETTY JSON, NOT single-line.** Line count same (327) as default; only example-ordering differs slightly (HashMap iteration non-determinism). Same bug class as `tldr taint`/`tldr resources`. Workaround: `jq -c`.
- **P08** — stderr `"Error: --format dot not supported by temporal. ..."`, exit `1`.
- **P09** — `--min-support 1`: 699 lines — many more constraints accepted at lower support threshold.
- **P10** — `--min-support 999`: `constraints: [], metadata: { sequences_extracted: 276, min_support: 999 }`. **The metadata REPORTS the user's requested threshold but `sequences_extracted` shows the engine still extracted 276 sequences before filtering.** Cross-check signal.
- **P11** — `--min-confidence 0.0`: 487 lines — slightly more constraints (engine emits low-confidence ones).
- **P12** — `--min-confidence 1.0`: 211 lines — fewer constraints, only perfect-confidence ones.
- **P13** — `--query fetch_historical_data`: `constraints: []` — the query filter matches against `before`/`after` exact names. Stock-Monitor's actual constraints use qualified names like `yf.Ticker`, `_to_finite_float` — none have exact name `fetch_historical_data` in their before/after slots. **Subtle:** `--query` is positional-exact match, not substring search.
- **P14** — Explicit `--source-lang python`: identical to default (P01).
- **P15** — `--source-lang auto`: identical to P01. Auto-detect returns python.
- **P16** — **DISTINCT error path for `--source-lang`:** stderr `"Error: unsupported language: wat"`, exit `1`. NOT clap-rejected (since `--source-lang` is `String` per `--help` "Accepts any of the 18 TLDR languages or auto"). The engine validates and emits its own error message. Differs from `--lang -l <bad>` (clap exit 2).
- **P17** — `--max-files 1` on backend: 1819 lines — even with 1 file, constraint mining produces rich output.
- **P18** — `--include-trigrams`: 22440 lines (massive growth — 3-method sequences explode combinatorially). For large repos, this flag is expensive.
- **P19** — `--include-examples 0`: 144 lines — each constraint has empty `examples: []`. Saves tokens for LLM consumption.
- **P20** — `--timeout 1` (1 second): completed in time on this scope (347 lines). For large repos, timeout would abort with engine-level error.
- **P21** — `--project-root backend`: identical output to P01. Used for path validation.
- **P22** — clap-style: `"error: invalid value 'brainfuck' for '--lang <LANG>': Unknown language: brainfuck"`, exit `2`.
- **P23** — Explicit `-l python`: identical to default.
- **P24** — Empty dir: `files_analyzed: 0, sequences_extracted: 0`. Distinguishable from "filtered to empty" (P10) by these counts.
- **P25** — README.md: exit 0 with `files_analyzed: 1, sequences_extracted: 0`. **Silent acceptance** of non-source file. NO error or warning. Distinct from `tldr taint`/`tldr resources` which produce errors.
- **P26** — `-q` suppresses any progress output (none observed in this command anyway).

---

## Source Code Reality

**Target file(s):**
- `crates/tldr-cli/src/commands/patterns/temporal.rs` (~1500+ lines)
- `crates/tldr-core/src/patterns/temporal/...` (sequence extractor, FP-growth mining)
- `crates/tldr-cli/src/output.rs:113` (`validate_format_for_command`)

**Pinned to upstream commit:** `6c4011a` (release v0.4.0)

**Argument struct (key flags):**
```rust
// crates/tldr-cli/src/commands/patterns/temporal.rs:61-115
#[derive(Debug, Args)]
pub struct TemporalArgs {
    pub path: PathBuf,
    #[arg(long, default_value = "2")] pub min_support: u32,
    #[arg(long, default_value = "0.5")] pub min_confidence: f64,
    #[arg(long)] pub query: Option<String>,
    #[arg(long = "source-lang", default_value = "python")] pub source_lang: String,
    #[arg(long, default_value = "1000")] pub max_files: u32,
    #[arg(long)] pub include_trigrams: bool,
    #[arg(long, default_value = "3")] pub include_examples: u32,
    #[arg(long = "output", short = 'o', hide = true, default_value = "json", value_enum)]
    pub output_format: OutputFormat,
    #[arg(long, default_value = "60")] pub timeout: u64,
    #[arg(long)] pub project_root: Option<PathBuf>,
    #[arg(long, short = 'l')] pub lang: Option<Language>,
}
```
Reveals: `--source-lang` is `String` (legacy) — accepts unconstrained input, validated at engine level. `--lang` is `Option<Language>` (clap-typed, strict). **Two language flags coexist:** `--source-lang` (legacy, string) and `-l/--lang` (global, typed).

**Format validation:** confirmed at `crates/tldr-cli/src/output.rs:113-163` — `temporal` is in neither `SARIF_SUPPORTED` nor `DOT_SUPPORTED`.

**No daemon route:** `grep -n try_daemon_route patterns/temporal.rs` returns 0 matches.

---

## Architectural Deep Dive

- **Under the hood:** Per-file tree-sitter parse → `SequenceExtractor` walks each function, tracks variable assignments and method calls per object. Builds object→[method_a, method_b, method_c, ...] sequences. FP-Growth-like algorithm mines frequent bigrams (and trigrams if `--include-trigrams`). For each pair (A, B): support = total occurrences; confidence = P(B | A) = occurrences(A→B) / occurrences(A).
- **Performance:** Cold ~100-500ms per 4-file dir. `--include-trigrams` is exponentially more expensive. NO daemon caching. `--timeout 60` default protects against pathological inputs (E03 mitigation per source).
- **LLM cognitive load:** The CANONICAL command for "what's the expected order of operations in this codebase?" — useful for inferring init/teardown sequences, builder patterns, lifecycle protocols. The `examples[]` array is highest-value for LLM context — actual file:line pairs that demonstrate the constraint.

---

## Intent & Routing

- **User/Agent Goal:** mine method-call sequences from a codebase — discover "A is usually called before B" patterns (e.g., `open()` before `read()`, `acquire()` before `release()`).
- **When to choose this over similar tools:**
  - Over `tldr patterns`: patterns is convention-based; temporal is sequence-based.
  - Over `tldr calls`: calls is the call graph; temporal is call ORDERING.
  - Over `tldr resources`: resources tracks RESOURCE lifecycles; temporal tracks any method ordering.
- **Prerequisites (composition):**
  - Pass a directory (file works too but yields fewer sequences).
  - Default `--source-lang python` — override for non-Python projects (or use `--source-lang auto`).
  - For specific method investigation, use `--query <exact-name>`.
  - For deeper sequences, add `--include-trigrams` (note: 50x slower, much larger output).

---

## Agent Synthesis

> **How to use `tldr temporal`:**
> Method-sequence miner. `tldr temporal <PATH>` returns JSON `{ constraints, trigrams, metadata }`. Each `Constraint` has `{ before, after, support, confidence, examples: [{file, line}] }`. Default mines 2-method sequences (bigrams); `--include-trigrams` adds 3-method sequences. Default `--min-support 2`, `--min-confidence 0.5`, `--include-examples 3`. Default JSON; `-f text` for human report; **`-f compact` returns pretty JSON quirk (NOT single-line)**; `sarif`/`dot` rejected. Exit codes: 0 ok (including silent empty for non-source files), 1 file-not-found / bad --source-lang / format-reject, 2 missing PATH / bad --lang.
>
> **Crucial Rules:**
> - **TWO LANGUAGE FLAGS coexist:** `--source-lang <STRING>` (legacy, default "python", accepts `auto`) AND `-l/--lang <Language>` (global, clap-typed). The legacy `--source-lang` accepts any string and validates at engine level (P16: bad value → "unsupported language: wat", exit 1). The global `-l` rejects via clap (P22: exit 2). For new code, use `-l`; the legacy `--source-lang` is documented as "legacy" in `--help`.
> - **`--source-lang` default is hardcoded `"python"`**, NOT auto-detect. This is the ONLY tldr command with a non-auto default language. For non-Python projects, MUST pass `--source-lang <lang>` or `--source-lang auto`, otherwise the engine tries Python and produces empty results.
> - **`-f compact` returns PRETTY JSON, not single-line** (P07). Line count same as default. Same quirk class as `tldr taint`/`tldr resources`. Workaround: `jq -c`.
> - **`--query <method>` is EXACT MATCH** against `before`/`after` qualified names (P13). Stock-Monitor constraints use qualified names like `"yf.Ticker"`, `"_to_finite_float"` — a query like `fetch_historical_data` doesn't match because no constraint has that exact name in either slot. For substring search, pipe output to `jq '.constraints[] | select(.before | contains("X"))'`.
> - **`--include-trigrams` is EXPONENTIALLY MORE EXPENSIVE.** P18: 22,440 lines vs 12,691 for backend/ (1.8x size). On larger repos, can produce massive output. Use sparingly.
> - **README.md is SILENTLY ACCEPTED with empty result** (P25). `files_analyzed: 1, sequences_extracted: 0`. NO error/warning. Distinct from `tldr taint`/`tldr resources` which produce errors for non-source files.
> - **`metadata.sequences_extracted` distinguishes failure modes:** P10 (filter too strict): 276 sequences extracted, 0 constraints; P25 (non-source): 0 sequences; P24 (empty dir): 0 files, 0 sequences. Inspect both `files_analyzed` and `sequences_extracted` to diagnose empty results.
> - **`--include-examples 0` saves tokens** (P19: 144 lines vs 327 default). For LLM consumption when only the constraint statements matter.
> - **File-not-found exit code is 1**, lowercase `"file not found:"` (matches `tldr cohesion`/`tldr resources`/`tldr contracts`).
> - **NO daemon route.** Every call walks + extracts + mines fresh.
> - **`examples[].file` is ABSOLUTE PATH** (not project-relative). Strip prefix for portable output.
>
> **Command:** `tldr temporal <PATH>`
>
> **With common flags:** `tldr temporal <PATH> --min-support 5 --min-confidence 0.8 --include-examples 1 -f compact | jq '.constraints | sort_by(-.support) | .[:10]'` (use for top-10 high-confidence sequences with minimal example overhead, ideal for inferring API protocols).
