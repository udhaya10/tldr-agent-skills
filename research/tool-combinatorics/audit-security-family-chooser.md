# Lens: Audit security — family chooser

**The question this lens answers**: "I need to find security problems in this code — which of `secure`, `taint`, `vuln` should I run?"

**Toolset**: `tldr secure`, `tldr taint`, `tldr vuln`

**Why a family-chooser lens, why these tools**: All three are taint-flow-driven security scanners that share an engine, but each exposes that engine at a different scope and packages the output for a different consumer. Picking wrong leads to either a wall of aggregate findings when one CFG dive was wanted, or a single-function trace when a project posture was needed. The discriminator is **scope × output consumer**, not "which is the security tool."

> **None of these three is a CVE / dependency / supply-chain scanner.** They reason about code flow, not package manifests or known-CVE databases. If the user wants "is this version of `requests` vulnerable?" or "scan my `package.json`" — none of `secure`, `taint`, `vuln` is the answer. Reach for an external tool (`pip-audit`, `npm audit`, `osv-scanner`, Snyk, Dependabot).

## Decision tree

| You want... | Scope | Output consumer | Reach for |
|-------------|-------|-----------------|-----------|
| A project posture across taint + resources + bounds + contracts + behavioral + mutability | Whole path | Human triage / one JSON artifact | `tldr secure` |
| To prove or disprove that attacker data reaches ONE sink inside ONE function | One file, one function | Reviewer / yourself | `tldr taint` |
| Categorized findings by vuln class, SARIF for GitHub Code Scanning / Azure DevOps | Whole project | CI code-scanning platform | `tldr vuln` |

## The default

**`tldr secure --quick` first for any unfamiliar codebase.** It runs the three cheapest sub-analyses (taint + resources + bounds), shares one AST cache across them, and returns an 11-counter `summary` block that doubles as a posture readout — that's the right "what's even worth investigating?" signal. Escalate to `tldr taint <file> <function>` when secure or vuln has flagged a specific call site and the reviewer needs the CFG-block taint state to explain it. Escalate to `tldr vuln -f sarif -O findings.sarif` when the destination is CI, not a human.

## Common mistakes

- **Running `tldr vuln` on a small Python project and concluding "we're clean" from zero findings.** Vuln (and taint, the engine underneath) treats function PARAMETERS as untrusted-but-not-tainted. A deliberately bad `cursor.execute("..." + user_id)` returns zero findings unless an external source (file read, network input) flows in. Mature projects routinely scan to zero — that's the engine being conservative, not the code being safe.
- **Reaching for `tldr secure` when the goal is a SARIF artifact for CI.** Secure has NO SARIF output. Of the audit suite, only `vuln` and `clones` emit SARIF. Use `tldr vuln -f sarif` for code-scanning uploads.
- **Looping `tldr taint` across every file in a project to scan breadth.** Taint is strictly one-FILE-one-FUNCTION by design; that loop is what `tldr vuln` already does, with categorization and SARIF for free. Use taint when you have a shortlist of suspects, not as a scan strategy.
- **Passing a directory to `tldr taint`'s FILE argument.** It leaks a raw OS error (`"Is a directory (os error 21)"`) at exit 1 instead of degrading gracefully. Validate that the path is a file before invoking.
- **Expecting `tldr secure` to be daemon-cached.** It is not — every run redoes the AST work from scratch. For repeated runs over the same code (CI loops, watch mode), accept the cold cost or split into per-sub-command calls where caching helps.
- **Using any of these three for "is my dependency vulnerable?"** None of them parses lockfiles or queries CVE databases. Send the user to `pip-audit` / `npm audit` / `osv-scanner` and stop.

## What this lens captures

- The scope × consumer discriminator is durable: dashboard vs CFG-dive vs SARIF-categorization is the real choice, not "which security tool is best."
- The shared-engine reality: a finding in `vuln` and a finding in `taint` come from the same analysis — `vuln` is `taint` looped and categorized.

## What this lens misses

- **Misuse patterns that aren't flow-based** (no-timeout HTTP, bare except, weak crypto). Those are regex-rule territory — see `tldr api-check`, covered in the API/design family chooser.
- **Resource leaks and bounds checks as standalone runs.** `secure --quick` rolls them in, but if the goal is just "find unclosed files," `tldr resources` is the direct call.
- **CVE / dependency scanning.** Repeating because it bears it: not in this family.

## Pair with

- `audit-coverage-testing-family-chooser.md` — `verify` is the constraint-coverage sibling of `secure` (constraints vs security findings)
- `audit-api-design-family-chooser.md` — `api-check` handles the regex-rule misuse signal this family deliberately skips

## Sources

- `research/tool-cards/audit/secure.md`
- `research/tool-cards/audit/taint.md`
- `research/tool-cards/audit/vuln.md`
