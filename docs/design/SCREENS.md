# Stev.AI screens

The reference frame is a 390 × 844 phone. All numbers are logical px taken from the prototype CSS. Build each screen with normal Flutter layout (padding, Column, Stack), not absolute coordinates, so it still works at other heights. Content scrolls; bars and sheets stay pinned.

Every screen enters with a 280 ms fade (no slide). See MOTION.md.

## 0. Shared layers

### Aura layer

The aura layer sits behind everything on canvas screens: Onboarding, Home, Weekly, Cari manual, and Tambah. It is a `Stack` of 4 soft circles clipped to the screen:

| Aura | Size | Position | Color |
|---|---|---|---|
| leaf | 280 | top 170, left −90 | auraLeaf |
| sugar | 260 | top 58, right −130 | auraSugar |
| sun | 240 | top 510, right −88 | auraSun |
| leaf-bottom | 250 | bottom −120, left −80 | auraLeaf |

The prototype blurs these circles by 70 px. A `RadialGradient` from the color to transparent looks the same and is cheaper.

On Result, the whole aura layer sits on top of the photo, shifted down by 320, so the sheet's glass picks up color.

### Screen padding

| Screen type | Padding (top / sides / bottom) | Notes |
|---|---|---|
| Canvas screen with tab bar | 56 / 20 / 112 | 112 clears the tab bar |
| Inner canvas screen (manual, add) | header at top 48; content top 116–126 / 20 / 36 | |

### Photo screens (Camera, Confirm, Result)

- The status bar text and icons are **white** on these screens.
- **Top bar:** at top 56, 20 from each side, laid out as `46 | 1fr | 46`.
  - Left: glass round back button.
  - Center: title, label 16/700, white, soft text shadow.

## 1. Onboarding 1: "Lihat gula sebelum kamu beli."

1. **Background:** aura layer.
2. **Top-left:** logo (30 px mark + "Stev.AI").
3. **Mascot:** Stev **cheer**, 184 px, centered, 120 below the logo. It waves and breathes (MOTION.md).
4. **Title:** "Lihat gula sebelum kamu beli.", 43 below the mascot, onboardingTitle (24/30, 800), centered, one line.
5. **Button:** dark "Mulai", 56 high, pinned 38 from the bottom, 20 side margins. Goes to Onboarding 2.

## 2. Onboarding 2: "Kenalan dulu, yuk."

1. **Back button:** inner back button (46, glass). Goes to Onboarding 1.
2. **Title:** "Kenalan dulu, yuk.", title style (28/34, 800), 42 below the back button.
3. **Name field:** 40 below the title.
   - Label: "Nama kamu" (caption).
   - Input: 58 high, placeholder "Tulis nama".
4. **Time question:** 40 below the name field.
   - Question: "Biasanya beli minum jam berapa?" (label, 700).
   - Chips: 16 below the question, 4 equal chips (Pagi / Siang / Sore / Malam), 48 high, 8 gap.
   - Selection: single-select; tapping the selected chip again keeps it selected.
5. **Bottom actions:** pinned 38 from the bottom, 16 gap.
   - Dark "Mulai".
   - Ghost "Lewati".
   - Both finish onboarding: save the flag, go to Home.

In the prototype the name and time are not used anywhere else yet. Keep them in local state or prefs.

## 3. Home (Beranda)

The content scrolls with padding 56 / 20 / 112. From the top:

1. **Logo.**
2. **Week strip:** 20 below the logo, 66 high, 7 columns.
   - Letters: S S R K J S M.
   - Dates: 5 to 11.
   - States: 5–7 past (dashed ink3 circle), 8 today (ink circle, white number), 9–11 future.
3. **Daily card:** 20 below the week strip. Glass, 290 high, padding 28, radius 28, clips its content.
   - **Number:** "32" (number 64/800) followed by "/50 g" (22/700 ink2, 3 px left gap), baseline-aligned.
   - **Caption:** "Gula hari ini" (caption ink2), 6 below the number.
   - **Mascot:** Stev at 92 px, top 22, right 22. **happy** when total ≤ 50, **worried** when total > 50. Breathes.
   - **Spoon meter:** pinned bottom 21, left 27, right 27.
     - Always 4 spoons (46 wide), plus red extra spoons when over 50.
     - Spacing: space-between, bottom-aligned.
4. **"Hari ini" section:** 40 below the card. Heading 20/700.
5. **Drink list:** 14 below the heading, rows with 12 gap, newest first.
6. **Tab bar:**
   - Active tab: Beranda.
   - Scan button: pulses once when Home appears.
   - Tapping Scan opens the Camera (back returns to Home).

After a drink is logged, Home plays the "logged" animations: a flying thumbnail, the first row dropping in, and the spoons refilling (MOTION.md §Log).

## 4. Weekly (Mingguan)

The content scrolls with padding 56 / 20 / 112.

