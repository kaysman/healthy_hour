import 'package:healthy_hour/src/domain/entities/activity_kind.dart';
import 'package:healthy_hour/src/domain/entities/session.dart';
import 'package:healthy_hour/src/domain/repositories/session_repository.dart';

class StartSession {
  const StartSession(this._repo);
  final SessionRepository _repo;

  Future<Session> call({
    required ActivityKind kind,
    required DateTime now,
    required String idGenerator,
  }) async {
    final current = await _repo.currentSession();
    if (current != null) {
      // Discard sessions shorter than a minute — they're almost always
      // accidental taps and clutter the timeline.
      if (now.difference(current.startedAt) < const Duration(minutes: 1)) {
        await _repo.deleteSession(current.id);
      } else {
        await _repo.endSession(current.id, endedAt: now);
      }
    }
    return _repo.startSession(
      Session(id: idGenerator, kind: kind, startedAt: now),
    );
  }
}
