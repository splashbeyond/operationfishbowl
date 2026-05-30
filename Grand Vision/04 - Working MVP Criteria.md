# Working MVP Criteria

## Purpose

This document defines what TimeTank must do to count as a working MVP.

The MVP is not "an app that has every future feature." The MVP is a reliable Screen Time product with one clear emotional loop:

> Pick the apps that pull you in, set a fair daily allowance, and protect Finn's tank by respecting that boundary.

Everything in the MVP should support that loop. Anything that makes Screen Time behavior less reliable should wait.

## MVP Product Promise

TimeTank helps users reduce unintentional scrolling without punishing healthy phone use.

The app should:

- Let the user choose specific distracting apps, categories, or websites.
- Let the user set one daily time budget for that selected group.
- Show a living tank that reflects the user's relationship with that budget.
- Shield the selected apps when the budget is spent.
- Let the user bypass intentionally, while making the cost visible through murkiness.
- Show simple usage stats that help the user understand their behavior.
- Reset each day so the user does not enter a shame spiral.

## Core MVP Rule

TimeTank monitors **selected distraction apps only**.

It should not judge all screen time by default.

Reason:

- All-phone usage includes useful, necessary, and healthy activity.
- Selected-app usage is personally meaningful.
- Apple's Screen Time implementation is more stable with one clear token bucket.
- The user understands the rule faster.

The default language should be "distraction budget" or "selected app budget," not "phone limit."

## User Flow Criteria

### 1. Onboarding

The MVP onboarding must:

- Introduce Finn and the tank.
- Explain that the user chooses the apps that make the water murky.
- Request Screen Time authorization.
- Make clear that TimeTank runs locally through Apple's Screen Time APIs.
- Avoid long education screens.

Onboarding is successful when the user understands:

> I choose the apps. I choose the budget. Finn's tank shows how well I keep that promise.

### 2. Authorization

The app must request Family Controls authorization using Apple's Screen Time APIs.

Acceptance criteria:

- If authorization is approved, the user can continue setup.
- If authorization is denied or unavailable, the app explains that Screen Time access is required.
- The app must not show fake real-device Screen Time functionality in Simulator.
- Simulator may have demo mode, but it must be labeled as demo mode.

### 3. App Selection

The user must be able to pick the apps, categories, or websites they personally want to reduce.

Acceptance criteria:

- Selection uses `FamilyActivityPicker`.
- Selection is stored in the shared App Group.
- Selection persists after app relaunch.
- The app shows the number of selected items.
- The MVP encourages specific apps over broad categories because specific app selections are easier to reason about and test.

### 4. Budget Setup

The user must set one daily budget for the selected distraction group.

Acceptance criteria:

- Budget applies to the whole selected group, not per-app budgets.
- Budget is stored locally.
- Budget persists after app relaunch.
- Recommended presets should be simple: 15 min, 30 min, 1 hr, 2 hr.
- Custom budget can exist, but should not dominate the flow.

MVP should avoid:

- Per-app budgets.
- Multiple daily schedules.
- Bedtime blocks.
- Work mode blocks.
- Complex calendar rules.

Those can come later.

## Murkiness Criteria

Murkiness is not a generic screen time score.

Murkiness means:

> The user crossed or bypassed the boundary they personally set.

### Recommended MVP Murkiness States

| State | Condition | Visual Behavior | Product Meaning |
|---|---|---|---|
| Clean | 0-79% of selected-app budget used | Clear water | You are within your plan. |
| Warning | 80-99% used | Water stays mostly clean; UI warns; Finn looks concerned | You are close. Choose carefully. |
| Spent | 100% reached | Shield applies to selected apps | Your allowance is spent. |
| Murky | User bypasses shield or continues beyond limit | Water gets murkier | You made an intentional exception. |
| Reset | New day | Water clears | New day, fresh start. |

### MVP Pollution Formula

Use event-based murkiness, not continuous report-based murkiness.

Reason:

- Device Activity threshold events are the enforcement source of truth.
- Device Activity reports may update with delay.
- Users understand discrete consequences better.
- The code is simpler and less glitchy.

Suggested MVP formula:

- At daily threshold reached: set pollution to `0.2`.
- Each bypass: add `0.2`.
- Maximum pollution: `1.0`.
- At midnight/new daily interval: reset pollution to `0.0`.

Optional later formula:

```text
overflowMinutes = max(0, selectedAppMinutes - dailyBudgetMinutes)
pollution = min(1.0, overflowMinutes / dailyBudgetMinutes)
```

Do not use this formula for MVP enforcement.

## Shield Criteria

The shield is the most important functional feature.

The shield should appear when selected-app usage reaches the daily budget.

Acceptance criteria:

- `DeviceActivityMonitor.eventDidReachThreshold` fires for the selected app bucket.
- The monitor applies `ManagedSettingsStore.shield` to the selected tokens.
- Opening a selected app after threshold shows the custom TimeTank shield.
- Non-selected apps are not blocked.
- The shield copy is calm, direct, and short.

Recommended shield copy:

Title:

> Your budget is spent.

Subtitle:

> Opening this will make the tank murkier.

Primary action:

> Stay Focused

Secondary action:

> Open Anyway

## Bypass Criteria

Bypass is allowed, but it must be intentional.

Acceptance criteria:

- Tapping `Stay Focused` closes or keeps the shield active.
- Tapping `Open Anyway` clears the shield temporarily.
- Bypass increments pollution.
- Bypass records a timestamp.
- Bypass starts a short cooldown schedule.
- When bypass expires, the shield reapplies if the budget is still spent.

