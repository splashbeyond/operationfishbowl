# TimeTank — Brand Design

**Product:** TimeTank: Screen Time & Focus
**Platform:** iOS (Native)
**Design Language:** Bright, warm, character-driven. A living world you actually want to protect.

---

## Brand Positioning

Most screen time apps make you feel punished. TimeTank makes you feel responsible — for something you care about. Finn, your fish, lives in your tank. When you scroll too much, he suffers. When you stay focused, he thrives. The brand is warm, energetic, and a little cheeky — like a productivity app that actually knows how to have fun.

**Tagline:** Keep the water clean.

**Brand voice in three words:** Warm. Playful. Honest.

---

## Brand Personality

| Trait | What It Means in Practice |
|---|---|
| Warm | Orange-led palette, rounded type, friendly copy — never cold or clinical |
| Playful | Finn reacts, the tank breathes, animations have personality |
| Honest | No dark patterns, no guilt-shaming, no hidden subscriptions |
| Encouraging | Celebrates wins genuinely — not with hollow confetti but with a happy fish |
| Focused | Every screen has one job. Clarity over decoration. |

---

## Color System

Warm, vibrant, and rooted in orange. Two state accents mirror Finn's world: aqua for clean, amber-brown for polluted.

### Base Palette

| Name | Hex | Role |
|---|---|---|
| Pure White | `#FFFFFF` | Primary backgrounds, card surfaces, overlays |
| Warm White | `#FFF8F2` | App background — very slightly warm, never cold |
| Peach Foam | `#FFE8D6` | Section fills, input backgrounds, subtle card tint |
| Tide Orange | `#FF6B2B` | Hero color — CTAs, Finn's body, active states, brand mark |
| Coral | `#FF8C61` | Secondary accent — hover states, tag chips, mascot highlights |
| Text Dark | `#1C1A18` | All primary text — warm near-black, never pure `#000000` |
| Text Muted | `#857975` | Labels, timestamps, secondary copy |

### State Accents (Finn's World)

| State | Hex | Name | Usage |
|---|---|---|---|
| Healthy | `#00BFA5` | Tank Teal | Clean water, healthy state, Finn at full speed |
| Healthy glow | `#E0FAF5` | Mist | Healthy-state card backgrounds, tank border glow |
| Warning (80%) | `#FFAB40` | Amber | Budget nearly spent, Finn slowing down |
| Polluted | `#B5651D` | Muddy Brown | Water at 100% pollution, murky tank fill |
| Pollution surface | `#F5CBA7` | Murky Peach | Pollution-state water tint at 50% — yucky but not scary |
| Currents badge | `#FF6B2B` at 15% opacity | Peach glow | Currents balance badge background |

### 60-30-10 Distribution

- **60%** — Pure White / Warm White `#FFF8F2` (all backgrounds)
- **30%** — Peach Foam `#FFE8D6` + white card surfaces (sections, cards, UI chrome)
- **10%** — Tide Orange `#FF6B2B` (CTAs, Finn, active states, brand marks only)

**Rule:** Orange is the hero. It earns every appearance — primary buttons, active tabs, Finn's body, the brand wordmark. Never used as a background wash.
**Rule:** Tank Teal appears only inside the fishbowl and healthy-state indicators. It's Finn's color, not the brand's.
**Rule:** Text Dark `#1C1A18` on Pure White passes WCAG 4.5:1 — verified.

### The Pollution Gradient (Canvas Only)

Used exclusively inside the SwiftUI Canvas fishbowl renderer. Never in UI chrome.

```
0%   pollution → #00BFA5  (bright aqua — crystal clear)
25%  pollution → #4DD0B8  (slightly muted teal)
50%  pollution → #FFAB40  (amber murk — Finn is worried)
75%  pollution → #D4895E  (muddy warm brown)
100% pollution → #B5651D  (murky brown — Finn is struggling)
```

The tank never goes black. Pollution is yucky, not terrifying — keeping the tone approachable.

---

## Typography

Single-family system. Nunito carries the entire app — rounded, warm, energetic at every weight. DM Mono is the one exception: used only for budget numbers and time metrics to give data a precise, readable feel.

| Use | Font | Weight | Size |
|---|---|---|---|
| App wordmark | Nunito | ExtraBold 800 | 28px |
| Screen titles | Nunito | ExtraBold 800 | 26–30px |
| Section headers | Nunito | Bold 700 | 18–20px |
| Body / UI copy | Nunito | Regular 400 | 15–16px |
| Button labels | Nunito | SemiBold 600 | 15px |
| Tags / chips / labels | Nunito | SemiBold 600 | 12px, tracked +40 |
| Budget numbers / time | DM Mono | Bold 700 | 40–56px (display scale) |
| Secondary data | DM Mono | Regular 400 | 14–16px |

**Why Nunito:** Rounded letterforms signal warmth and approachability without feeling childish. Bold weights have real visual impact. Scales cleanly from 12px labels to 30px hero titles without losing personality. Used by Duolingo, Headspace, and other top-tier consumer wellness apps.

