import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:steviai/app/app.dart';
import 'package:steviai/app/router.dart';
import 'package:steviai/features/family/application/family_controller.dart';
import 'package:steviai/features/family/data/family_preferences.dart';
import 'package:steviai/features/family/domain/family_member.dart';
import 'package:steviai/features/risk_assessment/domain/risk_assessment.dart';
import 'package:steviai/features/risk_assessment/presentation/risk_invite_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('family metadata persists locally without health answers', () async {
    final controller = await FamilyController.persistent();
    await controller.add(nickname: 'Ibu', relationship: 'Orang tua');
    final member = controller.members.single;
    await controller.updateStatus(member.id, FamilyProgressStatus.assessed);

    final restored = await FamilyController.persistent();
    expect(restored.members.single.nickname, 'Ibu');
    expect(restored.members.single.relationship, 'Orang tua');
    expect(restored.members.single.status, FamilyProgressStatus.assessed);

    final preferences = await SharedPreferences.getInstance();
    final encoded = preferences.getString(FamilyPreferences.storageKey)!;
    expect(encoded, isNot(contains('score')));
    expect(encoded, isNot(contains('bmi')));
    expect(encoded, isNot(contains('answers')));
  });

  testWidgets('adds a family member and links the parent risk flow', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final family = FamilyController();
    final router = createAppRouter(onboardingComplete: true)..go('/family');
    addTearDown(router.dispose);
    addTearDown(family.dispose);
    await tester.pumpWidget(
      StevAiApp(router: router, familyController: family),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('emptyFamilyState')), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('addFamilyMember')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('familyNameField')),
      'Ibu',
    );
    await tester.enterText(
      find.byKey(const ValueKey('familyRelationshipField')),
      'Orang tua',
    );
    await tester.tap(find.byKey(const ValueKey('saveFamilyMember')));
    await tester.pumpAndSettle();

    expect(family.members.single.nickname, 'Ibu');
    expect(find.text('Belum dicek'), findsOneWidget);
    final memberId = family.members.single.id;
    await tester.tap(find.byKey(ValueKey('assessFamilyMember-$memberId')));
    await tester.pumpAndSettle();
    expect(find.text('Usia Ayah/Ibu berapa?'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('riskOption-<45')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('bmiCalculatorToggle')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const ValueKey('bmiHeightField')), '160');
    await tester.enterText(find.byKey(const ValueKey('bmiWeightField')), '55');
    await tester.pump();
    await tester.drag(find.byType(ListView).last, const Offset(0, -500));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('bmiContinue')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('waistCalculatorToggle')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Wanita'));
    await tester.enterText(find.byKey(const ValueKey('waistField')), '70');
    await tester.pump();
    await tester.drag(find.byType(ListView).last, const Offset(0, -500));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('waistContinue')));
    await tester.pumpAndSettle();
    for (final label in ['Ya', 'Ya', 'Tidak', 'Tidak', 'Tidak']) {
      await tester.tap(find.byKey(ValueKey('riskOption-$label')));
      await tester.pumpAndSettle();
    }

    expect(find.byKey(const ValueKey('riskResultScreen')), findsOneWidget);
    expect(family.members.single.status, FamilyProgressStatus.assessed);
  });

  testWidgets('successful referral marks a linked member as invited', (
    tester,
  ) async {
    final family = FamilyController();
    addTearDown(family.dispose);
    await family.add(nickname: 'Ayah', relationship: 'Orang tua');
    final memberId = family.members.single.id;

    await tester.pumpWidget(
      FamilyScope(
        controller: family,
        child: MaterialApp(
          home: RiskInviteScreen(
            result: RiskAssessmentResult(
              subject: RiskSubject.parent,
              level: RiskLevel.medium,
              topFactors: const [],
              score: 12,
              familyMemberId: memberId,
            ),
            shareMessage: (payload, origin) async {},
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    final shareButton = find.byKey(const ValueKey('shareRiskMessage'));
    await tester.ensureVisible(shareButton);
    await tester.pumpAndSettle();
    await tester.tap(shareButton);
    await tester.pumpAndSettle();

    expect(family.members.single.status, FamilyProgressStatus.invited);
  });
}
