# `tldr <command>`

> **Before writing the Usage block**: check `verified-invocations.md` in this group's
> `tool-cards/<group>/` directory and copy the canonical syntax verbatim.
> Do NOT reconstruct syntax from prose — that is how hallucinated flags get introduced.

**Pitch**: <one-sentence answer to "why does this command exist?">

**Why reach for it**
- <specific capability that replaces N manual steps>
- <specific capability>
- <specific capability>

**When to use**
- <concrete scenario that maps to this command>
- <concrete scenario>

**When NOT to use**
- <scenario that looks like this command but belongs elsewhere — name the right command>
- <scenario>

**Usage (copy from `verified-invocations.md` — do not reconstruct)**:
```bash
tldr <command> <args>          # happy-path example from P01
tldr <command> <args> --flag   # key variant (P0N)
```

**Output in plain words**: <what the JSON contains, no field names, just what it means>

**Killer detail**: <the single most surprising or dangerous thing about this command — a footgun, a silent failure mode, a flag that does nothing, an exit-code lie>

**Other footguns** *(if more than one)*:
- <footgun>
- <footgun>

**Source**: `research/tldr/<group>/<command>.md`
