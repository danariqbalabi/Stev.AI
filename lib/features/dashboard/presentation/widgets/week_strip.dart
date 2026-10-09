import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../core/theme/stev_tokens.dart';

class WeekStrip extends StatelessWidget {
  const WeekStrip({super.key});

  static const _days = ['S', 'S', 'R', 'K', 'J', 'S', 'M'];
  static const _dates = [5, 6, 7, 8, 9, 10, 11];
  static const _todayIndex = 3;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Minggu ini, hari ini Kamis tanggal 8',
      child: ExcludeSemantics(
        child: SizedBox(
          height: 66,
          child: Row(
            children: [
              for (var index = 0; index < _days.length; index++)
                Expanded(
                  child: _Day(
                    letter: _days[index],
                    date: _dates[index],
                    state: index < _todayIndex
                        ? _DayState.past
                        : index == _todayIndex
                        ? _DayState.today
                        : _DayState.future,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

enum _DayState { past, today, future }

class _Day extends StatelessWidget {
  const _Day({required this.letter, required this.date, required this.state});

  final String letter;
  final int date;
  final _DayState state;

  @override
  Widget build(BuildContext context) {
    final dateText = Text(
      '$date',
      style: StevType.caption.copyWith(
        color: state == _DayState.today ? StevColors.onInk : StevColors.ink2,
        fontWeight: state == _DayState.today ? StevType.w700 : StevType.w600,
      ),
    );

    return Column(
      children: [
        Text(letter, style: StevType.micro.copyWith(color: StevColors.ink2)),
        const SizedBox(height: StevSpace.s2),
        SizedBox.square(
          dimension: 36,
          child: switch (state) {
            _DayState.today => DecoratedBox(
              decoration: const BoxDecoration(
                color: StevColors.ink,
                shape: BoxShape.circle,
              ),
              child: Center(child: dateText),
            ),
            _DayState.past => CustomPaint(
              painter: _DashedCirclePainter(),
              child: Center(child: dateText),
            ),
            _DayState.future => Center(child: dateText),
          },
        ),
      ],
    );
  }
}

class _DashedCirclePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = StevColors.ink3
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    final rect = Offset.zero & size;
    const segments = 14;
    const gapRadians = 0.11;
    final sweep = 2 * math.pi / segments - gapRadians;

    for (var index = 0; index < segments; index++) {
      final start = index * 2 * math.pi / segments;
      canvas.drawArc(rect.deflate(1), start, sweep, false, paint);
    }
  }

  @override
  bool shouldRepaint(_DashedCirclePainter oldDelegate) => false;
}
