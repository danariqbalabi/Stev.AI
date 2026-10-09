// Spoon + level icon, ported 1:1 from the prototype SVG.
//
// Spoon geometry lives in a 40 x 100 box:
//   handle: path M15.5 34 L24.5 34 L27.5 89 A7.5 7.5 0 0 1 12.5 89 Z
//   bowl:   ellipse center (20, 21), rx 15.5, ry 19
//   sugar:  rect clipped to the bowl, height 38 * fill, anchored at y = 40
// One spoon holds 12.5 g. fill = clamp(grams / 12.5, 0, 1).

import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import '../../core/theme/stev_tokens.dart';

class Spoon extends StatelessWidget {
  const Spoon({
    super.key,
    required this.grams,
    this.width = StevSize.spoonHome,
    this.over = false,
    this.fillProgress = 1,
  });

  /// Grams inside THIS spoon (0..12.5).
  final double grams;
  final double width;

  /// Spoons past the 50 g limit are filled red instead of orange.
  final bool over;

  /// 0..1 multiplier for the "sugar-rise" animation (scaleY from the bottom).
  final double fillProgress;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: '${grams.toStringAsFixed(grams % 1 == 0 ? 0 : 1)} gram',
      child: CustomPaint(
        size: Size(width, width * 2.5),
        painter: _SpoonPainter(
          fill:
              (grams / StevSugar.gramsPerSpoon).clamp(0, 1).toDouble() *
              fillProgress,
          empty: grams <= 0,
          over: over,
        ),
      ),
    );
  }
}

class _SpoonPainter extends CustomPainter {
  _SpoonPainter({required this.fill, required this.empty, required this.over});

  final double fill;
  final bool empty;
  final bool over;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.scale(size.width / 40, size.height / 100);

    final handle = Path()
      ..moveTo(15.5, 34)
      ..lineTo(24.5, 34)
      ..lineTo(27.5, 89)
      ..arcToPoint(
        const Offset(12.5, 89),
        radius: const Radius.circular(7.5),
        clockwise: true,
      )
      ..close();
    canvas.drawPath(
      handle,
      Paint()..color = empty ? StevColors.ink3 : StevColors.ink,
    );

    final bowl = Rect.fromCenter(
      center: const Offset(20, 21),
      width: 31,
      height: 38,
    );
    canvas.drawOval(bowl, Paint()..color = StevColors.spoonBowl);

    if (fill > 0) {
      final h = 38 * fill;
      canvas.save();
      canvas.clipPath(Path()..addOval(bowl));
      canvas.drawRect(
        Rect.fromLTWH(0, 40 - h, 40, h + 1),
        Paint()..color = over ? StevColors.over : StevColors.sugar,
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_SpoonPainter old) =>
      old.fill != fill || old.empty != empty || old.over != over;
}

/// Splits a total into spoons for the HOME meter:
/// always 4 spoons (= 50 g), plus extra red spoons for every 12.5 g over 50.
List<({double grams, bool over})> homeSpoons(double total) {
  final base = List.generate(4, (i) {
    final g = (total - i * StevSugar.gramsPerSpoon).clamp(0, 12.5).toDouble();
    return (grams: g, over: false);
  });
  final overCount =
      (math.max(0.0, total - StevSugar.dailyLimit) / StevSugar.gramsPerSpoon)
          .ceil();
  final extra = List.generate(overCount, (i) {
    final g = (total - StevSugar.dailyLimit - i * StevSugar.gramsPerSpoon)
        .clamp(0, 12.5)
        .toDouble();
    return (grams: g, over: true);
  });
  return [...base, ...extra];
}

/// Splits ONE drink into spoons for the RESULT card:
/// max(1, ceil(grams / 12.5)) spoons, all orange.
List<double> drinkSpoons(double grams) {
  final count = math.max(1, (grams / StevSugar.gramsPerSpoon).ceil());
  return List.generate(
    count,
    (i) => (grams - i * StevSugar.gramsPerSpoon).clamp(0, 12.5).toDouble(),
  );
}

/// Sugar level icon: three small cubes, filled up to [level].
/// 0 = No sugar, 1 = Low, 2 = Less, 3 = Normal. Box 41 x 18, drawn at 32 x 14.
class LevelIcon extends StatelessWidget {
  const LevelIcon({super.key, required this.level, this.width = 32});

  final int level;
  final double width;

  static const labels = ['No sugar', 'Low sugar', 'Less sugar', 'Normal sugar'];

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: labels[math.min(math.max(level, 0), 3)],
      child: CustomPaint(
        size: Size(width, width * 18 / 41),
        painter: _LevelPainter(level),
      ),
    );
  }
}

class _LevelPainter extends CustomPainter {
  _LevelPainter(this.level);

  final int level;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.scale(size.width / 41, size.height / 18);
    const xs = [1.0, 15.0, 29.0];
    for (var i = 0; i < 3; i++) {
      final filled = i < level;
      final r = RRect.fromRectAndRadius(
        Rect.fromLTWH(xs[i], 4, 11, 11),
        const Radius.circular(3.2),
      );
      canvas.drawRRect(
        r,
        Paint()..color = filled ? StevColors.ink : StevColors.card,
      );
      canvas.drawRRect(
        r,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.8
          ..color = filled ? StevColors.ink : StevColors.ink3,
      );
    }
  }

  @override
  bool shouldRepaint(_LevelPainter old) => old.level != level;
}
