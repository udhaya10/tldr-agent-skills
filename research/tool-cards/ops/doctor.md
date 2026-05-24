# tldr doctor

> **Before writing the Usage block**: check `verified-invocations.md` in this group's
> `tool-cards/ops/` directory and copy the canonical syntax verbatim.
> Do NOT reconstruct syntax from prose — that is how hallucinated flags get introduced.

**Pitch**: Environment check for whether the type-checkers and linters that back `tldr diagnostics` are installed on the local system — a human-operator setup command suppressed from agent skills.

**Why reach for it**
- (Humans only) One-shot inventory of which language toolchains are missing
- (Humans only) `--install <LANG>` runs the registered install command (`pip install pyright ruff`, etc.) — a destructive convenience for dev-machine setup
- Agents get zero value: they can't fix missing system binaries, and `tldr diagnostics` already emits exit 60 with install hints when its dependencies are missing

**When to use**
- Operator setting up a fresh dev machine and wants a status board of language tooling
- Operator wants `tldr diagnostics` working for a specific language and prefers auto-install over reading docs
- Never inside an agent tool loop

**When NOT to use**
- An agent that just hit a `diagnostics` failure — read the exit 60 hint that's already in `tldr diagnostics` output instead
- Checking whether a specific package is installed — use `which` directly

**Usage (copy from `verified-invocations.md` — do not reconstruct)**:
```
tldr doctor [OPTIONS]
```
```
# P01 — full environment check
tldr doctor
# P02 — machine-readable output, quiet
tldr doctor -f json -q
# P11 — filter to a specific language
tldr doctor -l python
```

**Output in plain words**: JSON object keyed by language name (~15 languages), each with `type_checker` and `linter` sub-objects reporting `installed`, the absolute path when present, and an `install` hint string when missing.

**Killer detail**: Only 7 of the ~15 detected languages have working `--install` support (go, kotlin, lua, python, ruby, rust, swift) — JavaScript, TypeScript, C, C++, C#, Java, PHP, and Scala all return exit 1 "No auto-install available" because their install commands aren't registered.

**Source**: `research/tldr/ops/doctor.md`
