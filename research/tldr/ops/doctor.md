# Command: `tldr doctor`

## Environment Pin

| Field | Value |
|---|---|
| `tldr --version` | 0.4.0 |
| Build features | `semantic` (verified; doctor uses `which` for tool detection, non-semantic) |
| Target repo | N/A — doctor is environment-only, not project-scoped |
| Upstream `tldr-code` pinned to | local clone @ `6c4011a` (release v0.4.0) |
| Daemon state at probe time | N/A — `tldr doctor` does **not** call `try_daemon_route` (verified by grep) |
| OS | darwin 25.2.0 |
| Probe date | 2026-05-22 |

Re-run all evidence via [`doctor.probes/probe.sh`](./doctor.probes/probe.sh).

**Omission note:** Per `05_OMITTED_COMMANDS_RATIONALE.md` §2, `tldr doctor` is **SUPPRESSED from agent-facing skills**. It checks local system binaries (Python, Rustc, etc.) — purely for human operators debugging their environment. Agents cannot fix missing system binaries. Probed for research completeness, NOT for agent guidance.

---

## Ground Truth (`tldr doctor --help`)

```text
Check and install diagnostic tools

Usage: tldr doctor [OPTIONS]

Options:
      --install <INSTALL>          Install diagnostic tools for a specific language
  -f, --format <FORMAT>            [default: json]
  -l, --lang <LANG>
  -q, --quiet  -v, --verbose  -h, --help
```

**Modes:**
- **Check mode (default):** detect all language tools, report installed/missing.
- **Install mode (`--install <LANG>`):** run install commands for the specified language.

---

## Output Shape

| Aspect | Value |
|---|---|
| Default format | `json` (per `-f --help`; though source comment says text — **source-comment drift!**) |
| Formats that work | `json`, `text`, `compact` (P01, P06, P07) |
| Formats that error | `sarif`, `dot` (P05, P08: exit 1) |
| Typical output size | ~190 lines (JSON, all langs), ~74 lines (text) |

**Top-level keys (JSON, check mode):** OBJECT keyed by language name — `{ c: {...}, cpp: {...}, csharp: {...}, go: {...}, java: {...}, javascript: {...}, kotlin: {...}, lua: {...}, php: {...}, python: {...}, ruby: {...}, rust: {...}, scala: {...}, swift: {...}, typescript: {...} }`. **~15 languages checked** regardless of project context.

**Per-language shape:**
```json
{
  "type_checker": { "name": "pyright", "installed": true, "path": "/usr/bin/pyright", "install": null },
  "linter": { "name": "ruff", "installed": false, "path": null, "install": "pip install ruff" }
}
```
- `name` (`string`) — tool name
- `installed` (`bool`)
- `path` (`string` | `null`) — absolute path via `which::which` when installed
- `install` (`string` | `null`) — install command HINT (only when NOT installed)

**Install mode output (P09 SKIPPED):**
Would print `"Installing tools for <lang>: <cmd>"` to stderr, then `"Installed <lang> tools"` on success. Exit 0 on success, exit 1 on failure.

**Error shapes:**
- Bad `--install <X>`: `"Error: No auto-install available for '<X>'. Available: go, kotlin, lua, python, ruby, rust, swift. unknown language."` → exit **1** (note: `"unknown language."` suffix is duplicated stylistically)
- Format reject sarif: `"Error: --format sarif not supported by doctor. ..."` → exit **1**
- `--install` twice (clap conflicts): `"error: the argument '--install <INSTALL>' cannot be used multiple times"` → exit **2**
- Bad `--lang`: clap-style → exit **2**
- `--install ""`: same as bad-install error (empty string treated as unknown) → exit **1**

---

## Probe Matrix

