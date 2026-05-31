# TimeTank Session Notes — May 30 2026

## Branch
`mvp` — all changes committed and pushed to `https://github.com/splashbeyond/operationfishbowl.git`

## Current Build Setup
- **Xcode 26 beta** (iOS 26 beta device)
- **Scheme**: Debug build, no debugger (`selectedDebuggerIdentifier = ""`), `launchStyle = "0"` (auto-launch)
- **dyld error on build**: Known iOS 26 beta issue — click OK, app still installs and runs
- **How to run**: Build (Cmd+R) → tap app icon manually on phone (or auto-launches)
- **Always delete app from phone + clean build (Cmd+Shift+K) before a fresh test**

---

## What Was Fixed This Session

### 1. Custom Shield Now Works
The `TimeTankShieldConfiguration` extension was loading but crashing silently because the Finn PNG images in `ShieldAssets.xcassets` were 1.1–1.7 MB each. Extensions have tight memory limits. Fixed by resizing all three images to 400×400px (~85 KB each).

`ShieldAssets.xcassets` was added to the `TimeTankShieldConfiguration` target via Xcode UI (not pbxproj manual edit). Located at:
`TimeTankShieldConfiguration/ShieldAssets.xcassets/`

Images:
- `FinnMascotWorried.png` — deep sad frown (400×400)
- `FinnMascotDistressed.png` — sad droopy eyes (400×400)
- `FinnMascotSuffering.png` — open mouth alarmed (400×400)

Shield logic in `TimeTankShieldConfigurationExtension.swift`:
- `pollution < 0.8` → FinnMascotWorried
- `pollution 0.8–1.0` → FinnMascotDistressed
- `pollution >= 1.0` → FinnMascotSuffering

### 2. Bypass Counting Fixed
`incrementBypassCount()` was previously triggered by a DeviceActivity event threshold (unreliable from extensions). Moved to fire **immediately** in `TimeTankShieldActionExtension` when "Open Anyway" is tapped. This works reliably for all budget intervals.

### 3. No More Home Screen Friction on Bypass
Changed `completionHandler(.close)` → `completionHandler(.none)` for the secondary button. Since `clearShield()` unblocks the app in ManagedSettingsStore before the handler fires, the user stays in the app instead of being kicked to the home screen.

### 4. Escalating Bypass Windows
Logic lives in `TimeTankRules.bypassWindowMinutes(bypassCount:budgetMinutes:)`:

| Budget | Bypass # | Window |
|--------|----------|--------|
| ≤ 1 min (test mode) | any | 1 min |
| > 1 min (production) | 1st | 5 min |
| > 1 min | 2nd | 10 min |
| > 1 min | 3rd | 15 min |
| > 1 min | 4th | 30 min |
| > 1 min | 5th+ | 60 min |

### 5. Event-Based Pollution
The MVP follows the criteria doc's event-based murkiness rule:
- Daily threshold reached: pollution becomes at least 20%.
- Each "Open Anyway" bypass: adds 20%.
- 5 bypasses = 100% full tank.

Do not drive MVP pollution from continuously reported overflow minutes. DeviceActivity reports can lag, so reports stay in Stats and enforcement/murkiness stay tied to threshold and bypass events.

### 6. Shield Reappearance After Bypass (Three Paths)
**Path A** — Extension scheduling works: `startBypassCooldown()` called from `TimeTankShieldActionExtension` → monitor's `intervalDidEnd` fires → shield reapplied automatically.

**Path B** — User opens TimeTank: `scenePhase.active` → `model.refresh()` → `enforceExpiredBypassIfNeeded()` → schedules bypass cooldown from main app when needed and cancels pending bypass notifications.

**Path C** — Usage-evidenced notification fallback: during bypass, DeviceActivity watches only the selected app/category/web tokens. If the user accumulates 30 seconds of selected-app activity, TimeTank arms a neutral bypass-expiry notification. If the user opens TimeTank or the shield reapplies, the notification is canceled.

Key fix in `ScreenTimeScheduler.startBypassCooldown`: now uses a single `DeviceActivityCenter` instance and adds a **10-second buffer** to the schedule start time to prevent stale timing when called from extension processes. The bypass interval end controls shield reapply; the bypass event threshold is only 30 seconds of selected-app usage evidence for notification gating.

### 7. Scene Phase Observer
Added to `TimeTankApp.swift`:
```swift
.onChange(of: scenePhase) { _, newPhase in
    if newPhase == .active {
        model.refresh()
    }
}
```
This ensures bypass enforcement and pollution sync happens every time the user opens TimeTank.