**Why DM Mono for data:** The contrast between Nunito's rounded body copy and DM Mono's clean monospace makes budget numbers feel precise and real — the one moment in the app where things get serious.

**Rules:**
- Never use Nunito below 12px.
- Budget numbers in DM Mono only — not Nunito.
- Letter-spacing on all-caps labels: +40 minimum.
- Line height: 1.5× for body, 1.2× for display titles.

---

## Mascot — Finn

Finn is a small, geometric vector fish who lives in your tank. He is the emotional core of TimeTank — the reason you care about keeping the water clean.

### Character Design

- **Shape:** Simple geometric form — a rounded body, triangular tail fin, single circular eye. Clean vector paths only. No gradients in the base character.
- **Base color:** Tide Orange `#FF6B2B` body, Coral `#FF8C61` fin tips and tail edges.
- **Eye:** White circle, small dark pupil. Expressive — this is where his emotion lives.
- **Style:** Flat 2D vector. Consistent with the fishbowl Canvas rendering. Not 3D, not illustrated-realism.

### Finn's States

| State | Tank Pollution | Finn's Appearance | Animation |
|---|---|---|---|
| Thriving | 0% | Bright orange, eye wide, fins perky | Fast, sweeping bezier arcs |
| Cruising | 1–40% | Normal coloring | Normal speed, relaxed paths |
| Worried | 41–70% | Slightly muted, fins drooping slightly | Slower, shorter paths |
| Struggling | 71–90% | Dull orange, eye squinted | Very slow, tight circles |
| Exhausted | 91–100% | Grayish-orange, eye half-closed | Nearly still, small idle drift |

### Finn's Expressions (Keyframe States)

Used on specific UI screens (not in the tank renderer):

- **Happy Finn** — onboarding complete, clean day earned, Currents received
- **Curious Finn** — onboarding picker (selecting apps), settings
- **Worried Finn** — 80% budget warning card, widget at 80%+
- **Sad Finn** — shield intercept screen (the "speed bump" moment)
- **Sleeping Finn** — empty state, app idle overnight

### Finn's Name Visibility

Finn is mentioned by name in:
- Onboarding ("This is Finn. He lives in your tank.")
- App Store subtitle ("Meet Finn. Keep his tank clean.")
- Marketplace intro copy ("Finn's looking good. Spend your Currents.")

Finn is never named in data screens, stats, or budget settings — those stay clean and functional.

---

## Logo

**Wordmark:** TIMETANK — Nunito ExtraBold 800, tracked +20, all caps. Written as one word, no space.

**Icon mark:** A circle (the tank, viewed front-on) with Finn's silhouette swimming inside it. Finn is centered, facing right. The circle has a 2px stroke in Tide Orange `#FF6B2B`. No fill on the circle — Finn sits on white.

**App Icon:**
- Background: Tide Orange `#FF6B2B`
- Finn silhouette: `#FFFFFF` white, simplified to 3–4 paths
- The tank circle: white 2px stroke inside the icon bounds
- Result: instantly readable at 60px, distinctive on the home screen

**Don'ts:**
- No drop shadows on the wordmark
- No gradient fills on the icon mark
- Never place the wordmark on an orange background (no contrast)
- Never distort Finn's proportions — he should always look like himself

---

## Voice & Tone

Warm and direct. Finn gives the app personality; the copy stays clean and clear. Not saccharine. Not corporate. Like a friend who genuinely wants you to put your phone down.

### Copy Examples

| Screen | Copy |
|---|---|
| Onboarding step 1 | "Pick the apps that eat your time." |
| Onboarding step 2 | "How long is fair? Set Finn's budget." |
| Budget confirmed | "Got it. 45 minutes. Finn's counting on you." |
| Clean day, midnight | "Clean day. Finn's happy. +1 Current earned." |
| Budget at 80% | "Finn's looking a little anxious. 9 minutes left." |
| Shield intercept | "Your budget is spent. Finn's watching. Open anyway?" |
| Shield bypass | "The water just got murkier." |
| Marketplace | "Finn earned these. Make the tank beautiful." |
| No apps selected | "Pick something. Finn needs a reason to care." |
| All budgets respected for 7 days | "One week clean. Finn's doing backflips." |

