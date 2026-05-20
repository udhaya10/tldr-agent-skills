# Command: `tldr vuln`

## Ground Truth (`tldr vuln --help`)
```text
Vulnerability scanning via taint analysis (SQL injection, XSS, command injection)

Usage: tldr vuln [OPTIONS] <PATH>

Arguments:
  <PATH>
          File or directory to analyze

Options:
  -l, --lang <LANG>
          Programming language to filter by (auto-detected if omitted)

      --severity <SEVERITY>
          Filter by minimum severity level
          
          [possible values: critical, high, medium, low, info]

      --vuln-type <TYPE>
          Filter by vulnerability type
          
          [possible values: sql_injection, xss, command_injection, ssrf, path_traversal, deserialization, unsafe_code, memory_safety, panic, xxe, open_redirect, ldap_injection, xpath_injection]

      --include-informational
          Include informational findings

      --include-smells
          Include code-smell findings (e.g., per-`.unwrap()` Panic emissions on Rust files). Default: false (smells suppressed) to keep production-codebase JSON output focused on real security findings. Pass `--include-smells` to restore the legacy emission set

      --include-tests
          Include findings on JavaScript/TypeScript test files (paths under `test/`, `tests/`, `__tests__/`, or filenames ending in `.test.{js,ts,jsx,tsx}`, `.spec.{js,ts,jsx,tsx}`, or `.e2e.{js,ts}`). Default: false — test-file findings are suppressed because they exercise sink behavior on synthetic inputs and pollute production-codebase scans. Pass `--include-tests` to restore them

  -O, --output <OUTPUT>
          Output file (optional, stdout if not specified)

      --no-default-ignore
          Walk vendored/build dirs (node_modules, target, dist, etc.) that would normally be skipped

  -f, --format <FORMAT>
          Output format
          
          Supported by every command: json, text, compact.
          
          Command-specific formats (rejected at runtime by other commands): sarif  — only: vuln, clones dot    — only: calls, impact, hubs, inheritance, clones, deps
          
          cli-error-clarity-v2 (P2.BUG-5): possible values are hidden on the global help to avoid promising sarif/dot for every subcommand. Run `tldr <cmd> --help` to confirm what a specific command emits, and see `validate_format_for_command` in `output.rs` for the source of truth.
          
          [default: json]

  -q, --quiet
          Suppress progress output

  -v, --verbose
          Enable verbose/debug output

  -h, --help
          Print help (see a summary with '-h')
```

## Empirical Probes
* **Command Executed:** Checked `tldr vuln --help` and tested on `backend/db.py`.
* **Raw Output:** Returns an array of `findings` with severity, type, and location, plus a `summary`.
* **Observation:** The vulnerability scanner operates via taint analysis. It looks for data flowing from untrusted sources into sinks (like SQL execution or shell commands).

## Source Code Reality
* **Target File:** `crates/tldr-cli/src/commands/remaining/vuln.rs`
* **Code Evidence:** 
  ```rust
  // VAL-006: if the autodetected language lies outside the native-analysis set {Python, Rust}, error out early
  ```
* **Observation 1:** The rust code explicitly states that the native taint engine currently only supports Python and Rust! If an agent attempts to run this on a TypeScript repository, it might fail or return zero findings depending on the language detection logic.
* **Observation 2:** It has a highly specific `--include-tests` flag which defaults to false. This is brilliant because it prevents the tool from flagging test files where developers deliberately inject SQL or mock bad inputs.
* **Observation 3:** `vuln` is one of the only commands that natively supports the `--format sarif` flag, allowing it to hook directly into GitHub Code Scanning.

## Intent & Routing
* **User/Agent Goal:** Run security taint analysis to find SQLi, XSS, and command injection.
* **When to choose this over similar tools:** Only supports Python and Rust natively. Excludes tests by default.

## Agent Synthesis
> **How to use `tldr vuln` (Security Taint Analysis):**
> Use this command to find SQL injection, XSS, and command injection vulnerabilities.
> 1. You MUST provide the `<PATH>` argument.
> 2. Test files are excluded by default to reduce noise. Only append `--include-tests` if you specifically want to audit the test harness.
> 3. Native support is currently best for Python and Rust.
> 
> **Command:** `tldr vuln .`
