import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:steviai/app/app.dart';
import 'package:steviai/app/router.dart';
import 'package:steviai/core/theme/stev_tokens.dart';
import 'package:steviai/features/risk_assessment/domain/risk_assessment.dart';
import 'package:steviai/features/risk_assessment/presentation/risk_assessment_screen.dart';
import 'package:steviai/features/risk_assessment/presentation/risk_invite_screen.dart';
import 'package:steviai/features/risk_assessment/presentation/risk_result_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('RiskAssessment', () {
    test('classifies the demo high-risk answers and ranks factors', () {
      final result = RiskAssessment.evaluate(
        subject: RiskSubject.parent,
        answers: [
          RiskAssessment.questions[0].options[3],
          RiskAssessment.questions[1].options[2],
          RiskAssessment.questions[2].options[2],
          RiskAssessment.questions[3].options[1],
          RiskAssessment.questions[4].options[1],
          RiskAssessment.questions[5].options[1],
          RiskAssessment.questions[6].options[1],
          RiskAssessment.questions[7].options[2],
        ],
      );

      expect(result.score, 19);
      expect(result.level, RiskLevel.high);
      expect(result.topFactors, [
        'Riwayat keluarga inti',
        'Usia di atas 64',
        'Lingkar pinggang tinggi',
      ]);
      expect(result.isMinimumEstimate, isFalse);
    });

    test('classifies the medium-risk boundary', () {
      final result = RiskAssessment.evaluate(
        subject: RiskSubject.self,
        answers: [
          RiskAssessment.questions[0].options[2],
          RiskAssessment.questions[1].options[2],
          RiskAssessment.questions[2].options[2],
          RiskAssessment.questions[3].options[1],
          RiskAssessment.questions[4].options[0],
          RiskAssessment.questions[5].options[1],
          RiskAssessment.questions[6].options[1],
          RiskAssessment.questions[7].options[0],
        ],
      );

      expect(result.score, 12);
      expect(result.level, RiskLevel.medium);
    });

    test('classifies lowest answers as low risk', () {
      final result = RiskAssessment.evaluate(
        subject: RiskSubject.self,
        answers: [
          RiskAssessment.questions[0].options[0],
          RiskAssessment.questions[1].options[0],
          RiskAssessment.questions[2].options[0],
          RiskAssessment.questions[3].options[0],
          RiskAssessment.questions[4].options[0],
          RiskAssessment.questions[5].options[1],
          RiskAssessment.questions[6].options[1],
          RiskAssessment.questions[7].options[0],
        ],
      );

      expect(result.score, 0);
      expect(result.level, RiskLevel.low);
      expect(result.topFactors, isEmpty);
    });

    test('marks results with unknown answers as minimum estimates', () {
      final answers = List.generate(
        RiskAssessment.questions.length,
        (index) => RiskAssessment.questions[index].options.last,
      );
      final result = RiskAssessment.evaluate(
        subject: RiskSubject.parent,
        answers: answers,
      );

      expect(result.isMinimumEstimate, isTrue);
      expect(result.level, RiskLevel.low);
    });
  });

  testWidgets('uses the final risk labels and minimum estimate treatment', (
    tester,
  ) async {
    const result = RiskAssessmentResult(
      subject: RiskSubject.parent,
      level: RiskLevel.low,
      isMinimumEstimate: true,
      topFactors: [],
      score: 0,
    );

    await tester.pumpWidget(
      const MaterialApp(home: RiskResultScreen(result: result)),
    );

    expect(find.text('Rendah'), findsOneWidget);
    expect(find.text('Estimasi minimal'), findsOneWidget);
    expect(find.textContaining('karena ada jawaban'), findsNothing);
    expect(
      find.ancestor(
        of: find.byKey(const ValueKey('minimumEstimateLabel')),
        matching: find.byType(Row),
      ),
      findsWidgets,
    );

    final pill = tester.widget<Container>(
      find.byKey(const ValueKey('riskLevelPill')),
    );
    final decoration = pill.decoration! as BoxDecoration;
    expect(decoration.color, StevColors.ink);
  });

  testWidgets('uses the reduced transition duration when motion is disabled', (
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

    final switcher = tester.widget<AnimatedSwitcher>(
      find.byType(AnimatedSwitcher),
    );
    expect(switcher.duration, StevMotion.reduced);
  });

  testWidgets('completes the low-risk flow without showing a raw score', (
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

    expect(find.text('Cek risiko untuk siapa?'), findsOneWidget);
    expect(
      find.textContaining('Jawaban diproses di perangkatmu'),
      findsOneWidget,
    );
    await tester.tap(find.text('Diri sendiri'));
    await tester.pumpAndSettle();

    const answerLabels = [
      '<45',
      '<25',
      'Rendah',
      'Ya',
      'Ya',
      'Tidak',
      'Tidak',
      'Tidak ada',
    ];
    for (final label in answerLabels) {
      await tester.tap(find.byKey(ValueKey('riskOption-$label')));
      await tester.pumpAndSettle();
    }

    expect(find.byKey(const ValueKey('riskResultScreen')), findsOneWidget);
    expect(find.text('Rendah'), findsOneWidget);
    expect(find.text('Belum ada faktor utama'), findsOneWidget);
    expect(find.text('0'), findsNothing);
    expect(
      find.textContaining('Ini skrining, bukan diagnosis'),
      findsOneWidget,
    );
    await tester.drag(
      find.byKey(const ValueKey('riskResultScreen')),
      const Offset(0, -500),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('openRiskInvite')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('riskInviteScreen')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('shares only the edited referral message', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    String? sharedMessage;
    await tester.pumpWidget(
      MaterialApp(
        home: RiskInviteScreen(
          subject: RiskSubject.parent,
          shareMessage: (message, origin) async {
            sharedMessage = message;
          },
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Ajak & Rujukan'), findsOneWidget);
    expect(find.text('Pesan buat Ibu/Bapak'), findsOneWidget);
    expect(find.text('Dewasa 18+'), findsOneWidget);
    expect(find.text('Puskesmas terdekat'), findsOneWidget);

    const editedMessage = 'Bu, Sabtu kita cek gula darah bareng, yuk.';
    await tester.enterText(
      find.byKey(const ValueKey('riskInviteMessage')),
      editedMessage,
    );
    await tester.tap(find.byKey(const ValueKey('shareRiskMessage')));
    await tester.pumpAndSettle();

    expect(sharedMessage, editedMessage);
    expect(sharedMessage, isNot(contains('Risiko tinggi')));
    expect(sharedMessage, isNot(contains('19')));
    expect(tester.takeException(), isNull);
  });
}
