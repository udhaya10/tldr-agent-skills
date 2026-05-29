# Research Journal 10: Shell Commands vs tldr — Token Efficiency for LLM Harnesses

> **Question:** LLM harnesses (Claude Code, Codex, Kiro, etc.) rely heavily on shell commands like `ls`, `find`, `grep`, `cat`, `wc`, `git log`, `git diff`. Which of these can `tldr` replace, and what's the token efficiency tradeoff?

> **Date:** 2026-05-29  
> **Method:** Empirical — ran both shell commands and tldr equivalents on the tldr-code repo itself (292 Rust files), measured byte output, compared information density.

---

## 1. Direct Replacements — Same Job, Different Signal

| Shell pattern LLMs use | What it answers | `tldr` replacement | Key flags |
|---|---|---|---|
| `find . -name "*.py"` / `ls -R` | What files exist? | `tldr tree --ext .py` | `--ext`, `--include-hidden` |
| `grep -rn "def \|class "` | What functions/classes exist? | `tldr structure src/` | `--max-results`, `--lang` |
| `grep -rn "pattern"` | Where does this text appear? | `tldr search "pattern"` | `--top-k`, `--regex`, `--hybrid`, `--no-callgraph` |
| `grep -rn "import X"` in one file | What does this file import? | `tldr imports file.py` | `--lang` |
| `grep -rn "import X"` across project | Who imports module X? | `tldr importers X src/` | `--limit` |
| `grep -rn "fn_name("` | Find callers of a function | `tldr references fn_name` | `--kinds call`, `--scope`, `--limit`, `--min-confidence` |
| `grep -rn "fn_name"` + read file | Where is this defined? | `tldr definition --symbol fn_name` | `--project`, `--workspace` |
| `wc -l **/*.py` | How big is this codebase? | `tldr loc src/` | `--by-file`, `--by-dir`, `--lang` |
| `git log --name-only \| sort \| uniq -c \| sort -rn` | Which files change most? | `tldr churn src/` | `--days`, `--top`, `--authors` |
| `git diff file_a file_b` | What changed between versions? | `tldr diff a.py b.py` | `--granularity`, `--semantic-only` |
| `cat file.py` (to understand a module) | What's in this file? | `tldr extract file.py` | Returns functions, classes, imports — not raw source |
| `cat file.py` + grep callers + grep callees | Understand a function | `tldr explain file.py fn_name` | `--depth` for call graph traversal |

---

## 2. No Shell Equivalent — Capabilities That Don't Exist in grep/find/cat

| LLM need | Shell workaround | `tldr` command | Output |
|---|---|---|---|
| "Who calls this function transitively?" | grep + manual tracing (multiple rounds) | `tldr impact fn src/` | Reverse call graph, N levels deep (`--depth`) |
| "Full call graph of this project" | Impossible | `tldr calls src/` | Cross-file caller→callee edges (`--max-items`) |
| "Is this code dead?" | Impossible | `tldr dead src/` | Reference-counted or `--call-graph` based detection |
| "What breaks if I change X?" | Impossible | `tldr whatbreaks X src/` | Transitive impact analysis |
| "Give me LLM-ready context for fn" | cat + grep × 5 calls | `tldr context fn src/` | Signature + callers + callees + complexity in one bundle (`--depth`, `--include-docstrings`) |
| "Security vulnerabilities?" | `grep "eval\|exec"` (naive) | `tldr secure src/` | Taint flow + resource leaks + bounds + contracts (`--quick` for fast mode) |
| "Taint flow from user input to sink?" | Impossible | `tldr taint src/` | Source→sink paths with propagation |
| "Cyclomatic complexity of fn?" | Impossible | `tldr complexity file fn` | Per-function CC metric |
| "Cognitive complexity?" | Impossible | `tldr cognitive file fn` | SonarQube algorithm |
| "Code clones / duplication?" | Impossible | `tldr clones src/` | Token-normalized detection (`--threshold`, `--type-filter`, `--min-tokens`) |
| "Churn × complexity hotspots?" | git log + manual correlation | `tldr hotspots src/` | Combined risk score |
| "What tests are affected by this diff?" | Impossible | `tldr change-impact` | Maps diff → affected test files |
| "Code smells?" | Impossible | `tldr smells src/` | Named anti-patterns with remediation |
| "Technical debt estimate?" | Impossible | `tldr debt src/` | SQALE-method debt in minutes |
| "Class cohesion?" | Impossible | `tldr cohesion src/` | LCOM4 metric |
| "Module coupling?" | Impossible | `tldr coupling src/` | Afferent/efferent, instability index |
| "Design patterns in use?" | Impossible | `tldr patterns src/` | Pattern detection |
| "Hub functions (bottlenecks)?" | Impossible | `tldr hubs src/` | Centrality analysis |
| "Backward program slice from line?" | Impossible | `tldr slice file fn` | All statements affecting a target |
| "Pre/postconditions?" | Impossible | `tldr contracts src/` | Inferred from guards, assertions, isinstance |
| "Resource leaks?" | Impossible | `tldr resources src/` | Open/close lifecycle analysis |

