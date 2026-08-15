# LipidCare — Product & Design Specification

A production-quality cholesterol tracking app for Android (Jetpack Compose) and iOS (SwiftUI),
designed after researching the top-rated cholesterol trackers on Google Play and the App Store
(LDL: Cholesterol Tracker, iCholesterol, Cholesterol Heart Tracker, BCMon Pro) and matching or
exceeding their combined feature set.

## Feature map

| Area | Features |
|------|----------|
| Lipid panel logging | Total, LDL, HDL, Triglycerides · fasting flag · notes · date/time · edit/delete · input validation per unit |
| Auto-calculation | Friedewald LDL (flagged, disabled above TG 400 mg/dL) · Non-HDL · VLDL estimate · TC/HDL, LDL/HDL, TG/HDL ratios |
| Risk classification | NCEP ATP III bands, sex-aware HDL thresholds, color-coded everywhere |
| Lipid Score | Composite 0–100 weighted score (LDL 35%, TC 25%, HDL 20%, TG 20%) with animated gauge |
| Units | mg/dL ⇄ mmol/L everywhere (cholesterol 38.67, TG 88.57 factors) |
| Trends | Animated line charts, optimal-zone bands, LDL target guide line, 1M/3M/6M/1Y/All ranges, stats (latest/avg/min/max/change), tap-to-inspect |
| Food diary | FatSecret Platform API (OAuth2) search + barcode scan · offline built-in food DB (70+ foods incl. Indian dishes) · per-serving cholesterol/sat-fat/calories · meal grouping · favorites quick-add · daily cholesterol & sat-fat budgets with progress rings · 7-day bar chart |
| Medications | Meds with dose times, colors, notes · daily dose checklist (taken/skipped) · 7-day adherence ring · reminders |
| Reminders | Daily log reminder · per-dose medication alarms (exact when permitted, reschedule on boot) |
| Insights | Rule-based engine: trend deltas, retest nudges, TG/HDL insulin-resistance flag, diet-vs-budget feedback |
| Learn | 8 in-app articles (lipid panel, ratios, diet, exercise, medication, risk, lab reports, myths) |
| Reports | CSV export + doctor-ready PDF report via share sheet |
| Profile | Name, sex, birth year, risk factors, custom LDL target & diet budgets |
| Polish | Onboarding pager, splash screen, dark mode, edge-to-edge, animations throughout |

## Design system

**Identity**: warm, medical-but-friendly. Heart-crimson primary with teal secondary.

| Token | Light | Notes |
|-------|-------|-------|
| Primary (Crimson) | `#E8425A` | hero gradients `#E8425A → #B23A78 → #B02342` |
| Secondary (Teal) | `#0E9E8D` | HDL identity, positive accents |
| Tertiary (Indigo) | `#6C63FF` | Triglycerides identity, charts |
| Background | `#F8F4F5` | dark: `#161113` |
| Surface | `#FFFBFB` | dark: `#1E181A` |

**Risk colors** (consistent on both platforms):
GOOD `#2EB872` · OK `#7CB342` · WARN `#F5A623` · BAD `#EF6C3A` · SEVERE `#E5484D`

**Metric identity colors**: Total `#E8425A` · LDL `#F2762E` · HDL `#0E9E8D` · TG `#6C63FF` · Non-HDL `#B85CC7`

**Type**: system font; ExtraBold, tight-tracked display numerals; 8dp spacing grid; 16–28dp corner radii.

**Motion**: 900 ms eased counter animations, 1.1 s gauge sweep, 1 s chart draw-in with PathMeasure,
250 ms page-indicator morphs, slide+fade navigation transitions, animated bar growth.

## Classification thresholds (mg/dL)

- **Total**: <200 Desirable · 200–239 Borderline · ≥240 High
- **LDL**: <100 Optimal · <130 Near optimal · <160 Borderline · <190 High · ≥190 Very high
- **HDL**: ≥60 Protective · ≥40 (♂) / ≥50 (♀) Acceptable · below Low
- **TG**: <150 Normal · <200 Borderline · <500 High · ≥500 Very high
- **Non-HDL**: <130 Optimal · <160 Above optimal · <190 Borderline · <220 High · ≥220 Very high
- **Ratios**: TC/HDL <3.5 excellent, ≤5 average, >5 high · LDL/HDL <2.5 / ≤3.5 / >3.5 · TG/HDL <2 / ≤4 / >4

## FatSecret integration

- OAuth 2.0 client-credentials → `https://oauth.fatsecret.com/connect/token` (Basic auth, scope `basic`), token cached ~24 h
- `foods.search`, `food.get.v4`, `food.find_id_for_barcode` on `https://platform.fatsecret.com/rest/server.api` (JSON)
- Credentials pasted by the user in Settings, stored encrypted (EncryptedSharedPreferences / Keychain)
- Graceful degradation: built-in food DB when unconfigured or offline; error banners never block logging

## Architecture

- **Android**: Kotlin · Jetpack Compose + Material 3 · MVVM · Room · DataStore · OkHttp + kotlinx.serialization ·
  manual DI (AppContainer) · AlarmManager reminders · CameraX + ML Kit barcode · custom Canvas charts
- **iOS**: Swift · SwiftUI · SwiftData · Swift Charts · URLSession async/await · Keychain ·
  UserNotifications · VisionKit DataScanner · matching domain layer

Both apps share identical domain logic, thresholds, color system and screen inventory for 1:1 feature parity.
