# Command: `tldr surface`

## Environment Pin

| Field | Value |
|---|---|
| `tldr --version` | 0.4.0 |
| Build features | `semantic` (verified; surface is AST-based, non-semantic) |
| Target repo | Stock-Monitor @ commit `e601869` (used for backend dir probes) |
| Upstream `tldr-code` pinned to | local clone @ `6c4011a` (release v0.4.0) |
| Daemon state at probe time | N/A — `tldr surface` does **not** call `try_daemon_route` (verified by grep) |
| OS | darwin 25.2.0 |
| Probe date | 2026-05-22 |

Re-run all evidence via [`surface.probes/probe.sh`](./surface.probes/probe.sh).
See also: [agent-oriented tool card](../../tool-cards/ops/surface.md).

**Omission note:** Per `05_OMITTED_COMMANDS_RATIONALE.md` §2, `tldr surface` is **SUPPRESSED from agent-facing skills** because it outputs massive raw structural data (P18: 38,111 lines for backend/). Agents are better served by `tldr api-check` (compare surface changes) or `tldr interface` (synthesize interfaces). Probed for research completeness.

---

## Ground Truth (`tldr surface --help`)

```text
Extract machine-readable API surface for a library/package

Usage: tldr surface [OPTIONS] <TARGET>

Arguments:
  <TARGET>                                     Package name OR directory path

Options:
      --lookup <LOOKUP>                        Lookup specific API by qualified name
      --include-private                        Include private/internal APIs
      --limit <LIMIT>                          Maximum APIs to extract
      --manifest-path <MANIFEST_PATH>          Path to Cargo.toml (Rust)
  -f, --format <FORMAT>                        [default: json]
  -l, --lang <LANG>
  -q, --quiet  -v, --verbose  -h, --help
```

---

## Output Shape

| Aspect | Value |
|---|---|
| Default format | `json` |
| Formats that work | `json`, `text`, `compact` (P01, P06, P07) |
| Formats that error | `sarif`, `dot` (P05, P08: exit 1) |
| Typical output size | LARGE: ~714 lines for stdlib `json` package; **~38,000 lines** for backend dir |

**Top-level keys (JSON, `ApiSurface`):**
- `package` (`string`) — input TARGET echoed (package name OR canonical dir name)
- `language` (`string`) — detected/specified language
- `total` (`u32`) — count of APIs
- `apis` (`array<Api>`) — extracted APIs
- `files_skipped` (`u32`)
- `warnings` (`array<string>`)

**`Api` shape:**
- `qualified_name` (`string`) — e.g., `"json.loads"`
- `kind` (`string`) — `"Function"`, `"Class"`, `"Method"`, `"Constant"`, etc.
- `module` (`string`) — containing module
- `signature` (`object`) — language-specific signature with `params: [{ name, default?, is_variadic, is_keyword }, ...]`, return type, etc.

**Empty-result shape (P04 bad package, P10 lookup-not-found, P13 --limit 0, P19 empty dir):**
```json
{
  "package": "<TARGET>",
  "language": "python",
  "total": 0,
  "apis": [],
  "files_skipped": 0,
  "warnings": []
}
```
Exit 0. Same shape across all 4 cases — agents cannot distinguish bad-package from empty-result from limit-zero by output alone.

**Error shapes:**
- Missing TARGET: clap-style → exit **2**
- Format reject sarif: `"Error: --format sarif not supported by surface. ..."` → exit **1**
- Bad `--lang`: clap-style → exit **2**
- Lang mismatch (TARGET not findable in that language): `"Error: Parse error in : Cannot find <lang> package '<target>'. No node_modules/<target>/package.json found in ..."` → exit **10** (TldrError::CoverageParseError or similar — distinct exit code!)

---

## Probe Matrix

