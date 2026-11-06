# Mind Forensics

> **Calm, Intelligent Mental Health Companion & Cognitive Self-Awareness Platform**

[![Flutter](https://img.shields.io/badge/Flutter-3.47+-02569B?logo=flutter&logoColor=white)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-3.13+-0175C2?logo=dart&logoColor=white)](https://dart.dev)
[![License: MIT](https://img.shields.io/badge/License-MIT-34D399.svg)](LICENSE)
[![Tests](https://img.shields.io/badge/Tests-124%20Passing-34D399.svg)]()
[![Platform](https://img.shields.io/badge/Platform-iOS%20%7C%20Android%20%7C%20Web%20%7C%20Desktop-black)]()

---

## 🌿 Overview

**Mind Forensics** is a privacy-first psychological self-awareness and management platform engineered for two audiences:
1. Individuals living with diagnosed mental health conditions seeking a structured, objective, non-stigmatizing tracking and reflection companion.
2. Anyone seeking to deconstruct their emotions, recurring thought patterns, stress triggers, and somatic well-being.

The application combines structured self-observation, epistemic cognitive deconstruction, data-driven personal baselines, and a compassionate, context-aware AI companion.

---

## 🎨 Design System: Calm Earth & Botanical Sage

Mind Forensics abandons harsh clinical pitch-black interfaces and cold analytics in favor of an organic, calming, and human visual identity:

* **Daylight Linen Theme:**
  * Background: `#F7F8F5` (Natural parchment linen)
  * Surface: `#FFFFFF` (Crisp elevated card)
  * Secondary Surface: `#E5ECE6` (Muted soft sage)
  * Primary Text: `#34443B` (Deep slate forest green)
  * Accent: `#668274` (Botanical sage)
* **Night Slate Theme:**
  * Background: `#151B19` (Deep slate botanical)
  * Surface: `#202925` (Elevated dark slate)
  * Surface Secondary: `#303E37` (Muted slate container)
  * Primary Text: `#F0F2EC` (Calm ivory)
  * Accent Glow: `#91AD9A` (Interactive sage green glow)
* **Geometry & Form:** Soft `20.0px` card radii, `24.0px–30.0px` time capsule pills, and `16.0px` input contours.
* **Typography:** Locally bundled **Inter** font family (Regular 400, Medium 500, SemiBold 600, Bold 700) with zero runtime network fetching dependencies.
* **Clinical Discipline:** Strict zero-emoji policy across all clinical widgets, badges, buttons, and bottom sheets to maintain emotional dignity and seriousness.

---

## ✨ Core Features

### 1. Home Dashboard & Data-Driven Telemetry
* **Authentic Baseline Engine:** Never fabricates artificial psychological data or fake percentages. Renders an honest calibrating dashed baseline until sufficient real user records exist.
* **Real-time Mood Stability:** Calculates authentic standard deviation across historical check-ins to derive evidence-based stability indicators.
* **Weekly Somatic Rhythm:** Monday-to-Sunday interactive bar charts dynamically derived from recorded telemetry.
* **Step 6 Daily Check-in:** Unified mood picker (1–10 intensity slider, emotion library selection, and optional daily reflection note) synchronized with the central repository.
* **Vagal Breathing Modal:** Integrated 4-4-4-4 box breathing visualizer with real-time breathing phase pacing.

### 2. Forensic Investigation & Epistemic Triage
* **Cognitive Deconstruction:** Differentiates statements into:
  * **Facts:** Objective, verifiable occurrences (`#38BDF8`).
  * **Assumptions:** Presumed motives or unconfirmed predictions (`#FBBF24`).
  * **Interpretations:** Internal meanings or emotional conclusions (`#A78BFA`).
* **Forensic Chains:** Links Trigger $\rightarrow$ Automatic Thought $\rightarrow$ Emotion & Intensity $\rightarrow$ Resulting Behavior.

### 3. Clinical Crisis Safety Interception
* **Offline Regex Safety Interceptor:** Scans input locally in real time without network transmission to immediately intercept acute distress keywords.
* **Emergency Helpline Overlay:** Provides direct, single-tap connection to verified support services:
  * **Tunisia Ligne Verte:** `80 10 50 50`
  * **SAMU:** `190`
  * **Protection Civile:** `198`

### 4. Zero-Friction Privacy & Security
* **Anonymous Local-First Vault:** Fully functional out of the box with zero required account creation or personal data collection.
* **Biometric Lock (`local_auth`):** Device-level fingerprint and Face ID authentication.
* **Clinical Sharing & Data Wipe:** Selective one-tap JSON export of sessions and a full GDPR-compliant data purge.

### 5. Trilingual Accessibility (AR / FR / EN)
* **Tunisian Arabic (`ar`):** Authentic colloquial and dialectal phrasing with comprehensive Right-to-Left (RTL) text directionality.
* **French (`fr`) & English (`en`):** Precise psychological and cognitive terminology.

---

## 🏗 Architecture & Tech Stack

```
lib/
├── app/
│   ├── localization/      # Trilingual strings (EN, FR, AR) & locale controller
│   ├── router/            # GoRouter configuration & bottom tab navigation
│   └── theme/             # Earth/Sage tokens, LabColors, and LabTheme
├── core/
│   ├── safety/            # Offline crisis keywords & safety interceptor
│   ├── security/          # Biometric auth & local daily usage limiter
│   └── widgets/           # BouncingWidget, MindCard, MindButton primitives
└── features/
    ├── auth/              # Anonymous vault & Firebase Spark credentials
    ├── case_file/         # Case models & clinical PDF/JSON export services
    ├── home/              # Home Dashboard, breathing exercise & metrics
    ├── investigation/     # Epistemic triage, AI companion & state controllers
    ├── journal/           # Searchable forensic vault & daily mind traces
    ├── mind_trace/        # Daily check-in controller & local repositories
    ├── profile/           # Psychological profile & conditions tracker
    └── settings/          # Biometrics, sync, language & appearance settings
```

* **Framework:** Flutter 3.47.9 / Dart 3.13.7
* **State Management:** Riverpod 3.4+ (`NotifierProvider`, `ConsumerStatefulWidget`)
* **Navigation:** `go_router` 18.1+
* **Persistence:** `shared_preferences` with in-memory fallback repositories
* **Cloud Infrastructure:** Firebase Spark Plan ($0.00 zero-cost configuration)

---

## 🚀 Getting Started

### Prerequisites
* [Flutter SDK](https://docs.flutter.dev/get-started/install) (version 3.22.0 or higher recommended)
* Android Studio / Xcode / VS Code with Flutter extension
* Git

### Installation

1. **Clone the repository:**
   ```bash
   git clone https://github.com/hajerbenrbeh/mind-forensics.git
   cd mind-forensics
   ```

2. **Install dependencies:**
   ```bash
   flutter pub get
   ```

3. **Verify static analysis:**
   ```bash
   flutter analyze
   ```

4. **Execute the test suite:**
   ```bash
   flutter test
   ```

5. **Run the application:**
   ```bash
   flutter run
   ```

---

## 🧪 Testing & Quality Assurance

The application includes an extensive test suite verifying clinical safety, state persistence, epistemic classification, and UI rendering:

```bash
# Run all 124 unit and widget tests
flutter test

# Run the UI screenshot generator
flutter test test/screenshot_generator_test.dart
```

---

## ⚖️ Clinical & Ethical Disclaimer

**Mind Forensics** is an educational and self-awareness platform inspired by cognitive behavioral principles. It is **not** a licensed medical provider, diagnostic instrument, or a replacement for professional clinical care.

* The application **never** predicts relapse or provides dietary/weight advice.
* In cases of acute psychological crisis or self-harm ideation, the offline safety interceptor immediately directs users to professional human emergency helplines.

---

## 📄 License

This project is licensed under the MIT License — see the [LICENSE](LICENSE) file for details.
