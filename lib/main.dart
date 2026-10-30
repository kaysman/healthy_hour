import 'dart:async';
import 'dart:developer';

import 'package:bloc/bloc.dart';
import 'package:flutter/widgets.dart';
import 'package:healthy_hour/src/app.dart';
import 'package:healthy_hour/src/app_observer.dart';
import 'package:healthy_hour/src/data/data.dart';
import 'package:healthy_hour/src/features/reminders/reminder_coordinator.dart';

void main() {
  FlutterError.onError = (details) {
    log(details.exceptionAsString(), stackTrace: details.stack);
  };

  Bloc.observer = const AppBlocObserver();

  runZonedGuarded(
    () async {
      WidgetsFlutterBinding.ensureInitialized();
      final data = await DataBootstrap.initialize();
      final scheduler = await LocalNotificationScheduler.initialize();
      ReminderCoordinator(
        sessions: data.sessions,
        settings: data.settings,
        hydration: data.hydration,
        scheduler: scheduler,
      ).start();
      runApp(
        HealthyHourApp(
          sessions: data.sessions,
          settings: data.settings,
          hydration: data.hydration,
        ),
      );
      // Ask once Home is on screen, so the prompt has the app behind it.
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => unawaited(scheduler.requestPermission()),
      );
    },
    (error, stack) => log(error.toString(), stackTrace: stack),
  );
}
