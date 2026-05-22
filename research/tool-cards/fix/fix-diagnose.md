# tldr fix diagnose

**Pitch**: Pure error-text parser — takes raw compiler, runtime, or test output and returns a structured `{ error_code, message, location?, confidence }` JSON diagnosis, without attempting any fix.

**Why reach for it**
- Unified schema across 7+ tool dialects (Python tracebacks, Rust E0xxx, TS2xxx, gcc/clang, jest/mocha, eslint, ruff) — agents stop writing per-tool regex
- Very fast (~10ms, pure text parser, no daemon needed)
- Exit 0 whenever the error parses — works as a structured input stage for an LLM-driven fixer regardless of fixability
- `--stdin` accepts piped error text directly: `<runtime-cmd> 2>&1 | tldr fix diagnose -s <FILE> --stdin`

**When to use**
- First step of an LLM-fix pipeline: convert raw error text into structured JSON before prompting the model
- Filtering or routing errors by `error_code` / `location` without trying to repair them
- Sanity-checking that a runtime's error format is even recognizable before reaching for `fix apply` or `fix check`

**When NOT to use**
- Want to actually attempt a registry fix — use `tldr fix apply`
- Want a test → fix → retest loop — use `tldr fix check`
- Have source files to lint or type-check, not error text — use `tldr diagnostics`

**Output in plain words**: A small JSON object naming the language, the parsed error code, a human-readable message with a suggested action, an optional `location: { file, line }` when the error text carries file:line metadata, and a confidence band of Low / Medium / High.

**Killer detail**: Exits 0 on `confidence: Low` — its sibling `tldr fix apply` exits 1 on the same diagnosis. This is the discriminator: diagnose says "I parsed it" with exit 0; apply says "I parsed it but can't deterministically fix it" with exit 1. Use diagnose when the downstream consumer is an LLM that wants the parse regardless of fixability.

**Source**: `research/tldr/fix/fix-diagnose.md`
