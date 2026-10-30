import 'package:equatable/equatable.dart';

/// User-defined working hours (the "Working Time" button on Home).
class WorkingWindow extends Equatable {
  const WorkingWindow({
    required this.startMinutes,
    required this.endMinutes,
  });

  /// Minutes since midnight when the working window opens.
  final int startMinutes;

  /// Minutes since midnight when the working window closes.
  final int endMinutes;

  static const defaultWindow =
      WorkingWindow(startMinutes: 9 * 60, endMinutes: 18 * 60);

  Duration get length => Duration(minutes: endMinutes - startMinutes);

  /// The moment the window opens on [day]'s calendar date.
  DateTime startOn(DateTime day) =>
      DateTime(day.year, day.month, day.day, 0, startMinutes);

  /// The moment the window closes on [day]'s calendar date.
  DateTime endOn(DateTime day) =>
      DateTime(day.year, day.month, day.day, 0, endMinutes);

  WorkingWindow copyWith({int? startMinutes, int? endMinutes}) {
    return WorkingWindow(
      startMinutes: startMinutes ?? this.startMinutes,
      endMinutes: endMinutes ?? this.endMinutes,
    );
  }

  @override
  List<Object?> get props => [startMinutes, endMinutes];
}
