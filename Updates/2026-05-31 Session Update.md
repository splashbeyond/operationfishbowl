# TimeTank — Session Update: May 31, 2026

**Branch:** `mvp`
**Repo:** `https://github.com/splashbeyond/operationfishbowl.git`
**Status:** All changes applied locally. Build and test in Xcode needed.

---

## Overview

This session focused entirely on onboarding polish and widget improvements. The major themes were:

1. Expanding the bypass education section into three distinct screens
2. Replacing the before/after tank comparison with iOS-authentic Screen Time bar charts
3. Maximizing Finn's size across all three widget sizes
4. Replacing the app icon with the new design and propagating it throughout onboarding
5. Global "phone" → "device" copy pass

---

## What Changed

### Bypass Section Expanded: 3 New Screens

The single bypass explanation slide was replaced with three sequential screens, each doing one job. `paywallStep` was bumped from 23 → 25 to accommodate them.

**Screen 1 — Over-Limit Emotional Hook (`bypassOverLimitScreen`, step 19)**
Shows `FinnMascotDistressed` with a polluted tank at 48% and a single child-readable sentence:
> "Your budget is Finn's clean water. Every extra minute past it pours mud into his bowl — the more you go over, the cloudier his world gets."

**Screen 2 — Interactive Bypass Demo (`bypassMurkScreen`, step 20)**
The user taps a button to simulate bypasses. Each tap:
- Increments `bypassDemoCount` (state: `@State private var bypassDemoCount: Int = 0`)
- Raises `bypassDemoLevel` by `bypassPollutionIncrement` (0.2)
- Animates the tank murkier with `withAnimation(.spring)`
- Changes Finn's face: Worried (0–1 bypass), Distressed (2), Suffering (3+)
- Shows a live "murky" percentage badge below Finn

A card below the demo shows the escalating bypass window schedule (5 → 10 → 15 → 30 → 60 min) with a live `← now` indicator on the active row, driven by `bypassDemoCount`.

**Screen 3 — Shield Mockup (`shieldScreen`, step 21)**
An iOS-authentic mockup of the Screen Time block screen so users recognize it before they see it for real. Uses actual system colors (`Color(UIColor.systemBackground)`), the real app icon (dimmed with `.black.opacity(0.38)` and a dark clock badge), and real iOS copy: "Ask For More Time" / "It's OK". Underneath, a caption explains that the shield appears after the daily budget is spent.

---

### Before/After Screen: iOS Screen Time Bar Charts

Replaced the side-by-side `FocusTankView` comparison with bar charts that match the style of Apple's native Screen Time graphs.

**`screenTimeBarChart(label:avgHours:color:sharedMax:)`**
- 7 bars (S M T W T F S), Saturday = "today"
- Rounded rectangle track at 10% opacity, fill at 48% for non-today bars, full opacity for Saturday
- Day multipliers `[1.18, 0.78, 0.85, 0.74, 0.91, 1.20, 1.30]` simulate a realistic usage week
- The shared y-axis was the key fix: both charts receive `sharedMax: screenTimeHours * 1.30` so BEFORE bars reach full height and WITH TIMETANK bars are proportionally shorter — visually proving the reduction at a glance

---

### Widget Finn Sizing Maximized

All three widget sizes were updated to give Finn as much space as physically possible.

| Widget | Change |
|--------|--------|
| Small | `ZStack(alignment: .bottom)` — Finn fills entire widget with `frame(maxWidth: .infinity, maxHeight: .infinity)`, percentage overlaid at bottom with white text shadow |
| Medium | `frame(maxHeight: .infinity)` on Finn removes the old 112pt fixed height cap |
| Large | `frame(maxWidth: .infinity)` + `layoutPriority(1)` ensures Finn expands before the stat block |

Also removed the "CLEAN" status text label from the small widget entirely. Only the percentage remains.

---

### New App Icon + Onboarding Propagation

