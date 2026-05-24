# tldr references

> **Before writing the Usage block**: check `verified-invocations.md` in this group's
> `tool-cards/trace/` directory and copy the canonical syntax verbatim.
> Do NOT reconstruct syntax from prose — that is how hallucinated flags get introduced.

**Pitch**: Every use-site of a symbol across the codebase, AST-verified and classified as call/read/write/import/type.

**Why reach for it**
- Replaces `grep -rn` with kind classification, confidence scores, and false-positive filtering
- Surfaces ALL definitions when a symbol name lives in multiple files (e.g., the same helper in three modules)
- `--kinds import` reveals importers a call-graph view would miss; `--kinds write` finds mutation sites
- Friendly "no results" stderr block suggests recovery steps when the search comes up empty

**When to use**
- Need a flat enumeration of every use site of one symbol — broader than calls (also reads, writes, imports, types)
- Verifying a `possibly_dead` candidate from `tldr dead` really has only one reference
- Renaming preparation, where you need to find every touch point
- Same symbol exists in multiple files and you need to see all definitions

**When NOT to use**
- Want recursive callers-of-callers — use `tldr impact <fn>` (this is flat, level-1 only)
- Want the whole-project edge list — use `tldr calls`
- Just looking up where a name is declared — use `tldr definition`

**Usage (copy from `verified-invocations.md` — do not reconstruct)**:
```
tldr references [OPTIONS] <SYMBOL> [PATH]
tldr references _to_finite_float backend -l python         # P01 — happy path
tldr references _to_finite_float backend -l python --kinds call  # P12 — call sites only
```

**Output in plain words**: JSON with `definitions[]` (all matches), `references[]` (each with `kind`, `confidence`, single-line `context`), `total_references` vs `shown_references`, and a `search_scope` that reports the ACTUAL scope used.

**Killer detail**: `--scope workspace` is the default but the engine silently auto-narrows to `file` when the symbol looks file-local — always read `search_scope` in the response to know what was actually searched.

**Other footguns**
- `--kinds invalid_kind` is a silent failure: unknown kinds become a filter matching nothing and you get zero results with no clap rejection. Stick to `call`, `read`, `write`, `import`, `type`.
- `--limit 0` means LITERAL zero references returned, not unlimited. Pass `--limit 999999` for "all."
- `--context-lines N` is plumbed but unimplemented per `--help`; context is always one line.

**Source**: `research/tldr/trace/references.md`
