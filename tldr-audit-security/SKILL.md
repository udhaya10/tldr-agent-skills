---
name: tldr-audit-security
description: Audit code for security vulnerabilities — taint-flow scanning, per-function CFG dives, and project-wide categorized vuln reports with SARIF for CI. Reach for this when the user asks for a "security audit", "find vulnerabilities", "scan for security issues", "SQL injection", "XSS", "command injection", "taint analysis", "security review", "is this safe from user input", or wants a CI security gate. NOT a CVE / dependency / supply-chain scanner — for "is requests vulnerable?" or "scan package.json", send the user to pip-audit / npm audit / osv-scanner.
allowed-tools: [Bash]
compatibility: "Requires tldr-code CLI v0.4.0+. Tested on darwin and linux."
metadata:
  version: "1.0.0"
  author: "udhaya10"
  repository: "udhaya10/tldr-agent-skills"
  tldr.cli-version: "0.4.0"
  tldr.research-commit: "a025973"
  tldr.commands-wrapped: "secure, taint, vuln"
---

# tldr-audit-security

## When to use

Use this skill when the user wants to **find security problems in source code** — places where attacker-controlled data reaches dangerous sinks (SQL queries, shell commands, file opens, eval), or wants a project-wide security posture, or needs a SARIF report for CI code scanning.

The discriminator vs sibling skills:

- For **non-security** quality concerns (smells, debt, dead code, hotspots) → see `tldr-audit-smells`
- For **going deeper than taint** (reaching-defs, slice, variable-origin tracing) → see `tldr-trace-data-flow`
- For **regex-based misuse patterns** (no-timeout HTTP, bare except, weak crypto checks) → see `tldr-audit-api` (those are `api-check` rules, not flow analysis)

**Critical scope warning — NONE of the three tools here is a CVE / dependency / supply-chain scanner.** They reason about *code flow*, not package manifests or known-CVE databases. If the user wants "is this version of `requests` vulnerable?" or "scan my `package.json` / `Cargo.lock` / `requirements.txt`" — reach for `pip-audit`, `npm audit`, `osv-scanner`, Snyk, or Dependabot. Say so explicitly and stop.

## The decision — which tool to use

The discriminator is **scope × output consumer**, not "which is the security tool."

| You want... | Scope | Output consumer | Reach for |
|-------------|-------|-----------------|-----------|
| A project posture across taint + resources + bounds + contracts + behavioral + mutability | Whole path | Human triage / one JSON artifact | `tldr secure` |
| To prove or disprove that attacker data reaches ONE sink inside ONE function | One file, one function | Reviewer / yourself | `tldr taint` |
| Categorized findings by vuln class, SARIF for GitHub Code Scanning / Azure DevOps | Whole project | CI code-scanning platform | `tldr vuln` |

**Default: `tldr secure --quick` first for any unfamiliar codebase.** It runs the three cheapest sub-analyses (taint + resources + bounds), shares one AST cache across them, and returns an 11-counter `summary` block that doubles as a posture readout — the right "what's even worth investigating?" signal. Escalate to `tldr taint <file> <function>` when secure or vuln has flagged a specific call site and the reviewer needs the CFG-block taint state to explain it. Escalate to `tldr vuln -f sarif -O findings.sarif` when the destination is CI, not a human.

All three share the **same taint engine underneath** — a finding in `vuln` and a finding in `taint` come from the same analysis. `vuln` is `taint` looped over the whole project and categorized; `secure` is `taint` + 2–5 sibling analyses rolled into one dashboard.

## Tool reference

> **Command guardrail**: Only invoke the exact subcommands documented below. Do **not** invent or guess command names. If uncertain whether a command exists, run `tldr --help` before proceeding.

### `tldr secure` — security dashboard, 6 sub-analyses, one JSON

One-shot security dashboard that runs up to six structural analyses (taint, resources, bounds, contracts, behavioral, mutability) over a path and returns a single aggregated findings list with an 11-counter summary.

**Why reach for it**:
- Replaces running `taint`, `resources`, `bounds`, and friends separately and stitching their outputs
- The `summary` block doubles as a health check — 11 named counters give an at-a-glance posture without parsing `findings[]`
- `--quick` mode (taint + resources + bounds only) is the right default for CI; full mode adds contracts/behavioral/mutability for deep audits
- Shares an AST cache across all enabled sub-analyses, so the aggregator is cheaper than running the components serially

