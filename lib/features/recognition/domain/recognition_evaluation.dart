class RecognitionEvaluationCase {
  const RecognitionEvaluationCase({
    required this.id,
    required this.expectedDrinkId,
  });

  final String id;
  final String? expectedDrinkId;

  bool get expectsRejection => expectedDrinkId == null;
}

class RecognitionEvaluationOutcome {
  const RecognitionEvaluationOutcome({
    required this.testCase,
    required this.predictedIds,
    required this.latencyMs,
    this.error,
  });

  final RecognitionEvaluationCase testCase;
  final List<String> predictedIds;
  final int latencyMs;
  final String? error;

  bool get requestSucceeded => error == null;
}

class RecognitionEvaluationReport {
  RecognitionEvaluationReport._({
    required this.totalCases,
    required this.positiveCases,
    required this.negativeCases,
    required this.requestErrors,
    required this.top1Correct,
    required this.top3Correct,
    required this.correctRejections,
    required this.falsePositives,
    required this.p50LatencyMs,
    required this.p95LatencyMs,
  });

  factory RecognitionEvaluationReport.fromOutcomes(
    Iterable<RecognitionEvaluationOutcome> values,
  ) {
    final outcomes = values.toList(growable: false);
    var positiveCases = 0;
    var negativeCases = 0;
    var requestErrors = 0;
    var top1Correct = 0;
    var top3Correct = 0;
    var correctRejections = 0;
    var falsePositives = 0;
    final latencies = <int>[];

    for (final outcome in outcomes) {
      final testCase = outcome.testCase;
      if (testCase.expectsRejection) {
        negativeCases++;
      } else {
        positiveCases++;
      }

      if (!outcome.requestSucceeded) {
        requestErrors++;
        continue;
      }
      latencies.add(outcome.latencyMs);

      if (testCase.expectsRejection) {
        if (outcome.predictedIds.isEmpty) {
          correctRejections++;
        } else {
          falsePositives++;
        }
        continue;
      }

      if (outcome.predictedIds.firstOrNull == testCase.expectedDrinkId) {
        top1Correct++;
      }
      if (outcome.predictedIds.take(3).contains(testCase.expectedDrinkId)) {
        top3Correct++;
      }
    }

    latencies.sort();
    return RecognitionEvaluationReport._(
      totalCases: outcomes.length,
      positiveCases: positiveCases,
      negativeCases: negativeCases,
      requestErrors: requestErrors,
      top1Correct: top1Correct,
      top3Correct: top3Correct,
      correctRejections: correctRejections,
      falsePositives: falsePositives,
      p50LatencyMs: _percentile(latencies, 0.50),
      p95LatencyMs: _percentile(latencies, 0.95),
    );
  }

  final int totalCases;
  final int positiveCases;
  final int negativeCases;
  final int requestErrors;
  final int top1Correct;
  final int top3Correct;
  final int correctRejections;
  final int falsePositives;
  final int? p50LatencyMs;
  final int? p95LatencyMs;

  double? get top1Accuracy => _ratio(top1Correct, positiveCases);
  double? get top3Accuracy => _ratio(top3Correct, positiveCases);
  double? get rejectionAccuracy => _ratio(correctRejections, negativeCases);
  double? get falsePositiveRate => _ratio(falsePositives, negativeCases);
  double get requestErrorRate => _ratio(requestErrors, totalCases) ?? 0;

  Map<String, Object?> toJson() => {
    'totalCases': totalCases,
    'positiveCases': positiveCases,
    'negativeCases': negativeCases,
    'requestErrors': requestErrors,
    'top1Correct': top1Correct,
    'top3Correct': top3Correct,
    'correctRejections': correctRejections,
    'falsePositives': falsePositives,
    'top1Accuracy': top1Accuracy,
    'top3Accuracy': top3Accuracy,
    'rejectionAccuracy': rejectionAccuracy,
    'falsePositiveRate': falsePositiveRate,
    'requestErrorRate': requestErrorRate,
    'p50LatencyMs': p50LatencyMs,
    'p95LatencyMs': p95LatencyMs,
  };

  static double? _ratio(int numerator, int denominator) {
    if (denominator == 0) return null;
    return numerator / denominator;
  }

  static int? _percentile(List<int> sortedValues, double percentile) {
    if (sortedValues.isEmpty) return null;
    final index = ((sortedValues.length - 1) * percentile).ceil();
    return sortedValues[index];
  }
}

extension<T> on List<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
