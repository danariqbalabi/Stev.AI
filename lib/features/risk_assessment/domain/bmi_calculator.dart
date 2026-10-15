enum BmiCategory { below25, from25To30, above30 }

class BmiCalculation {
  const BmiCalculation({required this.value, required this.category});

  final double value;
  final BmiCategory category;
}

abstract final class BmiCalculator {
  static BmiCalculation? calculate({
    required String heightCentimeters,
    required String weightKilograms,
  }) {
    final height = _parseNumber(heightCentimeters);
    final weight = _parseNumber(weightKilograms);
    if (height == null || weight == null) return null;
    if (height < 80 || height > 250 || weight < 20 || weight > 400) {
      return null;
    }

    final heightMeters = height / 100;
    final bmi = weight / (heightMeters * heightMeters);
    return BmiCalculation(value: bmi, category: categoryFor(bmi));
  }

  static BmiCategory categoryFor(double bmi) {
    if (bmi < 25) return BmiCategory.below25;
    if (bmi <= 30) return BmiCategory.from25To30;
    return BmiCategory.above30;
  }

  static double? _parseNumber(String value) {
    return double.tryParse(value.trim().replaceAll(',', '.'));
  }
}
