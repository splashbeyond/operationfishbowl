# TimeTank — Session Update: May 31, 2026 (Evening)

**Branch:** `go2market`
**Repo:** `https://github.com/splashbeyond/operationfishbowl.git`
**Status:** All changes pushed and live on branch.

---

## Overview

This session focused on three things:

1. Building a post-onboarding first-setup flow (`FirstSetupView`)
2. Fixing the "Today's Budget" card showing pre-install Screen Time usage as budget spent on fresh install
3. Removing the Today's Budget card entirely from the home screen once the root cause was understood

---

## What Changed

### First-Setup Flow: `FirstSetupView`

A new full-screen cover appears after onboarding completes, gated by `!model.hasCompletedFirstSetup`. It walks the user through 4 steps before they reach the main dashboard.

**Step 0 — Budget**
Slider (5m → 12h, snaps to 5-minute increments) with `FinnMascotWorried` in an info card explaining what the budget means in plain language. "Save & Continue" calls `model.saveBudget(minutes:)`.

**Step 1 — Apps**
"Choose Apps" opens the real `FamilyActivityPicker`. Shows a confirmation message after selection with the count. Has a "Skip for now" option if the picker was never opened.

**Step 2 — Features**
Six feature rows (Tank, Shield, Bypasses, Widgets, Currents, Stats), each with a coloured icon, title, and one-sentence description. No interaction — just education.

**Step 3 — Launch**
"Start Finn's Protection" calls `handleLaunch()`. "Set up later" calls `model.completeFirstSetup()` and goes straight to the dashboard.

**New model state:**
- `hasCompletedFirstSetup: Bool` — stored in app group UserDefaults, read in `init()` and `refresh()`
- `completeFirstSetup()` — sets the flag; also sets `budgetTrackingStartDate` if nil

**New constants key:** `TimeTankDefaultsKey.hasCompletedFirstSetup`

**`RootView`** gained a `.fullScreenCover` binding on `!model.hasCompletedFirstSetup`.

---

### Fresh-Install Budget Tracking Fix

**The problem:** `DeviceActivitySchedule` starts at midnight by default. On a fresh install at 6:30 PM, a user who already spent 2 hours on social media that day would immediately trigger `eventDidReachThreshold` — the shield fires before they've used the app at all.

**The fix:**

`ScreenTimeScheduler.startDailyMonitoring(startFromNow: Bool = false)`
- When `startFromNow: true`: creates a **non-repeating** schedule starting at current time + 5s. iOS only counts usage from that point toward the threshold.
- When `startFromNow: false`: normal midnight-repeating schedule (all subsequent days).

`TimeTankModel.startMonitoring()`
- Detects first install via `store.budgetTrackingStartDate == nil`
- Passes `startFromNow: true` on first install; sets `store.isInstallDaySchedule = true`

`TimeTankMonitorExtension.intervalDidEnd`
- When `isInstallDaySchedule` is true and the install-day schedule ends at 23:59, clears the flag and restarts the normal midnight-repeating schedule automatically — no user action needed.

**New store/model state:**
- `isInstallDaySchedule: Bool` — true while the non-repeating install-day schedule is active; cleared at midnight by the monitor extension

---

### Today's Budget Card: Root Cause + Removal

**Why the card was broken:** `DeviceActivityFilter.Segment.daily(during:)` does not support sub-day filtering. Passing a `DateInterval` starting at 6:30 PM still returns full-day usage from midnight. There is no API to tell `DeviceActivityReport` "only count usage after this time today."

**Intermediate fix attempted:** Gate `DeviceActivityReport` behind `model.isInstallDaySchedule` — show a native SwiftUI view on install day, show the report from day 2+. This was correct in concept but the `isInstallDaySchedule` flag was being reset to `false` before the dashboard rendered.

**Root cause of the flag reset:** `handleLaunch()` in `FirstSetupView` was calling `model.startMonitoring()` twice:
1. First from `requestAuthorization()` → `autoStartIfReady()` → `startMonitoring()` (correctly detected `budgetTrackingStartDate == nil`, set `isInstallDaySchedule = true`)
2. Then `handleLaunch()` called `model.startMonitoring()` again immediately after — by this point `budgetTrackingStartDate != nil` so `isFirstInstall = false` and `isInstallDaySchedule` was reset to `false`

**Fix:** Added `!model.isMonitoringEnabled` guard in both branches of `handleLaunch()` so `startMonitoring()` is never called a second time if it already ran via `autoStartIfReady()`.

**Final decision:** User requested the Today's Budget card be removed entirely. Removed `budgetTrackerCard`, `installDayBudgetView`, `budgetTrackerTimer`, `budgetTrackerRefreshID`, `refreshBudgetTracker()`, `budgetTrackerFilter`, `budgetTrackerContext`, and all related `.onChange` / `.onReceive` modifiers from `TankDashboardView`. Also removed the now-unused `import DeviceActivity` and `import ManagedSettings` from that file.

---

## Key Files Changed

| File | What Changed |
|------|-------------|
| `TimeTank/App/FirstSetupView.swift` | New file — 4-step first-setup flow |
| `TimeTank/App/RootView.swift` | Added `.fullScreenCover` for `FirstSetupView` |
| `TimeTank/App/TimeTankModel.swift` | `hasCompletedFirstSetup`, `isInstallDaySchedule`, `completeFirstSetup()`, install-day detection in `startMonitoring()` |
| `TimeTank/App/TankDashboardView.swift` | Removed Today's Budget card and all DeviceActivityReport infrastructure |
| `TimeTank/Shared/TimeTankStore.swift` | `hasCompletedFirstSetup`, `isInstallDaySchedule` properties |
| `TimeTank/Shared/TimeTankConstants.swift` | Two new `TimeTankDefaultsKey` entries |
| `TimeTank/Shared/ScreenTimeScheduler.swift` | `startDailyMonitoring(startFromNow:)` parameter |
| `TimeTankMonitor/TimeTankMonitorExtension.swift` | `intervalDidEnd` rollover from install-day schedule to midnight schedule |
| `TimeTank.xcodeproj/project.pbxproj` | Added `FirstSetupView.swift` to target |

---

## What's Still Pending

- **RevenueCat paywall** — step 25 (`paywallScreen`) in onboarding is still a placeholder
- **Budget tab** (`BudgetView`) — referenced in the tab bar but not updated this session; the `DeviceActivityReport` there may have the same install-day display issue if it's still present
