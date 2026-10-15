import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:steviai/app/app.dart';
import 'package:steviai/app/router.dart';
import 'package:steviai/features/auth/application/auth_controller.dart';
import 'package:steviai/features/auth/domain/auth_user.dart';
import 'package:steviai/shared/widgets/stev_design_system.dart';

void main() {
  test('auth controller exposes session and signs out', () async {
    final gateway = _FakeAuthGateway();
    final controller = AuthController(gateway);
    addTearDown(controller.dispose);
    addTearDown(gateway.dispose);

    expect(controller.isSignedIn, isFalse);
    expect(
      await controller.signIn(
        email: ' user@example.com ',
        password: 'password',
      ),
      isTrue,
    );
    expect(controller.user?.email, 'user@example.com');
    expect(gateway.lastEmail, 'user@example.com');

    expect(await controller.signOut(), isTrue);
    expect(controller.isSignedIn, isFalse);
  });

  test('registration without a session asks for email confirmation', () async {
    final gateway = _FakeAuthGateway(signUpNeedsConfirmation: true);
    final controller = AuthController(gateway);
    addTearDown(controller.dispose);
    addTearDown(gateway.dispose);

    expect(
      await controller.signUp(email: 'user@example.com', password: 'password'),
      isTrue,
    );
    expect(controller.isSignedIn, isFalse);
    expect(controller.confirmationPending, isTrue);
  });

  testWidgets('guest can register, then sign in from the auth screen', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final gateway = _FakeAuthGateway(signUpNeedsConfirmation: true);
    final auth = AuthController(gateway);
    final router = createAppRouter(onboardingComplete: true)..go('/auth');
    addTearDown(auth.dispose);
    addTearDown(gateway.dispose);
    addTearDown(router.dispose);
    await tester.pumpWidget(StevAiApp(router: router, authController: auth));
    await tester.pump(const Duration(milliseconds: 400));

    await tester.tap(find.text('Daftar'));
    await tester.pump();
    await tester.enterText(
      find.byKey(const ValueKey('authEmailField')),
      'user@example.com',
    );
    await tester.enterText(
      find.byKey(const ValueKey('authPasswordField')),
      'password',
    );
    await tester.tap(find.byKey(const ValueKey('authSubmitButton')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(
      find.byKey(const ValueKey('authConfirmationMessage')),
      findsOneWidget,
    );
    await tester.tap(find.text('Masuk'));
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('authSubmitButton')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 700));

    expect(router.routeInformationProvider.value.uri.path, '/profile');
    expect(auth.isSignedIn, isTrue);
    expect(find.byKey(const ValueKey('profileAccountCard')), findsOneWidget);
  });

  testWidgets('shows a safe guest fallback without Supabase configuration', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final gateway = _FakeAuthGateway(available: false);
    final auth = AuthController(gateway);
    final router = createAppRouter(onboardingComplete: true)..go('/auth');
    addTearDown(auth.dispose);
    addTearDown(gateway.dispose);
    addTearDown(router.dispose);
    await tester.pumpWidget(StevAiApp(router: router, authController: auth));
    await tester.pump(const Duration(milliseconds: 400));

    expect(
      find.byKey(const ValueKey('authUnavailableMessage')),
      findsOneWidget,
    );
    final submit = tester.widget<StevButton>(
      find.byKey(const ValueKey('authSubmitButton')),
    );
    expect(submit.onPressed, isNull);
  });
}

class _FakeAuthGateway implements AuthGateway {
  _FakeAuthGateway({
    this.available = true,
    this.signUpNeedsConfirmation = false,
  });

  final bool available;
  final bool signUpNeedsConfirmation;
  final _changes = StreamController<StevAuthUser?>.broadcast();
  StevAuthUser? _user;
  String? lastEmail;

  @override
  bool get isAvailable => available;

  @override
  StevAuthUser? get currentUser => _user;

  @override
  Stream<StevAuthUser?> get userChanges => _changes.stream;

  @override
  Future<StevAuthUser> signIn({
    required String email,
    required String password,
  }) async {
    lastEmail = email;
    _user = StevAuthUser(id: 'user-1', email: email);
    _changes.add(_user);
    return _user!;
  }

  @override
  Future<StevAuthUser?> signUp({
    required String email,
    required String password,
  }) async {
    lastEmail = email;
    if (signUpNeedsConfirmation) return null;
    _user = StevAuthUser(id: 'user-1', email: email);
    _changes.add(_user);
    return _user;
  }

  @override
  Future<void> signOut({bool localOnly = false}) async {
    _user = null;
    _changes.add(null);
  }

  Future<void> dispose() => _changes.close();
}
