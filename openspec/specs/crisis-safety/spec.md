# Capability: Crisis Safety & Interception

## Overview
Mind Forensics operates a dual-layer, offline-first safety system to detect crisis indicators and connect Tunisian users with immediate emergency services, while strictly enforcing clinical non-diagnostic boundaries.

## Requirements

### Requirement: Offline Regex Crisis Interception
The system SHALL continuously inspect user text inputs against offline regex patterns for self-harm or suicidal ideation.

#### Scenario: Keyword match triggered
- GIVEN the user enters text containing distress keywords
- WHEN the safety interceptor detects the regex match
- THEN the active session is paused, and a non-dismissible Safety Support Bottom Sheet is presented.

### Requirement: Direct Tunisian Emergency Helplines
The safety modal and Tools screen SHALL display callable buttons for official Tunisian emergency hotlines:
1. Tunisian Ligne Verte: `80 10 50 50` (Toll-Free 24/7)
2. SAMU (Emergency Medical): `190`
3. Protection Civile (Rescue): `198`

#### Scenario: User initiates emergency call
- GIVEN the user is on the Crisis Helpline Hub
- WHEN they tap "Call 80 10 50 50"
- THEN the device opens the system dialer with the hotline number.

### Requirement: Strictly Forbidden Clinical Boundaries
The system SHALL NOT generate, store, suggest, or facilitate:
1. Diet plans, calorie targets, or weight advice;
2. Relapse predictions or psychiatric prognostic scoring;
3. Calling any feature "CBT treatment" or "therapy" (system terminology MUST strictly state "inspired by CBT");
4. Copying text from other apps or books;
5. Emojis in any user-facing widget, button, bottom sheet, or badge.
