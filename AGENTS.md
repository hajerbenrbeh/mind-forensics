# Mind Forensics — Agent Instructions & Operational Standard

Welcome to the **Mind Forensics** codebase. This file provides immediate operational rules and reference points for any AI agent pair programming on this repository.

---

## 📌 Critical Reference Files
- **Autonomous Agent Master Guide:** [`agent/PROJECT_GUIDE.md`](file:///c:/Users/HAJER/Desktop/mind%20forensics/agent/PROJECT_GUIDE.md)
- **OpenSpec Configuration & Specs:** [`openspec/config.yaml`](file:///c:/Users/HAJER/Desktop/mind%20forensics/openspec/config.yaml), [`openspec/specs/`](file:///c:/Users/HAJER/Desktop/mind%20forensics/openspec/specs/)
- **OpenSpec SDD Skill:** [`.agent/skills/openspec/SKILL.md`](file:///c:/Users/HAJER/Desktop/mind%20forensics/.agent/skills/openspec/SKILL.md)
- **Mind Forensics Skill:** [`.agent/skills/mind-forensics/SKILL.md`](file:///c:/Users/HAJER/Desktop/mind%20forensics/.agent/skills/mind-forensics/SKILL.md)
- **Palette & Tokens:** [`lib/app/theme/lab_colors.dart`](file:///c:/Users/HAJER/Desktop/mind%20forensics/lib/app/theme/lab_colors.dart)
- **Localization Dictionary:** [`lib/app/localization/app_strings.dart`](file:///c:/Users/HAJER/Desktop/mind%20forensics/lib/app/localization/app_strings.dart)
- **Safety Interceptor:** [`lib/core/safety/safety_interceptor.dart`](file:///c:/Users/HAJER/Desktop/mind%20forensics/lib/core/safety/safety_interceptor.dart)
- **Investigation Controller:** [`lib/features/investigation/controllers/investigation_providers.dart`](file:///c:/Users/HAJER/Desktop/mind%20forensics/lib/features/investigation/controllers/investigation_providers.dart)

---

## ⚠️ Non-Negotiable Directives

1. **COST AND DATA RULES:**
   - Develop entirely on the free Firebase Spark plan, with billing NOT linked.
   - Use the Gemini free tier ONLY with fictional test text, never with real personal data.
   - Default to the fake "test mode" in `AiService` (`MockAiService`).
   - The Gemini free tier lets Google use submitted content to improve its products and allows human review. Therefore, before ANY real user, the project must move to the paid tier (billing linked), with budget alerts and spend caps.
   - Remind the user of this at **Steps 10 and 14**, and check CURRENT official pricing and data terms then.

2. **BOTTOM TABS & NAVIGATION ARCHITECTURE:**
   - Bottom tabs: `Home`, `Journal`, `Investigator`, `Toolkit (placeholder in v1)`, `Profile`.
   - `Insights` lives inside Home until v2.

3. **STEP 6 SPECIFICATION (Daily Check-in):**
   - 6. Daily check-in with a daily note: emotion (from an emotion library), self-reported intensity 1-10, optional free-text "today's note", and a simple Home (check-in card, last mood, open cases, recent entries).

4. **LATER FEATURES (Section 6 — do NOT build now):**
   - **Toolkit (v2):** short mindfulness and relaxation exercises (with a "stop anytime" option), sleep hygiene tips and a self-reported sleep diary, an activity planner based on behavioral activation, and an emotion library.
   - **CBT-inspired tools and Resilience Plan (v2.5):** a distortion explorer, behavioral experiments, a problem-solving flow, and a user-written Resilience Plan ("My Plan": early warning signs, what helps, who to contact), shareable with a therapist only by the user's choice. The AI may help organize it but must NEVER predict relapse or judge the person.
   - **Paths (v3):** multi-week guided programs where the AI adapts pacing and reflection questions. Content is written as placeholder drafts and must be reviewed by a professional before release.

5. **🚫 STRICTLY FORBIDDEN LIST:**
   - Diet plans, calorie targets, or weight advice;
   - Predicting relapse;
   - Calling anything "CBT treatment" or "therapy" (use "inspired by CBT");
   - Copying text from other apps or books;
   - NO EMOJIS IN UI (Widgets, buttons, bottom sheets, badges).

6. **LUXURY VERCEL DARK PALETTE:**
   - Ground level background: `#000000` (Pure pitch black).
   - Surface level 1: `#0A0A0A` with 1.0px hairline borders (`#222222`).
   - Secondary accents: Cherry Red (`#E11D48`), Warm Beige (`#E7D8C9`), Sage Green (`#34D399`).
   - Primary action buttons: Stark white background (`#FFFFFF`) with black text (`#000000`).
   - Corner radii: Strict `8.0px`–`10.0px`.

7. **TRILINGUAL LOCALIZATION (AR / FR / EN):**
   - Every user-facing string must be referenced via `ref.watch(appStringsProvider)` from `app_strings.dart`.
   - Arabic translations (`ar`) must use authentic Tunisian dialectal phrasing where natural, supported by proper RTL text directionality.

8. **SAFETY & CRISIS INTERCEPTION:**
   - Never disable or bypass the offline regex keyword detector in `crisis_keywords.dart` or `safety_interceptor.dart`.
   - Ensure emergency crisis hotlines (Tunisian Ligne Verte `80 10 50 50`, SAMU `190`, Protection Civile `198`) remain intact and callable.

9. **DATA PERSISTENCE & HYDRATION:**
   - Active investigations must remain fully hydrated across page transitions and application reboots via `LocalCaseRepository` and `_hydrateFields()`.
   - Changes to the forensic model must be serialized in `CaseModel.toJson()` and `CaseModel.fromJson()`.

10. **ZERO RUNTIME REGRESSIONS:**
    - Before finishing any turn, run:
      ```powershell
      flutter analyze --no-pub
      flutter test
      ```
    - Both commands must pass with zero issues.
