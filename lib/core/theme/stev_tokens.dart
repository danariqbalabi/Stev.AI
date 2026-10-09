// Stev.AI design tokens.
//
// Source of truth: the Figma Make prototype (oval-long-86495241.figma.site),
// values copied 1:1 from its CSS. Widgets must read colors, sizes, radii,
// shadows, durations and curves from here instead of hardcoding them.
//
// CSS #RRGGBBAA was converted to Flutter 0xAARRGGBB.

import 'package:flutter/widgets.dart';

abstract final class StevColors {
  // Surfaces
  static const canvas = Color(0xFFF5F5F7); // app background
  static const card = Color(0xFFFFFFFF); // solid cards (sugar card, guess card)
  static const glass = Color(0xB8FFFFFF); // tab bar + bottom sheets (72%)
  static const glassCard = Color(0x8CFFFFFF); // glass cards on canvas (55%)
  static const glassEdge = Color(0xE6FFFFFF); // 1px border on glass (90%)

  // Background auras (blurred blobs behind content)
  static const auraLeaf = Color(0x5734D07F);
  static const auraSugar = Color(0x33E07008);
  static const auraSun = Color(0x57FFD23F);

  // Text + lines
  static const ink = Color(
    0xFF111113,
  ); // primary text, dark buttons, scan button
  static const ink2 = Color(0xFF6E6E73); // secondary text, units ("/50 g")
  static const ink3 = Color(
    0xFFC7C7CC,
  ); // disabled, empty spoon handle, dashed day
  static const onInk = Color(0xFFFFFFFF);

  // Accents
  static const leaf = Color(
    0xFF34D07F,
  ); // primary/positive button (Swap, reward CTA)
  static const leafEdge = Color(0xFF1FA862); // 3D bottom edge of leaf button
  static const sugar = Color(0xFFE07008); // sugar fill inside spoons
  static const over = Color(
    0xFFD93036,
  ); // over the 50 g limit (spoons, bars, "lewat 12 g")
  static const sun = Color(0xFFFFD23F); // confetti only

  // Spoon
  static const spoonBowl = Color(0xFFDCDCE1);

  // Reward popup (dark)
  static const night = Color(0xF0111113); // 94% ink overlay
  static const onNight2 = Color(0xFFA1A1A6); // unit "g" on dark
  static const rewardCard = Color(0x14FFFFFF); // 8% white
  static const rewardCardEdge = Color(0x24FFFFFF); // 14% white

  // Mascot + logo
  static const cubeSide = Color(0xFFE6E6EB);
  static const cubeDots = Color(0xFFD4D4DA);
  static const blush = Color(0xFFFFB3A1);
  static const tongue = Color(0xFFFF8F7A);

  // Press edges (3D buttons)
  static const pressCardEdge = Color(0xFFE1E1E6);

  // On-photo controls (camera / confirm / result headers)
  static const photoButton = Color(0x47FFFFFF); // 28% white
  static const photoButtonEdge = Color(0x80FFFFFF);
  static const photoButtonGlow = Color(0x3DFFFFFF); // 0 4px 0 bottom edge
  static const cameraLink = Color(0x47111113);
  static const shutterFill = Color(0x3DFFFFFF);
}

abstract final class StevSpace {
  static const s1 = 4.0;
  static const s2 = 8.0;
  static const s3 = 12.0;
  static const s4 = 16.0;
  static const s5 = 20.0; // screen side padding
  static const s6 = 24.0;
  static const s7 = 28.0; // card inner padding
  static const s10 = 40.0; // gap between sections
  static const s14 = 56.0; // top padding under status bar
}

abstract final class StevRadius {
  static const small = 14.0; // small buttons, stepper buttons
  static const button = 20.0; // 56px buttons, inputs, level picker
  static const row = 22.0; // drink rows, guess cards
  static const card = 28.0; // daily card, sugar card, chart card
  static const sheet = 36.0; // top corners of bottom sheets
  static const pill = 999.0;
}

abstract final class StevShadows {
  /// Soft lift for cards.
  static const elevCard = [
    BoxShadow(color: Color(0x0A111113), offset: Offset(0, 1), blurRadius: 2),
    BoxShadow(
      color: Color(0x1A111113),
      offset: Offset(0, 12),
      blurRadius: 32,
      spreadRadius: -8,
    ),
  ];

  /// Floating scan button + log-flight thumbnail.
  static const elevFloat = [
    BoxShadow(
      color: Color(0x4D111113),
      offset: Offset(0, 14),
      blurRadius: 32,
      spreadRadius: -6,
    ),
  ];

  /// Upward shadow on the tab bar and bottom sheets.
  static const elevGlass = [
    BoxShadow(
      color: Color(0x1F111113),
      offset: Offset(0, -10),
      blurRadius: 30,
      spreadRadius: -12,
    ),
  ];

  // 3D "press" edges: a hard shadow with 0 blur under the button.
  // On press: move the button down by the same offset and remove the shadow.
  static const pressLeaf = [
    BoxShadow(color: StevColors.leafEdge, offset: Offset(0, 5)),
  ];
  static const pressCard = [
    BoxShadow(color: StevColors.pressCardEdge, offset: Offset(0, 4)),
  ];
  static const pressInk = [
    BoxShadow(color: StevColors.ink2, offset: Offset(0, 5)),
  ];
  static const pressInkChip = [
    BoxShadow(color: StevColors.ink2, offset: Offset(0, 4)),
  ];
}

