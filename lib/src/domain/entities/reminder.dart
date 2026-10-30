import 'package:equatable/equatable.dart';

enum ReminderKind { water, walking }

/// One notification due at [at]. [overdueBy] is how long the countdown has
/// been running at that moment — "it's been 50 min since your last drink".
class Reminder extends Equatable {
  const Reminder({
    required this.id,
    required this.kind,
    required this.at,
    required this.overdueBy,
  });

  /// Unique within one plan. Plans are replaced wholesale, so ids only need
  /// to be stable for as long as a plan is scheduled.
  final int id;
  final ReminderKind kind;
  final DateTime at;
  final Duration overdueBy;

  @override
  List<Object?> get props => [id, kind, at, overdueBy];
}
