---
name: tldr-security-taint
description: Low-level security taint analysis. Use this to manually trace untrusted data flows through a specific function to prove or disprove a vulnerability.
allowed-tools: [bash]
---
# Skill: tldr-security-taint

This skill provides granular visibility into the security engine's underlying Data Flow tracing.

## When to Use This Skill
Use this skill when `tldr vuln` reports a vulnerability, and you need to manually inspect the exact path the untrusted data took through the AST to verify if it is a false positive.

## Supported Commands

### 1. `tldr taint`
Analyze taint flows to detect security vulnerabilities inside a specific function.
* **Usage:** `tldr taint <file> <function>`
* **Advanced Flags:**
  * `--verbose`: Show the exact tainted variables per control-flow block.
* **Crucial Rule:** By running this with `--verbose`, you can see exactly which variable needs to be wrapped in a sanitizer/escape function to break the taint flow and remediate the vulnerability.