**Rules:**
- Finn is always lowercase ("finn" is wrong — he's a proper character, capitalize always)
- Short sentences. No semicolons in UI copy.
- Avoid "amazing," "incredible," "you're crushing it" — be specific instead
- Humor is allowed but never at the user's expense

---

## UI Patterns

### The Fishbowl (Hero Element)

Full-width SwiftUI Canvas. The centrepiece of Tab 1.

- **Healthy:** Bright aqua `#00BFA5` water, animated sine wave at the top, Finn swimming fast on overlapping bezier arcs
- **50% polluted:** Amber-murky water `#FFAB40`, Finn visibly slower, tank border shifts from teal to amber
- **100% polluted:** Muddy brown water `#B5651D`, Finn near-still, small worried-eye expression state fires

The bowl outer ring: 2px stroke, Tide Orange `#FF6B2B` at 30% opacity. Slightly more visible than before.

### Cards

White `#FFFFFF` surface. 12px border radius. Subtle drop shadow: `0 2px 8px rgba(0,0,0,0.07)`. Peach Foam `#FFE8D6` border at 1px.

```
┌────────────────────────────────┐
│  TODAY'S BUDGET                │  ← Nunito SemiBold 600, 11px, muted, tracked +60
│  45 min                        │  ← DM Mono Bold, 48px, Text Dark
│  ────────────────────────      │
│  23 min remaining              │  ← Nunito Regular 400, 14px, muted
│  ████████████░░░░ 51%          │  ← progress bar — teal fill, peach track
└────────────────────────────────┘
```

### Bottom Navigation

5 tabs. Icon + label. Active tab: Tide Orange icon + label, 2px Tide Orange underline. Inactive: muted gray.

| Tab | Icon | Label |
|---|---|---|
| 1 | Finn silhouette in circle | Tank |
| 2 | Clock | Budget |
| 3 | Bar chart | Stats |
| 4 | Coin | Currents |
| 5 | Gear | Settings |

### Buttons

**Primary CTA:** Tide Orange `#FF6B2B` background, Pure White text, Nunito SemiBold 600, 15px, 12px border radius, full-width. Drop shadow: `0 4px 12px rgba(255,107,43,0.30)` — the orange glow.

**Secondary:** White background, Tide Orange border 1.5px, Tide Orange text.

**Destructive / Bypass:** Coral `#FF8C61` background, white text. Used on Shield "Open Anyway" only. Softer than a hard red — the app doesn't shame.

**Haptic:** `.medium` impact on primary CTA tap. `.light` on secondary.

### Shield Screen (Speed Bump)

Warm White `#FFF8F2` full-screen. Sad Finn illustration centered at 120px. Rounded bottom sheet style, not a harsh full takeover.

```
          [Sad Finn — 120px]

     Your budget is spent.
  Finn's watching. Open anyway?

[Stay Focused]        [Open Anyway]
Orange primary        Coral secondary
```

Nunito Bold 700 for the headline. Nunito Regular 400 for the subtext. Two lines max.

### Progress Bar (Budget Meter)

Track: Peach Foam `#FFE8D6`, 6px height, 3px radius.
Fill: Teal `#00BFA5` from 0–79%, shifts to Amber `#FFAB40` from 80–99%, Muddy Brown `#B5651D` at 100%.

---

## Competitive Differentiation

| | TimeTank | BrainRot | Opal |
|---|---|---|---|
| Mascot | Finn the fish (vector, reactive) | Decaying brain cartoon | None |
| Palette | Bright orange + white + teal | Playful / mixed | Clean white / blue |
| Pollution mechanic | Muddy water, Finn struggling | Mascot decay | Streaks / circles |
| Tone | Warm + encouraging | Humorous / guilt-adjacent | Minimal / clinical |
| Target user | Anyone who wants to care about focus | Gen Z / casual | Productivity-minded |

**TimeTank's gap:** The only screen time app that makes you feel genuine warmth toward your own focus habit — because you're protecting something alive.

---

## Anti-Patterns (never)

- [ ] Cold / blue-white backgrounds — always warm white `#FFF8F2` base
- [ ] Pure black text — always Text Dark `#1C1A18`
- [ ] Orange used as a background wash or section fill
- [ ] Finn looking mean, aggressive, or exaggeratedly sad — keep it gentle
- [ ] Gradients on the wordmark or button backgrounds
- [ ] Pollution state using black or dark gray water — it should look gross, not scary
- [ ] Font sizes below 12px anywhere in the UI
- [ ] Nunito used for budget numbers — DM Mono only for data display
- [ ] Dark mode (TimeTank is a light-mode app — the bright palette is the product)

---

## App Store Brand Presence

**App Name:** TimeTank: Screen Time & Focus
**Subtitle:** Meet Finn. Keep his tank clean.
**Category:** Productivity
**Screenshots:** Bright white backgrounds, real UI, Finn prominently visible in the tank hero shot. One screenshot showing tank at 100% pollution (muddy but cute). One showing the marketplace. One showing the shield screen.
**Keywords:** screen time, focus, app blocker, fish, mascot, digital wellness, time budget, productivity, habit
**App Icon feeling:** Immediately warm, immediately distinctive. Finn on orange — impossible to miss.




Mascot:  (His name is Finn)
![[ChatGPT Image May 28, 2026, 09_33_54 PM.png]]
Finn's Bowl Only:
![[ChatGPT Image May 28, 2026, 10_40_56 PM.png]]


Finn in his bowl:

![[ChatGPT Image May 28, 2026, 09_55_29 PM.png]]
IOS Icon:
![[TimeTank IOS Icon.png]]