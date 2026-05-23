---
name: tldr-audit-complexity
description: Measure code complexity and size — cyclomatic, cognitive, Halstead, or raw lines of code, for one function or a whole directory. Reach for this whenever the question is "how complex is this", "find the most complex functions", "what's the cyclomatic/cognitive complexity", "halstead metrics", "lines of code", or "code size". Replaces hand-rolled complexity loops, `wc -l`, and ad-hoc grep counts with one indexed query. Triggers on "find complex functions", "rank functions by complexity", "what's the worst function", "how big is this codebase", "code volume", "vocabulary effort", "predicted bugs".
allowed-tools: [Bash]
compatibility: "Requires tldr-code CLI v0.4.0+. Tested on darwin and linux."
metadata:
  version: "1.0.0"
  author: "udhaya10"
  repository: "udhaya10/tldr-agent-skills"
  tldr.cli-version: "0.4.0"
  tldr.research-commit: "a025973"
  tldr.commands-wrapped: "cognitive, complexity, halstead, loc"
---

# tldr-audit-complexity

## When to use

Use this skill whenever the question is **how complex or how big** some code is — at the function, file, directory, or repo level. The four tools here measure four different dimensions: cognitive (human readability via nesting penalty), cyclomatic + 3 others (structural metrics for ONE named function), Halstead (token vocabulary → effort/bugs), and lines of code (raw size with comment/blank breakdown).

The discriminator vs sibling skills:

- For "**what to refactor**" (anti-patterns, debt, code smells) → see `tldr-audit-smells`
- For **structural** quality at the class/module level (coupling, cohesion, hubs) → see `tldr-architecture`
- For **security** issues → see `tldr-audit-security`

If you don't have a function name and want to rank candidates, this is the right skill — `tldr cognitive` does the ranking in one call. If you already have a named function and want one cheap number, `tldr complexity` is the focused path.

## The decision — which tool to use

The discriminator is **what you already have × which dimension you care about**: do you have ONE named function or a whole tree, and are you measuring control flow, human readability, token vocabulary, or raw size?

| You already have... | And you want... | Dimension | Reach for |
|---------------------|-----------------|-----------|-----------|
| A directory or file with many functions | A ranked list of the worst offenders by readability | Cognitive complexity (SonarQube nesting penalty) across all functions | `tldr cognitive` |
| One specific function name | The four structural metrics in one cheap call | Cyclomatic + cognitive + max_nesting + LoC for one function | `tldr complexity` |
| A directory or file | Token-vocabulary effort, predicted bug count, or size-of-review estimate | Halstead volume / difficulty / effort / bugs | `tldr halstead` |
| A complex function and need to know WHY it's complex | Per-line breakdown of which `if`/`for`/`while` contributed | Cognitive contributors | `tldr cognitive --show-contributors` |
| Any repo or directory | Raw size: total lines, code vs comment vs blank, by language | Lines of code | `tldr loc` |

**Default: `tldr cognitive <DIR> --include-cyclomatic` for the dominant "find the worst functions" intent.** It ranks every function in the path by cognitive score (penalizes nesting more than cyclomatic does, better matching human "what is this doing?" effort) AND folds in cyclomatic in the same call — two metrics for the price of one. Escalate to `tldr complexity <file> <function>` only when the function is already named and you want the daemon-cached sub-millisecond repeat path. Reach for `tldr halstead` when the question is about size-effort, test-priority shortlists (the `bugs` field), or token-level evidence. Reach for `tldr loc` as the cheap first step on an unfamiliar repo to answer "is this 5K lines or 500K?" before any per-function analysis.

## Tool reference

> **Command guardrail**: Only invoke the exact subcommands documented below. Do **not** invent or guess command names. If uncertain whether a command exists, run `tldr --help` before proceeding.

### `tldr cognitive` — rank functions by SonarQube cognitive complexity

SonarQube cognitive-complexity scorer that ranks every function in a path by how hard it is for a human to follow, with optional per-line breakdown of which constructs contributed to the score.

**Why reach for it**:
- Cognitive complexity penalizes NESTING more heavily than cyclomatic — a deeply-nested loop scores higher here than under `tldr complexity`, better matching human "what is this doing?" effort
- `--show-contributors` returns `{line, construct, base_increment, nesting_increment, nesting_level}` per row — directly drives refactor suggestions ("flatten this nested `if`, extract this inner loop")
- `--include-cyclomatic` adds the cyclomatic number side-by-side without a second tool invocation
- `threshold_status` enum (`ok`/`warning`/`severe`) makes triage automation trivial — tied to `--threshold` (default 15) and `--high-threshold` (default 25)

