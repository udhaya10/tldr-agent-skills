# Command: `tldr tree`

## Environment Pin

| Field | Value |
|---|---|
| `tldr --version` | 0.4.0 |
| Build features | `semantic` (verified via runtime probe on 2026-05-21) |
| Target repo | Stock-Monitor @ commit `e601869` |
| Upstream `tldr-code` pinned to | `6c4011a` (release v0.4.0, 2026-05-11) |
| Daemon state at probe time | warm (project = Stock-Monitor) |
| OS | darwin 25.2.0 |
| Probe date | 2026-05-22 |

Re-run all evidence via [`tree.probes/probe.sh`](./tree.probes/probe.sh).
See also: [agent-oriented tool card](../../tool-cards/overview/tree.md).

---

## Ground Truth (`tldr tree --help`)

```text
Show file tree structure

Usage: tldr tree [OPTIONS] [PATH]

Arguments:
  [PATH]
          Directory to scan (default: current directory)
          
          [default: .]

Options:
  -e, --ext <EXTENSIONS>
          Filter by file extensions (e.g., --ext .py --ext .rs)

  -H, --include-hidden
          Include hidden files and directories

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
| Formats that work | `json`, `text`, `compact` (P01, P06, P10) |
| Formats that error | `sarif`, `dot` (P05: exit 1) |
| Typical output size | medium (1–50KB) for a subdirectory (P01: ~6KB); **heavy (>50KB)** for an unfiltered repo (P02: ~500KB pre-truncation) |

**Top-level keys (JSON):**
- `name` (`string`) — directory or file name (not a path)
- `type` (`string`) — `"dir"` or `"file"`
- `children` (`array<object>`, dirs only) — recursive `FileTree` nodes
- `path` (`string`, files only) — repo-relative path, e.g. `"providers/base.py"`

**Recursive shape:** every `children` element is the same `{name, type, children?, path?}` node. Dirs have `children`; files have `path`.

**Empty result:**
```json
{ "name": "<dirname>", "type": "dir", "children": [] }
```
(returned when `--ext` filter matches nothing; exit 0)

**Text format (P06):** ASCII tree with `[D]` for dirs, `[F]` for files, indentation via `|--`.

**Compact format (P10):** single-line JSON, all whitespace stripped.

**Error shapes:**
- Bad path (P04): stderr `Error: Path not found: <path>`, exit `2`.
- Format rejection (P05): stderr `Error: --format sarif not supported by tree. Use --format json. SARIF is only emitted by: vuln, clones.`, exit `1`.

> **Distinct exit codes** for path errors (2) vs validator errors (1) — useful for agent recovery branching.

---

## Probe Matrix

Slug convention: `NN-<token>[-<modifier>]`. The audit script globs by ID, so modifiers are safe.

| # | Probe | Type | Exit | Captured |
|---|-------|------|------|----------|
| P01 | `tldr tree backend --ext .py` | happy | 0 | [`01-happy.*`](./tree.probes/) |
| P02 | `tldr tree . --ext .py` | happy-scale | 0 | [`02-happy-scale.*`](./tree.probes/) |
| P03 | N/A: all inputs optional — `[PATH]` defaults to `.` (verified at `tree.rs:21`). Running `tldr tree` with no args succeeds. | — | — | — |
| P04 | `tldr tree /no/such/path/definitely/missing` | failure-badpath | 2 | [`04-badpath.*`](./tree.probes/) |
| P05 | `tldr tree backend --ext .py -f sarif` | format-reject | 1 | [`05-format-reject-sarif.*`](./tree.probes/) |
| P06 | `tldr tree backend --ext .py -f text` | format-text | 0 | [`06-format-text.*`](./tree.probes/) |
| P07 | `tldr tree backend -H --ext .py` | flag-include-hidden | 0 | [`07-include-hidden.*`](./tree.probes/) |
| P08 | `tldr tree . --ext .py --ext .js` | flag-multi-ext | 0 | [`08-multi-ext.*`](./tree.probes/) |
| P09 | `tldr tree backend` | flag-no-ext-filter | 0 | [`09-no-ext-filter.*`](./tree.probes/) |
| P10 | `tldr tree backend --ext .py -f compact` | format-compact | 0 | [`10-format-compact.*`](./tree.probes/) |
| P11 | `tldr tree backend --ext .py` *(daemon stopped)* | env-cold-daemon | 0 | [`11-cold-daemon.*`](./tree.probes/) |

### Observations

- **P01 (happy, 298 lines):** Returns recursive `FileTree` JSON. `.gitignore` respected by default — `node_modules/`, `__pycache__/`, `.venv/` excluded.
- **P02 (full repo, 13,366 lines pre-truncation):** Output exceeded the 500-line cap and was truncated per protocol §5. Stock-Monitor's `webui/node_modules`-equivalents are correctly filtered. Latency ~sub-second on warm daemon.
- **P04 (bad path):** stderr `Error: Path not found: /no/such/path/definitely/missing`, exit `2`. **Recovery hint:** agent should `stat` the path or use `tldr tree <known-ancestor>` to discover valid subdirs before recursing.
- **P05 (sarif rejection):** stderr `Error: --format sarif not supported by tree. Use --format json. SARIF is only emitted by: vuln, clones.`, exit `1`. The error message itself lists the alternate commands — agent can route the user's intent if SARIF was actually needed.
- **P06 (text format, 60 lines):** Human-readable ASCII tree; useful for chat display but harder to parse programmatically — stick to JSON when feeding the output back into other tools.
- **P07 (include-hidden):** Output **identical** to P01 against `backend/` because Stock-Monitor's `backend/` has no dotfiles. Diff appears only at repo root or when probing a directory that contains `.env`, `.cache/`, etc.
- **P08 (multi-ext):** Both `.py` and `.js` matched. Confirms `--ext` is repeatable; under the hood the extensions are normalized in `tree.rs:54-66` (auto-prepends `.` if absent — so `--ext py` and `--ext .py` are equivalent).
- **P09 (no `--ext`):** 320 lines vs 298 for `--ext .py` — only ~22 non-Python files included (configs, JSON, markdown). Confirms unfiltered mode is reasonable for small dirs.
- **P10 (compact, 1 line / 4KB):** All whitespace stripped — the right format for piping into `jq` or stuffing into a single LLM message.
- **P11 (cold daemon):** Exit 0, 298 lines — identical to P01. **Why:** the daemon status at probe time showed `files: 0`, meaning the daemon's cache had not been populated yet. So both P01 and P11 fell through to the direct-compute fallback. Real cold-vs-warm comparison requires `tldr warm` first; see Architectural Deep Dive.

---

## Source Code Reality

**Target file:** `crates/tldr-cli/src/commands/tree.rs` (pinned to upstream commit `6c4011a`).

**Argument definition (`tree.rs:18-32`):**
```rust
#[derive(Debug, Args)]
pub struct TreeArgs {
    /// Directory to scan (default: current directory)
    #[arg(default_value = ".")]
    pub path: PathBuf,

