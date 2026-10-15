import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

enum RiskReminderScheduleStatus { scheduled, denied, unsupported, failed }

abstract interface class RiskReminderScheduler {
  Future<RiskReminderScheduleStatus> scheduleSevenDayReminder();

  Future<void> cancelReminder();
}

class LocalRiskReminderScheduler implements RiskReminderScheduler {
  LocalRiskReminderScheduler._();

  static final instance = LocalRiskReminderScheduler._();

  static const _notificationId = 7001;
  static const _payload = '/risk';
  static const _channelId = 'risk_check_reminders';
  static const _channelName = 'Pengingat cek kesehatan';

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  Future<void> initialize({required VoidCallback onOpenRisk}) async {
    if (_initialized) return;
    tz.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation('Asia/Jakarta'));

    const settings = InitializationSettings(
      android: AndroidInitializationSettings('ic_stat_stev'),
      iOS: DarwinInitializationSettings(
        requestAlertPermission: false,
        requestBadgePermission: false,
        requestSoundPermission: false,
      ),
    );
    await _plugin.initialize(
      settings: settings,
      onDidReceiveNotificationResponse: (response) {
        if (response.payload == _payload) onOpenRisk();
      },
    );
    _initialized = true;

    final launchDetails = await _plugin.getNotificationAppLaunchDetails();
    if (launchDetails?.didNotificationLaunchApp ?? false) {
      if (launchDetails?.notificationResponse?.payload == _payload) {
        onOpenRisk();
      }
    }
  }

  @override
  Future<RiskReminderScheduleStatus> scheduleSevenDayReminder() async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) {
      return RiskReminderScheduleStatus.unsupported;
    }
    if (!_initialized) return RiskReminderScheduleStatus.failed;

    final android = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    final permissionGranted = await android?.requestNotificationsPermission();
    if (permissionGranted == false) {
      return RiskReminderScheduleStatus.denied;
    }

    try {
      await _plugin.zonedSchedule(
        id: _notificationId,
        title: 'Waktunya cek kesehatan',
        body: 'Yuk lanjutkan langkah kecilmu dan cek gula darah.',
        scheduledDate: tz.TZDateTime.now(tz.local).add(const Duration(days: 7)),
        notificationDetails: const NotificationDetails(
          android: AndroidNotificationDetails(
            _channelId,
            _channelName,
            channelDescription:
                'Pengingat untuk melanjutkan pemeriksaan risiko diabetes.',
            icon: 'ic_stat_stev',
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        payload: _payload,
      );
      return RiskReminderScheduleStatus.scheduled;
    } catch (_) {
      return RiskReminderScheduleStatus.failed;
    }
  }

  @override
  Future<void> cancelReminder() => _plugin.cancel(id: _notificationId);
}
