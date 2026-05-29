---
name: tldr-runtime
description: Diagnose tldr's runtime state — daemon health, Salsa cache counters, on-disk cache size, token-savings telemetry, and environment checks. Reach for this when tldr feels slow, when checking whether the daemon is running, or when inspecting cache health. NOT for starting, stopping, warming, or embedding — the supervisor daemon (tldr-cli-demon) owns the full lifecycle. Triggers on "is the daemon running", "why is tldr slow", "check tldr cache", "tldr stats", "tldr doctor".
allowed-tools: [Bash]
compatibility: "Requires tldr-code CLI v0.4.0+. Tested on darwin and linux."
metadata:
  version: "2.0.0"
  author: "udhaya10"
  repository: "udhaya10/tldr-agent-skills"
  tldr.cli-version: "0.4.0"
  tldr.research-commit: "a025973"
  tldr.commands-wrapped: "cache, daemon status, stats, doctor"
---

# tldr-runtime

## When to use

Use this skill whenever the **subject is tldr itself**, not the code under analysis. The intent space: checking daemon health, inspecting Salsa cache counters, viewing on-disk cache size, surfacing token-savings telemetry, and verifying the local toolchain environment.

This is the **diagnostics skill**. It tells you whether tldr's infrastructure is healthy. It does NOT manage that infrastructure — the supervisor daemon (`tldr-cli-demon`) owns the full lifecycle: start, stop, warm, and embed are all automatic.

**If the daemon is not running**, the project has not been registered with the supervisor. Tell the user:

> "The tldr daemon is not running for this project. Register it with the supervisor: `cd <project-root> && tldr-ctl init`"

If you're trying to analyze, search, trace, or audit code → leave for the appropriate sibling skill. If you're trying to diagnose tldr itself → you're in the right place.

## The decision — which diagnostic to use

| You want to... | Reach for |
|----------------|-----------|
| Check whether the daemon is running + Salsa hit/miss counters | `tldr daemon status -p "$(pwd)"` |
| See how much disk the cache uses | `tldr cache stats` |
| See aggregate token savings across all sessions | `tldr stats` |
| Check whether language toolchains for `diagnostics` are installed | `tldr doctor` |
| Verify the Salsa cache is actually warm | `tldr dead .` (warm health test) |

## Daemon health check

```bash
tldr daemon status -p "$(pwd)"
```

> **Multi-daemon caveat:** bare `tldr daemon status` and `--project .` fail with "multiple daemons running" when >1 daemon exists in the registry. Always use `-p "$(pwd)"` (absolute path). This only affects `status` — other subcommands canonicalize `.` correctly.

**Interpreting the output:**

- **Running with non-zero Salsa counters** → daemon is live and routing commands, ~35x speedup active
- **Running but Salsa counters are 0/0** → daemon is up but no commands have routed through it yet. This is normal at the start of a session — run a graph-traversal command like `tldr dead .` to generate traffic, then re-check
- **Not running** → the supervisor has not been set up for this project. Tell the user to register: `tldr-ctl init`

## Warm health test

Use `tldr dead .` (not `tldr search`) to verify the Salsa cache is warm:

```bash
tldr dead .
# Warm: ~25ms on a 9-file project, ~1s on a 171-file project
# Cold or broken: 10× slower or hangs
```

`tldr search` bypasses Salsa entirely — using it as a warm test will always "pass" regardless of warm state.

## Three performance worlds

tldr-code has three independent performance worlds. The supervisor daemon manages caches for Worlds 1 and 3 automatically:

| World | Commands | Cache | Managed by |
|-------|----------|-------|------------|
| **Graph traversal (Salsa)** | `calls`, `dead`, `hubs`, `impact`, `whatbreaks`, `slice`, `tree`, `structure` | Salsa cache (`tldr warm`) | Supervisor — auto-warms on file changes |
| **BM25 text search** | `search` | None — rescans all files at query time | N/A — scales with file count |
| **Vector semantic search** | `semantic`, `similar` | Vector index (`tldr embed`) | Supervisor — periodic embed refresh |

**If `search` is slow** (e.g. ~5s on a 171-file repo), the fix is to scope to a subdirectory — warm will not help. If `semantic` is slow and the project is registered with the supervisor, the embed cache may still be building — check `tldr-ctl status`.

**Verified embed benchmarks** (Stock-Monitor, 373 meaningful source files / ~176K LOC, Apple Silicon ARM64):

| Scope | Chunks | Model | First-run time |
|---|---|---|---|
| `.` (full repo incl. dist artifacts) | 17,188 | arctic-m | **36.46 min** |
| `backend/` only | 1,397 | arctic-m | ~3 min (est.) |
| `webui/src/` only | ~2,000 | arctic-m | ~4 min (est.) |

After the index is built, subsequent `tldr semantic` queries complete in **~260 ms**. Re-running `tldr embed` on an unchanged path completes in **~2.5 seconds** (all cache hits).

## Tool reference

> **Command guardrail**: Only invoke the exact subcommands documented below. Do **not** invent or guess command names. If uncertain whether a command exists, run `tldr --help` before proceeding.

### `tldr daemon status` — CHECK the daemon's running state

Diagnostic query for the background Salsa-cache process. Shows running state, uptime, and Salsa hit/miss/invalidation/recomputation counters.

**Usage**:
```bash
tldr daemon status -p "$(pwd)"
```

**Output**: JSON with running-state, uptime, and Salsa counters. Every subcommand has a different top-level schema — agents schema-validating output must branch on the subcommand name.

**Other useful daemon subcommands** (read-only diagnostics):
```bash
tldr daemon list     # list all registered daemons across projects
```

