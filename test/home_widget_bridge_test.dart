import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:steviai/app/router.dart';
import 'package:steviai/features/home_widget/application/home_widget_bridge.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('Android home widget opens scan and accepts refresh requests', () async {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    final router = createAppRouter(onboardingComplete: true);
    final channel = MethodChannel(HomeWidgetBridge.channelName);
    final calls = <String>[];
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          calls.add(call.method);
          if (call.method == 'getInitialRoute') return '/scan';
          return null;
        });
    addTearDown(() {
      debugDefaultTargetPlatformOverride = null;
      router.dispose();
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, null);
    });

    await HomeWidgetBridge.initialize(router);
    await HomeWidgetBridge.update();

    expect(router.routeInformationProvider.value.uri.path, '/scan');
    expect(calls, ['getInitialRoute', 'updateWidget']);
  });
}
