# Command: `tldr clones`

## Environment Pin

| Field | Value |
|---|---|
| `tldr --version` | 0.4.0 |
| Build features | `semantic` (verified; clones is token-based, non-semantic) |
| Target repo | Stock-Monitor @ commit `e601869` |
| Upstream `tldr-code` pinned to | local clone @ `6c4011a` (release v0.4.0) |
| Daemon state at probe time | N/A — `tldr clones` does **not** call `try_daemon_route` (verified by grep) |
| Scoping | All probes against `backend/providers/` (4 files). Clone detection is O(N²); full backend (56 files) would exceed 30s — per Journal 04 §13 slow-command guidance |
| OS | darwin 25.2.0 |
| Probe date | 2026-05-22 |

Re-run all evidence via [`clones.probes/probe.sh`](./clones.probes/probe.sh).
See also: [agent-oriented tool card](../../tool-cards/audit/clones.md).

---

## Ground Truth (`tldr clones --help`)

```text
Detect code clones in a codebase

Usage: tldr clones [OPTIONS] [PATH]

Arguments:
  [PATH]
          Path to analyze (default: current directory)

          [default: .]

Options:
      --min-tokens <MIN_TOKENS>
          Minimum tokens for a clone (default: 25)

          [default: 25]

      --min-lines <MIN_LINES>
          Minimum lines for a clone (default: 5)

          [default: 5]

  -t, --threshold <THRESHOLD>
          Similarity threshold (0.0-1.0, default: 0.7)

          [default: 0.7]

      --type-filter <TYPE_FILTER>
          Filter by clone type: 1, 2, 3, or all (default: all)

          [default: all]

      --normalize <NORMALIZE>
          Normalization mode: none, identifiers, literals, all (default: all)

          [default: all]

      --language <LANGUAGE>
          Filter by language: python, typescript, go, rust

  -o, --output <OUTPUT>
          Output format: json, text, sarif (default: json) Use sarif for IDE/CI integration (GitHub, VS Code, etc.)

          [default: json]

      --show-classes
          Show clone classes (transitive grouping)

      --include-within-file
          Include clones within the same file

      --max-clones <MAX_CLONES>
          Maximum clones to report (default: 20)

          [default: 20]

      --max-files <MAX_FILES>
          Maximum files to analyze (default: 1000)

          [default: 1000]

      --exclude-generated
          Exclude generated files (e.g., *.pb.go, *_generated.ts, vendor/, etc.)

      --exclude-tests
          Exclude test files (e.g., test_*.py, *_test.go, *_spec.rb, tests/, __tests__/)

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
| Formats that work | `json`, `text`, `compact`, **`sarif`**, **`dot`** (P01, P06, P07, P08, P09) |
| Formats that error | (none — clones is in BOTH `SARIF_SUPPORTED` and `DOT_SUPPORTED`) |
| Typical output size | small (<1 KB no clones) to medium (~5 KB with several clones + sarif boilerplate) |

**Top-level keys (JSON, `CloneDetectionReport`):**
- `root` (`string`) — input PATH (NOT canonicalized)
- `language` (`string`) — resolved language (`"python"`, `"auto"`, etc.)
- `clone_pairs` (`array<ClonePair>`) — found clone pairs, truncated to `--max-clones`
- `stats` (`object`) — `{ files_analyzed, total_tokens, clones_found, type1_count, type2_count, type3_count, detection_time_ms }`
- `config` (`object`) — echoes `{ min_tokens, min_lines, similarity_threshold, normalization }` for reproducibility
- `total_clones` (`u32`) — **TOP-LEVEL MIRROR** of `stats.clones_found`
- `files_analyzed` (`u32`) — **TOP-LEVEL MIRROR** of `stats.files_analyzed`
- `summary` (`object`) — duplicate of `stats` shape, with `total_clones` instead of `clones_found`

**`ClonePair` shape:**
- `id` (`u32`)
- `clone_type` (`string`) — `"Type-1"`, `"Type-2"`, `"Type-3"`
- `similarity` (`float64`, 0.0–1.0)
- `fragment1`, `fragment2` (`Fragment`) — `{ file, start_line, end_line, tokens, lines, preview }` (preview is a 100-char source snippet)
- `interpretation` (`string`) — human bucket: `"Moderate similarity (Type-3 clone candidate)"`, etc.

**DOT format (P09):** Minimal `digraph clones { ... }` — empty when no clones found (just the `digraph` wrapper). With clones, edges would represent clone-pair relationships.

**SARIF format (P08):** Full SARIF 2.1.0 spec — `{ "$schema": "...sarif-2.1.0...", "version": "2.1.0", "runs": [{ tool: { driver: ... }, results: [...] }] }`. CI/IDE-ready.

**Silent-failure shapes:**
- **Bad path returns exit 0 with empty result.** P04: `tldr clones /no/such/dir` returns the standard schema with `files_analyzed: 0`, `language: "auto"`. NO error — only the zero count signals the failure.
- **`--language <wrong>` returns exit 0 with empty result.** P19: `--language typescript` on a Python-only dir → `files_analyzed: 0`.

**Error shapes:**
- Bad `-f <value>`: clap-style `"error: invalid value 'wat' for '--format <FORMAT>' [possible values: json, text, compact, sarif, dot]"` → exit **2**
- Bad `--lang`: clap-style → exit **2**
- **NO file-not-found error** — bad paths are silently accepted (P04)

---

## Probe Matrix

| # | Probe | Type | Exit | Captured |
|---|-------|------|------|----------|
| P01 | `tldr clones backend/providers` | happy (no clones at default 0.7) | 0 | [`01-happy.*`](./clones.probes/) |
| P02 | `tldr clones backend/providers --threshold 0.5` | happy-scale (1 Type-3 clone) | 0 | [`02-happy-scale.*`](./clones.probes/) |
| P03 | N/A: PATH defaults to `.`. | — | — | [`03-missing-arg.*`](./clones.probes/) (placeholder) |
| P04 | `tldr clones /no/such/dir` | badpath (silent empty!) | 0 | [`04-badpath.*`](./clones.probes/) |
| P05 | `tldr clones ... -f wat` | bad-format (clap) | 2 | [`05-format-reject-bogus.*`](./clones.probes/) |
| P06 | `tldr clones ... -f text` | format-text | 0 | [`06-format-text.*`](./clones.probes/) |
| P07 | `tldr clones ... -f compact` | format-compact | 0 | [`07-format-compact.*`](./clones.probes/) |
| P08 | `tldr clones ... -f sarif` | format-sarif (supported) | 0 | [`08-format-sarif.*`](./clones.probes/) |
| P09 | `tldr clones ... -f dot` | format-dot (supported) | 0 | [`09-format-dot.*`](./clones.probes/) |
| P10 | `tldr clones ... --threshold 0.99` | high-threshold (empty) | 0 | [`10-threshold-high.*`](./clones.probes/) |
| P11 | `tldr clones ... --threshold 0.0` | zero-threshold (all pairs) | 0 | [`11-threshold-zero.*`](./clones.probes/) |
| P12 | `tldr clones ... --min-tokens 100` | high-min-tokens (filters out small) | 0 | [`12-min-tokens-high.*`](./clones.probes/) |
| P13 | `tldr clones ... --min-lines 50` | high-min-lines | 0 | [`13-min-lines-high.*`](./clones.probes/) |
| P14 | `tldr clones ... --type-filter 1` | Type-1-only filter | 0 | [`14-type-filter-1.*`](./clones.probes/) |
| P15 | `tldr clones ... --type-filter wat` | bogus type-filter (silent fallback) | 0 | [`15-type-filter-bogus.*`](./clones.probes/) |
| P16 | `tldr clones ... --normalize none` | normalize-none | 0 | [`16-normalize-none.*`](./clones.probes/) |
| P17 | `tldr clones ... --normalize wat` | bogus normalize (silent fallback) | 0 | [`17-normalize-bogus.*`](./clones.probes/) |
| P18 | `tldr clones ... --language python` | local --language flag | 0 | [`18-language-local.*`](./clones.probes/) |
| P19 | `tldr clones ... --language typescript` | local lang mismatch | 0 | [`19-language-mismatch.*`](./clones.probes/) |
| P20 | `tldr clones ... -l python` | global --lang flag | 0 | [`20-global-lang.*`](./clones.probes/) |
| P21 | `tldr clones ... --include-within-file` | within-file flag | 0 | [`21-include-within-file.*`](./clones.probes/) |
| P22 | `tldr clones ... --show-classes` | show-classes flag | 0 | [`22-show-classes.*`](./clones.probes/) |
| P23 | `tldr clones ... --max-clones 1` | truncation | 0 | [`23-max-clones-low.*`](./clones.probes/) |
| P24 | `tldr clones ... --max-files 1` | file-cap | 0 | [`24-max-files-low.*`](./clones.probes/) |
| P25 | `tldr clones ... --exclude-tests --exclude-generated` | exclusions | 0 | [`25-excludes.*`](./clones.probes/) |
| P26 | `tldr clones ... -o sarif` | legacy -o flag | 0 | [`26-legacy-output-sarif.*`](./clones.probes/) |
| P27 | `tldr clones ... -q` | quiet | 0 | [`27-quiet.*`](./clones.probes/) |

### Observations

- **P01** — Default threshold 0.7 on 4 Python files: 0 clones detected. `files_analyzed: 4`, `total_tokens: 2514`. `language: "python"` (auto-detected from extensions).
- **P02** — Threshold 0.5: 1 Type-3 clone pair (`dhan.py` lines 1-230 vs `yahoo.py` lines 1-239, similarity 0.71). Both files are Provider implementations — high structural similarity, different identifiers/literals → Type-3.
- **P03** — **N/A.** PATH defaults to `.`.
- **P04** — **SILENT FAILURE:** `tldr clones /no/such/dir` exits 0 with valid JSON `{ root: "/no/such/dir", language: "auto", files_analyzed: 0, ... }`. NO error message. **No exit code distinction between "path doesn't exist" and "path exists but has 0 matching files"** — agents must inspect `files_analyzed > 0` to detect path validity.
- **P05** — clap-style: `"error: invalid value 'wat' for '--format <FORMAT>' [possible values: json, text, compact, sarif, dot]"`, exit `2`. **Possible-values list confirms clones supports sarif AND dot at the global format gate.**
- **P06** — Text format: `"Clone Detection: 0 pairs in 4 files (2514 tokens)\n\nNo clones found."` — minimalist.
- **P07** — Single-line minified JSON.
- **P08** — **SARIF 2.1.0 output** (supported). Schema URI is `https://raw.githubusercontent.com/oasis-tcs/sarif-spec/...sarif-2.1.0.json`. `runs[0].tool.driver.name: "tldr"`, version `0.4.0`. CI-ready.
- **P09** — DOT graph: `digraph clones { rankdir=LR; ... }`. EMPTY body when no clones (only the wrapper). With clones, edges would represent pair relationships.
- **P10** — `--threshold 0.99`: 0 clones (no pair reaches 99% similarity). Exit 0.
- **P11** — `--threshold 0.0`: **6 clone pairs** (every file-pair combination among 4 files = C(4,2) = 6). Threshold floor admits all candidates. Note this includes the Type-3 pair from P02 PLUS 5 lower-similarity pairs.
- **P12** — `--min-tokens 100`: same output as default (0 clones). Filter eliminates fragments smaller than 100 tokens.
- **P13** — `--min-lines 50`: same as default (0 clones). Filter eliminates fragments shorter than 50 lines.
- **P14** — `--type-filter 1`: Type-1 (exact) only → 0 clones in this scope. Confirms default 0.7 + Type-3 detection found only Type-3, not Type-1.
- **P15** — `--type-filter wat`: **silently falls back to "all"** (per `parse_type_filter` at `clones.rs:171-179` — unknown values map to `None` which means all). Output identical to default. No error.
- **P16** — `--normalize none`: same 0 clones (more conservative matching → fewer Type-2/3 clones, same Type-1 count).
- **P17** — `--normalize wat`: **silently falls back to All** (per `NormalizationMode::parse(...).unwrap_or(NormalizationMode::All)` at `clones.rs:91-92`). Output identical to default. No error.
- **P18** — `--language python` (local flag): same as default — Python is auto-detected anyway.
- **P19** — `--language typescript` (local lang mismatch): `files_analyzed: 0`, `language: "typescript"`. **The local --language flag filters files by extension; .py files are skipped.** Silent empty result.
- **P20** — `-l python` (GLOBAL lang flag): same output as P18. Source confirms the global `-l/--lang` is honored at `clones.rs:103-106` (per P13.AGG13-10 fix). Local `--language` wins when both set.
- **P21** — `--include-within-file`: 0 clones in this scope (no intra-file duplication in 4 small Provider files).
- **P22** — `--show-classes`: adds an extra field for transitive clone grouping (NOT visible when 0 clones).
- **P23** — `--max-clones 1`: when there are 0 clones in scope, no truncation effect visible. Would cap the array at 1 if there were more.
- **P24** — `--max-files 1`: limits files analyzed. Default 1000 (`MAX_FILES` per source).
- **P25** — `--exclude-tests --exclude-generated`: no effect in this scope (no test/generated files in `backend/providers/`).
- **P26** — Legacy `-o sarif` (the local `--output` flag): produces SARIF output, identical to `-f sarif`. **`-o sarif` and `-f sarif` are both honored — but `-o` accepts only json/text/sarif/dot, while `-f` (global) accepts json/text/compact/sarif/dot.** Compact is NOT in `-o`'s value set.
- **P27** — `-q` suppresses the `"Detecting clones in <path>..."` progress message.

