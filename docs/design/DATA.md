# Stev.AI demo data and app logic

This is the dummy data and rules the prototype runs on. Sugar numbers are **illustrative demo values**, not from product labels or a database yet.

## Drink model

```
id            string
name          string
grams         number        sugar in grams for the current selection
estimated     bool          true for non-packaged → show "≈"
sugarLevel    0..3          optional; shows the level icon (3 Normal, 2 Less, 1 Low, 0 No)
levels        {normal, less, none}   optional; only non-packaged drinks → shows the level picker
category      Kemasan | Kopi | Teh | Boba | Jus
photo         asset key (see Photos)
photoFit      cover (default) | contain (packaged products)
photoPosition alignment, default center (e.g. "center 48%" → Alignment(0, -0.04))
```

## Catalog ("Cari manual" list, in this order)

| id | Name | g | ≈ | Levels (normal/less/none) | Category | Photo | Fit / position |
|---|---|---|---|---|---|---|---|
| es-teh-manis-manual | Es teh manis | 24 | yes | 24 / 14 / 0 | Teh | es-teh | cover |
| es-kopi-susu-gula-aren | Es kopi susu gula aren | 36 | yes | 36 / 22 / 6 | Kopi | aren | cover, 48% |
| boba-milk-tea | Boba milk tea | 38 | yes | 38 / 25 / 12 | Boba | boba | cover |
| es-jeruk | Es jeruk | 16 | yes | – | Jus | jeruk | cover, 45% |
| matcha | Matcha | 20 | yes | 20 / 12 / 4 | Teh | matcha | cover, 46% |
| teh-melati-manual | Teh melati kotak | 18 | no | – | Teh | teh-kotak | contain |
| kopi-susu-kaleng | Kopi susu kaleng Nescafe | 30 | no | – | Kemasan | nescafe | cover, 50% |
| susu-cokelat-ultra | Susu cokelat kotak Ultra | 22 | no | – | Kemasan | ultra | contain |
| sprite-botol | Sprite botol | 25 | no | – | Kemasan | sprite | contain |
| hydro-coco | Hydro Coco | 9 | no | – | Kemasan | hydro | contain |

There are also two swap targets that are not in the list:

| id | Name | g | Level | Photo |
|---|---|---|---|---|
| teh-melati-kotak-less-sugar | Teh melati kotak less sugar | 10 | 2 | teh-kotak (contain) |
| es-kopi-susu-gula-aren-less | Es kopi susu gula aren, less sugar | 22 (≈) | 2 | aren |

## Starting state

**Today**, newest first. The total is **32 g**.

1. Teh melati kotak: 18 g (packaged, teh-kotak, contain).
2. Es teh manis: ≈14 g, level 2 (es-teh).

**Confirm** guesses, in order:

1. Kopi susu kaleng Nescafe (badge "Paling cocok").
2. Es kopi susu gula aren.
3. Boba milk tea.

**Weekly:**

- Days: Sen 38 · Sel 55 (over) · Rab 41 · Kam 42 · Jum/Sab/Min no data.
- Saved this week: **46 g** (shown as "lewat swap").
- Week strip: dates 5–11, today = Kamis 8.

## Rules

- **Spoons:** 1 spoon = 12.5 g. Daily reference = 50 g = 4 spoons.
- **Home total:** sum of today's drinks.
  - Mascot is worried if the total is > 50.
  - Spoon meter: 4 spoons + `ceil(max(total − 50, 0) / 12.5)` red spoons.
- **Result grams:**
  - If the drink has levels: `levels[selected]`, default Normal.
  - Otherwise: `grams`.
- **Result "over":** `max(todayTotal + resultGrams − 50, 0)`.
  - Over > 0: "Waduh, lewat X g!" with a worried mascot.
  - Otherwise: "Masih aman, nih!" with a happy mascot.
