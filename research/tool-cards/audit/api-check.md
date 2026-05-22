# tldr api-check

**Pitch**: Pattern-based API-misuse scanner that catches the classic mistakes — no-timeout HTTP, bare except, weak crypto, unclosed files — across 17 languages, each finding shipped with a `fix_suggestion`.

**Why reach for it**
- Curated, language-tagged rules (rule IDs like `PY001`, `JS003`, `CPP001`) keep false positives tight
- `fix_suggestion` and `code_context` per finding turn output directly into LLM remediation prompts
- `--severity` is a MINIMUM threshold and `--category` is comma-separated OR — both compose for tight CI gates
- Regex-based (not AST), so it scales fast and works on partial / generated / unparseable code

**When to use**
- CI gate for "missing timeout / bare except / weak crypto" type bugs — pair `--severity high --category crypto,security`
- Security review of HTTP and crypto call sites without spinning up a language server
- Quick audit on a new dependency or vendor drop to spot misuse patterns
- Want a fast scan with per-finding remediation templates

**When NOT to use**
- Need CVE-level dependency vulnerability data — that's `tldr vuln`
- Want broad taint/dataflow security analysis — `tldr secure` and `tldr taint` cover that ground
- Want the API surface itself (signatures, classes) rather than misuse — `tldr interface`

**Output in plain words**: An `APICheckReport` with `findings[]` (each with `file`, `line`, `column`, `rule` (id/name/category/severity/description/correct_usage), `api_call`, `message`, `fix_suggestion`, `code_context`), a `summary` with `by_category`/`by_severity`, and top-level mirrors of `total_findings`/`files_scanned`.

**Killer detail**: `rules_applied: 92` counts the rules across ALL 17 supported languages — even when `-l python` scopes the scan to Python-only files. The number does NOT reflect rules actually executed; use `summary.apis_checked` for true per-language coverage.

**Source**: `research/tldr/audit/api-check.md`
