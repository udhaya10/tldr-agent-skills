# Agentic Utils

A repository for custom agent skills, tools, and workflows designed to enhance Large Language Model (LLM) autonomy.

## Skill Installation

This repository is compatible with the [Agent Skills CLI](https://agentskills.io/). You can install skills directly from this GitHub repository into your local agent environment (like Claude Code, Cursor, or Amp) without needing to clone it manually.

### Install Interactively
To browse and select which skills to install from this repository:
```bash
npx skills add udhayakumar/agentic-utils -g
```
*(The `-g` flag installs the skills globally for your agent user profile).*

### Install a Specific Skill
If you know the exact name of the skill (e.g., `tldr-fix`):
```bash
npx skills add udhayakumar/agentic-utils --skill tldr-fix -g
```

### Install All Skills
To install every skill in this repository at once, skipping prompts:
```bash
npx skills add udhayakumar/agentic-utils --all -g
```

---

## Directory Structure

To maintain compatibility with the Agent Skills CLI, this repository follows the standard `SKILL.md` structure. Each skill lives in its own isolated directory:

```text
agentic-utils/
├── README.md
├── skill-name-1/
│   ├── SKILL.md          # Required: The prompt and instructions
│   └── scripts/          # Optional: Executable bash/python scripts
└── skill-name-2/
    └── SKILL.md
```

## Developing New Skills

1. Create a new folder for your skill.
2. Add a `SKILL.md` file containing the YAML frontmatter and markdown instructions.
3. Push to GitHub.
4. Run `npx skills update -g` locally to fetch the latest changes.
## TLDR-Code Skills Ecosystem

This repository houses the decomposed agent skills for the `tldr-code` AST engine. The original CLI contains 60+ commands, which have been systematically audited and mapped into 13 highly-specialized agent skills.

For a full breakdown of the research methodology and why certain commands were intentionally hidden from the LLM, please see:
* [Empirical Research Methodology](research/03_EMPIRICAL_RESEARCH_METHODOLOGY.md)
* [Omitted Commands Rationale](research/05_OMITTED_COMMANDS_RATIONALE.md)
