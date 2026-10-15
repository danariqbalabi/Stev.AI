enum WaistSex { male, female }

enum WaistCategory { belowThreshold, middleRange, aboveThreshold }

class WaistCalculation {
  const WaistCalculation({required this.value, required this.category});

  final double value;
  final WaistCategory category;
}

abstract final class WaistCalculator {
  static WaistCalculation? calculate({
    required String circumferenceCentimeters,
    required WaistSex? sex,
  }) {
    if (sex == null) return null;
    final value = double.tryParse(
      circumferenceCentimeters.trim().replaceAll(',', '.'),
    );
    if (value == null || value < 40 || value > 200) return null;

    final category = switch (sex) {
      WaistSex.male =>
        value < 94
            ? WaistCategory.belowThreshold
            : value <= 102
            ? WaistCategory.middleRange
            : WaistCategory.aboveThreshold,
      WaistSex.female =>
        value < 80
            ? WaistCategory.belowThreshold
            : value <= 88
            ? WaistCategory.middleRange
            : WaistCategory.aboveThreshold,
    };
    return WaistCalculation(value: value, category: category);
  }
}
