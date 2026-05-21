# Command: `tldr cfg` — **OMITTED (Internal Engine)**

> **Status: NOT a top-level CLI subcommand.** Per
> [`research/05_OMITTED_COMMANDS_RATIONALE.md`](../../05_OMITTED_COMMANDS_RATIONALE.md)
> § 1 (Internal Engine Hallucinations), `tldr cfg` is an internal
> Control-Flow-Graph engine, not an invocable command. Running
> `tldr cfg ...` returns:
>
> ```text
> error: unrecognized subcommand 'cfg'
> ```
>
> No Journal 04 probe dossier exists for `tldr cfg` because there is
> nothing to probe — the CFG engine is reachable only INDIRECTLY via
> commands that consume it:
>
> | Command | How it uses CFG |
> |---|---|
> | `tldr slice` | Forward/backward dataflow slice over the CFG |
> | `tldr reaching-defs` | Dataflow equations over the CFG |
> | `tldr chop` | Intersection of forward and backward slices over the CFG |
> | `tldr available` | Available-expressions dataflow over the CFG |
> | `tldr dead-stores` | SSA-based dead-store detection over the CFG |
>
> Agents that need CFG-derived information should pick the
> highest-level command that answers their actual question — never
> attempt to invoke `tldr cfg` directly.

## Probe Stub

See [`cfg.probes/probe.sh`](./cfg.probes/probe.sh) — a one-line marker
script that emits the omission notice and exits non-zero. It exists so
the protocol's automated audit (`done_count` from `find -type d -name
'*.probes'`) treats this entry as accounted for without requiring real
probe captures.
