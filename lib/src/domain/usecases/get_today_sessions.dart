import 'package:healthy_hour/src/core/core.dart';
import 'package:healthy_hour/src/domain/entities/session.dart';
import 'package:healthy_hour/src/domain/repositories/session_repository.dart';

class GetTodaySessions {
  const GetTodaySessions(this._repo);
  final SessionRepository _repo;

  Stream<List<Session>> call({required DateTime now}) {
    return _repo.watchSessions(
      from: now.atStartOfDay,
      to: now.atEndOfDay,
    );
  }
}