---

## Source Code Reality

**Target file(s):**
- `crates/tldr-cli/src/commands/clones.rs` (185 lines)
- `crates/tldr-core/src/analysis/clones.rs` (`detect_clones`, `ClonesOptions`, `CloneType`, `NormalizationMode`)
- `crates/tldr-cli/src/output.rs:113` (`validate_format_for_command`)
- `crates/tldr-cli/src/output.rs` (`format_clones_dot`, `format_clones_sarif`, `format_clones_text`)

**Pinned to upstream commit:** `6c4011a` (release v0.4.0)

**Argument struct:**
```rust
// crates/tldr-cli/src/commands/clones.rs:19-77
#[derive(Debug, Args)]
pub struct ClonesArgs {
    #[arg(default_value = ".")] pub path: PathBuf,
    #[arg(long, default_value = "25")] pub min_tokens: usize,
    #[arg(long, default_value = "5")] pub min_lines: usize,
    #[arg(short = 't', long, default_value = "0.7")] pub threshold: f64,
    #[arg(long, default_value = "all")] pub type_filter: String,
    #[arg(long, default_value = "all")] pub normalize: String,
    #[arg(long = "language")] pub language: Option<String>,
    #[arg(short, long, default_value = "json")] pub output: String,
    #[arg(long)] pub show_classes: bool,
    #[arg(long)] pub include_within_file: bool,
    #[arg(long, default_value = "20")] pub max_clones: usize,
    #[arg(long, default_value = "1000")] pub max_files: usize,
    #[arg(long)] pub exclude_generated: bool,
    #[arg(long)] pub exclude_tests: bool,
}
```
Reveals: `type_filter`, `normalize`, `language` are all `String` (NOT typed enums) — bad values silently fall back to defaults (P15, P17). `--output` (`-o`) is a separate local format flag from the global `-f`.