**When to use**:
- Need a project-wide security posture in one call before drilling down with the specialist commands
- About to wire security gating into CI and want a single JSON artifact (`-o secure-findings.json`)
- Triaging an unfamiliar codebase and want to see which categories have any findings at all
- Want a dashboard view before deciding whether to invest in `tldr taint` per-function or `tldr vuln` for vuln-class categorization

**When NOT to use**:
- Need per-function flow tracing — use `tldr taint`
- Need categorized findings by vuln class with SARIF output for code-scanning platforms — use `tldr vuln`

**Usage**:
```bash
tldr secure <path> [--quick] [-o secure-findings.json] [-f json|text]
```

**Output**: JSON with `findings[]` (each `{category, severity, description, file, line}`) and a fixed-shape `summary` block of 11 counters spanning every sub-analysis. Text format renders the same data as a human-readable report.

**Killer detail**: There is NO SARIF output and NO daemon caching — `tldr secure` is the dashboard, but for CI uploads use `tldr vuln -f sarif`, and expect every run to redo the AST work from scratch. For repeated runs over the same code (CI loops, watch mode), accept the cold cost or split into per-sub-command calls where caching helps.

---

### `tldr taint` — per-function CFG/DFG taint trace

Per-function CFG/DFG taint-flow tracer that flags dangerous sinks (`sql_query`, `shell_exec`, `file_open`, `code_exec`) and tells the caller, per sink, whether external taint actually reaches them.

**Why reach for it**:
- Returns explicit `sources[]`, `sinks[]`, and `tainted_vars` keyed by CFG block — the only `tldr` command that exposes block-level taint state
- The `tainted` flag on each sink separates "dangerous API was called" from "dangerous API was called with attacker-controlled data"
- Targeted scope (one file, one function) makes it cheap to loop over a shortlist
- Built on the same engine `tldr vuln` uses, but exposes the raw flow data instead of a categorized report

**When to use**:
- Already have a suspect function and need to know whether unsafe data actually reaches a sink inside it
- `tldr vuln` or `tldr secure` flagged a file and the next move is a per-function deep dive
- Want to see the CFG-block-level taint state for explaining a finding to a reviewer

**When NOT to use**:
- Scanning a project — `taint` is strictly one-FILE-one-FUNCTION; use `tldr vuln` or `tldr secure` for breadth
- Looking for dangerous APIs regardless of flow — `tldr secure --quick` is the right tool

**Usage**:
```bash
tldr taint <file> <function> [-f json|text]
```

**Output**: JSON with `function`, `tainted_vars` (block-id → vars), `sources[]`, `sinks[]` (each with a `tainted: bool`), `flows[]`, `sanitized_vars[]`. The actionable signal is `sinks[*].tainted == true`; treat false-tainted sinks as "API used, no traced flow".

**Killer detail**: Function PARAMETERS are NOT treated as taint sources — `vulnerable_sql(user_id)` with `cursor.execute("..." + user_id)` returns `sources: []` and `tainted: false`. The engine only fires on EXPLICIT sources (file reads, network input); for parameter-as-source coverage, escalate to external SAST.

**Other footguns**:
- `-f compact` is broken — returns pretty JSON byte-identical to default (workaround: pipe through `jq -c`)
- Passing a DIRECTORY as FILE leaks a raw OS error (`"Is a directory (os error 21)"`) at exit 1 — validate the path is a file before invoking
- Passing `README.md` silently falls back to the Python parser and exits 20 with `"Function not found"`

---

### `tldr vuln` — project-wide categorized scanner with SARIF

Project-wide taint-driven vulnerability scanner that categorizes findings into 13 vuln types and 5 severity levels, with first-class SARIF 2.1.0 output for CI code-scanning platforms.

**Why reach for it**:
- One of only TWO `tldr` commands that emits SARIF (`tldr clones` is the other) — pipes straight into GitHub Code Scanning, Azure DevOps, etc.
- Filter by `--severity {critical,high,medium,low,info}` and/or repeatable `--vuln-type` across 13 categories (`sql_injection, xss, command_injection, ssrf, path_traversal, deserialization, unsafe_code, memory_safety, panic, xxe, open_redirect, ldap_injection, xpath_injection`)
- Bad-value errors print the FULL valid list inline — the most discoverable CLI surface in the audit suite
- `-O <file>` writes the report directly to disk (stdout stays clean for CI logs)

