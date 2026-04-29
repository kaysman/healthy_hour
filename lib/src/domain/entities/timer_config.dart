import 'package:equatable/equatable.dart';

/// Per-activity timer config — shows how often the user should be reminded.
class TimerConfig extends Equatable {
  const TimerConfig({required this.interval});

  final Duration interval;

  static const water =
      TimerConfig(interval: Duration(minutes: 25, seconds: 25));
  static const walking =
      TimerConfig(interval: Duration(minutes: 25, seconds: 25));

  TimerConfig copyWith({Duration? interval}) =>
      TimerConfig(interval: interval ?? this.interval);

  @override
  List<Object?> get props => [interval];
}
