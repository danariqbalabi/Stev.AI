# Stev.AI motion spec

Every animation in the prototype is listed here with exact timing. Durations and curves also live in `StevMotion` (`stev_tokens.dart`).

**Curves (CSS → Flutter):**

| Name | CSS | Flutter | Feel |
|---|---|---|---|
| outExpo | `cubic-bezier(.16,1,.3,1)` | `Cubic(0.16, 1, 0.3, 1)` | Fast start, long soft landing |
| outBack | `cubic-bezier(.34,1.56,.64,1)` | `Cubic(0.34, 1.56, 0.64, 1)` | Small overshoot |
| jump | `cubic-bezier(.2,1.4,.4,1)` | `Cubic(0.2, 1.4, 0.4, 1)` | Bouncy |
| ease-out / ease-in / ease-in-out | same | `Curves.easeOut` / `easeIn` / `easeInOut` | Identical in Flutter |

**Rule:** no animation package is needed. Use `AnimationController` + `Tween`/`TweenSequence` + `Interval` for staggers, or `TweenAnimationBuilder` for one-shots.

## A. Everywhere

| # | Name | Trigger | Spec | Flutter hint |
|---|---|---|---|---|
| A1 | Screen fade | Any screen appears | Opacity 0→1, **280 ms**, easeOut. No slide. | `CustomTransitionPage` in go_router with `FadeTransition` |
| A2 | 3D press | Pointer down on any button, chip, row, or scan button | Moves **down 5 px** (4 px for card-edge buttons) and the hard bottom shadow disappears. **80 ms**. Releases back the same way. | `GestureDetector` onTapDown/Up/Cancel → `AnimatedContainer` (margin/transform + boxShadow) |
| A3 | Stev breathe | Always, on idle mascots (Home card, Weekly card, Onboarding) | translateY 0 → −2 → 0, **2.4 s** loop, easeInOut | `controller.repeat(reverse: true)` with period 1.2 s each way |

## B. Onboarding

| # | Name | Spec |
|---|---|---|
| B1 | Wave | The mascot wrapper rocks forever around its **bottom center**: rotate −2° / y 0 → rotate +3° / y −4 → back. **1.5 s** loop, easeInOut. It runs together with A3 on the inner mascot. |

## C. Home

| # | Name | Trigger | Spec |
|---|---|---|---|
| C1 | Scan pulse | Home appears | Scan button scale 1 → 1.06 → 1, **900 ms**, easeInOut, **delay 450 ms**, plays **once**. |
| C2 | Logged row in | Home appears right after a drink was logged | The new first row drops in: translateY −16 → 0 + fade, **400 ms**, easeOut. |
| C3 | Spoons refill | Same moment as C2 | Every spoon's sugar rect scales Y 0 → 1 from the **bottom**, **500 ms**, easeOut. Spoons that just became red fill red. |

## D. Result: entrance timeline

t = 0 is when Result appears.

```
0 ms      ├─ screen fade (A1, 280 ms)
0 ms      ├─ spoon 1 appears ─┐  each spoon: opacity 0→1, translateY 12→0, scale .92→1
80 ms     ├─ spoon 2 appears  │  320 ms, outBack
160 ms    ├─ spoon 3 appears  │  sugar inside each spoon: scaleY 0→1 from bottom,
240 ms    ├─ spoon 4 appears  │  420 ms, easeOut, same delay as its spoon
320 ms    ├─ spoon 5 appears ─┘  (stagger 80 ms; spoons 6+ start at 0 ms like spoon 1)
0–500 ms  ├─ number counts up 0 → grams, LINEAR, rounded to int each frame
540 ms    ├─ Stev wobble: rotate 0 → −7° → +7° → −5° → 0 (keys at 0/25/50/75/100%), 520 ms, easeInOut
1100 ms   └─ Stev breathe starts (A3), forever
```

| # | Name | Trigger | Spec |
|---|---|---|---|
| D1 | Level change | User taps Normal / Less / No | Grams change **instantly** (no count-up). The spoon row is rebuilt with a new key, so D-timeline spoon appear + sugar rise **replay**. The selected option's level icon **pops**: scale .78 → 1.15 (at 65%) → 1, **260 ms**, outBack. |
| D2 | Swap haptic | Tap Swap | `HapticFeedback.lightImpact()` (prototype: vibrate 10 ms), then open Reward. |

Flutter hints for Result:

