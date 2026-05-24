# tldr change-impact

> **Before writing the Usage block**: check `verified-invocations.md` in this group's
> `tool-cards/ops/` directory and copy the canonical syntax verbatim.
> Do NOT reconstruct syntax from prose — that is how hallucinated flags get introduced.

**Pitch**: Maps a git diff (or explicit file list) to the test files and functions affected by those changes, optionally emitting a runner-ready test command for direct CI integration.

**Why reach for it**
- Replaces a full test-suite run with a focused subset on PR CI
- `--runner pytest|jest|cargo-test|go-test|pytest-k` emits a paste-ready CLI string — no glue script needed
- Walks the call graph forward from changed code to identify ripple-affected tests, not just touched files
- Distinct exit code 3 for "no git baseline" surfaces the recoverable failure mode immediately

**When to use**
- Setting up PR CI: `tldr change-impact --base origin/main --runner pytest | xargs pytest`
- Want to know which tests a refactor will invalidate before running anything
- Reviewing a PR and need to focus attention on the test files in scope

**When NOT to use**
- Tracing blast radius from a single function — use `tldr impact` (per-symbol, no git involved)
- Need the test-affected list with full mapping back to which change caused which test — use `tldr whatbreaks`
- Comparing two specific files structurally — use `tldr diff`

**Usage (copy from `verified-invocations.md` — do not reconstruct)**:
```
tldr change-impact [OPTIONS] [PATH]
```
```
# P01 — unstaged changes in current dir
tldr change-impact
# P02 — explicit file list
tldr change-impact -F backend/providers/yahoo.py,backend/providers/dhan.py
# P09 — diff against a remote branch
tldr change-impact --base origin/main
```

**Output in plain words**: JSON with `changed_files`, `affected_tests`, `affected_test_functions`, `affected_functions`, a `detection_method` tag, call-graph metadata, and a status block. With `--runner X` the JSON is replaced by a single runner-formatted command string (empty when nothing is affected).

**Killer detail**: `-F` explicit files don't override language autodetect — on a TypeScript-dominant repo, `-F backend/foo.py` silently returns `changed_files: []` because the Python files don't exist in the TS call graph. Always pair `-F` with `-l <lang>`.

**Other footguns**
- Exit 3 is unique to git-baseline failures (bad `--base`, non-git dir, empty repo); the error string includes a built-in "Try `--files <path>` or `--base <ref>`" hint — branch on exit 3 to fall back to explicit `-F`.
- Passing a file as PATH gives a best-in-class custom error ("change-impact requires a directory") instead of the cryptic upstream git error.

**Source**: `research/tldr/ops/change-impact.md`
