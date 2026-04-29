import 'package:equatable/equatable.dart';
import 'package:healthy_hour/src/domain/domain.dart';

abstract class SettingsEvent extends Equatable {
  const SettingsEvent();

  @override
  List<Object?> get props => [];
}

final class SettingsStarted extends SettingsEvent {
  const SettingsStarted();
}

final class SettingsWindowChanged extends SettingsEvent {
  const SettingsWindowChanged(this.window);
  final WorkingWindow window;

  @override
  List<Object?> get props => [window];
}

final class SettingsWaterChanged extends SettingsEvent {
  const SettingsWaterChanged(this.config);
  final TimerConfig config;

  @override
  List<Object?> get props => [config];
}

final class SettingsWalkingChanged extends SettingsEvent {
  const SettingsWalkingChanged(this.config);
  final TimerConfig config;

  @override
  List<Object?> get props => [config];
}
