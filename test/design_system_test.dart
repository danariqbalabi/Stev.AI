import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:steviai/core/theme/stev_theme.dart';
import 'package:steviai/core/theme/stev_tokens.dart';
import 'package:steviai/shared/widgets/stev_design_system.dart';

void main() {
  test('sugar helpers split home and drink totals into spoons', () {
    expect(homeSpoons(32), hasLength(4));
    expect(homeSpoons(62.5), hasLength(5));
    expect(homeSpoons(62.5).last, (grams: 12.5, over: true));
    expect(drinkSpoons(0), [0]);
    expect(drinkSpoons(30), [12.5, 12.5, 5]);
  });

  testWidgets('design-system primitives render and button responds', (
    tester,
  ) async {
    var taps = 0;

    await tester.pumpWidget(
      MaterialApp(
        theme: StevTheme.light,
        home: AuraBackground(
          child: Scaffold(
            backgroundColor: Colors.transparent,
            body: SingleChildScrollView(
              padding: const EdgeInsets.all(StevSpace.s5),
              child: Column(
                children: [
                  const StevLogo(),
                  const StevMascot(),
                  const GlassCard(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [Spoon(grams: 12.5), LevelIcon(level: 2)],
                    ),
                  ),
                  StevButton(
                    label: 'Lanjut',
                    onPressed: () => taps++,
                    variant: StevButtonVariant.leaf,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Stev.AI'), findsOneWidget);
    expect(find.text('Lanjut'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.tap(find.text('Lanjut'));
    await tester.pump();
    expect(taps, 1);
  });

  test('theme uses the Stev.AI typeface and canvas', () {
    final theme = StevTheme.light;

    expect(theme.textTheme.bodyMedium?.fontFamily, StevType.family);
    expect(theme.scaffoldBackgroundColor, StevColors.canvas);
    expect(theme.colorScheme.secondary, StevColors.leaf);
  });
}
