# Mind Forensics — Autonomous Agent & Engineering Master Guide

> **Project Identity:** *Mind Forensics* is an evidence-based cognitive forensic mental wellness mobile application built in Flutter and Dart. It transitions users from passive emotional validation to rigorous, collaborative forensic deconstruction of automatic negative thoughts and cognitive distortions.

---

## 1. System Vision & Core Clinical Philosophy

Traditional mental health applications often fall into the **validation trap**: validating irrational catastrophic assumptions without examining the underlying evidence, inadvertently reinforcing cognitive distortions.

Mind Forensics treats every emotional disturbance as a **Forensic Case**:
1. **Incident (The Crime Scene):** What objectively happened in the physical environment?
2. **Evidence Chain:** Splitting internal experience into four distinct components:
   - **Trigger:** Environmental stimulus or internal physical sensation.
   - **Automatic Thought:** The instantaneous mental assertion.
   - **Emotion:** Primary affect (anxiety, shame, anger, despair) with intensity rating (1–10).
   - **Behavior:** The action taken or impulse generated (avoidance, defensiveness, confrontation).
3. **Epistemic Classification (Triage):**
   - `Fact`: Verifiable in the physical world by a camera or third-party observer.
   - `Assumption`: Unverified prediction or belief without definitive proof.
   - `Interpretation`: Subjective narrative or emotional projection disguised as truth.
4. **Warm Investigator Persona:**
   - Sharp, compassionate, forensic, and non-judgmental.
   - Never gaslights; never offers empty toxic positivity.
   - Formulates alternative hypotheses to explain the evidence without personalizing guilt.
5. **Cross-Examination:**
   - Stress-tests assumptions against real-world evidence and probability.
6. **Findings & My Conclusion:**
   - Synthesizes findings into actionable cognitive restructuring.
   - User commits their personal verdict to permanent case memory.

---

## 2. Directory Taxonomy & Architecture

Mind Forensics follows a strict feature-first, layered architectural pattern powered by `flutter_riverpod` and `go_router`:

```
lib/
├── main.dart                               # App entry point, ProviderScope initialization
├── app/
│   ├── localization/
│   │   ├── app_strings.dart                # Trilingual dictionary (EN, FR, AR with Tunisian phrasing)
│   │   └── locale_controller.dart          # Riverpod state notifier for dynamic language switching
│   ├── router/
│   │   ├── app_router.dart                 # GoRouter declarations with 5-tab bottom navigation shell
│   │   └── scaffold_with_nav_bar.dart      # Minimalist 62px bottom bar with 5 tabs
│   └── theme/
│       ├── lab_colors.dart                 # Vercel Luxury Dark & Light palette tokens + Secondary Accents
│       ├── lab_theme.dart                  # Material 3 ThemeData with razor borders & radii
│       └── theme_controller.dart           # Riverpod state notifier for Dark/Light mode
├── core/
│   ├── safety/
│   │   ├── crisis_keywords.dart            # Trilingual crisis regex (EN, FR, Tunisian AR)
│   │   ├── safety_interceptor.dart         # Offline Layer 1 + Layer 2 crisis interceptor
│   │   ├── safety_model.dart               # Risk assessment domain model
│   │   └── support_button.dart             # Emergency support bottom sheet with direct dialing
│   ├── security/
│   │   └── daily_usage_limiter.dart        # 20 request/day throttling for API cost control
│   └── widgets/
│       ├── bouncing_widget.dart            # Tactile spring interaction widget
│       ├── slide_to_anchor.dart            # Tactile drag slider for cognitive reframes
│       ├── somatic_body_radar.dart         # Interactive anatomical wireframe scanner
│       ├── vagal_breathing_visualizer.dart # Concentric ripple visualizer
│       └── label_badge.dart                # Minimalist epistemic classification badges
└── features/
    ├── case_file/presentation/             # Completed case viewer & report export
    ├── home/presentation/                  # Executive dashboard, check-in card, last mood, open cases, recent entries
    ├── investigation/                      # Forensic workflow engine
    │   ├── controllers/                    # investigation_providers.dart (StateNotifier & state hydration)
    │   ├── data/                           # local_case_repository.dart & mock_investigator_service.dart
    │   ├── domain/                         # CaseModel, ForensicChain, Hypothesis, AI interfaces
    │   └── presentation/                   # flash_case_screen.dart (6-stage forensic lab)
    ├── journal/presentation/               # Vault / archive of historical cases
    ├── onboarding/presentation/            # Initial psychiatric introduction & mission briefing
    ├── profile/presentation/               # Profile & Settings (Language, Theme, Purge, Safety)
    └── toolkit/presentation/               # Grounding tools & v1 Toolkit placeholder
```

### Bottom Navigation Architecture
**Bottom tabs:** `Home`, `Journal`, `Investigator`, `Toolkit (placeholder in v1)`, `Profile`. `Insights` lives inside Home until v2.

---