    /// Filter by file extensions (e.g., --ext .py --ext .rs)
    #[arg(long = "ext", short = 'e')]
    pub extensions: Vec<String>,

    /// Include hidden files and directories
    #[arg(long, short = 'H')]
    pub include_hidden: bool,
}
```
Confirms: `path` is optional (defaults to `.`), `extensions` is repeatable (`Vec<String>`), `include_hidden` is a boolean flag.

**Daemon-route shortcut (`tree.rs:36-50`):**
```rust
if let Some(tree) =
    try_daemon_route::<FileTree>(&self.path, "tree", params_with_path(Some(&self.path)))
{
    if writer.is_text() {
        let text = format_file_tree_text(&tree, 0);
        writer.write_text(&text)?;
        return Ok(());
    } else {
        writer.write(&tree)?;
        return Ok(());
    }
}
```
**Hidden constraint:** when the daemon route hits a cached `FileTree`, the cached tree is returned **as-is**. The `extensions` and `include_hidden` flags are *not re-applied to the cached output*. Filtering occurs only in the fallback compute path below. This means a warmed daemon plus `--ext` may return more files than expected if the cache was warmed without filters. In Stock-Monitor probes we did not observe this because the daemon's cache was empty (`files: 0`).

**Fallback compute path (`tree.rs:53-79`):**
```rust
let extensions: Option<HashSet<String>> = if self.extensions.is_empty() {
    None
} else {
    Some(
        self.extensions
            .iter()
            .map(|s| {
                if s.starts_with('.') { s.clone() } else { format!(".{}", s) }
            })
            .collect(),
    )
};

