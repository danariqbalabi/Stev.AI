import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:steviai/features/profile/data/local_data_preferences.dart';
import 'package:steviai/features/risk_assessment/data/risk_history_preferences.dart';
import 'package:steviai/features/risk_assessment/domain/risk_assessment.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('risk history supports deleting one entry and clearing all', () async {
    final storage = RiskHistoryPreferences();
    const result = RiskAssessmentResult(
      subject: RiskSubject.self,
      level: RiskLevel.medium,
      topFactors: ['Riwayat keluarga inti'],
      score: 12,
    );
    await storage.add(result, checkedAt: DateTime(2026, 10, 14));
    await storage.add(result, checkedAt: DateTime(2026, 10, 15));

    final before = await storage.read();
    expect(before, hasLength(2));
    await storage.remove(before.first.id);
    expect((await storage.read()).single.id, before.last.id);

    await storage.clear();
    expect(await storage.read(), isEmpty);
  });

  test('app reset removes only Stev.AI preferences', () async {
    SharedPreferences.setMockInitialValues({
      'stev-onboarding-complete': true,
      'stev-risk-history-v1': '[]',
      'third-party-setting': 'keep',
    });

    expect(await LocalDataPreferences.resetAll(), 2);
    final preferences = await SharedPreferences.getInstance();
    expect(preferences.containsKey('stev-onboarding-complete'), isFalse);
    expect(preferences.containsKey('stev-risk-history-v1'), isFalse);
    expect(preferences.getString('third-party-setting'), 'keep');
  });
}