| # | Probe | Type | Exit | Captured |
|---|-------|------|------|----------|
| P01 | `tldr surface json` | happy (Python stdlib package — 12 APIs) | 0 | [`01-happy.*`](./surface.probes/) |
| P02 | `tldr surface backend/providers` | happy-scale (dir, ~560 lines) | 0 | [`02-happy-scale.*`](./surface.probes/) |
| P03 | `tldr surface` *(no TARGET)* | failure-missing-input | 2 | [`03-missing-arg.*`](./surface.probes/) |
| P04 | `tldr surface no_such_package_zzz` | bad package (SILENT empty) | 0 | [`04-badpath.*`](./surface.probes/) |
| P05 | `tldr surface ... -f sarif` | format-reject (sarif) | 1 | [`05-format-reject-sarif.*`](./surface.probes/) |
| P06 | `tldr surface json -f text` | format-text | 0 | [`06-format-text.*`](./surface.probes/) |
| P07 | `tldr surface json -f compact` | format-compact | 0 | [`07-format-compact.*`](./surface.probes/) |
| P08 | `tldr surface json -f dot` | format-reject (dot) | 1 | [`08-format-reject-dot.*`](./surface.probes/) |
| P09 | `tldr surface json --lookup json.loads` | --lookup specific API | 0 | [`09-lookup.*`](./surface.probes/) |
| P10 | `tldr surface json --lookup json.no_such_function` | lookup not found (silent empty) | 0 | [`10-lookup-not-found.*`](./surface.probes/) |
| P11 | `tldr surface json --include-private` | include private (1425 lines, 2x default) | 0 | [`11-include-private.*`](./surface.probes/) |
| P12 | `tldr surface json --limit 5` | limit 5 | 0 | [`12-limit-low.*`](./surface.probes/) |
| P13 | `tldr surface json --limit 0` | **--limit 0 = LITERAL ZERO** | 0 | [`13-limit-zero.*`](./surface.probes/) |
| P14 | `tldr surface json --manifest-path /no/such/Cargo.toml` | manifest-path (ignored for Python) | 0 | [`14-manifest-path.*`](./surface.probes/) |
| P15 | `tldr surface json -l brainfuck` | bad-lang | 2 | [`15-bad-lang.*`](./surface.probes/) |
| P16 | `tldr surface json -l python` | explicit python | 0 | [`16-lang-python.*`](./surface.probes/) |
| P17 | `tldr surface json -l typescript` | lang-mismatch (exit 10!) | 10 | [`17-lang-mismatch.*`](./surface.probes/) |
| P18 | `tldr surface backend` | directory as TARGET (~38K lines!) | 0 | [`18-target-as-directory.*`](./surface.probes/) |
| P19 | `tldr surface <empty-tmp-dir>` | empty dir | 0 | [`19-empty-dir.*`](./surface.probes/) |
| P20 | `tldr surface json -q` | quiet | 0 | [`20-quiet.*`](./surface.probes/) |

### Observations

