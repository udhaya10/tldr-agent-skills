# tldr interface

**Pitch**: Public-API surface extractor — pulls every top-level class, function, method, decorator, and docstring out of a file or directory across 18 languages.

**Why reach for it**
- Distills a file to just its consumer-visible API — what an external caller would see — without the body noise
- `all_exports[]` is a sorted public-name list ready for `__all__` / module-doc generation
- Captures decorators, base classes, and docstrings per method, not just bare signatures
- Built-in text format renders developer-friendly API documentation directly

**When to use**
- Generating or refreshing API documentation for a module
- Before-and-after API surface comparison (capture interface, refactor, compare) to check breakage
- Building a contract for a downstream consumer to mock or stub against
- Quickly seeing what a package exposes without grepping for `class` / `def` patterns

**When NOT to use**
- Comparing the surface against a baseline to flag breakage — that's the dedicated job of `tldr api-check` (misuse) plus the surface diff workflow built on this command
- Need every function including private ones with their full call graph — use `tldr extract`
- Want the class hierarchy specifically (parents, children, DOT visualization) — `tldr inheritance`

**Output in plain words**: For a single file, an OBJECT `{ file, all_exports, functions, classes }` where each class has `name, lineno, bases, methods` and each function carries its signature + docstring. For a directory, an ARRAY of those file-objects. Empty directory returns `[]`.

**Killer detail**: The top-level JSON shape flips between OBJECT (single file or non-source file like `.md`) and ARRAY (directory) based on PATH type. Consumers must branch on `Array.isArray()` before parsing — there is no `mode` field to disambiguate, and non-source files silently return an empty single-file object instead of erroring.

**Source**: `research/tldr/audit/interface.md`
