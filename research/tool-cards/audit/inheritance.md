# tldr inheritance

**Pitch**: Class-hierarchy extractor that maps every parent→child edge — with ABC/Protocol/mixin/diamond detection and a first-class DOT visualization path.

**Why reach for it**
- One of the few audit commands that emits DOT directly; pipe to `dot -Tsvg` for a publication-ready hierarchy diagram
- `--class <NAME>` zooms to a single class's ancestors + descendants — focused output that fits in an LLM context
- External base resolution flags stdlib bases (`ABC`, `Exception`) distinctly with `resolution: "stdlib"`
- Handles Python `extends`, TypeScript `extends`/`implements`, Go struct `embeds`, and Rust trait impl blocks under one `kind` taxonomy

**When to use**
- Visualizing or auditing a deep class hierarchy before a refactor
- Producing an architecture diagram for documentation (`-f dot | dot -Tsvg`)
- Investigating a specific class's ancestry/descendants (`--class <NAME> --depth N`)
- Finding diamond inheritance patterns or mixin abuse

**When NOT to use**
- Want intra-class cohesion (do methods share state?) — that's `tldr cohesion`
- Want generic per-file structural dump including non-class symbols — `tldr structure` or `tldr extract`

**Output in plain words**: An `InheritanceReport` with `edges[]` (each `child`, `parent`, file/line refs, `kind`, `external`, `resolution`), `nodes[]`, `roots[]`, `leaves[]`, `count`, and the resolved `languages[]`. With `-f dot`, a `digraph inheritance { rankdir=BT; ... }` with abstract classes styled in lightyellow and external nodes as dashed lightblue ellipses.

**Killer detail**: FOUR distinct failure modes — bad path, language mismatch, empty directory, and non-source file — all return exit 0 with the identical empty shape (`count: 0`, every array empty). Agents cannot tell them apart from output; verify the path externally and check `count > 0`.

**Other footguns**
- `--depth` without `--class` fails with the audit suite's best error — explicit hint paragraph and exit 25 (`TldrError::InvalidArgs`). Use `--class <NAME>` whenever depth-limiting.
- `--class NoSuchClass` returns exit 24 (`TldrError::NotFound`), distinct from `FunctionNotFound`'s exit 20. Branch on the exit code when scripting.

**Source**: `research/tldr/audit/inheritance.md`
