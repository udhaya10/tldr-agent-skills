# Lens: Fix detect-vs-repair — family chooser

**The question this lens answers**: "I'm in the fix group — which command actually fits what I'm doing: scanning for bugs, running linters, or trying to patch an error?"

**Toolset**: `tldr bugbot`, `tldr diagnostics`, `tldr fix diagnose`, `tldr fix check`, `tldr fix apply`

**Why a family-chooser lens, why these tools**: The fix group looks like one workflow but is actually **two separate branches** that share a folder. The detection branch (`bugbot`, `diagnostics`) finds problems; the repair branch (`fix diagnose`, `fix check`, `fix apply`) tries to fix specific error texts. The agent-relevant trap is treating `bugbot` as the entry point to a fix loop — it isn't; bugbot only reports, it never repairs. Picking the right branch first, then the right tool inside it, prevents wasted calls and broken automation.

## Decision tree

### Branch 1 — Detection (find problems)

| Input | Goal | Reach for |
|-------|------|-----------|
| A git diff (uncommitted, staged, branch-vs-main) | Bug-gate a commit/PR on changed code only | `tldr bugbot` |
| A source file or directory | Run installed linters/type-checkers and unify their output | `tldr diagnostics` |

### Branch 2 — Repair (act on a known error)

| Input | Goal | Reach for |
|-------|------|-----------|
| Raw error text (compiler/runtime/test output) | Get a structured `{error_code, location, confidence}` JSON for routing or LLM hand-off | `tldr fix diagnose` |
| Source file + error text | Attempt the deterministic-fix registry; emit patched file or LLM-ready diagnosis | `tldr fix apply` |
| Source file + shell test command | Loop test → diagnose → apply → retest, bounded by `--max-attempts` | `tldr fix check` |

## The default

**Default depends on intent — pick the branch first:**

- **Pre-commit or pre-push scan** → `tldr bugbot` (diff-driven, exit 1 on findings)
- **"How healthy is this code right now?"** → `tldr diagnostics` (executes pyright / ruff / tsc / eslint / clippy and normalizes the output)
- **"I have an error text, what is it?"** → `tldr fix diagnose` (parse-only, ~10ms, exit 0 on Low confidence)
- **"I have an error and want the registry to try a deterministic fix"** → `tldr fix apply`
- **"I have a failing test and want the loop to grind"** → `tldr fix check`

## Common mistakes

- **Treating `bugbot` as the entry point to a fix loop.** Bugbot only reports. It will not invoke the fix-registry, will not call an LLM, and will not edit a file. After bugbot exits 1, the next move is `tldr fix diagnose` (parse the error) or `tldr fix check` (loop on the test), not "bugbot again."
- **Reaching for `tldr diagnostics` when `tldr fix diagnose` would do.** Diagnostics EXECUTES installed tools (pyright, tsc, etc.) on source files; fix-diagnose PARSES already-produced error text. If a build already failed and you have the stderr in hand, parsing it is ~10ms; re-running the tool is seconds-to-minutes and pointless.
- **Reaching for `tldr bugbot` for a whole-repo audit.** Bugbot is diff-scoped — it shells out to `git diff` and exits 1 with `"Failed to list uncommitted changes"` outside a git repo. For full-repo audits, use `tldr secure` / `tldr vuln` / the per-analysis commands.
- **Treating `fix apply`'s exit 1 as a failure.** Exit 1 is the COMMON case — it means "I parsed your error but can't deterministically fix it; here is the JSON diagnosis, escalate to a model." The happy path for LLM hand-off is exit 1 + populated JSON, not exit 0.
- **Aborting `bugbot` on first run because it "looks hung."** The first invocation on a new repo silently performs a full-baseline scan (~2 minutes). Subsequent runs are 10–30s. Bake the latency into CI timeouts.
- **Running `tldr fix apply -s buggy.py` interactively without `--error` or `--error-file`.** It implicitly reads stdin and hangs waiting for input. Always pass `--error`, `--error-file`, or `< /dev/null` in scripts.
- **Using `-f sarif` on `tldr diagnostics`.** Rejected with a global format-validator error. The correct flag is `--output sarif` — a different code path. Expect `-f sarif` to look like a tooling bug.
- **Using `-f compact` on `tldr fix check`.** `-f` is `--file` on this subcommand (the local short flag shadows the global). Use `--format compact` long-form; note also that `--format text` is broken and silently emits JSON.

## What this lens captures

The branch split (Detection vs Repair) is the load-bearing distinction. The further split inside Repair — *parse* (`diagnose`) vs *patch* (`apply`) vs *loop* (`check`) — picks the right tool by how much work the agent wants the registry to do.

## What this lens misses

- **What to do AFTER `fix apply` returns Low confidence.** That's an LLM hand-off pattern, not a tool-picking question — covered in a future orchestration doc.
- **Cross-tool sequencing.** `bugbot` finding → `fix diagnose` parse → LLM repair is a real workflow, but the family-chooser frame stops at "which tool, when."
- **Baseline workflows.** `tldr diagnostics --baseline` / `--save-baseline` cuts through technical-debt noise; the snapshot-and-compare pattern deserves its own orchestration treatment.

## Pair with

- *(future)* `fix-loop-orchestration.md` — the full bugbot → diagnose → apply → LLM sequencing
- `change-impact-family-chooser.md` *(future)* — pre-commit hook design across bugbot, change-impact, and whatbreaks

## Sources

- `research/tool-cards/fix/bugbot.md`
- `research/tool-cards/fix/diagnostics.md`
- `research/tool-cards/fix/fix-diagnose.md`
- `research/tool-cards/fix/fix-apply.md`
- `research/tool-cards/fix/fix-check.md`