**Silent type_filter fallback (P15 root cause):**
```rust
// clones.rs:171-179
fn parse_type_filter(s: &str) -> Option<CloneType> {
    match s {
        "1" => Some(CloneType::Type1),
        "2" => Some(CloneType::Type2),
        "3" => Some(CloneType::Type3),
        "all" | "" => None,
        _ => None,  // ← unknown values silently fall through to None = all types
    }
}
```
Reveals: any unrecognized string for `--type-filter` returns None, which means "filter to nothing in particular" = include all types. **No error for typos.**

**Silent normalize fallback:**
```rust
// clones.rs:91-92
let normalization =
    NormalizationMode::parse(&self.normalize).unwrap_or(NormalizationMode::All);
```
Reveals: `NormalizationMode::parse` returns Option; `unwrap_or(All)` silently defaults bad values. P17 confirms.

**Global `-l/--lang` is honored (P13.AGG13-10 fix):**
```rust
// clones.rs:103-106
let effective_language = self
    .language
    .clone()
    .or_else(|| global_lang.map(|l| l.as_str().to_string()));
```
Reveals: local `--language` wins; falls back to global `-l/--lang`. This is the P13.AGG13-10 fix mentioned in the source — pre-fix the global `-l` was silently ignored, scanning ALL languages on a multi-language repo.

