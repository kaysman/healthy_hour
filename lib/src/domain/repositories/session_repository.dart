import 'package:healthy_hour/src/domain/entities/session.dart';

abstract class SessionRepository {
  Stream<List<Session>> watchSessions({DateTime? from, DateTime? to});

  Future<Session?> currentSession();

  Future<Session> startSession(Session session);

  Future<Session> endSession(String id, {required DateTime endedAt});

  Future<Session> updateSession(Session session);

  Future<void> deleteSession(String id);
}
