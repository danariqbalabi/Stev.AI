import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:steviai/app/app.dart';
import 'package:steviai/app/router.dart';
import 'package:steviai/features/scan/presentation/scan_mode_switcher.dart';
import 'package:steviai/features/scan/presentation/scan_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('plugins.flutter.io/camera'),
          (call) async => call.method == 'availableCameras' ? [] : null,
        );
  });
  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('plugins.flutter.io/camera'),
          null,
        );
  });
  testWidgets(
    'one tap opens photo camera and inline modes fit a small screen',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final router = createAppRouter(onboardingComplete: true);
      addTearDown(router.dispose);
      await tester.pumpWidget(StevAiApp(router: router));
      await tester.tap(find.byKey(const ValueKey('scanButton')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      tester.view.physicalSize = const Size(320, 568);
      await tester.pump();
      expect(find.byKey(const ValueKey('photoScanScreen')), findsOneWidget);
      expect(find.text('Mau scan lewat apa?'), findsNothing);
      expect(find.byKey(const ValueKey('galleryButton')), findsOneWidget);
      for (final mode in ScanMode.values) {
        expect(
          find.byKey(ValueKey('scanMode-${mode.name}')).hitTestable(),
          findsOneWidget,
        );
      }
      for (var i = 0; i < 2; i++) {
        await tester.tap(find.byKey(const ValueKey('scanMode-label')));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 500));
        await tester.pump(const Duration(milliseconds: 500));
        expect(find.byKey(const ValueKey('labelScanScreen')), findsOneWidget);
        expect(find.byType(ScanScreen, skipOffstage: false), findsOneWidget);
        expect(
          find.byKey(const ValueKey('manualNutritionLabel')),
          findsOneWidget,
        );
        await tester.tap(find.byKey(const ValueKey('scanMode-photo')));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 500));
        expect(find.byKey(const ValueKey('photoScanScreen')), findsOneWidget);
        expect(find.byType(ScanScreen, skipOffstage: false), findsOneWidget);
      }
      tester.view.physicalSize = const Size(390, 844);
      router.pop();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.byKey(const ValueKey('dashboardScreen')), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('old photo link still resolves directly to the default camera', (
    tester,
  ) async {
    final router = createAppRouter(onboardingComplete: true);
    addTearDown(router.dispose);
    router.go('/scan/photo');
    await tester.pumpWidget(StevAiApp(router: router));
    await tester.pump(const Duration(milliseconds: 500));
    expect(router.routeInformationProvider.value.uri.path, '/scan');
    expect(find.byKey(const ValueKey('photoScanScreen')), findsOneWidget);
    expect(find.byType(ScanScreen, skipOffstage: false), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('inline barcode control selects barcode mode without a chooser', (
    tester,
  ) async {
    ScanMode? selected;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ScanModeSwitcher(
            selected: ScanMode.photo,
            onChanged: (mode) => selected = mode,
          ),
        ),
      ),
    );
    await tester.tap(find.byKey(const ValueKey('scanMode-barcode')));
    expect(selected, ScanMode.barcode);
    expect(selected!.route, '/scan/barcode');
  });
}