| # | Probe | Type | Exit | Captured |
|---|-------|------|------|----------|
| P01 | `tldr doctor` | happy (check mode, default JSON) | 0 | [`01-happy.*`](./doctor.probes/) |
| P02 | `tldr doctor -f json -q` | happy-scale (JSON quiet) | 0 | [`02-happy-scale.*`](./doctor.probes/) |
| P03 | N/A: no required positional. | — | — | [`03-missing-arg.*`](./doctor.probes/) (placeholder) |
| P04 | `tldr doctor --install brainfuck` | bad install lang | 1 | [`04-badpath.*`](./doctor.probes/) |
| P05 | `tldr doctor -f sarif` | format-reject (sarif) | 1 | [`05-format-reject-sarif.*`](./doctor.probes/) |
| P06 | `tldr doctor -f text` | format-text | 0 | [`06-format-text.*`](./doctor.probes/) |
| P07 | `tldr doctor -f compact` | format-compact | 0 | [`07-format-compact.*`](./doctor.probes/) |
| P08 | `tldr doctor -f dot` | format-reject (dot) | 1 | [`08-format-reject-dot.*`](./doctor.probes/) |
| P09 | `tldr doctor --install python` | install mode (SKIPPED — destructive) | — | [`09-install-python.*`](./doctor.probes/) (placeholder) |
| P10 | `tldr doctor --install wat` | bad install (full lang list) | 1 | [`10-install-bogus.*`](./doctor.probes/) |
| P11 | `tldr doctor -l python` | -l IGNORED (all langs checked) | 0 | [`11-lang-python.*`](./doctor.probes/) |
| P12 | `tldr doctor -l typescript` | -l IGNORED | 0 | [`12-lang-typescript.*`](./doctor.probes/) |
| P13 | `tldr doctor -l brainfuck` | bad-lang | 2 | [`13-bad-lang.*`](./doctor.probes/) |
| P14 | `tldr doctor -q` | quiet (NOT silent — full output) | 0 | [`14-quiet.*`](./doctor.probes/) |
| P15 | `tldr doctor --install python --install rust` | multiple --install (clap rejects) | 2 | [`15-install-multiple.*`](./doctor.probes/) |
| P16 | `tldr doctor --install ''` | empty --install | 1 | [`16-install-empty.*`](./doctor.probes/) |
| P17 | `cd <tmp> && tldr doctor -f json -q` | doctor from non-project dir | 0 | [`17-from-tmp.*`](./doctor.probes/) |

### Observations

- **P01** — Default mode: 191 lines JSON. Reports type_checker + linter for each of ~15 languages. **CONFIRMED SOURCE-COMMENT DRIFT:** the source comment at doctor.rs:220 says "doctor defaults to text output for better UX" — but ACTUAL default is JSON. Likely the global `-f json` default overrides the local intent.
- **P02** — `-f json -q`: same 191 lines as P01 (P01 already defaulted to JSON). `-q` doesn't suppress output for doctor — it's NOT a "silent" flag for this command.
- **P03** — **N/A.** No required positional arg.
- **P04** — stderr `"Error: No auto-install available for 'brainfuck'. Available: go, kotlin, lua, python, ruby, rust, swift. unknown language."`, exit `1`. **7 languages have auto-install:** go, kotlin, lua, python, ruby, rust, swift. JS/TS/C/C++/etc. canNOT be auto-installed via doctor. Note the trailing `"unknown language."` — appended to the error verbatim.
- **P05** — stderr `"Error: --format sarif not supported by doctor. Use --format json. SARIF is only emitted by: vuln, clones."`, exit `1`.
- **P06** — Text format: 74 lines. `"TLDR Diagnostics Check\n==================================================\n\nC:\n  [OK] gcc - /usr/bin/gcc\n  [OK] cppcheck - /opt/homebrew/bin/cppcheck\n\nCpp:\n  ...\n"`. Per-language block.
- **P07** — Single-line minified JSON (1 line).
- **P08** — stderr `"Error: --format dot not supported by doctor. ..."`, exit `1`.
- **P09** — **SKIPPED** (destructive). Would print stderr `"Installing tools for python: pip install pyright ruff"` (approx) and then run the install command. Returns exit 0 on success, exit 1 on failure.
- **P10** — stderr `"Error: No auto-install available for 'wat'. Available: go, kotlin, lua, python, ruby, rust, swift. unknown language."`, exit `1`. Same shape as P04.
- **P11** — `-l python`: 191 lines, **IDENTICAL to default**. The `--lang` flag is parsed but the doctor check mode IGNORES it — all languages are checked regardless.
- **P12** — `-l typescript`: same as P11 (191 lines, identical to default).
- **P13** — clap-style: `"error: invalid value 'brainfuck' for '--lang <LANG>': Unknown language: brainfuck"`, exit `2`.
- **P14** — `-q`: 191 lines (NOT suppressed). Doctor's `-q` doesn't actually silence the output — it's a no-op here. **Unusual** vs other commands.
- **P15** — clap-style: `"error: the argument '--install <INSTALL>' cannot be used multiple times"`, exit `2`. `--install` is single-valued (NOT `Vec<String>`).
- **P16** — stderr `"Error: No auto-install available for ''. Available: go, kotlin, lua, python, ruby, rust, swift. unknown language."`, exit `1`. **Empty string treated as bad language.**
- **P17** — Run from `/tmp/...`: identical output. **Doctor is CWD-independent** — checks system PATH regardless of working directory.

