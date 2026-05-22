[Skip to main content](https://agentskills.io/home#content-area)

Agent Skills now has an official [Discord server](https://discord.gg/MKPE9g8aUy). See the [announcement](https://github.com/agentskills/agentskills/discussions/273) for details.

[Agent Skills home page\\
Agent Skills](https://agentskills.io/)

Search...

Ctrl KAsk AI

Search...

Navigation

Agent Skills Overview

> ## Documentation Index
>
> Fetch the complete documentation index at: [https://agentskills.io/llms.txt](https://agentskills.io/llms.txt)
>
> Use this file to discover all available pages before exploring further.

## [​](https://agentskills.io/home\#what-are-agent-skills)  What are Agent Skills?

Agent Skills are a lightweight, open format for extending AI agent capabilities with specialized knowledge and workflows.At its core, a skill is a folder containing a `SKILL.md` file. This file includes metadata (`name` and `description`, at minimum) and instructions that tell an agent how to perform a specific task. Skills can also bundle scripts, reference materials, templates, and other resources.

```
my-skill/
├── SKILL.md          # Required: metadata + instructions
├── scripts/          # Optional: executable code
├── references/       # Optional: documentation
├── assets/           # Optional: templates, resources
└── ...               # Any additional files or directories
```

## [​](https://agentskills.io/home\#why-agent-skills)  Why Agent Skills?

Agents are increasingly capable, but often don’t have the context they need to do real work reliably. Skills solve this by packaging procedural knowledge and company-, team-, and user-specific context into portable, version-controlled folders that agents load on demand. This gives agents:

- **Domain expertise**: Capture specialized knowledge — from legal review processes to data analysis pipelines to presentation formatting — as reusable instructions and resources.
- **Repeatable workflows**: Turn multi-step tasks into consistent, auditable procedures.
- **Cross-product reuse**: Build a skill once and use it across any skills-compatible agent.

## [​](https://agentskills.io/home\#how-do-agent-skills-work)  How do Agent Skills work?

Agents load skills through **progressive disclosure**, in three stages:

1. **Discovery**: At startup, agents load only the name and description of each available skill, just enough to know when it might be relevant.
2. **Activation**: When a task matches a skill’s description, the agent reads the full `SKILL.md` instructions into context.
3. **Execution**: The agent follows the instructions, optionally executing bundled code or loading referenced files as needed.

Full instructions load only when a task calls for them, so agents can keep many skills on hand with only a small context footprint.

## [​](https://agentskills.io/home\#where-can-i-use-agent-skills)  Where can I use Agent Skills?

Agent Skills are supported by a large number of AI tools and agentic clients — see the [Client Showcase](https://agentskills.io/clients) to explore some of them!

[![OpenCode](https://agentskills.io/images/logos/opencode/opencode-wordmark-light.svg)![OpenCode](https://agentskills.io/images/logos/opencode/opencode-wordmark-dark.svg)](https://opencode.ai/)

[![Letta](https://agentskills.io/images/logos/letta/Letta-logo-RGB_OffBlackonTransparent.svg)![Letta](https://agentskills.io/images/logos/letta/Letta-logo-RGB_GreyonTransparent.svg)](https://www.letta.com/)

[![Roo Code](https://agentskills.io/images/logos/roo-code/roo-code-logo-black.svg)![Roo Code](https://agentskills.io/images/logos/roo-code/roo-code-logo-white.svg)](https://roocode.com/)

[![Emdash](https://agentskills.io/images/logos/emdash/emdash-logo-light.svg)![Emdash](https://agentskills.io/images/logos/emdash/emdash-logo-dark.svg)](https://emdash.sh/)

[![OpenAI Codex](https://agentskills.io/images/logos/oai-codex/OAI_Codex-Lockup_400px.svg)![OpenAI Codex](https://agentskills.io/images/logos/oai-codex/OAI_Codex-Lockup_400px_Darkmode.svg)](https://developers.openai.com/codex)

[![Gemini CLI](https://agentskills.io/images/logos/gemini-cli/gemini-cli-logo_light.svg)![Gemini CLI](https://agentskills.io/images/logos/gemini-cli/gemini-cli-logo_dark.svg)](https://geminicli.com/)

[![Kiro](https://agentskills.io/images/logos/kiro/kiro-logo-light.svg)![Kiro](https://agentskills.io/images/logos/kiro/kiro-logo-dark.svg)](https://kiro.dev/)

[![Firebender](https://agentskills.io/images/logos/firebender/firebender-wordmark-light.svg)![Firebender](https://agentskills.io/images/logos/firebender/firebender-wordmark-dark.svg)](https://firebender.com/)

[![Piebald](https://agentskills.io/images/logos/piebald/Piebald_wordmark_light.svg)![Piebald](https://agentskills.io/images/logos/piebald/Piebald_wordmark_dark.svg)](https://piebald.ai/)

[![Cursor](https://agentskills.io/images/logos/cursor/LOCKUP_HORIZONTAL_2D_LIGHT.svg)![Cursor](https://agentskills.io/images/logos/cursor/LOCKUP_HORIZONTAL_2D_DARK.svg)](https://cursor.com/)

[![pi](https://agentskills.io/images/logos/pi/pi-logo-light.svg)![pi](https://agentskills.io/images/logos/pi/pi-logo-dark.svg)](https://shittycodingagent.ai/)

[![Vita](https://agentskills.io/images/logos/vita/logo-horizontal-light.svg)![Vita](https://agentskills.io/images/logos/vita/logo-horizontal-dark.svg)](https://www.vita-ai.net/)

[![Tabnine](https://agentskills.io/images/logos/tabnine/tabnine-logo-light.svg)![Tabnine](https://agentskills.io/images/logos/tabnine/tabnine-logo-dark.svg)](https://www.tabnine.com/)

[![Factory](https://agentskills.io/images/logos/factory/factory-logo-light.svg)![Factory](https://agentskills.io/images/logos/factory/factory-logo-dark.svg)](https://factory.ai/)

[![Goose](https://agentskills.io/images/logos/goose/goose-logo-black.png)![Goose](https://agentskills.io/images/logos/goose/goose-logo-white.png)](https://block.github.io/goose/)

[![fast-agent](https://agentskills.io/images/logos/fast-agent/fast-agent-light.svg)![fast-agent](https://agentskills.io/images/logos/fast-agent/fast-agent-dark.svg)](https://fast-agent.ai/)

[![Claude](https://agentskills.io/images/logos/claude-ai/Claude-logo-Slate.svg)![Claude](https://agentskills.io/images/logos/claude-ai/Claude-logo-Ivory.svg)](https://claude.ai/)

[![Autohand Code CLI](https://agentskills.io/images/logos/autohand/autohand-light.svg)![Autohand Code CLI](https://agentskills.io/images/logos/autohand/autohand-dark.svg)](https://autohand.ai/)

[![Qodo](https://agentskills.io/images/logos/qodo/qodo-logo-light.png)![Qodo](https://agentskills.io/images/logos/qodo/qodo-logo-dark.svg)](https://www.qodo.ai/)

[![VT Code](https://agentskills.io/images/logos/vtcode/vt_code_light.svg)![VT Code](https://agentskills.io/images/logos/vtcode/vt_code_dark.svg)](https://github.com/vinhnx/vtcode)

[![Google AI Edge Gallery](https://agentskills.io/images/logos/google-ai-edge-gallery/google-ai-edge-gallery-light.svg)![Google AI Edge Gallery](https://agentskills.io/images/logos/google-ai-edge-gallery/google-ai-edge-gallery-dark.svg)](https://github.com/google-ai-edge/gallery)

[![GitHub Copilot](https://agentskills.io/images/logos/github/GitHub_Lockup_Dark.svg)![GitHub Copilot](https://agentskills.io/images/logos/github/GitHub_Lockup_Light.svg)](https://github.com/)

[![VS Code](https://agentskills.io/images/logos/vscode/vscode.svg)![VS Code](https://agentskills.io/images/logos/vscode/vscode-alt.svg)](https://code.visualstudio.com/)

[![Superconductor](https://agentskills.io/images/logos/superconductor/superconductor-wordmark-light.svg)![Superconductor](https://agentskills.io/images/logos/superconductor/superconductor-wordmark-dark.svg)](https://superconductor.com/)

[![bub](https://agentskills.io/images/logos/bub/bub-light.svg)![bub](https://agentskills.io/images/logos/bub/bub-dark.svg)](https://bub.build/)

[![TRAE](https://agentskills.io/images/logos/trae/trae-logo-lightmode.svg)![TRAE](https://agentskills.io/images/logos/trae/trae-logo-darkmode.svg)](https://trae.ai/)

[![Ona](https://agentskills.io/images/logos/ona/ona-wordmark-light.svg)![Ona](https://agentskills.io/images/logos/ona/ona-wordmark-dark.svg)](https://ona.com/)

[![nanobot](https://agentskills.io/images/logos/nanobot/nanobot-logo-light.png)![nanobot](https://agentskills.io/images/logos/nanobot/nanobot-logo-dark.png)](https://nanobot.wiki/)

[![Junie](https://agentskills.io/images/logos/junie/junie-logo-on-white.svg)![Junie](https://agentskills.io/images/logos/junie/junie-logo-on-dark.svg)](https://junie.jetbrains.com/)

[![Snowflake Cortex Code](https://agentskills.io/images/logos/snowflake/snowflake-logo-light.svg)![Snowflake Cortex Code](https://agentskills.io/images/logos/snowflake/snowflake-logo-dark.svg)](https://docs.snowflake.com/en/user-guide/cortex-code/cortex-code)

[![Mux](https://agentskills.io/images/logos/mux/mux-editor-light.svg)![Mux](https://agentskills.io/images/logos/mux/mux-editor-dark.svg)](https://mux.coder.com/)

[![Mistral AI Vibe](https://agentskills.io/images/logos/mistral-vibe/vibe-logo_black.svg)![Mistral AI Vibe](https://agentskills.io/images/logos/mistral-vibe/vibe-logo_white.svg)](https://github.com/mistralai/mistral-vibe)

[![Agentman](https://agentskills.io/images/logos/agentman/agentman-wordmark-light.svg)![Agentman](https://agentskills.io/images/logos/agentman/agentman-wordmark-dark.svg)](https://agentman.ai/)

[![Amp](https://agentskills.io/images/logos/amp/amp-logo-light.svg)![Amp](https://agentskills.io/images/logos/amp/amp-logo-dark.svg)](https://ampcode.com/)

[![Command Code](https://agentskills.io/images/logos/command-code/command-code-logo-for-light.svg)![Command Code](https://agentskills.io/images/logos/command-code/command-code-logo-for-dark.svg)](https://commandcode.ai/)

[![Databricks Genie Code](https://agentskills.io/images/logos/databricks/databricks-logo-light.svg)![Databricks Genie Code](https://agentskills.io/images/logos/databricks/databricks-logo-dark.svg)](https://databricks.com/)

[![OpenHands](https://agentskills.io/images/logos/openhands/openhands-logo-light.svg)![OpenHands](https://agentskills.io/images/logos/openhands/openhands-logo-dark.svg)](https://openhands.dev/)

[![Spring AI](https://agentskills.io/images/logos/spring-ai/spring-ai-logo-light.svg)![Spring AI](https://agentskills.io/images/logos/spring-ai/spring-ai-logo-dark.svg)](https://docs.spring.io/spring-ai/reference)

[![Workshop](https://agentskills.io/images/logos/workshop/workshop-logo-light.svg)![Workshop](https://agentskills.io/images/logos/workshop/workshop-logo-dark.svg)](https://workshop.ai/)

[![Laravel Boost](https://agentskills.io/images/logos/laravel-boost/boost-light-mode.svg)![Laravel Boost](https://agentskills.io/images/logos/laravel-boost/boost-dark-mode.svg)](https://github.com/laravel/boost)

[![Claude Code](https://agentskills.io/images/logos/claude-code/Claude-Code-logo-Slate.svg)![Claude Code](https://agentskills.io/images/logos/claude-code/Claude-Code-logo-Ivory.svg)](https://claude.ai/code)

[![OpenCode](https://agentskills.io/images/logos/opencode/opencode-wordmark-light.svg)![OpenCode](https://agentskills.io/images/logos/opencode/opencode-wordmark-dark.svg)](https://opencode.ai/)

[![Letta](https://agentskills.io/images/logos/letta/Letta-logo-RGB_OffBlackonTransparent.svg)![Letta](https://agentskills.io/images/logos/letta/Letta-logo-RGB_GreyonTransparent.svg)](https://www.letta.com/)

[![Roo Code](https://agentskills.io/images/logos/roo-code/roo-code-logo-black.svg)![Roo Code](https://agentskills.io/images/logos/roo-code/roo-code-logo-white.svg)](https://roocode.com/)

[![Emdash](https://agentskills.io/images/logos/emdash/emdash-logo-light.svg)![Emdash](https://agentskills.io/images/logos/emdash/emdash-logo-dark.svg)](https://emdash.sh/)

[![OpenAI Codex](https://agentskills.io/images/logos/oai-codex/OAI_Codex-Lockup_400px.svg)![OpenAI Codex](https://agentskills.io/images/logos/oai-codex/OAI_Codex-Lockup_400px_Darkmode.svg)](https://developers.openai.com/codex)

[![Gemini CLI](https://agentskills.io/images/logos/gemini-cli/gemini-cli-logo_light.svg)![Gemini CLI](https://agentskills.io/images/logos/gemini-cli/gemini-cli-logo_dark.svg)](https://geminicli.com/)

[![Kiro](https://agentskills.io/images/logos/kiro/kiro-logo-light.svg)![Kiro](https://agentskills.io/images/logos/kiro/kiro-logo-dark.svg)](https://kiro.dev/)

[![Firebender](https://agentskills.io/images/logos/firebender/firebender-wordmark-light.svg)![Firebender](https://agentskills.io/images/logos/firebender/firebender-wordmark-dark.svg)](https://firebender.com/)

[![Piebald](https://agentskills.io/images/logos/piebald/Piebald_wordmark_light.svg)![Piebald](https://agentskills.io/images/logos/piebald/Piebald_wordmark_dark.svg)](https://piebald.ai/)

[![Cursor](https://agentskills.io/images/logos/cursor/LOCKUP_HORIZONTAL_2D_LIGHT.svg)![Cursor](https://agentskills.io/images/logos/cursor/LOCKUP_HORIZONTAL_2D_DARK.svg)](https://cursor.com/)

[![pi](https://agentskills.io/images/logos/pi/pi-logo-light.svg)![pi](https://agentskills.io/images/logos/pi/pi-logo-dark.svg)](https://shittycodingagent.ai/)

[![Vita](https://agentskills.io/images/logos/vita/logo-horizontal-light.svg)![Vita](https://agentskills.io/images/logos/vita/logo-horizontal-dark.svg)](https://www.vita-ai.net/)

[![Tabnine](https://agentskills.io/images/logos/tabnine/tabnine-logo-light.svg)![Tabnine](https://agentskills.io/images/logos/tabnine/tabnine-logo-dark.svg)](https://www.tabnine.com/)

[![Factory](https://agentskills.io/images/logos/factory/factory-logo-light.svg)![Factory](https://agentskills.io/images/logos/factory/factory-logo-dark.svg)](https://factory.ai/)

[![Goose](https://agentskills.io/images/logos/goose/goose-logo-black.png)![Goose](https://agentskills.io/images/logos/goose/goose-logo-white.png)](https://block.github.io/goose/)

[![fast-agent](https://agentskills.io/images/logos/fast-agent/fast-agent-light.svg)![fast-agent](https://agentskills.io/images/logos/fast-agent/fast-agent-dark.svg)](https://fast-agent.ai/)

[![Claude](https://agentskills.io/images/logos/claude-ai/Claude-logo-Slate.svg)![Claude](https://agentskills.io/images/logos/claude-ai/Claude-logo-Ivory.svg)](https://claude.ai/)

[![Autohand Code CLI](https://agentskills.io/images/logos/autohand/autohand-light.svg)![Autohand Code CLI](https://agentskills.io/images/logos/autohand/autohand-dark.svg)](https://autohand.ai/)

[![Qodo](https://agentskills.io/images/logos/qodo/qodo-logo-light.png)![Qodo](https://agentskills.io/images/logos/qodo/qodo-logo-dark.svg)](https://www.qodo.ai/)

[![VT Code](https://agentskills.io/images/logos/vtcode/vt_code_light.svg)![VT Code](https://agentskills.io/images/logos/vtcode/vt_code_dark.svg)](https://github.com/vinhnx/vtcode)

[![Google AI Edge Gallery](https://agentskills.io/images/logos/google-ai-edge-gallery/google-ai-edge-gallery-light.svg)![Google AI Edge Gallery](https://agentskills.io/images/logos/google-ai-edge-gallery/google-ai-edge-gallery-dark.svg)](https://github.com/google-ai-edge/gallery)

[![GitHub Copilot](https://agentskills.io/images/logos/github/GitHub_Lockup_Dark.svg)![GitHub Copilot](https://agentskills.io/images/logos/github/GitHub_Lockup_Light.svg)](https://github.com/)

[![VS Code](https://agentskills.io/images/logos/vscode/vscode.svg)![VS Code](https://agentskills.io/images/logos/vscode/vscode-alt.svg)](https://code.visualstudio.com/)

[![Superconductor](https://agentskills.io/images/logos/superconductor/superconductor-wordmark-light.svg)![Superconductor](https://agentskills.io/images/logos/superconductor/superconductor-wordmark-dark.svg)](https://superconductor.com/)

[![bub](https://agentskills.io/images/logos/bub/bub-light.svg)![bub](https://agentskills.io/images/logos/bub/bub-dark.svg)](https://bub.build/)

[![TRAE](https://agentskills.io/images/logos/trae/trae-logo-lightmode.svg)![TRAE](https://agentskills.io/images/logos/trae/trae-logo-darkmode.svg)](https://trae.ai/)

[![Ona](https://agentskills.io/images/logos/ona/ona-wordmark-light.svg)![Ona](https://agentskills.io/images/logos/ona/ona-wordmark-dark.svg)](https://ona.com/)

[![nanobot](https://agentskills.io/images/logos/nanobot/nanobot-logo-light.png)![nanobot](https://agentskills.io/images/logos/nanobot/nanobot-logo-dark.png)](https://nanobot.wiki/)

[![Junie](https://agentskills.io/images/logos/junie/junie-logo-on-white.svg)![Junie](https://agentskills.io/images/logos/junie/junie-logo-on-dark.svg)](https://junie.jetbrains.com/)

[![Snowflake Cortex Code](https://agentskills.io/images/logos/snowflake/snowflake-logo-light.svg)![Snowflake Cortex Code](https://agentskills.io/images/logos/snowflake/snowflake-logo-dark.svg)](https://docs.snowflake.com/en/user-guide/cortex-code/cortex-code)

[![Mux](https://agentskills.io/images/logos/mux/mux-editor-light.svg)![Mux](https://agentskills.io/images/logos/mux/mux-editor-dark.svg)](https://mux.coder.com/)

[![Mistral AI Vibe](https://agentskills.io/images/logos/mistral-vibe/vibe-logo_black.svg)![Mistral AI Vibe](https://agentskills.io/images/logos/mistral-vibe/vibe-logo_white.svg)](https://github.com/mistralai/mistral-vibe)

[![Agentman](https://agentskills.io/images/logos/agentman/agentman-wordmark-light.svg)![Agentman](https://agentskills.io/images/logos/agentman/agentman-wordmark-dark.svg)](https://agentman.ai/)

[![Amp](https://agentskills.io/images/logos/amp/amp-logo-light.svg)![Amp](https://agentskills.io/images/logos/amp/amp-logo-dark.svg)](https://ampcode.com/)

[![Command Code](https://agentskills.io/images/logos/command-code/command-code-logo-for-light.svg)![Command Code](https://agentskills.io/images/logos/command-code/command-code-logo-for-dark.svg)](https://commandcode.ai/)

[![Databricks Genie Code](https://agentskills.io/images/logos/databricks/databricks-logo-light.svg)![Databricks Genie Code](https://agentskills.io/images/logos/databricks/databricks-logo-dark.svg)](https://databricks.com/)

[![OpenHands](https://agentskills.io/images/logos/openhands/openhands-logo-light.svg)![OpenHands](https://agentskills.io/images/logos/openhands/openhands-logo-dark.svg)](https://openhands.dev/)

[![Spring AI](https://agentskills.io/images/logos/spring-ai/spring-ai-logo-light.svg)![Spring AI](https://agentskills.io/images/logos/spring-ai/spring-ai-logo-dark.svg)](https://docs.spring.io/spring-ai/reference)

[![Workshop](https://agentskills.io/images/logos/workshop/workshop-logo-light.svg)![Workshop](https://agentskills.io/images/logos/workshop/workshop-logo-dark.svg)](https://workshop.ai/)

[![Laravel Boost](https://agentskills.io/images/logos/laravel-boost/boost-light-mode.svg)![Laravel Boost](https://agentskills.io/images/logos/laravel-boost/boost-dark-mode.svg)](https://github.com/laravel/boost)

[![Claude Code](https://agentskills.io/images/logos/claude-code/Claude-Code-logo-Slate.svg)![Claude Code](https://agentskills.io/images/logos/claude-code/Claude-Code-logo-Ivory.svg)](https://claude.ai/code)

## [​](https://agentskills.io/home\#open-development)  Open development

The Agent Skills format was originally developed by [Anthropic](https://www.anthropic.com/), released as an open standard, and has been adopted by a growing number of agent products. The standard is open to contributions from the broader ecosystem.Come join the discussion on [GitHub](https://github.com/agentskills/agentskills) or [Discord](https://discord.gg/MKPE9g8aUy)!

## [​](https://agentskills.io/home\#get-started-with-agent-skills)  Get started with Agent Skills

[**Quickstart** \\
\\
Create your first Agent Skill and see it in action.](https://agentskills.io/skill-creation/quickstart)

[**Specification** \\
\\
The complete format specification for Agent Skills.](https://agentskills.io/specification)

[Specification](https://agentskills.io/specification)

Ctrl+I

Assistant

Responses are generated using AI and may contain mistakes.