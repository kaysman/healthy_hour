import 'package:flutter/material.dart';
import 'package:healthy_hour/src/domain/domain.dart';
import 'package:healthy_hour/src/flavor.dart';
import 'package:healthy_hour/src/router.dart';
import 'package:healthy_hour_ui_kit/healthy_hour_ui_kit.dart';

class HealthyHourApp extends StatelessWidget {
  const HealthyHourApp({
    required this.flavor,
    required this.sessions,
    required this.settings,
    super.key,
  });

  final Flavor flavor;
  final SessionRepository sessions;
  final SettingsRepository settings;

  @override
  Widget build(BuildContext context) {
    final router = buildRouter(sessions: sessions, settings: settings);
    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      title: flavor.title,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      routerConfig: router,
    );
  }
}
