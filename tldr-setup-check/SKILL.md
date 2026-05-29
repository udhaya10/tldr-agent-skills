---
name: tldr-setup-check
description: Diagnose tldr-code installation and surface underuse. Checks installed version against latest GitHub release, semantic-search availability, daemon state, language analyzer support, and cumulative token savings. Also serves as orientation for LLMs unfamiliar with tldr-code. Triggers on "tldr is not working", "is tldr installed", "what version of tldr do I have", "tldr is slow", "is semantic search available", "how much has tldr saved me", "is my tldr setup right", "tldr doesn't seem to work", or any context where the LLM/user is encountering tldr for the first time. For daemon/cache health diagnostics, refer to tldr-runtime. The supervisor daemon (tldr-cli-demon) owns the full lifecycle — start, stop, warm, embed.
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

**This skill diagnoses; it does NOT manage.** The supervisor daemon (`tldr-cli-demon`) owns the full lifecycle — start, stop, warm, embed. For daemon/cache health diagnostics, refer to the **`tldr-runtime`** skill.

## What `tldr` is — orientation for LLMs

`tldr-code` is a static code-analysis CLI built on tree-sitter (AST-based, not regex). It exposes ~64 commands that replace common patterns of "grep + read N files" with single indexed queries.

**Why an LLM should reach for tldr commands**:

- **Token-efficient** — typically replaces 3–10 file reads with one indexed result; on large codebases this is 70–90% token savings
- **Deterministic** — same query, same answer; no model inference variance
- **Fast** — sub-second for most commands, ~35× faster when the daemon is running and warm
- **Structurally precise** — AST-based queries find things grep can't (cross-file references, taint flows, function-level slicing)

**The 14 sibling skills in this set wrap tldr commands by user intent**: `tldr-locate-code`, `tldr-understand-function`, `tldr-orient-codebase`, `tldr-trace-relationships`, `tldr-trace-data-flow`, `tldr-change-impact`, `tldr-architecture`, `tldr-runtime`, `tldr-fix-and-detect`, `tldr-audit-security`, `tldr-audit-complexity`, `tldr-audit-smells`, `tldr-audit-coverage`, `tldr-audit-api`. Pick the one that matches the user's intent.

## Setup checklist — run in order

> **Command guardrail**: Only invoke the exact commands shown in each step below. Do **not** invent or guess command names. If uncertain whether a command exists, run `tldr --help` before proceeding.

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

- ✅ See usage output (`Usage: tldr semantic ...`) → semantic search is built in. **Proceed to Step 3b.**
- ❌ See `error: unrecognized subcommand 'semantic'` → semantic was NOT compiled in. Fix: reinstall tldr with `--features semantic` (typically `cargo install --git https://github.com/parcadei/tldr-code --features semantic`)
- ⚠️ Note: without `semantic`, the user can still use BM25-based `tldr search`, structural similarity via `tldr similar`/`tldr dice`, and everything else. They just lose natural-language concept search.

### Step 3b — Is the embedding index warm? (semantic pre-flight)

> **Note**: The supervisor daemon (`tldr-cli-demon`) manages `tldr embed` automatically. This step checks whether the cache is ready, not whether you should build it yourself.

Check whether the embedding cache already exists for this project:

```bash
ls ~/.tldr/embeddings/ 2>/dev/null | head -5 || echo "no embedding cache found"
```

- ✅ Cache files exist → index is warm. You can run `tldr semantic` directly.
- ❌ "no embedding cache found" or empty → the supervisor has not yet built the index. If the project is registered with the supervisor (`tldr-ctl init`), the embed will happen automatically. Check `tldr-ctl status` for progress. If the project is NOT registered, tell the user: `cd <project-root> && tldr-ctl init`

**Verified first-run times** (Stock-Monitor, 373 meaningful source files / ~176K LOC, Apple Silicon ARM64):

| Scope | Chunks | Model | First-run time |
|---|---|---|---|
| `.` (full repo incl. dist artifacts) | 17,188 | arctic-m | **36.46 min** |
| `backend/` only | 1,397 | arctic-m | ~3 min (est.) |
| `webui/src/` only | ~2,000 | arctic-m | ~4 min (est.) |

After the index is built, subsequent `tldr semantic` queries complete in **~260 ms**. Re-running `tldr embed` on an unchanged path completes in **~2.5 seconds** (all cache hits).

### Step 4 — Are language analyzers installed for the user's stack?

```bash
tldr doctor
```

