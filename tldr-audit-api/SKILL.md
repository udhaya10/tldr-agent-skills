---
name: tldr-audit-api
description: Audit a codebase's API design — extract the public surface, detect API misuse, map the class hierarchy, or pull out the unwritten conventions an LLM needs to match local style. Reach for this when the question is about INTERFACES, SIGNATURES, INHERITANCE, or DESIGN PATTERNS rather than raw structure. Triggers on "extract the API surface", "extract interfaces", "what does this module expose", "class hierarchy", "inheritance tree", "find API misuse", "API stability check", "design patterns in this code", "extract conventions for LLM onboarding", "is the crypto / HTTP usage correct?".
allowed-tools: [Bash]
compatibility: "Requires tldr-code CLI v0.4.0+. Tested on darwin and linux."
metadata:
  version: "1.0.0"
  author: "udhaya10"
  repository: "udhaya10/tldr-agent-skills"
  tldr.cli-version: "0.4.0"
  tldr.research-commit: "a025973"
  tldr.commands-wrapped: "api-check, interface, inheritance, patterns, surface"
---

# tldr-audit-api

## When to use

Use this skill when the question is about a codebase's **API design** — what it exposes (surface), how it's misused (anti-patterns), how its classes inherit (hierarchy), or what conventions it implicitly enforces (patterns). These are four sharply different intents that share the word "API"; the four tools in this skill each answer exactly one of them.

The discriminator vs sibling skills:

- For **structural** questions (coupling, hubs, layering) rather than API-design → see `tldr-architecture`
- For **broader codebase orientation** (the API extraction is part of getting oriented, not API-design specific) → see `tldr-orient-codebase`
- For **CVE-style dependency vulnerabilities** → see `tldr-audit-security`
- For **function-level contracts and invariants** → see `tldr-audit-coverage`

## The decision — which tool to use

This family is **intent-conditional** — there is no single default. The discriminator is **intent × signal direction**: extract a surface (neutral), detect misuse (negative), map a hierarchy (structural), or extract conventions (positive, LLM-ready).

| Intent | Signal direction | Output shape | Reach for |
|--------|------------------|--------------|-----------|
| "Did the code MISUSE an API (missing timeout, bare except, weak crypto)?" | Negative — anti-patterns | Findings with `fix_suggestion` per call site | `tldr api-check` |
| "What's the public API SURFACE of this file/module?" | Neutral — extraction | Classes, functions, methods, decorators, docstrings | `tldr interface` |
| "What does a stdlib or third-party PACKAGE expose?" | Neutral — extraction | Per-API qualified-name entries with structured `signature.params[]` | `tldr surface` |
| "What does the CLASS HIERARCHY look like? Diamonds? Mixins?" | Structural — parent→child edges | Edges + nodes + roots + leaves, optional DOT | `tldr inheritance` |
| "What unwritten CONVENTIONS does this codebase follow? (for an LLM)" | Positive — patterns | `constraints[]` strings, paste-ready for prompts | `tldr patterns` |

**Intent-specific defaults**:

- "Detect API misuse / CI gating" → `tldr api-check --severity high --category crypto,security`
- "Extract the API surface of a project file/dir for refactor or docs" → `tldr interface <path>`
- "Extract the API surface of an installed package" → `tldr surface <package>`
- "Map the class hierarchy" → `tldr inheritance --class <NAME> -f dot | dot -Tsvg`
- "Extract codebase conventions for LLM onboarding" → `tldr patterns` (feed `constraints[]` into the system prompt)

## Tool reference

> **Command guardrail**: Only invoke the exact subcommands documented below. Do **not** invent or guess command names. If uncertain whether a command exists, run `tldr --help` before proceeding.

### `tldr api-check` — pattern-based API misuse scanner

Catches classic API misuses — no-timeout HTTP, bare `except`, weak crypto, unclosed files — across 17 languages, each finding shipped with a `fix_suggestion`.

**Why reach for it**:
- Curated, language-tagged rules (rule IDs like `PY001`, `JS003`, `CPP001`) keep false positives tight
- `fix_suggestion` and `code_context` per finding turn output directly into LLM remediation prompts
- `--severity` is a MINIMUM threshold and `--category` is comma-separated OR — both compose for tight CI gates
- Regex-based (not AST), so it scales fast and works on partial / generated / unparseable code

**When to use**:
- CI gate for "missing timeout / bare except / weak crypto" bugs — pair `--severity high --category crypto,security`
- Security review of HTTP and crypto call sites without spinning up a language server
- Quick audit on a new dependency or vendor drop to spot misuse patterns

**Usage**:
```bash
tldr api-check [path] [-l <lang>] [--severity low|medium|high|critical] [--category <c1,c2,...>]
```

**Output**: An `APICheckReport` with `findings[]` (each carrying `file`, `line`, `column`, `rule` (id/name/category/severity/description/correct_usage), `api_call`, `message`, `fix_suggestion`, `code_context`), a `summary` with `by_category`/`by_severity`, and top-level `total_findings`/`files_scanned`.

