# Maintainer Workflow — Agent Rules Authoring & Distribution

This document covers the end-to-end pipeline for updating the tldr agent instructions and getting them onto client machines.

---

## The pipeline at a glance

```
agent-rules.md  →  update_hash.py  →  git push  →  npx skills  →  tldr-setup-check Step 7
 (edit here)        (hash only on       (publishes     (delivers       (injects/updates
                     agent-rules.md)     hash to        SKILL.md        AGENTS.md in
                                         GitHub)        files)          client projects)
```

---

## Step 1 — Edit `agent-rules.md`

`agent-rules.md` is the **only file you edit** when changing the agent instructions.

It contains the tldr rules block wrapped in sentinel markers:

```
<!-- BEGIN TLDR-AGENT-SKILLS hash:<8-hex> -->
...body...
<!-- END TLDR-AGENT-SKILLS -->
```

Edit only the body — between (not including) the markers. Do not touch the markers themselves; the hash script handles those.

---

## Step 2 — Recompute the hash

After editing, run:

```bash
python3 update_hash.py agent-rules.md
```

This computes `SHA-256(body)[:4]` (8 hex chars) and stamps the result into the BEGIN marker of `agent-rules.md`. Example output:

```
✅  agent-rules.md
    hash: a57cc22e → f39b7c01
```

**Do NOT run `update_hash.py` on `AGENTS.md`** — that file is not the source and is not part of this workflow.

---

## Step 3 — Commit and push

```bash
git add agent-rules.md
git commit -m "fix(agent-rules): <what changed and why>"
git push
```

The new hash in `agent-rules.md` on GitHub is now the canonical version. This is what all client machines will pull against.

---

## Step 4 — Distribution: `npx skills`

On client machines, users install the skill files with:

```bash
npx skills add udhaya10/tldr-agent-skills --all -g
```

This delivers all `SKILL.md` files. It does **not** deliver `AGENTS.md` — that is handled separately by `tldr-setup-check`.

---

## Step 5 — AGENTS.md injection: `tldr-setup-check` Step 7

`npx skills` only installs skill files. The agent instructions (`AGENTS.md`) reach client projects via a different mechanism built into `tldr-setup-check`.

When Step 7 of `tldr-setup-check` runs in any project, it:

1. Fetches `agent-rules.md` from raw GitHub (`https://raw.githubusercontent.com/udhaya10/tldr-agent-skills/main/agent-rules.md`)
2. Reads the hash from the fetched BEGIN marker
3. Compares it against the hash in the project's existing `AGENTS.md`

| Situation | Result |
|-----------|--------|
| Hashes match | No-op — nothing written, nothing changed |
| Hashes differ | Replaces only the managed block; surrounding AGENTS.md content untouched |
| No marker in AGENTS.md yet | First install — creates `AGENTS.md` if missing, appends the block |

After the first run, every future agent session in that project loads the tldr instructions automatically via `AGENTS.md`. `tldr-setup-check` only needs to inject once; after that it's hash-checking only.

---

## Ongoing freshness

`tldr-setup-check` runs in client projects on-demand (triggered by setup/diagnostic queries). Every time it runs, Step 7 re-checks the hash. If you pushed an update in Step 3, the next run in any client project will automatically pull in the new instructions — no manual action required from the user.

---

## What NOT to do

- **Do not run `update_hash.py AGENTS.md`** — `AGENTS.md` in this repo is a local reference copy, not the source. The hash script is for `agent-rules.md` only.
- **Do not edit `AGENTS.md` in this repo to publish changes** — edits here have no effect on client machines. Changes must go through `agent-rules.md`.
- **Do not skip the hash step** — without a new hash, client machines will see a hash match against the old content and not pull in your changes.

---

## Quick reference

```bash
# 1. Edit the rules
$EDITOR agent-rules.md

# 2. Stamp the hash (agent-rules.md only)
python3 update_hash.py agent-rules.md

# 3. Commit and push
git add agent-rules.md
git commit -m "fix(agent-rules): ..."
git push

# Client machines auto-update next time tldr-setup-check runs
```