- **Result spoons:** `max(1, ceil(g / 12.5))`, each holding `clamp(g − i×12.5, 0, 12.5)`.
- **Swap target.** The principle: a swap **never changes the kind of drink**. It offers the same drink with less sugar, or, only when that doesn't exist, a similar drink of the same kind (coffee stays coffee, tea stays tea). This replaces the prototype's behavior, which wrongly sent packaged drinks to tea. Check the rules top to bottom:
  1. **Drink with levels** (non-packaged) → the **same drink, one level down**: Normal → Less, Less → No. The name gets ", less sugar" / ", no sugar", grams come from `levels`, and the level icon updates.
  2. **Packaged drink with a less-sugar version of the same product** → that version.
  3. **Otherwise** → the closest lower-sugar drink of the **same kind**, from the table below.
  4. **No match** → no swap, and the Swap button is **hidden**.
  - The Swap button is also hidden when the user picked **No** sugar.
  - **Saved** = old grams − new grams. Confetti only when saved ≥ 12.5.

  Demo mapping:

  | Drink | Kind | Swap to | g | Saved |
  |---|---|---|---|---|
  | Es teh manis (Normal / Less) | teh | Es teh manis, less / no sugar | 14 / 0 | 10 / 14 |
  | Es kopi susu gula aren (Normal / Less) | kopi | same, less / no sugar | 22 / 6 | 14 / 16 |
  | Boba milk tea (Normal / Less) | boba | same, less / no sugar | 25 / 12 | 13 / 13 |
  | Matcha (Normal / Less) | teh | same, less / no sugar | 12 / 4 | 8 / 8 |
  | Teh melati kotak | teh | Teh melati kotak less sugar | 10 | 8 |
  | Kopi susu kaleng Nescafe | kopi | Es kopi susu gula aren, less sugar (≈) | 22 | 8 |
  | Susu cokelat kotak Ultra | susu | no swap in demo data | – | – |
  | Sprite botol | soda | no swap in demo data | – | – |
  | Hydro Coco | isotonik | no swap in demo data | – | – |
  | Es jeruk | jus | no swap in demo data | – | – |
  | Custom drink (Tambah) | – | no swap | – | – |

  To give the "no swap" drinks a swap, add a same-kind, lower-sugar dummy drink (e.g. a zero-sugar soda for Sprite) and add a row here. Never fall back to another kind.

  For a real version, store a `kind` field on every drink (kopi, teh, susu, soda, jus, boba, isotonik). Pick the same product's lower-sugar variant first. Otherwise pick the same-kind drink with the highest sugar that is still lower than the current one (the gentlest step down, not the most extreme).
- **Logging:**
  - The logged drink goes to the **top** of today. If the same id was already there, it's replaced.
  - If the drink had levels, it's logged with the chosen grams and level (Normal → 3, Less → 2, No → 0).
  - A swapped drink is logged with the ", less sugar" / ", no sugar" suffix **removed** from its name. The level icon shows it instead.
- **Custom drink** ("Tambah minuman"):
  - `grams = sendok × 12.5 + pump × 5`, always `estimated: true`.
  - Name defaults to "Minuman racikan" when empty.
  - Uses the es-teh photo as a placeholder.
  - The preview shows one decimal only when needed (12.5, 30).
- **Search:** keep a drink when (no category chip or the category matches) **and** the name contains the query (case-insensitive).
- **Onboarding:** shown until finished once; persist the flag (`stev-onboarding-complete`).

## Photos

The 10 drink photos are hosted on the published prototype. Download them into `assets/drinks/` and register the folder in `pubspec.yaml`:

| key | file name | URL | px |
|---|---|---|---|
| es-teh | es_teh_manis.png | https://oval-long-86495241.figma.site/assets/01-es-teh-manis-C3bNvDYP.png | 447×447 |
| aren | es_kopi_susu_gula_aren.png | https://oval-long-86495241.figma.site/assets/02-es-kopi-susu-gula-aren-zWrxblMU.png | 546×366 |
| boba | boba_milk_tea.png | https://oval-long-86495241.figma.site/assets/03-boba-milk-tea-CRk5XB7M.png | 554×554 |
| jeruk | es_jeruk.png | https://oval-long-86495241.figma.site/assets/04-es-jeruk-C2Prkchk.png | 486×630 |
| matcha | matcha.png | https://oval-long-86495241.figma.site/assets/05-matcha-eyyysY0r.png | 487×629 |
| teh-kotak | teh_melati_kotak.png | https://oval-long-86495241.figma.site/assets/06-teh-melati-kotak-DxaRpUiJ.png | 447×447 |
| nescafe | kopi_susu_kaleng.png | https://oval-long-86495241.figma.site/assets/07-kopi-susu-kaleng-nescafe-DXOYC-1B.png | 415×739 |
| ultra | susu_cokelat_ultra.png | https://oval-long-86495241.figma.site/assets/08-susu-cokelat-ultra-7DbEbdJj.png | 447×447 |
| sprite | sprite_botol.png | https://oval-long-86495241.figma.site/assets/09-sprite-botol-C2REKTJm.png | 437×702 |
| hydro | hydro_coco.png | https://oval-long-86495241.figma.site/assets/10-hydro-coco-CWYP7do3.png | 335×597 |

The files are 175–400 KB each. Compress them (e.g. to WebP, ~80% quality) before the APK and web build.
