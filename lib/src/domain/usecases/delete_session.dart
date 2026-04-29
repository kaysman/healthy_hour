import 'package:healthy_hour/src/domain/repositories/session_repository.dart';

class DeleteSession {
  const DeleteSession(this._repo);
  final SessionRepository _repo;

  Future<void> call(String id) => _repo.deleteSession(id);
}