**Killer detail**: `rules_applied: 92` counts rules across ALL 17 supported languages — even when `-l python` scopes the scan to Python-only files. The number does NOT reflect rules actually executed. **Use `summary.apis_checked` for true per-language coverage.**

---

### `tldr interface` — public API surface extractor (project file/dir)

Pulls every top-level class, function, method, decorator, and docstring out of a file or directory across 18 languages.

**Why reach for it**:
- Distills a file to just its consumer-visible API — what an external caller would see — without the body noise
- `all_exports[]` is a sorted public-name list ready for `__all__` / module-doc generation
- Captures decorators, base classes, and docstrings per method, not just bare signatures
- Built-in text format renders developer-friendly API documentation directly

**When to use**:
- Generating or refreshing API documentation for a module
- Before-and-after API surface comparison (capture → refactor → capture → diff) to check breakage
- Building a contract for a downstream consumer to mock or stub against
- Quickly seeing what a package exposes without grepping for `class` / `def` patterns

**Usage**:
```bash
tldr interface <path> [-l <lang>] [-f json|text]
```

**Output**: For a single file, an OBJECT `{ file, all_exports, functions, classes }` where each class has `name, lineno, bases, methods` and each function carries its signature + docstring. For a directory, an ARRAY of those file-objects. Empty directory returns `[]`.

**Killer detail**: The top-level JSON shape **flips between OBJECT (single file or non-source file like `.md`) and ARRAY (directory)** based on PATH type. Consumers must branch on `Array.isArray()` before parsing — there is no `mode` field to disambiguate, and non-source files silently return an empty single-file object instead of erroring.

---

### `tldr surface` — machine-readable API extraction of an installed package

Per-package public-API dump — every function, class, method, and constant with structured signatures including parameter kinds. Complementary to `tldr interface`: `interface` is the right pick for project file/dir trees, `surface` is the right pick for named installed packages.

**Why reach for it**:
- Package mode (`tldr surface <name>`) is the right tool when an agent needs to know what a library exposes without grep-walking `node_modules` / `site-packages`
- `--lookup <qualified.name>` filters to a single API for sharp targeted questions
- Per-language resolvers handle Python stdlib, JS/TS `node_modules`, and Rust Cargo manifests automatically
- `signature.params[]` distinguishes `*args` (variadic) from `**kwargs` (keyword-only)

**When to use**:
- "What does this stdlib or third-party package expose?" → `tldr surface <package>`
- Pulling a single function's parameter list → `tldr surface <package> --lookup <qualified.name>`
- Producing API-surface JSON for downstream contract comparison

**Usage**:
```bash
tldr surface <package-or-path> [--lookup <qualified.name>] [-l <lang>]
```

**Output**: JSON with `package`, `language`, `total`, an `apis` array of typed entries (`qualified_name`, `kind`, `module`, structured `signature`), `files_skipped`, and `warnings`.

**Killer detail**: Directory targets are an agent footgun — `tldr surface backend` produced **38,111 lines** of output. **Reserve `surface` for named packages; use `tldr interface` when the target is a project tree.**

---

### `tldr inheritance` — class-hierarchy extractor

Maps every parent→child edge — with ABC / Protocol / mixin / diamond detection — and a first-class DOT visualization path.

**Why reach for it**:
- One of the few audit commands that emits DOT directly; pipe to `dot -Tsvg` for a publication-ready hierarchy diagram
- `--class <NAME>` zooms to a single class's ancestors + descendants — focused output that fits in an LLM context
- External base resolution flags stdlib bases (`ABC`, `Exception`) distinctly with `resolution: "stdlib"`
- Handles Python `extends`, TypeScript `extends`/`implements`, Go struct `embeds`, and Rust trait `impl` blocks under one `kind` taxonomy

**When to use**:
- Visualizing or auditing a deep class hierarchy before a refactor
- Producing an architecture diagram for documentation (`-f dot | dot -Tsvg`)
- Investigating a specific class's ancestry/descendants (`--class <NAME> --depth N`)
- Finding diamond inheritance or mixin abuse

**Usage**:
```bash
tldr inheritance <path> [-l <lang>] [--class <NAME>] [--depth <N>] [-f json|dot]
```

**Output**: An `InheritanceReport` with `edges[]` (each `child`, `parent`, file/line refs, `kind`, `external`, `resolution`), `nodes[]`, `roots[]`, `leaves[]`, `count`, and `languages[]`. With `-f dot`, a `digraph inheritance { rankdir=BT; ... }` with abstract classes styled lightyellow and external nodes as dashed lightblue ellipses.

**Killer detail**: FOUR distinct failure modes — bad path, language mismatch, empty directory, non-source file — all return exit 0 with the identical empty shape (`count: 0`, every array empty). Agents cannot tell them apart from output. **Verify the path externally and check `count > 0`.**

