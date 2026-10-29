import 'package:flutter/material.dart';
import 'package:healthy_hour/src/domain/domain.dart';
import 'package:healthy_hour/src/router.dart';
import 'package:healthy_hour_ui_kit/healthy_hour_ui_kit.dart';

class HealthyHourApp extends StatelessWidget {
  const HealthyHourApp({
    required this.sessions,
    required this.settings,
    required this.hydration,
    super.key,
  });

  final SessionRepository sessions;
  final SettingsRepository settings;
  final HydrationRepository hydration;

  @override
  Widget build(BuildContext context) {
    final router = buildRouter(
      sessions: sessions,
      settings: settings,
      hydration: hydration,
    );
    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      title: 'Healthy Hour',
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      routerConfig: router,
    );
  }
}
