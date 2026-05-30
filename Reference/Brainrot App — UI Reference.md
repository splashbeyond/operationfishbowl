---
tags: reference, design
---

# Brainrot App — UI Reference

**Source:** App Store screenshot (Brainrot — Screen Time tracker)

**Drop the PNG here:** `Brainrot App — UI Reference.png`

## What to borrow

- Big centered number below the mascot (score/percentage) — already applied to TimeTank as the large `% murky` display
- "Your Screen Time" list below the score showing per-app usage with time (X, Messages, YouTube, etc.) — implemented via `DeviceActivityReport` extension
- Clean white card with app icon + name on left, duration on right
- Simple dividers between rows, no heavy borders

## What NOT to copy

- Brain mascot (we have Finn)
- Overall score system (Brainrot tracks a "health" number; TimeTank tracks pollution %)
- The Brainrot color scheme — keep TimeTank warm white + tide orange
