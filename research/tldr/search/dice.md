# Command: `tldr dice`

## Environment Pin

| Field | Value |
|---|---|
| `tldr --version` | 0.4.0 |
| Build features | `semantic` (verified; dice itself is non-semantic) |
| Target repo | Stock-Monitor @ commit `e601869` |
| Upstream `tldr-code` pinned to | local clone @ `6c4011a` (release v0.4.0) |
| Daemon state at probe time | N/A — `tldr dice` does **not** call `try_daemon_route` (verified by grep) |
| OS | darwin 25.2.0 |
| Probe date | 2026-05-22 |

Re-run all evidence via [`dice.probes/probe.sh`](./dice.probes/probe.sh).

---

## Ground Truth (`tldr dice --help`)

```text
Compare similarity between two code fragments

Usage: tldr dice [OPTIONS] <TARGET1> <TARGET2>

Arguments:
  <TARGET1>
          First target: file, file::function, or file:start:end

  <TARGET2>
          Second target: file, file::function, or file:start:end

Options:
      --normalize <NORMALIZE>
          Normalization mode: none, identifiers, literals, all (default: all)

          [default: all]

      --language <LANGUAGE>
          Language hint (auto-detected if not specified)

  -o, --output <OUTPUT>
          Output format: json, text (default: json)

          [default: json]

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
| Formats that work | `json`, `text` (via `-f` OR `-o`), `compact` (P01, P06, P07, P17) |
| Formats that error | `sarif`, `dot` (P05, P08: exit 1) |
| Typical output size | small (<300 bytes JSON; 7 lines text) |

**Top-level keys (JSON, `DiceSimilarityReport`):**
- `target1` (`string`) — input target spec verbatim
- `target2` (`string`) — input target spec verbatim
- `dice_coefficient` (`float64`, 0.0–1.0) — `2 × |T1 ∩ T2| / (|T1| + |T2|)` over normalized token multisets
- `interpretation` (`string`) — human-readable bucket: `"Near-identical (exact or trivial differences)"`, `"Very high similarity (Type-1/2 clone)"`, `"Moderate similarity (Type-3 clone candidate)"`, …
- `tokens1_count` (`usize`) — token count in fragment 1 AFTER normalization
- `tokens2_count` (`usize`) — token count in fragment 2 AFTER normalization

**Text format (`-f text` OR `-o text`):**
```text
Similarity Comparison
=====================

Target 1: <spec> (N tokens)
Target 2: <spec> (M tokens)