Recommended MVP bypass duration:

- 15 minutes for normal product behavior.
- 1 minute test mode for device verification only.

The app should not punish the user with harsh copy. The consequence is the tank state.

## Stats Criteria

Stats exist to make behavior visible, not to drive enforcement in MVP.

Stats should include:

- Selected-app time today.
- Pickups.
- Notifications.
- First pickup.
- Longest session.

Acceptance criteria:

- Stats use `DeviceActivityReport`.
- Stats render only on real authorized devices.
- Simulator clearly says real stats require a signed iPhone.
- Stats do not need to update instantly to be considered functional.
- Enforcement does not depend on stats data.

## Dashboard Criteria

The dashboard should answer three questions quickly:

1. How is Finn's tank doing?
2. How close am I to my selected-app budget?
3. What should I do next?

MVP dashboard should include:

- Finn/tank visual.
- Murkiness percentage or state.
- Selected-app budget status.
- Short status message.
- Start monitoring button if monitoring is off.

Avoid dashboard clutter:

- No marketplace on the main screen yet.
- No complex graphs.
- No total-phone guilt scoreboard.

## Diagnostics Criteria

Because Screen Time APIs are device-only and sometimes opaque, diagnostics are required for MVP.

Settings must show:

- Authorization status.
- Selected token count.
- Current budget.
- Monitoring enabled state.
- Active Device Activity schedule names.
- Last monitoring start.
- Last threshold callback.
- Last shield apply.
- Last shield clear.
- Last shield action.
- Last schedule error.

Diagnostics must be stored in App Group `UserDefaults` so the main app and extensions can coordinate.

The diagnostic log should answer:

> Did authorization work? Did scheduling work? Did the threshold fire? Did the shield apply? Did the shield action run?

## Real Device Testing Criteria

The MVP is not verified until it works on a physical iPhone.

Simulator does not count for:

- Real Screen Time authorization.
- Family Activity token selection.
- Device Activity threshold callbacks.
- Managed Settings shields.
- Device Activity reports.

### Required Real Device Test

1. Install a fresh signed build on iPhone.
2. Approve Screen Time authorization.
3. Select one obvious test app.
4. Set budget to 1 minute.
5. Start monitoring.
6. Use selected app for more than one minute.
7. Confirm diagnostics show threshold callback.
8. Confirm selected app is shielded.
9. Tap `Open Anyway`.
10. Confirm pollution increases.
11. Confirm bypass diagnostics are recorded.
12. Confirm shield reapplies after bypass expires.
13. Confirm Stats show usage data.

MVP is not complete until this test passes.

## Technical Architecture Criteria

The Screen Time implementation should remain as small as possible.

### App Target

Responsibilities:

- Authorization.
- Picker.
- Budget.
- Dashboard.
- Stats report host.
- Diagnostics UI.

### Monitor Extension

Responsibilities:

- Daily interval start.
- Threshold reached.
- Apply shield.
- Record diagnostics.

No heavy UI. No image loading. No reports. No complex calculations.

### Shield Action Extension

Responsibilities:

- Handle primary action.
- Handle secondary bypass.
- Increment pollution.
- Start bypass cooldown.
- Record diagnostics.

### Shield Configuration Extension

Responsibilities:

- Provide shield title/subtitle/buttons.
- Stay visually simple.

### Report Extension

Responsibilities:

- Summarize Screen Time report data.
- Show selected-app usage stats.
- Never control enforcement.

## Reliability Criteria

The MVP should prefer boring reliability over cleverness.

Rules:

- One selected token bucket.
- One daily budget.
- One daily Device Activity schedule.
- One threshold event.
- One named Managed Settings store.
- One bypass cooldown.
- One App Group.
- Minimal extension logic.

Avoid:

- Multiple overlapping schedules.
- Per-app budgets.
- Background tasks for enforcement.
- Report-driven blocking.
- Complex state machines.
- Cloud sync.
- Social features.
- Marketplace mechanics before the shield loop is proven.

## Privacy Criteria

TimeTank must remain local-first.

Acceptance criteria:

- Selected apps are stored as Apple's opaque tokens.
- Screen Time data is not sent to a server.
- Usage reports are displayed locally.
- Diagnostics should not include app names unless we intentionally decide they are safe and useful.
- App Store review notes clearly explain Family Controls usage.

## MVP Non-Goals

The MVP does not need:

- Full marketplace.
- Widgets.
- Social sharing.
- AI coaching.
- Per-app budgets.
- Bedtime schedules.
- Focus timer.
- Cross-device sync.
- Streak calendar.
- Subscription system.

Those can come after the Screen Time loop is reliable.

## Definition of Done

The TimeTank MVP is working as intended when:

- A real iPhone can authorize Screen Time access.
- A user can select distraction apps.
- A user can set one daily budget.
- Monitoring starts without error.
- The threshold fires after selected-app usage exceeds the budget.
- The selected apps are shielded.
- Non-selected apps remain available.
- Bypass works and increases murkiness.
- The shield reapplies after bypass expires.
- Stats show real usage data on device.
- The tank visual clearly reflects clean, warning, spent, and murky states.
- Diagnostics make failures understandable.

If any of these fail, the MVP is not done yet.

## Product North Star

TimeTank should feel like a small, trustworthy promise:

> I choose what pulls me in. I choose how much is fair. Finn helps me notice when I cross that line.

The best version is not the strictest blocker. It is the clearest mirror with just enough friction to break the automatic loop.
