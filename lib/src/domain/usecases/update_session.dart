import 'package:healthy_hour/src/domain/entities/session.dart';
import 'package:healthy_hour/src/domain/repositories/session_repository.dart';

class UpdateSession {
  const UpdateSession(this._repo);
  final SessionRepository _repo;

  Future<Session> call(Session session) => _repo.updateSession(session);
}
