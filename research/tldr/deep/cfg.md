# Command: `tldr cfg`

## Ground Truth (`tldr cfg --help`)
```text
error: unrecognized subcommand 'cfg'
```

## Empirical Probes
* **Observation:** The `cfg` command does not exist in the public CLI.

## Intent & Routing
* **User/Agent Goal:** Not a CLI command.
* **When to choose this over similar tools:** Never. Internal engine only. CFG is accessed indirectly via `slice`, `reaching-defs`, `available`, and `dead-stores`.

## Agent Synthesis
> **Note:** DO NOT USE `tldr cfg`. It is not a valid subcommand.
