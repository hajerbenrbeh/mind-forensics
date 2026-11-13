# Mind Forensics — Store-Mastery Product, UI/UX & Engineering Master Plan

> **How to Use This Plan (Especially in a Brand-New Conversation):**  
> This document is the single complete source of truth for **Mind Forensics v1.0 -> Market Launch**. Every file path, widget class, visual flaw, color hex, typography rule, micro-interaction timing, safety check, and acceptance test below was verified directly against the repository and rendered visual QA screenshots (`01`–`08`).  
> Before writing code in any step, read:
> 1. [`AGENTS.md`](../AGENTS.md)
> 2. [`.agent/skills/mind-forensics/SKILL.md`](../.agent/skills/mind-forensics/SKILL.md)
> 3. [`.agent/skills/flutter-design-engineer/SKILL.md`](../.agent/skills/flutter-design-engineer/SKILL.md)
> 4. [`.agent/skills/flutter-motion/SKILL.md`](../.agent/skills/flutter-motion/SKILL.md)

---

## 1. Strategic Store Thesis & Psychological Differentiation

### 1.1 Why Most Mental Health Apps Fail After Day 3
| Failure Mode in Store Competitors | How Mind Forensics Wins |
| :--- | :--- |
| **Static Diaries (Daylio / Apple Journal):** Require daily willpower to type notes; offer no calming intervention when distress spikes. | **Active 10-Second Loop:** Tap 1 mood -> slide intensity -> immediately see optional **Breathing Reset**, **Thought Reframe**, or **AI Guide** in 1 tap. |
| **Paywalled / Scripted English Chatbots (Wysa / Woebot):** Repetitive bot templates, English-only bias, aggressive Day-2 paywalls. | **Natural Trilingual Empathy (`EN / FR / Tunisian AR`):** Built-in Tunisian dialect support, local crisis lines (`80 10 50 50`, `190`, `198`), offline-first encrypted vault, and Groq/Gemini text intelligence. |
| **Guilt-Based Gamification (Streaks / Scores):** Missing one day breaks streaks and triggers avoidance/uninstalls during low-mood dips. | **Non-Punitive Continuity:** Celebrates *"Days Observed"* cleanly without shaming gaps or reducing humans to recovery percentages. |
| **Wall-of-Text Onboarding & Academic Jargon:** Terms like *"Hyperaroused"*, *"Dorsal Vagal"*, or *"Epistemic Triage"* overwhelm tired minds. | **Affect Labeling + 1-Tap Clarity:** Translates evidence-based cognitive defusion into human choices: **`Fact`** vs **`Guess`** vs **`Story`**, always **Options-First**. |

