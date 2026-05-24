<!-- BEGIN TLDR-AGENT-SKILLS hash:f39b7c01 -->
## tldr-code — Code Exploration Rules

This project has **tldr-code** installed. Agents MUST use `tldr` commands and `tldr-*` skills for all codebase exploration — not shell tools.

### Rule: start the daemon once at session start

Run this **once** when the session begins — not before every command:

```bash
tldr daemon start 2>/dev/null || true
```

The daemon is **per-project** and persists across commands. This is safe to run unconditionally: if already running it exits silently; if not, it starts one. You get ~35× faster queries once it is up.

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

### Allowed exceptions

Shell tools are permitted **only** when:

1. Reading `AGENTS.md` itself or other non-code files (markdown docs, configs) explicitly named by the user.
2. Running validation commands — tests, lint, typecheck, build.
3. `tldr` is unavailable or a `tldr` command fails — say so explicitly before falling back.
4. Applying or verifying an edit in a single already-identified file.

### Available skills — pick by intent

- `tldr-locate-code` — find any symbol, function, or concept by name or description
- `tldr-understand-function` — deep-dive a specific function or method
- `tldr-orient-codebase` — structural overview of the repo
- `tldr-trace-relationships` — follow call chains and cross-file dependencies
- `tldr-trace-data-flow` — trace how data moves through the system
- `tldr-change-impact` — blast radius of a proposed change
- `tldr-architecture` — high-level architecture and module boundaries
- `tldr-runtime` — start/stop daemon, warm caches, view live stats
- `tldr-fix-and-detect` — find bugs, anti-patterns, and duplicates
- `tldr-audit-security` — security vulnerability review
- `tldr-audit-complexity` — complexity hotspots
- `tldr-audit-smells` — code smell detection
- `tldr-audit-coverage` — coverage gaps
- `tldr-audit-api` — API surface analysis
- `tldr-setup-check` — diagnose tldr installation and verify setup
<!-- END TLDR-AGENT-SKILLS -->