**When to use**:
- Ranking functions across a file or directory by maintainability risk — picking refactor candidates
- Need per-line explanations of WHERE the complexity comes from, not just a single score
- Want a project-wide complexity dashboard with violations classified into three buckets

**Usage**:
```bash
tldr cognitive <PATH> [-l <lang>] [--include-cyclomatic] [--show-contributors] [--threshold N] [--high-threshold N]
```

**Output**: JSON `{functions[], violations[], summary, warnings?}`. Each function entry carries `cognitive, max_nesting, nesting_penalty, threshold_status` (and `cyclomatic`/`contributors[]` when their flags are set).

**Killer detail**: THREE silent-empty modes return exit 0 with identical empty shapes: function-not-found, empty directory, and language-mismatch. **ONLY** the lang-mismatch case populates `warnings: ["No supported source files found in <path>"]` — without that warning field, the caller cannot distinguish "wrong language" from "no such function" by JSON shape alone.

---

### `tldr complexity` — four structural metrics for one named function

Minimal single-function metric scorer that returns the four standard structural numbers — cyclomatic, cognitive, max_nesting, lines_of_code — for one named function, daemon-cached for sub-millisecond repeat calls.

**Why reach for it**:
- Smallest, fastest, most focused complexity command in the suite — perfect for filling in `complexity` columns in audit reports
- Routes through the daemon: cold ~50ms, warm sub-millisecond, byte-identical results across cold and warm
- Cognitive score matches `tldr cognitive` exactly (same canonical `tldr_core::calculate_complexity` engine) — safe to use either
- Cleanest CLI surface in the audit suite: two positionals (FILE, FUNCTION), `-l`, `-f`, `-q`, nothing else

**When to use**:
- Already know the function name and want its four metrics in one cheap call
- Building a CI workflow that scores a fixed set of functions on every commit (daemon cache makes this near-free)
- Need a deterministic, scriptable JSON for downstream tooling — `tldr complexity ... -f compact | jq .cognitive`

**Usage**:
```bash
tldr complexity <FILE> <FUNCTION> [-l <lang>] [-f json|compact] [-q]
```

**Output**: A 5-field JSON record (`function, cyclomatic, cognitive, max_nesting, lines_of_code`). No `file` field in the output, so multi-function aggregation requires external bookkeeping — `tldr cognitive` is the right tool for that case.

**Killer detail**: `-l typescript` on a `.py` file does NOT report a language mismatch — the TypeScript parser walks Python source, fails to locate the function, and the command **exits 20 with a misleading `"Function not found: <name>"`**. When the language might be ambiguous, omit `-l` and trust auto-detect, or pass the file's actual language.

---

### `tldr halstead` — token vocabulary, volume, effort, bug estimate

Halstead software-science scorer that counts operators and operands per function and derives the classic vocabulary/length/volume/difficulty/effort/bugs/time measures.

**Why reach for it**:
- Lexical complexity dimension — orthogonal to `tldr complexity` (decision points) and `tldr cognitive` (nesting); a function can pass both and still score high on Halstead volume
- The `bugs` field (`volume / 3000`, classic Halstead estimate) makes a defensible "where should we add tests?" shortlist
- `--show-operators` / `--show-operands` expose the actual token classification — invaluable for explaining why a score is unexpectedly high
- Independent `--threshold-volume` (default 1000) and `--threshold-difficulty` (default 20); a function violates if it exceeds EITHER

**When to use**:
- Need a vocabulary/length view of complexity to complement structural metrics — auditing test coverage priorities, sizing review effort
- Want token-level evidence for a refactor recommendation (raw operator/operand lists)
- Running a project-wide scan with volume/difficulty thresholds for CI gating

**Usage**:
```bash
tldr halstead <PATH> [-l <lang>] [--show-operators] [--show-operands] [--threshold-volume N] [--threshold-difficulty N]
```

**Output**: JSON `{functions[], violations[], summary, warnings?}`. Each function carries a nested `metrics: {n1, n2, N1, N2, vocabulary, length, volume, difficulty, effort, time, bugs}` plus a `status` of `good`/`warning`/`bad`.

