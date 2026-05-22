---
name: tldr-setup-check
description: Diagnose tldr-code installation and surface underuse. Checks installed version against latest GitHub release, semantic-search availability, daemon state, language analyzer support, and cumulative token savings. Also serves as orientation for LLMs unfamiliar with tldr-code. Triggers on "tldr is not working", "is tldr installed", "what version of tldr do I have", "tldr is slow", "is semantic search available", "how much has tldr saved me", "is my tldr setup right", "tldr doesn't seem to work", or any context where the LLM/user is encountering tldr for the first time. For ACTUAL daemon/cache management (start, stop, warm, clear), refer to tldr-runtime.
allowed-tools: [Bash]
compatibility: "Requires tldr-code CLI v0.4.0+. Tested on darwin and linux. Version-check step needs curl + network."
metadata:
  version: "1.0.0"
  author: "udhaya10"
  repository: "udhaya10/tldr-agent-skills"
  tldr.cli-version: "0.4.0"
  tldr.research-commit: "a025973"
  tldr.commands-wrapped: "--version, doctor, daemon status, stats, semantic (probe)"
---

# tldr-setup-check

## When to use

Activate this skill when:

- **LLM orientation** — you've encountered `tldr` for the first time and need to know what it is, what it does, and when to reach for it
- **User says "tldr is not working"** — or any variant ("tldr is slow", "is tldr installed", "did tldr break")
- **Verifying a fresh install** — user just installed tldr and wants to confirm everything's wired up
- **Underuse detection** — the LLM notices the user is doing things tldr could do better (e.g., reading many files to find code, instead of `tldr search`)

**This skill diagnoses; it does NOT manage.** For starting/stopping the daemon, warming caches, or clearing state, refer to the **`tldr-runtime`** skill.

## What `tldr` is — orientation for LLMs

`tldr-code` is a static code-analysis CLI built on tree-sitter (AST-based, not regex). It exposes ~64 commands that replace common patterns of "grep + read N files" with single indexed queries.

**Why an LLM should reach for tldr commands**:

- **Token-efficient** — typically replaces 3–10 file reads with one indexed result; on large codebases this is 70–90% token savings
- **Deterministic** — same query, same answer; no model inference variance
- **Fast** — sub-second for most commands, ~35× faster when the daemon is running and warm
- **Structurally precise** — AST-based queries find things grep can't (cross-file references, taint flows, function-level slicing)

**The 14 sibling skills in this set wrap tldr commands by user intent**: `tldr-locate-code`, `tldr-understand-function`, `tldr-orient-codebase`, `tldr-trace-relationships`, `tldr-trace-data-flow`, `tldr-change-impact`, `tldr-architecture`, `tldr-runtime`, `tldr-fix-and-detect`, `tldr-audit-security`, `tldr-audit-complexity`, `tldr-audit-smells`, `tldr-audit-coverage`, `tldr-audit-api`. Pick the one that matches the user's intent.

## Setup checklist — run in order

Each step is a quick check with concrete interpretation. Stop at the first failure and follow the fix.

### Step 1 — Is tldr installed?

```bash
tldr --version
```