**Other footguns**:
- `--depth` without `--class` fails with exit 25 (`TldrError::InvalidArgs`) and an explicit hint paragraph. `--depth` is a class-zoom modifier, not a global filter — always pair with `--class <NAME>`.
- `--class NoSuchClass` returns exit 24 (`TldrError::NotFound`), distinct from `FunctionNotFound`'s exit 20 — branch on the exit code when scripting.

---

### `tldr patterns` — convention and design-pattern inferrer

Extracts the implicit rules a codebase follows (naming style, error handling, API conventions) and emits them as LLM-ready constraint statements.

**Why reach for it**:
- The single best command for "what are the unwritten rules of this codebase?" — useful before contributing or generating new code
- `constraints[]` array contains human-readable rules like `"functions must use snake_case"` — paste-ready for prompts
- `naming.consistency_score` (0.0-1.0) gives an at-a-glance health signal for naming discipline
- Multi-axis: surfaces naming, imports, type coverage, error handling, API conventions, validation, and resource management together

**When to use**:
- Onboarding a new contributor or LLM to a codebase — feed `constraints[]` into the system prompt
- Auditing for convention drift after several contributors
- Establishing a style baseline before introducing a new module
- Building LLM code-writers that need to match local conventions

**Usage**:
```bash
tldr patterns [path] [-l <lang>] [--max-files <N>]
```

**Output**: Always-present `{ metadata, conflicts, constraints, naming, import_patterns, type_coverage }` plus conditionally-present `{ error_handling?, api_conventions?, resource_management?, validation? }` blocks. Each conditional block has `patterns[]` with `pattern_id`, `confidence`, and up to 3 `evidence` examples per pattern.

**Killer detail**: `--max-files 0` literally means ZERO files (returns metadata-only empty), despite the `--help` text claiming `"0 = unlimited"` — a source-comment drift. **Use `--max-files 999999` for unlimited, or omit the flag and accept the 1000 default.**

**Other footguns**:
- Non-source single files error with `"Error: Unsupported language: md"` (exit 11) — extension-only wording. Branch on exit 11 to detect.
- Top-level keys `error_handling`, `api_conventions`, `resource_management`, `validation` are CONDITIONAL on whether patterns were detected — they vanish entirely on empty scans. Defensive parsing must check field presence before reading.

## Common mistakes

- **Reaching for `tldr api-check` when the question is "what's the API surface?"** api-check finds MISUSE of APIs (rule violations); `tldr interface` extracts the surface itself. Different direction, different output.
- **Reaching for `tldr interface` when the question is "did we break the API?"** Interface extracts a surface but doesn't diff. The workflow is `interface` before + `interface` after + external diff. There is no built-in baseline check inside interface itself.
- **Parsing `tldr interface` output without branching on `Array.isArray()`.** Single-file PATH returns an OBJECT, directory PATH returns an ARRAY of those objects. There is no `mode` field. Non-source files (like `.md`) silently return an empty single-file object — they do NOT error.
- **Pointing `tldr surface` at a project directory.** Output explodes (~38,000 lines for a moderate backend). Reserve `surface` for named packages (`tldr surface json`, `tldr surface react`); reach for `tldr interface` when the target is a project tree.
- **Treating `tldr api-check`'s `rules_applied: 92` as a per-language count.** It counts rules across ALL 17 supported languages, even when `-l python` scopes the scan. Use `summary.apis_checked` for true per-language coverage.
- **Calling `tldr inheritance --depth N` without `--class`.** Fails with exit 25 (`TldrError::InvalidArgs`) and an explicit hint paragraph. `--depth` is a class-zoom modifier, not a global filter — always pair with `--class <NAME>`.
- **Trusting `tldr inheritance`'s empty output to mean "no hierarchy."** FOUR distinct failures (bad path, language mismatch, empty directory, non-source file) all return exit 0 with identical empty shapes. Verify the path externally and check `count > 0`.
- **Passing `tldr patterns --max-files 0` expecting "unlimited".** It literally means ZERO — returns metadata-only empty. Use `--max-files 999999` or omit the flag and accept the 1000 default.
- **Reading `tldr patterns` output without checking field presence.** `error_handling`, `api_conventions`, `resource_management`, `validation` are CONDITIONAL — they vanish entirely on empty scans.
- **Using `tldr patterns` to find anti-patterns.** Patterns extracts what the code DOES follow (positive); `tldr smells` (in `tldr-audit-smells`) extracts what it shouldn't (negative). They are inverse counterparts.

## See also

- `tldr-architecture` — when the question is structural (hubs, coupling, layering) rather than API-design
- `tldr-orient-codebase` — when API extraction is part of broader orientation, not specific API design
- `tldr-audit-coverage` — for function-level contracts, invariants, and verification (the per-function counterpart to interface-level extraction)
- `tldr-audit-smells` — for the negative-signal counterpart to `patterns` (anti-patterns and code debt)
- `tldr-audit-security` — for CVE-style dependency vulnerabilities and deep taint analysis (`api-check` is regex-based; vuln/secure/taint are deeper)
