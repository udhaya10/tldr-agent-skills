---
name: tldr-fix-and-detect
description: Find bugs in code or apply deterministic fixes — scan a git diff for pre-commit/PR gates, run installed linters/type-checkers and unify their output, parse raw error text into structured JSON, or try a registry-based auto-fix on a known error pattern. Triggers on "find bugs", "fix this bug", "auto-fix", "lint check", "diagnose errors", "is this code OK", "review uncommitted changes", "pre-commit check", "apply patches", "what's wrong with this file", "parse this error", "loop test until it passes".
allowed-tools: [Bash]
---

# tldr-fix-and-detect

## When to use

Use this skill when the user wants to **find what's actively broken** in code OR **attempt a mechanical fix on a known error**. This covers two distinct workflows that share the `tldr fix` folder but are not the same job:

- **Detection** — "is this code OK", "find bugs in my changes", "lint this", "review uncommitted code before I push"
- **Repair** — "I have this error text, what is it", "try to auto-fix this", "loop until the test passes"

The discriminator vs sibling skills:

- For tracing how a buggy VALUE flows through code (not parsing an error text) → see `tldr-trace-data-flow`
- For "what should I clean up someday" (smells, debt, hotspots) rather than "what's actively broken" → see `tldr-audit-smells`
- For known security vulnerabilities and taint analysis → see `tldr-audit-security`
- For "what will break if I change this" (pre-change blast radius) → see `tldr-change-impact`

If you don't have either a git diff to scan, a source path to lint, or an error text to parse, you're in the wrong skill.

## The decision — which tool to use

The first cut is **which branch you're in**. Detection and Repair don't compose linearly; pick one based on what you have in hand.

### Branch 1 — Detection (find problems)

| You have... | And want... | Reach for |
|-------------|-------------|-----------|
| A git diff (uncommitted, staged, or branch-vs-main) | Bug-gate a commit/PR on changed code only | `tldr bugbot` |
| A source file or directory | Run installed linters/type-checkers and unify their output | `tldr diagnostics` |

### Branch 2 — Repair (act on a known error)

| You have... | And want... | Reach for |
|-------------|-------------|-----------|
| Raw error text (compiler/runtime/test stderr) | Structured `{error_code, location, confidence}` JSON for routing or LLM hand-off | `tldr fix diagnose` |
| A source file + an error text | Try the deterministic-fix registry; emit patched file OR an LLM-ready diagnosis | `tldr fix apply` |
| A source file + a shell test command | Loop test → diagnose → apply → retest, bounded by `--max-attempts` | `tldr fix check` |

**Defaults by intent:**

- **Pre-commit / pre-push / PR scan** → `tldr bugbot` (diff-driven, exit 1 on findings — drop-in for hooks and CI)
- **"How healthy is this code right now?"** → `tldr diagnostics` (executes pyright/ruff/tsc/eslint/clippy and normalizes the output)
- **"I have an error text, what is it?"** → `tldr fix diagnose` (parse-only, ~10ms, exit 0 even on Low confidence)
- **"I have an error and want the registry to try a deterministic patch"** → `tldr fix apply`
- **"I have a failing test and want the loop to grind on it"** → `tldr fix check`

**Critical: `bugbot` is NOT a fix-loop orchestrator.** It only reports findings. After bugbot exits 1, the next move is `tldr fix diagnose` (parse the error) or `tldr fix check` (loop on the test), NOT "bugbot again."

## Tool reference

### `tldr bugbot` — diff-driven bug detector for commit/PR gates

Git-diff-driven bug detector that runs commodity linters (L1) and tldr's own analyses (L2) on uncommitted or staged changes, then gates the commit/CI on findings.

**Why reach for it**:
- One command replaces invoking clippy, cargo-audit, ruff, pyright, etc. plus tldr's own taint/resources/complexity checks on the diff
- Findings cause exit 1 by default — drop-in for `tldr bugbot check && git push` or pre-merge CI gates
- Splits results into `summary.l1_findings` (commodity tool noise) and `l2_findings` (tldr-specific deep findings), so agents can prioritize
- `--base-ref` and `--staged` let it target any diff window — branch-vs-main, staged-only for pre-commit hooks, last commit, etc.

