# TimeTank — Session Update: May 30, 2026

**Branch:** `mvp`
**Repo:** `https://github.com/splashbeyond/operationfishbowl.git`
**Status:** All changes committed and pushed. Ready to test.

---

## Overview

This session completed the core bypass loop for TimeTank. The major themes were:

1. Getting the custom Finn shield to actually appear (not iOS's generic one)
2. Making bypass correctly track pollution
3. Escalating bypass windows that increase over the day
4. Shield reappearance after bypass (the hardest problem)
5. Finn tap-to-reapply as a user-facing override
6. Usage-evidenced notifications that fire at bypass expiry and deep-link back to the tank
7. All new Finn mascot artwork added throughout the app

---

## What Changed

### Custom Shield Now Works
The shield extension was loading but crashing silently because the Finn PNG images were 1.1–1.7 MB each. Extensions have very tight memory limits. Fixed by resizing all three shield images to 400×400 px (~85 KB each).

`ShieldAssets.xcassets` is inside `TimeTankShieldConfiguration/` and must be added to that target specifically in Xcode — it is separate from the main app's `Assets.xcassets`.

Shield face logic (`TimeTankShieldConfigurationExtension.swift`):
- `pollution < 0.8` → FinnMascotWorried
- `pollution 0.8–1.0` → FinnMascotDistressed
- `pollution >= 1.0` → FinnMascotSuffering

---

### Bypass Counting Is Now Reliable
Previously, `incrementBypassCount()` was triggered by a DeviceActivity event threshold — unreliable when called from an extension. Now it fires immediately inside `TimeTankShieldActionExtension` the moment "Open Anyway" is tapped. Works for every budget interval, not just the 1-minute test.

---

### No Home Screen Friction on Bypass
Changed `completionHandler(.close)` → `completionHandler(.none)` for the secondary button. `clearShield()` unblocks the app before the handler fires, so the user stays in the blocked app instead of being kicked to the home screen.

---

### Escalating Bypass Windows
Centralized in `TimeTankRules.bypassWindowMinutes(bypassCount:budgetMinutes:)`:

| Budget | Bypass # | Window |
|--------|----------|--------|
| ≤ 1 min (test mode) | any | 1 min |
| > 1 min (production) | 1st | 5 min |
| > 1 min | 2nd | 10 min |
| > 1 min | 3rd | 15 min |
| > 1 min | 4th | 30 min |
| > 1 min | 5th+ | 60 min |

Test mode (budget ≤ 1 min) always returns 1 minute regardless of bypass count. This means the full pollution arc can be tested in about 10 minutes.

---

### Event-Based Pollution
The MVP uses the criteria doc's event-based pollution model. Crossing the daily threshold sets pollution to at least **20%**, and each "Open Anyway" tap adds **20% pollution**. Five bypasses = fully polluted tank.

Reports and overflow minutes are useful for reflection, but they do not drive MVP enforcement or murkiness because Screen Time reports can update late.

---

### Shield Reappearance After Bypass (Three Paths)

This was the hardest problem. `DeviceActivityCenter.startMonitoring` is unreliable from extension processes. The solution is three layered paths:

**Path A — Extension best-effort:** `startBypassCooldown()` called from the shield action extension right when bypass starts. A 10-second buffer is added to the schedule start time to avoid stale timing. If this works, the shield returns automatically.

**Path B — App foreground fallback:** Every time the user opens TimeTank, `scenePhase.active` triggers `model.refresh()` → `enforceExpiredBypassIfNeeded()`. If the bypass has expired and no active DeviceActivity is running, it reschedules from the main app process (which is reliable) and reapplies the shield directly.

**Path C — Usage-evidenced notification fallback:** During bypass, DeviceActivity watches only the selected app/category/web tokens. If the user accumulates 30 seconds of selected-app activity, a neutral notification is armed for `bypassExpiresAt`. User taps it, TimeTank opens, shield reapplied immediately via Path B. If they leave the selected app bucket, no timer-only notification should fire.

Key fix: `ScreenTimeScheduler.startBypassCooldown` now uses a **single** `DeviceActivityCenter` instance, a 10-second start buffer, and a threshold matching the actual bypass window so the shield does not reappear early.

---

### Tap Finn to Reapply Shield
A new interactive fallback on the main tank screen. When Finn is tapped:

1. Medium haptic feedback fires
2. Finn scales up to 118% with a spring animation
3. Finn's face briefly switches to `FinnMascotAlert` (shocked expression)
4. After the animation, if budget is exceeded, shield is reapplied immediately

Implemented in `FocusTankView` with `onFinnTap` closure wired in `TankDashboardView`. Finn tap is disabled at 100% pollution — he's suffering and can't help.

---

### Neutral Bypass Notification Copy
Notifications only arm after selected-app usage is detected during bypass. The copy stays neutral because TimeTank cannot perfectly prove foreground app state at delivery time:

| Title | Body |
|-------|------|
| "Bypass ended." | "TimeTank is protecting your distraction budget again." |

Tapping the notification deep-links to the Tank tab via `NotificationCenter.default.post(name: .openTankTab)`.

---

### Notifications Are Usage-Evidenced
The shield action extension no longer schedules a timer-only notification at "Open Anyway." Instead, the bypass DeviceActivity event watches selected app/category/web tokens and only arms the expiry notification after 30 seconds of selected-app activity during the bypass.

---

### All New Finn Artwork

All mascot images were replaced with new PNGs. The full set:

| Asset | Expression | Used |
|-------|-----------|------|
| `FinnMascot` | Happy / smiling | 0–20% pollution in tank |
| `FinnMascotAlert` | Shocked / surprised | 20–40% pollution; Finn tap animation |
| `FinnMascotWorried` | Deep sad frown | 40–80% pollution |
| `FinnMascotSuffering` | Open mouth alarmed | 80–100% pollution; shield at 80–100% |
| `FinnMascotDistressed` | Sad droopy eyes | 100% pollution (fully defeated); shield at 100% |
| `FinnBowl` | Finn in bowl | Onboarding |
| `AppIcon` | Finn on orange bg | App icon (1024×1024, center-cropped square) |

---

### App Icon Fixed
Original image was 4096×6144 portrait with black bars. Detected content bounds, center-cropped to 1024×1024 square.

---

## Key Files Changed

| File | What Changed |
|------|-------------|
| `TimeTankShieldAction/TimeTankShieldActionExtension.swift` | Immediate bypass count, `.none` completion, escalating window calc |
| `TimeTankMonitor/TimeTankMonitorExtension.swift` | Usage-evidenced bypass notification arming and shield reapply at interval end |
| `TimeTankShieldConfiguration/TimeTankShieldConfigurationExtension.swift` | Updated thresholds, correct Finn faces |
| `TimeTankShieldConfiguration/ShieldAssets.xcassets/` | Finn images resized to 400×400 |
| `TimeTank/Shared/TimeTankRules.swift` | `bypassWindowMinutes()`, event-based 20% threshold and bypass pollution |
| `TimeTank/Shared/ScreenTimeScheduler.swift` | Single center instance, 10s start buffer, bypass-window event threshold |
| `TimeTank/Shared/TimeTankStore.swift` | `startBypassWindow` takes explicit window parameter |
| `TimeTank/App/TimeTankModel.swift` | Notification cancellation, `enforceExpiredBypassIfNeeded`, notification permission request |
| `TimeTank/App/TimeTankApp.swift` | `scenePhase.active` refresh, deep-link handler, `AppDelegate` with `UNUserNotificationCenterDelegate` |
| `TimeTank/App/RootView.swift` | `selectedTab` moved to `TimeTankApp`, binding passed in |
| `TimeTank/App/FocusTankView.swift` | Finn tap handler, haptic, animation, updated face thresholds |
| `TimeTank/App/TankDashboardView.swift` | `onFinnTap` closure wired up, imports ManagedSettings |
| `TimeTank/Resources/Assets.xcassets/` | All Finn PNGs + AppIcon replaced |
| `TimeTank.xcodeproj/.../TimeTank.xcscheme` | Debug build, no debugger, auto-launch (fixes iOS 26 beta dyld error) |

---

## Known Limitations

- **Shield without opening TimeTank:** Path A (extension scheduling) has to work for the shield to return automatically. Path C only fires if DeviceActivity detects selected-app usage during bypass, so no usage evidence callback means no notification. This is more conservative and avoids random timer-only pings.
- **`bypassWindowMinutes` constant in `TimeTankConstants.swift`** is now unused. Can be deleted in a cleanup pass.
- **Custom shield on first fresh install** — delete app + clean build (Cmd+Shift+K) required to register extensions properly with iOS.

---

## Test Checklist (1-Minute Test)

1. Delete app from phone
2. Cmd+Shift+K clean → Cmd+R build → tap app icon manually
3. Authorize Screen Time if prompted + allow notifications
4. Select a distraction app (e.g. Instagram)
5. Settings → Start 1-Minute Device Test
6. Use selected app for 1 min → custom Finn shield appears (should show FinnMascotWorried)
7. Tap "Open Anyway" → stay in app, pollution should jump to 20%
8. Open TimeTank → verify 20% pollution visible, FinnMascotAlert face
9. Stay in or return to the blocked app for at least 30 seconds during bypass → shield should return in ~1 min, or a neutral notification should open TimeTank if automatic re-shielding is delayed
10. Repeat 4 more times → 40% → 60% → 80% → 100%, Finn face changes each time
11. At 100%, tap Finn — verify nothing happens (disabled at full pollution)
12. Tap bypass notification, if one fired → verify it opens TimeTank on the Tank tab