### 1.2 Store Market Non-Negotiables ([`AGENTS.md`](../AGENTS.md))
- **0 emojis in UI** (strictly vector `Icons.*` and clean custom painters across all widgets, sheets, pills, and badges).
- **Forbidden:** Diet plans, calorie targets, weight advice, relapse prediction, calling anything `"CBT treatment"` / `"therapy"` (use **`"CBT-inspired"`** or **`"reflective self-care"`**), or copying external app/book text.
- **Clinical & Privacy Boundaries:** Never impersonate a licensed physician or diagnose. Keep offline crisis regex detection (`crisis_keywords.dart`, `safety_interceptor.dart`) active on every free-text field.
- **Cost & API Gate (Pre-Launch Rule #1):** Default safely to `MockInvestigatorService` (`$0`) or private user keys; before real personal users use cloud AI, migrate from free tiers (where prompts may be logged/used for model improvement) to a **paid tier with billing caps and budget alerts** (explicitly re-verify at Steps 10 & 14 / Pre-Launch).

---

## 2. Visual Audit of Current App (Observed Real Defects to Fix)

Inspecting rendered screenshots (`contact_sheet.png`, `01`–`08`) and core widget files surfaced **9 exact defects**:

1. **Unbundled `'serif'` / `'monospace'` Fallback Boxes (`04`, `05`, `06`, `07`, `08`) — FIXED IN STEP 4:**  
   `LabTheme.serifStyle()`, `LabTheme.editorialSerif()`, `LabTheme.monoStyle()`, and screens specifying `fontFamily: 'serif'` fell back to missing glyph boxes (`Ahem`) because `Inter` is the bundled asset font in `pubspec.yaml`.
2. **Jargon & Horizontal Overflow Inside `HomeDailyCheckInCard` (`01`, `02`, `03`) — FIXED IN STEP 4:**  
   Replaced `NeuralWaveformVisualizer` (`"NERVOUS ACTIVATION"`), jargon labels (`Regulated | Hyperaroused | Reactive | Dorsal Vagal`), raw hex colors, and clipped horizontal scrolling pills with wrapped plain human mood chips (`Calm`, `Anxious`, `Frustrated`, `Heavy`, `Restless`), plain `Intensity`, and `VIEW` -> `/track`.
3. **Clipped Catalyst Pills in `HomeScreen` (`01`–`03`) — FIXED IN STEP 4:**  
   Wrapped concise catalyst pills (`Unanswered text`, `Work feedback`, `Mental overload`) inside `Wrap` with `48dp` `MindPressable` targets.
4. **Cartoonish Face Icon in Breathing Card (`home_organic_exercise_art.dart`) — FIXED IN STEP 4:**  
   Replaced spiral eyes and straight mouth line with layered botanical concentric wave rings matching `LabColors`.
5. **Triple-Redundant Navigation on `TrackScreen` (`04_mood_tracking.png`) — SCHEDULED FOR STEP 6:**  
   Consolidate `Quick Check-in | Detailed Trace | Trace History` into 2 clear tabs: **`Check-In Today`** | **`History & Calendar`**.
6. **Hidden Modes & Tiny Badge in `FlashCaseScreen` / `AI Guide` (`05_ai_companion.png`) — SCHEDULED FOR STEP 7:**  
   Put a tappable **Mode Selector Pill** + visible **AI Engine Status** in the header, and add a **Warm Welcome Card + 3 Starter Taps** at the top of blank sessions.
7. **Zero-Delta Robotic Copy in `InsightsScreen` (`06_insights_progress.png`) — SCHEDULED FOR STEP 8:**  
   Fix `"-0.0 points from baseline"` / `"up by 0.0h"` copy and refine `SmoothSplineChart` axis/tooltip placement.
8. **Exhausting 8-Step Onboarding (`08_main_navigation.png`, `2,278` lines) — SCHEDULED FOR STEP 5:**  
   Compress to a **4-step, <45-second Flo-style onboarding** where Step 4 records the user's first check-in directly into Home.
9. **Hardcoded Hex Colors Leaking Outside Tokens — FIXED FOR HOME/THEME/PROGRESS IN STEP 4:**  
   Eliminate raw `Color(0xFF...)` constants across feature widgets in favor of `context.tokens.*` and `LabColors.*`.

---

## 3. Color & Typography Mastery: Strict **2 Combo + 1 Accent** System (`60-30-10`)

Users in anxious, depressed, or burnt-out states experience visual hypersensitivity. Every pixel adheres strictly to **two harmonious neutral tones + one calming botanical accent**, with **one strictly isolated safety warmth color**:

### 3.1 Exact 60 / 30 / 10 Color Palette Contract (WCAG AA >= 4.5:1 Verified)
| Proportion & Semantic Role | Daylight (`Warm Linen`) | Night (`Soft Obsidian Slate`) | Strict Enforcement Rule |
| :--- | :--- | :--- | :--- |
| **60% Base Canvas** (`tokens.background`) | `#F7F5F0` Warm Ivory | `#121614` Slate Obsidian | Never `#000000` (causes OLED black smear & text halation) or stark `#FFFFFF` background glare. |
| **30% Structural Surfaces** (`tokens.surface`, `surfaceSecondary`, `border`) | `#FFFFFF` Lifted Card<br>`#EDE9E0` Inset Well<br>`#E5E0D6` 1px Border | `#1A211E` Card Surface<br>`#232C28` Inset Well<br>`#2B3631` 1px Border | Separation via hairline `1.0px` border + tonal shift. Zero heavy drop shadows, zero nested gradient cards. |
| **10% Single Hero Accent** (`tokens.accent`, `accentSoft`) | `#3B5242` Mineral Forest<br>`#E8EFEA` Soft Sage Tint | `#8EB19B` Botanical Sage<br>`#213028` Deep Moss Tint | Primary CTA fill, active tab pill, focus ring, selected mood ring, chart curve. **Max 1 primary CTA per viewport.** |
| **Text Contrast Tokens (WCAG >= 4.5:1)** | `#1F2420` Ink<br>`#535C55` Muted Slate (`5.7:1+`)<br>`#5D665F` Tertiary (`4.9:1+`) | `#EFF2EE` Warm Chalk<br>`#9CA9A0` Muted Sage (`5.8:1+`)<br>`#8D9B91` Tertiary (`4.9:1+`) | Verified across canvas, card surfaces, and secondary inset wells (`step_4_design_hygiene_test.dart`). |
| **Isolated Safety Accent** (`tokens.safetyWarmth`, `safetyWarmthSoft`) | `#B34624` Terracotta Clay (`5.04:1`)<br>`#FDF3EE` Tint | `#E58363` Terracotta Ember (`6.06:1`)<br>`#2B1C17` Tint | **ONLY** used on `SupportButton`, Crisis Pause dialogs, and Emergency Hotline rows. Never decorative. |
| **Data-Only Desaturated State Tints** | Moods: Sage `#8EB19B`, Sand `#D4976A`, Amber `#E5A93C`, Iris `#9B8CE0`, Sky `#5FA8D3` | Same muted hues with darkened surface wells | **Always paired with icon + text label.** Never convey meaning by color alone. |

### 3.2 Typography & Layout Rhythm (`Inter` Only — Zero Missing Font Fallback)
| Role | Size / Weight | Line Height (`height`) | Usage |
| :--- | :--- | :--- | :--- |
| **Screen Greeting / Hero** | `22px` `FontWeight.w700` | `1.25` (`-0.3` tracking) | Home greeting, Onboarding step question |
| **Section Overline** | `11.5px`–`12px` `FontWeight.w700` | `1.3` (`+0.6` tracking) | `"ALL FEATURES"`, `"RECENT SESSIONS"` — never smaller than `11.5px` |
| **Card Title** | `15px`–`16px` `FontWeight.w700` | `1.3` | Feature card titles, check-in prompt |
| **Body & AI Dialogue** | `14px`–`15px` `FontWeight.w400` | **`1.5`–`1.6`** | Chat bubbles, summaries, instructions (wide line height reduces anxiety/eye strain) |
| **Interactive Chip / Button** | `13px`–`14px` `FontWeight.w600` | `1.25` | Minimum height **`48px`** for every button/chip/tile |

- **Spacing Grid (`8px` Base):** Horizontal screen margin `20px`; card internal padding `16px–18px`; gap between cards `16px–18px`; minimum interactive tap size **`48 × 48dp`**.

---

## 4. Nervous-System Motion, Soundless Pacing & Haptic Grammar

Motion exists solely to communicate **causality, continuity, hierarchy, or physiological calm** (`transform` & `opacity` only; all durations honor `MediaQuery.disableAnimationsOf(context)` -> `Duration.zero`).

1. **Micro-Tactile Press (`MindPressable`):** `AnimatedScale(0.975)` + `AnimatedOpacity(0.88)` over **`110ms`** (`Curves.easeOutCubic`) + `HapticFeedback.selectionClick()`.
2. **Guided 4-4-4-4 Breathing Ring (`VagalBreathingVisualizer`):** Continuous sine pacing (`4000ms` per phase, `Curves.easeInOutSine`) + `HapticFeedback.lightImpact()` at phase transitions.
3. **Progressive Disclosure (`Add context`, Coping Expanders):** `AnimatedSize` (`220ms`, `Curves.easeOutCubic`, `alignment: Alignment.topCenter`).
4. **Emotion Intensity Slider & Core Selection:** Discrete `1..10` snap feedback + `160ms` selection border transition.
5. **Check-In Save Reward:** Calm non-blocking confirmation card + `HapticFeedback.mediumImpact()`.
6. **AI Companion Pacing:** `280ms` scroll-to-bottom, calm `900ms` fade breath indicator, `200ms` staggered reply entry.

---

## 5. Complete Information Architecture & Flo-Style Consolidation Map

### 5.1 5 Bottom Tabs (`ScaffoldWithNavBar`) + Root Utilities
| Slot | Tab Label (EN / FR / AR) | Screen & Route | User Mental Model ("Why I Tap Here") |
| :--- | :--- | :--- | :--- |
| **0** | `Home` / `Accueil` / `الرئيسية` | `HomeScreen` (`/home`) | **Today:** Quick check-in, see all features in 1 tap, resume today's reflection or breathe. |
| **1** | `Track` / `Suivi` / `التتبع` | `TrackScreen` (`/track`) | **Log & Calendar:** Record how I feel with optional context, browse Calendar dots & past entries. |
| **2 (Hero Center)** | `AI Guide` / `Assistant` / `المساعد` | `FlashCaseScreen` (`/companion`) | **Talk & Untangle:** Guided 1-on-1 reflection with AI Psychological Specialist + past sessions. |
| **3** | `Insights` / `Analyses` / `التحليلات` | `InsightsScreen` (`/insights`) | **Patterns & Report:** Mood curve, real baseline patterns, exportable summary for therapist/doctor. |
| **4** | `Profile` / `Profil` / `ملفي` | `SettingsScreen` (`/profile`) | **Me & Privacy:** Goals, theme, EN/FR/AR, AI engine (`Local`/`Groq`/`Gemini`), PIN/biometric lock, hotlines. |

### 5.2 Retiring Stranded / Overlapping Screens Cleanly
| Current Fragmented Routes | Action in Roadmap | Preserved Route Compatibility |
| :--- | :--- | :--- |
| `TrackScreen` + `MindTraceScreen` + `ProgressScreen` | **Unify logging & timeline inside Tab 1 (`TrackScreen`)** (`Check-In Today` \| `History & Calendar` tabs + embedded month mood calendar). Keep `ProgressScreen` (`/progress`) focused cleanly as **Full Calendar & Deep Analytics**. | `/mind-trace` and `/check-in` smoothly route to `/track`. |
| `InnerObservatoryScreen` + `ToolsScreen` + `JourneyScreen` + `ContextualSupportSheet` | **Unify all tools into `Self-Care Tools` (`InnerObservatoryScreen`, `/observatory`)** integrating interactive `[Fact]`/`[Guess]` drills from `ToolsScreen` inside Tool 1 (`Reframe Thought`). | `/toolkit`, `/tools`, `/observatory` land cleanly in `Self-Care Tools`. |

---

## 6. Screen-by-Screen & Button-by-Button UX Specification (Screens 0–6)

- **Screen 0 — 4-Step Fast Onboarding (`OnboardingScreen`, `/onboarding`):** `Language & Privacy Promise` -> `Goals (1–3 options)` -> `Comfort & Safety Check` -> `First Check-In` saved directly into Home (`< 45s`, `Skip` supported cleanly).
- **Screen 1 — Home / Today (`HomeScreen`, Tab 0, `/home`):** Greeting + Calendar/Support/Profile circular actions -> `HomeDailyCheckInCard` -> `ALL FEATURES` 2×2 grid (`AI Guide`, `Self-Care Tools`, `Calendar & Log`, `Insights & Export`) -> `Continue/Start Reflection` + wrapped 3 catalyst pills -> `Quick 5-Min Reset` (`HomeOrganicExerciseArt`) -> `Recent Sessions` (max 2).
- **Screen 2 — Track (`TrackScreen`, Tab 1, `/track`):** 2 tabs (`Check-In Today` | `History & Calendar`) + embedded month mood calendar + optional collapsed `Add context (optional)` + `Prefer step-by-step check-in?` drawer.
- **Screen 3 — AI Guide (`FlashCaseScreen`, Tab 2 Center, `/companion`):** `AI Guide` header + tappable **Mode Pill** (`6 modes` sheet) + tappable **Engine Badge** (`Local`/`Groq`/`Gemini`) + **Warm Welcome Card + 3 Starters** + `[Fact]`/`[Guess]`/`[Story]` chips + Suggested Replies + Level 2 Crisis Interception.
- **Screen 4 — Self-Care Tools (`InnerObservatoryScreen`, `/observatory` & `/toolkit`):** Quick Calm banner + 2×2 wrapped tools (`Reframe Thought` with interactive `[Fact]`/`[Guess]` drills, `Coping Steps`, `Saved Notes`, `Body & Mind`).
- **Screen 5 — Insights (`InsightsScreen`, Tab 3, `/insights`):** `1W|1M|3M|6M` + `Tools` filter strip -> `SmoothSplineChart` -> `Patterns & Rolling Baseline` (clean baseline phrasing, zero `-0.0` deltas) -> `Weekly Summary & Therapist Export`.
- **Screen 6 — Profile & Privacy (`SettingsScreen`, Tab 4, `/profile`):** `You & Wellness Focus`, `Display & Language`, `AI Guide & Security`, `Data & Crisis Support` (`80 10 50 50`, `190`, `198`).

---

## 7. Verification Gates & Execution Roadmap (Steps 4–9)

### Mandatory Git & PR Workflow After Every Step
1. Remote `upstream` -> `https://github.com/hajerbenrbeh/mind-forensics.git`.
2. Work on a dedicated branch per step (`git checkout -b feat/step-<N>-<slug>`).
3. Run verification gates before every commit:
   ```powershell
   flutter analyze --no-pub
   flutter test
   ```
4. Push branch to `origin` (`git push -u origin feat/step-<N>-<slug>`) and open Pull Request against `hajerbenrbeh/mind-forensics:main`.

- **Step 4 [COMPLETED]:** Design Token Hygiene (`>= 4.5:1` AA across all surfaces), 100% bundled `'Inter'` typography (0 missing-glyph `'serif'`/`'monospace'` calls), `MindPressable` (`110ms` scale+opacity+haptic), wrapped `HomeDailyCheckInCard` + catalyst pills, serene `HomeOrganicExerciseArt`, and `step_4_design_hygiene_test.dart`.
- **Step 5 [NEXT]:** 4-Step Fast Onboarding & Zero-Blank-Screen Handoff (`onboarding_screen.dart`).
- **Step 6:** Consolidate `Track` (`Check-In Today` + `History & Calendar` tabs + embedded month calendar).
- **Step 7:** `AI Guide` Header Clarity, Mode Selector Pill, Engine Badge & Zero-Blank-Screen Welcome Starters.
- **Step 8:** Unify `Self-Care Tools` Drills, Fix Insights Delta Copy & Group Profile Settings.
- **Step 9:** Full Visual QA Sheet Regeneration, Store APK Verification & `AGENTS.md` Rule #1 Paid-Tier Gate.

---

## New Conversation Execution Prompt (Zero-Loss Handoff)
> *"Read `agent/MASTER_PLAN.md` and `AGENTS.md`. Tell me briefly which files the next pending Step touches, implement it cleanly on `feat/step-<N>-<slug>`, verify with `flutter analyze --no-pub` and `flutter test`, push the branch to `origin`, and give me the Pull Request link to `hajerbenrbeh/mind-forensics:main`."*

