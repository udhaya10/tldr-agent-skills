# Research Journal 04: The Probe Protocol (Operational Rulebook)

## Why this exists

Journal 03 established the **principle** — "Zero Trust in Documentation," empirical evidence only. But principle without enforcement leaks. A spot audit of the existing dossiers revealed two failure modes:

1. **Placeholder evidence.** Several dossiers (e.g., `search/semantic.md`, `fix/fix-apply.md`) carry the line *"Tool evaluated and integrated successfully via batch script profiling"* with no actual probe captured. That is not evidence — that is a promise of evidence.
2. **Inconsistent depth.** `overview/tree.md` has a real command, raw output, and observations. `audit/secure.md` does not. Two dossiers, same methodology header, wildly different evidentiary value.

This document is the **operational protocol** that makes Journal 03's principle enforceable. It defines exactly what a dossier must contain, how probes must be captured, and how an auditor (human or LLM) can verify compliance in seconds.

> **Rule of thumb:** If another LLM cannot re-run your evidence and get the same shape of output, your dossier is not done.

---

## 1. The Dossier Contract

Every command dossier (`research/tldr/<group>/<cmd>.md`) must contain these eight sections, in this order:

1. **Environment Pin** — what we probed against (version, repo, daemon state, date)
2. **Ground Truth (`--help`)** — verbatim CLI help output
3. **Output Shape** — explicit JSON contract the agent will consume
4. **Probe Matrix** — table of probes executed, with pointers to captured evidence
5. **Source Code Reality** — Rust source citations with line refs
6. **Architectural Deep Dive** — how it works under the hood
7. **Intent & Routing** — user goal + when to choose this over neighbors
8. **Agent Synthesis** — final instruction for `SKILL.md`, must reflect every flag exercised above

A dossier missing any section is **non-compliant** and must not be referenced by any `SKILL.md`.

See [`_TEMPLATES/dossier.md`](./_TEMPLATES/dossier.md) for the copy-pasteable scaffold.

---

## 2. Environment Pin (mandatory header block)

The first content block of every dossier, immediately after the title:

```markdown
## Environment Pin

| Field | Value |
|---|---|
| `tldr --version` | 0.4.0 |
| Build features | `semantic` (verified via runtime probe) |
| Target repo | Stock-Monitor @ commit `<short-sha>` |
| Daemon state at probe time | warm / cold / N/A |
| OS | darwin 25.2.0 |
| Probe date | YYYY-MM-DD |
```

Why: when the `tldr` binary bumps, an auditor can `diff` re-run probes against this pin to detect drift. Without it, every observation is unfalsifiable.

---

## 3. Output Shape (mandatory)

This section answers: *"What JSON contract does this command emit?"* Agents need this to parse output safely.

Required fields:
- **Default format** — usually `json`
- **Supported formats** — which of `json | text | compact | sarif | dot` actually work (not what `--help` claims; what runtime accepts)
- **Top-level keys** — name, type, brief description
- **Nested structures** — for recursive or array-of-object responses
- **Empty result shape** — what comes back when nothing is found
- **Error shape** — stderr text + exit code on common failures
- **Approximate size** — small (<1KB) / medium (1–50KB) / heavy (>50KB) per typical invocation

This data is extracted from the probe captures (Section 4) — not invented.

---

## 4. The Probe Matrix (the heart of the protocol)

Every command gets a `<cmd>.probes/` sibling directory containing the raw evidence. The dossier table indexes those files.

### 4.1 Directory layout

```
research/tldr/<group>/
├── <cmd>.md                  # the dossier
└── <cmd>.probes/
    ├── probe.sh              # regeneratable script (Section 6)
    ├── README.md             # one-line description per probe row
    ├── 01-happy.cmd          # exact bash invocation
    ├── 01-happy.out          # stdout (truncated per rules below)
    ├── 01-happy.err          # stderr + trailing "exit=<N>" line
    ├── 02-happy-scale.cmd
    ├── 02-happy-scale.out
    ├── 02-happy-scale.err
    └── ...
```

**Slug naming rule (strict):**
- Every probe capture has slug `NN-<token>[-<modifier>]` where `NN` is the zero-padded probe ID (`01`, `02`, ..., `99`).
- `<token>` is a stable identifier for the probe class — happy, missing-arg, badpath, format-reject, format-text, warm-daemon, composition, etc. Pick the canonical token from the table in §4.2/§4.3 and stick with it across all dossiers so cross-command audits stay legible.
- `<modifier>` is optional and adds a scope (e.g., `01-happy-small`, `02-happy-scale`, `06-format-reject-sarif`).
- The audit script globs by `NN-*`, so modifiers do not break compliance.

