# tldr surface

> **Before writing the Usage block**: check `verified-invocations.md` in this group's
> `tool-cards/ops/` directory and copy the canonical syntax verbatim.
> Do NOT reconstruct syntax from prose — that is how hallucinated flags get introduced.

**Pitch**: Machine-readable API extraction for a package (e.g., `tldr surface json`) or a directory — every public function, class, method, and constant with structured signatures including parameter kinds.

**Why reach for it**
- Package mode (`tldr surface <name>`) is the right tool when an agent needs to know what a library exposes without grep-walking node_modules
- `--lookup <qualified.name>` filters to a single API for sharp targeted questions
- Per-language resolvers handle Python stdlib, JS/TS node_modules, and Rust Cargo manifests automatically
- `signature.params[]` distinguishes `*args` (variadic) from `**kwargs` (keyword-only)

**When to use**
- "What does this stdlib or third-party package expose?" — `tldr surface <package>`
- Pulling a single function's parameter list — `tldr surface <package> --lookup <qualified.name>`
- Producing API-surface JSON for downstream contract comparison

**When NOT to use**
- Pointing it at a project directory — output explodes (~38,000 lines for a moderate backend). Use `tldr api-check` (diff-focused) or `tldr interface` (per-file synthesis) instead.
- Detecting API breakage between two versions — use `tldr api-check`
- Quickly skimming what's defined in one file — use `tldr extract`

**Usage (copy from `verified-invocations.md` — do not reconstruct)**:
```
tldr surface [OPTIONS] <TARGET>
```
```
# P01 — stdlib module surface
tldr surface json
# P09 — lookup a specific symbol
tldr surface json --lookup json.loads
# P12 — limit result count
tldr surface json --limit 5
```

**Output in plain words**: JSON with `package`, `language`, `total`, an `apis` array of typed entries (`qualified_name`, `kind`, `module`, structured `signature`), `files_skipped`, and `warnings`.

**Killer detail**: Directory targets are an agent footgun — `tldr surface backend` produced 38,111 lines of output. Reserve surface for named packages; reach for `tldr api-check` or `tldr interface` when the target is a project tree.

**Source**: `research/tldr/ops/surface.md`