/// Glass recipe. Use with BackdropFilter(ImageFilter.blur(...)).
abstract final class StevGlass {
  static const blurSigma = 28.0; // CSS blur(28px) saturate(180%)
  static const photoButtonBlur = 20.0;
  static const rewardBlur = 14.0;
  static const auraBlur = 70.0; // aura blobs; a RadialGradient fake is fine
}

abstract final class StevType {
  static const family = 'Onest'; // weights used: 500, 600, 700, 800

  static const w500 = FontWeight.w500;
  static const w600 = FontWeight.w600;
  static const w700 = FontWeight.w700;
  static const w800 = FontWeight.w800;

  /// CSS letter-spacing is in em; Flutter wants logical pixels.
  static double em(double em, double fontSize) => em * fontSize;

  static TextStyle _t(
    double size,
    double line,
    FontWeight w, [
    double em = 0,
  ]) => TextStyle(
    fontFamily: family,
    fontSize: size,
    height: line / size,
    fontWeight: w,
    letterSpacing: em * size,
    color: StevColors.ink,
  );

  static final rewardNumber = _t(88, 88, w800, -0.04); // odometer "10"
  static final heroCard = _t(72, 72, w800, -0.04); // result "30"
  static final number = _t(64, 64, w800, -0.03); // home "32", weekly "46"
  static final unitResult = _t(28, 34, w700); // result "g" (ink2)
  static final unitHome = _t(22, 28, w700); // home "/50 g" (ink2)
  static final title = _t(
    28,
    34,
    w800,
    -0.02,
  ); // reward message, onboarding step
  static final onboardingTitle = _t(24, 30, w800, -0.02);
  static final logo = _t(22, 28, w800, -0.02);
  static final headingResult = _t(22, 28, w700, -0.01); // drink name on sheets
  static final heading = _t(20, 26, w700, -0.01); // section headings
  static final label = _t(16, 22, w600); // drink names, inputs
  static final listGrams = _t(17, 22, w700); // "18 g" at row end
  static final button = _t(17, 22, w700);
  static final body = _t(15, 20, w600); // "Waduh, lewat 12 g!"
  static final caption = _t(13, 18, w600); // ink2 captions, chips
  static final micro = _t(11, 14, w600); // tab labels, week letters, chart days

  /// Every number uses tabular figures so digits don't jump.
  static const tabular = [FontFeature.tabularFigures()];
}

abstract final class StevSize {
  static const screenWidth = 390.0; // design frame (iPhone 14/15)
  static const screenHeight = 844.0;
  static const buttonHeight = 56.0;
  static const tapMin = 44.0;
  static const tabBarHeight = 92.0;
  static const scanButton = 68.0; // overlaps tab bar top by 24
  static const drinkRow = 84.0; // full-bleed photo is 84x84
  static const guessCard = 88.0;
  static const rewardCard = 76.0;
  static const roundButton = 46.0; // back buttons
  static const shutter = 82.0;
  static const spoonHome = 46.0; // spoon width on home (height = width * 2.5)
  static const spoonResult = 40.0;
  static const stevHome = 92.0;
  static const stevResult = 76.0;
  static const stevReward = 150.0;
  static const stevOnboarding = 184.0;
}

abstract final class StevMotion {
  // Durations
  static const press = Duration(milliseconds: 80);
  static const screenFade = Duration(milliseconds: 280);
  static const countUp = Duration(milliseconds: 500);
  static const spoonAppear = Duration(milliseconds: 320);
  static const sugarRise = Duration(milliseconds: 420);
  static const spoonStagger = Duration(milliseconds: 80);
  static const cubePop = Duration(milliseconds: 260);
  static const stevWobble = Duration(milliseconds: 520);
  static const stevJump = Duration(milliseconds: 550);
  static const breathe = Duration(milliseconds: 2400);
  static const wave = Duration(milliseconds: 1500);
  static const scanPulse = Duration(milliseconds: 900);
  static const chartGrow = Duration(milliseconds: 600);
  static const odometer = Duration(milliseconds: 1200);
  static const rewardRise = Duration(milliseconds: 450);
  static const confetti = Duration(milliseconds: 900);
  static const logFlight = Duration(milliseconds: 560);
  static const loggedRowIn = Duration(milliseconds: 400);
  static const homeSugarRise = Duration(milliseconds: 500);
  static const reduced = Duration(milliseconds: 150);

  // Curves (CSS cubic-bezier -> Flutter Cubic)
  /// cubic-bezier(.16,1,.3,1): fast start, long soft landing. Odometer, chart, log flight.
  static const outExpo = Cubic(0.16, 1, 0.3, 1);

  /// cubic-bezier(.34,1.56,.64,1): small overshoot. Spoon appear, cube pop.
  static const outBack = Cubic(0.34, 1.56, 0.64, 1);

  /// cubic-bezier(.2,1.4,.4,1): bouncy jump. Reward mascot.
  static const jump = Cubic(0.2, 1.4, 0.4, 1);

  // CSS ease-out / ease-in / ease-in-out are identical to Flutter's
  // Curves.easeOut / Curves.easeIn / Curves.easeInOut.
}

/// Sugar math used everywhere. 1 spoon = 1 tablespoon = 12.5 g.
abstract final class StevSugar {
  static const gramsPerSpoon = 12.5;
  static const dailyLimit = 50.0; // 4 spoons (Permenkes 30/2013)
}
