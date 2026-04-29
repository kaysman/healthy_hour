import 'package:healthy_hour/src/domain/entities/timer_config.dart';
import 'package:healthy_hour/src/domain/entities/working_window.dart';

abstract class SettingsRepository {
  Stream<WorkingWindow> watchWorkingWindow();
  Future<WorkingWindow> getWorkingWindow();
  Future<void> setWorkingWindow(WorkingWindow window);

  Stream<TimerConfig> watchWaterConfig();
  Future<TimerConfig> getWaterConfig();
  Future<void> setWaterConfig(TimerConfig config);

  Stream<TimerConfig> watchWalkingConfig();
  Future<TimerConfig> getWalkingConfig();
  Future<void> setWalkingConfig(TimerConfig config);
}
