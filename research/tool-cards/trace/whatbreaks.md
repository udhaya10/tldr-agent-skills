# tldr whatbreaks

**Pitch**: One-shot blast-radius wrapper that auto-detects whether the target is a function, file, or module and dispatches to the right sub-analysis.

**Why reach for it**
- Replaces a 2–3 step `extract → impact → importers` workflow with one invocation
- `detection_reason` field explains how the target was classified — debuggable when auto-detect misfires
- `--quick` skips the slow `change-impact` pass and roughly halves runtime on file targets
- Aggregates the underlying analyses into one `summary` row with caller, importer, and test-impact counts

**When to use**
- Have a target identifier but aren't sure whether it's a function name, file path, or module path
- Want a unified "what will this change touch?" summary for a code review or PR description
- Need callers AND importers AND test fan-out in a single JSON for downstream tooling

**When NOT to use**
- You already know it's a function — call `tldr impact <fn>` directly and skip the wrapper overhead
- You already know it's a module — call `tldr importers <module>` directly
- Need per-caller detail in text form — text mode is just 4 summary lines; use JSON

**Output in plain words**: JSON with `target_type`, `detection_reason`, a `sub_results` object (one entry per dispatched analysis, each in a `{success, data|error, elapsed_ms}` envelope), and a flat `summary` of aggregate counters.

**Killer detail**: Exit code 0 does NOT mean the analysis succeeded — sub-analysis failures (e.g., "Function not found") are buried in `sub_results.<analysis>.success: false` while the wrapper exits 0. Agents MUST inspect each sub-result's `success` flag; the process exit code is misleading.

**Other footguns**
- Dotted Python module paths like `backend.providers.base` are auto-classified as `function` when the first segment isn't a real directory under PATH. Always pass `--type module` for dotted paths.
- Bare filenames without `/` (e.g., `base.py`) are also misclassified as functions. Pass `--type file` explicitly.

**Source**: `research/tldr/trace/whatbreaks.md`