- **Spoons:** one controller of 320 + 4×80 = 640 ms. Each spoon uses `Interval(i*80/640, (i*80+320)/640, curve: outBack)`, and its sugar uses the same start with a 420 ms length (clamp the end to 1.0).
- **Count-up:** `TweenAnimationBuilder<double>(tween: Tween(begin: 0, end: g), duration: 500ms, curve: Curves.linear)`, display `value.round()`. Use tabular figures.
- **Wobble:** a `TweenSequence<double>` of rotations [0, −7, 7, −5, 0]° with equal weights.

## E. Reward popup timeline

t = 0 is the Swap tap. The overlay itself appears **instantly** (no fade in the prototype).

```
0 ms       ├─ Stev JUMP: opacity 0→1, translateY +70→0, scale .65→1, 550 ms, curve jump
0 ms       ├─ confetti (only if saved ≥ 12.5 g), see E2
150 ms     ├─ odometer roll, 1200 ms, outExpo  → ends at 1350 ms
650 ms     ├─ Stev breathe starts (y 0 → −2 → 0, 2.4 s loop)
650 ms     ├─ message rises:   translateY 18→0 + fade, 450 ms, easeOut
800 ms     ├─ drink card rises: same, 450 ms
900 ms     └─ button rises:     same, 450 ms
```

### E1. Odometer (e.g. "36 → 22")

- **Digits:** both numbers are padded to 2 digits ("30" → [3,0], "10" → [1,0]).
- **Columns:** each digit position is its own column. A column **counts down** from the old digit to the new one, wrapping 0 → 9. Build the list by starting at `from`, adding digits with `d = (d + 9) % 10` until you reach `to` (max 10 items).
  - 30 → 10: tens column `[3, 2, 1]`, ones column `[0]` (static).
  - 36 → 22: tens `[3, 2]`, ones `[6, 5, 4, 3, 2]`.
- **Window:** 58 × 88 and clipped. A vertical fade mask hides the top and bottom 18%: transparent → black 18% … black 82% → transparent. Use `ShaderMask` + `LinearGradient`.
- **Motion:** the column translates up by `(count − 1) × 88` px, **1200 ms**, delay 150 ms, outExpo.
- **Accessibility:** the screen reader only gets the final value ("10 gram"). The rolling digits are hidden from it.

### E2. Confetti

- **When:** only when the saving is ≥ 12.5 g.
- **Pieces:** 12, each 10 × 18 with radius 3. Each starts 24 px above the top at `left%` and falls **380 px** while rotating from its start angle to **440°**. The animation is **900 ms**, easeIn, with delay = `delayUnit × 18 ms`. They are not removed; they end off-screen.

| color | left % | delayUnit | start ° |
|---|---|---|---|
| sun | 8 | 13 | −12 |
| leaf | 26 | 7 | 14 |
| sugar | 42 | 4 | −8 |
| sun | 56 | 10 | 8 |
| leaf | 72 | 5 | −16 |
| sugar | 87 | 13 | 13 |
| leaf | 16 | 22 | 10 |
| sun | 34 | 17 | −13 |
| sugar | 64 | 20 | 14 |
| sun | 92 | 24 | −8 |
| sugar | 5 | 30 | 15 |
| leaf | 82 | 32 | −12 |

## F. Log flight ("Aku pilih ini" / "Simpan")

1. **Log and navigate:** log the drink and **immediately** show Home.
2. **Thumbnail flight:** an overlay thumbnail of the drink photo (84 × 84, radius 14, 3 px white border, elevFloat) flies to where the **first drink row's photo** will be.
   - **Start:** prototype frame (x 153, y 430), which is the screen center around the old button area.
   - **Keyframes:**
     - 0%: scale 1.2 at the start.
     - 70%: at the target, scale 1.
     - 100%: still at the target, opacity 0.
   - **Timing:** **560 ms**, outExpo.
   - **Flutter:** compute the target from a `GlobalKey` on the first row instead of hardcoding (−133, +138).
3. **Home reacts:** at the same time Home plays C2 (row drops in) and C3 (spoons refill).
4. **Guard:** ignore further log taps until the flight finishes (560 ms, or 150 ms with reduced motion).

## G. Weekly

| # | Name | Spec |
|---|---|---|
| G1 | Bars grow | On appear, every bar scales Y 0 → 1 from the **bottom**, **600 ms**, outExpo, all at once (no stagger). |

## H. Reduced motion (required)

When `MediaQuery.disableAnimationsOf(context)` is true:

- Every entrance animation (screens, spoons, sugar rise, rows, bars, level pop, reward texts, log flight) becomes a **150 ms fade** with no movement.
- **Confetti is off.** The **scan pulse is off.** **Loops** (breathe, wave) play once or not at all.
- The **odometer** shows the final number directly. The **count-up** shows the final number directly.
- **Press** feedback doesn't move the button. The shadow may still disappear.
