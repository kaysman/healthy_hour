import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:healthy_hour/src/domain/domain.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

/// [ReminderScheduler] backed by `flutter_local_notifications`.
///
/// Reminders go out with [AndroidScheduleMode.inexactAllowWhileIdle]: exact
/// alarms need `SCHEDULE_EXACT_ALARM`, which Android 14 denies by default
/// and Play restricts to alarm-clock and calendar apps. A drink reminder a
/// minute or two late costs nothing.
class LocalNotificationScheduler implements ReminderScheduler {
  LocalNotificationScheduler._(this._plugin);

  final FlutterLocalNotificationsPlugin _plugin;

  static const _water = AndroidNotificationDetails(
    'water',
    'Water reminders',
    channelDescription: 'Nudges to drink water during working hours.',
    icon: 'ic_notification',
  );

  static const _walking = AndroidNotificationDetails(
    'walking',
    'Walking reminders',
    channelDescription: 'Nudges to get up and walk after a long stretch.',
    icon: 'ic_notification',
  );

  static Future<LocalNotificationScheduler> initialize() async {
    tz_data.initializeTimeZones();
    final local = await FlutterTimezone.getLocalTimezone();
    tz.setLocalLocation(tz.getLocation(local.identifier));

    final plugin = FlutterLocalNotificationsPlugin();
    await plugin.initialize(
      const InitializationSettings(
        android: AndroidInitializationSettings('ic_notification'),
        // Permission is asked for explicitly, once Home is on screen.
        iOS: DarwinInitializationSettings(
          requestAlertPermission: false,
          requestBadgePermission: false,
          requestSoundPermission: false,
        ),
      ),
    );
    return LocalNotificationScheduler._(plugin);
  }

  @override
  Future<bool> requestPermission() async {
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return await _plugin
                .resolvePlatformSpecificImplementation<
                    AndroidFlutterLocalNotificationsPlugin>()
                ?.requestNotificationsPermission() ??
            false;
      case TargetPlatform.iOS:
        return await _plugin
                .resolvePlatformSpecificImplementation<
                    IOSFlutterLocalNotificationsPlugin>()
                ?.requestPermissions(alert: true, sound: true) ??
            false;
      case TargetPlatform.fuchsia:
      case TargetPlatform.linux:
      case TargetPlatform.macOS:
      case TargetPlatform.windows:
        return false;
    }
  }

  @override
  Future<void> replaceAll(List<Reminder> plan) async {
    await _plugin.cancelAll();
    for (final r in plan) {
      final (title, body, android) = switch (r.kind) {
        ReminderKind.water => (
            'Time for some water 💧',
            "It's been ${_minutes(r.overdueBy)} since your last drink.",
            _water,
          ),
        ReminderKind.walking => (
            'Time for a walk 👟',
            "You've been working for ${_minutes(r.overdueBy)}.",
            _walking,
          ),
      };
      await _plugin.zonedSchedule(
        r.id,
        title,
        body,
        tz.TZDateTime.from(r.at, tz.local),
        NotificationDetails(
          android: android,
          iOS: const DarwinNotificationDetails(),
        ),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      );
    }
  }

  static String _minutes(Duration d) {
    final h = d.inHours;
    final m = d.inMinutes.remainder(60);
    if (h == 0) return '$m min';
    if (m == 0) return '$h h';
    return '$h h $m min';
  }
}
