# tldr cognitive

**Pitch**: SonarQube cognitive-complexity scorer that ranks every function in a path by how hard it is for a human to follow, with optional per-line breakdown of which constructs contributed to the score.

**Why reach for it**
- Cognitive complexity penalizes NESTING more heavily than cyclomatic — a function with a deeply-nested loop scores higher here than under `tldr complexity`, which better matches human "what is this doing" effort
- `--show-contributors` returns `{line, construct, base_increment, nesting_increment, nesting_level}` per row — directly drives refactor suggestions ("flatten this nested `if`, extract this inner loop")
- `--include-cyclomatic` adds the cyclomatic number side-by-side without a second tool invocation
- `threshold_status` enum (`ok`/`warning`/`severe`) makes triage automation trivial — tied to `--threshold` (default 15) and `--high-threshold` (default 25)

**When to use**
- Ranking functions across a file or directory by maintainability risk — picking refactor candidates
- Need per-line explanations of WHERE the complexity comes from, not just a single score
- Want a project-wide complexity dashboard with violations classified into three buckets

**When NOT to use**
- Need just the four metrics for ONE function already named — `tldr complexity` is the focused, daemon-cached path
- Care about token vocabulary / predicted bug count — `tldr halstead` measures a different dimension

**Output in plain words**: JSON `{functions[], violations[], summary, warnings?}`. Each function entry carries `cognitive, max_nesting, nesting_penalty, threshold_status` (and `cyclomatic`/`contributors[]` when their flags are set).

**Killer detail**: THREE silent-empty modes return exit 0 with identical empty shapes: function-not-found, empty directory, and language-mismatch. ONLY the lang-mismatch case includes `warnings: ["No supported source files found in <path>"]` — without that warning field, the caller cannot distinguish "wrong language" from "no such function" by JSON shape alone.

**Source**: `research/tldr/audit/cognitive.md`
