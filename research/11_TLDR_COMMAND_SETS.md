# Research Journal 11: tldr Commands as Overlapping Sets

> **Organizing principle:** Group by *intent* — what the LLM is trying to DO. Commands belong to every set where they're relevant. Sets have intersections, and the intersections reveal where `tldr` provides compound value that shell commands cannot match.

> **Date:** 2026-05-29

---

## The Sets

```
┌─────────────────────────────────────────────────────────────┐
│                                                             │
│   ┌──────────┐    ┌──────────┐    ┌──────────┐            │
│   │ READING  │    │SEARCHING │    │   GIT    │            │
│   │          ├────┤          ├────┤          │            │
│   └────┬─────┘    └────┬─────┘    └────┬─────┘            │
│        │               │               │                   │
│        └───────┬───────┘               │                   │
│                │                       │                   │
│   ┌────────────┴───┐    ┌─────────────┴──┐                │
│   │   TRACING      ├────┤   MEASURING    │                │
│   │                │    │                │                │
│   └────────┬───────┘    └────────┬───────┘                │
│            │                     │                         │
│            └──────────┬──────────┘                         │
│                       │                                    │
│              ┌────────┴───────┐                            │
│              │   SECURITY    │                            │
│              └───────────────┘                            │
└─────────────────────────────────────────────────────────────┘
```

---

## Set 1: Reading

**Intent:** "What's in this file/module? Help me understand this code without reading raw source."

**Shell commands this replaces:** `cat`, `head`, `tail`, `less`, `bat`

---

### `tldr extract <file>`

**Replaces:** `cat file.py` when the LLM wants to understand a module.

| Shell approach | tldr approach |
|---|---|
| `cat src/auth.py` → 400 lines of raw source | `tldr extract src/auth.py` → functions, classes, imports, structured |

**What you get:** Complete module inventory — every function signature, class with methods, import statement. No function bodies.

**Flags:** `--lang`

**When to use:** First encounter with a file. "What's defined here?"

---

### `tldr structure <path>`

**Replaces:** `grep -rn "def \|class " src/` when scanning a directory for what exists.

| Shell approach | tldr approach |
|---|---|
| `grep -rn "def \|class " src/` → raw lines, false positives in strings/comments | `tldr structure src/` → AST-parsed, hierarchical, class→method grouping |

**What you get:** Per-file breakdown of functions, classes (with their methods), organized hierarchically.

**Flags:** `--max-results`, `--lang`

**When to use:** "What's in this directory?" at a code level (not file level).

---

### `tldr explain <file> <function>`

**Replaces:** `cat file.py` + `grep callers` + `grep callees` — the 3-5 call workflow to understand one function.

| Shell approach | tldr approach |
|---|---|
| Read file + grep for callers + grep for callees = 3-5 tool calls | `tldr explain file.py fn` = 1 call |

**What you get:** Signature, purity analysis, complexity metric, list of callers, list of callees — everything about one function.

**Flags:** `--depth` (call graph traversal depth)

**When to use:** "What does this function do and who uses it?"

**Also in:** Tracing (because it includes caller/callee relationships)

---

### `tldr context <entry> <path>`

**Replaces:** The entire "read function → find callees → read those → find their callees" loop.

| Shell approach | tldr approach |
|---|---|
| 5-10 cat/grep calls to build a mental model | `tldr context fn src/ --depth 3` = 1 call |

**What you get:** LLM-ready bundle — the entry function + all functions it calls (transitively to depth N), each with signature and complexity.

**Flags:** `--depth`, `--include-docstrings`, `--file` (disambiguate common names)

**When to use:** Before writing code that touches a function. "Give me everything I need to work on this."

**Also in:** Tracing (it walks the call graph to build the bundle)

---

### `tldr imports <file>`

**Replaces:** `grep -n "import\|from.*import\|require\|use " file.py`

| Shell approach | tldr approach |
|---|---|
| Regex matching (misses aliased imports, multi-line imports) | AST-parsed, catches `from x import y as z`, `use crate::*` |

**What you get:** Structured list of every import — module, names imported, aliases, line numbers.

**Flags:** `--lang`

**When to use:** "What does this file depend on?"

---

## Set 2: Searching

**Intent:** "Where is this thing? Find it for me."

**Shell commands this replaces:** `grep`, `rg`, `ag`, `find`, `ls`, `locate`

---

### `tldr tree <path>`

**Replaces:** `find . -name "*.py"` / `ls -R` / `tree`

