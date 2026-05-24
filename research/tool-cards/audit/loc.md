# tldr loc

> **Before writing the Usage block**: check `verified-invocations.md` in this group's
> `tool-cards/audit/` directory and copy the canonical syntax verbatim.
> Do NOT reconstruct syntax from prose — that is how hallucinated flags get introduced.

**Pitch**: Language-aware line-of-code counter that separates code, comments, and blanks, broken down by language, file, or directory.

**Why reach for it**
- Knows comment syntax for every supported language — gives a real code/comment ratio instead of `wc -l`'s raw total
- Respects `.gitignore` by default and skips binaries automatically — output is what you'd actually count
- Multi-language repos get a `by_language` keyed object for free; no need to scope twice
- First-pass sizing for unfamiliar codebases: "is this 5K lines or 500K?" answered in one call

**When to use**
- Onboarding to a new repo and need an honest size estimate before diving deeper
- Multi-language project where the dominant language isn't obvious — the `by_language` breakdown answers it
- Audit prep: pairs with `tldr structure` and `tldr health` as the cheap first step before expensive analyses
- Reporting code volume to a stakeholder, or budgeting LLM token costs for a "read the whole repo" pass

**When NOT to use**
- Need cyclomatic, Halstead, or cognitive complexity — those are dedicated commands, not `loc`
- Counting just one file's structure — `tldr extract` returns functions+classes+line numbers in one pass

**Usage (copy from `verified-invocations.md` — do not reconstruct)**:
```
tldr loc [OPTIONS] [PATH]
```
```
tldr loc backend/providers/yahoo.py               # single file
tldr loc backend                                  # directory (PATH defaults to .)
tldr loc backend --by-file --by-dir               # per-file and per-directory breakdown
```

**Output in plain words**: A summary block with the eight counts (totals, code, comment, blank, and three percents), a `by_language` object keyed by language name, plus optional `files[]` (with `--by-file`) and `directories[]` (with `--by-dir`) arrays.

**Killer detail**: `by_language` is a KEYED OBJECT (`result.by_language.python`), not an array — iterate with `Object.entries`. Most other tldr commands return arrays for similar data; the wrong access pattern silently returns undefined.

**Source**: `research/tldr/audit/loc.md`
