# TimeTank MVP Build Notes

## Current Project Settings

- App target: `TimeTank`
- Bundle ID: `com.piperstudio.timetank`
- App Group: `group.com.piperstudio.timetank`
- Minimum iOS target: iOS 17.0
- Xcode used for verification: Xcode 16.4

## Targets

- `TimeTank`: SwiftUI app, onboarding, app picker, budget setup, tank dashboard, stats, Currents, settings.
- `TimeTankMonitor`: `DeviceActivityMonitor` extension. Keeps logic intentionally tiny for the Screen Time extension memory ceiling.
- `TimeTankShieldAction`: handles shield button taps and pollution increments.
- `TimeTankShieldConfiguration`: provides the branded TimeTank shield copy and Finn icon.

## Apple Developer Setup Required

Before real Screen Time behavior can work on a device, the Apple Developer account must have:

- Family Controls entitlement approved by Apple.
- App Groups capability enabled for all four targets.
- App Group value: `group.com.piperstudio.timetank`.
- Matching bundle IDs created for:
  - `com.piperstudio.timetank`
  - `com.piperstudio.timetank.monitor`
  - `com.piperstudio.timetank.shieldaction`
  - `com.piperstudio.timetank.shieldconfiguration`
- A development team selected in Xcode for every target.

Without those, the project can compile, but authorization, monitoring, and shields will not work as a true installed Screen Time app.

See `APPLE_REVIEW_AND_ENTITLEMENT.md` for entitlement request copy, App Review notes, and the device acceptance checklist.

## Real Device Testing Notes

Screen Time APIs are not meaningfully testable in Simulator. Use a physical iPhone signed with the approved entitlement.

Recommended first device test:

1. Install TimeTank on device from Xcode.
2. Launch app and approve Screen Time authorization.
3. Go to Budget.
4. Pick one low-risk distraction app using the Family Activity picker.
5. Set a small budget, such as 1 minute.
6. Start monitoring.
7. Use the selected app until the threshold is reached.
8. Confirm the TimeTank shield appears.
9. Tap `Stay Focused` and confirm the app closes/stays blocked.
10. Reopen and tap `Open Anyway`.
11. Return to TimeTank and confirm the tank pollution rose.
12. Wait for the 15-minute bypass window to expire and confirm the selected app is shielded again.

The app stores budget-exceeded and bypass-expiration state in the shared App Group. The monitor extension reapplies the shield when the bypass activity ends, and the main app also reapplies the shield on foreground refresh if the bypass has already expired. This gives the MVP a recovery path if a device delays the extension callback.

The shield action extension returns `.close` for the primary "stay focused" path. For "open anyway," it clears the shield, records pollution, starts the bypass cooldown, and returns `.none` so the system does not redraw the shield after the bypass action.

The Settings tab includes a small diagnostics log backed by App Group `UserDefaults`. It records authorization attempts, schedule starts/failures, monitor threshold callbacks, shield applications, and bypass actions. Use it during physical-device testing to confirm which extension callbacks actually fired.

## Verified Locally

These checks passed with signing disabled:

```sh
xcodebuild -project TimeTank.xcodeproj -scheme TimeTank -destination 'generic/platform=iOS Simulator' -configuration Debug CODE_SIGNING_ALLOWED=NO build
xcodebuild -project TimeTank.xcodeproj -scheme TimeTank -destination 'generic/platform=iOS' -configuration Debug CODE_SIGNING_ALLOWED=NO build
```

## Known MVP Boundaries

- The marketplace is intentionally stubbed until the Screen Time loop is proven on device.
- Detailed historical stats are intentionally stubbed until device behavior is validated.
- StoreKit, analytics, widgets, CI/CD, and TestFlight automation are not part of this first vertical slice.
