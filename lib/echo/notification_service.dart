import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:logging/logging.dart';

final _log = Logger('echo.notifications');

final FlutterLocalNotificationsPlugin _plugin =
    FlutterLocalNotificationsPlugin();

const _channelId = 'echo_evening_signal';
const _channelName = 'Evening Signal';
const _notifId = 42;

/// Initialize and schedule the nightly Evening Signal notification.
/// Safe to call on all platforms — silently no-ops on desktop/web.
Future<void> initNotifications({
  required Future<void> Function() onTap,
}) async {
  if (kIsWeb || (!_isMobile)) return;

  tz.initializeTimeZones();

  const android = AndroidInitializationSettings('@mipmap/launcher_icon');
  const ios = DarwinInitializationSettings(
    requestAlertPermission: true,
    requestBadgePermission: true,
    requestSoundPermission: true,
  );

  await _plugin.initialize(
    const InitializationSettings(android: android, iOS: ios),
    onDidReceiveNotificationResponse: (_) async => onTap(),
    onDidReceiveBackgroundNotificationResponse: _bgHandler,
  );

  await _plugin
      .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>()
      ?.requestNotificationsPermission();

  await _scheduleEveningSignal();
}

@pragma('vm:entry-point')
void _bgHandler(NotificationResponse _) {}

Future<void> _scheduleEveningSignal() async {
  await _plugin.cancel(_notifId);

  final now = tz.TZDateTime.now(tz.local);
  var scheduled = tz.TZDateTime(tz.local, now.year, now.month, now.day, 19);
  if (scheduled.isBefore(now)) {
    scheduled = scheduled.add(const Duration(days: 1));
  }

  const details = NotificationDetails(
    android: AndroidNotificationDetails(
      _channelId,
      _channelName,
      channelDescription: 'Daily Evening Signal check-in reminder',
      importance: Importance.high,
      priority: Priority.high,
      enableLights: true,
      playSound: true,
    ),
    iOS: DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    ),
  );

  // On Android 12+ SCHEDULE_EXACT_ALARM may be revoked by the user.
  // Check first and fall back to inexact if not permitted.
  AndroidScheduleMode scheduleMode = AndroidScheduleMode.inexact;
  if (defaultTargetPlatform == TargetPlatform.android) {
    final androidImpl = _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    final canExact = await androidImpl?.canScheduleExactNotifications() ?? false;
    if (canExact) {
      scheduleMode = AndroidScheduleMode.exactAllowWhileIdle;
    } else {
      _log.info('Exact alarms not permitted — using inexact scheduling');
    }
  }

  await _plugin.zonedSchedule(
    _notifId,
    'Evening Signal',
    'Echo has something to ask. 3 questions · 5 minutes',
    scheduled,
    details,
    androidScheduleMode: scheduleMode,
    uiLocalNotificationDateInterpretation:
        UILocalNotificationDateInterpretation.absoluteTime,
    matchDateTimeComponents: DateTimeComponents.time,
  );

  _log.info('Evening Signal scheduled for ${scheduled.hour}:00 daily (exact: ${scheduleMode == AndroidScheduleMode.exactAllowWhileIdle})');
}

bool get _isMobile {
  try {
    return defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS;
  } catch (_) {
    return false;
  }
}
