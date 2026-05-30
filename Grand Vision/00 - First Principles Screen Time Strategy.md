# TimeTank Grand Vision: First Principles Screen Time Strategy

## The Core Problem

People do not usually need help using less of every app. They need help interrupting the small set of apps that repeatedly steal attention after the user has already decided they want that time back.

TimeTank should not become a complicated parental-control product. It should be a simple personal commitment tool:

1. The user chooses the apps that create drift.
2. The user chooses a fair daily allowance for those apps.
3. TimeTank makes the cost of crossing that boundary visible.
4. If the user keeps pushing, TimeTank creates friction through a shield.
5. The app stays local, predictable, and emotionally legible.

## First Principles

### 1. Track the Behavior That Matters

The meaningful behavior is not "phone use" in general. Maps, music, banking, messages, camera, calendar, and work tools can be healthy or necessary.

The meaningful behavior is unplanned repeat use of personally selected distraction apps.

So the default TimeTank budget should apply to selected distraction apps only, not all screen time.

### 2. One Boundary Is Stronger Than Ten

Apple Screen Time APIs are powerful but brittle when overcomplicated. A screen time app gets more reliable when it has fewer schedules, fewer token sets, and fewer edge cases.

TimeTank should start with:

- One daily distraction bucket.
- One daily time budget.
- One threshold event.
- One shield state.
- One bypass window.

No per-app budgets in the MVP. No complex schedule matrix. No bedtime mode until the core loop is proven.

### 3. Murkiness Should Mean Broken Commitment

If the water gets murky merely because the user is approaching their budget, the app can feel punitive. The user has not failed yet.

Better model:

- 0-79% of budget: water is clear.
- 80-99% of budget: water is still clear, but the UI becomes alert. Finn looks worried. Copy gets direct.
- 100% of budget: shield begins. The boundary has been reached.
- After 100%, or after bypassing the shield: murkiness increases.

Murkiness should represent "attention debt," not normal planned use.

### 4. The Shield Is a Speed Bump, Not a Cage

The shield should interrupt the automatic tap. It should ask one clear question:

> Is this worth making the water murkier?

The user can still bypass. The consequence is local, visible, and immediate.

### 5. Reports Inform; Shields Enforce

Device Activity reports should power insight:

- Selected-app time.
- Pickups.
- Notifications.
- First pickup.
- Longest session.

But enforcement should remain simple: selected distraction apps exceed daily budget, then shield.

Pickups are useful as reflection data, not a blocking trigger for MVP.

## Recommended MVP Rule

The user selects a small group of distraction apps and sets a daily comfortable allowance for that group.

TimeTank monitors only that selected group.

While usage is under the allowance, the tank remains clean.

At 80%, TimeTank warns gently.

At 100%, TimeTank shields the selected apps.

If the user bypasses, the app opens for a short window and murkiness increases.

At midnight, if the user did not bypass past the budget, the water resets clean and the user earns a Current.

## Why This Should Work

The emotional loop is clean:

**Commitment -> awareness -> boundary -> consequence -> reset**

The technical loop is clean:

**FamilyActivitySelection -> one DeviceActivity schedule -> one threshold -> one ManagedSettings shield -> one ShieldAction bypass**

The product loop is clean:

**Pick apps -> set time -> protect Finn -> earn decorations**

## What We Should Avoid For Now

- Whole-phone hard blocking.
- Per-app limits.
- Many repeating schedules.
- Punishing productive screen time.
- Making murkiness rise from every minute of ordinary use.
- Treating pickups as a blocking rule before reports are stable.
- A marketplace before the shield loop is reliable.

## Core Decision

TimeTank should be a selected-app daily budget app, not a total-phone-limit app.

Whole-phone screen time can appear as context in Stats later, but the tank should react primarily to the apps the user explicitly marked as harmful drift.