---

## Source Code Reality

**Target file(s):**
- `crates/tldr-cli/src/commands/doctor.rs` (~400+ lines including `get_tool_info` registry)
- `crates/tldr-cli/src/output.rs:113` (`validate_format_for_command`)

**Pinned to upstream commit:** `6c4011a` (release v0.4.0)

**Argument struct:**
```rust
// crates/tldr-cli/src/commands/doctor.rs:223-227
#[derive(Debug, Args)]
pub struct DoctorArgs {
    #[arg(long)] pub install: Option<String>,
}
```
Reveals: ONE flag (`--install`). All other flags are global. `--install` is `Option<String>` (NOT typed enum), so any string is accepted — bad values fall through to the runtime "No auto-install available" error.

**Source-comment drift (default format):**
```rust
// doctor.rs:217-221 (excerpt)
/// Unlike most tldr commands, doctor defaults to text output for better UX.
/// Use `-f json` to get JSON output.
```
**vs OBSERVED:** P01 (no `-f` flag) returns JSON, not text. The source comment is OUT OF DATE. The global `-f json` default applies.

**Install command registry:**
```rust
// doctor.rs:247-254 (excerpt of run_install)
let Some(cmd_args) = install_commands.get(lang_lower.as_str()) else {
    let available: Vec<&str> = install_commands.keys().copied().collect();
    bail!(
        "No auto-install available for '{}'. Available: {}. unknown language.",
        lang, available.join(", ")
    );
};
```
Reveals: **7 languages have install commands:** go, kotlin, lua, python, ruby, rust, swift (per P04 error list).

**Format validation:** confirmed at `crates/tldr-cli/src/output.rs:113-163` — `doctor` is in neither `SARIF_SUPPORTED` nor `DOT_SUPPORTED`.

**No daemon route:** `grep -n try_daemon_route doctor.rs` returns 0 matches.

---

## Architectural Deep Dive

- **Under the hood:** Two modes. **Check (default):** iterates the `get_tool_info()` registry (~15 languages × type_checker + linter); for each tool, uses `which::which()` to detect installation; emits absolute path when found, install hint when missing. **Install (`--install <LANG>`):** runs the registered install command (e.g., `pip install pyright ruff` for Python) as a subprocess.
- **Performance:** Fast (~50-100ms). No file I/O beyond `which` lookups.
- **LLM cognitive load:** **Agents should NEVER invoke this command** per OMITTED_RATIONALE §2. Even if missing tools are detected, agents can't act on the install hints (they don't have system-level permissions). For human operators: `tldr doctor` is the canonical "is my dev env set up?" check.

