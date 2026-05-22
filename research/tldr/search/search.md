# Command: `tldr search`

## Environment Pin

| Field | Value |
|---|---|
| `tldr --version` | 0.4.0 |
| Build features | `semantic` (verified via runtime probe on 2026-05-21) |
| Target repo | Stock-Monitor @ commit `e601869` |
| Upstream `tldr-code` pinned to | `6c4011a` (release v0.4.0, 2026-05-11) |
| Daemon state at probe time | N/A — `search` does not use the daemon route |
| OS | darwin 25.2.0 |
| Probe date | 2026-05-22 |

Re-run all evidence via [`search.probes/probe.sh`](./search.probes/probe.sh).
See also: [agent-oriented tool card](../../tool-cards/search/search.md).

---

## Ground Truth (`tldr search --help`)

```text
Enriched search with function-level context cards (BM25 + structure + call graph)

Usage: tldr search [OPTIONS] <QUERY> [PATH]

Arguments:
  <QUERY>
          Search query (natural language or code terms; BM25 by default, regex when `--regex` is set)

  [PATH]
          Directory to search in (default: current directory)
          
          [default: .]

Options:
  -l, --lang <LANG>
          Programming language (auto-detect if not specified)

  -k, --top-k <TOP_K>
          Maximum number of result cards to return
          
          [default: 10]

      --no-callgraph
          Skip call graph enrichment (much faster, no callers/callees)

      --regex
          Use regex pattern matching instead of BM25 ranking. The query is interpreted as a regex pattern

      --hybrid <HYBRID>
          Hybrid mode: combine BM25 relevance with regex filtering. The positional query is used for BM25 ranking, this pattern for regex filtering

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
| Formats that work | `json`, `text`, `compact` (P01, P06, P14) |
| Formats that error | `sarif`, `dot` (P05: exit 1) |
| Typical output size | medium (1–50KB) for ≤10 cards (default `-k 10`); scales linearly with `--top-k` |

**Top-level keys (JSON):**
- `query` (`string`) — the query as passed
- `results` (`array<ResultCard>`) — ranked matches, length ≤ `--top-k`
- `total_results` (`int`) — number of cards returned (≤ top-k)
- `total_files_searched` (`int`) — how many files were considered for the BM25 index
- `search_mode` (`string`) — **observable signal of the actual mode used** (see modes table below)

**`results[]` card shape:**
- `name` (`string`) — function/method/class name
- `kind` (`string`) — `"function"`, `"method"`, `"class"`
- `file` (`string`) — repo-relative file path
- `line_range` (`[int, int]`) — start and end line numbers
- `signature` (`string`) — the source signature (e.g., `def foo(x: int) -> dict:`)
- `callers` (`array<string>`) — function names that call this (intra-file; omitted when `--no-callgraph`)
- `callees` (`array<string>`) — function names this calls (intra-file; omitted when `--no-callgraph`)
- `score` (`float`) — BM25 score (or regex match score)
- `matched_terms` (`array<string>`) — which query tokens matched
- `preview` (`string`) — short multi-line snippet showing matched lines

**`search_mode` values observed:**
| Trigger | Value |
|---|---|
| Default | `"bm25+structure+callgraph"` |
| `--no-callgraph` | `"bm25+structure"` |
| `--regex` | `"regex+structure+callgraph"` |
| `--hybrid <pattern>` | `"hybrid(bm25+regex)+structure+callgraph"` |
| All query tokens are stopwords (`fn`, `def`, `function`, `class`) | `"literal-fallback+structure+callgraph"` |

> **`search_mode` is the agent's self-check.** If you searched for `"def"` expecting BM25 ranking and got `literal-fallback`, you now know the engine fell back — and you can re-query with a more specific term.

**Text format (P06):** Numbered cards with file/line/score header and callers/callees lines. Includes a multi-line preview per card.

**Compact format (P14):** Single-line JSON, all whitespace stripped.

**Empty result (P13):** Exit 0. JSON: `{query, results: [], total_results: 0, total_files_searched: <N>, search_mode: "..."}`.

**Error shapes:**
- Missing `<QUERY>` (P03): clap error `error: the following required arguments were not provided: <QUERY>` with `Usage:` hint, exit `2`.
- Bad path (P04): `Error: Path not found: <path>`, exit `1`. Source: `search.rs:80-83`, uses `anyhow::bail!`. **Note:** matches `structure` (exit 1), differs from `extract` (exit 2).
- `--regex` + `--hybrid` together (P11): clap error `error: the argument '--regex' cannot be used with '--hybrid <HYBRID>'`, exit `2`. Enforced via clap `conflicts_with` in `search.rs:57,62`.
- Format rejection (P05): standard validator error, exit `1`.

---

## Probe Matrix

Slug convention: `NN-<token>[-<modifier>]`. The audit script globs by ID, so modifiers are safe.

| # | Probe | Type | Exit | Captured |
|---|-------|------|------|----------|
| P01 | `tldr search "database" backend` | happy | 0 | [`01-happy.*`](./search.probes/) |
| P02 | `tldr search "database" .` | happy-scale | 0 | [`02-happy-scale.*`](./search.probes/) |
| P03 | `tldr search` *(no args)* | failure-missing-arg | 2 | [`03-missing-arg.*`](./search.probes/) |
| P04 | `tldr search "database" /no/such/path` | failure-badpath | 1 | [`04-badpath.*`](./search.probes/) |
| P05 | `tldr search "database" backend -f sarif` | format-reject | 1 | [`05-format-reject-sarif.*`](./search.probes/) |
| P06 | `tldr search "database" backend -f text` | format-text | 0 | [`06-format-text.*`](./search.probes/) |
| P07 | `tldr search "database" backend -k 3` | flag-top-k-cap | 0 | [`07-top-k-3.*`](./search.probes/) |
| P08 | `tldr search "database" backend --no-callgraph` | flag-no-callgraph | 0 | [`08-no-callgraph.*`](./search.probes/) |
| P09 | `tldr search "ensure_.*_table" backend --regex` | mode-regex | 0 | [`09-regex.*`](./search.probes/) |
| P10 | `tldr search "database connection" backend --hybrid ".*sqlite.*"` | mode-hybrid | 0 | [`10-hybrid.*`](./search.probes/) |
| P11 | `tldr search "x" backend --regex --hybrid "y"` | flag-conflict | 2 | [`11-conflict-regex-hybrid.*`](./search.probes/) |
| P12 | `tldr search "def" backend` | mode-stopword-fallback | 0 | [`12-all-stopwords.*`](./search.probes/) |
| P13 | `tldr search "zzzqqqxxxnotapresent" backend` | boundary-zero-results | 0 | [`13-zero-results.*`](./search.probes/) |
| P14 | `tldr search "database" backend -f compact` | format-compact | 0 | [`14-format-compact.*`](./search.probes/) |

### Observations

- **P01 (small dir):** 10 result cards (default `-k 10`), `total_files_searched: 56` (Stock-Monitor's `backend/` has 56 Python files), `search_mode: "bm25+structure+callgraph"`. Cards include BM25 scores ranging from ~6.2 down to ~1.6.
- **P02 (full repo, ZERO RESULTS):** `total_files_searched: 627` but `results: []`. **The auto-detected language at repo root was likely JavaScript** (Stock-Monitor's `webui/` has hundreds of `.js` files vs `backend/`'s ~56 `.py` files). The BM25 index was built only for JS files; Python's "database"-rich code was never indexed. **Critical agent constraint:** on multi-language repos, pass `-l <lang>` explicitly or scope `<PATH>` to one language's subdirectory.
- **P03 (missing `<QUERY>`):** clap-level error with `Usage:` hint, exit `2`. **Recovery hint:** the query is the *first* positional, path is the *second*.
- **P04 (bad path):** stderr `Error: Path not found: <path>`, exit `1`. Source: `search.rs:80-83` uses `anyhow::bail!`. Path is validated before language detection.
- **P05 (sarif rejection):** standard validator error, exit `1`.
- **P06 (text format, 96 lines):** Numbered card format with `1. fn <name> (<file>:<start>-<end>) [<score>]` headers. The first card includes a generated **fragment view** of nearby matched functions in the same file — useful for chat output.
- **P07 (`-k 3`, 69 lines):** Cap respected — 3 cards instead of 10.
- **P08 (`--no-callgraph`, 178 lines):** `search_mode` becomes `"bm25+structure"` (no `+callgraph`). Cards omit `callers`/`callees` keys. Faster for large repos where callgraph enrichment is the bottleneck.
- **P09 (`--regex`):** Query `"ensure_.*_table"` matched a different set of functions than BM25 would. `search_mode: "regex+structure+callgraph"`. Note: the first card was `lifespan` in `api.py` — the regex matches text *anywhere in the file*, not just function names.
- **P10 (`--hybrid` BM25 + regex filter):** Both signals combined. `search_mode: "hybrid(bm25+regex)+structure+callgraph"`. Useful when you want BM25 relevance ranking but only over results matching a regex (e.g., function names matching a pattern).
- **P11 (`--regex` + `--hybrid` conflict):** clap rejects — `error: the argument '--regex' cannot be used with '--hybrid <HYBRID>'`, exit `2`. Enforced declaratively via clap's `conflicts_with`.
- **P12 (all-stopwords `"def"`):** Exit 0, returns 10 results, `search_mode: "literal-fallback+structure+callgraph"`. **Confirms the source-stated stopword-fallback path.** BM25 would have filtered all tokens and returned nothing; the literal substring search saves the query.
- **P13 (zero results, gibberish query):** Exit 0, `results: []`, `total_results: 0`, `total_files_searched: 56`, `search_mode: "bm25+structure+callgraph"`. **Empty is not an error** — agents should branch on `total_results` rather than exit code.
- **P14 (compact, 1 line / ~5KB):** Same content as P01, all whitespace stripped.

---

## Source Code Reality

**Target file:** `crates/tldr-cli/src/commands/search.rs` (pinned to upstream commit `6c4011a`).

**Argument definition (`search.rs:30-66`):**
```rust
pub struct SmartSearchArgs {
    pub query: String,                    // required
    #[arg(default_value = ".")]
    pub path: PathBuf,                    // optional, defaults to .
    #[arg(long, short = 'l')]
    pub lang: Option<Language>,
    #[arg(long, short = 'k', default_value = "10")]
    pub top_k: usize,                     // default 10
    #[arg(long)]
    pub no_callgraph: bool,
    #[arg(long, conflicts_with = "hybrid")]
    pub regex: bool,
    #[arg(long, conflicts_with = "regex")]
    pub hybrid: Option<String>,
}
```
**Critical:** `<QUERY>` is required (no default). `--regex` and `--hybrid` are declaratively mutually exclusive via clap `conflicts_with` — verified at P11.

**Stopword fallback comment (`search.rs:17-26`):**
```rust
/// ux-and-explain-completeness-v1 (P12.AGG12-13): when EVERY query
/// token is filtered (e.g. `fn new`, `function`, `def `), the command
/// transparently falls back to literal substring search so the query
/// still returns useful results. The report's `search_mode` field is
/// then `literal-fallback+structure` (or `+callgraph`).
```
**Reveals exactly what P12 captured.** Stopwords filtered: `fn`, `def`, `function`, `class`. If the query consists *only* of these, BM25 would return nothing — the literal-fallback path runs a substring search instead.

**Path validation (`search.rs:80-83`):**
```rust
// Validate path exists BEFORE language detection / progress banner
if !self.path.exists() {
    anyhow::bail!("Path not found: {}", self.path.display());
}
```
Same pattern as `structure.rs`. Explains P04's exit 1.

**Language defaulting cascade (`search.rs:85-88`):**
```rust
let language = self
    .lang
    .unwrap_or_else(|| Language::from_directory(&self.path).unwrap_or(Language::Python));
