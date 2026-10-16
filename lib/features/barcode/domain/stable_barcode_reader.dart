import 'barcode_product.dart';

/// Three separated, matching detections; never three copies in one capture.
/// This reduces transient misreads, but does not prove product identity.
class StableBarcodeReader {
  String? _lastCode;
  DateTime? _lastAt;
  int _count = 0;
  bool _accepted = false;

  void reset() {
    _lastCode = null;
    _lastAt = null;
    _count = 0;
    _accepted = false;
  }

  String? observe(Iterable<String> readings, DateTime at) {
    if (_accepted) return null;
    final codes = readings.map(validRetailBarcode).whereType<String>().toSet();
    if (codes.length != 1) {
      reset();
      return null;
    }
    final code = codes.single;
    final elapsed = _lastAt == null ? null : at.difference(_lastAt!);
    if (code != _lastCode ||
        elapsed == null ||
        elapsed.isNegative ||
        elapsed > const Duration(seconds: 2)) {
      _lastCode = code;
      _lastAt = at;
      _count = 1;
      return null;
    }
    if (elapsed < const Duration(milliseconds: 100)) return null;
    _lastAt = at;
    if (++_count < 3) return null;
    _accepted = true;
    return code;
  }
}