Dice coefficient: XX.XX%
Interpretation: <bucket>
```

**Empty-block "ghost similarity" (P16):**
```json
{
  "target1": "backend/providers/yahoo.py:99999:99999",
  "target2": "backend/providers/base.py:99999:99999",
  "dice_coefficient": 1.0,
  "interpretation": "Near-identical (exact or trivial differences)",
  "tokens1_count": 0,
  "tokens2_count": 0
}
```
**Two empty blocks return dice 1.0** — false-positive "near-identical" output. The Dice formula on `(0+0)` denominator presumably short-circuits to 1.0. Agents must check `tokens1_count > 0 && tokens2_count > 0` before trusting the score.

**Error shapes (all stderr):**
- Missing TARGET2: clap-style `"error: the following required arguments were not provided: <TARGET2> …"` → exit **2**
- File read failure: `"Error: Failed to read /no/such/file.py: No such file or directory (os error 2)"` → exit **1** (anyhow!)
- Tokenization failure on block: `"Error: Failed to tokenize target1: File has parse errors, skipping tokenization"` → exit **1** (a block whose surrounding context tree-sitter can't parse)
- Format reject: `"Error: --format sarif not supported by dice. Use --format json. SARIF is only emitted by: vuln, clones."` → exit **1**

---

## Probe Matrix

| # | Probe | Type | Exit | Captured |
|---|-------|------|------|----------|
| P01 | `tldr dice <F> <F>` *(same file twice)* | happy | 0 | [`01-happy.*`](./dice.probes/) |
| P02 | `tldr dice yahoo.py dhan.py` | happy-scale | 0 | [`02-happy-scale.*`](./dice.probes/) |
| P03 | `tldr dice <F>` *(no TARGET2)* | failure-missing-input | 2 | [`03-missing-arg.*`](./dice.probes/) |
| P04 | `tldr dice /no/such/file.py <F>` | failure-badpath | 1 | [`04-badpath.*`](./dice.probes/) |
| P05 | `tldr dice ... -f sarif` | format-reject | 1 | [`05-format-reject-sarif.*`](./dice.probes/) |
| P06 | `tldr dice ... -f text` | format-text | 0 | [`06-format-text.*`](./dice.probes/) |
| P07 | `tldr dice ... -f compact` | format-compact | 0 | [`07-format-compact.*`](./dice.probes/) |
| P08 | `tldr dice ... -f dot` | format-reject-dot | 1 | [`08-format-reject-dot.*`](./dice.probes/) |
| P09 | `tldr dice ... --normalize none` | normalize-none | 0 | [`09-norm-none.*`](./dice.probes/) |
| P10 | `tldr dice ... --normalize identifiers` | normalize-idents | 0 | [`10-norm-identifiers.*`](./dice.probes/) |
| P11 | `tldr dice ... --normalize literals` | normalize-literals | 0 | [`11-norm-literals.*`](./dice.probes/) |
| P12 | `tldr dice ... --normalize wat` | normalize-bogus (silent fallback) | 0 | [`12-norm-bogus.*`](./dice.probes/) |
| P13 | `tldr dice ... --language python` | language-flag | 0 | [`13-language-flag.*`](./dice.probes/) |
| P14 | `tldr dice F1::func F2::func` | function-spec (DEAD — file-level) | 0 | [`14-function-spec.*`](./dice.probes/) |
| P15 | `tldr dice F1:38:80 F2:48:100` | block-range (parse failure) | 1 | [`15-block-range.*`](./dice.probes/) |
| P16 | `tldr dice F:99999:99999 F2:99999:99999` | block-out-of-range (ghost dice=1.0) | 0 | [`16-block-oor.*`](./dice.probes/) |
| P17 | `tldr dice ... -o text` | output-flag-text | 0 | [`17-output-text.*`](./dice.probes/) |
| P18 | `tldr dice ... -o text -f compact` | output-vs-format precedence | 0 | [`18-output-text-vs-format-compact.*`](./dice.probes/) |
| P19 | `tldr dice base.py package.json` | mixed-langs (missing file in our case) | 1 | [`19-mixed-langs.*`](./dice.probes/) |
| P20 | `tldr dice F:1:10 F:1:10` | same-block | 0 | [`20-same-block.*`](./dice.probes/) |
| P21 | `tldr dice ... -q` | quiet | 0 | [`21-quiet.*`](./dice.probes/) |

### Observations

- **P01** — Comparing a file with itself: `dice_coefficient: 1.0`, `tokens1_count == tokens2_count == 272`, `interpretation: "Near-identical (exact or trivial differences)"`. Sanity check passes.
- **P02** — `yahoo.py` vs `dhan.py` (sibling Provider implementations): `dice: 0.9032`, `tokens: 1106 vs 1208`, interpretation `"Very high similarity (Type-1/2 clone)"`. Both files implement the same `Provider` interface; the high similarity captures that.
- **P03** — stderr `"error: the following required arguments were not provided: <TARGET2>"`, exit `2`. `DiceArgs.target1` and `DiceArgs.target2` are both `String` (required).
- **P04** — stderr `"Error: Failed to read /no/such/file.py: No such file or directory (os error 2)"`, exit `1`. Uses `anyhow!` (`dice.rs:149`) — yet another path-error convention (cf. definition=5, importers=1, context=2). The OS error code is included verbatim in the message.
- **P05** — stderr `"Error: --format sarif not supported by dice. Use --format json. SARIF is only emitted by: vuln, clones."`, exit `1`.
- **P06** — Text format produces a 7-line plain-text block via `format_dice_text`. Progress message `"Comparing similarity between <T1> and <T2>..."` lands on stderr.
- **P07** — Single-line minified JSON, same six keys as P01.
- **P08** — stderr `"Error: --format dot not supported by dice. Use --format json. DOT is only emitted by: clones, deps, calls, impact, hubs, inheritance."`, exit `1`.
- **P09 / P10 / P11 / P12** — Normalization comparison on the same `yahoo.py` vs `dhan.py` pair:
  - `--normalize none` → dice **0.7087**
  - `--normalize identifiers` → dice **0.8634**
  - `--normalize literals` → dice **0.7476**
  - `--normalize all` (default) → dice **0.9032**
  - `--normalize wat` (bogus) → dice **0.9032** — **silently same as `all`** (confirmed: bogus value falls back to `NormalizationMode::All` per `dice.rs:79`). Token counts (1106 / 1208) are identical across all four modes — normalization RENAMES tokens (e.g., `IDENT_N`, `LITERAL_N`), it does not drop them.
- **P13** — Explicit `--language python` produces identical output to auto-detect on `.py` files. Auto-detect delegates to `Language::from_path` (`dice.rs:192-194`).
- **P14** — **Major silent failure mode:** `yahoo.py::fetch_historical_data` vs `dhan.py::fetch_historical_data` produces dice = 0.9032 — EXACTLY the same as P02 (whole-file comparison), with identical token counts. The function name in `file::function` syntax is parsed but **completely ignored** — the source comment at `dice.rs:156-166` says *"For now, return full file - function extraction requires more work / TODO: Extract function body using tree-sitter"*. Users believe they're comparing functions; they're actually comparing the entire files. **Source-comment drift between `--help` ("file::function" is documented) and behavior.**
- **P15** — stderr `"Error: Failed to tokenize target1: File has parse errors, skipping tokenization"`, exit `1`. A `file:38:80` block that contains incomplete code (e.g., open braces or partial statements) cannot be parsed by tree-sitter as a standalone fragment. **Recovery hint:** widen the block range to encompass complete syntactic units (function boundaries, class boundaries) — `tldr extract <file>` returns line ranges for valid units.
- **P16** — Two non-existent line ranges (lines 99999:99999) both produce `tokens_count: 0` and **`dice_coefficient: 1.0`**. The Dice formula on `(0 + 0)` denominator returns 1.0 by convention or short-circuit — a **false-positive "near-identical" output**. Agents must validate `tokens_count > 0` before interpreting the coefficient.
- **P17** — `-o text` (the legacy `--output text` flag) produces text format. Behavior identical to `-f text`.
- **P18** — `-o text -f compact`: text wins. The source `dice.rs:104-108` shows `effective_format = if self.output == "text" { Text } else { format }` — `--output text` overrides `--format` UNCONDITIONALLY. (`-o json` does NOT override — `format` wins when `--output` is "json" or anything else.)
- **P19** — Stock-Monitor doesn't have a top-level `package.json` (it's under `webui/`), so this probe failed with `"Failed to read package.json"` (exit 1) rather than exercising mixed-language tokenization. **Probe documentation:** to actually test mixed languages, use absolute paths to confirmed files.
- **P20** — `F:1:10` vs `F:1:10` (same block): dice 1.0, token counts equal, interpretation near-identical. Confirms block extraction works for valid ranges.
- **P21** — `-q` suppresses stderr progress; stdout JSON unaffected.

---

## Source Code Reality

**Target file(s):**
- `crates/tldr-cli/src/commands/dice.rs` (227 lines)
- `crates/tldr-core/src/analysis/normalize.rs` (`NormalizationMode`, `normalize_tokens`)
- `crates/tldr-core/src/analysis/dice.rs` (`compute_dice_similarity`, `interpret_similarity`)
- `crates/tldr-cli/src/output.rs:113` (`validate_format_for_command`)

**Pinned to upstream commit:** `6c4011a` (release v0.4.0)

**Argument struct:**
```rust
// crates/tldr-cli/src/commands/dice.rs:19-38
#[derive(Debug, Args)]
pub struct DiceArgs {
    pub target1: String,
    pub target2: String,
    #[arg(long, default_value = "all")]
    pub normalize: String,  // <-- String, not enum
    #[arg(long = "language")]
    pub language: Option<String>,  // <-- String, not Language
    #[arg(short, long, default_value = "json")]
    pub output: String,  // <-- legacy --output flag, separate from --format
}
```
Reveals:
- `target1`/`target2` are required `String` (not paths — parsed at runtime via `parse_target`).
- `normalize` is `String`, NOT a clap-typed enum. Bad values fall back via `NormalizationMode::parse(...).unwrap_or(NormalizationMode::All)` (`dice.rs:79`) — **silent fallback, no clap rejection**.
- `language` is `Option<String>`, NOT clap-typed `Option<Language>` — bypassing the strict enum check other commands use. Unknown values would be checked at `Language::from_path` time, not by clap.
- `--output` (`-o`) is a SEPARATE flag from the global `--format` (`-f`). Conflicting semantics, see P18.

**Target parser:**
```rust
// dice.rs:121-142
fn parse_target(s: &str) -> Result<Target> {
    if let Some((path, func)) = s.split_once("::") {
        return Ok(Target::Function(PathBuf::from(path), func.to_string()));
    }
    let parts: Vec<&str> = s.rsplitn(3, ':').collect();
    if parts.len() == 3 {
        if let (Ok(end), Ok(start)) = (parts[0].parse::<usize>(), parts[1].parse::<usize>()) {
            return Ok(Target::Block(PathBuf::from(parts[2]), start, end));
        }
    }
    Ok(Target::File(PathBuf::from(s)))
}
```
Reveals: `::` always wins over `:` for function-spec parsing. Block-range requires BOTH start AND end to parse as `usize`. Windows drive letters (`C:\foo.py`) are safe because `parts[0]` and `parts[1]` would be `py` and `\foo`, which fail `parse::<usize>()` → falls through to `Target::File`.

**Dead `file::function` support (P14 root cause):**
```rust
// dice.rs:156-166
Target::Function(path, _func_name) => {
    // For now, return full file - function extraction requires more work
    // TODO: Extract function body using tree-sitter
    let source = std::fs::read_to_string(path)
        .map_err(|e| anyhow!("Failed to read {}: {}", path.display(), e))?;
    let lang = lang_hint
        .map(String::from)
        .or_else(|| detect_language(path))
        .ok_or_else(|| anyhow!("Could not detect language"))?;
    Ok((source, lang))
}
```
Reveals: the `_func_name` binding is intentionally unused (note the leading underscore). The function returns the WHOLE file source. `--help` advertises `file::function` as a supported target form, but the implementation collapses it to `Target::File` semantics. **Source-comment drift.**

**`-o text` overrides `-f` (P18 root cause):**
```rust
// dice.rs:103-108
let effective_format = match self.output.as_str() {
    "text" => OutputFormat::Text,
    "json" => format,
    _ => format,
};
```
Reveals: only `--output text` is honored as an override; `--output json` (and any other value) defers to `--format`. So `-o text` is the ONLY value that does anything when used with `-f`.

**Format validation:** confirmed at `crates/tldr-cli/src/output.rs:113-163` — `dice` is in neither `SARIF_SUPPORTED` nor `DOT_SUPPORTED`. `--format sarif`/`--format dot` are rejected with exit 1.

**No daemon route:** `grep -n try_daemon_route dice.rs` returns 0 matches. Every call re-tokenizes both targets from disk. The tokenization uses tree-sitter — moderately expensive on large files.

---

## Architectural Deep Dive

- **Under the hood:** Per-target tokenization via `normalize_tokens(source, lang, mode)` (tree-sitter parse → token stream → optional rename pass → multiset). Dice coefficient computed via `compute_dice_similarity(multiset1, multiset2)`. `interpret_similarity(score)` buckets the float into a human label.
- **Performance:** O(parse+tokenize) per target. Two files of ~1000 LoC each take ~200ms cold. No caching; no daemon route.
- **LLM cognitive load:** Replaces "diff these two files and tell me if they're suspiciously similar." Useful for quick clone-detection between candidate refactor targets without setting up a full `tldr clones` index. The token-count fields give the agent a sanity check (large token-count delta + high dice = identical core logic with different formatting; small token-count + high dice = trivial near-duplicate).

---

## Intent & Routing

- **User/Agent Goal:** quickly score whether two source fragments are likely the same code (Type-1/2 clones), Type-3 candidates, or distinct.
- **When to choose this over similar tools:**
  - Over `tldr clones`: `clones` scans an entire project for clone families; `dice` is a one-shot two-target comparison. Use `dice` to confirm a suspicion; use `clones` to discover them.
  - Over `tldr similar`: `similar` likely uses semantic embeddings; `dice` uses syntactic token-set overlap. They answer different questions ("looks like" vs "behaves like").
  - Over `diff <(cat F1) <(cat F2)`: `diff` shows line-level changes; `dice` returns one number. Use `dice` for ranking; use `diff` for review.
- **Prerequisites (composition):**
  - For function-level comparison, **`file::function` does NOT work** (P14). Either compare entire files OR use line ranges from `tldr extract` (which emits function line bounds).
  - Block ranges must encompass complete syntactic units; partial blocks fail tokenization (P15).

---

## Agent Synthesis

> **How to use `tldr dice`:**
> Two-target syntactic similarity comparator. `tldr dice <TARGET1> <TARGET2>` returns a JSON `{ target1, target2, dice_coefficient, interpretation, tokens1_count, tokens2_count }`. Coefficient is in [0.0, 1.0]; `interpretation` buckets it into Type-1/2 clone / Type-3 candidate / Moderate / Low / Dissimilar. Targets accept three forms: bare file, `file:start:end` (line range), `file::function` (DOCUMENTED but broken — see Crucial Rules). Default normalization is `all` which renames identifiers and literals (highest similarity scores); use `--normalize none` for raw-token comparison. Exit codes: 0 ok, 1 file-read / tokenize / format-reject, 2 clap missing-arg.
>
> **Crucial Rules:**
> - **`file::function` is DEAD — it compares the whole file.** Both targets are loaded as full files even when `::function` is specified; `dice.rs:156-166` admits *"For now, return full file - function extraction requires more work / TODO"*. The `_func_name` is intentionally unused. **Fix:** use `file:start:end` block ranges from `tldr extract <FILE>` to compare specific functions (P14).
> - **Empty blocks (0 tokens vs 0 tokens) return `dice_coefficient: 1.0`** — a false-positive "near-identical" output. Validate `tokens1_count > 0 && tokens2_count > 0` before trusting the score. Out-of-range line numbers silently yield empty blocks (P16).
> - **`--normalize <bogus>` silently falls back to `all`** (`dice.rs:79`). No clap-level rejection because `normalize` is `String`, not a typed enum. Spell carefully: `none | identifiers | literals | all`.
> - **`--language` is also untyped (`Option<String>`).** Unlike most tldr commands which use clap-typed `Option<Language>`, `dice` accepts arbitrary strings. Invalid values fall through to `Language::from_path` at runtime.
> - **`-o text` overrides `-f compact`** (and `-f json`). The legacy `--output` flag has higher precedence than the global `--format` ONLY when `-o text` is set; `-o json` defers to `-f` (`dice.rs:103-108`). Conflicting flags are silently resolved in `-o text`'s favor (P18).
> - **Bad-path exit code is 1** (anyhow!). Cross-command divergence — definition/explain=5, importers=1, context=2, imports=2, dice=1. Five different conventions across the CLI.
> - **Block ranges must be complete syntactic units.** A `file:38:80` slice that ends mid-function or mid-block fails tokenization with `"File has parse errors, skipping tokenization"` (exit 1). Use `tldr extract <FILE>`'s reported `line_start`/`line_end` to ensure valid ranges (P15).
> - **Normalization renames tokens; does not drop them.** Token counts are identical across `none/identifiers/literals/all` modes for the same file pair — only the vocabulary changes. So a low dice score with high token counts means "different code"; a high dice score with mismatched token counts means "similar logic, different verbosity."
> - **No daemon route.** Every call re-tokenizes from disk; `tldr warm` does nothing.
>
> **Command:** `tldr dice <TARGET1> <TARGET2>`
>
> **With common flags:** `tldr dice <F1>:<L1>:<L2> <F2>:<L3>:<L4> --normalize none -f compact` (use for raw-token comparison of two line ranges; the safest way to compare two specific functions since `::function` is broken).
