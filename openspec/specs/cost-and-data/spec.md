# Capability: Cost and Data Rules

## Overview
Mind Forensics enforces strict operational cost boundaries and data privacy safeguards during development, staging, and production rollouts.

## Requirements

### Requirement: Free Development Environment
The application SHALL be developed entirely on the free Firebase Spark plan, with billing NOT linked.

#### Scenario: Running during development
- GIVEN the developer or automated agent is executing development tasks
- WHEN Firebase services are initialized
- THEN the system remains strictly within the unbilled Spark free tier.

### Requirement: Fictional Test Data Restriction on Gemini Free Tier
The system SHALL use the Gemini free tier ONLY with fictional test text, never with real personal data.

#### Scenario: Free tier AI invocation
- GIVEN the application is operating in free tier mode
- WHEN AI analysis is executed
- THEN only fictional test scenarios and synthetic text may be submitted to the model.

### Requirement: Default Test Mode in AiService
The system SHALL default to the fake "test mode" in `AiService` (`MockAiService`) across all providers and test runners.

#### Scenario: Out-of-the-box operation
- GIVEN the app is launched fresh or run in unit tests
- WHEN `aiServiceProvider` is read
- THEN `MockAiService` is injected, incurring $0.00 cost and zero network data transmission.

### Requirement: Mandatory Paid Tier Migration Before Real Users
Because the Gemini free tier permits Google to use submitted content to improve products and allows human review, the project MUST move to the paid tier (billing linked) with budget alerts and spend caps before ANY real user touches the application.

#### Scenario: Step 10 and Step 14 reminders
- GIVEN the project reaches Step 10 or Step 14
- WHEN planning or engineering instructions are reviewed
- THEN the system SHALL explicitly remind the team of the paid tier requirement, budget alerts, spend caps, and check CURRENT official pricing and data terms.

