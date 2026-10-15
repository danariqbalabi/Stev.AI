import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../core/theme/stev_tokens.dart';

class WeekStrip extends StatelessWidget {
  const WeekStrip({
    super.key,
    required this.today,
    required this.selectedDate,
    required this.onSelected,
  });

  final DateTime today;
  final DateTime selectedDate;
  final ValueChanged<DateTime> onSelected;

  static const _days = ['S', 'S', 'R', 'K', 'J', 'S', 'M'];

  bool _isSameDay(DateTime first, DateTime second) =>
      first.year == second.year &&
      first.month == second.month &&
      first.day == second.day;

  @override
  Widget build(BuildContext context) {
    final normalizedToday = DateTime(today.year, today.month, today.day);
    final monday = normalizedToday.subtract(
      Duration(days: normalizedToday.weekday - DateTime.monday),
    );
    final dates = List.generate(
      7,
      (index) => monday.add(Duration(days: index)),
    );

    return Semantics(
      label: 'Pilih riwayat minuman minggu ini',
      child: SizedBox(
        height: 66,
        child: Row(
          children: [
            for (var index = 0; index < dates.length; index++)
              Expanded(
                child: _Day(
                  letter: _days[index],
                  date: dates[index],
                  state: dates[index].isAfter(normalizedToday)
                      ? _DayState.future
                      : _isSameDay(dates[index], normalizedToday)
                      ? _DayState.today
                      : _DayState.past,
                  selected: _isSameDay(dates[index], selectedDate),
                  onPressed: dates[index].isAfter(normalizedToday)
                      ? null
                      : () => onSelected(dates[index]),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

enum _DayState { past, today, future }

class _Day extends StatelessWidget {
  const _Day({
    required this.letter,
    required this.date,
    required this.state,
    required this.selected,
    required this.onPressed,
  });

  final String letter;
  final DateTime date;
  final _DayState state;
  final bool selected;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final dateText = Text(
      '${date.day}',
      style: StevType.caption.copyWith(
        color: selected ? StevColors.onInk : StevColors.ink2,
        fontWeight: selected ? StevType.w700 : StevType.w600,
      ),
    );

    return Semantics(
      button: onPressed != null,
      selected: selected,
      label:
          '${date.day}/${date.month}${state == _DayState.today ? ', hari ini' : ''}',
      child: InkWell(
        key: ValueKey(
          'weekDay-${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}',
        ),
        onTap: onPressed,
        customBorder: const CircleBorder(),
        child: ExcludeSemantics(
          child: Column(
            children: [
              Text(
                letter,
                style: StevType.micro.copyWith(color: StevColors.ink2),
              ),
              const SizedBox(height: StevSpace.s2),
              SizedBox.square(
                dimension: 36,
                child: selected
                    ? DecoratedBox(
                        decoration: const BoxDecoration(
                          color: StevColors.ink,
                          shape: BoxShape.circle,
                        ),
                        child: Center(child: dateText),
                      )
                    : state == _DayState.past
                    ? CustomPaint(
                        painter: _DashedCirclePainter(),
                        child: Center(child: dateText),
                      )
                    : Center(child: dateText),
              ),
            ],
          ),
        ),
      ),
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
