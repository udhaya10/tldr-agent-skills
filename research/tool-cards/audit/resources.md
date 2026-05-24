# tldr resources

> **Before writing the Usage block**: check `verified-invocations.md` in this group's
> `tool-cards/audit/` directory and copy the canonical syntax verbatim.
> Do NOT reconstruct syntax from prose — that is how hallucinated flags get introduced.

**Pitch**: CFG-based resource lifecycle analyzer — finds leaks, double-closes, and use-after-close bugs in a single file by walking every control-flow path.

**Why reach for it**
- Examines all paths through a function, not just the happy path — catches leaks that only trigger on exceptions or early returns
- Three detectors in one command: R2 (leaks) is on by default; `--check-all` adds R3 (double-close) and R4 (use-after-close)
- `--suggest-context` proposes the actual refactor (e.g., wrap `open()` in `with`) instead of just flagging the problem
- `--constraints` emits LLM-consumable rule statements — direct prompt fodder for a repair agent

**When to use**
- Reviewing a single file that handles files, DB connections, sockets, locks, or cursors
- Pre-commit check on code that opens external resources
- Generating refactor suggestions for legacy code missing `with`/`using`/`defer` blocks
- Pairing with `tldr temporal` to cross-check: temporal mines the project-wide acquire/release pattern, resources verifies a specific file follows it

**When NOT to use**
- Want project-wide method-call sequencing (not just resource lifecycles) — that's `tldr temporal`
- Looking for security findings (taint, injection) — that's `tldr secure`/`tldr taint`/`tldr vuln`

**Usage (copy from `verified-invocations.md` — do not reconstruct)**:
```
tldr resources [OPTIONS] <FILE> [FUNCTION]
```
```
tldr resources backend/providers/yahoo.py                         # whole file (FILE required; do NOT pass a directory)
tldr resources backend/providers/yahoo.py fetch_historical_data  # optional FUNCTION scopes analysis
tldr resources backend/providers/yahoo.py --check-all            # all leak checks
```

**Output in plain words**: A JSON record with `resources[]` (each with `name`, `resource_type`, `line`, `closed`), `leaks[]`, `double_closes[]`, `use_after_closes[]`, plus optional `suggestions[]` and `constraints[]` arrays, and a summary count block.

**Killer detail**: Passing a DIRECTORY instead of a file leaks a raw OS error (`"Error: IO error: Is a directory (os error 21)"`, exit 1) — the CLI never pre-checks `is_file()`. Always pass a single regular file; loop externally if scanning many.

**Other footguns**
- `-f compact` is BROKEN — returns byte-identical pretty JSON because the legacy local output_format enum only knows `Json`/`Text`. Use `jq -c` for actual compact output.
- `--summary` flag appears to be a no-op (returns full output identical to default). Don't rely on it for filtering.

**Source**: `research/tldr/audit/resources.md`
