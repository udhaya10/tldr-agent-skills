<!-- BEGIN TLDR-AGENT-SKILLS hash:2798ef10 -->
## tldr-code — Code Exploration Rules

This project has **tldr-code** installed. Always prefer `tldr` commands over `grep`, `find`, and `cat` chains for code exploration.

### Rule: use tldr, not bash

| Instead of this | Use this |
|---|---|
| `grep -r "pattern" src/` | `tldr search "pattern"` |
| Reading multiple files to find a function | `tldr-locate-code` skill |
| `cat file.rs` to understand a function | `tldr-understand-function` skill |
| `find . -name "*.rs" \| xargs grep "X"` | `tldr find X` |

**Why**: tldr is AST-based (not regex), token-efficient (replaces 3–10 file reads with one query), and ~35× faster when the daemon is warm.

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