let tree = get_file_tree(
    &self.path,
    extensions.as_ref(),
    !self.include_hidden,
    Some(&IgnoreSpec::default()),
)?;
```
Reveals: extensions are normalized (auto-prepended `.`); the `IgnoreSpec::default()` parses the project's `.gitignore`; `include_hidden` inverts to `exclude_hidden` for the underlying call.

**Format validator** (`crates/tldr-cli/src/output.rs::validate_format_for_command`):
```rust
const SARIF_SUPPORTED: &[&str] = &["vuln", "clones"];
const DOT_SUPPORTED: &[&str] = &["clones", "deps", "calls", "impact", "hubs", "inheritance"];
```
Confirms exactly what P05 captured: `tree` is in neither list, so `-f sarif` and `-f dot` are rejected with exit 1.

**Module-level comment (`tree.rs:1-4`):**
```rust
//! Tree command - Show file tree
//! Auto-routes through daemon when available for ~35x speedup.
```
Source-stated performance claim: ~35x speedup when daemon cache is hit. Unverified in our probes because the daemon cache was empty at probe time.

---

## Architectural Deep Dive

- **Engine:** Filesystem traversal in `tldr_core::get_file_tree`. Layered with `IgnoreSpec` (parses `.gitignore`) and optional extension filtering. Pure I/O, no AST involvement.
- **Cache layer:** When the `tldr` daemon is running and has been warmed (e.g., via `tldr warm`), the in-memory SQLite-backed `FileTree` is returned directly — the source comment cites ~35x speedup. A cold daemon (status `files: 0`) silently falls back to direct compute.
- **Filter timing:** Filters (`--ext`, `--include-hidden`) only apply on the compute fallback. Cached returns ignore these flags. Practical implication: if you warm the daemon with `tldr warm`, expect the cache to materialize an unfiltered tree; subsequent `--ext` calls may not behave as filters.
- **LLM cognitive load:** Replaces `ls -R` / system `tree` which dump tens of thousands of nodes and burn LLM context. By respecting `.gitignore` and exposing a structured JSON node shape, the agent can navigate via `jq '.children[] | select(.type=="dir")'` rather than reading raw text.

---

## Intent & Routing

- **User/Agent Goal:** Get a `.gitignore`-respecting directory layout to plan deeper inspection.
- **When to choose this over similar tools:**
  - Use *instead of* `ls -R` to skip ignored directories without writing find expressions.
  - Use *instead of* `tldr structure <dir>` when you want **file enumeration**, not function/class enumeration.
  - Use *before* `tldr extract` or `tldr semantic` to pick which files to drill into.
- **Prerequisites:** None — `tree` is itself a discovery entry point. If you intend many subsequent queries, run `tldr daemon start && tldr warm <repo>` first for the ~35x speedup (caveat: the cache will be unfiltered).

---

## Agent Synthesis

> **How to use `tldr tree`:**
> Use as the first discovery step on a new codebase. `.gitignore` is respected by default, so noise from `node_modules`, `.venv`, build outputs, etc. is already filtered out. Output is JSON by default — pipe through `jq` or set `-f compact` to keep it on one line.
>
> **Crucial Rules:**
> - **`[PATH]` is optional** — defaults to `.`. Pass a subdirectory to scope the output (`tldr tree backend` instead of `tldr tree .` if you don't need the whole repo).
> - **`--ext` filters are repeatable**, and a leading `.` is optional (`--ext py` = `--ext .py`).
> - **`-f sarif` and `-f dot` are rejected** for `tree` (exit 1). Stick to `json` (default), `text`, or `compact`.
> - **Path not found returns exit 2** (distinct from validator errors which exit 1) — let the agent branch on exit code.
> - **Daemon warm-up caveat:** if `tldr warm` was run, the cached tree may ignore `--ext` filters. For predictable filtering, run with `--ext` against a stopped daemon, or accept a fuller tree from the cache.
> - **Output can be huge** on unfiltered full-repo invocations (Stock-Monitor: ~13k lines). Always combine with `--ext` or a subdirectory path unless you actually need the entire repo's file enumeration.
>
> **Commands:**
> - Quick scope: `tldr tree <dir>`
> - Filtered by language: `tldr tree <dir> --ext .py --ext .ts`
> - Single-line JSON for piping: `tldr tree <dir> --ext .py -f compact`
> - Human-readable for chat: `tldr tree <dir> -f text`