| Shell approach | tldr approach |
|---|---|
| `find . -name "*.py"` → flat list | `tldr tree --ext .py` → nested structure, respects .gitignore |

**What you get:** File tree filtered by extension, structured as nested directories.

**Flags:** `--ext` (filter extensions), `--include-hidden`

**When to use:** "What files exist in this project?" — file-level discovery.

---

### `tldr search <query> <path>`

**Replaces:** `grep -rn "pattern" src/` when you want context, not just matching lines.

| Shell approach | tldr approach |
|---|---|
| `grep -rn "parse config" src/` → bare matching lines | `tldr search "parse config" src/` → context cards with function signature + callers + callees per match |

**What you get:** BM25-ranked results, each enriched with the enclosing function's structure and call graph relationships.

**Flags:** `--top-k`, `--regex` (switch to regex mode), `--hybrid` (BM25 + regex filter), `--no-callgraph` (faster, skip enrichment)

**When to use:** "Find code related to X" — when you need understanding, not just location.

---

### `tldr definition --symbol <name>`

**Replaces:** `grep -rn "def fn_name\|function fn_name\|fn fn_name" src/`

| Shell approach | tldr approach |
|---|---|
| Regex for definition patterns (language-specific, fragile) | AST-based, cross-file, workspace-aware resolution |

**What you get:** Exact file + line + column where a symbol is defined. Works across files.

**Flags:** `--symbol`, `--file`, `--project`, `--workspace`

**When to use:** "Where is X defined?" — go-to-definition.

**Also in:** Tracing (it resolves cross-file references)

---

### `tldr references <symbol> <path>`

**Replaces:** `grep -rn "fn_name" src/` when looking for usages.

| Shell approach | tldr approach |
|---|---|
| `grep -rn "fn_name" src/` → matches in comments, strings, definitions, actual calls — all mixed | `tldr references fn_name --kinds call` → only actual call sites, AST-verified |

**What you get:** All references to a symbol, filterable by kind (call, read, write, import, type), with confidence scores.

**Flags:** `--kinds` (call,read,write,import,type), `--scope` (local/file/workspace), `--limit`, `--min-confidence`

**When to use:** "Who uses this?" / "Is it safe to rename?"

