# Capability: Cognitive Deconstruction

## Overview
Mind Forensics implements a structured 6-stage cognitive neuroscience deconstruction workflow designed to dismantle automatic cognitive distortions in under 60 seconds without essay journaling.

## Requirements

### Requirement: 1-Tap Activating Catalyst Selection
The system SHALL provide pre-computed cognitive catalyst chips (e.g. Unanswered Message, Work Critique, Social Comparison, Imposter Doubt) allowing 1-tap activation.

#### Scenario: User selects catalyst chip
- GIVEN the user starts a session at Stage 1
- WHEN they tap "Work Critique"
- THEN the chip is highlighted with Cherry Red accent borders and the trigger context is pre-populated.

### Requirement: Somatic & Neural Mapping
The system SHALL collect somatic body sensation and nervous system arousal intensity (1-10) before prompting for epistemic thought classification (Fact, Assumption, Interpretation).

#### Scenario: High emotional activation
- GIVEN the user adjusts the arousal slider
- WHEN intensity reaches >= 7/10
- THEN the slider track and numerical indicator illuminate in Cherry Red (#E11D48).

### Requirement: Socratic Reality Testing
The system SHALL provide interactive micro-toggles (Camera Test, 6-Month Horizon, Catastrophe Probability) rather than open text prompts.

#### Scenario: User tests empirical proof
- GIVEN the user is at Stage 4
- WHEN they toggle "Camera Test: Proven"
- THEN the toggle highlights in Warm Beige/Sand indicating empirical reality grounding.

### Requirement: 1-Tap Adaptive Reframe Anchoring
The system SHALL present 3 pre-computed clinical reframes and a "Slide-to-Anchor" tactile gesture slider.

#### Scenario: User anchors reframe
- GIVEN the user selects a clinical reframe
- WHEN they drag the anchor thumb past the 85% threshold
- THEN heavy haptic feedback fires, the session is persisted to offline storage, and the screen routes to the Cognitive Session Report.

