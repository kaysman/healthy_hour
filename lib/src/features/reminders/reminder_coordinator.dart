import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:healthy_hour/src/core/core.dart';
import 'package:healthy_hour/src/domain/domain.dart';
import 'package:rxdart/rxdart.dart';

/// Keeps the OS notification schedule in step with the app's data.
///
/// Whenever anything a reminder depends on changes — a session starts or
/// ends, a drink is logged, a setting moves — the whole plan is recomputed
/// with [planReminders] and handed to the scheduler, which cancels what was
/// pending and schedules the new plan. No diffing, no background job: the
/// schedule is always exactly what the current data implies.
class ReminderCoordinator {
  ReminderCoordinator({
    required SessionRepository sessions,
    required SettingsRepository settings,
    required HydrationRepository hydration,
    required ReminderScheduler scheduler,
    Clock? clock,
  })  : _sessions = sessions,
        _settings = settings,
        _hydration = hydration,
        _scheduler = scheduler,
        _clock = clock ?? DateTime.now;

  final SessionRepository _sessions;
  final SettingsRepository _settings;
  final HydrationRepository _hydration;
  final ReminderScheduler _scheduler;
  final Clock _clock;

  StreamSubscription<void>? _sub;

  void start() {
    _sub ??= Rx.combineLatest5(
      _sessions.watchSessions().map(_ongoing),
      _settings.watchWorkingWindow(),
      _settings.watchWaterConfig(),
      _settings.watchWalkingConfig(),
      _hydration.watchLastDrink(),
      (current, window, water, walking, lastDrinkAt) => planReminders(
        now: _clock(),
        current: current,
        window: window,
        water: water,
        walking: walking,
        lastDrinkAt: lastDrinkAt,
      ),
    )
        .distinct(listEquals)
        // asyncMap waits for each replaceAll to finish before starting the
        // next, so two plans can never interleave their cancel/schedule calls.
        .asyncMap(_scheduler.replaceAll)
        .listen(null);
  }

  Future<void> stop() async {
    await _sub?.cancel();
    _sub = null;
  }

  static Session? _ongoing(List<Session> sessions) {
    Session? latest;
    for (final s in sessions) {
      if (s.isOngoing &&
          (latest == null || s.startedAt.isAfter(latest.startedAt))) {
        latest = s;
      }
    }
    return latest;
  }
}
