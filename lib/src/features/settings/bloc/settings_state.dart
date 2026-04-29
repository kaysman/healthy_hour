import 'package:equatable/equatable.dart';
import 'package:healthy_hour/src/domain/domain.dart';

class SettingsState extends Equatable {
  const SettingsState({
    this.window = WorkingWindow.defaultWindow,
    this.water = TimerConfig.water,
    this.walking = TimerConfig.walking,
  });

  final WorkingWindow window;
  final TimerConfig water;
  final TimerConfig walking;

  SettingsState copyWith({
    WorkingWindow? window,
    TimerConfig? water,
    TimerConfig? walking,
  }) {
    return SettingsState(
      window: window ?? this.window,
      water: water ?? this.water,
      walking: walking ?? this.walking,
    );
  }

  @override
  List<Object?> get props => [window, water, walking];
}