**Footguns**:
- Bare `status` and `--project .` fail with "multiple daemons running (N); use --project <abs-path>" when >1 daemon exists. Always pass absolute path.
- Salsa counters only appear when the daemon is running. When it's down, `cache stats` returns only file count and disk bytes.

---

### `tldr cache` — INSPECT the on-disk Salsa store

See how many MB of cache files a project has accumulated.

**Usage**:
```bash
tldr cache stats [--project <path>]
```

**Output**: File count, total bytes, and human-readable size. When the daemon is up, also includes Salsa hit/miss/invalidation counters.

**When NOT to use**: As a remedy for "my query feels stale." The right diagnostic is `tldr daemon status -p "$(pwd)"` to check Salsa counters, not `cache stats`.

**Footguns**:
- `tldr cache clear` is destructive — it triggers a ~10× slowdown on every subsequent query while the on-disk store rebuilds from scratch. **Do not run `cache clear` unless the user explicitly asks for it.** If the user suspects stale cache, the supervisor will handle re-warming automatically.
- `cache clear` returns exit 0 with `"No cache directory found"` on a bad path — a wrong directory looks identical to a successful wipe.

---

### `tldr stats` — TELEMETRY for aggregate token savings

Global usage summary that aggregates token savings across every daemon-tracked invocation.

**Usage**:
```bash
tldr stats
```

**Output**: When populated, JSON with `total_invocations`, `estimated_tokens_saved`, `raw_tokens_total`, `tldr_tokens_total`, and `savings_percent`. When empty, JSON with `message` and `next_steps`.

**Known bug in v0.4.0**: `tldr stats` always returns empty regardless of daemon state. Even commands that DO route through the daemon never write to `~/.tldr/stats.jsonl`. Additionally, `smells`, `complexity`, `context`, `slice`, `search`, `semantic` and most audit/metric commands bypass the daemon entirely. **Do not use `tldr stats` as a health signal in v0.4.0 — use `tldr daemon status` Salsa counters instead.** Track both bugs at [parcadei/tldr-code](https://github.com/parcadei/tldr-code).

---

### `tldr doctor` — ENVIRONMENT check for `diagnostics` toolchains

Environment check for whether the type-checkers and linters that back `tldr diagnostics` are installed.

**Usage**:
```bash
tldr doctor [--install <LANG>]
```

**Output**: JSON object keyed by language name (~15 languages), each with `type_checker` and `linter` sub-objects reporting `installed`, the absolute path when present, and an `install` hint string when missing.

**Killer detail**: Only 7 of the ~15 detected languages have working `--install` support (go, kotlin, lua, python, ruby, rust, swift). The other 8 return exit 1 `"No auto-install available"` — read the `install` hint string and run it manually.

## Known bugs — v0.4.0

> **Bug 1 — Partial routing.** Only these commands route through the daemon (increment Salsa counters): `tree`, `structure`, `extract`, `calls`, `impact`, `dead`, `imports`, `importers`. These bypass the daemon entirely: `smells`, `complexity`, `context`, `slice`, `search`, `semantic`, and most audit/metric commands.
>
> **Bug 2 — Stats recording broken.** Even when commands DO route through the daemon (Salsa counters increment), `~/.tldr/stats.jsonl` is never written. `tldr stats` will always return "No usage recorded yet" in v0.4.0 regardless of daemon state or routing. These are two independent bugs.
>
> Track both at [parcadei/tldr-code](https://github.com/parcadei/tldr-code).

## Common mistakes

- **Trying to start, stop, warm, or embed from this skill.** The supervisor daemon (`tldr-cli-demon`) owns the full lifecycle. If the daemon isn't running, the project needs to be registered: `tldr-ctl init`.
- **Using bare `tldr daemon status` or `--project .` when multiple daemons are running.** With >1 daemon in the registry, both fail with "multiple daemons running (N); use --project <abs-path>." Always use `tldr daemon status -p "$(pwd)"`.
- **Reaching for `tldr cache clear` when you suspect stale cache.** Clear is destructive and triggers a ~10× slowdown. The supervisor will re-warm automatically; if you must intervene, tell the user to check `tldr-ctl status`.
- **Expecting `tldr warm` to speed up `search` or `semantic`.** Warm builds the Salsa call graph cache, which powers ONLY graph-traversal commands. `search` runs BM25 over all files at query time (e.g. ~5s for 171 files). `semantic` pays a flat ~4.3s model cold-start per call regardless of warm state — to check semantic readiness, verify the embed cache exists: `ls ~/.tldr/embeddings/ 2>/dev/null | head -3`.
- **Expecting Salsa hit/miss counters from `tldr cache stats` when the daemon is down.** Salsa counters only appear when the daemon is running.
- **Reading an empty `tldr stats` as a configuration problem in v0.4.0.** In v0.4.0, `tldr stats` always returns empty — this is an upstream bug, not a setup issue.
- **Using `tldr doctor` to fix a per-call `diagnostics` failure.** When `tldr diagnostics` exits 60, it already prints the exact install hint. Reach for `doctor` only for the full multi-language status board.
- **Using this skill to analyze code.** This skill diagnoses tldr's runtime. For code search, tracing, audit, etc., use the appropriate sibling skill.

## See also

- **`tldr-setup-check`** — full installation diagnostic (version, semantic support, language analyzers, AGENTS.md hash injection). This skill (`tldr-runtime`) checks daemon and cache health; `tldr-setup-check` checks the broader installation.
- **`tldr-cli-demon`** — the supervisor that manages daemon start/stop, warm, and embed automatically. See [tldr-cli-demon](https://github.com/udhaya10/tldr-cli-demon).
- The 13 other tldr-* skills — what to USE tldr for once the runtime is healthy.
