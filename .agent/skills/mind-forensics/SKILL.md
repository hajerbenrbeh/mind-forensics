---
name: mind-forensics
description: Comprehensive architecture, clinical guidelines, Vercel dark styling, and development runbook for the Mind Forensics mobile application. Use whenever reading or modifying screens, cognitive workflows, translations (EN, FR, AR), or safety interceptors.
---

# Mind Forensics Agent Skill — Neuro-Cognitive Deconstruction

This skill defines the technical and clinical architecture of the **Mind Forensics** application. Any autonomous agent working on this codebase MUST follow these operational guidelines.

---

## 1. Quick Technical Blueprint

| Layer | Implementation | Key Files |
| :--- | :--- | :--- |
| **Framework** | Flutter 3.x / Dart 3.x | `pubspec.yaml` |
| **State Management** | `flutter_riverpod: ^2.5.1` | `lib/features/investigation/controllers/investigation_providers.dart` |
| **Navigation** | `go_router: ^14.2.0` | `lib/app/router/app_router.dart`, `scaffold_with_nav_bar.dart` |
| **Persistence** | `shared_preferences: ^2.2.3` | `lib/features/investigation/data/local_case_repository.dart` |
| **Theme / Design** | Vercel Luxury Dark & Minimalist | `lib/app/theme/lab_colors.dart`, `lab_theme.dart` |
| **Localization** | Trilingual Medical (EN, FR, Tunisian AR) | `lib/app/localization/app_strings.dart` |
| **Safety Engine** | Dual-Layer Keyword & Triage | `lib/core/safety/safety_interceptor.dart`, `crisis_keywords.dart` |

---

## 2. Cost and Data Rules & Boundaries

* **Spark Plan Discipline:** Develop entirely on the free Firebase Spark plan, with billing NOT linked.
* **Gemini Free Tier Restriction:** Use the Gemini free tier ONLY with fictional test text, never with real personal data.
* **Default Fake Mode:** Default to the fake "test mode" in `AiService` (`MockAiService`).
* **Paid Tier Prerequisite:** The Gemini free tier allows human review and content training. Before ANY real user, the project must move to the paid tier (billing linked) with budget alerts and spend caps. Remind at **Steps 10 and 14**, checking current pricing and terms then.

---

## 3. Navigation & Screen Taxonomy

* **Bottom Tabs:** `Home`, `Journal`, `Investigator`, `Toolkit (placeholder in v1)`, `Profile`.
* **Insights:** Lives inside `Home` until v2.
* **Step 6 (Daily Check-in):** Emotion (from emotion library), self-reported intensity 1-10, optional free-text "today's note", and a simple Home (check-in card, last mood, open cases, recent entries).

---

## 4. Later Features (do NOT build now)

* **Toolkit (v2):** Short mindfulness and relaxation exercises (with a "stop anytime" option), sleep hygiene tips and a self-reported sleep diary, an activity planner based on behavioral activation, and an emotion library.
* **CBT-inspired tools and Resilience Plan (v2.5):** A distortion explorer, behavioral experiments, a problem-solving flow, and a user-written Resilience Plan ("My Plan": early warning signs, what helps, who to contact), shareable with a therapist only by the user's choice. The AI may help organize it but must NEVER predict relapse or judge the person.
* **Paths (v3):** Multi-week guided programs where the AI adapts pacing and reflection questions. Content is written as placeholder drafts and must be reviewed by a professional before release.

---

## 5. 🚫 Strictly Forbidden List

1. **Diet plans, calorie targets, or weight advice;**
2. **Predicting relapse;**
3. **Calling anything "CBT treatment" or "therapy" (use "inspired by CBT");**
4. **Copying text from other apps or books;**
5. **Emojis in UI:** Strictly prohibited across widgets, buttons, bottom sheets, and badges.

---

## 6. Global Low-Cognitive-Load & Options-First Principle

* **Core Mandate:** The product must be **OPTIONS-FIRST, not QUESTION-FIRST**. Using the application must never feel like another mental chore.
* **Options Before Open Questions:** Present selectable choices first (3–6 clear options: emotion cards, situation chips, suggested replies, sliders).
* **No Compulsory Blank Text Fields:** Free text is always optional ("Something else", "Add your own", "I prefer to explain", "Skip for now"). Never make an unexplained blank text box the default path.
* **Progressive Interaction & Cognitive Limit:** One decision at a time; simple language; never penalize incomplete or skipped interactions.
* **Intelligent Suggestions:** Suggestions may be presented from context, but never auto-submitted or presumed true without explicit confirmation.
* **AI Companion Interaction:** Not an interrogator; never stack questions; offer quick suggested responses; allow brief replies; respect conversational boundaries.
* **Safety Non-Compromise:** Crisis and safety queries remain direct, clear, and unambiguous—never oversimplified into vague multiple-choice options.

---

## 7. Verification Commands

Always run both commands after making code changes:
```powershell
flutter analyze --no-pub
flutter test
```
Ensure zero analyzer errors and 100% test pass rate before declaring any task complete.