1. **Logo.**
2. **Summary:** 40 below the logo.
   - "Minggu ini hemat" in heading 20/700.
   - "46" in number 64/800, with "g" in 22/700 ink2 (2 px left gap), 4 below the heading.
   - "lewat swap" in caption ink2, 4 below the number.
3. **Chart card:** 38 below the summary. Glass, height 350, padding 28, radius 28, **not clipped**.
   - **Mascot:** Stev **happy** at 92 px, top −28, right 18 (peeks over the edge). Breathes.
   - **Title:** "Gula harian" in heading 20/700.
   - **Chart:** 20 below the title, height 244.
     - **Grid:** 7 columns with 8 gap. Each column is a 210-high bar track, a 10 gap, then the day label (micro ink2).
     - **Bars:** 22 wide, radius 8 8 4 4, ink. Days over 50 g are red. Height = grams / 60 × 210.
     - **Limit line:** dashed 1 px ink2 at the 50 g line (35 from the top of the track), with a "50 g" label in micro ink2 at the right, just above it.
     - **Accessibility:** one label for the whole chart: "Gula harian: Senin 38 gram, Selasa 55 gram, Rabu 41 gram, Kamis 42 gram, Jumat sampai Minggu belum ada data. Batas 50 gram."
4. **Tab bar:**
   - Active tab: Mingguan.
   - Scan opens the Camera (back returns to Weekly).

## 5. Camera (Scan minuman)

The prototype fakes the camera with a full-screen drink photo. In the app, this is the real camera preview (the repo already has `ScanScreen`).

- **Layer 1:** full-bleed camera preview (cover).
- **Layer 2:** shade gradient from top to bottom: ink@25% → transparent at 35% → transparent at 58% → ink@62% at the bottom.
- **Top bar:** "Scan minuman".
- **Frame brackets:** 4 L-shaped corners in a 280 × 280 square, centered horizontally, 218 from the top.
  - Each corner is 54 × 54, a 4 px white stroke with an 18 outer radius and a soft drop shadow.
- **Bottom actions:** pinned 42 from the bottom, centered column, 20 gap.
  - **Shutter:** 82 circle, 4 px white border, white@24% fill, a 64 white inner circle, and a `0 6 0 ink@35%` bottom edge. Goes to Confirm.
  - **"Cari manual" link:** 44 high, radius 14, dark glass (ink@28% + blur 12), white caption 13/700. Opens Cari manual (back returns to Camera).

## 6. Confirm (Ini minuman apa?)

- **Photo:** top 430 shows the captured photo (cover).
- **Top bar:** "Ini minuman apa?". Back returns to Camera.
- **Sheet:** glass, pinned to the bottom, min height 574, padding 27 / 20 / 28.
  1. **Heading:** "Pilih yang paling cocok" (headingResult 22/700).
  2. **Guess list:** 20 below the heading, 3 guess cards with 12 gap.
     - **Card:** 88 high, white, radius 22, pressCard + elevCard edge, laid out as `88 | 1fr | 24`.
     - **Contents:** photo 88 × 88 full-bleed, name label 16/600 with 16 left padding, ink2 chevron.
     - **First card:** micro ink2 badge **"Paling cocok"** at top 8, right 42.
     - **Tap:** opens Result for that drink (back returns to Confirm).
  3. **Manual link:** "Bukan ini? Cari manual", 20 below the list, centered small white button (44 high, radius 14, pressCard edge, caption 700 ink2). Opens Cari manual (back returns to Confirm).

## 7. Result (Hasil scan)

- **Photo:** top 430 shows the drink photo (cover, position from data).
- **Top bar:** "Hasil scan". Back returns to where Result was opened from (Confirm or Cari manual).
- **Aura layer:** above the photo, shifted down 320.
- **Sheet:** glass, min height 504, or 590 when the level picker shows. Padding 26 / 20 / 34. From the top:
  1. **Drink name:** headingResult 22/700.
  2. **Level picker:** only for non-packaged drinks (the ones with `levels`), 12 below the name.
     - Normal / Less / No. Default is **Normal**.
     - Changing it updates grams instantly (no count-up) and replays the spoons.
  3. **Sugar card:** 14 below the name or picker. White, height 290, padding 22 / 20 / 50, centered.
     - **Spoons:** 40 wide, `max(1, ceil(g / 12.5))` of them, 16 gap, 100 high row.
     - **Number:** 72 high line, 2 below the spoons. "≈" (if estimated) + grams (heroCard 72/800, count-up) + "g" (28/700 ink2).
     - **Warning:** 3 below the number, body 15/600.
       - Over the limit: "Waduh, lewat **12 g**!" with the number in red.
       - Otherwise: "Masih aman, nih!".
     - **Mascot:** Stev at 76 px, centered, hanging 39 below the card. **worried** if over, **happy** if not. Wobbles once, then breathes.
  4. **Actions:** 53 below the card (room for the hanging Stev). Two columns `1.25fr | 0.9fr`, 12 gap.
     - Secondary "Aku pilih ini" logs this drink and goes Home.
     - Primary leaf "Swap" with the swap icon gives haptic feedback and opens the Reward popup.
     - Swap is hidden when the user picked **No** sugar, or when the drink has no same-kind swap (DATA.md §Swap target). Then "Aku pilih ini" fills the row.