**When to use**:
- Pre-commit or pre-push hook needs to flag bugs in changed code without re-scanning the whole repo
- CI step that should fail when uncommitted/staged changes introduce findings
- Reviewing a feature branch's diff against `main` (`--base-ref main`)

**Usage**:
```bash
tldr bugbot [check] [--base-ref <ref>] [--staged] [--output json|sarif] [path]
```

**Output**: A JSON report with the diffed file list (absolute paths), every finding with severity and location, a summary that breaks down L1 vs L2 counts, and `notes: ["no_changes_detected"]` as the canonical "nothing to do" signal when the diff is empty.

**Killer detail**: The first invocation on a new repo silently performs a full-baseline scan that takes ~2 minutes on a real codebase — subsequent runs are 10–30s. Agents that abort on "looks hung" will lose the baseline; **bake the latency into CI timeouts.**

**Other footguns**:
- Outside a git repo, bugbot exits 1 with `"Failed to list uncommitted changes"` — it shells out to `git diff` and cannot operate without one
- Bugbot ONLY reports; it never invokes the fix-registry, never calls an LLM, never edits a file — the next step after a finding is a Repair-branch tool, not bugbot again

---

### `tldr diagnostics` — execute and unify installed linters/type-checkers

Runs the project's installed type checkers and linters (pyright, ruff, tsc, eslint, clippy, etc.) on a path and normalizes their output into one unified JSON schema.

**Why reach for it**:
- One report covers every diagnostic tool installed for the language — no per-tool JSON parsing
- `--output sarif` emits SARIF 2.1.0 for GitHub/GitLab Code Scanning; `--output github-actions` emits inline `::error::`/`::warning::` workflow commands (the only `tldr` command that does)
- `--baseline` / `--save-baseline` enables "show only NEW issues since last snapshot" — kills the technical-debt firehose
- Distinct exit codes (60 = no tools installed, 61 = all tools failed) make tool-availability problems debuggable

**When to use**:
- Running type-check + lint on a file or directory and want one schema downstream
- Producing SARIF for code-scanning dashboards or PR annotations in CI
- Comparing the current state to a saved baseline to surface only new findings

**Usage**:
```bash
tldr diagnostics <path> [--output json|sarif|github-actions] [--baseline <file>] [--save-baseline <file>]
```

**Output**: A JSON record with the full list of normalized diagnostics (file, line, severity, code, source tool, message, doc URL), a summary by severity, and a `tools_run[]` array showing each tool's name, version, success, duration, and finding count.

**Killer detail**: `-f sarif` is REJECTED with a global format-validator error, but `--output sarif` IS supported — they're two different code paths. **Always reach for `--output sarif`** when targeting SARIF consumers; `-f sarif` will exit 1 and look like a tooling bug.

---

### `tldr fix diagnose` — parse raw error text into structured JSON

Pure error-text parser — takes raw compiler, runtime, or test output and returns a structured `{ error_code, message, location?, confidence }` JSON diagnosis, without attempting any fix.

**Why reach for it**:
- Unified schema across 7+ tool dialects (Python tracebacks, Rust E0xxx, TS2xxx, gcc/clang, jest/mocha, eslint, ruff) — agents stop writing per-tool regex
- Very fast (~10ms, pure text parser, no daemon needed)
- Exit 0 whenever the error parses — works as a structured input stage for an LLM-driven fixer regardless of fixability
- `--stdin` accepts piped error text directly: `<runtime-cmd> 2>&1 | tldr fix diagnose -s <FILE> --stdin`

**When to use**:
- First step of an LLM-fix pipeline: convert raw error text into structured JSON before prompting the model
- Filtering or routing errors by `error_code` / `location` without trying to repair them
- Sanity-checking that a runtime's error format is even recognizable before reaching for `fix apply` or `fix check`

