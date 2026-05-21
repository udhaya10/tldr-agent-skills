# Command: `tldr <command>`

> Copy this template to `research/tldr/<group>/<command>.md` and fill in every section.
> Non-compliant dossiers (see Journal 04, Section 11) must not be referenced by any `SKILL.md`.

## Environment Pin

| Field | Value |
|---|---|
| `tldr --version` | 0.4.0 |
| Build features | `semantic` (verified via runtime probe) |
| Target repo | Stock-Monitor @ commit `<short-sha>` |
| Daemon state at probe time | warm / cold / N/A |
| OS | darwin 25.2.0 |
| Probe date | YYYY-MM-DD |

---

## Ground Truth (`tldr <command> --help`)

```text
<paste verbatim --help output here — do not edit, do not summarize>
```

---

## Output Shape

| Aspect | Value |
|---|---|
| Default format | `json` |
| Formats that actually work | `json`, `text`, `compact` (probe P05 confirms) |
| Formats that error | `sarif`, `dot` — error: `<verbatim stderr from rejection probe>` |
| Typical output size | small (<1KB) / medium (1–50KB) / heavy (>50KB) |

**Top-level keys:**
- `<key>` (`type`) — description
- `<key>` (`type`) — description

**Nested structures:** describe recursion / array-of-object schemas here.

**Empty result shape:**
```json
{ "<key>": [] }
```

**Error shape:**
- stderr: `"<verbatim>"`
- exit: `<N>`

---

## Probe Matrix

Slug convention: `NN-<token>[-<modifier>]` (see Journal 04 §4.1). The audit script globs by `NN-*`, so modifiers are safe.

| # | Probe | Type | Exit | Captured |
|---|-------|------|------|----------|
| P01 | `tldr <command> <minimal-args>` | happy | 0 | [`01-happy.*`](./<command>.probes/) |
| P02 | `tldr <command> <realistic-args>` | happy-scale | 0 | [`02-happy-scale.*`](./<command>.probes/) |
| P03 | `tldr <command>` *(no args)* | failure-missing-input | ? | [`03-missing-arg.*`](./<command>.probes/) |
| P04 | `tldr <command> /no/such/path` | failure-badpath | ? | [`04-badpath.*`](./<command>.probes/) |
| P05 | `tldr <command> ... -f sarif` | format-reject | ? | [`05-format-reject.*`](./<command>.probes/) |
| P06 | `tldr <command> ... -f text` | format-text | 0 | [`06-format-text.*`](./<command>.probes/) |

**If the command has no required input** (e.g., path defaults to `.`), replace the P03 row with:
```
| P03 | N/A: all inputs optional — <reason, e.g., "path defaults to current directory"> | — | — | — |
```

Add conditional probes per Journal 04 §4.3 (flag toggles, daemon hot/cold, composition, language variants).

### Observations

- **P01:** <what the output proves about happy-path behavior, output shape, performance>
- **P02:** <how it scales, latency, daemon involvement>
- **P03:** stderr `"<verbatim>"`, exit `<N>`. **Recovery hint:** <what the agent should do>.
- **P04:** stderr `"<verbatim>"`, exit `<N>`. **Recovery hint:** <what the agent should do>.
- **P05:** stderr `"<verbatim>"`, exit `<N>`. Confirms format validator in `output.rs::validate_format_for_command`.

---

## Source Code Reality

**Target file(s):**
- `crates/tldr-cli/src/commands/<command>.rs`
- `crates/tldr-core/src/<relevant>.rs` (if applicable)

**Pinned to upstream commit:** `<sha>` (from `parcadei/tldr-code`)

**Argument validators:**
```rust
// crates/tldr-cli/src/commands/<command>.rs:LNN
<verbatim Rust block>
```
Reveals: <constraint the validator enforces, not visible in --help>

**Hardcoded limits:**
```rust
// path:LNN
<block>
```
Reveals: <limit value, what triggers it>

**Daemon route:**
```rust
// path:LNN
if let Some(result) = try_daemon_route::<T>(&self.path, "<command>", ...) { ... }
```
Reveals: command hits daemon first; cold-boot fallback path is `<describe>`.

**Format validation:**
Confirmed at `crates/tldr-cli/src/output.rs::validate_format_for_command` — formats accepted: `<list>`.

---

## Architectural Deep Dive

- **Under the hood:** <AST / CFG / DFG / PDG / SQLite / git-history — which engine powers this command>
- **Performance:** <cold vs warm, what gets cached, typical latency on small/medium/large repos>
- **LLM cognitive load:** <what manual exploration this command replaces, why it matters for token efficiency>

---

## Intent & Routing

- **User/Agent Goal:** <one-line goal>
- **When to choose this over similar tools:** <distinguishing scenario>
- **Prerequisites (composition):** <list any commands that must run first — e.g., "Run `tldr extract` first to find line numbers">

---

## Agent Synthesis

> **How to use `tldr <command>`:**
> <One paragraph distilled from Probe Matrix + Source Code Reality. Must reflect every flag exercised above, every recovery hint from failure probes, every prerequisite from Intent & Routing.>
>
> **Crucial Rules:**
> - <rule from negative probe, e.g., "Function name is positional, not a flag">
> - <rule from source code, e.g., "Path must be a directory; passing a file errors">
> - <composition prerequisite, e.g., "Run `tldr extract <file>` first to obtain valid line numbers">
>
> **Command:** `tldr <command> <args>`
>
> **With common flags:** `tldr <command> <args> --<flag> <value>` (use when <condition>)
