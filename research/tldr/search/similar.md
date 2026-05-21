# Command: `tldr similar`

## Environment Pin

| Field | Value |
|---|---|
| `tldr --version` | 0.4.0 |
| Build features | `semantic` (required — `similar` is semantic-only) |
| Target repo | Stock-Monitor @ commit `e601869` |
| Upstream `tldr-code` pinned to | local clone @ `6c4011a` (release v0.4.0) |
| Daemon state at probe time | N/A — `tldr similar` does **not** call `try_daemon_route`. Uses its own `CacheConfig` for embedding cache (verified by grep) |
| Scoping | All probes run against `backend/providers/` (4 files, 22 chunks). Full-repo semantic index is too slow for probe iteration |
| OS | darwin 25.2.0 |
| Probe date | 2026-05-22 |

Re-run all evidence via [`similar.probes/probe.sh`](./similar.probes/probe.sh).

---

## Ground Truth (`tldr similar --help`)

```text
Find similar code fragments

Usage: tldr similar [OPTIONS] <FILE>

Arguments:
  <FILE>
          Source file to find similar code for

Options:
  -F, --function <FUNCTION>
          Specific function name (optional, searches whole file if not specified)

  -n, --top <TOP>
          Maximum number of results

          [default: 5]

  -t, --threshold <THRESHOLD>
          Minimum similarity threshold

          [default: 0.7]

  -p, --path <PATH>
          Path to search for similar code (default: current directory)

          [default: .]

  -m, --model <MODEL>
          Embedding model: arctic-xs, arctic-s, arctic-m, arctic-m-long, arctic-l

          [default: arctic-m]

      --include-self
          Include self in results (by default, the query is excluded)

      --no-cache
          Disable embedding cache

      --by-chunk
          M16 (med-cleanup-bundle-v1): emit one row per matching chunk (legacy behavior). The default — when no `--function` is given and the target is a whole file — aggregates chunk matches per destination file and ranks by total similarity, since per-chunk scoring on a 600-LOC file made the user wade through 5 unrelated 4-9 line helpers

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
| Typical output size | small (<1 KB aggregated; medium ~5 KB per-chunk) |

**Default (aggregated) shape — `AggregatedSimilarityReport`** (no `--function`, no `--by-chunk`):
- `source_file` (`string`, absolute path) — the canonicalized FILE path
- `source_chunks` (`usize`) — number of chunks the indexer extracted from the source file
- `model` (`string`) — embedding model name (`"arctic-m"`, etc.)
- `similar_files` (`array<FileSimilarityResult>`) — destination files ranked by `total_score` descending, truncated to `--top`
- `total_compared_chunks` (`usize`) — total (src_chunk × dest_chunk) pairs evaluated

**`FileSimilarityResult` shape:**
- `file_path` (`string`, absolute)
- `total_score` (`float64`) — sum of best-per-source-chunk scores against this destination
- `matched_chunks` (`usize`) — how many source chunks contributed
- `avg_score` (`float64`) — `total_score / matched_chunks`

**Per-chunk shape — `SimilarityReport`** (`--by-chunk` OR `--function`):
- `source` (`ChunkInfo`) — the query chunk: `{ file_path, function_name, class_name, line_start, line_end, content, content_hash, language }`
- `similar` (`array<ChunkInfo + score>`) — matching chunks ranked by score, truncated to `--top`
- `model`, `total_compared`, `exclude_self` — metadata

**Empty result (aggregated, P10 threshold 0.99):**
```json
{
  "source_file": "...",
  "source_chunks": 7,
  "model": "arctic-m",
  "similar_files": [],
  "total_compared_chunks": 105
}
```
Exit 0 — empty `similar_files` is a normal "above-threshold matches: 0" response.

**Error shapes (all stderr; build banner on stderr first, then "Error:" line):**
- Missing FILE: clap-style `"error: the following required arguments were not provided: <FILE> …"` → exit **2**
- Source file not in index (aggregated path): `"Error: no indexed chunks found for source file: <abs path>"` → exit **1**
- Source chunk not in index (per-chunk path): `"Error: Chunk not found: <abs path>::<func>"` → exit **54** (TldrError::ChunkNotFound)
- Bad model: `"Error: Invalid model 'X'. Options: arctic-xs, arctic-s, arctic-m, arctic-m-long, arctic-l"` → exit **1** (anyhow!)
- Format reject: `"Error: --format sarif not supported by similar. Use --format json. SARIF is only emitted by: vuln, clones."` → exit **1**

---

## Probe Matrix

| # | Probe | Type | Exit | Captured |
|---|-------|------|------|----------|
| P01 | `tldr similar base.py -p <ABS>/backend/providers` | happy (aggregated) | 0 | [`01-happy.*`](./similar.probes/) |
| P02 | `tldr similar yahoo.py -p <ABS>/backend/providers` | happy-scale | 0 | [`02-happy-scale.*`](./similar.probes/) |
| P03 | `tldr similar` *(no FILE)* | failure-missing-input | 2 | [`03-missing-arg.*`](./similar.probes/) |
| P04 | `tldr similar /no/such/file.py -p ...` | failure-badpath | 1 | [`04-badpath.*`](./similar.probes/) |
| P05 | `tldr similar ... -f sarif` | format-reject | 1 | [`05-format-reject-sarif.*`](./similar.probes/) |
| P06 | `tldr similar ... -f text` | format-text (aggregated) | 0 | [`06-format-text.*`](./similar.probes/) |
| P07 | `tldr similar ... -f compact` | format-compact | 0 | [`07-format-compact.*`](./similar.probes/) |
| P08 | `tldr similar ... -f dot` | format-reject-dot | 1 | [`08-format-reject-dot.*`](./similar.probes/) |
| P09 | `tldr similar ... -t 0.0` | threshold-zero | 0 | [`09-threshold-zero.*`](./similar.probes/) |
| P10 | `tldr similar ... -t 0.99` | threshold-high (empty) | 0 | [`10-threshold-high.*`](./similar.probes/) |
| P11 | `tldr similar ... -n 1` | top-one | 0 | [`11-top-one.*`](./similar.probes/) |
| P12 | `tldr similar ... -n 50` | top-fifty | 0 | [`12-top-fifty.*`](./similar.probes/) |
| P13 | `tldr similar ... --by-chunk` | per-chunk-mode (silent first-chunk pick) | 0 | [`13-by-chunk.*`](./similar.probes/) |
| P14 | `tldr similar yahoo.py -F fetch_historical_data ...` | function-mode | 0 | [`14-function.*`](./similar.probes/) |
| P15 | `tldr similar ... -F HistoricalDataProvider` | function-missing (class name) | 54 | [`15-function-missing.*`](./similar.probes/) |
| P16 | `tldr similar ... --include-self` | include-self (dead flag) | 0 | [`16-include-self.*`](./similar.probes/) |
| P17 | `tldr similar ... -m fake-model` | bad-model | 1 | [`17-bad-model.*`](./similar.probes/) |
| P18 | `tldr similar ... -m arctic-xs` | smaller-model | 0 | [`18-model-xs.*`](./similar.probes/) |
| P19 | `tldr similar ... --no-cache` | no-cache | 0 | [`19-no-cache.*`](./similar.probes/) |
| P20 | `tldr similar ... -q` | quiet | 0 | [`20-quiet.*`](./similar.probes/) |
| P21 | `tldr similar backend/db.py -p <ABS>/backend/providers` | file-outside-scope | 1 | [`21-file-outside-scope.*`](./similar.probes/) |
| P22 | `tldr similar base.py -p backend/providers` *(RELATIVE -p)* | **relative-path bug** | 1 | [`22-relative-path-bug.*`](./similar.probes/) |

### Observations

- **P01** — `base.py` query within absolute-pathed `backend/providers/` scope finds 2 destination files: `yahoo.py` (avg 0.839) and `dhan.py` (avg 0.839). `source_chunks: 7`, `total_compared_chunks: 105` (7 src × 15 candidate dest chunks, minus same-file). Self-file (base.py) excluded.
- **P02** — `yahoo.py` query: similar shape, slightly different scoring (yahoo's chunks differ from base's abstract methods).
- **P03** — stderr `"error: the following required arguments were not provided: <FILE>"`, exit `2`. `SimilarArgs.file` is `PathBuf` (required).
- **P04** — stderr (after build banner) `"Error: no indexed chunks found for source file: /no/such/file.py"`, exit `1`. The file doesn't exist on disk, but the smart-path logic doesn't catch it; the index is built without the file's chunks, and aggregation fails on the source-chunks-empty check (`similar.rs:214-219`). Cross-command divergence: most commands return path-not-found errors; here it's "no indexed chunks found".
- **P05** — stderr `"Error: --format sarif not supported by similar. Use --format json. SARIF is only emitted by: vuln, clones."`, exit `1`. **Order note:** the build banner ("Building index for N chunks...") is printed BEFORE format validation fires for this command, so users see partial progress before the format rejection.
- **P06** — Text format renders `Finding files similar to: <green path> (N source chunks)` header, model row, then numbered destination files with `total / avg / chunks` columns. Aggregated-shape text formatter (`format_aggregated_similar_text`).
- **P07** — Single-line minified JSON, aggregated schema.
- **P08** — stderr `"Error: --format dot not supported by similar. Use --format json. DOT is only emitted by: clones, deps, calls, impact, hubs, inheritance."`, exit `1`.
- **P09** — `-t 0.0` returns all candidates (still capped at `--top 5`). Same destinations as P01 because the scope only has 3 files anyway.
- **P10** — `-t 0.99` returns `similar_files: []`. Exit 0 — empty is a typed success result, not an error. `total_compared_chunks: 105` is still set, so callers can tell "compared but nothing matched" from "nothing was indexed".
- **P11** — `-n 1` keeps only the top destination file (yahoo.py with the highest score). Truncation happens AFTER scoring, so it's the highest-ranked single result.
- **P12** — `-n 50` includes everything (only 2 destination files match the source's scope, so no truncation effect). Confirms top-N is upper-bounded, not lower-bounded.
- **P13** — `--by-chunk` on a whole-file query routes through `index.find_similar(file_str, None, opts)` — but the per-chunk path requires ONE source chunk. The engine **silently picks the first chunk** of the source file (in this case, `HistoricalDataProvider.fetch_historical_data` at line 19). Users expecting "all chunks vs all chunks" get a one-chunk query. Hidden behavior.
- **P14** — `-F fetch_historical_data` on yahoo.py returns per-chunk shape `{ source: {…fetch_historical_data details…}, similar: [{…DhanProvider.fetch_historical_data, score: 0.87…}, …] }`. The `source` block includes the FULL function content as a string field (`content`) — large files yield large output.
- **P15** — stderr `"Error: Chunk not found: <abs>/base.py::HistoricalDataProvider"`, exit `54`. `HistoricalDataProvider` is a **class** name, not a function; the index keys by function name only (chunk granularity is `Function`). **Recovery hint:** the `--function` flag accepts function names, not class names; method-of-class works if you use the method name directly. Exit 54 is unique — `TldrError::ChunkNotFound::exit_code() = 54` (`tldr-core/src/error.rs:354`).
- **P16** — `--include-self` produces output **identical** to P01 (base.py NOT included in `similar_files`). The flag is declared at `similar.rs:43-45` but **never read elsewhere in the file**. Source-comment drift: `--help` claims "Include self in results"; the implementation always excludes. **Dead flag.**
- **P17** — stderr `"Error: Invalid model 'fake-model'. Options: arctic-xs, arctic-s, arctic-m, arctic-m-long, arctic-l"`, exit `1`. `parse_model` (`similar.rs:328-340`) rejects unknown values via `anyhow!`.
- **P18** — `arctic-xs` produces a different scoring distribution but the same shape. The model name appears in `report.model`.
- **P19** — `--no-cache` disables embedding cache. Output identical to P01 because cache hit/miss doesn't change scores, only timing.
- **P20** — `-q` suppresses stderr progress (the "Building index..." and "Searching..." messages). Stdout JSON unaffected.
- **P21** — File outside the `-p` scope: stderr `"Error: no indexed chunks found for source file: /Users/.../backend/db.py"`, exit `1`. The index was built only over `backend/providers/`, so db.py has zero chunks. Same error shape as P04 (truly non-existent file).
- **P22** — **Relative `-p` bug:** `tldr similar backend/providers/base.py -p backend/providers` (relative path arg) fails with `"Error: no indexed chunks found for source file: /Users/.../backend/providers/base.py"`, exit `1`. The semantic index stores chunk paths in a form that does NOT match the source's canonicalized absolute path. **Workaround:** pass `-p` as an absolute path, OR omit `-p` entirely (the smart-path logic at `similar.rs:79-87` only kicks in when `-p` is the literal default `"."`).

---

## Source Code Reality

**Target file(s):**
- `crates/tldr-cli/src/commands/similar.rs` (409 lines)
- `crates/tldr-core/src/semantic/index.rs` (`SemanticIndex`, `find_similar`)
- `crates/tldr-core/src/semantic/types.rs:298, 353` (`SimilarityReport`, `IndexSearchOptions`)
- `crates/tldr-core/src/error.rs:314-358` (TldrError exit-code mapping, ChunkNotFound→54)
- `crates/tldr-cli/src/output.rs:113` (`validate_format_for_command`)

**Pinned to upstream commit:** `6c4011a` (release v0.4.0)

**Argument struct:**
```rust
// crates/tldr-cli/src/commands/similar.rs:18-59
#[derive(Debug, Args)]
pub struct SimilarArgs {
    pub file: PathBuf,
    #[arg(short = 'F', long)] pub function: Option<String>,
    #[arg(short = 'n', long, default_value = "5")] pub top: usize,
    #[arg(short = 't', long, default_value = "0.7")] pub threshold: f64,
    #[arg(short, long, default_value = ".")] pub path: PathBuf,
    #[arg(short, long, default_value = "arctic-m")] pub model: String,
    #[arg(long)] pub include_self: bool,
    #[arg(long)] pub no_cache: bool,
    #[arg(long)] pub by_chunk: bool,
}
```
Reveals: `--function` short is `-F` (uppercase, unusual). `--model` is `String` (not clap-typed) — bad values rejected at runtime via `parse_model`. `--include-self` is declared but unused downstream (see Dead Flag below).

**Smart-path logic (the P22 bug context):**
```rust
// similar.rs:76-87
let canonical_file = self.file.canonicalize().unwrap_or_else(|_| self.file.clone());
let file_str = canonical_file.display().to_string();
let effective_path =
    if self.path == std::path::Path::new(".") && canonical_file.is_absolute() {
        canonical_file.parent().map(|p| p.to_path_buf()).unwrap_or_else(|| self.path.clone())
    } else {
        self.path.clone()
    };
