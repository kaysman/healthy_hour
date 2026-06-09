import 'package:healthy_hour/src/domain/entities/activity_kind.dart';
import 'package:healthy_hour/src/domain/entities/session.dart';
import 'package:healthy_hour/src/domain/repositories/session_repository.dart';

/// Ends the current session (if any) and starts a new one of the opposite
/// kind. This is the action wired to the big "Have a walk" / "Continue
/// working" CTA on Home.
class SwitchActivity {
  const SwitchActivity(this._repo);
  final SessionRepository _repo;

  Future<Session> call({
    required DateTime now,
    required String idGenerator,
    ActivityKind? to,
  }) async {
    final current = await _repo.currentSession();
    final nextKind = to ?? (current?.kind.opposite ?? ActivityKind.working);
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
      Session(id: idGenerator, kind: nextKind, startedAt: now),
    );
  }
}
