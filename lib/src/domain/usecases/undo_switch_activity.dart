import 'package:healthy_hour/src/domain/entities/session.dart';
import 'package:healthy_hour/src/domain/repositories/session_repository.dart';

/// Reverses a `SwitchActivity`: drops the session it started and reopens
/// the one it ended, so an accidental tap on "Start walk" doesn't reset the
/// walking countdown of the work session it interrupted.
///
/// `previous` is the session as it was *before* the switch. It is written
/// back whole, which also restores it if the switch discarded it for being
/// under a minute.
class UndoSwitchActivity {
  const UndoSwitchActivity(this._repo);
  final SessionRepository _repo;

  Future<void> call({required Session started, Session? previous}) async {
    await _repo.deleteSession(started.id);
    if (previous != null) {
      await _repo.updateSession(
        Session(
          id: previous.id,
          kind: previous.kind,
          startedAt: previous.startedAt,
        ),
      );
    }
  }
}
