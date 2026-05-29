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