### 4.2 Mandatory probe rows

Every command must include **at minimum**:

| ID | Probe | Purpose |
|---|---|---|
| P01 | Happy path, smallest meaningful input | Confirms the command runs |
| P02 | Happy path, realistic scale (Stock-Monitor) | Confirms it scales without crash |
| P03 | Required input omitted | Captures the missing-input error shape (see rule below) |
| P04 | Bad path / non-existent target | Captures the not-found error shape |
| P05 | Format validation | One rejected format + one alternate accepted format (see rule below) |

**P03 rule (missing-input):**
- If the command has a **required positional** (e.g., `impact <FUNCTION>`, `slice <FILE> <FUNCTION> <LINE>`): run the command with no args, capture the error.
- If the command has a **required flag** (e.g., `fix apply --source <SOURCE>`): run without the flag, capture the error.
- If **all inputs are optional** (e.g., `tree`, `structure`, `health` — path defaults to `.`): mark the row `N/A` in the Probe Matrix table with a one-line reason. The audit script accepts either a capture file or this N/A marker.

**P05 rule (format validation):**
- One probe with a **rejected format** the command does *not* support (typically `sarif` or `dot`) — captures the runtime validator's error message.
- One probe with an **alternate accepted format** the command *does* support (typically `text` or `compact`) — proves multi-format output works.
- Commands that accept additional formats (e.g., `vuln` also takes `sarif`; `calls` takes `dot`) probe those extras in conditional rows P06+.

### 4.3 Conditional probe rows (add when applicable)

| Trigger | Add probe |
|---|---|
| Command has a `--quick` / `--summary` / mode flag | One probe with the flag, one without — show the diff |
| Command hits the daemon | One cold-daemon probe + one warm-daemon probe |
| Command requires prerequisites (e.g., `slice` needs a line number) | Composition probe: run the prerequisite command, feed its output in |
| Command has output-limiting flags (`--top`, `--max-results`, `--depth`) | One probe at default, one at extreme value |
| Command operates on file vs directory differently | Probe both |
| Command supports multiple languages | Probe at least Python + one other |

### 4.4 The matrix table in the dossier

```markdown
## Probe Matrix

| # | Probe | Type | Exit | Captured |
|---|-------|------|------|----------|
| P01 | `tldr tree backend --ext .py` | happy | 0 | [01-happy.*](./tree.probes/) |
| P02 | `tldr tree . --ext .py` | happy-scale | 0 | [02-happy-scale.*](./tree.probes/) |
| P03 | `tldr tree /no/such/path` | failure-badpath | 1 | [03-badpath.*](./tree.probes/) |
| P04 | `tldr tree backend -f sarif` | format-reject | 2 | [04-sarif-reject.*](./tree.probes/) |
| P05 | `tldr tree backend --ext .py -f text` | format-text | 0 | [05-text.*](./tree.probes/) |
| P06 | `tldr tree backend --ext .py -H` | flag-hidden | 0 | [06-hidden.*](./tree.probes/) |

### Observations

- **P01:** Returns nested JSON `{name, type, children, ...}`. `.gitignore` respected by default.
- **P03:** stderr `"Path not found: ..."`, exit 1. Recovery: agent should validate path before invoking.
- **P04:** stderr includes `"sarif format is only supported for vuln, clones"`. Format validator in `output.rs::validate_format_for_command`.
- ...
```

---

## 5. Verbatim Capture Rule

Probe outputs are **captured verbatim, never paraphrased**.

- `.cmd` files contain the **exact** bash invocation, one per line if multi-step.
- `.out` files contain raw stdout. If output exceeds **500 lines**, truncate as:
  ```
  <first 400 lines>
  ... [N lines truncated, full output regeneratable via probe.sh] ...
  <last 50 lines>
  ```
  The Output Shape section of the dossier carries the schema; no separate `.shape` file is needed.
- `.err` files contain raw stderr, with a final line `exit=<N>` appended.
- Pretty-printing JSON is allowed (pipe through `jq .`) — but the command in `.cmd` must show the actual invocation; if `jq` was used, include the pipe.

