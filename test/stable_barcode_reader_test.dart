import 'package:flutter_test/flutter_test.dart';
import 'package:steviai/features/barcode/domain/stable_barcode_reader.dart';

void main() {
  const correct = '8991749000012';
  const other = '8991749000043';
  final start = DateTime.utc(2026, 10, 16);

  test(
    'requires three matching separated detections and locks once accepted',
    () {
      final reader = StableBarcodeReader();
      expect(reader.observe([correct, correct, correct], start), isNull);
      expect(reader.observe([correct], start), isNull);
      expect(
        reader.observe([correct], start.add(const Duration(milliseconds: 200))),
        isNull,
      );
      expect(
        reader.observe([correct], start.add(const Duration(milliseconds: 400))),
        correct,
      );
      expect(
        reader.observe([correct], start.add(const Duration(milliseconds: 600))),
        isNull,
      );
      reader.reset();
      expect(reader.observe([correct], start), isNull);
    },
  );

  test('a different valid barcode restarts the count instead of querying it immediately', () {
    final reader = StableBarcodeReader();
    final codes = [correct, other, correct, correct, correct];
    for (var i = 0; i < codes.length; i++) {
      expect(
        reader.observe([codes[i]], start.add(Duration(milliseconds: i * 200))),
        i == 4 ? correct : isNull,
      );
    }
  });

  for (final noise in [
    <String>[],
    ['invalid'],
    [correct, other],
  ]) {
    test(
      'missing, invalid or multiple barcode candidates reset stability: $noise',
      () {
        final reader = StableBarcodeReader();
        reader.observe([correct], start);
        reader.observe([correct], start.add(const Duration(milliseconds: 200)));
        expect(
          reader.observe(noise, start.add(const Duration(milliseconds: 400))),
          isNull,
        );
        expect(
          reader.observe([
            correct,
          ], start.add(const Duration(milliseconds: 600))),
          isNull,
        );
        expect(
          reader.observe([
            correct,
          ], start.add(const Duration(milliseconds: 800))),
          isNull,
        );
        expect(
          reader.observe([
            correct,
          ], start.add(const Duration(milliseconds: 1000))),
          correct,
        );
      },
    );
  }

  test('long gaps and reversed clocks cannot complete stale detections', () {
    final reader = StableBarcodeReader();
    reader.observe([correct], start);
    reader.observe([correct], start.add(const Duration(milliseconds: 200)));
    expect(
      reader.observe([correct], start.add(const Duration(seconds: 5))),
      isNull,
    );
    expect(reader.observe([correct], start), isNull);
    expect(
      reader.observe([correct], start.add(const Duration(milliseconds: 200))),
      isNull,
    );
    expect(
      reader.observe([correct], start.add(const Duration(milliseconds: 400))),
      correct,
    );
  });
}
