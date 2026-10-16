import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:steviai/app/app.dart';
import 'package:steviai/app/router.dart';
import 'package:steviai/features/scan/presentation/scan_screen.dart';

void main() {
  testWidgets('reloaded barcode result without its drink returns to scanner', (
    tester,
  ) async {
    final router = createAppRouter(onboardingComplete: true);
    addTearDown(router.dispose);
    router.go('/result?barcodeMl=250');
    await tester.pumpWidget(StevAiApp(router: router));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));
    expect(find.byKey(const ValueKey('barcodeScanScreen')), findsOneWidget);
    expect(find.byKey(const ValueKey('resultScreen')), findsNothing);
  });
  setUp(
    () => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('plugins.flutter.io/camera'),
          (call) async => call.method == 'availableCameras' ? [] : null,
        ),
  );
  tearDown(
    () => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('plugins.flutter.io/camera'),
          null,
        ),
  );
  testWidgets(
    'one tap opens photo camera without tabs or label entry on a small screen',
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
      await tester.pump(const Duration(milliseconds: 600));
      await tester.pump(const Duration(milliseconds: 600));
      tester.view.physicalSize = const Size(320, 568);
      await tester.pump();
      expect(find.byKey(const ValueKey('photoScanScreen')), findsOneWidget);
      expect(
        find.byKey(const ValueKey('galleryButton')).hitTestable(),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('openBarcodeScanner')).hitTestable(),
        findsOneWidget,
      );
      expect(find.text('Arahkan ke minuman atau barcode'), findsOneWidget);
      expect(find.text('Label Gizi'), findsNothing);
      expect(find.byKey(const ValueKey('manualNutritionLabel')), findsNothing);
      expect(tester.takeException(), isNull);
      // Replacing the scanner does not leave a hidden photo camera below it.
      await tester.tap(find.byKey(const ValueKey('openBarcodeScanner')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));
      await tester.pump(const Duration(milliseconds: 600));
      expect(find.byKey(const ValueKey('barcodeScanScreen')), findsOneWidget);
      expect(find.byType(ScanScreen, skipOffstage: false), findsNothing);
      expect(find.byKey(const ValueKey('barcodeInput')), findsNothing);
      tester.view.physicalSize = const Size(390, 844);
      router.go('/');
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));
      await tester.pump(const Duration(milliseconds: 600));
      expect(find.byKey(const ValueKey('dashboardScreen')), findsOneWidget);
    },
  );
  testWidgets('old photo link still resolves directly to the camera', (
    tester,
  ) async {
    final router = createAppRouter(onboardingComplete: true);
    addTearDown(router.dispose);
    router.go('/scan/photo');
    await tester.pumpWidget(StevAiApp(router: router));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));
    await tester.pump(const Duration(milliseconds: 600));
    expect(router.routeInformationProvider.value.uri.path, '/scan');
    expect(find.byType(ScanScreen, skipOffstage: false), findsOneWidget);
  });
  testWidgets(
    'unrecognized photo offers only drink types present in the catalog',
    (tester) async {
      final router = createAppRouter(onboardingComplete: true);
      addTearDown(router.dispose);
      router.go('/scan/unrecognized');
      await tester.pumpWidget(StevAiApp(router: router));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));
      await tester.pump(const Duration(milliseconds: 600));
      expect(find.text('Belum kenal minuman ini'), findsOneWidget);
      expect(find.text('Es teh'), findsOneWidget);
      expect(find.text('Kopi susu'), findsOneWidget);
      expect(find.text('Teh susu'), findsNothing);
      expect(find.text('Cokelat'), findsOneWidget);
      await tester.tap(find.text('Es teh'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));
      await tester.pump(const Duration(milliseconds: 600));
      expect(find.byKey(const ValueKey('resultScreen')), findsOneWidget);
      expect(find.text('Es teh manis'), findsOneWidget);
    },
  );
}
