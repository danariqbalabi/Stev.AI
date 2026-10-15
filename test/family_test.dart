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
    expect(find.text('Usia Ibu/Bapak berapa?'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('riskOption-Tidak tahu')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('bmiUnknown')));
    await tester.pumpAndSettle();
    for (var index = 0; index < 6; index++) {
      await tester.tap(find.byKey(const ValueKey('riskOption-Tidak tahu')));
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
            subject: RiskSubject.parent,
            familyMemberId: memberId,
            shareMessage: (message, origin) async {},
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('shareRiskMessage')));
    await tester.pumpAndSettle();

    expect(family.members.single.status, FamilyProgressStatus.invited);
  });
}
