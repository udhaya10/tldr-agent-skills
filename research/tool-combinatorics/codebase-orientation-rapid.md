# Lens: Codebase orientation — rapid (time-boxed) flow

**The question this lens answers**: "I have ~60 minutes. What's the highest-signal orientation I can get?"

**Toolset**: `tldr structure`, `tldr extract` — *deliberately* not `tldr tree` first

**Why this lens, why these tools**: Time-boxed orientation skips the filesystem-only step. The signal density per minute is highest at the API surface: what functions and classes exist, where they live, how they relate. The filesystem walk (`tldr tree`) is mostly noise when you only have an hour — `tldr structure` already gives you file paths via its line-number locations. The discipline is "highest signal first, accept the coverage gap."

## Moves

The order is firm — but the loop terminates aggressively. Resist drilling further than step 4.

1. **`tldr structure <project> -l <dominant-lang>`** — one call, every function and class across the project with line numbers. Pass `-l` explicitly to avoid the auto-detect-picks-wrong-language silent failure.
2. **Scan output for "anchor files"** — files with many definitions, files in `core/` / `lib/` / `services/` / `domain/` paths, files referenced often in import statements. These are the project's spine. Usually 3–5 files; never more than ~10.
3. **`tldr extract <anchor-file>` × 3** — pick the top 3 anchor files and get full intra-file call graph for each. That's the architectural skeleton.
4. **Stop.** Resist drilling further until you've started actual work. Orientation is for triage, not mastery.

## What this lens captures

- **Highest-density signal in the shortest time** — `structure` + 3 `extract` calls is usually 20–30 minutes of real work.
- **Enough mental model to start triaging real questions**, not enough to claim expertise — that's the right calibration for a time-box.
- **Avoids the "I read every file" trap** that wastes hours without producing insight.

## What this lens misses

- **File-system surprises.** Skipping `tldr tree` means you might not notice unusual directory layouts, config sprawl, or build artifacts living in source dirs. If layout matters to your task (e.g., you're about to add a new module), switch to canonical.
- **Coverage.** You'll skip 80% of files. That's the trade — accept it.
- **Dependency direction.** Rapid lens doesn't run `importers`/`imports`. If you're about to make a structural change, switch to canonical or add targeted `importers` calls for the modules you'll touch.
- **Hot-spot prioritization.** Same as canonical — needs `tldr hotspots`.

## Common mistake

**Cargo-culting `tldr tree` before `structure`.** Tree adds nothing for time-boxed orientation; structure already gives you file paths via the line-number locations on every definition. Running tree first burns 5–10 minutes for zero new signal.

## Pair with

- `codebase-orientation-canonical.md` — same toolset (mostly), full-depth lens
- *(future)* `codebase-orientation-pre-change.md` — same toolset, change-safety lens

## Sources

- `research/tool-cards/overview/structure.md`
- `research/tool-cards/overview/extract.md`
