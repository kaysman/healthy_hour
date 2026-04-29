import 'package:healthy_hour/src/domain/domain.dart';
import 'package:hive_ce/hive.dart';

part 'session_model.g.dart';

@HiveType(typeId: 1)
class SessionModel extends HiveObject {
  SessionModel({
    required this.id,
    required this.kindIndex,
    required this.startedAt,
    this.endedAt,
  });

  @HiveField(0)
  String id;

  @HiveField(1)
  int kindIndex;

  @HiveField(2)
  DateTime startedAt;

  @HiveField(3)
  DateTime? endedAt;

  Session toEntity() => Session(
        id: id,
        kind: ActivityKind.values[kindIndex],
        startedAt: startedAt,
        endedAt: endedAt,
      );

  static SessionModel fromEntity(Session s) => SessionModel(
        id: s.id,
        kindIndex: s.kind.index,
        startedAt: s.startedAt,
        endedAt: s.endedAt,
      );
}