```
Reveals: the smart-path "use the file's parent dir" optimization ONLY fires when `self.path == "."` (the literal default) AND the file is absolute. If the user supplies a relative `-p` value (`backend/providers`), the index is built over that relative root, but `file_str` is the canonical absolute path. The aggregation filter (`similar.rs:208-212`) compares the chunk's stored `file_path` to `file_str`; if the index stores relative paths and `file_str` is absolute, they never match → empty source chunks → "no indexed chunks found" (P22).

**Default aggregation gate:**
```rust
// similar.rs:136
if self.function.is_none() && !self.by_chunk {
    let report = aggregate_similar_by_file(...);
    ...
    return Ok(());
}
// Otherwise legacy per-chunk path:
let report = index.find_similar(&file_str, self.function.as_deref(), &search_opts)?;
```
Reveals: routing decision is `(--function set) OR (--by-chunk set) → per-chunk; else → aggregated`. The default behavior changed in M16 (cleanup-bundle-v1) precisely because per-chunk on a 600-LOC file returned 5 unrelated 4-9 line helpers.

**`--include-self` is a dead flag:**
```bash
$ grep -n "include_self\|exclude_self" similar.rs
45:    pub include_self: bool,        # declared
368:        report.exclude_self        # only used to DISPLAY in text formatter
```
Reveals: `include_self` is on the args struct but never consulted when constructing `IndexSearchOptions` or in the aggregation path. The semantic index's `find_similar` hardcodes `exclude_self: true` (`semantic/index.rs:537`), and the aggregation explicitly skips matching the source's own file (`similar.rs:228-231`). The flag has no observable effect (P16 vs P01 byte-identical results).

**Source chunk lookup for aggregation:**
```rust
// similar.rs:208-219
let source_chunks: Vec<&EmbeddedChunk> = index
    .chunks()
    .iter()
    .filter(|c| c.chunk.file_path.to_string_lossy() == file_str)
    .collect();
