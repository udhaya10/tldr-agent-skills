# Command: `tldr context`

## Environment Pin

| Field | Value |
|---|---|
| `tldr --version` | 0.4.0 |
| Build features | `semantic` |
| Target repo | Stock-Monitor @ commit `e601869` |
| Upstream `tldr-code` pinned to | local clone @ `6c4011a` (release v0.4.0) |
| Daemon state at probe time | mixed (probe.sh cycles cold→warm; P18 cold, P19/P20 warm) |
| OS | darwin 25.2.0 |
| Probe date | 2026-05-22 |

Re-run all evidence via [`context.probes/probe.sh`](./context.probes/probe.sh).

---

## Ground Truth (`tldr context --help`)

```text
Build LLM-ready context from entry point

Usage: tldr context [OPTIONS] <ENTRY> [PATH]

Arguments:
  <ENTRY>
          Entry point function name

  [PATH]
          Project root directory as positional argument (mirrors sibling path-taking commands like `impact`, `whatbreaks`). When set, this takes precedence over `--project`. (med-cleanup-bundle-v1 / M1)

          [default: .]

Options:
  -p, --project <PROJECT>
          Project root directory (deprecated alias for the positional path argument; kept for back-compat). (med-cleanup-bundle-v1 / M1)

  -l, --lang <LANG>
          Programming language

  -d, --depth <DEPTH>
          Maximum traversal depth

          [default: 3]

      --include-docstrings
          Include function docstrings

      --file <FILE>
          Filter to functions in this file (for disambiguating common names like "render")

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
| Typical output size | small (<1 KB single fn) to medium (~3-4 KB for depth-3 traversal) |

**Top-level keys (JSON, `RelevantContext`):**
- `entry_point` (`string`) — echoes the entry name VERBATIM (preserves `<file>:<func>` shorthand's func portion, or qualified `Class.method`)
- `depth` (`usize`) — echoes the `--depth` flag value
- `functions` (`array<FunctionContext>`) — every function reachable from the entry within depth; empty array if entry not in scope of --file filter

**`FunctionContext` shape** (`tldr-core/src/types.rs:3000-3022`):
- `name` (`string`) — possibly qualified (`YahooProvider.fetch_historical_data`)
- `file` (`string`) — path **relative to the supplied PATH argument** (e.g. `providers/yahoo.py` when PATH=`backend`, NOT `backend/providers/yahoo.py`)
- `line` (`u32`, 1-indexed)
- `signature` (`string`) — language-flavored; usually `def …` for Python, but shorthand path may render as `function …` (see P13)
- `docstring` (`string`, omitted when no `--include-docstrings` OR when source has none)
- `calls` (`array<string>`) — names of called functions (may be empty)
- `blocks` (`usize`, omitted when 0 — see P13)
- `cyclomatic` (`u32`, omitted when None)

**Text format (`-f text`):** calls `context.to_llm_string()` which emits markdown:
```text
# Code Context: <entry> (depth=N)

## Summary
- Entry point: `<entry>`
- Functions included: M

## Functions