**`probe.sh` is the reproducer of record.** Individual `.cmd` files are *invocation records*, not standalone scripts. Stateful probes (e.g., a cold-daemon probe that requires `tldr daemon stop` first) capture only the `tldr ...` invocation in `.cmd`; the precondition lives in `probe.sh`. Re-running a single `.cmd` outside `probe.sh` may not reproduce the captured `.out`/`.err`.

**No prose in capture files.** Observations go in the dossier, not in `.out` files.

---

## 6. The `probe.sh` Script (regeneratable evidence)

Every `.probes/` directory contains a `probe.sh` script that, when run, regenerates every `.cmd`/`.out`/`.err` file in that directory.

Why: when `tldr` bumps to v0.5.0, an auditor runs every `probe.sh`, diffs the resulting captures against committed evidence, and any non-zero diff flags a command whose behavior changed. Drift detection becomes mechanical.

See [`_TEMPLATES/probe.sh`](./_TEMPLATES/probe.sh) for the canonical structure.

---

## 7. Negative Probes Are First-Class

The agent needs to know what *failure* looks like as urgently as it needs to know what success looks like — because failure is what it must recover from.

Every dossier must capture at least **two failure probes**: P03 (missing arg) and P04 (bad path). For commands with type-sensitive inputs (`slice` line number, `impact` function name), add a third capturing wrong-type input.

The Observations section must document, per failure probe:
- **Exact stderr text** (verbatim from `.err` file)
- **Exit code**
- **Recovery hint** for the agent (e.g., "run `tldr extract` first to get a valid line number")

---

## 8. Composition Probes (chained workflows)

Some commands are useless in isolation. `slice` requires a line number you don't know. `impact` requires a function name you may not have. These commands need a **composition probe** showing the full chain:

```bash
# Composition probe: slice depends on extract for line numbers
$ tldr extract backend/db.py 2>&1 | jq '.functions[] | select(.name=="get_yahoo_symbol_from_security_id")'
  → {"name": "...", "line": 168, ...}

$ tldr slice backend/db.py get_yahoo_symbol_from_security_id 168
  → {"slice_lines": [...], "edges": [...]}
```

Capture this in a single `Pxx-composition.*` triple. The dossier's Agent Synthesis must reference the prerequisite explicitly.

---

## 9. Source Code Reality: reactive depth, not exhaustive archaeology

Reading the Rust source is a **clarification tool, not a mandatory five-item checklist.** The empirical probes are the primary evidence. Open the code when — and only when — a probe result is *confusing, surprising, or contradicts what `--help` claims*.

**Default:** open the command's CLI dispatch file (`crates/tldr-cli/src/commands/<cmd>.rs`) once to confirm the argument struct, default values, and which engine function is called. That's almost always enough.

**Dig deeper into `tldr-core` / engine code only when:**
- An empirical probe behaves differently than `--help` describes (e.g., `search` returns 0 results on a directory that obviously contains matches → read the language-detection code).
- Two probes that should agree disagree (e.g., warm vs cold daemon producing different output → read the cache key construction).
- A flag is documented but its observable effect is unclear (e.g., `--no-cache` — does it disable embedding cache, daemon cache, or both? → read the cache wiring).
- The exit code or error message contradicts your model of what the command should do.

**The five things to skim for** (when you do open the code):

1. **Argument validators** — `require_directory`, `require_file`, custom guards. Reveals constraints `--help` hides.
2. **Hardcoded limits** — depth caps, result caps, token caps.
3. **Daemon-route shortcuts** — `try_daemon_route::<T>(...)` calls. Reveals which commands benefit from a warm daemon.
4. **Fallback paths** — what happens when the daemon is cold, when the cache is missing, when the language can't be detected.
5. **Format-validation logic** — `validate_format_for_command` in `output.rs` is the source of truth for which `--format` values each command accepts.

Cite with `crates/<crate>/src/<file>.rs:LNNN` and quote the exact Rust block. Pin to a commit SHA when possible.

**Anti-pattern:** opening five Rust files for a command whose probes all matched `--help`. The Source Code Reality section can be short ("CLI dispatch confirmed; engine call delegates to `enriched_search` — not opened because empirical behavior matches `--help`"). Don't pad it.

---

## 10. Agent Synthesis: must reflect the probes

The final synthesis block is the **only** part of the dossier copied into `SKILL.md`. It must:

