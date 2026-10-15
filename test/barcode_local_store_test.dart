import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:steviai/features/barcode/data/barcode_local_store.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('cache is bounded, future dates and corrupt data are ignored', () async {
    final now = DateTime.utc(2026, 10, 16);
    final store = BarcodeLocalStore();
    for (var i = 0; i < 51; i++) {
      await store.write('$i', {'data': i}, now);
    }
    expect(await store.read('0', now), isNull);
    expect((await store.read('50', now))?['data'], 50);
    expect(
      await store.read('50', now.subtract(const Duration(seconds: 1))),
      isNull,
    );
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(BarcodeLocalStore.cacheKey, 'broken JSON');
    expect(await store.read('50', now), isNull);
    await store.write('new', {'data': 1}, now);
    expect(await store.read('new', now), isNotNull);
  });

  test(
    'HTTP-date and missing Retry-After produce deterministic cooldowns',
    () async {
      final now = DateTime.utc(2026, 10, 16);
      final store = BarcodeLocalStore();
      expect(
        await store.block('Fri, 16 Oct 2026 00:02:00 GMT', now),
        now.add(const Duration(minutes: 2)),
      );
      expect(
        await BarcodeLocalStore().reserve(now),
        now.add(const Duration(minutes: 2)),
      );
      final later = now.add(const Duration(minutes: 3));
      expect(
        await store.block('invalid', later),
        later.add(const Duration(minutes: 1)),
      );
    },
  );

  test('simultaneous reservations cannot both call the provider', () async {
    final now = DateTime.utc(2026, 10, 16);
    final results = await Future.wait([
      BarcodeLocalStore().reserve(now),
      BarcodeLocalStore().reserve(now),
    ]);
    expect(results.where((value) => value == null), hasLength(1));
    expect(
      results.whereType<DateTime>().single,
      now.add(const Duration(seconds: 6)),
    );
  });
}
