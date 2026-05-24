# tldr diagnostics

> **Before writing the Usage block**: check `verified-invocations.md` in this group's
> `tool-cards/fix/` directory and copy the canonical syntax verbatim.
> Do NOT reconstruct syntax from prose — that is how hallucinated flags get introduced.

**Pitch**: Runs the project's installed type checkers and linters (pyright, ruff, tsc, eslint, clippy, etc.) on a path and normalizes their output into one unified JSON schema.

**Why reach for it**
- One report covers every diagnostic tool installed for the language — no per-tool JSON parsing
- `--output sarif` emits SARIF 2.1.0 for GitHub/GitLab Code Scanning; `--output github-actions` emits inline `::error::`/`::warning::` workflow commands (the only `tldr` command that does)
- `--baseline`/`--save-baseline` enables "show only NEW issues since last snapshot" — kills the technical-debt firehose
- Distinct exit codes (60 = no tools installed, 61 = all tools failed) make tool-availability problems debuggable

**When to use**
- Running type-check + lint on a file or directory and want a single schema downstream
- Producing SARIF for code-scanning dashboards or PR annotations in CI
- Comparing the current state to a saved baseline to surface only new findings

**When NOT to use**
- Want to scope to git-changed files only — use `tldr bugbot` (diff-driven) instead
- Want to PARSE error text a runtime already produced — use `tldr fix diagnose` (text parser, no tool execution)
- Need taint or vulnerability analysis — use `tldr secure` / `tldr vuln`

**Usage (copy from `verified-invocations.md` — do not reconstruct)**:
```
tldr diagnostics [OPTIONS] [PATH]
tldr diagnostics backend/providers/yahoo.py --timeout 10
tldr diagnostics backend/providers/yahoo.py --tools ruff --output sarif --timeout 10
```

**Output in plain words**: A JSON record with the full list of normalized diagnostics (file, line, severity, code, source tool, message, doc URL), a summary by severity, and a `tools_run[]` array showing each tool's name, version, success, duration, and finding count.

**Killer detail**: `-f sarif` is REJECTED with a global format-validator error, but `--output sarif` IS supported — they're two different code paths. Always reach for `--output sarif` when targeting SARIF consumers; `-f sarif` will exit 1 and look like a tooling bug.

**Source**: `research/tldr/fix/diagnostics.md`
