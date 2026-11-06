# Capability: Navigation Tabs & Daily Check-in

## Overview
Defines the 5-tab persistent bottom navigation bar, Step 6 daily check-in workflows, and future roadmap boundary conditions.

## Requirements

### Requirement: 5 Persistent Bottom Tabs
The application bottom navigation shell SHALL consist of exactly five tabs:
1. **Home:** Executive overview, daily check-in card, last mood, open sessions, recent entries, and internal insights.
2. **Journal:** Chronological archive and search of all past cognitive deconstruction sessions.
3. **Investigator:** Tactile launchpad for active cognitive deconstruction sessions.
4. **Toolkit (placeholder in v1):** Grounding and neuro-regulation tools with explicit placeholder badge for v2 expansion.
5. **Profile:** User settings, data purge, language switcher (AR/FR/EN), and clinical safety information.

#### Scenario: Insights location in v1
- GIVEN the user is navigating the application in Version 1
- WHEN they view cognitive pattern insights
- THEN insights live inside Home until Version 2.

### Requirement: Step 6 Daily Check-in Workflow
The system SHALL provide a daily check-in with:
1. Emotion selection from an emotion library (`calm`, `anxious`, `frustrated`, `heavy`, `restless`);
2. Self-reported intensity slider on a discrete 1–10 scale;
3. Optional free-text "today's note" field;
4. Simple Home layout displaying check-in card, last mood, open cases, and recent entries.

#### Scenario: Submitting a daily check-in
- GIVEN the user is on the Home screen
- WHEN they select an emotion, set intensity, optionally enter "today's note", and save
- THEN the "last mood" reflects the entry, and the state persists.

### Requirement: Later Features Boundary (Do NOT build now)
The following capabilities are deferred and MUST NOT be built in v1:
- **Toolkit (v2):** Short mindfulness and relaxation exercises (with "stop anytime" option), sleep hygiene tips, self-reported sleep diary, activity planner based on behavioral activation, emotion library.
- **CBT-inspired tools and Resilience Plan (v2.5):** Distortion explorer, behavioral experiments, problem-solving flow, user-written Resilience Plan ("My Plan": early warning signs, what helps, who to contact), shareable with a therapist only by user choice. The AI may help organize it but must NEVER predict relapse or judge the person.
- **Paths (v3):** Multi-week guided programs with AI-adapted pacing and reflection questions (placeholder drafts requiring professional review before release).

