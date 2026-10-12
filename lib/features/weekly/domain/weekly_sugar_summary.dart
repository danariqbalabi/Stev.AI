class DailySugarSummary {
  const DailySugarSummary({required this.date, this.grams});

  final DateTime date;
  final double? grams;
}

class WeeklySugarSummary {
  const WeeklySugarSummary({required this.days, required this.savedGrams});

  final List<DailySugarSummary> days;
  final double savedGrams;
}
