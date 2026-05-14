import 'package:flutter/foundation.dart';
import 'dart:convert';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:logging/logging.dart';
import 'package:chatmcp/echo/auth_service.dart';
import 'package:chatmcp/echo/echo_api_client.dart';

final _log = Logger('echo.notifications');

final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();

const _channelId = 'echo_evening_signal';
const _channelName = 'Evening Signal';
const _notifId = 42;
const _trainingReadyNotifId = 44;

/// Initialize and schedule the nightly Evening Signal notification.
/// Safe to call on all platforms — silently no-ops on desktop/web.
Future<void> initNotifications({required Future<void> Function(String? payload) onTap}) async {
  if (kIsWeb || (!_isMobile)) return;

  tz.initializeTimeZones();

  const android = AndroidInitializationSettings('@mipmap/launcher_icon');
  const ios = DarwinInitializationSettings(requestAlertPermission: true, requestBadgePermission: true, requestSoundPermission: true);

  await _plugin.initialize(
    const InitializationSettings(android: android, iOS: ios),
    onDidReceiveNotificationResponse: (response) async => onTap(response.payload),
    onDidReceiveBackgroundNotificationResponse: _bgHandler,
  );

  await _plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()?.requestNotificationsPermission();

  await _scheduleEveningSignal();
  await syncEchoInterventionNotification();
  await syncTrainingReadyNotification();
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
    iOS: DarwinNotificationDetails(presentAlert: true, presentBadge: true, presentSound: true),
  );

  // On Android 12+ SCHEDULE_EXACT_ALARM may be revoked by the user.
  // Check first and fall back to inexact if not permitted.
  AndroidScheduleMode scheduleMode = AndroidScheduleMode.inexact;
  if (defaultTargetPlatform == TargetPlatform.android) {
    final androidImpl = _plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
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
    uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
    matchDateTimeComponents: DateTimeComponents.time,
  );

  _log.info('Evening Signal scheduled for ${scheduled.hour}:00 daily (exact: ${scheduleMode == AndroidScheduleMode.exactAllowWhileIdle})');
}

Future<void> syncEchoInterventionNotification() async {
  if (kIsWeb || (!_isMobile) || !AuthService().isLoggedIn) return;
  try {
    final data = await EchoApiClient().getNextIntervention();
    final intervention = data?['intervention'];
    if (intervention is! Map) return;

    final id = intervention['id']?.toString();
    final title = intervention['title']?.toString() ?? 'Echo noticed something';
    final body = intervention['body']?.toString() ?? 'Open Today to see the next useful move.';
    final scheduledRaw = intervention['scheduled_for']?.toString();
    if (id == null || id.isEmpty) return;

    var scheduled = tz.TZDateTime.now(tz.local).add(const Duration(minutes: 2));
    if (scheduledRaw != null && scheduledRaw.isNotEmpty) {
      final parsed = DateTime.tryParse(scheduledRaw.replaceFirst(' ', 'T'));
      if (parsed != null) {
        scheduled = tz.TZDateTime.from(parsed.toLocal(), tz.local);
        if (scheduled.isBefore(tz.TZDateTime.now(tz.local))) {
          scheduled = tz.TZDateTime.now(tz.local).add(const Duration(minutes: 2));
        }
      }
    }

    const details = NotificationDetails(
      android: AndroidNotificationDetails(
        _channelId,
        _channelName,
        channelDescription: 'Trusted Echo interventions with visible reasons',
        importance: Importance.high,
        priority: Priority.high,
        enableLights: true,
        playSound: true,
      ),
      iOS: DarwinNotificationDetails(presentAlert: true, presentBadge: true, presentSound: true),
    );

    await _plugin.zonedSchedule(
      id.hashCode & 0x7fffffff,
      title,
      body,
      scheduled,
      details,
      payload: jsonEncode({'id': id, 'kind': intervention['kind']?.toString(), 'action': intervention['action']}),
      androidScheduleMode: AndroidScheduleMode.inexact,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
    );
    await EchoApiClient().ackIntervention(id, status: 'delivered');
    _log.info('Echo intervention scheduled: $title at $scheduled');
  } catch (e) {
    _log.warning('syncEchoInterventionNotification error: $e');
  }
}

Future<void> syncTrainingReadyNotification() async {
  if (kIsWeb || (!_isMobile) || !AuthService().isLoggedIn) return;
  try {
    await _plugin.cancel(_trainingReadyNotifId);
    final summary = await EchoApiClient().getTrainingSummary(lane: 'gemma4_e2b');
    final ready = summary?['can_train_now'] == true || summary?['ready_for_training'] == true;
    if (!ready) return;

    final untrained = (summary?['untrained_pairs'] as num?)?.toInt() ?? 0;
    final dpoReady = (summary?['dpo_ready_pairs'] as num?)?.toInt() ?? 0;
    final dpoRequired = (summary?['dpo_required_pairs'] as num?)?.toInt() ?? 4;
    final scheduled = tz.TZDateTime.now(tz.local).add(const Duration(minutes: 1));

    const details = NotificationDetails(
      android: AndroidNotificationDetails(
        _channelId,
        _channelName,
        channelDescription: 'Echo model training readiness',
        importance: Importance.high,
        priority: Priority.high,
        enableLights: true,
        playSound: true,
      ),
      iOS: DarwinNotificationDetails(presentAlert: true, presentBadge: true, presentSound: true),
    );

    await _plugin.zonedSchedule(
      _trainingReadyNotifId,
      'Echo is ready to update',
      '$untrained new moments and $dpoReady/$dpoRequired lessons are ready. Open Improve Echo to update Echo.',
      scheduled,
      details,
      payload: jsonEncode({
        'kind': 'training_ready',
        'action': {'type': 'open_training'},
      }),
      androidScheduleMode: AndroidScheduleMode.inexact,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
    );
    _log.info('Training-ready notification scheduled for $scheduled');
  } catch (e) {
    _log.warning('syncTrainingReadyNotification error: $e');
  }
}

bool get _isMobile {
  try {
    return defaultTargetPlatform == TargetPlatform.android || defaultTargetPlatform == TargetPlatform.iOS;
  } catch (_) {
    return false;
  }
}
