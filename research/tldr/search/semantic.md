# Command: `tldr semantic`

## Environment Pin

| Field | Value |
|---|---|
| `tldr --version` | 0.4.0 |
| Build features | `semantic` (verified via runtime probe on 2026-05-21 — FastEmbed + arctic-m loaded) |
| Target repo | Stock-Monitor @ commit `e601869` |
| Upstream `tldr-code` pinned to | `6c4011a` (release v0.4.0, 2026-05-11) |
| Daemon state at probe time | N/A — `semantic` does not use the daemon route (it has its own on-disk embedding cache) |
| OS | darwin 25.2.0 |
| Probe date | 2026-05-22 |

Re-run all evidence via [`semantic.probes/probe.sh`](./semantic.probes/probe.sh).

---

## Ground Truth (`tldr semantic --help`)

```text
Semantic code search using natural language

Usage: tldr semantic [OPTIONS] <QUERY> [PATH]

Arguments:
  <QUERY>
          Natural language query

  [PATH]
          Path to search (default: current directory)
          
          [default: .]

Options:
  -n, --top <TOP>
          Maximum number of results
          
          [default: 10]

  -t, --threshold <THRESHOLD>
          Minimum similarity threshold (0.0 to 1.0)
          
          [default: 0.5]

  -m, --model <MODEL>
          Embedding model: arctic-xs, arctic-s, arctic-m, arctic-m-long, arctic-l
          
          [default: arctic-m]

      --langs <LANGS>
          Filter by language via file extensions (comma-separated, e.g., `--langs rs,py`).
          
          Values are parsed by `Language::from_extension`, which accepts file extensions such as `rs`, `py`, `ts`, `go`, `java`, `rb`, `kt`, `cpp`. Language names (`rust`, `python`) are NOT accepted here; use the global `--lang <LANG>` flag above for name-based single-language selection. Passing an unknown extension silently drops that entry from the filter.
          
          Renamed from `--lang` (pre-VAL-009) to avoid a clap TypeId collision with the global `--lang` arg which is `Option<Language>`.

      --no-cache
          Disable embedding cache

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
| Formats that work | `json`, `text`, `compact` (P01, P06, P16) |
| Formats that error | `sarif`, `dot` (P05: exit 1) |
| Typical output size | small-medium (~1–5KB) for default `-n 10` cap; first invocation on a path also writes progress text to stderr while building the index |

**Top-level keys (JSON):**
- `results` (`array<ResultCard>`) — ranked matches, length ≤ `--top`
- `total_results` (`int`) — number of cards returned
- `query` (`string`) — echoed query
- `model` (`string`) — actual model name used (e.g., `"arctic-m"`, `"arctic-x-s"`)
- `total_chunks` (`int`) — number of function chunks in the built index. **Critical agent signal:** `0` means the index built nothing — usually `--langs` dropped everything.
- `matches_above_threshold` (`int`) — count *before* `-n` cap; can be larger than `total_results`
- `latency_ms` (`int`) — search-time latency only (not index-build time)
- `cache_hit` (`bool`) — index-level cache status

**`results[]` card shape:**
- `file_path` (`string`) — repo-relative path
- `function_name` (`string \| null`) — function name (e.g., `"_get_client"`)
- `class_name` (`string \| null`) — enclosing class if applicable (e.g., `"DhanProvider"`)
- `score` (`float`) — cosine similarity, range [0.0, 1.0]
- `line_start` (`int`), `line_end` (`int`) — function span
- `snippet` (`string`) — first ~5 lines of the function body (hardcoded in `semantic.rs:90` as `snippet_lines: 5`)

**`model` field canonicalization (P10):**
- Input `arctic-xs` → output `"arctic-x-s"` (snake-cased by the EmbeddingModel enum's Debug impl)
- Input `arctic-m` → output `"arctic-m"`
- The canonical strings to expect in the response are the snake-cased forms — agents parsing this field must accept both.

**Text format (P06):** Colored output with `Semantic search: "..."`, `Model: ArcticM | Threshold: 0.50 | Searched: N chunks` header, numbered result cards with file/class/function path + score + snippet, plus a trailing `Search completed in <N>ms`.

**Compact format (P16):** Single-line JSON, all whitespace stripped.

**Empty result examples:**
- High threshold (P08, `-t 0.8`): `{results: [], total_results: 0, total_chunks: 22, matches_above_threshold: 0, ...}` — chunks built, none passed threshold.
- Bad `--langs` filter (P13, P14): `{results: [], total_results: 0, total_chunks: 0, ...}` — **`total_chunks: 0` is the smoking gun** that the language filter silently dropped everything.

**Error shapes:**
- Missing `<QUERY>` (P03): clap error `error: the following required arguments were not provided: <QUERY>` with `Usage:` hint, exit `2`.
- Bad path (P04): stderr `Error: Path not found: <path>`, exit `2`. **Differs from `search` (exit 1) and `structure` (exit 1).** Source: `semantic.rs` has no upfront path-existence check (unlike `search.rs:80-83`); the error propagates from inside `SemanticIndex::build`.
- Invalid model (P11): `Error: Invalid model 'bogus-model'. Options: arctic-xs, arctic-s, arctic-m, arctic-m-long, arctic-l`, exit `1`. The full valid-options list is in the error message — agents can parse this for recovery.
- Format rejection (P05): standard validator error, exit `1`.

---

## Probe Matrix

Slug convention: `NN-<token>[-<modifier>]`. The audit script globs by ID, so modifiers are safe.

| # | Probe | Type | Exit | Captured |
|---|-------|------|------|----------|
| P01 | `tldr semantic "database connection" backend/providers` | happy | 0 | [`01-happy.*`](./semantic.probes/) |
| P02 | `tldr semantic "database connection" backend` | happy-scale | 0 | [`02-happy-scale.*`](./semantic.probes/) |
| P03 | `tldr semantic` *(no args)* | failure-missing-arg | 2 | [`03-missing-arg.*`](./semantic.probes/) |
| P04 | `tldr semantic "x" /no/such/path` | failure-badpath | 2 | [`04-badpath.*`](./semantic.probes/) |
| P05 | `tldr semantic "database" backend/providers -f sarif` | format-reject | 1 | [`05-format-reject-sarif.*`](./semantic.probes/) |
| P06 | `tldr semantic "database" backend/providers -f text` | format-text | 0 | [`06-format-text.*`](./semantic.probes/) |
| P07 | `tldr semantic "database" backend/providers -n 3` | flag-top-cap | 0 | [`07-top-3.*`](./semantic.probes/) |
| P08 | `tldr semantic "database" backend/providers -t 0.8` | flag-threshold-high | 0 | [`08-threshold-high.*`](./semantic.probes/) |
| P09 | `tldr semantic "database" backend/providers -t 0.1` | flag-threshold-low | 0 | [`09-threshold-low.*`](./semantic.probes/) |
| P10 | `tldr semantic "database" backend/providers -m arctic-xs` | flag-model-xs | 0 | [`10-model-xs.*`](./semantic.probes/) |
| P11 | `tldr semantic "database" backend/providers -m bogus-model` | failure-invalid-model | 1 | [`11-model-invalid.*`](./semantic.probes/) |
| P12 | `tldr semantic "database" backend/providers --langs py` | flag-langs-valid | 0 | [`12-langs-py.*`](./semantic.probes/) |
| P13 | `tldr semantic "database" backend/providers --langs python` | flag-langs-name-silent-drop | 0 | [`13-langs-name.*`](./semantic.probes/) |
| P14 | `tldr semantic "database" backend/providers --langs xyz` | flag-langs-unknown-silent-drop | 0 | [`14-langs-unknown.*`](./semantic.probes/) |
| P15 | `tldr semantic "database" backend/providers --no-cache` | flag-no-cache | 0 | [`15-no-cache.*`](./semantic.probes/) |
| P16 | `tldr semantic "database" backend/providers -f compact` | format-compact | 0 | [`16-format-compact.*`](./semantic.probes/) |
| P17 | `tldr semantic "lookup external trading symbol for an asset" backend/providers` | mode-conceptual-vocab-gap | 0 | [`17-conceptual.*`](./semantic.probes/) |

### Observations

- **P01 (small dir, 38 lines):** Built an index of `total_chunks: 22` for `backend/providers/` (4 files). `matches_above_threshold: 3` at default threshold 0.5. `cache_hit: false` (first build). Top result: `YahooProvider.__init__` (score 0.573), all results were `__init__` methods — semantic scoring tied "database connection" loosely to "initialize connection-like state."
- **P02 (realistic scale, 101 lines):** `total_chunks: 1397` for `backend/` — 56 Python files × ~25 functions/file. Default `-n 10` cap means the JSON contains exactly 10 cards regardless of how many matched. First build is multi-second; subsequent runs hit the embedding cache.
- **P03 (missing `<QUERY>`):** clap error with `Usage:` hint, exit `2`.
- **P04 (bad path):** stderr `Error: Path not found: <path>`, exit **`2`** — note this **differs from `search` and `structure` (both exit 1)**. Source: `semantic.rs` has no upfront path-existence guard, so the error originates inside the index builder and propagates with a different exit code.
- **P05 (sarif rejection):** standard validator error, exit `1`.
- **P06 (text format, 20 lines):** Colored ASCII output suitable for chat. Includes `Model:`, `Threshold:`, `Searched:` header; numbered result cards.
- **P07 (`-n 3`):** Returns 3 cards; `matches_above_threshold` would still report the full pre-cap count.
- **P08 (`-t 0.8`):** `results: []`, `matches_above_threshold: 0`. The threshold filters out everything. **`total_chunks: 22` confirms the index was built; nothing scored above 0.8.**
- **P09 (`-t 0.1`):** More results (capped at 10 by default `-n`). Low threshold accepts weakly-related matches.
- **P10 (`-m arctic-xs`):** Works. The response's `model` field reads **`"arctic-x-s"`** (note the canonicalization — the Debug impl of `EmbeddingModel::ArcticXS` produces `ArcticXS` which serializes lowercased with hyphens to `arctic-x-s`). Agents parsing this field must accept both `arctic-xs` (input form) and `arctic-x-s` (output form).
- **P11 (invalid model):** Exit `1` with stderr `Error: Invalid model 'bogus-model'. Options: arctic-xs, arctic-s, arctic-m, arctic-m-long, arctic-l`. **The error message embeds the full valid-options list** — agents can parse this for self-recovery.
- **P12 (`--langs py`, valid extension):** Works, `total_chunks: 22` (same as P01 — backend/providers is all .py).
- **P13 (`--langs python`, LANGUAGE NAME):** **Silent failure.** Exit `0`, `total_chunks: 0`, `results: []`. The language name `"python"` is not a valid extension per `Language::from_extension`, so it gets silently dropped. With no extensions accepted, the index builds nothing. **No warning is emitted** — agents must check `total_chunks` to detect this.
- **P14 (`--langs xyz`, unknown extension):** Same as P13 — `total_chunks: 0`. Silent drop confirmed.
- **P15 (`--no-cache`):** Behaves like P01 (`cache_hit: false`). The flag disables the on-disk embedding cache, forcing rebuild. Useful when you suspect cache corruption.
- **P16 (compact, 1 line / ~1.5KB):** Same content as P01-equivalent, all whitespace stripped.
- **P17 (conceptual query — vocabulary gap):** Query `"lookup external trading symbol for an asset"` matched the actual symbol-lookup functions even though no exact keywords overlap. **This is the use case `semantic` excels at over `search`**: the vocabulary gap (concept ≠ keyword) is bridged by embeddings.

---

## Source Code Reality

**Target file:** `crates/tldr-cli/src/commands/semantic.rs` (pinned to upstream commit `6c4011a`).

**Argument definition (`semantic.rs:18-67`):**
```rust
pub struct SemanticArgs {
    pub query: String,                                      // required
    #[arg(default_value = ".")]
    pub path: PathBuf,
    #[arg(short = 'n', long, default_value = "10")]
    pub top: usize,                                         // default 10
    #[arg(short = 't', long, default_value = "0.5")]
    pub threshold: f64,                                     // default 0.5
    #[arg(short, long, default_value = "arctic-m")]
    pub model: String,
    #[arg(long = "langs", value_delimiter = ',')]
    pub langs: Option<Vec<String>>,
    #[arg(long)]
    pub no_cache: bool,
}
```
Key shapes: `langs` is `Option<Vec<String>>` with comma-delimiter; `model` is a plain `String` (parsed at runtime via `parse_model`).

**`--langs` quirk explainer (`semantic.rs:46-60`, embedded as doc comment):**
```rust
/// Filter by language via file extensions (comma-separated, e.g., `--langs rs,py`).
///
/// Values are parsed by `Language::from_extension`, which accepts file
/// extensions such as `rs`, `py`, `ts`, `go`, `java`, `rb`, `kt`, `cpp`.
/// Language names (`rust`, `python`) are NOT accepted here; use the
/// global `--lang <LANG>` flag above for name-based single-language
/// selection. Passing an unknown extension silently drops that entry
/// from the filter.
///
/// Renamed from `--lang` (pre-VAL-009) to avoid a clap TypeId collision
/// with the global `--lang` arg which is `Option<Language>`.
```
**P13 and P14 empirically verify this.** When all extensions are unknown/dropped, the resulting `BuildOptions.languages: Some([])` filters out every source file → `total_chunks: 0`.

**No path validation upfront.** Unlike `structure.rs`, `search.rs`, `semantic.rs` does NOT have an `if !self.path.exists()` guard. The error originates inside `SemanticIndex::build` and exits with code **2** (different from `anyhow::bail!`'s exit 1 used by `structure`/`search`).

**Model parsing (`semantic.rs:128-141`):**
```rust
fn parse_model(model_str: &str) -> Result<EmbeddingModel> {
    match model_str {
        "arctic-xs" | "xs" => Ok(EmbeddingModel::ArcticXS),
        "arctic-s" | "s" => Ok(EmbeddingModel::ArcticS),
        "arctic-m" | "m" => Ok(EmbeddingModel::ArcticM),
        "arctic-m-long" | "m-long" => Ok(EmbeddingModel::ArcticMLong),
        "arctic-l" | "l" => Ok(EmbeddingModel::ArcticL),
        _ => Err(anyhow::anyhow!(
            "Invalid model '{}'. Options: arctic-xs, arctic-s, arctic-m, arctic-m-long, arctic-l",
            model_str
        )),
    }
}
```
**Reveals:** model strings accept BOTH `arctic-xs` and just `xs` (short alias). The list is closed — anything else errors with the full options list embedded in the message.

**No daemon route.** `semantic.rs` does not call `try_daemon_route`. It has its own caching system via `CacheConfig::default()`, which is on by default and disabled by `--no-cache`. The `cache_hit` field in the output reports index-level cache status; the embedding cache works at the chunk level and is not directly visible in the response.

**Hardcoded values in `semantic.rs:79,89-93`:**
```rust
let build_opts = BuildOptions {
    granularity: ChunkGranularity::Function,    // hardcoded
    ...
};
let search_opts = IndexSearchOptions {
    top_k: self.top,
    threshold: self.threshold,
    include_snippet: true,                       // hardcoded
    snippet_lines: 5,                            // hardcoded
};
```
**Reveals:** chunk granularity is always `Function` (cannot search by class, file, or block). Snippet preview is hardcoded to 5 lines.

**Format validator** confirmed at `crates/tldr-cli/src/output.rs::validate_format_for_command` — `semantic` is in neither `SARIF_SUPPORTED` nor `DOT_SUPPORTED`.

---

## Architectural Deep Dive

- **Engine:** FastEmbed local embedding models (Arctic family from Snowflake). Index built per invocation: every function in the target path becomes one chunk; chunks are embedded; query is embedded; cosine similarity ranks results above `--threshold`, top `--top` returned.
- **Chunk granularity is hardcoded to Function.** No class-level or file-level search mode.
- **Cache architecture:** **Two distinct caches.** (1) On-disk embedding cache (`CacheConfig::default()`) — persists per-chunk embeddings; survives across invocations; toggleable via `--no-cache`. (2) The `cache_hit` field in the response is index-level (did we find a previously-built full index for this path), separate from the embedding cache.
- **No daemon involvement.** Independent of `tldr daemon`. Even with a warm daemon, semantic still rebuilds its index.
- **First-invocation cost is high.** For Stock-Monitor's `backend/` (1397 chunks), the first index build takes seconds-to-minutes. Subsequent searches on the same path are sub-second.
- **`--langs` is fragile.** Per source comments: only file extensions are accepted (`py`, `rs`, `ts`, ...); language names (`python`, `rust`) are silently dropped. Empirically verified (P13, P14): unknown values → 0 chunks indexed → empty results, no error.
- **LLM cognitive load:** Bridges the vocabulary gap. When the agent knows the *concept* (`"billing logic"`, `"network retry"`, `"asset symbol lookup"`) but not the exact identifier, `semantic` finds the relevant function. `search` (BM25) would fail when the identifier diverges from natural-language terms.

---

## Intent & Routing

- **User/Agent Goal:** Find functions by *meaning*, not by keyword. Use when you don't know the exact variable/function names but can describe what you want in natural language.
- **When to choose this over similar tools:**
  - Use *over* `tldr search` when query terms unlikely to appear literally in code (e.g., `"payment retry logic"` when the code uses `TransactionProcessor.with_backoff`).
  - Use *with* `--langs <ext>` to scope to a specific language in mixed-language repos — and remember it's **extensions only**, not language names.
  - Use *before* `tldr extract` / `tldr impact` to find the entry point, then use those for deeper analysis.
- **Prerequisites:** None. (Note: `tldr-cli` must be built with the `semantic` cargo feature — verified on this machine.)
- **Composes well with:**
  - `tldr semantic "concept" <dir> -n 3` → pick a function → `tldr extract <file>` for full context.
  - `tldr semantic "<concept>" <dir>` → grab `file_path` + `line_start`/`line_end` → `tldr slice <file> <function> <line>` for data flow.

---

## Agent Synthesis

> **How to use `tldr semantic`:**
> Use when the agent knows the *concept* but not the exact identifier. Embeddings bridge the gap between natural language and code — `"payment retry logic"` will find `TransactionProcessor.with_backoff` even if neither word matches the other lexically. Default model `arctic-m`; default threshold 0.5; default top-10. Chunk granularity is hardcoded to function-level — no class/file/block search mode.
>
> **Crucial Rules:**
> - **`<QUERY>` is REQUIRED** — passing no args produces a clap error (exit 2).
> - **Bad path exits `2`** here (unlike `search`/`structure` which exit `1`). Three distinct exit codes total: `1` (format reject, invalid model), `2` (missing query, bad path), `0` (success — including empty results).
> - **`--langs` takes EXTENSIONS, not language names.** `--langs py,rs` works; `--langs python` is silently dropped. Verify the response's `total_chunks` field: if it's `0` after passing `--langs`, the filter dropped everything. **No warning is emitted** — this is the most dangerous silent failure of the command.
> - **Always check `total_chunks` in the response.** If `0`, the language filter (`--langs`) or the path matched no source files. Don't assume "no results" means "no matches" — it could mean "no index."
> - **`matches_above_threshold` ≠ `total_results`.** The former is the count *before* the `-n` cap; the latter is the count *after*. Use `matches_above_threshold` to gauge how much you're missing.
> - **Model name in response is canonicalized.** `arctic-xs` becomes `"arctic-x-s"` in the `model` output field. Agents parsing this must accept both forms.
> - **Invalid model error embeds the full options list** — `Error: Invalid model '<bad>'. Options: arctic-xs, arctic-s, arctic-m, arctic-m-long, arctic-l`. Agents can grep this for valid options on recovery.
> - **Threshold tuning:** default 0.5 is a reasonable starting point; raise to 0.7+ for high-precision queries, lower to 0.3 to surface weakly-related code. Threshold 0.8+ often yields zero matches on small repos.
> - **First invocation builds the embedding index** — slow (seconds-to-minutes for large repos). Subsequent calls hit the on-disk cache and are sub-second. `--no-cache` forces rebuild (use when you suspect stale cache).
> - **No daemon involvement** — `tldr daemon start` / `tldr warm` do nothing for `semantic`. The on-disk embedding cache is independent.
> - **`-f sarif` and `-f dot` are rejected** (exit 1).
>
> **Commands:**
> - Default semantic search: `tldr semantic "<concept>" <dir>`
> - Scoped to language: `tldr semantic "<concept>" <dir> --langs py` (extensions only!)
> - High-precision: `tldr semantic "<concept>" <dir> -t 0.7`
> - More results: `tldr semantic "<concept>" <dir> -n 20`
> - Smaller/faster model: `tldr semantic "<concept>" <dir> -m arctic-xs`
> - Force cache rebuild: `tldr semantic "<concept>" <dir> --no-cache`
