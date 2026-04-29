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
