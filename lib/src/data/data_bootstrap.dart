import 'package:healthy_hour/src/data/models/session_model.dart';
import 'package:healthy_hour/src/data/repositories/hive_session_repository.dart';
import 'package:healthy_hour/src/data/repositories/hive_settings_repository.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';

class DataBootstrap {
  const DataBootstrap({
    required this.sessions,
    required this.settings,
  });

  final HiveSessionRepository sessions;
  final HiveSettingsRepository settings;

  static Future<DataBootstrap> initialize() async {
    await Hive.initFlutter('healthy_hour');
    if (!Hive.isAdapterRegistered(1)) {
      Hive.registerAdapter(SessionModelAdapter());
    }
    final sessionsBox = await Hive.openBox<SessionModel>('sessions');
    final settingsBox = await Hive.openBox<dynamic>('settings');
    return DataBootstrap(
      sessions: HiveSessionRepository(sessionsBox),
      settings: HiveSettingsRepository(settingsBox),
    );
  }
}
