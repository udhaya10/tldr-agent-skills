# tldr patterns

**Pitch**: Convention and design-pattern inferrer — extracts the implicit rules a codebase follows (naming style, error handling, API conventions) and emits them as LLM-ready constraint statements.

**Why reach for it**
- The single best command for "what are the unwritten rules of this codebase?" — useful before contributing or generating new code
- `constraints[]` array contains human-readable rules like `"functions must use snake_case"` — paste-ready for prompts
- `naming.consistency_score` (0.0-1.0) gives an at-a-glance health signal for naming discipline
- Multi-axis: surfaces naming, imports, type coverage, error handling, API conventions, validation, resource management together

**When to use**
- Onboarding a new contributor or LLM to a codebase — feed `constraints[]` into the system prompt
- Auditing a codebase for convention drift after several contributors
- Establishing a style baseline before introducing a new module
- Building generation tools (LLM code-writers) that need to match local conventions

**When NOT to use**
- Looking for ANTI-patterns rather than conventions — `tldr smells` is the inverse counterpart
- Want API misuse rules (no-timeout HTTP etc.) rather than codebase conventions — `tldr api-check`

**Output in plain words**: Always-present `{ metadata, conflicts, constraints, naming, import_patterns, type_coverage }` plus conditionally-present `{ error_handling?, api_conventions?, resource_management?, validation? }` blocks. Each conditional block has a `patterns[]` with `pattern_id`, `confidence`, and up to 3 `evidence` examples per pattern.

**Killer detail**: `--max-files 0` literally means ZERO files (returns metadata-only empty), despite the `--help` text claiming `"0 = unlimited"` — a source-comment drift. Use a high value like `--max-files 999999` for unlimited, or just omit the flag and accept the 1000 default.

**Other footguns**
- Non-source single files error with `"Error: Unsupported language: md"` (exit 11) — extension-only wording, shorter than `tldr loc` or `tldr complexity`'s equivalents. Branch on exit 11 to detect.
- Top-level keys are CONDITIONAL on whether patterns were detected. Defensive code must check field presence before reading `error_handling`, `api_conventions`, etc. — they vanish entirely on empty scans.

**Source**: `research/tldr/audit/patterns.md`