---

## Intent & Routing

- **User/Agent Goal:** (HUMAN OPERATORS ONLY) verify local diagnostic tools are installed for tldr's `diagnostics` command. Agents do not benefit.
- **When to choose this over similar tools:**
  - For humans: setup-time check, optionally `--install <LANG>` to auto-install.
  - For agents: NEVER. The downstream `tldr diagnostics` command itself emits exit 60 with install hints when tools are missing.
- **Prerequisites (composition):**
  - None — doctor is environment-only.
  - `--install` requires the language to be in the 7-language auto-install set (go, kotlin, lua, python, ruby, rust, swift).

---

## Agent Synthesis

> **How to use `tldr doctor`:**
> **DO NOT USE.** Suppressed from agent-facing skills per `05_OMITTED_COMMANDS_RATIONALE.md` §2 — doctor checks LOCAL SYSTEM BINARIES (Python, Rustc, etc.), purely for human operators debugging their environment. Agents cannot fix missing system binaries. For reference: `tldr doctor` (check mode) returns JSON object KEYED by language name (~15 languages), each with `{ type_checker, linter }` tools showing `installed` bool, `path?`, and `install?` hint. `tldr doctor --install <LANG>` runs the install command for that language (DESTRUCTIVE — actually executes `pip install`, `cargo install`, etc.). Default JSON; `-f text` for human display; `-f compact` for one-line; `sarif`/`dot` rejected. Exit codes: 0 ok, 1 bad-install-lang / format-reject / install-failure, 2 bad-lang / multiple --install.
>
> **Crucial Rules:**
> - **AGENTS: DO NOT INVOKE.** When `tldr diagnostics` needs tools that aren't installed, it ALREADY emits exit 60 with install hints (per the diagnostics dossier). Doctor is redundant for agents.
> - **SOURCE-COMMENT DRIFT:** doctor.rs:220 claims "doctor defaults to text output for better UX." OBSERVED: default IS JSON (P01). The global `-f json` default overrides the source's intent. For text output, PASS `-f text` explicitly.
> - **ONLY 7 LANGUAGES HAVE AUTO-INSTALL** (P04 error list): `go, kotlin, lua, python, ruby, rust, swift`. JavaScript, TypeScript, C, C++, C#, Java, PHP, Scala canNOT be auto-installed via `--install`. Agents requesting auto-install for those will get exit 1.
> - **`--install` is DESTRUCTIVE** — runs the registered install command as a subprocess (e.g., `pip install pyright ruff`). Agents must NEVER invoke this — system-level permissions and side effects are out-of-scope.
> - **`-l <lang>` is IGNORED in check mode** (P11/P12: same output as default). Doctor always checks ALL ~15 languages — the lang flag is parsed for global-flag consistency but has no effect.
> - **`-q quiet` does NOT silence output** (P14: 191 lines same as default). Unusual — most tldr `-q` suppress at least progress messages. Doctor's check output is the "real" output, not progress.
> - **Empty `--install ''` is treated as a bad language** (P16: same error as `--install wat`). Not special-cased.
> - **Doctor is CWD-INDEPENDENT** (P17). Run from anywhere — checks system PATH, not project files.
> - **Schema is KEYED OBJECT** by language name. Iterate via `Object.entries()` (JS) or `.items()` (Python). Empty case is unlikely — at least one language is always checked.
> - **`install` field is the INSTALL HINT** (e.g., `"pip install ruff"`), not a path. When the tool IS installed, `install` is null. When MISSING, it's populated.
> - **NO daemon route.** Stateless check.
>
> **Command:** `tldr doctor` (HUMANS only — agents see this dossier for completeness).
>
> **With common flags:** `tldr doctor -f json | jq 'to_entries | map(select(.value.linter.installed == false)) | from_entries'` (HUMAN-only use: filter to languages with missing linters. Agents should NEVER include this in their tool loop.).