### <name> (<file>:<line>)
...
```

**Empty result shape (P12):**
```json
{ "entry_point": "fetch_historical_data", "depth": 3, "functions": [] }
```
Exit 0 — empty `functions` is a normal "no matches under filter" response, not an error.

**Error shapes (all stderr):**
- Missing ENTRY: clap-style `"error: the following required arguments were not provided: <ENTRY> …"` → exit **2**
- Path not found: `"Error: Path not found: /no/such/dir"` → exit **2** (TldrError::PathNotFound, not a typed FileNotFound)
- Function not found: `"Error: Function not found: <name>"` → exit **20** (TldrError::FunctionNotFound)
- Format reject: `"Error: --format sarif not supported by context. Use --format json. SARIF is only emitted by: vuln, clones."` → exit **1**
- Bad `--lang`: clap-style `"error: invalid value 'X' for '--lang <LANG>': Unknown language: X"` → exit **2**

---

## Probe Matrix

| # | Probe | Type | Exit | Captured |
|---|-------|------|------|----------|
| P01 | `tldr context _to_finite_float backend -l python` | happy | 0 | [`01-happy.*`](./context.probes/) |
| P02 | `tldr context fetch_historical_data backend -l python` | happy-scale | 0 | [`02-happy-scale.*`](./context.probes/) |
| P03 | `tldr context` *(no ENTRY)* | failure-missing-input | 2 | [`03-missing-arg.*`](./context.probes/) |
| P04 | `tldr context some_fn /no/such/dir` | failure-badpath | 2 | [`04-badpath.*`](./context.probes/) |
| P05 | `tldr context ... -f sarif` | format-reject | 1 | [`05-format-reject-sarif.*`](./context.probes/) |
| P06 | `tldr context ... -f text` | format-text | 0 | [`06-format-text.*`](./context.probes/) |
| P07 | `tldr context ... -f compact` | format-compact | 0 | [`07-format-compact.*`](./context.probes/) |
| P08 | `tldr context ... -f dot` | format-reject-dot | 1 | [`08-format-reject-dot.*`](./context.probes/) |
| P09 | `tldr context ... -d 1` | depth-one | 0 | [`09-depth-one.*`](./context.probes/) |
| P10 | `tldr context ... -d 10` | depth-ten | 0 | [`10-depth-ten.*`](./context.probes/) |
| P11 | `tldr context ... --include-docstrings` | with-docstrings | 0 | [`11-with-docstrings.*`](./context.probes/) |
| P12 | `tldr context ... --file backend/providers/yahoo.py` | file-filter-empty | 0 | [`12-file-filter.*`](./context.probes/) |
| P13 | `tldr context backend/providers/yahoo.py:fetch_historical_data` | shorthand | 0 | [`13-shorthand.*`](./context.probes/) |
| P14 | `tldr context no_such_entry backend -l python` | function-not-found | 20 | [`14-entry-not-found.*`](./context.probes/) |
| P15 | `tldr context ... -l brainfuck` | bad-lang | 2 | [`15-bad-lang.*`](./context.probes/) |
| P16 | `tldr context _to_finite_float -p backend -l python` | project-alias | 0 | [`16-project-alias.*`](./context.probes/) |
| P17 | `tldr context ... -q` | quiet | 0 | [`17-quiet.*`](./context.probes/) |
| P18 | `tldr context fetch_historical_data backend -l python` *(cold)* | cold-daemon | 0 | [`18-cold-daemon.*`](./context.probes/) |
| P19 | `tldr context fetch_historical_data backend -l python` *(warm)* | warm-daemon | 0 | [`19-warm-daemon.*`](./context.probes/) |
| P20 | `tldr context ... --file ...` *(warm)* | warm-daemon-file-filter (forces direct compute) | 0 | [`20-warm-daemon-file-filter.*`](./context.probes/) |
| P21 | `tldr context _to_finite_float` *(no PATH, no --lang)* | default-path-ambiguous | 0 | [`21-default-path.*`](./context.probes/) |

### Observations

- **P01** — `_to_finite_float` from `backend` with `-l python` returns 1 function: `_to_finite_float` at `providers/yahoo.py:18` with cyclomatic 3, blocks 8. Note `file: "providers/yahoo.py"` — path is **relative to the PATH argument** (`backend`), NOT absolute or workspace-relative.
- **P02** — `fetch_historical_data` returns multiple `FunctionContext` entries because the project has two definitions (`DhanProvider.fetch_historical_data`, `YahooProvider.fetch_historical_data`) plus their callees at depth ≤3. Function ordering is **non-deterministic across runs** (see P02 vs P18 diff).
- **P03** — stderr `"error: the following required arguments were not provided: <ENTRY>"`, exit **2**. ContextArgs.entry is `String` (required).
- **P04** — stderr `"Error: Path not found: /no/such/dir"`, exit **2** (TldrError::PathNotFound, not a typed RemainingError). **Diverges from `tldr definition`/`tldr explain` (exit 5) and `tldr importers` (exit 1).** Yet another path-error convention.
- **P05** — stderr `"Error: --format sarif not supported by context. Use --format json. SARIF is only emitted by: vuln, clones."`, exit `1`.
- **P06** — Text format renders markdown via `RelevantContext::to_llm_string` (`types.rs:3024`). Format includes headers, code-block-wrapped signatures, and `**Calls:**` / `**Complexity:**` bullets. Progress message `"Building context for _to_finite_float (depth=3)..."` on stderr.
- **P07** — Single-line minified JSON, identical schema to P01.
- **P08** — stderr `"Error: --format dot not supported by context. Use --format json. DOT is only emitted by: clones, deps, calls, impact, hubs, inheritance."`, exit `1`.
- **P09 vs P02 vs P10** — `--depth 1`, default `--depth 3`, and `--depth 10` produce three DIFFERENT outputs (verified via MD5). `--depth` is **effective**, unlike `tldr explain`'s dead `--depth` flag.
- **P11** — `--include-docstrings` adds a `"docstring": "Convert ..."` field on FunctionContext. Without the flag, the field is omitted entirely (skip_serializing_if = "Option::is_none").
- **P12** — `--file backend/providers/yahoo.py` with PATH=`backend` returns `functions: []`. **Path interpretation mismatch:** the `--file` filter is checked against the per-function path (which is project-relative, e.g. `providers/yahoo.py`), so passing `backend/providers/yahoo.py` (cwd-relative) does NOT match. **Recovery hint:** when PATH is set to a subdirectory, supply --file relative to that subdirectory (e.g., `--file providers/yahoo.py`).
- **P13** — Shorthand `backend/providers/yahoo.py:fetch_historical_data` works: auto-derives `--file` from the colon split AND auto-derives project root (`infer_project_root_from_file` walks up looking for `.git`/`package.json`/etc., `context.rs:229`). The result has `signature: "function fetch_historical_data(self, symbol, start_date, end_date) -> pd.DataFrame"` and `blocks: 0` — **anomalous: the signature starts with `function` (not `def`) and blocks=0 even though the same function via P02 shows real metrics.** Suggests the shorthand path through `find_function_node` returns a different `FunctionContext` shape.
- **P14** — stderr `"Error: Function not found: no_such_entry"`, exit **20** (`TldrError::FunctionNotFound::exit_code() = 20`).
- **P15** — clap-style: `"error: invalid value 'brainfuck' for '--lang <LANG>': Unknown language: brainfuck"`, exit `2`.
- **P16** — `-p backend` with default positional PATH `.` works: `effective_project()` returns `backend` because positional is at default. **Correct precedence semantics** (`context.rs:56-61`). If both positional `<PATH>` and `--project` are set to non-default values, positional WINS.
- **P17** — `-q` suppresses stderr progress; stdout JSON unaffected.
- **P18, P19** — Cold (P18) and warm (P19) daemon outputs are **byte-identical** (verified via MD5). The daemon route ran for both because no `--file` filter was set.
- **P20** — Warm daemon with `--file ...` returns `functions: []`, same as P12. **The daemon route is GATED OFF when `effective_file.is_some()`** (`context.rs:124`: `if effective_file.is_none() { try_daemon_route(...) }`). So with --file, you always get direct-compute — but the path-interpretation mismatch from P12 still applies.
- **P21** — `tldr context _to_finite_float` with default PATH=`.` and no `-l` finds the wrong instance: `backend/precomputed_indicators.py:32`, not `backend/providers/yahoo.py:18`. The two `_to_finite_float` functions exist (P01 finds the providers one when PATH=`backend`). With PATH=`.`, language detection on the project root combined with `get_relevant_context`'s first-match logic picks the precomputed_indicators one — **silent first-match-wins on duplicate names.**

---

## Source Code Reality

**Target file(s):**
- `crates/tldr-cli/src/commands/context.rs` (269 lines)
- `crates/tldr-core/src/types.rs:2989-3022` (`RelevantContext`, `FunctionContext`)
- `crates/tldr-cli/src/commands/daemon_router.rs:236-243` (`params_with_entry_depth`)
- `crates/tldr-cli/src/output.rs:113` (`validate_format_for_command`)
- `crates/tldr-core/src/error.rs:314-358` (TldrError exit-code mapping)

**Pinned to upstream commit:** `6c4011a` (release v0.4.0)

**Argument struct:**
```rust
// crates/tldr-cli/src/commands/context.rs:18-49
#[derive(Debug, Args)]
pub struct ContextArgs {
    pub entry: String,
    #[arg(default_value = ".")]
    pub path: PathBuf,
    #[arg(long, short = 'p')]
    pub project: Option<PathBuf>,  // deprecated alias
    #[arg(long, short = 'l')]
    pub lang: Option<Language>,
    #[arg(long, short = 'd', default_value = "3")]
    pub depth: usize,
    #[arg(long)]
    pub include_docstrings: bool,
    #[arg(long)]
    pub file: Option<PathBuf>,
}
```
Reveals: `entry` is required (clap exit 2); `path` defaults to `.`; `--project` is a SHORT alias `-p` (deprecated); `--depth` short is `-d` with default 3. `--file` has no short.

**Path precedence:**
```rust
// context.rs:56-61
fn effective_project(&self) -> PathBuf {
    match &self.project {
        Some(p) if self.path == PathBuf::from(".") => p.clone(),
        _ => self.path.clone(),
    }
}
```
Reveals: positional `<PATH>` wins UNLESS it's left at the `.` default — in which case `--project` overrides. Both at non-default values → positional wins. Both unset → `.` (default).

**Shorthand `<file>:<func>` parser (right-to-left walk):**
```rust
// context.rs:189-217
fn split_file_func_shorthand(entry: &str) -> Option<(PathBuf, String)> {
    let mut idx = entry.rfind(':')?;
    loop {
        // ... walks colons right-to-left, returns first split whose file_part exists on disk
    }
}
```
Reveals: handles C++ qualified names (`x.cpp:XMLDocument::Parse`) and Windows drive letters (`C:\foo.js:foo`) by trying each `:` position from the right until a valid file_part is found. The first valid split wins.

**Daemon gating with --file (P12/P20 root cause):**
```rust
// context.rs:124
if effective_file.is_none() {
    if let Some(context) = try_daemon_route::<RelevantContext>(...) {
        ...
        return Ok(());
    }
}
// Fallback to direct compute (always runs when effective_file.is_some())
```
Reveals: the daemon protocol does not propagate `--file`, so the CLI explicitly bypasses it whenever a filter is set. Comment: *"the daemon protocol does not currently propagate the `--file` filter (would silently ignore the disambiguator)."* This is the same anti-pattern as `tldr importers`'s dropped `--lang`, but here the CLI is defensive — it forces the direct-compute path instead of silently mis-routing.

**Default language detection (same mixed-language gotcha as importers):**
```rust
// context.rs:115-118
let language = self
    .lang
    .unwrap_or_else(|| Language::from_directory(&project_path).unwrap_or(Language::Python));
