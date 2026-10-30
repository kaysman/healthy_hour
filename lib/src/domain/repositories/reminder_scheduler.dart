import 'package:healthy_hour/src/domain/entities/reminder.dart';

/// Delivers [Reminder]s as OS notifications, including while the app is
/// closed. The domain only ever hands over a complete plan.
abstract class ReminderScheduler {
  /// Asks the OS for permission to notify. Returns whether it was granted.
  Future<bool> requestPermission();

  /// Cancels everything pending and schedules [plan] in its place.
  Future<void> replaceAll(List<Reminder> plan);
}
