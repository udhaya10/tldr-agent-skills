# Lens: Audit API & design — family chooser

**The question this lens answers**: "I want to understand or audit this codebase's API and design — which of `api-check`, `interface`, `inheritance`, `patterns` should I run?"

**Toolset**: `tldr api-check`, `tldr interface`, `tldr inheritance`, `tldr patterns`

**Why a family-chooser lens, why these tools**: All four touch "what does this code expose and how does it behave at the API level," but each has a sharply different intent. The discriminator is **intent × signal direction**: extract a surface (neutral), detect misuse (negative), map a hierarchy (structural), or extract conventions (positive, LLM-ready). Picking by name overlap ("they all sound like API tools") confuses misuse-detection for surface-extraction and ships the wrong artifact downstream.

## Decision tree

| Intent | Signal direction | Output shape | Reach for |
|--------|------------------|--------------|-----------|
| "Did the code MISUSE an API (missing timeout, bare except, weak crypto)?" | Negative — anti-patterns | Findings with `fix_suggestion` per call site | `tldr api-check` |
| "What's the public API SURFACE of this file/module?" | Neutral — extraction | Classes, functions, methods, decorators, docstrings | `tldr interface` |
| "What does the CLASS HIERARCHY look like? Diamonds? Mixins?" | Structural — parent→child edges | Edges + nodes + roots + leaves, optional DOT | `tldr inheritance` |
| "What unwritten CONVENTIONS does this codebase follow? (for an LLM)" | Positive — patterns | `constraints[]` strings, paste-ready for prompts | `tldr patterns` |

## The default

**No universal default — intent picks the tool, and the four intents are too distinct to collapse.** But for the most common framings:

- **"I'm onboarding an LLM (or contributor) to this codebase"** → `tldr patterns`. The `constraints[]` array is literally designed to paste into a system prompt, and `naming.consistency_score` gives a discipline readout.
- **"I'm about to refactor and want to know what I'd break"** → `tldr interface` to capture the surface BEFORE, refactor, capture again AFTER, diff.
- **"CI security gate for API misuse"** → `tldr api-check --severity high --category crypto,security`. Regex-based, fast, scales to 17 languages.
- **"I'm staring at a deep class tree"** → `tldr inheritance --class <NAME> -f dot | dot -Tsvg`.

## Common mistakes

- **Reaching for `tldr api-check` when the question is "what's the API surface?"** api-check finds MISUSE of APIs (rule violations); `tldr interface` extracts the surface itself. Different direction, different output.
- **Reaching for `tldr interface` when the question is "did we break the API?"** Interface extracts a surface but doesn't diff. The workflow is `interface` before + `interface` after + external diff. There is no built-in baseline check inside interface itself.
- **Parsing `tldr interface` output without branching on `Array.isArray()`.** Single-file PATH returns an OBJECT, directory PATH returns an ARRAY of those objects. There is no `mode` field. Non-source files (like `.md`) silently return an empty single-file object — they do NOT error.
- **Treating `tldr api-check`'s `rules_applied: 92` as a per-language count.** It counts rules across ALL 17 supported languages, even when `-l python` scopes the scan. Use `summary.apis_checked` for true per-language coverage.
- **Calling `tldr inheritance --depth N` without `--class`.** Fails with the audit suite's best error (exit 25, `TldrError::InvalidArgs`, explicit hint paragraph). `--depth` is a class-zoom modifier, not a global filter — always pair with `--class <NAME>`.
- **Trusting `tldr inheritance`'s empty output to mean "no hierarchy."** FOUR distinct failures (bad path, language mismatch, empty directory, non-source file) all return exit 0 with identical empty shapes. Verify the path externally and check `count > 0`.
- **Passing `tldr patterns --max-files 0` expecting "unlimited".** It literally means ZERO — returns metadata-only empty. The `--help` source-comment says "0 = unlimited" but the implementation contradicts it. Use `--max-files 999999` or omit the flag and accept the 1000 default.
- **Reading `tldr patterns` output without checking field presence.** Top-level keys like `error_handling`, `api_conventions`, `resource_management`, `validation` are CONDITIONAL — they vanish entirely on empty scans. Defensive parsing must check before reading.
- **Using `tldr patterns` to find anti-patterns.** Patterns extracts what the code DOES follow (positive); `tldr smells` extracts what it shouldn't (negative). They are inverse counterparts.

## What this lens captures

- The intent × signal-direction discriminator stays mechanical: misuse / surface / hierarchy / conventions is a 4-way choice with very little overlap once internalized.
- The default-by-framing approach surfaces the right tool for the four common "I want to understand this API" sub-intents.

## What this lens misses

- **Whether the API is actually USED correctly by callers.** None of these four traces caller-side behavior; `tldr references` and `tldr calls` (trace group) do that.
- **API stability over time.** Capture-and-diff with `tldr interface` is the workflow, but there's no built-in "is this a breaking change?" command.
- **Function-level contracts and invariants.** Those are `tldr contracts` / `tldr invariants` / `tldr specs` — covered in the coverage/testing family chooser.

## Pair with

- `audit-coverage-testing-family-chooser.md` — `patterns` can be a sub-analyzer of `tldr verify`; contracts/specs/invariants are the function-level constraint extractors
- `audit-structural-quality-family-chooser.md` — `inheritance` is the class-hierarchy axis; cohesion/coupling cover the intra-class and inter-module structural axes

## Sources

- `research/tool-cards/audit/api-check.md`
- `research/tool-cards/audit/interface.md`
- `research/tool-cards/audit/inheritance.md`
- `research/tool-cards/audit/patterns.md`