- Reflect every flag exercised in the probe matrix (not just the happy-path command).
- Encode every recovery hint from negative probes.
- State any composition prerequisite explicitly.
- Be copy-pasteable: agent should be able to run the example without modification.

A synthesis that says only `Command: tldr fix apply <file_path> <patch_file>` when the probe matrix exercised `--source`, `-i`, `-d`, and `--api-surface` is **incomplete**.

---

## 11. Auditor's Compliance Checklist

A dossier is compliant if and only if all of these are true:

- [ ] Title line follows `# Command: \`tldr <cmd>\``
- [ ] Environment Pin block present with all 6 fields
- [ ] Ground Truth section contains verbatim `--help` output
- [ ] Output Shape section documents default format, supported formats, top-level keys, empty case, error case
- [ ] Probe Matrix table present with at minimum P01–P05
- [ ] `<cmd>.probes/` directory exists with matching `.cmd`/`.out`/`.err` triples
- [ ] `<cmd>.probes/probe.sh` exists and is executable
- [ ] Observations section documents at least P03 and P04 failure shapes verbatim
- [ ] Source Code Reality cites file path + line numbers + Rust source quote
- [ ] Agent Synthesis reflects every flag/prerequisite surfaced by the probe matrix
- [ ] No placeholder text (e.g., "Tool evaluated successfully via batch script profiling")

Run `bash research/_TEMPLATES/audit.sh <dossier-path>` to mechanically check sections 1–7 of this list (the structural ones).

---

## 12. What changes vs Journal 03

| Aspect | Journal 03 (principle) | Journal 04 (protocol) |
|---|---|---|
| Probe captures | "Raw Output" inline | Separate `.probes/` sibling dir, verbatim |
| Failure modes | "observe crash conditions" | Mandatory P03, P04, plus type-error probes |
| Reproducibility | Implicit | `probe.sh` regenerates evidence; environment pinned |
| Output shape | Buried in prose | Dedicated section with required fields |
| Format flags | Not addressed | Mandatory probe per declared format value |
| Composition | Not addressed | First-class probe type with chain capture |
| Compliance check | None | 11-item checklist + mechanical audit script |
| Source code citation | "Code Evidence" with one snippet | Five things to search for, line refs required |

Journal 03 remains the philosophy. Journal 04 is the rulebook that makes the philosophy auditable.

---

## 13. Known Limitations & Fixture Repos

The default target is `Stock-Monitor` (Python data pipeline) — sufficient for the majority of commands. But a few commands need code shapes the Stock-Monitor codebase doesn't contain meaningfully:

| Command | Why Stock-Monitor is insufficient | Action |
|---|---|---|
| `coverage` | Needs LCOV / Cobertura XML / coverage.py JSON input | Use a fixture file under `research/fixtures/coverage/` |
| `inheritance` | Needs OOP-heavy code with class hierarchies | Probe also against a Java/Kotlin fixture or note that Python single-inheritance coverage is partial |
| `taint` | Needs SQL/web sinks (SQLi, XSS, command injection vectors) | Use a dedicated vulnerable fixture under `research/fixtures/taint/` |
| `coverage`, `surface` | Need machine-readable input the agent will produce | Synthesize a minimal fixture, capture probe against it |

When using a non-default fixture, record it in the Environment Pin's `Target repo` field (e.g., `research/fixtures/taint/sqli-demo`) so the probe is reproducible.

For now: probe-shape is captured from these fixtures, but **semantic coverage breadth is acknowledged as partial** for the four commands above. This is a known limitation, not a protocol violation.

---

## 14. Applying the protocol

The existing dossiers were produced under Journal 03 and are **non-compliant** with this protocol. They are not deleted — they remain as historical reference — but every dossier must be re-audited against the Section 11 checklist and rewritten where needed before the corresponding `SKILL.md` is updated.

**Mandatory first step:** apply the protocol to **one** command end-to-end (suggested: `tree`) — write the dossier from `_TEMPLATES/dossier.md`, write the `probe.sh`, run it, run `audit.sh`. If it does not score 15/15, the protocol still has a bug. Do not roll out to additional commands until one full round-trip is clean.

Suggested order after that: commands an agent is most likely to invoke first (`tree`, `structure`, `extract`, `search`, `semantic`, `impact`, `slice`, `health`). Backfill the rest skill group by skill group.
