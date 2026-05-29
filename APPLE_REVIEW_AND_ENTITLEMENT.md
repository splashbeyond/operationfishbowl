# TimeTank Apple Review and Entitlement Notes

## Family Controls Entitlement Request

Submit the Family Controls entitlement request as early as possible. TimeTank needs the entitlement for the main app and every Screen Time extension target:

- `com.piperstudio.timetank`
- `com.piperstudio.timetank.monitor`
- `com.piperstudio.timetank.shieldaction`
- `com.piperstudio.timetank.shieldconfiguration`

Use the same App Group across all targets:

- `group.com.piperstudio.timetank`

## Entitlement Justification Draft

TimeTank is a user-controlled productivity and digital wellness app. The app uses Apple's Screen Time APIs so an individual user can choose distracting apps and websites, set a daily time budget, and receive an on-device shield after that self-selected budget is spent.

TimeTank does not expose the names of selected apps or websites to a server. App and website selections are represented by Apple's opaque Family Controls tokens and stored locally in the shared App Group so the main app, Device Activity Monitor extension, Shield Action extension, and Shield Configuration extension can coordinate.

The app uses:

- `FamilyControls` to request individual authorization and present Apple's `FamilyActivityPicker`.
- `DeviceActivity` to monitor only the user-selected distractions against one daily budget schedule and one temporary bypass cooldown schedule.
- `ManagedSettings` to apply and remove shields for the user's selected tokens.
- App Groups to share small state values such as selected tokens, budget minutes, pollution level, Currents balance, and bypass expiration.

The Screen Time functionality is core to the product. TimeTank cannot provide selected-app budgets, shield screens, or bypass cooldowns without this entitlement.

## App Review Notes Draft

TimeTank is a Screen Time utility for individual users. During onboarding, tap `Allow Screen Time` and approve Screen Time authorization. In the Budget tab, choose at least one app, category, or website, set a small daily budget, and tap `Start Monitoring`.

When the selected app usage reaches the budget, TimeTank displays a custom shield. The primary button closes the app. The secondary button allows a 15-minute bypass, increments the local pollution state, and schedules the shield to return after the bypass window.

All Screen Time selections remain on device. The app uses Apple's opaque Family Controls tokens and does not collect or transmit app usage history.

## Implementation Notes for Review

- The app uses one global "Distractions" bucket to avoid creating many Device Activity schedules.
- The monitor extension is deliberately tiny and uses only App Group `UserDefaults` plus `ManagedSettings` to stay under Apple's extension memory limit.
- The custom shield uses brand copy and a vector Finn icon but does not reveal selected app names.
- The bypass flow clears the shield and returns `ShieldActionResponse.none`; the primary "stay focused" flow returns `ShieldActionResponse.close`.
- The main app re-checks bypass expiration on foreground refresh so shields recover if an extension callback is delayed by the system.

## Physical Device Acceptance Checklist

1. Install a signed build on a physical iPhone with the Family Controls entitlement active for all four targets.
2. Approve Screen Time authorization from onboarding.
3. Pick a low-risk app in the Budget tab.
4. Set the budget to 1 minute and start monitoring.
5. Use the selected app until the budget threshold is reached.
6. Confirm the TimeTank shield appears.
7. Tap the primary button and confirm the app closes or stays blocked.
8. Reopen the selected app, tap the secondary button, and confirm the app opens.
9. Return to TimeTank and confirm pollution increased by 20%.
10. Wait 15 minutes and confirm the selected app is shielded again.
11. Leave the app idle until the next daily interval starts and confirm pollution resets; if pollution was clean, confirm Currents increment by 1.
