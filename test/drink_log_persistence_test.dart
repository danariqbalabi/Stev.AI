import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:steviai/features/custom_drink/domain/custom_drink.dart';
import 'package:steviai/features/drinks/application/drink_log_controller.dart';
import 'package:steviai/features/drinks/data/drink_catalog.dart';
import 'package:steviai/features/drinks/data/drink_log_preferences.dart';
import 'package:steviai/features/drinks/domain/drink.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('first persistent launch is empty and restores later changes', () async {
    SharedPreferences.setMockInitialValues({});
    final date = DateTime(2026, 10, 12);

    final first = await DrinkLogController.persistent(now: date);
    addTearDown(first.dispose);
    expect(first.totalGrams, 0);

    final customDrink = CustomDrink.create(
      id: 'custom-persisted',
      name: 'Es kopi racikan',
      spoons: 2,
      syrupPumps: 1,
    );
    first.log(DrinkSelection(drink: customDrink));
    await first.flush();

    final restored = await DrinkLogController.persistent(now: date);
    addTearDown(restored.dispose);
    expect(restored.entries.first.drink.id, 'custom-persisted');
    expect(restored.entries.first.drink.name, 'Es kopi racikan');
    expect(restored.entries.first.grams, 30);
    expect(restored.entries.first.drink.estimated, isTrue);
    expect(restored.totalGrams, 30);
  });

  test('legacy dashboard demo is removed once', () async {
    SharedPreferences.setMockInitialValues({});
    final date = DateTime(2026, 10, 12);
    final storage = DrinkLogPreferences();
    await storage.write(date, DrinkLogController.demoEntries);

    final controller = await DrinkLogController.persistent(
      preferences: storage,
      now: date,
    );
    addTearDown(controller.dispose);

    expect(controller.entries, isEmpty);
    final preferences = await SharedPreferences.getInstance();
    expect(
      preferences.getBool(DrinkLogPreferences.legacyDemoMigrationKey),
      isTrue,
    );
  });

  test('a new calendar day starts with an empty daily log', () async {
    SharedPreferences.setMockInitialValues({});
    final firstDay = DateTime(2026, 10, 12, 23, 55);
    final nextDay = DateTime(2026, 10, 13, 0, 5);

    final first = await DrinkLogController.persistent(now: firstDay);
    addTearDown(first.dispose);
    expect(first.totalGrams, 0);

    final next = await DrinkLogController.persistent(now: nextDay);
    addTearDown(next.dispose);
    expect(next.entries, isEmpty);
    expect(next.totalGrams, 0);
  });

  test(
    'catalog sugar level and photo presentation survive serialization',
    () async {
      SharedPreferences.setMockInitialValues({});
      final date = DateTime(2026, 10, 12);
      final storage = DrinkLogPreferences();
      const selection = DrinkSelection(
        drink: DrinkCatalog.esKopiSusuGulaAren,
        sugarLevel: SugarLevel.less,
      );

      await storage.write(date, const [selection]);
      final restored = await storage.read(date);

      expect(restored, isNotNull);
      expect(restored, hasLength(1));
      expect(restored!.single.drink.id, selection.drink.id);
      expect(restored.single.sugarLevel, SugarLevel.less);
      expect(restored.single.grams, 22);
      expect(
        restored.single.drink.photoAlignment,
        selection.drink.photoAlignment,
      );
    },
  );

  test('invalid stored data does not crash startup', () async {
    final date = DateTime(2026, 10, 12);
    SharedPreferences.setMockInitialValues({
      DrinkLogPreferences.dateKey(date): '{broken json',
      DrinkLogPreferences.lastActiveDateKey: DrinkLogPreferences.dateLabel(
        date,
      ),
    });

    final controller = await DrinkLogController.persistent(now: date);
    addTearDown(controller.dispose);
    expect(controller.entries, isEmpty);
  });

  test('weekly summary combines daily totals and swap savings', () async {
    SharedPreferences.setMockInitialValues({});
    final storage = DrinkLogPreferences();
    await storage.write(DateTime(2026, 10, 5), const [
      DrinkSelection(drink: DrinkCatalog.tehMelatiKotak),
    ], savedGrams: 8);
    await storage.write(DateTime(2026, 10, 6), const [
      DrinkSelection(drink: DrinkCatalog.tehMelatiKotak),
      DrinkSelection(drink: DrinkCatalog.kopiSusuKalengNescafe),
    ], savedGrams: 14);
    final controller = await DrinkLogController.persistent(
      preferences: storage,
      now: DateTime(2026, 10, 6),
    );
    addTearDown(controller.dispose);

    final summary = await controller.loadWeeklySummary();

    expect(summary.days, hasLength(7));
    expect(summary.days[0].grams, 18);
    expect(summary.days[1].grams, 48);
    expect(summary.days[2].grams, isNull);
    expect(summary.savedGrams, 22);
  });
}
