import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:steviai/app/app.dart';
import 'package:steviai/app/router.dart';
import 'package:steviai/core/theme/stev_tokens.dart';
import 'package:steviai/features/risk_assessment/data/risk_reminder_scheduler.dart';
import 'package:steviai/features/risk_assessment/data/risk_history_preferences.dart';
import 'package:steviai/features/risk_assessment/domain/bmi_calculator.dart';
import 'package:steviai/features/risk_assessment/domain/risk_assessment.dart';
import 'package:steviai/features/risk_assessment/domain/waist_calculator.dart';
import 'package:steviai/features/risk_assessment/presentation/risk_assessment_screen.dart';
import 'package:steviai/features/risk_assessment/presentation/risk_invite_screen.dart';
import 'package:steviai/features/risk_assessment/presentation/risk_result_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('FINDRISC domain', () {
    test('rounds BMI to one decimal before assigning its category', () {
      final calculation = BmiCalculator.calculate(
        heightCentimeters: '100',
        weightKilograms: '30.04',
      );

      expect(calculation, isNotNull);
      expect(calculation!.value, 30);
      expect(calculation.category, BmiCategory.from25To30);
      expect(BmiCalculator.categoryFor(25), BmiCategory.from25To30);
      expect(BmiCalculator.categoryFor(30), BmiCategory.from25To30);
      expect(BmiCalculator.categoryFor(30.1), BmiCategory.above30);
    });

    test('uses sex-specific inclusive waist boundaries', () {
      expect(
        WaistCalculator.calculate(
          circumferenceCentimeters: '94',
          sex: WaistSex.male,
        )!.category,
        WaistCategory.middleRange,
      );
      expect(
        WaistCalculator.calculate(
          circumferenceCentimeters: '102',
          sex: WaistSex.male,
        )!.category,
        WaistCategory.middleRange,
      );
      expect(
        WaistCalculator.calculate(
          circumferenceCentimeters: '88.1',
          sex: WaistSex.female,
        )!.category,
        WaistCategory.aboveThreshold,
      );
    });

    test('maps all five FINDRISC score bands', () {
      expect(RiskAssessment.levelForScore(0), RiskLevel.low);
      expect(RiskAssessment.levelForScore(6), RiskLevel.low);
      expect(RiskAssessment.levelForScore(7), RiskLevel.slightlyElevated);
      expect(RiskAssessment.levelForScore(11), RiskLevel.slightlyElevated);
      expect(RiskAssessment.levelForScore(12), RiskLevel.medium);
      expect(RiskAssessment.levelForScore(14), RiskLevel.medium);
      expect(RiskAssessment.levelForScore(15), RiskLevel.high);
      expect(RiskAssessment.levelForScore(20), RiskLevel.high);
      expect(RiskAssessment.levelForScore(21), RiskLevel.veryHigh);
      expect(RiskAssessment.levelForScore(26), RiskLevel.veryHigh);
    });

    test('requires all eight answers', () {
      expect(
        () => RiskAssessment.evaluate(
          subject: RiskSubject.self,
          answers: [RiskAssessment.questions.first.options.first],
        ),
        throwsArgumentError,
      );
      expect(
        RiskAssessment.questions.expand((question) => question.options),
        isNot(
          contains(
            predicate<RiskOption>((option) => option.label == 'Tidak tahu'),
          ),
        ),
      );
    });

    test('evaluates the documented 13 point example as medium', () {
      final result = RiskAssessment.evaluate(
        subject: RiskSubject.self,
        answers: [
          RiskAssessment.questions[0].options[1],
          RiskAssessment.questions[1].options[1],
          RiskAssessment.questions[2].options[1],
          RiskAssessment.questions[3].options[1],
          RiskAssessment.questions[4].options[0],
          RiskAssessment.questions[5].options[0],
          RiskAssessment.questions[6].options[0],
          RiskAssessment.questions[7].options[2],
        ],
      );

      expect(result.score, 13);
      expect(result.level, RiskLevel.medium);
      expect(result.shouldOfferParentInvite, isTrue);
    });
  });

  test('risk history stores only a reusable local result summary', () async {
    SharedPreferences.setMockInitialValues({});
    final storage = RiskHistoryPreferences();
    const result = RiskAssessmentResult(
      subject: RiskSubject.self,
      level: RiskLevel.medium,
      topFactors: ['Riwayat keluarga inti'],
      score: 12,
    );

    await storage.add(result, checkedAt: DateTime(2026, 10, 15, 9, 30));
    final history = await storage.read();

    expect(history, hasLength(1));
    expect(history.single.level, RiskLevel.medium);
    expect(history.single.score, 12);
    expect(history.single.topFactors, ['Riwayat keluarga inti']);
    expect(history.single.toResult().subject, RiskSubject.self);
  });

  testWidgets('uses reduced transition duration when motion is disabled', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: MediaQuery(
          data: MediaQueryData(disableAnimations: true),
          child: RiskAssessmentScreen(),
        ),
      ),
    );

    expect(
      tester.widget<AnimatedSwitcher>(find.byType(AnimatedSwitcher)).duration,
      StevMotion.reduced,
    );
  });

  testWidgets('completes all required inputs and shows a low result', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final router = createAppRouter(onboardingComplete: true)..go('/risk');
    addTearDown(router.dispose);
    await tester.pumpWidget(StevAiApp(router: router));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Diri sendiri'));
    await tester.pumpAndSettle();
    expect(find.text('Tidak tahu'), findsNothing);
    await tester.tap(find.byKey(const ValueKey('riskOption-<45')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('bmiHeightField')), findsNothing);
    await tester.tap(find.byKey(const ValueKey('bmiCalculatorToggle')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const ValueKey('bmiHeightField')), '170');
    await tester.enterText(find.byKey(const ValueKey('bmiWeightField')), '60');
    await tester.pump();
    await tester.drag(find.byType(ListView).last, const Offset(0, -500));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('bmiContinue')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('waistField')), findsNothing);
    await tester.tap(find.byKey(const ValueKey('waistCalculatorToggle')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Pria'));
    await tester.enterText(find.byKey(const ValueKey('waistField')), '90');
    await tester.pump();
    expect(find.text('Kategori Di bawah batas'), findsOneWidget);
    await tester.drag(find.byType(ListView).last, const Offset(0, -500));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('waistContinue')));
    await tester.pumpAndSettle();
    for (final label in ['Ya', 'Ya', 'Tidak', 'Tidak', 'Tidak']) {
      await tester.tap(find.byKey(ValueKey('riskOption-$label')));
      await tester.pumpAndSettle();
    }

    expect(find.byKey(const ValueKey('riskResultScreen')), findsOneWidget);
    expect(find.text('Risiko Rendah'), findsOneWidget);
    expect(find.byKey(const ValueKey('riskScore')), findsOneWidget);
    expect(find.byKey(const ValueKey('openRiskInvite')), findsNothing);
    expect(find.text('GDP (Gula Darah Puasa)'), findsNothing);
  });

  testWidgets('medium self result offers tests and a parent poster', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    const result = RiskAssessmentResult(
      subject: RiskSubject.self,
      level: RiskLevel.medium,
      topFactors: ['Riwayat keluarga inti'],
      score: 12,
    );

    await tester.pumpWidget(
      const MaterialApp(home: RiskResultScreen(result: result)),
    );
    await tester.pumpAndSettle();
    for (var index = 0; index < 4; index++) {
      await tester.drag(find.byType(ListView), const Offset(0, -500));
      await tester.pumpAndSettle();
    }

    expect(find.text('GDP (Gula Darah Puasa)'), findsOneWidget);
    expect(find.text('HbA1c'), findsOneWidget);
    expect(find.text('TTGO (Tes Toleransi Glukosa Oral)'), findsOneWidget);
    expect(find.byKey(const ValueKey('openRiskInvite')), findsOneWidget);
  });

  testWidgets('shares the correct poster with an editable scored message', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    RiskSharePayload? sharedPayload;
    const result = RiskAssessmentResult(
      subject: RiskSubject.self,
      level: RiskLevel.high,
      topFactors: [],
      score: 16,
    );

    await tester.pumpWidget(
      MaterialApp(
        home: RiskInviteScreen(
          result: result,
          shareMessage: (payload, origin) async {
            sharedPayload = payload;
          },
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('riskPosterPreview')), findsOneWidget);
    expect(find.textContaining('hasilku Tinggi (skor 16)'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('shareRiskMessage')));
    await tester.pumpAndSettle();

    expect(sharedPayload!.message, contains('skor 16'));
    expect(sharedPayload!.posterAsset, endsWith('poster_diri_tinggi.jpeg'));
  });

  testWidgets('schedules and cancels the seven day reminder', (tester) async {
    final scheduler = _FakeRiskReminderScheduler();
    await tester.pumpWidget(
      MaterialApp(
        home: RiskInviteScreen(
          result: const RiskAssessmentResult(
            subject: RiskSubject.parent,
            level: RiskLevel.medium,
            topFactors: [],
            score: 12,
          ),
          reminderScheduler: scheduler,
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.drag(find.byType(ListView), const Offset(0, -1000));
    await tester.pumpAndSettle();
    final reminderSwitch = find.byKey(const ValueKey('riskReminderSwitch'));
    await tester.ensureVisible(reminderSwitch);
    await tester.tap(reminderSwitch);
    await tester.pumpAndSettle();
    expect(scheduler.scheduleCalls, 1);
    expect(tester.widget<Switch>(find.byType(Switch)).value, isTrue);

    await tester.tap(reminderSwitch);
    await tester.pumpAndSettle();
    expect(scheduler.cancelCalls, 1);
    expect(tester.widget<Switch>(find.byType(Switch)).value, isFalse);
  });
}

class _FakeRiskReminderScheduler implements RiskReminderScheduler {
  var scheduleCalls = 0;
  var cancelCalls = 0;

  @override
  Future<RiskReminderScheduleStatus> scheduleSevenDayReminder() async {
    scheduleCalls++;
    return RiskReminderScheduleStatus.scheduled;
  }

  @override
  Future<void> cancelReminder() async {
    cancelCalls++;
  }
}
