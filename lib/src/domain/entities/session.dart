import 'package:equatable/equatable.dart';
import 'package:healthy_hour/src/domain/entities/activity_kind.dart';

class Session extends Equatable {
  const Session({
    required this.id,
    required this.kind,
    required this.startedAt,
    this.endedAt,
  });

  final String id;
  final ActivityKind kind;
  final DateTime startedAt;
  final DateTime? endedAt;

  bool get isOngoing => endedAt == null;

  Duration durationAt(DateTime moment) =>
      (endedAt ?? moment).difference(startedAt);

  Session copyWith({
    String? id,
    ActivityKind? kind,
    DateTime? startedAt,
    DateTime? endedAt,
  }) {
    return Session(
      id: id ?? this.id,
      kind: kind ?? this.kind,
      startedAt: startedAt ?? this.startedAt,
      endedAt: endedAt ?? this.endedAt,
    );
  }

  @override
  List<Object?> get props => [id, kind, startedAt, endedAt];
}

extension SessionsX on Iterable<Session> {
  /// The session you're in: the latest one with no `endedAt`.
  Session? get ongoing {
    Session? latest;
    for (final s in this) {
      if (s.isOngoing &&
          (latest == null || s.startedAt.isAfter(latest.startedAt))) {
        latest = s;
      }
    }
    return latest;
  }
}