- **P01** — `tldr surface json` (Python stdlib): `{ package: "json", language: "python", total: 12, apis: [12 Function entries] }`. 714 lines. Each API has `qualified_name`, `kind: "Function"`, `module: "json"`, `signature: { params: [{ name, default?, is_variadic, is_keyword }, ...] }`.
- **P02** — `backend/providers/`: 559 lines, similar shape but for the project directory. `package: "backend/providers"` (path echo).
- **P03** — stderr `"error: the following required arguments were not provided: <TARGET>"`, exit `2`.
- **P04** — **SILENT BAD PACKAGE:** `tldr surface no_such_package_zzz_brainfuck` returns exit 0 with `{ total: 0, apis: [], warnings: [] }`. **No error or warning.** Indistinguishable from "no APIs in valid package."
- **P05** — stderr `"Error: --format sarif not supported by surface. Use --format json. SARIF is only emitted by: vuln, clones."`, exit `1`.
- **P06** — Text format: 87 lines, human-readable API list.
- **P07** — Single-line minified JSON.
- **P08** — stderr `"Error: --format dot not supported by surface. ..."`, exit `1`.
- **P09** — `--lookup json.loads`: filters to one API. `{ total: 1, apis: [{ qualified_name: "json.loads", ... }] }`. 81 lines.
- **P10** — `--lookup json.no_such_function`: same shape as P04 (silent empty). Exit 0.
- **P11** — `--include-private`: 1,425 lines — 2x default. Includes `_*` prefixed private APIs.
- **P12** — `--limit 5`: 389 lines, `total: 5`. Truncates.
- **P13** — **`--limit 0` LITERALLY ZERO** (same as `tldr contracts --limit 0` and `tldr patterns --max-files 0`): `total: 0, apis: []`. **Cross-command convention divergence.** Most "0 = unlimited" commands behave differently.
- **P14** — `--manifest-path /no/such/Cargo.toml` on Python target: 714 lines (same as P01). **Manifest path is IGNORED when language is not Rust** (source: `if is_rust { ... } else { self.target.clone() }`).
- **P15** — clap-style: `"error: invalid value 'brainfuck' for '--lang <LANG>': Unknown language: brainfuck"`, exit `2`.
- **P16** — Explicit `-l python`: identical to P01.
- **P17** — **EXIT 10 (DISTINCT!):** `-l typescript` on Python `json` package: stderr `"Error: Parse error in : Cannot find typescript package 'json'. No node_modules/json/package.json found in '<CWD>' or any parent directory."`. Includes the recovery hint. **TldrError::CoverageParseError-like distinct exit code.**
- **P18** — **MASSIVE OUTPUT: 38,111 lines!** Per `OMITTED_RATIONALE` §2: this is precisely why surface is suppressed from agents. Directory extraction is unbounded by default.
- **P19** — Empty dir: same silent-empty shape as P04. `total: 0, files_skipped: 0`.
- **P20** — `-q quiet`: same 714 lines as P01 — `-q` is a no-op for surface.

---

## Source Code Reality

**Target file(s):**
- `crates/tldr-cli/src/commands/api_surface.rs` (~150+ lines)
- `crates/tldr-core/src/contracts/surface/...` (per-language API extractors)
- `crates/tldr-cli/src/output.rs:113` (`validate_format_for_command`)

**Pinned to upstream commit:** `6c4011a` (release v0.4.0)

**Argument struct:**
```rust
// crates/tldr-cli/src/commands/api_surface.rs:34-53
#[derive(Debug, Args)]
pub struct ApiSurfaceArgs {
    pub target: String,
    #[arg(long)] pub lookup: Option<String>,
    #[arg(long)] pub include_private: bool,
    #[arg(long)] pub limit: Option<usize>,
    #[arg(long)] pub manifest_path: Option<PathBuf>,
}
```
Reveals: TARGET is `String` (NOT `PathBuf`!) — can be a package name OR a directory path. NO upfront path validation (any string accepted).

**`--manifest-path` is Rust-specific (P14):**
```rust
// api_surface.rs:69-81
let effective_target = if let Some(ref manifest) = self.manifest_path {
    let is_rust = lang_str.as_deref() == Some("rust");
    if is_rust {
        manifest.parent().map(|p| p.to_string_lossy().into_owned())
            .unwrap_or_else(|| self.target.clone())
    } else {
        self.target.clone()  // IGNORED for non-Rust
    }
} else { ... };
```
Reveals: `--manifest-path` is only honored when `--lang rust`. For other languages, the flag is silently ignored.

**Format validation:** confirmed at `crates/tldr-cli/src/output.rs:113-163` — `surface` is in neither `SARIF_SUPPORTED` nor `DOT_SUPPORTED`.

**No daemon route:** `grep -n try_daemon_route api_surface.rs` returns 0 matches.

---

## Architectural Deep Dive

- **Under the hood:** For package targets (e.g., `"json"`), the engine resolves via language-specific lookup (Python: sys.path + stdlib; JS/TS: node_modules; Rust: Cargo.toml). For directory targets, walks the project. For each file, extracts ALL declared functions, classes, methods (filter to public unless `--include-private`). Builds the `signature` block per language (params, defaults, kind annotations, etc.).
- **Performance:** Stdlib packages are fast (~100ms). Directory extraction is slow on large repos — P18 had 38K lines of output, took several seconds.
- **LLM cognitive load:** **AGENTS: AVOID for directory targets** — output overwhelms context. For "what does this library expose?" questions, use `tldr surface <PACKAGE>` (small output). For projects, prefer `tldr api-check` (diff-focused) or `tldr interface` (per-file synthesis). Per `OMITTED_RATIONALE` §2.

