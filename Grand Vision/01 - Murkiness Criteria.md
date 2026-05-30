# Murkiness Criteria

## What Murkiness Means

Murkiness is the visual state of broken intention.

It should not mean "you used your phone." It should mean "you crossed the boundary you personally set."

## Proposed State Model

| Budget State | Usage Range | Tank State | User Meaning |
|---|---:|---|---|
| Clean | 0-79% | Clear teal water | You are within your plan. |
| Warning | 80-99% | Clear water, warmer UI, worried Finn | You are close. Choose carefully. |
| Spent | 100% | Shield begins | Your planned allowance is gone. |
| Bypassed | 100%+ and user opens anyway | Murkiness increases | You made an intentional exception. |
| Recovered | Next day | Water resets | New day, no shame spiral. |

## Pollution Formula

For MVP, keep pollution event-based:

- Crossing the budget: set pollution to 20%.
- Each shield bypass: add 20%.
- Maximum pollution: 100%.
- Clean day reset: pollution returns to 0%.

This is easier to understand than a continuous formula and more reliable than trying to sync visual state to real-time reports.

Later, after reports are stable, we can test continuous overflow:

```text
overflowMinutes = max(0, selectedAppMinutes - dailyBudgetMinutes)
pollution = min(1.0, overflowMinutes / dailyBudgetMinutes)
```

But MVP should use event-based pollution because the system callback is the reliable source of truth for enforcement.

## Why Not Murky Before the Limit?

Approaching the limit is not a failure. It is planned use.

The app should preserve trust by only making the water dirty when the user crosses or bypasses the boundary.

## What the User Should Feel

Before the limit:

> I still have agency.

At the shield:

> I said this mattered. Do I really want to continue?

After bypass:

> I can choose this, but it changes the tank.

Next day:

> I get to start clean again.