**Killer detail**: Unlike `tldr cognitive`, a non-source single FILE (e.g., `README.md`) returns exit 11 with `"Unsupported language: Could not detect language for: README.md"` — the explicit error is preferable, but agents handling both commands cannot share an error path: `cognitive` swallows the same input as exit 0 with an empty result.

---

### `tldr loc` — language-aware lines of code (code/comment/blank)

Language-aware line-of-code counter that separates code, comments, and blanks, broken down by language, file, or directory.

**Why reach for it**:
- Knows comment syntax for every supported language — gives a real code/comment ratio instead of `wc -l`'s raw total
- Respects `.gitignore` by default and skips binaries automatically — output is what you'd actually count
- Multi-language repos get a `by_language` keyed object for free; no need to scope twice
- First-pass sizing for unfamiliar codebases: "is this 5K lines or 500K?" answered in one call

**When to use**:
- Onboarding to a new repo and need an honest size estimate before diving deeper
- Multi-language project where the dominant language isn't obvious — the `by_language` breakdown answers it
- Audit prep: pairs with the complexity tools above as the cheap first step before expensive per-function analyses
- Reporting code volume to a stakeholder, or budgeting LLM token costs for a "read the whole repo" pass

**Usage**:
```bash
tldr loc [PATH] [--by-file] [--by-dir] [-l <lang>]
```

**Output**: A summary block with the eight counts (totals, code, comment, blank, and three percents), a `by_language` object keyed by language name, plus optional `files[]` (with `--by-file`) and `directories[]` (with `--by-dir`) arrays.

**Killer detail**: `by_language` is a **KEYED OBJECT** (`result.by_language.python`), not an array — iterate with `Object.entries`. Most other tldr commands return arrays for similar data; the wrong access pattern silently returns undefined.

## Common mistakes

- **Looping `tldr complexity` over every function in a directory to build a ranking.** Don't. `tldr cognitive <DIR>` already ranks every function in one call with the same canonical engine. The loop is slower AND loses the project-wide `summary` / `violations[]` rollup.
- **Reaching for `tldr complexity` to discover candidates.** Complexity is single-function and takes the name as a required positional. If the function name isn't already in hand, use `tldr cognitive` (for ranking) or reach for `tldr-locate-code` / `tldr-understand-function` (to discover the name) first.
- **Trusting `tldr cognitive` on an empty/wrong-language directory without checking `warnings[]`.** Three silent-empty modes return identical exit 0 with empty shapes: function-not-found, empty directory, and language-mismatch. ONLY the lang-mismatch case populates `warnings: ["No supported source files found in <path>"]`. Other empties look identical to a successful "found nothing."
- **Passing `-l typescript` to `tldr complexity` on a `.py` file.** It does NOT report a mismatch — the TS parser walks the Python source, fails to locate the function, and exits 20 with a misleading `"Function not found"`. When the language might be ambiguous, omit `-l` and trust auto-detect, or pass the file's actual language.
- **Treating Halstead's `bugs` field as a fault prediction.** It's `volume / 3000`, the classic Halstead estimate — useful as a relative shortlist ("test these first"), useless as an absolute count. Don't put it in a stakeholder report as "we have N bugs."
- **Assuming the cognitive scores from `tldr complexity` and `tldr cognitive` might disagree.** They don't. Both share `tldr_core::calculate_complexity`. Pick by scope (one function vs many), not by hoping for a different number.
- **Iterating `tldr loc`'s `by_language` as an array.** It's a keyed object — `Object.entries(result.by_language)` is the correct access pattern; treating it as `result.by_language[0]` returns undefined.
- **Reaching for `tldr loc` when the real question is complexity.** LoC is raw size, not complexity. A 500-line config-table file scores high on `loc` but trivially low on `cognitive`/`complexity`/`halstead`. Use `loc` for sizing, the other three for difficulty.

## See also

- `tldr-audit-smells` — when the question is "what to refactor" (anti-patterns, debt, hotspots) rather than "how complex is this"
- `tldr-architecture` — when the complexity question is actually about coupling/cohesion at the class or module level
- `tldr-understand-function` — when you need a function name first before scoring its complexity
- `tldr-orient-codebase` — when `tldr loc` should be paired with structure/tree for a broader first-pass tour
