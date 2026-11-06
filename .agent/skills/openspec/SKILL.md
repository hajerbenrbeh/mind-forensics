---
name: openspec
description: Spec-Driven Development (SDD) framework by Fission-AI. Use whenever proposing new features, exploring architectural ideas, creating change artifacts (proposal.md, specs/, design.md, tasks.md), executing tasks step-by-step, or syncing and archiving changes. Supports /opsx:propose, /opsx:apply, /opsx:explore, /opsx:sync, and /opsx:archive.
license: MIT
metadata:
  author: Fission-AI
  version: "1.0"
  repository: https://github.com/Fission-AI/OpenSpec
---

# OpenSpec — Spec-Driven Development (SDD) Framework

OpenSpec by **Fission-AI** (`Fission-AI/OpenSpec`) is an open-source standard for Spec-Driven Development. It ensures that requirements, delta specs, technical designs, and implementation checklists are formalized in plain Markdown before code is written, eliminating hallucinated scope, architectural drift, and silent assumptions.

---

## 📂 Repository File System Architecture

```text
openspec/
├── config.yaml                     # Project OpenSpec configuration
├── specs/                          # Source of Truth: Core Project Capabilities
│   ├── <capability-1>/spec.md
│   └── <capability-2>/spec.md
├── changes/                        # Active Work-in-Progress Changes
│   └── <change-id>/                # Kebab-case change identifier
│       ├── proposal.md             # Why & What (boundaries & motivation)
│       ├── specs/                  # Delta specs (ADDED, MODIFIED, REMOVED)
│       │   └── <capability>/spec.md
│       ├── design.md               # Technical approach & trade-offs (optional for small tasks)
│       └── tasks.md                # Sequential implementation checklist
└── archive/                        # Completed & merged changes
    └── YYYY-MM-DD-<change-id>/
```

---

## ⚡ Core Slash Commands & Workflows

### 1. `/opsx:explore [topic]` — Concept Exploration
Use when exploring an ambiguous problem space, evaluating trade-offs, or discussing ideas before opening a formal change.
- Stance: Curious, open-ended, architectural, and empathetic.
- Output: ASCII diagrams, architectural options, pros/cons, and recommended paths.
- Exit criterion: When consensus crystallizes, transition directly into `/opsx:propose`.

### 2. `/opsx:propose [change-id]` — Spec Proposal & Scaffolding
Creates a new change under `openspec/changes/<change-id>/` with all planning artifacts generated in one pass:
1. **`proposal.md`**: Problem statement, proposed solution, capabilities touched, and non-goals.
2. **`specs/<capability>/spec.md`**: Delta specification using RFC-2119 keywords (`SHALL`, `MUST`, `SHOULD`):
   ```markdown
   ## MODIFIED Requirements
   ### Requirement: Somatic Arousal Slider
   The system SHALL display dynamic bio-reactive track colors transitioning from Warm Beige to Cherry Red at >= 7/10 intensity.

   #### Scenario: High emotional activation
   - GIVEN the user is at Stage 2
   - WHEN arousal slider is adjusted to 8/10
   - THEN the track and intensity counter glow in Cherry Red (#E11D48).
   ```
3. **`design.md`**: Technical architecture, Riverpod providers, UI component hierarchies, and data models.
4. **`tasks.md`**: Actionable checklist:
   ```markdown
   # Tasks: <change-id>
   - [ ] 1. Define theme tokens and data contracts
   - [ ] 2. Implement UI components and animations
   - [ ] 3. Update tests and verify zero regressions
   ```
> **CRITICAL PLANNING BOUNDARY:** Proposing generates planning artifacts ONLY. Never modify project source code during a proposal phase until explicitly authorized by `/opsx:apply`.

### 3. `/opsx:apply [change-id]` — Task Execution Loop
Implements tasks from `openspec/changes/<change-id>/tasks.md` loop-by-loop:
1. Read context files (`proposal.md`, `specs/`, `design.md`, `tasks.md`).
2. Pick the first incomplete task `- [ ]`.
3. Implement the minimal, focused code change.
4. Mark the task complete `- [x]` immediately.
5. If an unexpected blocker or scope creep is encountered, PAUSE and present options before guessing.
6. Verify code health (`flutter analyze`, `flutter test`).

### 4. `/opsx:sync [change-id]` — Master Spec Synchronization
Merges the delta specifications from `openspec/changes/<change-id>/specs/` into the master capability specs under `openspec/specs/`:
- `ADDED` requirements are appended to the target capability spec.
- `MODIFIED` requirements overwrite the previous requirement text.
- `REMOVED` requirements are deleted or marked deprecated.

### 5. `/opsx:archive [change-id]` — Archival
Moves the completed change from `openspec/changes/<change-id>/` to `openspec/archive/<YYYY-MM-DD>-<change-id>/`.

---

## 🛡️ Guardrails & Directives

1. **Specs Precede Code:** Never write or modify production code without a clear change proposal and task checklist.
2. **Deterministic Task Checkboxes:** Update `- [ ]` to `- [x]` in `tasks.md` as each task is verified.
3. **No Silent Scope Drops:** If a task turns out to be more complex than expected, surface the challenge to the user rather than quietly skipping requirements.
4. **Zero Regressions:** After completing tasks, run analyzer and test suite to guarantee 100% test passing and zero issues.