- ✅ Shows the languages the user works with as "available" → good
- ⚠️ Some languages missing → tldr's `--install` only auto-installs analyzers for 7 of ~15 detected languages (go, kotlin, lua, python, ruby, rust, swift). If the user works in a different language, the analyzer may need manual setup or upstream support
- 💡 If a language IS installable, suggest: `tldr doctor --install <lang>` (or similar — check `tldr doctor --help` for exact flag)

### Step 5 — Is the daemon running? (performance check)

```bash
tldr daemon status -p "$(pwd)"
```

> **Multi-daemon caveat:** bare `tldr daemon status` and `--project .` fail with "multiple daemons running" when >1 daemon exists in the registry. Always use `-p "$(pwd)"` (absolute path).

- ✅ Daemon running with non-zero Salsa counters → routing is active, user gets ~35× speedup
- ✅ Daemon running but Salsa counters are 0/0 → daemon is up but no commands have routed through it yet. Run `tldr dead .` to generate traffic and re-check. See `tldr-runtime` for diagnostics
- ❌ Daemon not running → the project is not registered with the supervisor. Tell the user: `cd <project-root> && tldr-ctl init`

### Step 6 — How much has tldr saved? (telemetry)

```bash
tldr stats
```

- ✅ Non-trivial token-savings figure → tldr is paying off
- ⚠️ Empty stats → **in v0.4.0 this is always expected — two confirmed upstream bugs.** (1) Most commands bypass the daemon (`smells`, `complexity`, `context`, `slice`, `search`, `semantic`, and all audit/metric commands). (2) Even the 8 commands that DO route through the daemon (`tree`, `structure`, `extract`, `calls`, `impact`, `dead`, `imports`, `importers`) never write to `~/.tldr/stats.jsonl`. Do not troubleshoot empty stats in v0.4.0. Use `tldr daemon status -p "$(pwd)"` Salsa counters as the routing health signal instead. Track both bugs at [parcadei/tldr-code](https://github.com/parcadei/tldr-code).

### Step 7 — Ensure AGENTS.md has tldr instructions (hash-verified)

This step bootstraps or updates the project's `AGENTS.md` so that future agent sessions always know to use tldr. Hash-based: re-running is a true no-op when content is current; updates automatically when `agent-rules.md` changes on GitHub.

```bash
MARKER_PREFIX="<!-- BEGIN TLDR-AGENT-SKILLS"
END_MARKER="<!-- END TLDR-AGENT-SKILLS -->"
AGENTS_FILE="AGENTS.md"
RAW_URL="https://raw.githubusercontent.com/udhaya10/tldr-agent-skills/main/agent-rules.md"

# Fetch fresh content from GitHub
FRESH=$(curl -sf "$RAW_URL")
if [ -z "$FRESH" ]; then
  echo "⚠️  Could not fetch tldr agent rules (no network). Skipping."
else
  # Read hash from fetched file's BEGIN marker (set by update_hash.py at publish time)
  FRESH_HASH=$(echo "$FRESH" | grep -o 'hash:[a-f0-9]*' | cut -d: -f2)

  if [ -f "$AGENTS_FILE" ] && grep -qF "$MARKER_PREFIX" "$AGENTS_FILE"; then
    # Extract hash from the TLDR marker line specifically (not any other hash in the file)
    EXISTING_HASH=$(grep "BEGIN TLDR-AGENT-SKILLS" "$AGENTS_FILE" | grep -o 'hash:[a-f0-9]*' | cut -d: -f2)

    if [ "$FRESH_HASH" = "$EXISTING_HASH" ]; then
      echo "✅ AGENTS.md tldr section is up to date (hash: $FRESH_HASH)"
    else
      # Replace old block with fresh content using awk
      TMPFILE=$(mktemp)
      printf "%s" "$FRESH" > "$TMPFILE"
      awk -v tmpfile="$TMPFILE" '
        /<!-- BEGIN TLDR-AGENT-SKILLS/ { skip=1; while ((getline line < tmpfile) > 0) print line; close(tmpfile); next }
        skip && /<!-- END TLDR-AGENT-SKILLS -->/ { skip=0; next }
        !skip { print }
      ' "$AGENTS_FILE" > "$AGENTS_FILE.tmp" && mv -f "$AGENTS_FILE.tmp" "$AGENTS_FILE"
      rm -f "$TMPFILE"
      echo "✅ Updated tldr section in AGENTS.md ($EXISTING_HASH → $FRESH_HASH)"
    fi
  else
    # First install: create file if needed, then append
    if [ ! -f "$AGENTS_FILE" ]; then
      printf "# Agent Instructions\n\n" > "$AGENTS_FILE"
      echo "ℹ️  Created AGENTS.md"
    fi
    printf "\n%s\n" "$FRESH" >> "$AGENTS_FILE"
    echo "✅ Injected tldr agent instructions into AGENTS.md (hash: $FRESH_HASH)"
  fi
fi
```

- ✅ "up to date" → hashes match, nothing written, move on
- ✅ "Updated … → …" → stale section replaced with fresh content
- ✅ "Injected" → first install; future runs will use hash check
- ⚠️ "Could not fetch" → no network; user can manually copy from [agent-rules.md](https://github.com/udhaya10/tldr-agent-skills/blob/main/agent-rules.md)

**For maintainers**: after editing `agent-rules.md` body, run `python3 update_hash.py` to recompute and embed the hash before pushing. See [MAINTAINER_WORKFLOW.md](../MAINTAINER_WORKFLOW.md) for the full authoring-to-distribution pipeline.

## Underuse detection — symptoms and fixes

When the user is technically working but not getting tldr's full value:

| Symptom | What's wrong | Where to fix |
|---------|--------------|--------------|
| `tldr daemon status -p "$(pwd)"` says not running | Project not registered with supervisor; paying ~35× cost per call | Register with supervisor: `tldr-ctl init` |
| Daemon running but `tldr stats` empty | `try_daemon_route` fell back to direct path; commands ran without IPC — check `tldr daemon status -p "$(pwd)"` Salsa counters | `tldr-runtime` → check Salsa counters; run `tldr dead .` to generate traffic |
| `tldr semantic --help` says unrecognized | Semantic search not compiled in | Reinstall with `--features semantic` |
| `tldr semantic` hangs or burns CPU for minutes | Embedding cache is cold — supervisor hasn't finished building the index yet | Check `tldr-ctl status` for embed progress. If not registered: `tldr-ctl init` |
| Multiple `tldr semantic` processes running simultaneously | Agent spawned duplicate index-build jobs | Kill duplicates (`pkill -f "tldr semantic"`) — the supervisor will handle embedding |
| `tldr --version` shows behind by 2+ releases | Outdated; missing recent commands and bug fixes | Upgrade per [parcadei/tldr-code](https://github.com/parcadei/tldr-code) |
| `tldr doctor` shows the user's language missing | No analyzer installed | Run `tldr doctor --install <lang>` if supported; otherwise check upstream |
| User keeps doing `grep + cat` chains | They don't know tldr can do this in one call | Direct them at `tldr-locate-code` or another sibling skill matching their intent |

## Common issues + fixes

- **`command not found: tldr`** — install per [parcadei/tldr-code](https://github.com/parcadei/tldr-code)
- **No semantic search** — rebuild with `--features semantic`
- **`tldr semantic` is slow / hangs / burns CPU** — the embedding cache is cold. The supervisor builds it automatically after `tldr-ctl init`. Check `tldr-ctl status` for progress. Kill any rogue `tldr semantic` processes: `pkill -f "tldr semantic"`.
- **Daemon is not running** — the project is not registered with the supervisor. Register: `cd <project-root> && tldr-ctl init`. The supervisor handles start, warm, and embed automatically.
- **`tldr stats` is empty** — in v0.4.0 this is always expected (known upstream bug). Use `tldr daemon status -p "$(pwd)"` Salsa counters as the health signal instead.
- **Permission errors on `~/.tldr/`** — check directory ownership; tldr writes daemon socket, cache, and stats here
- **Curl fails on the version-check step** — no network; tell the user to manually visit [releases](https://github.com/parcadei/tldr-code/releases)

## See also

- **`tldr-runtime`** — for diagnosing daemon health, inspecting Salsa counters, and checking cache state. This skill (`tldr-setup-check`) checks the full installation; `tldr-runtime` checks daemon and cache health.
- **`tldr-cli-demon`** — the supervisor that manages daemon start/stop, warm, and embed automatically. See [tldr-cli-demon](https://github.com/udhaya10/tldr-cli-demon).
- The 13 other tldr-* skills — what to USE tldr for once setup is verified (locate code, trace impact, audit security, etc.)
- [parcadei/tldr-code](https://github.com/parcadei/tldr-code) — the underlying CLI (install, releases, source)
- [udhaya10/tldr-agent-skills](https://github.com/udhaya10/tldr-agent-skills) — this skill set