### 8. New Finn Artwork
All Finn mascot images updated in `TimeTank/Resources/Assets.xcassets/`:

| Asset | State | Used In |
|-------|-------|---------|
| `FinnMascot` | Happy (smiling) | Currents page, 0–20% tank |
| `FinnMascotAlert` | Shocked/surprised | 20–40% tank |
| `FinnMascotWorried` | Deep sad frown | 40–80% tank |
| `FinnMascotSuffering` | Open mouth alarmed | 80–100% tank |
| `FinnMascotDistressed` | Sad droopy eyes | 100% tank (defeated) |
| `FinnBowl` | Finn in bowl | Onboarding screen |
| `AppIcon` | Finn on orange bg | App icon (1024×1024) |

Tank pollution thresholds in `FocusTankView.finnFaceName`:
- `0..<0.2` → FinnMascot
- `0.2..<0.4` → FinnMascotAlert
- `0.4..<0.8` → FinnMascotWorried
- `0.8..<1.0` → FinnMascotSuffering
- `default (≥1.0)` → FinnMascotDistressed

### 9. 1-Minute Test Mode
`TimeTankRules.bypassWindowMinutes` returns `1` when `budgetMinutes <= 1`. This means the full 5-bypass / 100% pollution arc can be tested in ~10 minutes:
- Each bypass: +20% pollution, shield returns in 1 min
- 5 bypasses → Finn suffering → tank fully polluted

---

## Key Files Changed This Session

| File | What Changed |
|------|-------------|
| `TimeTankShieldAction/TimeTankShieldActionExtension.swift` | Bypass count immediate, `.none` completion, escalating window calc |
| `TimeTankShieldConfiguration/TimeTankShieldConfigurationExtension.swift` | Updated pollution thresholds for shield faces |
| `TimeTankShieldConfiguration/ShieldAssets.xcassets/` | Resized Finn images to 400×400 |
| `TimeTank/Shared/TimeTankRules.swift` | `bypassWindowMinutes()` function, event-based 20% threshold and bypass pollution |
| `TimeTank/Shared/ScreenTimeScheduler.swift` | Single center instance, 10s start buffer, bypass-window event threshold |
| `TimeTank/Shared/TimeTankStore.swift` | `startBypassWindow` uses dynamic window from `TimeTankRules` |
| `TimeTank/App/TimeTankModel.swift` | Scene phase observer, bypass notification cancellation, `enforceExpiredBypassIfNeeded` improvements |
| `TimeTank/App/TimeTankApp.swift` | `scenePhase.active` → `model.refresh()` |
| `TimeTank/App/FocusTankView.swift` | Updated pollution thresholds, new Finn face mapping |
| `TimeTank/Resources/Assets.xcassets/` | All Finn PNGs + AppIcon replaced with new artwork |
| `TimeTank.xcodeproj/xcshareddata/xcschemes/TimeTank.xcscheme` | Debug build, no debugger, auto-launch |

---

## Known Issues / Not Yet Fixed
- **Custom shield on first install**: After a fresh install, deleting app + clean build (Cmd+Shift+K) required to register extensions properly. If generic "Restricted" shield shows, this is the fix.
- **Shield reappearance without opening TimeTank**: If user stays in blocked app and never opens TimeTank, Path A (extension scheduling) must work. The notification fallback is now conservative and only arms after selected-app usage is detected during bypass. This avoids random timer-only notifications, but means no usage evidence callback equals no notification.
- **`bypassWindowMinutes` constant** in `TimeTankConstants.swift` is now unused (replaced by `TimeTankRules.bypassWindowMinutes`). Can be cleaned up.

---

## Testing Checklist (1-Minute Test)
1. Delete app from phone
2. Cmd+Shift+K clean, Cmd+R build
3. Tap app icon manually to open
4. Authorize Screen Time if prompted
5. Settings → allow notifications
6. Select a distraction app (e.g. Instagram)
7. Settings → Start 1-Minute Device Test
8. Use selected app for 1 min → custom Finn shield appears
9. Tap "Open Anyway" → stay in app, pollution should jump to 20%
10. Open TimeTank → verify 20% pollution visible
11. Stay in or return to the blocked app for at least 30 seconds during bypass, then verify the shield returns in ~1 min or a neutral bypass-ended notification opens TimeTank.
12. Repeat 4 more times → verify 40% → 60% → 80% → 100% pollution with correct Finn face each time