**Format dispatch — supports json/text/compact/sarif/dot:**
```rust
// clones.rs:126-164 (excerpt)
match effective_format {
    OutputFormat::Text => writer.write_text(&format_clones_text(&report))?,
    OutputFormat::Sarif => writer.write_text(&format_clones_sarif(&report))?,
    OutputFormat::Dot => writer.write_text(&format_clones_dot(&report))?,  // P2.BUG-6 fix
    _ => writer.write(&report)?,
}
```
Reveals: explicit Dot arm added per `schema-cleanup-v2 P2.BUG-6` — pre-fix, `--format dot` fell through to JSON (silent format mis-match because the per-command DOT validator advertised clones as DOT-supported but the dispatch didn't actually route to the DOT emitter).

**Silent bad-path (P04 root cause):**
The CLI does NOT validate `self.path.exists()` upfront. `detect_clones` (in `tldr-core`) walks the path; a non-existent path simply finds 0 files. **No error propagates.** This is the only CLI command in this audit that silently accepts bad paths.

**Format validation:** confirmed at `crates/tldr-cli/src/output.rs:113-163` — `clones` is in BOTH `SARIF_SUPPORTED` and `DOT_SUPPORTED`.

**No daemon route:** `grep -n try_daemon_route clones.rs` returns 0 matches. Detection is O(N²) over the file set; daemon caching wouldn't help much for one-shot scans.

---

## Architectural Deep Dive

- **Under the hood:** Token-based clone detection. (1) Tokenize each source file via tree-sitter. (2) Apply `--normalize` (rename identifiers/literals to placeholders for Type-2/3 detection). (3) Find pairwise token sub-sequence matches above `--threshold`. (4) Classify as Type-1 (exact), Type-2 (identifier rename), or Type-3 (gapped/parameterized).
- **Performance:** O(N²) over files × O(M) tokens per file. Bound by `--max-files` (default 1000). On Stock-Monitor `backend/providers/` (4 files): ~1s; on full `backend/` (56 files): >30s. **Always scope to the smallest meaningful subdir.**
- **LLM cognitive load:** Surfaces duplicate code that grep can't catch (different identifiers, different literal values). Use `--threshold 0.5` to discover non-obvious clones; `--type-filter 1` for exact dupes only; SARIF output for CI integration.

---

## Intent & Routing

- **User/Agent Goal:** find duplicate or near-duplicate code fragments — refactoring candidates, copy-paste tech debt, security implications (vulnerable code propagated via copy-paste).
- **When to choose this over similar tools:**
  - Over `tldr dice <T1> <T2>`: `dice` compares two specific targets; `clones` scans the project for ALL pairs.
  - Over `tldr similar <FILE>`: `similar` is semantic embedding-based (one source, many candidates); `clones` is syntactic token-based (all-vs-all). Different precision tradeoffs.
  - Over `git diff`: clones works on arbitrary files (no git history needed) and finds cross-file duplication.
- **Prerequisites (composition):**
  - Scope to subdirectories to avoid O(N²) explosion on large codebases.
  - For known languages, pass `-l <lang>` to skip non-matching files (P19/P20).
  - Verify `files_analyzed > 0` to detect silent path failures (P04 returns empty result for non-existent paths).

---

## Agent Synthesis

> **How to use `tldr clones`:**
> Token-based clone detector. `tldr clones [PATH]` returns JSON `{ root, language, clone_pairs, stats, config, total_clones, files_analyzed, summary }`. Each `ClonePair` has `id`, `clone_type` (Type-1/Type-2/Type-3), `similarity`, two `Fragment`s with previews, and a human `interpretation`. Default JSON; `-f text` for minimal summary; `-f compact` for one-line; `-f sarif` for CI integration (SARIF 2.1.0); `-f dot` for graph visualization. Exit codes: 0 ok **including silent empty for non-existent paths**, 2 bad `-f`/`--lang` clap rejection. Detection is O(N²); always scope to subdirectories.
>
> **Crucial Rules:**
> - **Bad paths return exit 0, NOT exit 1.** P04: `tldr clones /no/such/dir` silently returns valid JSON with `files_analyzed: 0`. There is NO upfront path validation in clones.rs — `detect_clones` simply finds 0 files. **Agents must inspect `files_analyzed > 0`** to distinguish "scanned successfully but found nothing" from "path didn't exist."
> - **`--type-filter wat` and `--normalize wat` silently fall back to defaults.** `type_filter` is `String` (not typed enum); unknown values map to "all" via `parse_type_filter` (P15). `normalize` similarly falls back to `All` via `unwrap_or` (P17). Spell carefully: `--type-filter` accepts `1 | 2 | 3 | all`; `--normalize` accepts `none | identifiers | literals | all`.
> - **`--language` (local) wins over `-l/--lang` (global).** Both are supported; the local flag takes precedence (per P13.AGG13-10 fix). The fix is critical because pre-v0.4 the global `-l` was silently ignored, causing multi-language scans on what users expected to be language-scoped.
> - **Top-level fields are TRIPLE-MIRRORED.** `stats.clones_found == total_clones == summary.total_clones`. Same for `files_analyzed`. Use any path; both `jq '.total_clones'` and `jq '.stats.clones_found'` work.
> - **clones IS in both SARIF_SUPPORTED and DOT_SUPPORTED.** P08: `-f sarif` produces valid SARIF 2.1.0; P09: `-f dot` produces `digraph clones { ... }`. The DOT path was wired up per `schema-cleanup-v2 P2.BUG-6`; pre-fix it silently fell through to JSON.
> - **O(N²) — always scope to subdirs.** On Stock-Monitor `backend/providers/` (4 files) runs in ~1s; on full `backend/` (56 files) exceeds 30s. Default `--max-files 1000` is a safety net but not a performance fix. Use `--max-files 100` for fast scans on large codebases.
> - **`--threshold` is the dominant control knob.** Default 0.7 misses many Type-3 candidates; `--threshold 0.5` finds more; `--threshold 0.0` finds every pair (P11 finds C(N,2) pairs).
> - **The `-o` (local) and `-f` (global) format flags have different value sets.** `-o` accepts `json | text | sarif | dot` (NOT compact); `-f` accepts `json | text | compact | sarif | dot`. Use `-f` for the broader set.
> - **DOT output is empty when 0 clones** — just the `digraph clones { rankdir=LR; ... }` wrapper. Not a "graph of nodes I might cluster" — it's exclusively clone-pair edges.
> - **NO daemon route.** Every call re-tokenizes and re-pairs. `tldr warm` is a no-op for this command.
>
> **Command:** `tldr clones [PATH]`
>
> **With common flags:** `tldr clones <DIR> -l <lang> --threshold 0.5 --max-files 100 --exclude-tests --exclude-generated -f sarif > clones.sarif` (use for CI-friendly scanning of a single-language subdir, generating SARIF for code-scanning integration).