---

## Intent & Routing

- **User/Agent Goal:** extract the machine-readable API surface of a library/package or directory.
- **When to choose this over similar tools:**
  - For agents: NEVER for directories (38K lines!). Use `tldr api-check` or `tldr interface` instead.
  - For humans: documenting a library's API; comparing third-party package surfaces; auditing private vs public APIs.
- **Prerequisites (composition):**
  - Package targets need language-specific resolver (Python: stdlib/sys.path; JS/TS: node_modules; Rust: Cargo.toml).
  - For Rust packages, pass `--manifest-path Cargo.toml` to resolve.
  - For non-existent targets: silent empty result (P04) — verify externally.

---

## Agent Synthesis

> **How to use `tldr surface`:**
> **AGENTS: PREFER `tldr api-check` OR `tldr interface` instead.** Surface is suppressed from agent-facing skills per `OMITTED_RATIONALE` §2 — directory targets produce massive output (P18: 38,111 lines for backend/). For research completeness: `tldr surface <TARGET>` extracts API surface as JSON `{ package, language, total, apis: [{ qualified_name, kind, module, signature }], files_skipped, warnings }`. `<TARGET>` can be a package name (e.g., `"json"`) OR a directory path. Filter with `--lookup <qualified.name>` for one API; `--include-private` to add `_*` members; `--limit <N>` to cap. Default JSON; `-f text` for human display; `-f compact` for one-line; `sarif`/`dot` rejected. Exit codes: 0 ok (incl. SILENT bad-target), 1 format-reject, 2 missing TARGET / bad-lang, 10 lang-mismatch (cannot find package in specified language).
>
> **Crucial Rules:**
> - **AGENTS: AVOID DIRECTORY TARGETS.** P18: `tldr surface backend` produced 38,111 lines. Per OMITTED_RATIONALE §2: use `tldr api-check` (diff-focused) or `tldr interface` (per-file synthesis) instead — they produce focused, actionable output.
> - **BAD TARGET IS SILENT** (P04, P10, P19). Exit 0 with `{ total: 0, apis: [], warnings: [] }` for: unknown package (`no_such_package_zzz`), lookup-not-found, empty directory. **All FOUR cases indistinguishable from output alone** — verify externally or check `total > 0`.
> - **EXIT 10 FOR LANG-MISMATCH** (P17, distinct exit code): `-l typescript` on a Python `json` package returns `"Error: Parse error in : Cannot find typescript package 'json'. No node_modules/json/package.json found in '<CWD>' or any parent directory."` Includes recovery hint about node_modules. Agents seeing exit 10 should retry with correct `--lang`.
> - **`--limit 0` LITERALLY ZERO** (P13). NOT unlimited. Cross-command convention divergence — matches `tldr contracts --limit 0` and `tldr patterns --max-files 0`. Use a large number for "everything."
> - **`--manifest-path` is IGNORED for non-Rust languages** (P14, source: api_surface.rs:69-81). Only honored when `--lang rust`. Silent ignore otherwise.
> - **`--include-private` doubles output size** (P11: 1425 lines vs 714 default). Use sparingly.
> - **TARGET is `String`, not `PathBuf`** (source). No upfront path validation — silent empty for anything that doesn't resolve.
> - **`-q quiet` is a no-op** (P20: same output as default). Surface's "real" output is the API data, not progress.
> - **`signature.params[]` has `is_variadic` and `is_keyword` booleans** — distinguishes `*args` from `**kwargs` in Python, similar for JS/TS rest/destructure.
> - **NO daemon route.** Every call re-extracts.
>
> **Command:** `tldr surface <TARGET>`
>
> **With common flags:** `tldr surface <PACKAGE> --lookup <qualified.name> -f compact | jq '.apis[0].signature.params'` (HUMAN use for "what params does this function take?"; AGENTS should use `tldr interface <FILE>` for project files instead).
