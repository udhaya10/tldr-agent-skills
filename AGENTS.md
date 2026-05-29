# Agent Instructions

This project uses **bd** (beads) for issue tracking. Run `bd prime` for full workflow context.

> **Architecture in one line:** Issues live in a local Dolt database
> (`.beads/dolt/`); cross-machine sync uses `bd dolt push/pull` (a
> git-compatible protocol), stored under `refs/dolt/data` on your git
> remote — separate from `refs/heads/*` where your code lives.
> `.beads/issues.jsonl` is a passive export, not the wire protocol.
>
> See [SYNC_CONCEPTS.md](https://github.com/gastownhall/beads/blob/main/docs/SYNC_CONCEPTS.md)
> for the one-screen overview and anti-patterns (don't treat JSONL as the
> source of truth; don't `bd import` during normal operation; don't
> reach for third-party Dolt hosting before trying the default).

## Quick Reference

```bash
bd ready              # Find available work
bd show <id>          # View issue details
bd update <id> --claim  # Claim work atomically
bd close <id>         # Complete work
bd dolt push          # Push beads data to remote
```

## Non-Interactive Shell Commands

**ALWAYS use non-interactive flags** with file operations to avoid hanging on confirmation prompts.

Shell commands like `cp`, `mv`, and `rm` may be aliased to include `-i` (interactive) mode on some systems, causing the agent to hang indefinitely waiting for y/n input.

**Use these forms instead:**
```bash
# Force overwrite without prompting
cp -f source dest           # NOT: cp source dest
mv -f source dest           # NOT: mv source dest
rm -f file                  # NOT: rm file

# For recursive operations
rm -rf directory            # NOT: rm -r directory
cp -rf source dest          # NOT: cp -r source dest
```

**Other commands that may prompt:**
- `scp` - use `-o BatchMode=yes` for non-interactive
- `ssh` - use `-o BatchMode=yes` to fail instead of prompting
- `apt-get` - use `-y` flag
- `brew` - use `HOMEBREW_NO_AUTO_UPDATE=1` env var

<!-- BEGIN BEADS INTEGRATION v:1 profile:minimal hash:ccf33ec3 -->
## Beads Issue Tracker

This project uses **bd (beads)** for issue tracking. Run `bd prime` to see full workflow context and commands.

### Quick Reference

```bash
bd ready              # Find available work
bd show <id>          # View issue details
bd update <id> --claim  # Claim work
bd close <id>         # Complete work
```

### Rules

- Use `bd` for ALL task tracking — do NOT use TodoWrite, TaskCreate, or markdown TODO lists
- Run `bd prime` for detailed command reference and session close protocol
- Use `bd remember` for persistent knowledge — do NOT use MEMORY.md files

**Architecture in one line:** issues live in a local Dolt DB; sync uses `refs/dolt/data` on your git remote; `.beads/issues.jsonl` is a passive export. See https://github.com/gastownhall/beads/blob/main/docs/SYNC_CONCEPTS.md for details and anti-patterns.

## Session Completion

**When ending a work session**, you MUST complete ALL steps below. Work is NOT complete until `git push` succeeds.

**MANDATORY WORKFLOW:**

1. **File issues for remaining work** - Create issues for anything that needs follow-up
2. **Run quality gates** (if code changed) - Tests, linters, builds
3. **Update issue status** - Close finished work, update in-progress items
4. **PUSH TO REMOTE** - This is MANDATORY:
   ```bash
   git pull --rebase
   bd dolt push
   git push
   git status  # MUST show "up to date with origin"
   ```
5. **Clean up** - Clear stashes, prune remote branches
6. **Verify** - All changes committed AND pushed
7. **Hand off** - Provide context for next session

**CRITICAL RULES:**
- Work is NOT complete until `git push` succeeds
- NEVER stop before pushing - that leaves work stranded locally
- NEVER say "ready to push when you are" - YOU must push
- If push fails, resolve and retry until it succeeds
<!-- END BEADS INTEGRATION -->

<!-- BEGIN TLDR-AGENT-SKILLS hash:4d8951d0 -->
## tldr-code — Code Exploration Rules

This project has **tldr-code** installed. Agents MUST use `tldr` commands and `tldr-*` skills for all codebase exploration — not shell tools.

### Rule: the supervisor daemon is NOT your responsibility

A separate supervisor (`tldr-cli-demon`) manages the daemon lifecycle — start, warm, and embed are all automatic. **Do NOT start, stop, warm, or embed from skills or agent sessions.** If the daemon is not running, the project has not been registered with the supervisor. Tell the user:

> "The tldr daemon is not running for this project. Register it with the supervisor: `cd <project-root> && tldr-ctl init`"

To **check** whether the daemon is running (read-only, always safe):

```bash
tldr daemon status -p "$(pwd)"
```

### Rule: do NOT use shell tools for code exploration

**Do not use** `rg`, `grep`, `find`, `cat`, `sed`, `awk`, or `ls -R` to explore the repository when a `tldr` command or `tldr-*` skill can answer the question.

| Goal | Use |
|---|---|
| "Explore the repo structure" | `tldr-orient-codebase` skill |
| "Find where X is handled" | `tldr-locate-code` skill |
| "Understand this function/file" | `tldr-understand-function` skill |
| "Search for code by concept" | `tldr search "concept"` |
| "Map dependencies or coupling" | `tldr-architecture` skill |
| "Find callers or usages" | `tldr-trace-relationships` skill |
| `grep -r "pattern" src/` | `tldr search "pattern"` |
| `find . -name "*.rs" \| xargs grep "X"` | `tldr find X` |
| `rg --files` | `tldr structure .` |

**Why**: tldr is AST-based (not regex), token-efficient (replaces 3–10 file reads with one query), and ~35× faster when the daemon is warm.

### Required routing — intent to skill

When the user's request matches any of these intents, load the corresponding skill first:

| User intent | Load this skill |
|---|---|
| "Explore the repo" / "orient me" / "give me a tour" | `tldr-orient-codebase` |
| "Find where X is" / "locate this feature/symbol/concept" | `tldr-locate-code` |
| "Explain this function/file" / "understand X" | `tldr-understand-function` |
| "Map the architecture" / "show dependencies/coupling" | `tldr-architecture` |
| "Who calls X?" / "show callers/usages/relationships" | `tldr-trace-relationships` |

### Rule: understand the three performance worlds before choosing a command

tldr-code has three independent performance worlds. The supervisor daemon manages caches for Worlds 1 and 3 automatically:

| World | Commands | Cache | Managed by |
|-------|----------|-------|------------|
| **Graph traversal (Salsa)** | `calls`, `dead`, `hubs`, `impact`, `whatbreaks`, `slice`, `tree`, `structure` | Salsa cache (`tldr warm`) | Supervisor — auto-warms on file changes |
| **BM25 text search** | `search` | None — rescans all files at query time | N/A — scales with file count |
| **Vector semantic search** | `semantic`, `similar` | Vector index (`tldr embed`) | Supervisor — periodic embed refresh |

**Warm health check**: `tldr dead .` — if this returns fast (25ms on a small project, ~1s on a large one), the Salsa cache is live. Do NOT use `tldr search` as a warm health check — it bypasses Salsa entirely.

**If `search` is slow** (e.g. ~5s on a 171-file repo), the fix is to scope to a subdirectory — warm will not help. If `semantic` is slow and the project is registered with the supervisor, the embed cache may still be building — check `tldr-ctl status`.

### Allowed exceptions

Shell tools are permitted **only** when:

1. Reading `AGENTS.md` itself or other non-code files (markdown docs, configs) explicitly named by the user.
2. Running validation commands — tests, lint, typecheck, build.
3. `tldr` is unavailable or a `tldr` command fails — say so explicitly before falling back.
4. Applying or verifying an edit in a single already-identified file.

If using an exception, keep it narrow. Do not use shell tools for broad exploration.

### Available skills — pick by intent

- `tldr-locate-code` — find any symbol, function, or concept by name or description
- `tldr-understand-function` — deep-dive a specific function or method
- `tldr-orient-codebase` — structural overview of the repo
- `tldr-trace-relationships` — follow call chains and cross-file dependencies
- `tldr-trace-data-flow` — trace how data moves through the system
- `tldr-change-impact` — blast radius of a proposed change
- `tldr-architecture` — high-level architecture and module boundaries
- `tldr-runtime` — diagnose daemon state, inspect caches, view live stats
- `tldr-fix-and-detect` — find bugs, anti-patterns, and duplicates
- `tldr-audit-security` — security vulnerability review
- `tldr-audit-complexity` — complexity hotspots
- `tldr-audit-smells` — code smell detection
- `tldr-audit-coverage` — coverage gaps
- `tldr-audit-api` — API surface analysis
- `tldr-setup-check` — diagnose tldr installation and verify setup
<!-- END TLDR-AGENT-SKILLS -->
