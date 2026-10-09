# Stev.AI design system

This is the single source of truth for how Stev.AI looks. Every value here comes from the final Figma Make prototype (https://oval-long-86495241.figma.site). Read it next to:

- `SCREENS.md`: layout of every screen.
- `MOTION.md`: every animation.
- `DATA.md`: dummy data and app logic.

Tokens live in `lib/core/theme/stev_tokens.dart`. Widgets read from there and never hardcode hex values or sizes.

## 1. Product in one paragraph

Stev.AI shows Gen Z how much sugar a drink has **before they buy it**, and offers a lower-sugar **swap** on the spot. The core loop:

1. Scan.
2. Confirm the drink.
3. See sugar as spoons.
4. Swap or keep.
5. Log it.
6. Home updates.

Sugar is shown in **grams and spoons**:

- 1 spoon = 1 tablespoon = 12.5 g.
- The daily reference is 50 g = 4 spoons (Permenkes 30/2013).
- Estimates for non-packaged drinks always carry a `≈` prefix.
- The app never diagnoses.

## 2. Design principles

1. **Cal AI structure, Duolingo playfulness (light).** Calm, white, roomy layouts. Delight comes from the mascot and motion, not from colored cards.
2. **One hero number per screen.** Home shows the daily total, Result shows the drink's grams, Reward shows the new grams. Everything else is quieter.
3. **Sugar is a spoon, not a chart.** Spoons fill with orange sugar. Spoons past 50 g turn red.
4. **Neutral surfaces, color only means something.**
   - Orange = sugar.
   - Red = over the limit.
   - Green = the good action (Swap, reward CTA).
   - Ink black = primary navigation.
   - No decorative colored cards.
5. **Glass, not boxes.** The tab bar, bottom sheets, and home cards are frosted glass over soft blurred "auras". Solid white is reserved for cards that hold key data (the sugar card, guess cards).
6. **Real photos, full-bleed.** Drink photos fill their slot edge to edge, with the background kept. Packaged products use `contain`, glasses and cups use `cover`.
7. **3D press buttons.** Buttons have a hard bottom edge (shadow, 0 blur). On press they move down by that edge and the edge disappears. No Material ripples.
8. **No over-explaining.** No helper captions under obvious things. Labels are short Indonesian, casual "kamu".
9. **Tabular numbers everywhere.** Digits must not jump during count-ups.
10. **Motion has a job.** Every animation explains a change in sugar, confirms an action, or rewards a swap. All of them respect reduced motion.

## 3. Foundations

### Color

| Token | Hex | Use |
|---|---|---|
| canvas | #F5F5F7 | App background |
| card | #FFFFFF | Solid data cards |
| glass | #FFFFFF @72% | Tab bar, bottom sheets |
| glassCard | #FFFFFF @55% | Glass cards on canvas, inputs, chips |
| glassEdge | #FFFFFF @90% | 1px border on all glass |
| auraLeaf / auraSugar / auraSun | #34D07F @34% / #E07008 @20% / #FFD23F @34% | Blurred background blobs |
| ink | #111113 | Text, dark buttons, scan button, chart bars |
| ink2 | #6E6E73 | Secondary text, units |
| ink3 | #C7C7CC | Empty states, dashed past days |
| leaf / leafEdge | #34D07F / #1FA862 | Good action button and its 3D edge |
| sugar | #E07008 | Sugar inside spoons |
| over | #D93036 | Over the limit |
| spoonBowl | #DCDCE1 | Empty spoon bowl |
| night | #111113 @94% | Reward popup background |
| sun | #FFD23F | Confetti only |

### Type

The font is **Onest**, in weights 500, 600, 700 and 800. Every numeral uses `FontFeature.tabularFigures()`.

| Style | Size / line | Weight | Tracking | Where |
|---|---|---|---|---|
| rewardNumber | 88/88 | 800 | -0.04em | Reward odometer |
| heroCard | 72/72 | 800 | -0.04em | Result grams |
| number | 64/64 | 800 | -0.03em | Home total, weekly saved |
| title | 28/34 | 800 | -0.02em | Reward message, onboarding step title |
| onboardingTitle | 24/30 | 800 | -0.02em | "Lihat gula sebelum kamu beli." |
| logo | 22 | 800 | -0.02em | "Stev.AI" next to the mark |
| headingResult | 22/28 | 700 | -0.01em | Drink name on sheets |
| heading | 20/26 | 700 | -0.01em | Section headings, inner screen titles |
| label | 16/22 | 600 | 0 | Drink names, inputs |
| button | 17/22 | 700 | 0 | Buttons |
| listGrams | 17 | 700 | 0 | "18 g" at the end of rows |
| body | 15/20 | 600 | 0 | "Waduh, lewat 12 g!" |
| caption | 13/18 | 600 | 0 | Captions, chips (usually ink2) |
| micro | 11/14 | 600 | 0 | Tab labels, week letters, chart labels |

Units are smaller and grey, next to the number: "32" in ink with "/50 g" in ink2 22px; "30" with "g" in ink2 28px.

### Spacing and radius

- **Spacing scale:** 4, 8, 12, 16, 20, 24, 28, 40, 56.
- **Screen side padding:** 20.
- **Content top padding** below the status bar: 56.
- **Bottom padding** above the tab bar: 112.

| Radius | Value | Where |
|---|---|---|
| small | 14 | Small links, stepper buttons |
| button | 20 | 56px buttons, inputs, level picker |
| row | 22 | Drink rows, guess cards |
| card | 28 | Big cards |
| sheet | 36 | Top corners of bottom sheets |
| pill | 999 | Chips, round buttons |

### Elevation

| Name | Value | Where |
|---|---|---|
| elevCard | `0 1 2 ink@4%` + `0 12 32 -8 ink@10%` | All cards |
| elevFloat | `0 14 32 -6 ink@30%` | Scan button |
| elevGlass | `0 -10 30 -12 ink@12%` | Upward shadow on tab bar and sheets |
| pressLeaf | `0 5 0 #1FA862` | Leaf button edge |
| pressCard | `0 4 0 #E1E1E6` | White button edge |
| pressInk | `0 5 0 ink2` | Dark button edge |

### Glass recipe (Flutter)

```dart
ClipRRect(
  borderRadius: BorderRadius.circular(StevRadius.card),
  child: BackdropFilter(
    filter: ImageFilter.blur(sigmaX: 28, sigmaY: 28), // CSS also adds saturate(180%) — optional
    child: DecoratedBox(
      decoration: BoxDecoration(
        color: StevColors.glassCard,            // or StevColors.glass for bars/sheets
        borderRadius: BorderRadius.circular(StevRadius.card),
        border: Border.all(color: StevColors.glassEdge),
        boxShadow: StevShadows.elevCard,
      ),
      child: ...,
    ),
  ),
)
```

Some rules for the glass:

- **The glass needs something behind it to blur.** Every canvas screen (Home, Weekly, Onboarding, Cari manual, Tambah) has the **aura layer** behind the content. The aura layer is 4 blurred circles; positions are in SCREENS.md §0.
- **A cheaper aura is fine.** On Flutter web, a `RadialGradient` circle (color fading to transparent) looks the same as `blur(70)` and is much cheaper.
- **Keep BackdropFilter count low**: the tab bar, one sheet, and a few cards. Don't wrap every row.

## 4. Components

All measurements are logical px at a 390-wide screen.

### Logo
- **Mark:** `assets/brand/logo_mark.svg`, shown at 30×30.
- **Wordmark:** "Stev.AI" in `StevType.logo`, 10px to the right of the mark.

### Stev (mascot)
- **Mascot:** a sugar cube with arms, in `assets/brand/stev_{happy,cheer,worried}.svg`.
  - `stev_cheer_on_dark.svg` is for the reward popup; its raised arms are white.
- **Moods:**
  - **happy:** default.
  - **worried:** Home total > 50 g, or the drink pushes over 50 g. It has a sweat drop and wavy mouth.
  - **cheer:** onboarding and reward.
- **Sizes:** home card 92, result 76, reward 150, onboarding 184.
- **Idle:** always gently "breathes" (see MOTION.md).

### Spoon (`lib/shared/widgets/spoon.dart`)
- **Shape:** a flat two-tone spoon. Ink handle (ink3 when empty), grey bowl, and orange sugar filling the bowl from the bottom. Over-limit spoons are filled red.
- **Size:** width 46 on Home, 40 on Result; height = width × 2.5.
- **Home meter:** always 4 spoons, plus 1 red spoon per extra 12.5 g over 50. The spoons are spread with space-between, pinned 21px from the bottom of the daily card, and inset 27px left/right.
- **Result:** `max(1, ceil(g/12.5))` spoons, centered, 16px gap, row height 100.

### Level icon
- **Shape:** 3 small rounded cubes (11×11, radius 3.2, stroke 1.8), filled ink up to the level; empty ones are white with an ink3 stroke.
- **Levels:**
  - 3 = Normal
  - 2 = Less
  - 1 = Low
  - 0 = No
- **Size:** drawn 32×14.
- **Shown:** under the drink name when the drink has a sugar level (non-packaged drinks).

### Drink row
- **Container:** a glass card, height 84, radius 22, clipped.
- **Columns:**
  - **Photo:** 84×84 full-bleed on the left, no padding. Fit and position come from the data.
  - **Name:** label 16/600, left padding 16. The level icon sits under it with a 3px gap.
  - **Grams:** listGrams 17/700, right padding 18. Prefixed with `≈` when estimated.
- **Spacing:** rows stack with a 12px gap.

### Buttons (56 high, radius 20, label 17/700)

| Variant | Fill | Text | Edge | Use |
|---|---|---|---|---|
| primary | leaf | ink | pressLeaf | Swap, reward "Aku pilih ini" |
| secondary | card | ink | pressCard + elevCard | "Aku pilih ini" on Result, Simpan |
| dark | ink | onInk | pressInk | Onboarding "Mulai" |
| ghost | none | ink2 | none | "Lewati" (44 high) |

- **Press:** `translateY(5)` and remove the edge, over 80ms. Use a `GestureDetector` with `onTapDown`/`onTapUp` driving an `AnimatedContainer` or `AnimatedSlide`.
- **Swap icon:** `assets/icons/swap.svg` sits 22px to the left of the label, with an 8px gap.

### Scan button (center of the tab bar)
- **Shape:** a 68px ink circle with a 3px white border and elevFloat, holding a white scan icon at 28px.
- **Position:** sticks up 24px above the tab bar.
- **Home pulse:** pulses once on Home (MOTION.md).
- **Press:** translateY 5.

### Tab bar
- **Container:** height 92, glass (72%), top border glassEdge, elevGlass. It sits at the bottom over the content.
- **Columns:** `1fr | 92 | 1fr`.
  - **Left:** Beranda (home icon).
  - **Center:** scan button.
  - **Right:** Mingguan (bars icon).
- **Tabs:** a 24px icon (stroke 2) over a micro label, starting 16px from the top. Active tabs are ink, inactive ink2.

### Glass round button (on photos)
- **Shape:** 46px circle, white 28% fill, blur 20, 1px white@50% edge, `0 4 0 white@24%` bottom edge.
- **Icon:** white chevron at 25px.

### Inner back button (on canvas)
- **Shape:** 46px glass circle with pressCard + elevCard, and an ink chevron at 24px.

### Bottom sheet (Confirm, Result)
- **Shape:** glass 72%, top radius 36, top border glassEdge, elevGlass.
- **Position:** pinned to the bottom, over a photo that fills the top 430px.

### Sugar card (Result)
- **Container:** solid white, radius 28, elevCard, height 290, padding `22 / 20 / 50`, content centered.
- **Contents, top to bottom:**
  1. Spoons row.
  2. The number: heroCard, with `≈` in the same size if estimated, then a grey "g".
  3. The warning line.
- **Mascot:** Stev (76px) is centered and hangs 39px **below** the card's bottom edge, half outside.

### Level picker (Result, non-packaged only)
- **Container:** a 76-high segmented control on canvas grey, radius 20, padding 4, 3 equal options.
- **Options:** level icon over a micro label: Normal / Less / No.
- **Selected:** white fill, pressCard edge, ink text. Unselected options are ink2.

### Reward popup
- **Container:** full-screen overlay in night 94% with blur 14, padding top 148.
- **Contents, top to bottom:**
  1. Stev cheer, on-dark version, 150px.
  2. Odometer number: 88px with a grey "g" at 28px.
  3. "Mantap, hemat X g!" in title.
  4. New drink card: 76 high, white 8% fill, white 14% border, radius 22, photo 76×76, name, grams.
  5. A primary leaf button pinned 40 from the bottom.

### Chips
- **Time and category chips:** pill, glassCard fill, pressCard edge, caption 13/600 in ink2. Time chips are 48 high, category chips 40.
- **Active:** ink fill, onInk text, `0 4 0 ink2` edge.

### Inputs
- **Shape:** height 56–58, glassCard fill, glassEdge border, radius 20, blur 28, label 16/600, placeholder in ink2.
- **Field label:** caption 13/600 above, with an 8px gap.

### Week strip (Home)
- **Layout:** 7 columns, height 66: a micro letter over a 36px date circle.
  - **Past:** dashed ink3 circle border.
  - **Today:** filled ink circle, white date.
  - **Future:** plain ink2.

### Weekly chart
- **Card:** glass, height 350, padding 28.
- **Header:** title "Gula harian", with Stev happy (92px) peeking out 28px above the top-right corner.
- **Bars:** 7 columns in a 210-high track, ink bars 22 wide with radius `8 8 4 4`. Over-50 bars are red; empty days show nothing.
- **Limit line:** dashed ink2 at the 50 g line, labeled "50 g" in micro on the right. The y-scale max is 60 g.

## 5. Copy and voice

The voice is casual Indonesian ("kamu"), short, and positive. It never shames and never diagnoses.

| Where | Copy |
|---|---|
| Onboarding 1 | "Lihat gula sebelum kamu beli." · button "Mulai" |
| Onboarding 2 | "Kenalan dulu, yuk." · "Nama kamu" (placeholder "Tulis nama") · "Biasanya beli minum jam berapa?" (Pagi / Siang / Sore / Malam) · "Mulai" · "Lewati" |
| Home | "Gula hari ini" · "Hari ini" |
| Camera | "Scan minuman" · "Cari manual" |
| Confirm | "Ini minuman apa?" · "Pilih yang paling cocok" · badge "Paling cocok" · "Bukan ini? Cari manual" |
| Result | "Hasil scan" · "Waduh, lewat **12 g**!" (red number) or "Masih aman, nih!" · "Aku pilih ini" · "Swap" |
| Reward | "Mantap, hemat X g!" · "Aku pilih ini" |
| Weekly | "Minggu ini hemat" · "46 g" · "lewat swap" · "Gula harian" |
| Cari manual | "Cari minuman" · chips Kemasan / Kopi / Teh / Boba / Jus · "+ Tambah minuman" |
| Tambah minuman | "Nama minuman" (placeholder "Contoh: Es kopi susu") · "Sendok gula" · "Pump sirup" · "Simpan" |

**Words to avoid:** "diabetes" in the UI, "bahaya", "sehat/tidak sehat", diet language, red screens.

## 6. Accessibility

- **Touch targets:** at least 44×44.
- **Contrast:** ink on white and white on ink only. Never put ink2 on glass for anything important.
- **Visuals need text equivalents:**
  - Every spoon row has a semantics label like "30 gram".
  - The chart has one summary label (see SCREENS.md).
  - The odometer announces the final value only.
- **Reduced motion:** when `MediaQuery.disableAnimationsOf(context)` is true:
  - Everything becomes a 150ms fade.
  - No confetti, no pulse.
  - The odometer jumps to its final value.
  - Buttons don't move on press.
- **Health copy:** estimates always show `≈`, and nothing is presented as diagnosis.

## 7. Prototype → Flutter notes

- **Device frame:** the prototype draws a phone frame and a fake status bar (9:41). These are presentation only, so **don't build them**. Use `SafeArea`; the existing `maxWidth: 480` wrapper in `app.dart` is right for web.
- **Absolute positions:** the prototype positions things absolutely in a 390×844 frame. In Flutter, keep the same spacing but use `Stack` / `Column` with padding, so it survives other heights (the content scrolls; bottom bars are pinned).
- **SVGs:** add `flutter_svg` for the mascot, logo, and icons in `assets/`.
- **Font:** bundle Onest (static TTFs 500/600/700/800 from fonts.google.com → Onest → Download family → `static/`), declared in `pubspec.yaml` under `fonts:` with family `Onest`. Bundling works offline and on web. `google_fonts` is an alternative if it has Onest.
- **Onboarding flag:** the prototype stores `stev-onboarding-complete` in localStorage. Use `shared_preferences`.
- **Haptics:** the prototype calls `navigator.vibrate(10)` on Swap. Use `HapticFeedback.lightImpact()`.
- **Brand names:** the dummy data uses real brand names (Nescafe, Ultra, Sprite, Hydro Coco) and their photos. That's fine for a demo, but sugar numbers are illustrative, not from the labels.
