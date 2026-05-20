---
name: tldr-refactor-oo
description: Object-Oriented refactoring metrics. Use this to analyze class coupling, instantiation dependencies, and the depth of inheritance trees to untangle complex class structures.
allowed-tools: [bash]
---
# Skill: tldr-refactor-oo

This skill provides deep structural analysis of Object-Oriented designs.

## When to Use This Skill
Use this skill when refactoring a monolithic class, deciding whether to use Composition over Inheritance, or untangling tight object coupling.

## Supported Commands

### 1. `tldr coupling`
Calculate module/class coupling metrics (Afferent, Efferent, Instability).
* **Usage:** `tldr coupling <dir>`
* **Advanced Flags:**
  * `--threshold <FLOAT>`: Warn if instability exceeds this (default: 0.7).
* **Refactoring Value:** High Efferent coupling means the class relies on too many others (fragile). High Afferent means too many rely on it (rigid). Highly unstable classes should be refactored into interfaces.

### 2. `tldr inheritance`
Analyze class inheritance trees and depth.
* **Usage:** `tldr inheritance <dir>`
* **Advanced Flags:**
  * `--max-depth <N>`: Warn if tree depth exceeds this (default: 3).
* **Refactoring Value:** Deep inheritance trees (DIT > 3) are notoriously hard to test and maintain. Use this to identify classes that should be flattened via Composition.