## 3. UI/UX Design System: Luxury Vercel Dark & Minimalist Precision

Mind Forensics enforces an elite, modern, distraction-free aesthetic inspired by Vercel, Linear, and luxury developer tooling.

### Palette Tokens (`LabColors`)
* **Background (OLED Black):** `0xFF000000` (Pitch black for battery efficiency and contrast)
* **Surface Level 1 (Card):** `0xFF0A0A0A`
* **Surface Level 2 (Elevated):** `0xFF121212`
* **Hairline Razor Border:** `0xFF222222` (Strictly 1.0px width)
* **Hairline Border High Contrast:** `0xFF333333`
* **Text High Contrast (Stark White):** `0xFFEDEDED`
* **Text Medium Contrast (Muted):** `0xFF888888`
* **Text Low Contrast (Subtle):** `0xFF555555`
* **Primary Interactive Accent:** `0xFFFFFFFF` (Stark white filled buttons with `0xFF000000` text)
* **Secondary Luxury Accents:**
  * **Cherry Red:** `#E11D48` (dark surface `#22080F`, border `#4C1020`) — Neural arousal, urgent catalyst.
  * **Warm Beige / Cashmere:** `#E7D8C9` (dark surface `#1B1713`, border `#382F26`) — Grounded anchor, somatic calm.
  * **Sage Green:** `#34D399` (dark surface `#092419`, border `#134E37`) — Parasympathetic recovery.
* **Epistemic Classifications:**
  * **Fact (Ice Cyan):** `0xFF38BDF8`
  * **Assumption (Warm Gold):** `0xFFFBBF24`
  * **Interpretation (Soft Iris):** `0xFFA78BFA`
* **Safety Alert (Rose Crimson):** `0xFFF43F5E`

---

## 4. Multilingual Engine (Tunisian Arabic, French, English)

Mind Forensics natively supports three locales:
- `en`: English (International forensic clinical standard)
- `fr`: French (Clinical precision standard)
- `ar`: Arabic (Authentic Tunisian dialectal phrasing with formal Arabic clinical rigor, full RTL layout)

---

## 5. Dual-Layer Safety Interceptor & Tunisian Emergency Protocol

The safety system guarantees user protection without sacrificing local privacy:
- **Layer 1: Offline Regex Scanner (`crisis_keywords.dart`)**: Trilingual offline detector for immediate pause on crisis signals.
- **Layer 2: Psychiatric Safe Fallback**: Immediate access to verified Tunisian emergency hotlines:
  * **Tunisian National Suicide Prevention / Mental Health Hotline (Ligne Verte):** `80 10 50 50`
  * **SAMU Urgent Medical Emergency:** `190`
  * **Civil Protection (Protection Civile):** `198`

---

## 6. Cost and Data Rules & Infrastructure

### COST AND DATA RULES
- Develop entirely on the free Firebase Spark plan, with billing NOT linked. Use the Gemini free tier ONLY with fictional test text, never with real personal data. Default to the fake "test mode" in AiService.
- The Gemini free tier lets Google use submitted content to improve its products and allows human review. Therefore, before ANY real user, the project must move to the paid tier (billing linked), with budget alerts and spend caps. Remind me of this at Steps 10 and 14, and check the CURRENT official pricing and data terms then.

### Step 6: Daily Check-in & Dashboard
6. Daily check-in with a daily note: emotion (from an emotion library), self-reported intensity 1-10, optional free-text "today's note", and a simple Home (check-in card, last mood, open cases, recent entries).

### Later Features (do NOT build now)
- **Toolkit (v2):** short mindfulness and relaxation exercises (with a "stop anytime" option), sleep hygiene tips and a self-reported sleep diary, an activity planner based on behavioral activation, and an emotion library.
- **CBT-inspired tools and Resilience Plan (v2.5):** a distortion explorer, behavioral experiments, a problem-solving flow, and a user-written Resilience Plan ("My Plan": early warning signs, what helps, who to contact), shareable with a therapist only by the user's choice. The AI may help organize it but must NEVER predict relapse or judge the person.
- **Paths (v3):** multi-week guided programs where the AI adapts pacing and reflection questions. Content is written as placeholder drafts and must be reviewed by a professional before release.

---

## 7. 🚫 Strictly Forbidden List

The following are strictly banned from the product and all generated code:
1. **Diet plans, calorie targets, or weight advice;**
2. **Predicting relapse;**
3. **Calling anything "CBT treatment" or "therapy" (use "inspired by CBT");**
4. **Copying text from other apps or books;**
5. **Emojis in UI:** Emojis are strictly banned from UI widgets, buttons, bottom sheets, and badges.

---

## 8. Testing & Verification Protocol

Before completing any task, every agent MUST verify code integrity using:
```powershell
flutter analyze --no-pub
flutter test
```
* **Analyzer requirement:** 0 errors, 0 warnings, 0 lints.
* **Test requirement:** 100% test pass rate across all smoke and unit tests.