---

## 3. Empirical Token Measurements (tldr-code repo, 292 Rust files)

### 3.1 File Discovery

| Command | Output bytes | Notes |
|---|---|---|
| `find crates/tldr-cli/src/ -name "*.rs"` | 8,008 | Flat list, no structure |
| `tldr tree crates/tldr-cli/src/ --ext .rs --format compact` | 12,705 | Nested structure, JSON |

**Verdict:** grep/find wins on raw bytes for simple listing. tldr adds structure.

### 3.2 Function Discovery (single file — main.rs, 720 lines)

| Command | Output bytes | Notes |
|---|---|---|
| `grep -rn "pub fn\|fn " main.rs` | 211 | 3 raw lines |
| `tldr structure main.rs --format compact -q` | 2,689 | 3 functions + 4 classes + hierarchy |

**Verdict:** grep is 12× smaller for raw function names. But tldr gives class membership, method grouping, and line numbers in structured form.

### 3.3 Function Discovery (292 files — full commands/ directory)

| Command | Output bytes | Notes |
|---|---|---|
| `grep -rn "pub fn\|fn " commands/ --include="*.rs"` | 413,567 | Every line matching "fn" (includes false positives in comments/strings) |
| `tldr structure commands/ --format compact -q` | 818,174 | Every function + class + method hierarchy |

**Verdict:** Both are large. grep is smaller but includes false positives and no structure. tldr is larger but semantically correct (AST-parsed).

### 3.4 Caller Discovery

| Command | Output bytes | Notes |
|---|---|---|
| `grep -rn "run_command" src/` | 186 | 3 lines (definition + 1 call + 1 comment) — no depth |
| `tldr impact run_command src/ --format text -q` | 167 | Full reverse call tree with depth traversal |

**Verdict:** Similar size, but tldr gives the *transitive* call chain. grep gives text matches (may include comments, strings).

### 3.5 Lines of Code

| Command | Output bytes | Notes |
|---|---|---|
| `wc -l main.rs` | 30 | Just "720 main.rs" |
| `tldr loc main.rs --format text -q` | 195 | Code: 407, Comments: 222, Blank: 91, by language |

**Verdict:** wc is smaller. tldr gives the breakdown an LLM actually needs to assess code density.

### 3.6 Git Churn

| Command | Output bytes | Notes |
|---|---|---|
| `git log --format=format: --name-only -- src/ \| sort \| uniq -c \| sort -rn \| head -5` | ~200 | Commit counts only |
| `tldr churn src/ --top 5 --format text -q` | ~350 | Commits + added/removed lines + author count + last-modified |

**Verdict:** Similar size. tldr adds +/- lines and recency — more actionable per token.

---

## 4. The Real Token Efficiency Argument

### It's NOT about per-command byte reduction

For simple lookups, shell commands produce fewer bytes. `grep` is leaner than `tldr structure` for "show me function names."

### It IS about:

#### 4.1 Fewer Round-Trips