```
**Critical hidden constraint:** identical cascade to `structure`. `from_directory` picks the **dominant** language by file count. On Stock-Monitor's `.` root, JS dominates → BM25 indexes only JS files → Python `database` code never searched. This explains P02's zero-result mystery.

**Search mode dispatch (`search.rs:97-107`):**
```rust
let search_mode = if self.regex {
    SearchMode::Regex(self.query.clone())
} else if let Some(ref pattern) = self.hybrid {
    SearchMode::Hybrid { query: ..., pattern: ... }
} else {
    SearchMode::Bm25
};
```
The fourth mode — `LiteralFallback` — is decided inside `enriched_search` at runtime when stopword filtering empties the BM25 token list.

**No daemon route.** Unlike `tree`/`structure`/`extract`/`impact`, `search.rs` does not call `try_daemon_route`. Every invocation rebuilds the BM25 index for the target directory + language. **Implication:** repeated searches on the same directory pay the index-build cost each time. (This is why daemon cold/warm probes were omitted from the matrix.)

**Format validator** confirmed at `crates/tldr-cli/src/output.rs::validate_format_for_command` — `search` is in neither `SARIF_SUPPORTED` nor `DOT_SUPPORTED`.

---

## Architectural Deep Dive

- **Engine:** BM25 ranking over a per-language tree-sitter-extracted token index, plus structure + call-graph enrichment per result card. Two alternate modes: pure regex pattern matching; hybrid BM25 ranking gated by a regex filter.
- **Index lifecycle:** Built fresh on every invocation (no daemon caching). Stopwords (`fn`, `def`, `function`, `class`) filtered from queries. Empty post-filter queries fall back to literal substring search.
- **Language scoping:** **Single-language per invocation.** Auto-detection picks the dominant language by file count in `<PATH>`. To search multiple languages, run the command once per language with `-l <lang>`.
- **LLM cognitive load:** Replaces `grep -rn "<term>" .` with structured cards that bundle function signature, file/line range, callers, callees, and a preview snippet — agents get the information needed for a follow-up `tldr impact`/`tldr slice` call without an extra `cat`/`extract` round-trip.

---

## Intent & Routing

- **User/Agent Goal:** Locate functions by token relevance, regex pattern, or hybrid signal — with enough context (callers/callees/preview) to decide which result to drill into next.
- **When to choose this over similar tools:**
  - Use *instead of* `grep -rn` when you want ranked, function-level results with callers/callees.
  - Use *over* `tldr semantic` when query terms are likely to appear literally in code. `semantic` is better when concept ≠ keyword.
  - Use *with* `--regex` when you need exact pattern matching (e.g., `"def ensure_.*_table"`).
  - Use *with* `--hybrid` when you want BM25 ranking restricted to results matching a structural pattern.
- **Prerequisites:** None.
- **Composes well with:**
  - `tldr search "term" -k 3` → pick the right function → `tldr impact <function-name>` to assess blast radius.
  - `tldr search` → grab `file` + `line_range` from a card → `tldr slice <file> <function> <line>` for data flow.

---

## Agent Synthesis

> **How to use `tldr search`:**
> Use to find functions by token relevance with rich context — each result card includes signature, callers, callees, and a code preview, so the agent rarely needs a follow-up `tldr extract`. Default ranking is BM25 over a per-language token index built fresh on every call (no daemon cache).
>
> **Crucial Rules:**
> - **`<QUERY>` is REQUIRED** — passing no args produces a clap error (exit 2). Order is `query` then `path`: `tldr search "<query>" <path>`.
> - **Single-language scoping.** Auto-detection picks the dominant language by file count under `<PATH>`. On multi-language repos this is the biggest footgun: searching Stock-Monitor's root returns ZERO results for `"database"` because JS files dominate over Python (P02). **Either pass `-l <lang>` explicitly OR scope `<PATH>` to one language's subdirectory.**
> - **Three exit codes:** `1` = bad path or format reject; `2` = missing query or conflicting flags. Empty results are exit 0 — branch on `total_results`, not exit code.
> - **Always check the `search_mode` field in the response.** It tells you which mode actually ran. `literal-fallback+...` means your query was all stopwords (`def`, `fn`, `function`, `class`) and the engine substring-searched instead of BM25-ranking — usually a sign to re-query with a more specific term.
> - **Stopwords filtered from BM25:** `fn`, `def`, `function`, `class`. Don't include them; they add no signal.
> - **`--regex` matches text anywhere in the indexed file content**, not just function names. To target names specifically, prefix with the language's keyword: `"def my_func.*"`.
> - **`--regex` and `--hybrid` are mutually exclusive** (clap-enforced, exit 2 if both passed).
> - **`--no-callgraph` is the speed flag** — drops `callers`/`callees` from each card; useful when you only need to locate functions, not understand their relationships.
> - **No daemon caching.** Repeated searches on the same directory pay the index-build cost each time. For exploratory loops, prefer one search with high `-k` over many searches.
> - **`-f sarif` and `-f dot` are rejected** (exit 1).
>
> **Commands:**
> - Default BM25 search: `tldr search "<query>" <dir>`
> - Scoped + small cap: `tldr search "<query>" <dir> -k 3`
> - Fast (no callgraph): `tldr search "<query>" <dir> --no-callgraph`
> - Regex pattern: `tldr search "<regex>" <dir> --regex`
> - Hybrid (rank by BM25, filter by regex): `tldr search "<bm25-terms>" <dir> --hybrid "<regex>"`
> - Multi-language repo: `tldr search "<query>" <dir> -l python` (or scope to subdir)