**Usage**:
```bash
tldr fix diagnose -s <source-file> (--error "<text>" | --error-file <file> | --stdin)
```

**Output**: A small JSON object naming the language, the parsed error code, a human-readable message with a suggested action, an optional `location: { file, line }` when the error text carries file:line metadata, and a confidence band of Low / Medium / High.

**Killer detail**: Exits 0 on `confidence: Low` — its sibling `tldr fix apply` exits 1 on the same diagnosis. **This is the discriminator**: diagnose says "I parsed it" with exit 0; apply says "I parsed it but can't deterministically fix it" with exit 1. Use diagnose when the downstream consumer is an LLM that wants the parse regardless of fixability.

---

### `tldr fix apply` — attempt registry auto-fix, emit patch or LLM-ready diagnosis

Takes a source file and an error text, tries the deterministic-fix registry, and either writes the patched source or emits a structured diagnosis for LLM hand-off.

**Why reach for it**:
- For the small set of known-fixable patterns (TS2304 missing imports, simple Python typos with `--api-surface`, etc.) it produces the patched file with zero LLM cost
- When no deterministic fix exists, the JSON diagnosis (`error_code`, `message`, `location`, `confidence`) is the ideal LLM input — agents don't have to re-parse the raw traceback
- `--diff`, `-o <out>`, and `-i --in-place` cover the common write-back patterns
- Unified parser across Python tracebacks, Rust E0xxx, TS2xxx, gcc/clang, jest/mocha, eslint, ruff

**When to use**:
- Compiler/test output names a well-known error and the agent wants the registry to try first before paying for an LLM
- Building an LLM-fix pipeline and needs structured diagnosis as input: `<runtime> 2>&1 | tldr fix apply -s <FILE> --stdin`
- Targeting TS2339 property errors with an `--api-surface api-surface.json` from `tldr api-check`

**Usage**:
```bash
tldr fix apply -s <source-file> (--error "<text>" | --error-file <file> | --stdin) [-d|--diff] [-o <out>] [-i|--in-place] [--api-surface <json>]
```

**Output**: Default emits a JSON diagnosis `{ language, error_code, message, location?, confidence }`. When a deterministic fix exists, also prints the patched source (or unified diff with `-d`); when it doesn't, stderr says `"No auto-fix available... Escalate to a model."` and exit is 1.

**Killer detail**: **Exit 1 is the COMMON case, not the failure case** — the deterministic-fix registry is intentionally small, so most invocations return `confidence: Low` and `"Escalate to a model"` on stderr. Treat exit 1 + a populated JSON diagnosis as the happy path for LLM hand-off, not as an error to recover from.

**Other footguns**:
- Stdin is read implicitly when neither `--error` nor `--error-file` is provided (even without `--stdin`) — `tldr fix apply -s buggy.py` in an interactive terminal HANGS waiting on stdin. **Always pass `< /dev/null`** or set `--error`/`--error-file` explicitly in scripts
- `--api-surface <bad-path>` is SILENTLY IGNORED — no warning that the surface file is missing. Verify it exists externally before relying on TS2339-style suggestions

---

### `tldr fix check` — bounded test → diagnose → apply → retest loop

End-to-end test → diagnose → apply → retest loop, bounded by `--max-attempts`, returning a structured log of each attempt and whether the test eventually passed.

**Why reach for it**:
- Closes the loop that `fix diagnose` + `fix apply` only do single-shot — runs the test command, parses the failure, applies a registry fix, re-runs, repeats
- `attempts[]` array logs every iteration with `error_code`, `fixed: bool`, and a description — easy to filter "what actually got changed"
- `final_pass: true, attempts: []` is the clean "test was already green" signal
- Works with any shell-runnable test command (`pytest`, `npm test`, `cargo test`, anything via `sh -c`)

**When to use**:
- A known-fixable error pattern (e.g., TS2304 missing import) is blocking the test suite and an agent wants the registry to heal it without human attention
- Wrapping a CI step where the agent should retry up to N times before failing the build
- Verifying "test passes without any auto-fix needed" — pass `--max-attempts 0` to run the test exactly once and skip all repair attempts

