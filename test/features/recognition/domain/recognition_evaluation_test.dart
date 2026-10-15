import 'package:flutter_test/flutter_test.dart';
import 'package:steviai/features/recognition/domain/recognition_evaluation.dart';

void main() {
  test('calculates positive, rejection, error, and latency metrics', () {
    const tea = RecognitionEvaluationCase(
      id: 'tea-front',
      expectedDrinkId: 'teh-melati-kotak',
    );
    const coffee = RecognitionEvaluationCase(
      id: 'coffee-side',
      expectedDrinkId: 'kopi-susu-kaleng-nescafe',
    );
    const person = RecognitionEvaluationCase(
      id: 'person',
      expectedDrinkId: null,
    );

    final report = RecognitionEvaluationReport.fromOutcomes(const [
      RecognitionEvaluationOutcome(
        testCase: tea,
        predictedIds: ['teh-melati-kotak'],
        latencyMs: 100,
      ),
      RecognitionEvaluationOutcome(
        testCase: coffee,
        predictedIds: ['sprite-botol', 'kopi-susu-kaleng-nescafe'],
        latencyMs: 200,
      ),
      RecognitionEvaluationOutcome(
        testCase: person,
        predictedIds: [],
        latencyMs: 300,
      ),
      RecognitionEvaluationOutcome(
        testCase: tea,
        predictedIds: [],
        latencyMs: 400,
        error: 'timeout',
      ),
    ]);

    expect(report.totalCases, 4);
    expect(report.positiveCases, 3);
    expect(report.negativeCases, 1);
    expect(report.top1Correct, 1);
    expect(report.top3Correct, 2);
    expect(report.correctRejections, 1);
    expect(report.falsePositives, 0);
    expect(report.requestErrors, 1);
    expect(report.top1Accuracy, closeTo(1 / 3, 0.001));
    expect(report.top3Accuracy, closeTo(2 / 3, 0.001));
    expect(report.rejectionAccuracy, 1);
    expect(report.falsePositiveRate, 0);
    expect(report.requestErrorRate, 0.25);
    expect(report.p50LatencyMs, 200);
    expect(report.p95LatencyMs, 300);
  });

  test('returns null for metrics without relevant test cases', () {
    final report = RecognitionEvaluationReport.fromOutcomes(const []);

    expect(report.top1Accuracy, isNull);
    expect(report.top3Accuracy, isNull);
    expect(report.rejectionAccuracy, isNull);
    expect(report.falsePositiveRate, isNull);
    expect(report.requestErrorRate, 0);
    expect(report.p50LatencyMs, isNull);
  });
}