**Icon replacement**
Source file: `/Users/davis/Downloads/Group 2 (2).png` (4096×4096, larger Finn on orange background)
Scaled to 1024×1024 using Python PIL LANCZOS → written to `TimeTank/Resources/Assets.xcassets/AppIcon.appiconset/AppIcon.png`

> Requires **Product → Clean Build Folder** + fresh run in Xcode for the new icon to appear on device.

**Icon used in three onboarding locations via `UIImage(named: "AppIcon")`**

| Location | Size | Notes |
|----------|------|-------|
| `notificationPreview()` | 42×42, cornerRadius 10 | Left of notification text |
| `connectScreenTimeScreen` | 80×80, cornerRadius 18 | Replaces plain orange hourglass card; tideOrange shadow |
| `shieldMockup` | 76×76, cornerRadius 18 | Dimmed `.black.opacity(0.38)` overlay + dark clock badge bottom-right |

---

### Layout Fixes: Progress Bar Clearance

All screens in the bypass + before/after section were hitting the progress bar (which sits at ~56pt from top). Fixed by adding `Spacer().frame(height: 80)` as the first element on every affected screen.

| Screen | Old top spacer | Fixed |
|--------|---------------|-------|
| `bypassMurkScreen` | 16pt | 80pt |
| `shieldScreen` | 52pt | 80pt |
| `beforeAfterScreen` | 56pt | 80pt |

---

### Quiz Screen Finn Badge Removed

The small `FinnMascotAlert` badge in the top-left corner of every quiz screen was deleted. It was too small to read at quiz-card scale and added visual noise without adding meaning.

---

### Copy: "phone" → "device"

All user-facing strings referencing "phone" were updated to "device" so the app reads correctly on iPad and future form factors. Scientific study citations were left unchanged.

| File | Location | Before | After |
|------|----------|--------|-------|
| `OnboardingView.swift` | Finn intro screen | "Your phone is his world." | "Your device is his world." |
| `OnboardingView.swift` | Screen time stats | "scrolling on this phone" | "scrolling on this device" |
| `OnboardingView.swift` | Chart legend | "years on your phone" | "years on your device" |
| `OnboardingView.swift` | Pollution description | "lost to your phone" | "lost to your device" |
| `OnboardingView.swift` | All-day quiz result | "Your phone pulls at you" | "Your device pulls at you" |
| `TimeTankWidgetExtension.swift` | Widget status long | "break from the phone" | "break from the device" |

---

## Key Files Changed

| File | What Changed |
|------|-------------|
| `TimeTank/App/OnboardingView.swift` | 3 new bypass screens, bar chart before/after, quiz badge removed, icon in 3 places, layout fixes, phone→device copy |
| `TimeTankWidget/TimeTankWidgetExtension.swift` | Finn sizing for all 3 widget sizes, CLEAN label removed, phone→device copy |
| `TimeTank/Resources/Assets.xcassets/AppIcon.appiconset/AppIcon.png` | Replaced with new 1024×1024 design |

---

## What's Still Pending

- **RevenueCat paywall** — step 25 (`paywallScreen`) is a placeholder. The paywall needs to be wired in when RevenueCat is added.
- **Clean Build required** — new app icon will not appear until Xcode does Product → Clean Build Folder + fresh run.

---

## Current Onboarding Step Map

| Step | Screen |
|------|--------|
| 0 | Welcome / Finn intro |
| 1–5 | Quiz (usage habits) |
| 6 | Quiz result / personalized plan |
| 7 | Science / research backing |
| 8 | How pollution works |
| 9 | Notifications permission |
| 10 | Connect Screen Time |
| 11–18 | Feature education (tank, widgets, currents, etc.) |
| 19 | Bypass over-limit (Finn sad, mud metaphor) |
| 20 | Bypass interactive demo (tap to murky) |
| 21 | Shield mockup (what the block screen looks like) |
| 22 | Widgets preview |
| 23 | Commitment screen |
| 24 | Before/after bar charts |
| 25 | Paywall (placeholder) |
