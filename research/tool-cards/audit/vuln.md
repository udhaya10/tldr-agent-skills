# tldr vuln

**Pitch**: Project-wide taint-driven vulnerability scanner that categorizes findings into 13 vuln types and 5 severity levels, with first-class SARIF 2.1.0 output for CI code-scanning platforms.

**Why reach for it**
- One of only TWO `tldr` commands that emits SARIF (`tldr clones` is the other) — pipes straight into GitHub Code Scanning, Azure DevOps, etc.
- Filter by `--severity {critical,high,medium,low,info}` and/or repeatable `--vuln-type` across 13 categories (`sql_injection, xss, command_injection, ssrf, path_traversal, deserialization, unsafe_code, memory_safety, panic, xxe, open_redirect, ldap_injection, xpath_injection`)
- Bad-value errors print the FULL valid list inline — the most discoverable CLI surface in the audit suite
- `-O <file>` writes the report directly to disk (stdout stays clean for CI logs)

**When to use**
- Setting up CI security gating and need a SARIF artifact to upload
- Want findings bucketed by vuln class (SQL injection vs XSS vs path traversal), not a flat list
- Scanning a whole project, not deep-diving one function

**When NOT to use**
- Need the raw CFG/DFG flow data for a single function — use `tldr taint`
- Want a unified dashboard across taint + resources + bounds + behavioral + mutability — use `tldr secure`

**Output in plain words**: JSON with `findings[]`, a `summary` block of `{total_findings, by_severity, by_type, files_with_vulns}`, plus `scan_duration_ms` and `files_scanned`. Switch to `-f sarif` for the standard schema with `tool.driver.name: "tldr-vuln"`.

**Killer detail**: This is NOT a CVE/dependency scanner — it's a taint-flow scanner that inherits `tldr taint`'s "function parameters aren't sources" limitation, so a deliberately vulnerable `cursor.execute("..." + user_id)` returns 0 findings unless an external source (file read, request input) flows in. Mature Python projects routinely scan to 0 findings; that's the engine being conservative, not the code being clean.

**Source**: `research/tldr/audit/vuln.md`
