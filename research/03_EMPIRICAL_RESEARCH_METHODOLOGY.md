# Research Journal 03: Empirical Auditing Methodology

> **⚠️ Superseded by operational protocol.** This journal defines the *principle* ("Zero Trust in Documentation"). For the *operational rulebook* — exact dossier structure, mandatory probe matrix, capture conventions, and compliance checklist — see [`04_PROBE_PROTOCOL.md`](./04_PROBE_PROTOCOL.md). Journal 03 remains as the philosophy backing Journal 04's enforcement.

## Context and Core Decision

During the transition from capturing the CLI ground truth (Journal 02) to deeper behavioral analysis, a critical architectural decision was made by Udhayakumar: **We are abandoning the official repository documentation entirely.**

The "Trust but Verify" principle has been upgraded to **"Zero Trust in Documentation."** Documentation inevitably drifts, contains legacy flags, or describes idealized states rather than reality. For an autonomous agent, acting on deprecated documentation leads to fatal execution loops. 

From this point forward, the `tldr` binary and its underlying Rust source code are our **only sources of truth**.

## The Auditable Scientific Method

Because this research process will be peer-reviewed and verified by another LLM, every finding must be backed by an unbroken chain of evidence. We cannot rely on assumptions. 

For every command in the `tldr` suite, we will execute an **Auditable Empirical Workflow**. The results of this workflow will be appended to the respective command's dossier in the `research/tldr/` hierarchy.

### The Dossier Structure

Every command dossier will now follow this exact ledger:

#### 1. Ground Truth (`--help`)
The raw signature, arguments, and flags extracted directly from the CLI. *(Completed in Phase 02).*

#### 2. Empirical Probes
We will execute real commands against a live, complex repository (the `Stock-Monitor` codebase) to observe actual behavior, crash conditions, and output shapes.
* **Goal:** What are we testing? (e.g., "Does `impact` work without the daemon?")
* **Command Executed:** The exact bash string.
* **Raw Output:** The exact JSON/Text returned by the binary.
* **Observation:** What this output proves about the command's real-world behavior.

#### 3. Source Code Reality
We will read the actual Rust implementation (e.g., `crates/tldr-cli/src/commands/*.rs` or `crates/tldr-core/src/`) to uncover hidden constraints that `--help` does not reveal.
* **Target File:** Path to the Rust source file.
* **Code Evidence:** The specific Rust code block (e.g., `if depth > 10 { return Err() }`).
* **Observation:** The hidden rule or hardcoded limit discovered.

#### 4. Agent Synthesis
The final, distilled instruction paragraph that will be injected into the agent's `SKILL.md` prompt. This synthesis must be 100% justified by the empirical probes and source code reality above.

## Purpose of this Ledger

By structuring our research this way, the reviewing LLM will not have to take any leaps of faith. It will be able to read a command dossier, see exactly what we ran, see exactly what the Rust code says, and independently verify that our "Agent Synthesis" is logically sound and mathematically safe.