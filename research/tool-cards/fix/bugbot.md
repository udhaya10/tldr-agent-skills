# tldr bugbot

**Pitch**: Git-diff-driven bug detector that runs commodity linters (L1) and tldr's own analyses (L2) on uncommitted or staged changes, then gates the commit/CI on findings.

**Why reach for it**
- One command replaces invoking clippy, cargo-audit, ruff, pyright, etc. plus the tldr taint/resources/complexity checks on the diff
- Findings cause exit 1 by default — drop-in for `tldr bugbot check && git push` or pre-merge CI gates
- Splits results into `summary.l1_findings` (commodity tool noise) and `l2_findings` (tldr-specific deep findings), so agents can prioritize
- `--base-ref` and `--staged` let it target any diff window — branch-vs-main, staged-only for pre-commit hooks, last commit, etc.

**When to use**
- Pre-commit or pre-push hook needs to flag bugs in changed code without re-scanning the whole repo
- CI step that should fail when uncommitted/staged changes introduce findings
- Reviewing a feature branch's diff against `main` (`--base-ref main`)

**When NOT to use**
- Whole-repo audit, not just the diff — reach for `tldr secure`, `tldr vuln`, or the per-analysis commands directly
- Working tree isn't a git repo — bugbot shells out to `git diff` and exits 1 with `"Failed to list uncommitted changes"`
- The goal is to actually FIX something — bugbot only reports; pair with `tldr fix diagnose`/`fix apply` afterward

**Output in plain words**: A JSON report with the diffed file list (absolute paths), every finding with severity and location, a summary that breaks down L1 vs L2 counts, and `notes: ["no_changes_detected"]` as the canonical "nothing to do" signal when the diff is empty.

**Killer detail**: The first invocation on a new repo silently performs a full-baseline scan that takes ~2 minutes on a real codebase (PM-34) — subsequent runs are 10–30s. Agents that abort on "looks hung" will lose the baseline; bake the latency into CI timeouts.

**Source**: `research/tldr/fix/bugbot.md`