**Usage**:
```bash
tldr fix check --file <source> --test "<shell-command>" [--max-attempts <N>] [--format compact|json]
```

**Output**: A JSON report with the source file (absolute), the test command verbatim, an `attempts[]` array (each entry has iteration, parsed error code, message, whether a fix was applied, and what it was), a `final_pass` boolean, and the total `iterations` count.

**Killer detail**: `-f` is `--file`, NOT `--format` — the local short flag shadows the global. `tldr fix check -f buggy.py -f compact` errors with `"argument '--file <FILE>' cannot be used multiple times"`. **Always use `--format` long-form** to set output format on this subcommand; and note that `--format text` is broken anyway (silently emits JSON), so reach for `--format compact` when you want one line.

**Other footguns**:
- If the error pattern isn't in the deterministic registry, the loop bails after 1 unparseable attempt regardless of `--max-attempts` — `fix check` does NOT escalate to an LLM on its own

## Common mistakes

- **Treating `bugbot` as the entry point to a fix loop.** Bugbot only reports. It will not invoke the fix-registry, will not call an LLM, will not edit a file. After bugbot exits 1, the next move is `tldr fix diagnose` (parse the error) or `tldr fix check` (loop on the test) — NOT "bugbot again."
- **Reaching for `tldr diagnostics` when `tldr fix diagnose` would do.** Diagnostics EXECUTES installed tools (pyright, tsc, etc.) on source files; fix-diagnose PARSES already-produced error text. If a build already failed and you have the stderr in hand, parsing it is ~10ms; re-running the tool is seconds-to-minutes and pointless. This is the most-confused pair in the whole skill.
- **Reaching for `tldr bugbot` for a whole-repo audit.** Bugbot is diff-scoped — outside a git repo it exits 1 with `"Failed to list uncommitted changes"`, and on a clean working tree it returns `notes: ["no_changes_detected"]`. For full-repo audits, use `tldr-audit-security` (`tldr secure`, `tldr vuln`) or `tldr-audit-smells`.
- **Treating `fix apply`'s exit 1 as a failure.** Exit 1 is the COMMON case — it means "I parsed your error but can't deterministically fix it; here is the JSON diagnosis, escalate to a model." The happy path for LLM hand-off is exit 1 + populated JSON, not exit 0. Wire CI accordingly or you'll mark a working pipeline red.
- **Aborting `bugbot` on first run because it "looks hung."** The first invocation on a new repo silently performs a full-baseline scan (~2 minutes). Subsequent runs are 10–30s. Bake the latency into CI timeouts; don't kill the process.
- **Running `tldr fix apply -s buggy.py` interactively without `--error` or `--error-file`.** It implicitly reads stdin and hangs waiting for input. Always pass `--error`, `--error-file`, or `< /dev/null` in scripts.
- **Using `-f sarif` on `tldr diagnostics`.** Rejected with a global format-validator error. The correct flag is `--output sarif` — a different code path. Expect `-f sarif` to look like a tooling bug.
- **Using `-f compact` on `tldr fix check`.** `-f` is `--file` on this subcommand (the local short flag shadows the global). Use `--format compact` long-form; note also that `--format text` is broken and silently emits JSON.
- **Calling `tldr fix check` with an error pattern outside the deterministic registry.** The loop bails after one unparseable attempt regardless of `--max-attempts` — it does NOT escalate to an LLM. For unknown errors, use `fix diagnose` and hand the JSON to a model yourself.

## See also

- `tldr-trace-data-flow` — when the bug investigation is about how a VALUE flows or where a variable was last assigned, not parsing an error text
- `tldr-audit-smells` — when the question is "what should I clean up someday" rather than "what's actively broken"
- `tldr-audit-security` — for known-vulnerability and taint-analysis scans across the whole repo (not the diff)
- `tldr-change-impact` — for "what will break if I change this" pre-change blast radius, complementary to bugbot's post-change scan
