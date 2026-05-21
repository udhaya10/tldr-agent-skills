# Command: `tldr dfg` — **OMITTED (Internal Engine)**

> **Status: NOT a top-level CLI subcommand.** Per
> [`research/05_OMITTED_COMMANDS_RATIONALE.md`](../../05_OMITTED_COMMANDS_RATIONALE.md)
> § 1 (Internal Engine Hallucinations), `tldr dfg` is an internal
> Data-Flow-Graph engine, not an invocable command. Running
> `tldr dfg ...` returns:
>
> ```text
> error: unrecognized subcommand 'dfg'
> ```
>
> No Journal 04 probe dossier exists for `tldr dfg` because there is
> nothing to probe — the DFG engine is reachable only INDIRECTLY via
> commands that consume it:
>
> | Command | How it uses DFG |
> |---|---|
> | `tldr slice` | Forward/backward dataflow slice (uses DFG refs) |
> | `tldr reaching-defs` | Dataflow equations over the DFG ref graph |
> | `tldr chop` | Intersection of forward and backward slices |
> | `tldr available` | Available-expressions dataflow (DFG-aware) |
> | `tldr dead-stores` | DFG-based dead-store detection |
>
> Agents that need DFG-derived information (variable definitions, uses,
> refs across blocks) should pick the highest-level command that
> answers their actual question — never attempt to invoke `tldr dfg`
> directly.

## Probe Stub

See [`dfg.probes/probe.sh`](./dfg.probes/probe.sh) — a one-line marker
script that emits the omission notice and exits non-zero. It exists so
the protocol's automated audit (`done_count` from `find -type d -name
'*.probes'`) treats this entry as accounted for without requiring real
probe captures.