```
The Python fallback only fires when `Language::from_directory` returns None. For a mixed-language root with TypeScript-heavy `webui/`, this may pick TypeScript silently. P21 demonstrates a related (but distinct) failure: the wrong `_to_finite_float` instance is returned.

**Daemon params builder forwards entry + depth:**
```rust
// daemon_router.rs:236-243
pub fn params_with_entry_depth(entry: &str, depth: Option<usize>) -> serde_json::Value {
    let mut obj = serde_json::Map::new();
    obj.insert("entry".to_string(), serde_json::json!(entry));
    if let Some(d) = depth {
        obj.insert("depth".to_string(), serde_json::json!(d));
    }
    serde_json::Value::Object(obj)
}
```
Reveals: daemon receives `entry` and `depth` — but NOT `language`, NOT `file`, NOT `include_docstrings`. Anything reliant on those flags must use the direct-compute path.

**Format validation:** confirmed at `crates/tldr-cli/src/output.rs:113-163` — `context` is in neither `SARIF_SUPPORTED` nor `DOT_SUPPORTED`.

---

## Architectural Deep Dive

- **Under the hood:** `get_relevant_context(project, entry, depth, language, include_docstrings, file_filter)` traverses the project call graph from the named entry function, following callees up to `depth` levels. Each visited function becomes a `FunctionContext` with signature, docstring (when requested), callees, and complexity. The call graph is built per-call in cold mode; the daemon caches it.
- **Performance:** Cold ~1-3s on Stock-Monitor backend; warm sub-100ms via daemon. The `--file` filter and the `<file>:<func>` shorthand both force direct-compute (the daemon protocol can't express them), so use them sparingly when iterating.
- **LLM cognitive load:** This is the **flagship "context-window-fits" command** — it produces a token-efficient pack of one entry function + its dependency tree, designed for direct paste into LLM prompts. The `to_llm_string()` markdown shape (P06) is the canonical "prepare context for code-aware AI" output. Use `-f text` when handing off to another LLM; use `-f json` when programmatically consuming.

---

## Intent & Routing

- **User/Agent Goal:** prepare a minimum-viable code context for an LLM that needs to understand a function and its dependencies — without reading entire files or chasing imports manually.
- **When to choose this over similar tools:**
  - Over `tldr explain`: `explain` deep-analyzes ONE function; `context` returns the function PLUS its callees (transitively, up to depth N) as a single ready-to-paste pack.
  - Over `tldr calls`: `calls` returns a raw call graph; `context` decorates each node with signature/docstring/complexity for human reading.
  - Over manual file slurping: `context` skips irrelevant code (only callee chain), produces deterministic markdown via `to_llm_string()`.
- **Prerequisites (composition):**
  - To disambiguate a common entry name (e.g., `render` exists in many files), use either `--file <path>` (relative to PATH) OR the `<file>:<func>` shorthand. Both force direct-compute.
  - For repeated queries on the same project, run `tldr daemon start --project <ROOT> && tldr warm <ROOT>` first — daemon path is 35x faster but only fires when no `--file` filter is set.
  - On mixed-language project roots, supply `-l <lang>` explicitly OR set PATH to a single-language subdirectory.

---

## Agent Synthesis

> **How to use `tldr context`:**
> Pulls an entry function + its dependency tree as an LLM-ready context pack. `tldr context <ENTRY> [PATH]` with default depth=3 returns a `RelevantContext` JSON `{ entry_point, depth, functions: [...] }`. Each `FunctionContext` has name (possibly qualified), file (relative to PATH), line, signature, calls, blocks/cyclomatic, and optional docstring (when `--include-docstrings`). For human/LLM consumption use `-f text` which calls `to_llm_string()` to emit markdown. Exit codes: 0 ok (including empty functions array under --file filter), 1 format-reject, 2 missing ENTRY / bad path / bad --lang (three failure modes share exit 2!), 20 function-not-found. The `--file` flag and `<file>:<func>` shorthand both force direct-compute (the daemon protocol cannot express them).
>
> **Crucial Rules:**
> - **`--file <path>` is interpreted relative to PATH, not cwd.** With `tldr context fn backend --file backend/providers/yahoo.py`, the filter is checked against `providers/yahoo.py` (the project-relative path emitted in `FunctionContext.file`), so the cwd-relative form returns `functions: []` silently (P12). **Fix:** pass `--file providers/yahoo.py` when PATH=`backend`.
> - **`<file>:<func>` shorthand auto-derives project root via VCS/build markers.** The colon-split walks right-to-left so C++ qualified names like `x.cpp:Class::method` and Windows drives like `C:\foo.js:foo` work (`context.rs:189-217`). Project root inferred from `.git`/`Cargo.toml`/`pyproject.toml`/etc. via `infer_project_root_from_file` (`context.rs:229`).
> - **Daemon route is GATED OFF when --file (or shorthand) is set.** `context.rs:124` explicitly bypasses `try_daemon_route` when `effective_file.is_some()` — the daemon protocol doesn't carry the filter, and the CLI is defensive about NOT silently dropping it. Use unscoped queries to benefit from the daemon's ~35x speedup.
> - **Path-not-found exit code is 2 (TldrError::PathNotFound).** Cross-command divergence — definition/explain use 5, importers uses 1, context uses 2, imports uses 2. Bad-path and missing-ENTRY both exit 2, so callers must parse stderr to distinguish.
> - **Function-not-found returns exit 20** (`Error: Function not found: <name>`). Matches the impact/explain convention via TldrError::FunctionNotFound. Distinct from clap missing-arg (also 2).
> - **`-p/--project` is a deprecated alias for the positional PATH.** The positional wins unless it's left at default `.` (`context.rs:56-61`). New code should use the positional.
> - **Function ordering in `functions[]` is non-deterministic across runs.** P02 vs P18 (same args, both direct-compute) yielded different ordering. Do not rely on positional indexing.
> - **Duplicate-name entries silently first-match.** If two functions share the entry name (e.g., `_to_finite_float` in both `yahoo.py` and `precomputed_indicators.py`), the result depends on filesystem walk order and language guess (P21). **Fix:** use `--file` or `<file>:<func>` shorthand to disambiguate.
> - **Shorthand path produces anomalous function shape.** Via `<file>:<func>` (P13), the signature starts with `function` (not `def`) and `blocks: 0` — the shorthand routes through a different `find_function_node` path that returns minimal metrics. Use full PATH + ENTRY + `--file` if you need accurate complexity numbers.
>
> **Command:** `tldr context <ENTRY> <PATH> -l <lang>`
>
> **With common flags:** `tldr context <ENTRY> <PATH> -l <lang> -d 5 --include-docstrings -f text` (use when producing a complete LLM-ready pack); `tldr context <file>:<func>` (use when you have a precise location and want auto-detected project root).
