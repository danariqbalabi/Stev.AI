import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

abstract final class HomeWidgetBridge {
  static const channelName = 'com.joints.steviai/home_widget';
  static const _channel = MethodChannel(channelName);

  static bool get _isAndroid =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  static Future<void> initialize(GoRouter router) async {
    if (!_isAndroid) return;

    _channel.setMethodCallHandler((call) async {
      if (call.method == 'openRoute' && call.arguments is String) {
        _openRoute(router, call.arguments as String);
      }
    });

    try {
      final initialRoute = await _channel.invokeMethod<String>(
        'getInitialRoute',
      );
      if (initialRoute != null) _openRoute(router, initialRoute);
    } on PlatformException {
      // The Android bridge is optional on unsupported or older builds.
    } on MissingPluginException {
      // Keeps Flutter web/tests and hot restart resilient.
    }
  }

  static Future<void> update() async {
    if (!_isAndroid) return;
    try {
      await _channel.invokeMethod<void>('updateWidget');
    } on PlatformException {
      // The app remains usable even if the launcher rejects widget updates.
    } on MissingPluginException {
      // No native widget exists on non-Android targets.
    }
  }

  static void _openRoute(GoRouter router, String route) {
    if (route == '/scan') router.go('/scan');
  }
}
