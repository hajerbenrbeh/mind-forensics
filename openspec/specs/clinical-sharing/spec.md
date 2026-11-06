# Capability: Clinical Session Briefs & Patient-Initiated Sharing

## Overview
Mind Forensics implements Section 12 of the product concept: a patient-initiated, privacy-shielded clinical export system ("Session Brief") designed to assist users in preparing for consultations with licensed psychologists and healthcare professionals.

## Principles & Operational Constraints

1. **Patient Sovereignty (Principle 1):** The user decides everything. Nothing is ever shared automatically, and third-party professionals never receive independent access to the app or device database.
2. **Selective Shielding (Principle 2):** The user selectively designates cases. Any case marked "Private, never shareable" is strictly shielded and excluded from export generation.
3. **CBT Bounds & Disclaimers (Principle 4):**
   - Strictly described as "inspired by CBT principles" — never termed "CBT treatment" or "therapy".
   - AI-assisted hypotheses are explicitly branded as exploratory cognitive reflections, never clinical findings, psychiatric diagnoses, or medical advice.
   - The app never predicts relapse.
   - Patient statements, triggers, thoughts, and conclusions are presented as authentic self-reports.
4. **Visible Sharing Audit Trail (Principle 5):** The app maintains a locally persisted visible audit log of all exported briefs, session IDs included, recipient tags, and timestamps.
5. **Plain-Language Pre-Export Inspection (Principle 6):** Users review the full synthesized document within an OLED dark modal preview before copying or exporting.

## Requirements

### Requirement: Case Privacy Shield
The application SHALL support toggling an `isPrivate` flag on any case, strictly excluding it from session brief generation.

#### Scenario: Attempting to export a private shielded case
- GIVEN a case has `isPrivate == true`
- WHEN the user attempts to export or include it in a session brief
- THEN the system blocks export of that case and displays the privacy shield protection notice.

### Requirement: Clinical Session Brief Generation
The system SHALL compile selected non-private cases into a structured, trilingual clinical brief.

#### Scenario: Exporting multiple sessions
- GIVEN the user selects one or more non-private sessions in the Journal
- WHEN the user initiates "Preview Brief"
- THEN a formatted synthesis is produced containing:
  - Mandatory clinical disclaimers (inspired by CBT, exploratory AI reflections, non-diagnostic).
  - Activating catalysts and observable triggers.
  - Automatic thoughts with epistemic labels (Fact, Assumption, Interpretation).
  - Emotional affect and self-reported 1–10 intensity.
  - Patient's grounded conclusion in their own words.

### Requirement: Visible Export Audit Logging
The system SHALL log each patient-initiated export event into a local, reviewable audit trail.

#### Scenario: Inspecting sharing history in Settings
- GIVEN the user has previously copied or exported a Session Brief
- WHEN the user opens "Clinical Sharing History" in Settings
- THEN the system displays the timestamp, included session count, session numbers, and recipient/note, with the ability to purge the log at any time.