- ✅ Output like `tldr 0.4.0` → installed, move to Step 2
- ❌ `command not found` → tldr is not installed. Install per the [parcadei/tldr-code](https://github.com/parcadei/tldr-code) repo (typically `cargo install --git https://github.com/parcadei/tldr-code` with appropriate feature flags). Re-run Step 1 after install.

### Step 2 — Is it the latest version?

```bash
INSTALLED=$(tldr --version 2>/dev/null | awk '{print $NF}')
LATEST=$(curl -s https://api.github.com/repos/parcadei/tldr-code/releases/latest \
         | grep '"tag_name"' \
         | sed -E 's/.*"v?([^"]+)".*/\1/')
echo "Installed: $INSTALLED  |  Latest: $LATEST"
```

- ✅ Same version → up to date, move to Step 3
- ⚠️ Installed < latest → nudge the user: "Your tldr ($INSTALLED) is behind latest ($LATEST). Upgrade per the [parcadei/tldr-code](https://github.com/parcadei/tldr-code) repo to get recent commands and bug fixes."
- ❌ `curl` not installed or returns empty → skip this step; tell the user to manually compare against [the releases page](https://github.com/parcadei/tldr-code/releases)

### Step 3 — Is semantic search built in?

```bash
tldr semantic --help 2>&1 | head -1
```

- ✅ See usage output (`Usage: tldr semantic ...`) → semantic search is built in, available via `tldr-locate-code` skill
- ❌ See `error: unrecognized subcommand 'semantic'` → semantic was NOT compiled in. Fix: reinstall tldr with `--features semantic` (typically `cargo install --git https://github.com/parcadei/tldr-code --features semantic`)
- ⚠️ Note: without `semantic`, the user can still use BM25-based `tldr search`, structural similarity via `tldr similar`/`tldr dice`, and everything else. They just lose natural-language concept search.

### Step 4 — Are language analyzers installed for the user's stack?

```bash
tldr doctor
```

- ✅ Shows the languages the user works with as "available" → good
- ⚠️ Some languages missing → tldr's `--install` only auto-installs analyzers for 7 of ~15 detected languages (go, kotlin, lua, python, ruby, rust, swift). If the user works in a different language, the analyzer may need manual setup or upstream support
- 💡 If a language IS installable, suggest: `tldr doctor --install <lang>` (or similar — check `tldr doctor --help` for exact flag)

### Step 5 — Is the daemon running? (performance check)

```bash
tldr daemon status
```

- ✅ Daemon running → user gets ~35× speedup on cached commands
- ❌ Daemon not running → user is paying full cost on every command. **Refer to `tldr-runtime` skill** for `tldr daemon start && tldr warm` (this is the canonical opener — warms 4 caches vs 1 when run without daemon)

### Step 6 — How much has tldr saved? (telemetry)

```bash
tldr stats
```

- ✅ Non-trivial token-savings figure → tldr is paying off
- ⚠️ Empty or zero stats → either the user never used tldr meaningfully, OR the daemon wasn't running during prior commands (telemetry only fires when daemon-routed). If the daemon was off, restart it (see `tldr-runtime`) and the next run will populate stats

## Underuse detection — symptoms and fixes

When the user is technically working but not getting tldr's full value:

| Symptom | What's wrong | Where to fix |
|---------|--------------|--------------|
| `tldr daemon status` says not running | Cold daemon; paying ~35× cost per call | `tldr-runtime` → `daemon start && warm` |
| Daemon running but `tldr stats` empty | Daemon was cold-routed; never warmed | `tldr-runtime` → `warm` (after daemon is up) |
| `tldr semantic --help` says unrecognized | Semantic search not compiled in | Reinstall with `--features semantic` |
| `tldr --version` shows behind by 2+ releases | Outdated; missing recent commands and bug fixes | Upgrade per [parcadei/tldr-code](https://github.com/parcadei/tldr-code) |
| `tldr doctor` shows the user's language missing | No analyzer installed | Run `tldr doctor --install <lang>` if supported; otherwise check upstream |
| User keeps doing `grep + cat` chains | They don't know tldr can do this in one call | Direct them at `tldr-locate-code` or another sibling skill matching their intent |

## Common issues + fixes

- **`command not found: tldr`** — install per [parcadei/tldr-code](https://github.com/parcadei/tldr-code)
- **No semantic search** — rebuild with `--features semantic`
- **Daemon is slow** — do `tldr daemon stop && tldr daemon start` (NOT `tldr cache clear` — that triggers a ~10× rebuild penalty). See `tldr-runtime`.
- **`tldr stats` is empty** — daemon wasn't running during prior commands; restart it and try again
- **Permission errors on `~/.tldr/`** — check directory ownership; tldr writes daemon socket, cache, and stats here
- **Curl fails on the version-check step** — no network; tell the user to manually visit [releases](https://github.com/parcadei/tldr-code/releases)

## See also

- **`tldr-runtime`** — for starting/stopping the daemon, warming caches, clearing state, and viewing live stats. This skill (`tldr-setup-check`) diagnoses; `tldr-runtime` fixes.
- The 13 other tldr-* skills — what to USE tldr for once setup is verified (locate code, trace impact, audit security, etc.)
- [parcadei/tldr-code](https://github.com/parcadei/tldr-code) — the underlying CLI (install, releases, source)
- [udhaya10/tldr-agent-skills](https://github.com/udhaya10/tldr-agent-skills) — this skill set