An LLM trying to understand "what does function X do and who depends on it" with shell:
```
grep -rn "def X" src/          → find definition (1 call)
cat src/module.py              → read the function (1 call)  
grep -rn "X(" src/             → find callers (1 call)
cat src/caller1.py             → read caller context (1 call)
cat src/caller2.py             → read another caller (1 call)
```
**5 tool calls, 5 response payloads in context window.**

With tldr:
```
tldr context X src/ --depth 2  → everything in one call
```
**1 tool call, 1 response payload.**

#### 4.2 Correct Answers vs. Approximate Answers

| grep result for `"parse_config("` | tldr result for `impact parse_config` |
|---|---|
| Matches in comments | Only actual call sites |
| Matches in strings | AST-verified references |
| No transitive callers | Full depth traversal |
| No confidence score | Confidence-filtered |

An incorrect grep result → LLM makes wrong assumption → generates wrong code → debug cycle → **massive** token waste.

#### 4.3 Queries That Are Impossible Without tldr

Every time an LLM needs to answer "is this safe to change?" it either:
- **Without tldr:** Makes 5-15 grep/cat calls, builds a mental model, still misses transitive callers → ~5,000-20,000 tokens consumed, answer may be wrong
- **With tldr:** `tldr impact fn src/` → ~200-500 tokens, answer is correct

#### 4.4 The Compound Effect

In a typical coding session, an LLM harness makes 20-50 tool calls for exploration before writing code. If each `tldr` call replaces 3-5 shell calls:

| Metric | Shell-only session | tldr-augmented session |
|---|---|---|
| Tool calls for exploration | 30-50 | 8-12 |
| Context tokens consumed | 15,000-40,000 | 4,000-10,000 |
| Risk of wrong assumption | High (text matching) | Low (AST-verified) |
| Can answer "what breaks?" | No | Yes |

---

## 5. Replacement Decision Matrix

| When the LLM needs to... | Use shell | Use tldr | Why |
|---|---|---|---|
| Check if a file exists | ✅ `ls` | ❌ | Overkill |
| List files by extension | Either | `tree --ext` | Similar cost |
| Read a specific file | ✅ `cat`/read tool | ❌ | tldr doesn't read raw source |
| Find a text literal | ✅ `grep` | ❌ | grep is faster for exact text |
| Find function/class definitions | ❌ | ✅ `structure` | AST-correct, no false positives |
| Understand a function's role | ❌ | ✅ `explain` | One call vs 3-5 |
| Find all callers | ❌ | ✅ `impact` / `references` | Transitive, AST-verified |
| Assess change safety | ❌ | ✅ `whatbreaks` / `impact` | Impossible with shell |
| Security audit | ❌ | ✅ `secure` / `taint` | Impossible with shell |
| Measure complexity | ❌ | ✅ `complexity` / `cognitive` | Impossible with shell |
| Find dead code | ❌ | ✅ `dead` | Impossible with shell |
| Build LLM context bundle | ❌ | ✅ `context` | 1 call vs 5+ |
| Count lines | Either | `loc` | tldr adds code/comment split |
| Git history analysis | Either | `churn` / `hotspots` | tldr adds structure |
| Diff two files | Either | `diff` | tldr is AST-aware, multi-granularity |

---

## 6. Key Insight

**tldr doesn't replace shell commands — it replaces shell *workflows*.**

A single `tldr context fn src/` replaces the *workflow* of:
1. `grep` to find the function
2. `cat` to read it
3. `grep` to find callers
4. `cat` to read callers
5. `grep` to find callees

The token savings aren't in any single command — they're in eliminating the multi-step exploration loops that LLM harnesses currently burn through.

---

## 7. Implications for Agent Skill Design

1. **Don't replace grep for text search** — grep is fine for literal text. Use `tldr search` only when you need function-level context cards.
2. **Always use tldr for relationship queries** — callers, callees, impact, dead code. Shell cannot do this.
3. **Use `tldr context` as the default "understand this" command** — it's the highest-ROI single command for token efficiency.
4. **Reserve shell for file I/O** — reading, writing, checking existence. tldr is read-only analysis.
5. **The daemon matters** — for repeated queries in a session, `tldr daemon start` + `tldr warm` amortizes the parse cost across calls.
