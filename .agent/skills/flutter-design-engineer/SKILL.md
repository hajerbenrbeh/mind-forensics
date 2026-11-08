---
name: flutter-design-engineer
description: End-to-end Flutter design engineering uniting product UI/UX design, design token architecture, component craft, responsive layout, motion, accessibility, and visual QA verification. Use when designing, building, or refining production Flutter screens, widgets, design systems, and interactions.
---

# Flutter Design Engineer

Bridge the gap between product design, clinical/domain intent, and robust Flutter engineering. Implement beautiful, responsive, accessible, and high-performance Flutter interfaces grounded in the project's design system tokens and clinical directives.

## Core Pillars

1. **Design System & Token Discipline:**
   - Always leverage project-native tokens (`MindTokens`, `LabTheme`, `LabColors`) rather than hardcoded hex colors or arbitrary margins.
   - Enforce consistent geometry (e.g. 20px card radii, pill-shaped action buttons).
   - Maintain strict dual-theme coherence across Daylight (light) and Night (dark) palettes.

2. **Typography & Spatial Hierarchy:**
   - Bundled typefaces only (Inter) across all weights (400 Regular, 500 Medium, 600 SemiBold, 700 Bold, 800 ExtraBold).
   - Zero remote font fetching dependencies.
   - Proportional line heights, comfortable reading metrics (13–15px body, 20–28px headers), and optical alignment.

3. **Layout & Responsive Constraints:**
   - Prevent RenderFlex overflows proactively.
   - Constrain row children inside `Wrap` or flex layouts using `Flexible` or `Expanded`.
   - Support compact, phone, and tablet viewports gracefully without clipping.

4. **Accessibility (a11y) & Localization:**
   - Minimum 48x48 tap targets for all interactive touch points.
   - Trilingual localization (EN, FR, AR) via `appStringsProvider`.
   - Authentic RTL support and semantic directional padding (`EdgeInsetsDirectional`).
   - High-contrast text readability conforming to WCAG AA/AAA standards.

5. **Data Integrity & Calibrated States:**
   - Never invent or fabricate user metrics or fake psychological charts.
   - Render authentic empty states ("Calibrating baseline", "No entries yet") when records are insufficient.
   - Connect all tracking components directly to central state controllers (`MindTraceController`, `ProfileController`).

6. **Visual QA & Proof of Execution:**
   - Verify every UI change with rendered screenshots.
   - Always validate with `flutter analyze --no-pub` and `flutter test`.