**"Over" is the day total, not the drink alone:** `over = max(todayTotal + thisDrink − 50, 0)`.

## 8. Reward popup (over Result)

The popup is a full-screen overlay with night (ink 94%) and blur 14. It is not a route. Padding top 148, sides 20.

1. **Confetti:** only when the saving is ≥ 12.5 g (≥ 1 spoon). It falls in the top 360 px.
2. **Mascot:** Stev **cheer**, on-dark version (white raised arms), 150 px, centered.
3. **Odometer:** 88 high, −5 top margin. Two digit windows (58 × 88 each) roll from the old grams to the new grams, followed by "g" (28/700, onNight2, 5 left gap).
4. **Message:** "Mantap, hemat X g!" in title 28/800, centered, 19 below the odometer.
5. **New drink card:** 28 below the message. Height 76, white@8% fill, white@14% border, radius 22, laid out as `76 | 1fr | auto`.
   - Photo 76 × 76.
   - Name: label 16/700, 16 padding.
   - Grams: 16/700, right padding 20, with "≈" when estimated.
6. **Button:** primary leaf "Aku pilih ini", pinned 40 from the bottom. Logs the **swapped** drink and goes Home.

The button is the only exit: it logs the swapped drink and returns to Home. That's intended; there's no separate close button.

## 9. Cari manual

- **Background:** aura layer.
- **Inner header:** at top 48, 48 high, laid out as `48 | 1fr | 48`.
  - Inner back button. Returns to Camera or Confirm, depending on the origin.
  - "Cari manual" (heading 20/700) centered.
- **Content:** scrolls with padding 116 / 20 / 36.
  1. **Search field:** 56 high, glass, radius 20, laid out as `24 | 1fr` with 12 gap. Search icon in ink2, placeholder "Cari minuman".
  2. **Category chips:** 16 below the search field, horizontally scrollable, bleeding to the screen edges (−20 margin, +20 padding), 8 gap, 40 high.
     - Chips: Kemasan / Kopi / Teh / Boba / Jus.
     - Tap toggles a chip; one at a time; tapping the active chip clears it.
  3. **Results:** 20 below the chips, 12 gap. Drink rows wrapped in a pressable with the pressCard edge.
     - Filter: matches the category (if one is set) **and** the name contains the query (case-insensitive, Indonesian locale).
     - Tap opens Result (back returns to Cari manual).
  4. **"+ Tambah minuman" button:** 20 below the results. White, full width, 56 high, radius 20, pressCard + elevCard edge, "+" at 25 px. Opens Tambah minuman.

## 10. Tambah minuman

- **Inner header:** "Tambah minuman". Back returns to Cari manual.
- **Content:** a column with padding 126 / 20 / 36 and 24 gap.
  1. **Name field:** "Nama minuman", placeholder "Contoh: Es kopi susu", 56 high.
  2. **Stepper card:** glass, padding 20, radius 28, 20 gap between rows.
     - Rows: "Sendok gula" (default **1**) and "Pump sirup" (default **0**).
     - Each row has its label on the left and a `44 | 36 | 44` control on the right: "−" button, value (17/700 tabular), "+" button.
     - The buttons are white 44 squares, radius 14, pressCard + elevCard edge.
     - Minimum value is 0.
  3. **Preview card:** glass, min height 230, padding 24, radius 28, centered column with 16 gap.
     - **Number:** "≈12.5" (number 64/800) + "g" (22/700 ink2).
     - **Spoons:** the result spoon row for that number.
  4. **"Simpan" button:** secondary, full width. Logs the custom drink and goes Home.

## Navigation map

```
first launch ─► Onboarding 1 ─► Onboarding 2 ─► Home      (flag saved; later launches open Home)

Home ◄──tab──► Weekly
  │ scan          │ scan
  ▼               ▼
Camera (back → whichever opened it)
  ├─ shutter ─► Confirm ─ guess ─► Result
  │              └─ "Bukan ini? Cari manual" ─► Cari manual
  └─ "Cari manual" ─► Cari manual ─ row ─► Result
                         └─ "+ Tambah minuman" ─► Tambah ─ Simpan ─► Home (logged)

Result ─ "Aku pilih ini" ─► Home (logged)
   └─ "Swap" ─► Reward overlay ─ "Aku pilih ini" ─► Home (swapped drink logged)
```

The repo already uses `go_router` with `/`, `/scan`, `/confirmation`, and `/result`. A natural extension is to add `/onboarding`, `/onboarding/profile`, `/weekly`, `/manual`, and `/manual/add`. Keep Reward as an overlay inside Result, not a route. The prototype passes the "where to go back to" origin for Camera, Result, and Cari manual; with go_router, `context.pop()` handles that.