if source_chunks.is_empty() {
    return Err(anyhow::anyhow!(
        "no indexed chunks found for source file: {}",
        file_str
    ));
}
```
Reveals: the filter is **string equality** between the chunk's stored path and the user's canonicalized path. P22's relative-`-p` bug is here — paths don't match → empty filter → error.

**Per-chunk path uses ChunkNotFound (P15 root cause):**
The CLI delegates to `index.find_similar(&file_str, self.function.as_deref(), &search_opts)`. The index keys chunks by `(file_path, function_name)` where `function_name` is the symbol name extracted at chunk-granularity = Function. Class names are NOT chunk keys, so `--function <ClassName>` yields `TldrError::ChunkNotFound` (exit 54).

**Bad-model rejection:**
```rust
// similar.rs:328-340
fn parse_model(model_str: &str) -> Result<EmbeddingModel> {
    match model_str { ... _ => Err(anyhow::anyhow!("Invalid model '{}'. Options: ...", model_str)) }
}
```
Reveals: runtime rejection via `anyhow!`, exit 1. No clap-level typing; aliases (`xs`, `s`, `m`, `m-long`, `l`) supported.

**Format validation:** confirmed at `crates/tldr-cli/src/output.rs:113-163` — `similar` is in neither `SARIF_SUPPORTED` nor `DOT_SUPPORTED`.

**No daemon route:** `grep -n try_daemon_route similar.rs` returns 0 matches. The semantic stack has its own embedding cache (`CacheConfig`), independent of the daemon.

---

## Architectural Deep Dive

- **Under the hood:** Three-stage pipeline. (1) Build `SemanticIndex` over `--path` with chunk granularity = Function; index uses tree-sitter + arctic-* embeddings. (2) Find source chunks: either filter by file_path (aggregated) or look up `(file, function)` directly (per-chunk). (3) Score candidates via cosine similarity; aggregate or rank per-chunk; truncate to `--top`.
- **Performance:** Embedding cache lives on disk (per `CacheConfig::default`). With cache hit, index build is ~600ms for 22 chunks; with `--no-cache`, expect re-embedding which is much slower. The actual cosine-similarity loop is fast (microseconds per pair). NO daemon route — every call re-builds the index from cache or scratch.
- **LLM cognitive load:** This is the **semantic counterpart of `tldr dice`** — `dice` does syntactic token-set comparison; `similar` does meaning-level embedding comparison. Use `similar` to find "this function probably does the same thing" candidates across the codebase (different identifiers, different syntax, similar intent).

---

## Intent & Routing

- **User/Agent Goal:** "find code that does what this function does." Useful for: refactoring opportunities (consolidate near-duplicates), API discovery (find an existing helper before writing your own), security review (find clone families that share a bug).
- **When to choose this over similar tools:**
  - Over `tldr dice`: `dice` compares two specific targets syntactically; `similar` searches the whole project semantically. Use `dice` when you have a candidate pair; use `similar` when you need to discover candidates.
  - Over `tldr clones`: `clones` enumerates clone families project-wide via token-set hashing; `similar` is a one-source-many-candidates semantic search. Different unit of inquiry.
  - Over `tldr search` (substring): `similar` is semantic, not lexical. Find "compute average" even when the code says `mean()`.
- **Prerequisites (composition):**
  - **Pass `-p` as an absolute path** (or omit it). Relative `-p` values trigger the P22 bug and return "no indexed chunks found" with exit 1.
  - For function-level queries, supply a function NAME (not a class name) via `-F`. Method names work; class names produce ChunkNotFound (exit 54).
  - To benefit from the embedding cache, do NOT pass `--no-cache` between invocations.

---

## Agent Synthesis

> **How to use `tldr similar`:**
> Semantic similarity finder. `tldr similar <FILE> [-p PATH]` indexes PATH at function-granularity, then finds files/functions whose embeddings are closest to the source. **Default behavior aggregates per destination file** (M16 cleanup): each destination gets one row with `total_score`/`avg_score`/`matched_chunks`. Use `--function NAME` to search for similar instances of a specific function, OR `--by-chunk` to keep the legacy per-chunk view. Default threshold is 0.7; default top-N is 5; default model is `arctic-m`. Exit codes: 0 ok (including empty similar_files above threshold), 1 path-not-found / source-not-indexed / bad-model / format-reject, 2 clap missing-arg, 54 chunk-not-found (per-chunk path with bad function name).
>
> **Crucial Rules:**
> - **Relative `-p <PATH>` is broken — pass an absolute path.** With a relative `-p`, the index stores chunk paths in a form that does NOT match the canonicalized source file path; every query returns `"Error: no indexed chunks found for source file: <abs path>"` exit 1. The smart-path logic at `similar.rs:79-87` only kicks in when `-p` is the literal default `"."` (in which case it uses the source file's parent dir). **Fix:** use `-p "$(pwd)/backend/providers"` or omit `-p` entirely.
> - **`--include-self` is a DEAD flag.** Declared at `similar.rs:45` but never propagated to `IndexSearchOptions` or to the aggregation logic. The semantic index hardcodes `exclude_self: true` (`semantic/index.rs:537`) and aggregation explicitly skips same-file chunks (`similar.rs:228-231`). P16 produces output byte-identical to P01.
> - **`--function <name>` accepts function names ONLY, not class names.** The index keys chunks by `(file, function_name)` where chunk granularity is `Function`. `--function HistoricalDataProvider` (a class) returns exit 54 with `"Error: Chunk not found: <abs>/base.py::HistoricalDataProvider"` (P15). Use method names directly.
> - **`--by-chunk` without `--function` silently picks the FIRST chunk** of the source file as the query anchor (P13). Users expecting all-chunks-vs-all-chunks get a one-chunk query. Explicit `--function` is the safer per-chunk invocation.
> - **Two distinct exit codes for "missing source"**: aggregated path returns exit 1 (`anyhow!("no indexed chunks found")`), per-chunk path returns exit 54 (`TldrError::ChunkNotFound`). Both indicate the source isn't in the index but route through different code paths.
> - **No daemon route — `tldr warm` does nothing.** The semantic engine has its own on-disk embedding cache via `CacheConfig`. The cache persists across invocations and IS effective (P01 reports `"All chunks cached - skipping embedder initialization"`). `--no-cache` bypasses it.
> - **The `source` block in per-chunk output (`--function` / `--by-chunk`) contains the FULL function content as a string.** Large files yield large output — use `-f compact` and `jq` to extract only the score/file rows when piping to another tool.
> - **Empty `similar_files` with `total_compared_chunks > 0` means "matched nothing above threshold."** Distinguish from empty + `total_compared_chunks == 0` (nothing was indexed under PATH at all). P10 vs hypothetical empty-scope.
>
> **Command:** `tldr similar <FILE>` *(uses smart path: defaults `-p` to the file's parent dir when file is absolute)*
>
> **With common flags:** `tldr similar <FILE> -p $(pwd)/<DIR> -F <func_name> -n 10 -t 0.6 -f compact` (use when iterating on a specific function and want extra candidates below the conservative default threshold).
