# LipidCare — Cholesterol Tracker (iOS)

A polished, production-grade cholesterol tracking app built with **SwiftUI + SwiftData + Swift Charts**.
Track lipid panels, understand your numbers with color-coded ATP III risk bands and a composite
**Lipid Score**, log food with real cholesterol data from the **FatSecret Platform API**, manage
medications with reminders, and share doctor-ready reports.

> Android companion app: [`cholesterol-tracker-android`](https://github.com/kumarpradeepk/cholesterol-tracker-android) — full feature parity.

## Features

- 🩸 **Lipid panel logging** — Total, LDL, HDL, triglycerides with fasting flag, notes, validation and editing
- 🧮 **Auto-calculations** — Friedewald LDL, Non-HDL, VLDL, TC/HDL · LDL/HDL · TG/HDL ratios
- 🎯 **Lipid Score** — animated 0–100 composite gauge with NCEP ATP III color-coded categories (sex-aware HDL)
- 📊 **Trends** — Swift Charts with optimal-zone bands, LDL target line, 1M–All ranges, scrub-to-inspect, stats
- 🍽️ **Food diary** — FatSecret-powered search + **barcode scanning** (VisionKit), offline built-in database (70+ foods incl. Indian cuisine), daily cholesterol & saturated-fat budgets with progress rings, favorites quick-add, weekly chart
- 💊 **Medications** — dose schedule, daily checklist, 7-day adherence ring, repeating local-notification reminders
- 💡 **Insights** — rule-based nudges: trend changes, retest reminders, TG/HDL insulin-resistance flag, diet feedback
- 📚 **Learn** — 8 in-app education articles
- 📄 **Reports** — CSV export and a formatted PDF report (rendered with `ImageRenderer`) via the share sheet
- 🌗 mg/dL ⇄ mmol/L, dark mode, animated onboarding, haptic-friendly native design

See [DESIGN.md](DESIGN.md) for the full product/design specification shared by both platforms.

## Getting started

```bash
git clone https://github.com/kumarpradeepk/cholesterol-tracker-iOS
open LipidCare.xcodeproj   # Xcode 16 or newer
```

- **iOS 17.0+** · Swift 5 · no external dependencies — everything is first-party frameworks
- Select your development team under *Signing & Capabilities*, then Run.
- No API key needed to use the app — the built-in food database works offline.

### Connecting the FatSecret API (recommended)

1. Create a free application at [platform.fatsecret.com](https://platform.fatsecret.com) and copy the **Client ID** and **Client Secret** (OAuth 2.0).
2. In FatSecret's console, allow your IP addresses (or "Allow all") for OAuth 2.0.
3. In the app: **More → Food database (FatSecret) → API credentials**, paste both values.

Credentials are stored in the iOS **Keychain** and used only for the OAuth client-credentials flow
(`foods.search`, `food.get.v4`, `food.find_id_for_barcode`).

## Architecture

```
LipidCare/
├── LipidCareApp.swift        # App entry, SwiftData container, tab navigation
├── Domain/                   # Pure logic — identical math to Android:
│   ├── LipidMath.swift       #   Friedewald, ratios, ATP III bands, Lipid Score
│   ├── InsightsEngine.swift  #   rule-based personalized insights
│   ├── BuiltInFoods.swift    #   offline food database
│   └── DomainTypes.swift     #   shared enums & value types
├── Models/                   # SwiftData @Model classes (readings, food entries,
│                             #   medications, dose logs, favorites)
├── Services/
│   ├── FatSecretClient.swift # actor: OAuth2 token cache + API calls (URLSession)
│   ├── KeychainStore.swift   # secure credential storage
│   ├── ReminderService.swift # UNUserNotificationCenter scheduling
│   ├── ExportService.swift   # CSV + PDF report generation
│   └── UserSettings.swift    # @Observable profile & preferences
├── Theme/                    # Design tokens (palette identical to Android)
├── Components/               # ScoreGauge, ProgressRing, RiskChip, FlowLayout…
└── Views/                    # Onboarding, Dashboard, AddReading, History,
                              #   Trends, Diet, FoodSearch, BarcodeScanner,
                              #   Meds, Learn, Settings
```

- **SwiftData** `@Query`-driven views; all health data stays on device
- **Swift Charts** with `chartXSelection` scrubbing, target bands and animated transitions
- The Xcode project uses Xcode 16 synchronized folders — new files are picked up automatically

## Privacy & disclaimer

All health data stays on the device. The app provides educational information only and is not a
substitute for professional medical advice.
