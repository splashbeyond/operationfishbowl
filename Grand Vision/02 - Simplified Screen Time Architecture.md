# Simplified Screen Time Architecture

## Goal

Make the Screen Time implementation boring, stable, and easy to debug.

The app should use Apple Screen Time APIs in the smallest useful shape.

## MVP Architecture

### Main App

Responsibilities:

- Request Family Controls authorization.
- Present Family Activity Picker.
- Store selected tokens in the App Group.
- Store one daily budget.
- Start and stop one daily Device Activity monitor.
- Show Device Activity Report data in Stats.
- Show diagnostics for real-device testing.

### Device Activity Monitor Extension

Responsibilities:

- Receive interval start.
- Receive threshold reached.
- Apply the shield.
- Record tiny diagnostics to App Group.

The monitor extension should not render UI, calculate reports, load images, or do heavy work.

### Managed Settings Shield

Responsibilities:

- Apply shields to selected apps/categories/web domains.
- Clear shields when the user stops monitoring or starts a bypass.

### Shield Action Extension

Responsibilities:

- Primary action: close/stay focused.
- Secondary action: bypass, increment murkiness, start bypass cooldown.

### Device Activity Report Extension

Responsibilities:

- Read real Screen Time data.
- Show selected-app time, pickups, notifications, first pickup, and longest session.

Reports should not control blocking in the MVP.

## Reliability Rules

1. One selected token bucket.
2. One daily schedule.
3. One threshold event.
4. One shield store name.
5. One bypass cooldown.
6. No per-app rules until the core loop is proven on device.
7. No dependency on reports for enforcement.
8. Diagnostics in every important callback.

## Product Rule

The user should understand the whole product in one sentence:

> Pick the apps that pull you in, choose a daily allowance, and TimeTank shields them when the allowance is spent.

## Technical Rule

The code should be understandable in one pipeline:

```text
Selection + Budget
-> DeviceActivityCenter.startMonitoring
-> eventDidReachThreshold
-> ManagedSettingsStore.shield
-> ShieldActionDelegate
-> Bypass or close
-> App Group diagnostics
```

## Later, Not Now

- Per-app budgets.
- Schedules by time of day.
- Focus sessions.
- Widgets.
- Social accountability.
- Marketplace economy depth.
- AI recommendations.

Those can be great later. They should not enter until the core Apple API loop is reliable.