**When to use**:
- Setting up CI security gating and need a SARIF artifact to upload
- Want findings bucketed by vuln class (SQL injection vs XSS vs path traversal), not a flat list
- Scanning a whole project, not deep-diving one function

**When NOT to use**:
- Need the raw CFG/DFG flow data for a single function — use `tldr taint`
- Want a unified dashboard across taint + resources + bounds + behavioral + mutability — use `tldr secure`

**Usage**:
```bash
tldr vuln <path> [-f json|sarif] [-O findings.sarif] [--severity <level>] [--vuln-type <type>]...
```

**Output**: JSON with `findings[]`, a `summary` block of `{total_findings, by_severity, by_type, files_with_vulns}`, plus `scan_duration_ms` and `files_scanned`. Switch to `-f sarif` for the standard schema with `tool.driver.name: "tldr-vuln"`.

**Killer detail**: This is NOT a CVE/dependency scanner — it's a taint-flow scanner that inherits `tldr taint`'s "function parameters aren't sources" limitation, so a deliberately vulnerable `cursor.execute("..." + user_id)` returns 0 findings unless an external source (file read, request input) flows in. **Mature Python projects routinely scan to 0 findings; that's the engine being conservative, not the code being clean.** Communicate that uncertainty to the user — don't report "0 findings" as "clean."

## Common mistakes

- **Reaching for any of these three for "is my dependency vulnerable?"** None of them parses lockfiles or queries CVE databases. Send the user to `pip-audit` / `npm audit` / `osv-scanner` and stop.
- **Running `tldr vuln` on a small Python project and concluding "we're clean" from zero findings.** Vuln (and taint, the engine underneath) treats function PARAMETERS as untrusted-but-not-tainted. A deliberately bad `cursor.execute("..." + user_id)` returns zero findings unless an external source (file read, network input) flows in. Mature projects routinely scan to zero — that's the engine being conservative, not the code being safe. Always caveat the 0-finding case.
- **Reaching for `tldr secure` when the goal is a SARIF artifact for CI.** Secure has NO SARIF output. Of the audit suite, only `vuln` and `clones` emit SARIF. Use `tldr vuln -f sarif` for code-scanning uploads.
- **Looping `tldr taint` across every file in a project to scan breadth.** Taint is strictly one-FILE-one-FUNCTION by design; that loop is what `tldr vuln` already does, with categorization and SARIF for free. Use taint when you have a shortlist of suspects, not as a scan strategy.
- **Passing a directory to `tldr taint`'s FILE argument.** It leaks a raw OS error (`"Is a directory (os error 21)"`) at exit 1 instead of degrading gracefully. Validate that the path is a file before invoking.
- **Expecting `tldr secure` to be daemon-cached.** It is not — every run redoes the AST work from scratch. For CI loops over the same code, accept the cold cost or split into per-sub-command calls where caching helps.
- **Reporting `taint`'s `sinks[]` count as "vulnerabilities found."** The actionable count is `sinks[*].tainted == true`, not `len(sinks)`. A function with three `cursor.execute` calls and no traced source flow has 3 sinks and 0 tainted sinks — that's "API used, no proof of attack-controlled input," not three bugs.
- **Looking for non-flow security signals here.** Misuse patterns that aren't flow-based (no-timeout HTTP, bare except, weak crypto, hard-coded secrets) are regex-rule territory — see `tldr-audit-api` for `api-check`. Resource leaks as a standalone signal are in `tldr-audit-smells` (`resources`).

## See also

- `tldr-trace-data-flow` — when going deeper than `taint`: reaching-defs follows variable origins, slice/chop cut data dependencies, dead-stores finds assigned-but-never-read variables
- `tldr-audit-smells` — for non-security quality concerns (resources, debt, hotspots, smells)
- `tldr-audit-api` — for regex-based misuse patterns (`api-check` rules) and weak-crypto / no-timeout checks that aren't flow-based
- `tldr-audit-coverage` — `verify` is the constraint-coverage sibling of `secure` (constraints satisfied vs security findings)
