import 'dart:async';
import 'dart:developer';

import 'package:bloc/bloc.dart';
import 'package:flutter/widgets.dart';
import 'package:healthy_hour/src/app.dart';
import 'package:healthy_hour/src/app_observer.dart';
import 'package:healthy_hour/src/data/data.dart';
import 'package:healthy_hour/src/flavor.dart';

Future<void> bootstrap(Flavor flavor) async {
  FlutterError.onError = (details) {
    log(details.exceptionAsString(), stackTrace: details.stack);
  };

  Bloc.observer = const AppBlocObserver();

  await runZonedGuarded(
    () async {
      WidgetsFlutterBinding.ensureInitialized();
      final data = await DataBootstrap.initialize();
      runApp(
        HealthyHourApp(
          flavor: flavor,
          sessions: data.sessions,
          settings: data.settings,
        ),
      );
    },
    (error, stack) => log(error.toString(), stackTrace: stack),
  );
}