**Also in:** Tracing (it's relationship data)

---

### `tldr importers <module> <path>`

**Replaces:** `grep -rn "import module_name\|from module_name\|require.*module_name" src/`

| Shell approach | tldr approach |
|---|---|
| Regex across project (misses dynamic imports, aliased requires) | AST-parsed, finds all files that import a given module |

**What you get:** List of files that import the specified module, with line numbers.

**Flags:** `--limit`, `--lang`

**When to use:** "Who depends on this module?" — reverse import lookup.

**Also in:** Tracing (it's a dependency relationship)

---

### `tldr semantic '<query>' <path>`

**Replaces:** Nothing in shell. Closest is `grep` but grep can't understand meaning.

| Shell approach | tldr approach |
|---|---|
| `grep -rn "authenticate\|login\|auth\|verify"` (guess synonyms) | `tldr semantic 'user authentication logic'` → embedding-based similarity |

**What you get:** Code fragments ranked by semantic similarity to a natural language query.

**Flags:** (requires `--features semantic` build)

**When to use:** "Find code that does X" when you don't know the exact names.

---

### `tldr similar <file>`

**Replaces:** Nothing in shell.

**What you get:** Code fragments across the project that are structurally/semantically similar to the given file.

**When to use:** "Is there code like this elsewhere?" — duplication discovery by meaning.

---

## Set 3: Git

**Intent:** "What changed, when, how much, and what's at risk?"

**Shell commands this replaces:** `git log`, `git diff`, `git blame`, `git shortlog`, `git show`

---

### `tldr churn <path>`

**Replaces:** `git log --format=format: --name-only | sort | uniq -c | sort -rn`

| Shell approach | tldr approach |
|---|---|
| Multi-pipe chain → commit counts only | `tldr churn src/ --top 20` → commits + added lines + removed lines + author count + last-modified date |

**What you get:** Most-changed files ranked by commit frequency, with change volume and recency.

**Flags:** `--days` (history window), `--top` (limit), `--authors` (include author stats), `--exclude`

**When to use:** "What's been changing a lot?" — identify volatile code.

---

### `tldr diff <file_a> <file_b>`

**Replaces:** `git diff file_a file_b` / `diff file_a file_b`

| Shell approach | tldr approach |
|---|---|
| Line-by-line textual diff (whitespace, formatting noise) | AST-aware structural diff at chosen granularity |

**What you get:** Changes categorized by structural level — you can diff at token, expression, statement, function, class, file, module, or architecture level.

**Flags:** `--granularity` (token/expression/statement/function/class/file/module/architecture), `--semantic-only` (skip formatting changes)

**When to use:** "What *actually* changed between these versions?" — ignoring noise.

---

### `tldr hotspots <path>`

**Replaces:** `git log` + manual complexity correlation (practically impossible by hand).

| Shell approach | tldr approach |
|---|---|
| Run git log for churn, separately measure complexity, manually correlate | `tldr hotspots src/` → combined churn × complexity risk score |

**What you get:** Files/functions ranked by bug risk — things that change often AND are complex.

**Flags:** (inherits from churn + complexity)

**When to use:** "Where are bugs most likely to appear?"

**Also in:** Measuring (it uses complexity metrics)

---

### `tldr change-impact`

**Replaces:** `git diff --name-only` + manual test mapping (impossible at scale).

| Shell approach | tldr approach |
|---|---|
| `git diff --name-only` → changed files, then guess which tests matter | Maps diff → affected test files via call graph |

**What you get:** List of tests that exercise the changed code.

**When to use:** "Which tests should I run after this change?"

**Also in:** Tracing (uses call graph), Security (validates change safety)

---

### `tldr bugbot`

**Replaces:** Nothing in shell. Closest is `git diff | grep "TODO\|FIXME"` (naive).

| Shell approach | tldr approach |
|---|---|
| Manual code review of diff | Automated bug detection on code changes |

**What you get:** Potential bugs introduced by recent changes.

**When to use:** Pre-commit / pre-PR gate. "Did I introduce bugs?"

**Also in:** Security (catches security-relevant bugs)

---

## Set 4: Measuring

**Intent:** "How big, complex, or healthy is this code? Give me numbers."

**Shell commands this replaces:** `wc -l`, `cloc`, `sloccount`, manual counting

---

### `tldr loc <path>`

**Replaces:** `wc -l **/*.py` / `cloc`

| Shell approach | tldr approach |
|---|---|
| `wc -l` → total lines only | `tldr loc` → code vs comments vs blanks, by language, by file/dir |

**What you get:** Lines of code with type breakdown (code, comments, blanks), aggregated by language.

**Flags:** `--by-file`, `--by-dir`, `--lang`, `--exclude`, `--include-hidden`

**When to use:** "How big is this codebase?" / "What's the comment ratio?"

---

### `tldr complexity <file> <function>`

**Replaces:** Nothing in shell (no CLI equivalent without installing dedicated tools).

**What you get:** Cyclomatic complexity for a specific function.

**Flags:** `--lang`

**When to use:** "Is this function too complex to safely modify?"

---

### `tldr cognitive <file> <function>`

**Replaces:** Nothing in shell.

**What you get:** Cognitive complexity (SonarQube algorithm) — measures how hard a function is to *understand*, not just how many paths it has.

**When to use:** "Is this function hard to read?" — different from cyclomatic (nested loops score higher).

---

### `tldr halstead <file> <function>`

**Replaces:** Nothing in shell.

**What you get:** Halstead metrics — vocabulary, volume, difficulty, effort, estimated time to understand, predicted bugs.

**When to use:** "How much mental effort does this function require?"

---

### `tldr cohesion <path>`

**Replaces:** Nothing in shell.

**What you get:** LCOM4 (Lack of Cohesion of Methods) — measures whether a class is doing too many unrelated things.

**When to use:** "Should this class be split?" / "Is this class focused?"

---

### `tldr coupling <path>`

**Replaces:** Nothing in shell (would require parsing imports + call graph manually).

**What you get:** Afferent coupling (who depends on me), efferent coupling (who I depend on), instability index.

**When to use:** "Is this module too coupled?" / "What's the most depended-on module?"

---

### `tldr debt <path>`

**Replaces:** Nothing in shell.

**What you get:** Technical debt estimate using SQALE method — remediation time in minutes per issue category.

**When to use:** "How much cleanup work is there?" / "What should I prioritize?"

---

### `tldr health <path>`

**Replaces:** Running 5+ separate tools and correlating results manually.

| Shell approach | tldr approach |
|---|---|
| Run complexity + cohesion + coupling + dead code + clones separately | `tldr health src/` → combined dashboard |

**What you get:** Aggregated health report — complexity averages, cohesion scores, coupling, dead code count, duplication.

**When to use:** "Give me the overall picture." — one-shot health check.

**Also in:** Security (includes some safety metrics)

---

### `tldr clones <path>`

**Replaces:** Nothing in shell (no way to detect semantic duplication with grep).

**What you get:** Code clone pairs — Type 1 (exact), Type 2 (renamed), Type 3 (modified) — with similarity scores.

**Flags:** `--min-tokens`, `--min-lines`, `--threshold`, `--type-filter`, `--normalize`, `--max-clones`, `--show-classes`

**When to use:** "Is there duplicated code I should extract?"

---

### `tldr contracts <path>`

**Replaces:** Nothing in shell.

**What you get:** Inferred pre/postconditions from guard clauses, assertions, isinstance checks.

**When to use:** "What are the implicit contracts of this code?"

**Also in:** Security (contracts reveal safety assumptions)

---

## Set 5: Tracing

**Intent:** "What's connected to what? Follow the relationships."

**Shell commands this replaces:** `grep "fn("` chained multiple times (and even then, only approximates one hop).

**This is where tldr has NO shell equivalent.** Shell can find text matches. It cannot follow call graphs, compute reachability, or trace data flow.

---

### `tldr calls <path>`

**Replaces:** Nothing. Closest: `grep` for function calls, but no transitivity, no cross-file resolution.

**What you get:** Cross-file call graph — who calls whom, as edges.

**Flags:** `--max-items` (default 200), `--respect-ignore`, `--lang`

**When to use:** "Show me the call structure of this project."

---

### `tldr impact <function> <path>`

**Replaces:** `grep -rn "fn_name"` → then grep each caller → then grep each caller's caller... (3-10 rounds).

| Shell approach | tldr approach |
|---|---|
| Recursive grep (manual, incomplete, 5+ calls) | `tldr impact fn src/ --depth 5` → full reverse call tree, 1 call |

**What you get:** Reverse call graph — everyone who calls this function, transitively to N levels.

**Flags:** `--depth`, `--file` (filter), `--type-aware` (resolve self.method())

**When to use:** "What breaks if I change this function?"

---

### `tldr dead <path>`

**Replaces:** Nothing in shell. You cannot detect unreachable code with grep.

**What you get:** Functions that are defined but never called — definitely dead or possibly dead (public but uncalled).

**Flags:** `--entry-points`, `--max-items`, `--call-graph` (use call-graph instead of refcount)

**When to use:** "What can I safely delete?"

---

### `tldr whatbreaks <target> <path>`

**Replaces:** Nothing in shell.

**What you get:** Transitive breakage analysis — everything downstream that depends on the target.

**When to use:** "If I remove/change X, what's the blast radius?"

---

### `tldr hubs <path>`

**Replaces:** Nothing in shell.

**What you get:** Functions with highest centrality in the call graph — the bottlenecks/chokepoints.

**When to use:** "What are the most critical functions?" / "Where should I be most careful?"

---

### `tldr slice <file> <function>`

**Replaces:** Nothing in shell.

**What you get:** Backward program slice — all statements that could affect a target variable/line.

**When to use:** "What influences this value?" — debugging data flow.

---

### `tldr chop <file> <function>`

**Replaces:** Nothing in shell.

**What you get:** Intersection of forward slice from A and backward slice from B — the dependency path between two points.

**When to use:** "How does data flow from point A to point B?"

---

### `tldr reaching-defs <file> <function>`

**Replaces:** Nothing in shell.

**What you get:** Which variable definitions can reach a given point — classic data flow analysis.

**When to use:** "What value could this variable have here?"

---

### `tldr available <file> <function>`

**Replaces:** Nothing in shell.

**What you get:** Available expressions at each point — detects common subexpressions that could be cached.

**When to use:** "Is this expression already computed somewhere above?"

---

### `tldr dead-stores <path>`

**Replaces:** Nothing in shell.

**What you get:** Assignments whose values are never read (SSA-based analysis).

**When to use:** "Are there useless assignments I can remove?"

---

## Set 6: Security

**Intent:** "Is this code safe? Where are the vulnerabilities?"

**Shell commands this replaces:** `grep "eval\|exec\|system\|os.popen"` (naive pattern matching that misses indirect flows and produces false positives).

---

### `tldr secure <path>`

**Replaces:** Running 5+ separate security checks manually.

| Shell approach | tldr approach |
|---|---|
| `grep "eval"` + `grep "exec"` + `grep "system"` (misses indirect flows) | `tldr secure src/` → taint + resources + bounds + contracts + behavioral + mutability |

**What you get:** Full security dashboard combining multiple analysis passes.

**Flags:** `--quick` (taint + resources + bounds only), `--detail` (drill into sub-analysis), `--include-tests`

**When to use:** "Is this codebase secure?" — one-shot security audit.

---

### `tldr taint <path>`

**Replaces:** Nothing in shell. Taint analysis requires tracking data flow from sources to sinks across function boundaries.

**What you get:** Source→sink paths — where user input flows to dangerous operations (SQL, shell, file system).

**When to use:** "Can user input reach a dangerous function?"

**Also in:** Tracing (it's data flow analysis)

---

### `tldr vuln <path>`

**Replaces:** `grep` for known vulnerability patterns (but grep can't follow data flow).

**What you get:** Categorized vulnerabilities — SQL injection, XSS, command injection — with taint paths.

**Flags:** `--include-tests`, format supports SARIF for CI integration

**When to use:** "Find injection vulnerabilities." — more focused than `secure`.

---

### `tldr api-check <path>`

**Replaces:** Nothing in shell.

**What you get:** API misuse patterns — missing timeouts, bare except, weak crypto, unclosed files.

**When to use:** "Am I using libraries correctly?"

---

### `tldr resources <path>`

**Replaces:** `grep "open\|close"` (can't track lifecycle).

| Shell approach | tldr approach |
|---|---|
| `grep "open"` → finds opens, can't verify they're closed | `tldr resources src/` → open/close lifecycle, detects leaks and double-close |

**What you get:** Resource lifecycle analysis — leaks, double-close, use-after-close.

**When to use:** "Are there resource leaks?"

**Also in:** Measuring (it's a quality metric)

---

## The Intersections

These are the commands that live in multiple sets — and they're the highest-value commands because they serve multiple intents simultaneously.

```
Reading ∩ Tracing = { context, explain }
```
→ You're reading code, but the output includes relationship data. One call serves both intents.

```
Searching ∩ Tracing = { references, importers, definition }
```
→ You're finding something, but the mechanism is relationship traversal, not text matching.

```
Git ∩ Measuring = { hotspots }
```
→ Combines change history with complexity metrics into a risk score.

```
Git ∩ Tracing = { change-impact }
```
→ Maps a diff through the call graph to find affected tests.

```
Git ∩ Security = { bugbot }
```
→ Analyzes changes specifically for introduced bugs/vulnerabilities.

```
Measuring ∩ Security = { contracts, resources }
```
→ Quality metrics that are also safety-relevant.

```
Tracing ∩ Security = { taint, slice }
```
→ Data flow analysis applied to security questions.

```
Measuring ∩ Tracing = { coupling, cohesion, dead }
```
→ Metrics that require relationship traversal to compute.

---

## Intersection Value Table

| Intersection | Why it matters for LLMs |
|---|---|
| Reading ∩ Tracing | `tldr context` replaces 5+ cat/grep calls with 1 call. Highest token ROI. |
| Searching ∩ Tracing | `tldr references --kinds call` gives AST-verified callers. grep gives text matches. |
| Git ∩ Measuring | `tldr hotspots` answers "where will bugs appear?" — impossible to derive from git log alone. |
| Git ∩ Tracing | `tldr change-impact` answers "which tests to run?" — impossible without call graph. |
| Tracing ∩ Security | `tldr taint` answers "can user input reach eval?" — impossible with grep. |

---

## Summary: What Shell Cannot Do At Any Token Cost

| Capability | Required analysis | Shell possible? |
|---|---|---|
| Transitive callers (depth > 1) | Call graph | ❌ |
| Dead code detection | Reachability | ❌ |
| Taint flow (source → sink) | Data flow | ❌ |
| Cyclomatic/cognitive complexity | CFG analysis | ❌ |
| Code clone detection | Token normalization + similarity | ❌ |
| LCOM4 cohesion | Method-field usage graph | ❌ |
| Program slicing | PDG | ❌ |
| Change → affected tests | Call graph + diff | ❌ |
| Hotspots (churn × complexity) | Git + CFG | ❌ |
| Resource leak detection | Lifecycle tracking | ❌ |
| AST-aware diff | Parser | ❌ |
| Available expressions / dead stores | SSA | ❌ |

These aren't "nice to have" — they're the queries that prevent LLMs from making wrong assumptions that cost thousands of tokens to debug.
