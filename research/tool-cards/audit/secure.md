# tldr secure

> **Before writing the Usage block**: check `verified-invocations.md` in this group's
> `tool-cards/audit/` directory and copy the canonical syntax verbatim.
> Do NOT reconstruct syntax from prose — that is how hallucinated flags get introduced.

**Pitch**: One-shot security dashboard that runs up to six structural analyses (taint, resources, bounds, contracts, behavioral, mutability) over a path and returns a single aggregated findings list with an 11-counter summary.

**Why reach for it**
- Replaces running `taint`, `resources`, `bounds`, and friends separately and stitching their outputs
- The `summary` block doubles as a health check — 11 named counters give an at-a-glance posture without parsing `findings[]`
- `--quick` mode (taint + resources + bounds only) is the right default for CI; full mode adds contracts/behavioral/mutability for deep audits
- Shares an AST cache across all enabled sub-analyses, so the aggregator is cheaper than running the components serially

**When to use**
- Need a project-wide security posture in one call before drilling down with the specialist commands
- About to wire security gating into CI and want a single JSON artifact (`-o secure-findings.json`)
- Triaging an unfamiliar codebase and want to see which categories have any findings at all
- Want a dashboard view before deciding whether to invest in `tldr taint` per-function or `tldr vuln` for CVE-style categorization

**When NOT to use**
- Need per-function flow tracing — use `tldr taint`
- Need categorized findings by vuln class with SARIF output for code-scanning platforms — use `tldr vuln`

**Usage (copy from `verified-invocations.md` — do not reconstruct)**:
```
tldr secure [OPTIONS] <PATH>
```
```
tldr secure backend/providers --quick             # PATH required; --quick strongly recommended
tldr secure backend/providers --quick -f sarif    # sarif output (secure-specific)
tldr secure backend/providers --quick --detail taint
```

**Output in plain words**: JSON with `findings[]` (each `{category, severity, description, file, line}`) and a fixed-shape `summary` block of 11 counters spanning every sub-analysis. Text format renders the same data as a human-readable report.

**Killer detail**: There is NO SARIF output and NO daemon caching — `tldr secure` is the dashboard, but for CI uploads use `tldr vuln -f sarif`, and expect every run to redo the AST work from scratch.

**Source**: `research/tldr/audit/secure.md`
