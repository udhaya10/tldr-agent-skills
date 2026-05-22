[Skip to content](https://github.com/parcadei/llm-tldr#start-of-content)

You signed in with another tab or window. [Reload](https://github.com/parcadei/llm-tldr) to refresh your session.You signed out in another tab or window. [Reload](https://github.com/parcadei/llm-tldr) to refresh your session.You switched accounts on another tab or window. [Reload](https://github.com/parcadei/llm-tldr) to refresh your session.Dismiss alert

{{ message }}

[parcadei](https://github.com/parcadei)/ **[llm-tldr](https://github.com/parcadei/llm-tldr)** Public

- [Notifications](https://github.com/login?return_to=%2Fparcadei%2Fllm-tldr) You must be signed in to change notification settings
- [Fork\\
112](https://github.com/login?return_to=%2Fparcadei%2Fllm-tldr)
- [Star\\
1.2k](https://github.com/login?return_to=%2Fparcadei%2Fllm-tldr)


main

[**1** Branch](https://github.com/parcadei/llm-tldr/branches) [**0** Tags](https://github.com/parcadei/llm-tldr/tags)

[Go to Branches page](https://github.com/parcadei/llm-tldr/branches)[Go to Tags page](https://github.com/parcadei/llm-tldr/tags)

Go to file

Code

Open more actions menu

## Folders and files

| Name | Name | Last commit message | Last commit date |
| --- | --- | --- | --- |
| ## Latest commit<br>[![parcadei](https://avatars.githubusercontent.com/u/227596144?v=4&size=40)](https://github.com/parcadei)[parcadei](https://github.com/parcadei/llm-tldr/commits?author=parcadei)<br>[fix: correct license badge to AGPL-3.0](https://github.com/parcadei/llm-tldr/commit/c6494afdbe617b56c04ce562651117f9dd437d38)<br>4 months agoJan 17, 2026<br>[c6494af](https://github.com/parcadei/llm-tldr/commit/c6494afdbe617b56c04ce562651117f9dd437d38) · 4 months agoJan 17, 2026<br>## History<br>[65 Commits](https://github.com/parcadei/llm-tldr/commits/main/) <br>Open commit details<br>[View commit history for this file.](https://github.com/parcadei/llm-tldr/commits/main/) 65 Commits |
| [docs](https://github.com/parcadei/llm-tldr/tree/main/docs "docs") | [docs](https://github.com/parcadei/llm-tldr/tree/main/docs "docs") | [feat: add TypeScript/JavaScript CFG/DFG summaries to semantic embeddings](https://github.com/parcadei/llm-tldr/commit/91f3095ec853fa9efef436d36f7d3dc73921ba82 "feat: add TypeScript/JavaScript CFG/DFG summaries to semantic embeddings  * feat: add TypeScript/JavaScript CFG/DFG summaries to semantic embeddings  Adds full 5-layer semantic embedding support for TypeScript and JavaScript:  - Add TypeScript/JavaScript handling to _get_cfg_summary() and _get_dfg_summary() - Add TypeScript/JavaScript CFG/DFG cache building in build_semantic_index() - Add comprehensive tests verifying CFG/DFG summaries are populated - Update TLDR.md to accurately reflect which languages have full vs basic   semantic embedding support  Previously, semantic embeddings for TypeScript/JavaScript were missing the CFG complexity and DFG variable summaries, making semantic search less effective. Now TypeScript/JavaScript has parity with Python for semantic embeddings.  Tests added: - test_cfg_summary_populated - test_cfg_summary_simple_function - test_cfg_summary_javascript - test_dfg_summary_populated - test_dfg_summary_javascript - test_semantic_index_has_cfg_dfg - test_python_cfg_summary_works - test_typescript_matches_python_format  * refactor: address CodeRabbit review feedback  - Use pytest tmp_path fixture instead of tempfile.mkdtemp() for auto-cleanup - Use next() pattern instead of [0] indexing for safer extraction - Remove extraneous f-string prefixes where no placeholders exist - Assert function presence instead of silently skipping validations - Use set comprehension instead of set() with generator  * refactor: consolidate CFG/DFG extraction with language-to-extractor mapping  Eliminates code duplication between Python and TypeScript/JavaScript blocks by using a _get_extractors() helper that returns the appropriate extractor functions based on language. This makes it trivial to add support for additional languages in the future.") | 4 months agoJan 13, 2026 |
| [scripts](https://github.com/parcadei/llm-tldr/tree/main/scripts "scripts") | [scripts](https://github.com/parcadei/llm-tldr/tree/main/scripts "scripts") | [TLDR Code - Token-efficient code analysis for LLM agents](https://github.com/parcadei/llm-tldr/commit/d53fb0b0b6650b380157e9f18d9b1a5f205a0843 "TLDR Code - Token-efficient code analysis for LLM agents") | 4 months agoJan 9, 2026 |
| [tests](https://github.com/parcadei/llm-tldr/tree/main/tests "tests") | [tests](https://github.com/parcadei/llm-tldr/tree/main/tests "tests") | [fix: CommonJS call graph extraction + tests (Issue](https://github.com/parcadei/llm-tldr/commit/2489944edbb8c3190fbce6a4e3cafad06b98dc58 "fix: CommonJS call graph extraction + tests (Issue #21)  - Add call extraction for inferred-name functions (exports.foo = function) - Add 12 new tests for CommonJS call graph scenarios - Remove unused dataclasses import - Fix bare except clause  Closes #21") [#21](https://github.com/parcadei/llm-tldr/issues/21) [)](https://github.com/parcadei/llm-tldr/commit/2489944edbb8c3190fbce6a4e3cafad06b98dc58 "fix: CommonJS call graph extraction + tests (Issue #21)  - Add call extraction for inferred-name functions (exports.foo = function) - Add 12 new tests for CommonJS call graph scenarios - Remove unused dataclasses import - Fix bare except clause  Closes #21") | 4 months agoJan 13, 2026 |
| [tldr](https://github.com/parcadei/llm-tldr/tree/main/tldr "tldr") | [tldr](https://github.com/parcadei/llm-tldr/tree/main/tldr "tldr") | [fix: auto-detect languages when no cache exists](https://github.com/parcadei/llm-tldr/commit/b4beba699366802bb93f4dfc732af74828984e31 "fix: auto-detect languages when no cache exists  Previously --lang auto would fall back to Python if no cache. Now it detects languages automatically if .tldr/languages.json missing.  Flow: 1. Check cache → use if exists 2. No cache → detect languages from filesystem 3. No languages found → fall back to Python  All 17 languages tested and working.") | 4 months agoJan 14, 2026 |
| [.gitignore](https://github.com/parcadei/llm-tldr/blob/main/.gitignore ".gitignore") | [.gitignore](https://github.com/parcadei/llm-tldr/blob/main/.gitignore ".gitignore") | [TLDR Code - Token-efficient code analysis for LLM agents](https://github.com/parcadei/llm-tldr/commit/d53fb0b0b6650b380157e9f18d9b1a5f205a0843 "TLDR Code - Token-efficient code analysis for LLM agents") | 4 months agoJan 9, 2026 |
| [.tldrignore](https://github.com/parcadei/llm-tldr/blob/main/.tldrignore ".tldrignore") | [.tldrignore](https://github.com/parcadei/llm-tldr/blob/main/.tldrignore ".tldrignore") | [perf: cherry-pick performance improvements from PR](https://github.com/parcadei/llm-tldr/commit/885a05fb65ca136e3756cd2380e2f75b0be0e6de "perf: cherry-pick performance improvements from PR #4  - pdg_extractor: slots=True, O(1) node cache with _node_by_id - change_impact: replace regex with string ops in is_test_file (~18x faster) - analysis: Iterable type hints, better entry point handling - durability: Set instead of List for _edges_by_file (dedup, O(1) lookup) - session_warm: getattr fallback for Windows compatibility - stacked_db, workspace, install_swift: formatting - tldrignore: add project directory existence check  Also includes stashed changes: - semantic.py: _find_project_root() for cache location - .tldrignore: agent-specific excludes  Co-authored-by: Grigory Evko <grigory@evko.io>") [#4](https://github.com/parcadei/llm-tldr/pull/4) | 4 months agoJan 12, 2026 |
| [CONTRIBUTING.md](https://github.com/parcadei/llm-tldr/blob/main/CONTRIBUTING.md "CONTRIBUTING.md") | [CONTRIBUTING.md](https://github.com/parcadei/llm-tldr/blob/main/CONTRIBUTING.md "CONTRIBUTING.md") | [docs: add CONTRIBUTING.md with PR guidelines](https://github.com/parcadei/llm-tldr/commit/1f4301b42a6a8d1c25be728a1f116e71bc2a2fa4 "docs: add CONTRIBUTING.md with PR guidelines") | 4 months agoJan 11, 2026 |
| [LICENSE](https://github.com/parcadei/llm-tldr/blob/main/LICENSE "LICENSE") | [LICENSE](https://github.com/parcadei/llm-tldr/blob/main/LICENSE "LICENSE") | [chore: change license from Apache-2.0 to AGPL-3.0](https://github.com/parcadei/llm-tldr/commit/683d7ad86f89869a91d6fcdfa9750b2b1a6df042 "chore: change license from Apache-2.0 to AGPL-3.0") | 4 months agoJan 13, 2026 |
| [NOTICE](https://github.com/parcadei/llm-tldr/blob/main/NOTICE "NOTICE") | [NOTICE](https://github.com/parcadei/llm-tldr/blob/main/NOTICE "NOTICE") | [TLDR Code - Token-efficient code analysis for LLM agents](https://github.com/parcadei/llm-tldr/commit/d53fb0b0b6650b380157e9f18d9b1a5f205a0843 "TLDR Code - Token-efficient code analysis for LLM agents") | 4 months agoJan 9, 2026 |
| [README.md](https://github.com/parcadei/llm-tldr/blob/main/README.md "README.md") | [README.md](https://github.com/parcadei/llm-tldr/blob/main/README.md "README.md") | [fix: correct license badge to AGPL-3.0](https://github.com/parcadei/llm-tldr/commit/c6494afdbe617b56c04ce562651117f9dd437d38 "fix: correct license badge to AGPL-3.0") | 4 months agoJan 17, 2026 |
| [pyproject.toml](https://github.com/parcadei/llm-tldr/blob/main/pyproject.toml "pyproject.toml") | [pyproject.toml](https://github.com/parcadei/llm-tldr/blob/main/pyproject.toml "pyproject.toml") | [chore: bump version to 1.5.2](https://github.com/parcadei/llm-tldr/commit/8a9637050ecf47aa42e62dbf57819e6731b73b39 "chore: bump version to 1.5.2") | 4 months agoJan 14, 2026 |
| [requirements.txt](https://github.com/parcadei/llm-tldr/blob/main/requirements.txt "requirements.txt") | [requirements.txt](https://github.com/parcadei/llm-tldr/blob/main/requirements.txt "requirements.txt") | [TLDR Code - Token-efficient code analysis for LLM agents](https://github.com/parcadei/llm-tldr/commit/d53fb0b0b6650b380157e9f18d9b1a5f205a0843 "TLDR Code - Token-efficient code analysis for LLM agents") | 4 months agoJan 9, 2026 |
| [tldr\_code.py](https://github.com/parcadei/llm-tldr/blob/main/tldr_code.py "tldr_code.py") | [tldr\_code.py](https://github.com/parcadei/llm-tldr/blob/main/tldr_code.py "tldr_code.py") | [TLDR Code - Token-efficient code analysis for LLM agents](https://github.com/parcadei/llm-tldr/commit/d53fb0b0b6650b380157e9f18d9b1a5f205a0843 "TLDR Code - Token-efficient code analysis for LLM agents") | 4 months agoJan 9, 2026 |
| [uv.lock](https://github.com/parcadei/llm-tldr/blob/main/uv.lock "uv.lock") | [uv.lock](https://github.com/parcadei/llm-tldr/blob/main/uv.lock "uv.lock") | [chore: bump version to 1.5.1](https://github.com/parcadei/llm-tldr/commit/a85a6cdfe31e1f2175f58eef58c8a1516c61e78c "chore: bump version to 1.5.1") | 4 months agoJan 14, 2026 |
| View all files |

## Repository files navigation

# TLDR: Code Analysis for AI Agents

[Permalink: TLDR: Code Analysis for AI Agents](https://github.com/parcadei/llm-tldr#tldr-code-analysis-for-ai-agents)

[![PyPI](https://camo.githubusercontent.com/a81e154af32c2a06a73a9424e9066aa0dcfe00e4dc9dffa837107fbcd95fd6fc/68747470733a2f2f696d672e736869656c64732e696f2f707970692f762f6c6c6d2d746c6472)](https://pypi.org/project/llm-tldr/)[![Python](https://camo.githubusercontent.com/923b2464fa6fa1bc9d61812545f7b3a4224b588754b46d79e6dbb180ed45e517/68747470733a2f2f696d672e736869656c64732e696f2f707970692f707976657273696f6e732f6c6c6d2d746c6472)](https://pypi.org/project/llm-tldr/)[![License](https://camo.githubusercontent.com/e75361a6644d5c0f8c3efce74ee774f25811f1c1b9a2d7c7d3a1f05a33d790a3/68747470733a2f2f696d672e736869656c64732e696f2f62616467652f6c6963656e73652d4147504c2d2d332e302d626c7565)](https://github.com/parcadei/llm-tldr/blob/main/LICENSE)

**Give LLMs exactly the code they need. Nothing more.**

```
# One-liner: Install, index, search
pip install llm-tldr && tldr warm . && tldr semantic "what you're looking for" .
```

Your codebase is 100K lines. Claude's context window is 200K tokens. Raw code won't fit—and even if it did, the LLM would drown in irrelevant details.

TLDR extracts _structure_ instead of dumping _text_. The result: **95% fewer tokens** while preserving everything needed to understand and edit code correctly.

```
pip install llm-tldr
tldr warm .                    # Index your project
tldr context main --project .  # Get LLM-ready summary
```

* * *

## How It Works

[Permalink: How It Works](https://github.com/parcadei/llm-tldr#how-it-works)

TLDR builds 5 analysis layers, each answering different questions:

```
┌─────────────────────────────────────────────────────────────┐
│ Layer 5: Program Dependence  → "What affects line 42?"      │
│ Layer 4: Data Flow           → "Where does this value go?"  │
│ Layer 3: Control Flow        → "How complex is this?"       │
│ Layer 2: Call Graph          → "Who calls this function?"   │
│ Layer 1: AST                 → "What functions exist?"      │
└─────────────────────────────────────────────────────────────┘
```

**Why layers?** Different tasks need different depth:

- Browsing code? Layer 1 (structure) is enough
- Refactoring? Layer 2 (call graph) shows what breaks
- Debugging null? Layer 5 (slice) shows only relevant lines

The daemon keeps indexes in memory for **100ms queries** instead of 30-second CLI spawns.

### Architecture

[Permalink: Architecture](https://github.com/parcadei/llm-tldr#architecture)

```
┌──────────────────────────────────────────────────────────────────┐
│                         YOUR CODE                                │
│  src/*.py, lib/*.ts, pkg/*.go                                    │
└───────────────────────────┬──────────────────────────────────────┘
                            │ tree-sitter
                            ▼
┌──────────────────────────────────────────────────────────────────┐
│                     5-LAYER ANALYSIS                             │
│  ┌─────────┐ ┌─────────┐ ┌─────────┐ ┌─────────┐ ┌─────────┐     │
│  │   AST   │→│  Calls  │→│   CFG   │→│   DFG   │→│   PDG   │     │
│  │   L1    │ │   L2    │ │   L3    │ │   L4    │ │   L5    │     │
│  └─────────┘ └─────────┘ └─────────┘ └─────────┘ └─────────┘     │
└───────────────────────────┬──────────────────────────────────────┘
                            │ bge-large-en-v1.5
                            ▼
┌──────────────────────────────────────────────────────────────────┐
│                    SEMANTIC INDEX                                │
│  1024-dim embeddings in FAISS  →  "find JWT validation"          │
└───────────────────────────┬──────────────────────────────────────┘
                            │
                            ▼
┌──────────────────────────────────────────────────────────────────┐
│                       DAEMON                                     │
│  In-memory indexes  •  100ms queries  •  Auto-lifecycle          │
└──────────────────────────────────────────────────────────────────┘
```

### The Semantic Layer: Search by Behavior

[Permalink: The Semantic Layer: Search by Behavior](https://github.com/parcadei/llm-tldr#the-semantic-layer-search-by-behavior)

The real power comes from combining all 5 layers into **searchable embeddings**.

Every function gets indexed with:

- Signature + docstring (L1)
- What it calls + who calls it (L2)
- Complexity metrics (L3)
- Data flow patterns (L4)
- Dependencies (L5)
- First ~10 lines of actual code

This gets encoded into **1024-dimensional vectors** using `bge-large-en-v1.5`. The result: search by _what code does_, not just what it says.

```
# "validate JWT" finds verify_access_token() even without that exact text
tldr semantic "validate JWT tokens and check expiration" .
```

**Why this works:** Traditional search finds `authentication` in variable names and comments. Semantic search understands that `verify_access_token()` _performs_ JWT validation because the call graph and data flow reveal its purpose.

### Setting Up Semantic Search

[Permalink: Setting Up Semantic Search](https://github.com/parcadei/llm-tldr#setting-up-semantic-search)

```
# Build the semantic index (one-time, ~2 min for typical project)
tldr warm /path/to/project

# Search by behavior
tldr semantic "database connection pooling" .
```

Embedding dependencies (`sentence-transformers`, `faiss-cpu`) are included with `pip install llm-tldr`. The index is cached in `.tldr/cache/semantic.faiss`.

### Keeping the Index Fresh

[Permalink: Keeping the Index Fresh](https://github.com/parcadei/llm-tldr#keeping-the-index-fresh)

The daemon tracks dirty files and auto-rebuilds after 20 changes, but you need to notify it when files change:

```
# Notify daemon of a changed file
tldr daemon notify src/auth.py --project .
```

**Integration options:**

1. **Git hook** (post-commit):



```
git diff --name-only HEAD~1 | xargs -I{} tldr daemon notify {} --project .
```

2. **Editor hook** (on save):



```
tldr daemon notify "$FILE" --project .
```

3. **Manual rebuild** (when needed):



```
tldr warm .  # Full rebuild
```


The daemon auto-rebuilds semantic embeddings in the background once the dirty threshold (default: 20 files) is reached.

* * *

## The Workflow

[Permalink: The Workflow](https://github.com/parcadei/llm-tldr#the-workflow)

### Before Reading Code

[Permalink: Before Reading Code](https://github.com/parcadei/llm-tldr#before-reading-code)

```
tldr tree src/                      # See file structure
tldr structure src/ --lang python   # See functions/classes
```

### Before Editing

[Permalink: Before Editing](https://github.com/parcadei/llm-tldr#before-editing)

```
tldr extract src/auth.py            # Full file analysis
tldr context login --project .      # LLM-ready summary (95% savings)
```

### Before Refactoring

[Permalink: Before Refactoring](https://github.com/parcadei/llm-tldr#before-refactoring)

```
tldr impact login .                 # Who calls this? (reverse call graph)
tldr change-impact                  # Which tests need to run?
```

### Debugging

[Permalink: Debugging](https://github.com/parcadei/llm-tldr#debugging)

```
tldr slice src/auth.py login 42     # What affects line 42?
tldr dfg src/auth.py login          # Trace data flow
```

### Finding Code by Behavior

[Permalink: Finding Code by Behavior](https://github.com/parcadei/llm-tldr#finding-code-by-behavior)

```
tldr semantic "validate JWT tokens" .   # Natural language search
```

* * *

## Quick Setup

[Permalink: Quick Setup](https://github.com/parcadei/llm-tldr#quick-setup)

### 1\. Install

[Permalink: 1. Install](https://github.com/parcadei/llm-tldr#1-install)

```
pip install llm-tldr
```

### 2\. Index Your Project

[Permalink: 2. Index Your Project](https://github.com/parcadei/llm-tldr#2-index-your-project)

```
tldr warm /path/to/project
```

This builds all analysis layers and starts the daemon. Takes 30-60 seconds for a typical project, then queries are instant.

### 3\. Start Using

[Permalink: 3. Start Using](https://github.com/parcadei/llm-tldr#3-start-using)

```
tldr context main --project .   # Get context for a function
tldr impact helper_func .       # See who calls it
tldr semantic "error handling"  # Find by behavior
```

* * *

## Real Example: Why This Matters

[Permalink: Real Example: Why This Matters](https://github.com/parcadei/llm-tldr#real-example-why-this-matters)

**Scenario:** Debug why `user` is null on line 42.

**Without TLDR:**

1. Read the 150-line function
2. Trace every variable manually
3. Miss the bug because it's hidden in control flow

**With TLDR:**

```
tldr slice src/auth.py login 42
```

**Output:** Only 6 lines that affect line 42:

```
3:   user = db.get_user(username)
7:   if user is None:
12:      raise NotFound
28:  token = create_token(user)  # ← BUG: skipped null check
35:  session.token = token
42:  return session
```

The bug is obvious. Line 28 uses `user` without going through the null check path.

* * *

## Command Reference

[Permalink: Command Reference](https://github.com/parcadei/llm-tldr#command-reference)

### Exploration

[Permalink: Exploration](https://github.com/parcadei/llm-tldr#exploration)

| Command | What It Does |
| --- | --- |
| `tldr tree [path]` | File tree |
| `tldr structure [path] --lang <lang>` | Functions, classes, methods |
| `tldr search <pattern> [path]` | Text pattern search |
| `tldr extract <file>` | Full file analysis |

### Analysis

[Permalink: Analysis](https://github.com/parcadei/llm-tldr#analysis)

| Command | What It Does |
| --- | --- |
| `tldr context <func> --project <path>` | LLM-ready summary (95% savings) |
| `tldr cfg <file> <function>` | Control flow graph |
| `tldr dfg <file> <function>` | Data flow graph |
| `tldr slice <file> <func> <line>` | Program slice |

### Cross-File

[Permalink: Cross-File](https://github.com/parcadei/llm-tldr#cross-file)

| Command | What It Does |
| --- | --- |
| `tldr calls [path]` | Build call graph |
| `tldr impact <func> [path]` | Find all callers (reverse call graph) |
| `tldr dead [path]` | Find unreachable code |
| `tldr arch [path]` | Detect architecture layers |
| `tldr imports <file>` | Parse imports |
| `tldr importers <module> [path]` | Find files that import a module |

### Semantic

[Permalink: Semantic](https://github.com/parcadei/llm-tldr#semantic)

| Command | What It Does |
| --- | --- |
| `tldr warm <path>` | Build all indexes (including embeddings) |
| `tldr semantic <query> [path]` | Natural language code search |

### Diagnostics

[Permalink: Diagnostics](https://github.com/parcadei/llm-tldr#diagnostics)

| Command | What It Does |
| --- | --- |
| `tldr diagnostics <file>` | Type check + lint |
| `tldr change-impact [files]` | Find tests affected by changes |
| `tldr doctor` | Check/install diagnostic tools |

### Daemon

[Permalink: Daemon](https://github.com/parcadei/llm-tldr#daemon)

| Command | What It Does |
| --- | --- |
| `tldr daemon start` | Start background daemon |
| `tldr daemon stop` | Stop daemon |
| `tldr daemon status` | Check status |

* * *

## Supported Languages

[Permalink: Supported Languages](https://github.com/parcadei/llm-tldr#supported-languages)

Python, TypeScript, JavaScript, Go, Rust, Java, C, C++, Ruby, PHP, C#, Kotlin, Scala, Swift, Lua, Elixir

Language is auto-detected or specify with `--lang`.

* * *

## MCP Integration

[Permalink: MCP Integration](https://github.com/parcadei/llm-tldr#mcp-integration)

For AI tools (Claude Desktop, Claude Code):

**Claude Desktop** \- Add to `~/Library/Application Support/Claude/claude_desktop_config.json`:

```
{
  "mcpServers": {
    "tldr": {
      "command": "tldr-mcp",
      "args": ["--project", "/path/to/your/project"]
    }
  }
}
```

**Claude Code** \- Add to `.claude/settings.json`:

```
{
  "mcpServers": {
    "tldr": {
      "command": "tldr-mcp",
      "args": ["--project", "."]
    }
  }
}
```

* * *

## Configuration

[Permalink: Configuration](https://github.com/parcadei/llm-tldr#configuration)

### `.tldrignore` \- Exclude Files

[Permalink: .tldrignore - Exclude Files](https://github.com/parcadei/llm-tldr#tldrignore---exclude-files)

TLDR respects `.tldrignore` (gitignore syntax) for all commands including `tree`, `structure`, `search`, `calls`, and semantic indexing:

```
# Auto-create with sensible defaults
tldr warm .  # Creates .tldrignore if missing
```

**Default exclusions:**

- `node_modules/`, `.venv/`, `__pycache__/`
- `dist/`, `build/`, `*.egg-info/`
- Binary files (`*.so`, `*.dll`, `*.whl`)
- Security files (`.env`, `*.pem`, `*.key`)

**Customize** by editing `.tldrignore`:

```
# Add your patterns
large_test_fixtures/
vendor/
data/*.csv
```

**CLI Flags:**

```
# Add patterns from command line (can be repeated)
tldr --ignore "packages/old/" --ignore "*.generated.ts" tree .

# Bypass all ignore patterns
tldr --no-ignore tree .
```

### Settings - Daemon Behavior

[Permalink: Settings - Daemon Behavior](https://github.com/parcadei/llm-tldr#settings---daemon-behavior)

Create `.tldr/config.json` for daemon settings:

```
{
  "semantic": {
    "enabled": true,
    "auto_reindex_threshold": 20
  }
}
```

| Setting | Default | Description |
| --- | --- | --- |
| `enabled` | `true` | Enable semantic search |
| `auto_reindex_threshold` | `20` | Files changed before auto-rebuild |

### Monorepo Support

[Permalink: Monorepo Support](https://github.com/parcadei/llm-tldr#monorepo-support)

For monorepos, create `.claude/workspace.json` to scope indexing:

```
{
  "active_packages": ["packages/core", "packages/api"],
  "exclude_patterns": ["**/fixtures/**"]
}
```

* * *

## Performance

[Permalink: Performance](https://github.com/parcadei/llm-tldr#performance)

| Metric | Raw Code | TLDR | Improvement |
| --- | --- | --- | --- |
| Tokens for function context | 21,000 | 175 | **99% savings** |
| Tokens for codebase overview | 104,000 | 12,000 | **89% savings** |
| Query latency (daemon) | 30s | 100ms | **300x faster** |

* * *

## Deep Dive

[Permalink: Deep Dive](https://github.com/parcadei/llm-tldr#deep-dive)

For the full architecture explanation, benchmarks, and advanced workflows:

**[Full Documentation](https://github.com/parcadei/llm-tldr/blob/main/docs/TLDR.md)**

* * *

## License

[Permalink: License](https://github.com/parcadei/llm-tldr#license)

AGPL-3.0 - See LICENSE file.

## About

95% token savings. 155x faster queries. 16 languages. LLMs can't read your entire codebase. TLDR extracts structure, traces dependencies, and gives them exactly what they need.


### Resources

[Readme](https://github.com/parcadei/llm-tldr#readme-ov-file)

### License

[AGPL-3.0 license](https://github.com/parcadei/llm-tldr#AGPL-3.0-1-ov-file)

### Contributing

[Contributing](https://github.com/parcadei/llm-tldr#contributing-ov-file)

### Uh oh!

There was an error while loading. [Please reload this page](https://github.com/parcadei/llm-tldr).

[Activity](https://github.com/parcadei/llm-tldr/activity)

### Stars

[**1.2k**\\
stars](https://github.com/parcadei/llm-tldr/stargazers)

### Watchers

[**8**\\
watching](https://github.com/parcadei/llm-tldr/watchers)

### Forks

[**112**\\
forks](https://github.com/parcadei/llm-tldr/forks)

[Report repository](https://github.com/contact/report-content?content_url=https%3A%2F%2Fgithub.com%2Fparcadei%2Fllm-tldr&report=parcadei+%28user%29)

## [Releases](https://github.com/parcadei/llm-tldr/releases)

No releases published

## [Packages\  0](https://github.com/users/parcadei/packages?repo_name=llm-tldr)

No packages published

## [Contributors\  7](https://github.com/parcadei/llm-tldr/graphs/contributors)

- [![@parcadei](https://avatars.githubusercontent.com/u/227596144?s=64&v=4)](https://github.com/parcadei)
- [![@claude](https://avatars.githubusercontent.com/u/81847?s=64&v=4)](https://github.com/claude)
- [![@AntiS3mantic](https://avatars.githubusercontent.com/u/205022630?s=64&v=4)](https://github.com/AntiS3mantic)
- [![@francis-io](https://avatars.githubusercontent.com/u/10199020?s=64&v=4)](https://github.com/francis-io)
- [![@BrennerSpear](https://avatars.githubusercontent.com/u/12127609?s=64&v=4)](https://github.com/BrennerSpear)
- [![@GrigoryEvko](https://avatars.githubusercontent.com/u/24699844?s=64&v=4)](https://github.com/GrigoryEvko)
- [![@selogerkkk](https://avatars.githubusercontent.com/u/101962124?s=64&v=4)](https://github.com/selogerkkk)

## Languages

- [Python100.0%](https://github.com/parcadei/llm-tldr/search?l=python)

You can’t perform that action at this time.