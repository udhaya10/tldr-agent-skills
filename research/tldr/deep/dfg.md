# Command: `tldr dfg`

## Ground Truth (`tldr dfg --help`)
```text
error: unrecognized subcommand 'dfg'
```

## Empirical Probes
* **Observation:** The `dfg` command does not exist in the public CLI.

## Intent & Routing
* **User/Agent Goal:** Not a CLI command.
* **When to choose this over similar tools:** Never. Internal engine only. DFG is accessed indirectly via `slice`, `reaching-defs`, `available`, and `dead-stores`.

## Agent Synthesis
> **Note:** DO NOT USE `tldr dfg`. It is not a valid subcommand.
