import 'dart:async';

import 'package:healthy_hour/src/data/models/session_model.dart';
import 'package:healthy_hour/src/domain/domain.dart';
import 'package:hive_ce/hive.dart';
import 'package:rxdart/rxdart.dart';

class HiveSessionRepository implements SessionRepository {
  HiveSessionRepository(this._box);

  final Box<SessionModel> _box;

  late final BehaviorSubject<List<Session>> _subject =
      BehaviorSubject.seeded(_snapshot())..addStream(_changes());

  Stream<List<Session>> _changes() => _box.watch().map((_) => _snapshot());

  List<Session> _snapshot() {
    final list = _box.values.map((m) => m.toEntity()).toList()
      ..sort((a, b) => a.startedAt.compareTo(b.startedAt));
    return list;
  }

  @override
  Stream<List<Session>> watchSessions({DateTime? from, DateTime? to}) {
    return _subject.stream.map((all) {
      return all.where((s) {
        if (from != null && s.startedAt.isBefore(from)) return false;
        if (to != null && s.startedAt.isAfter(to)) return false;
        return true;
      }).toList();
    });
  }

  @override
  Future<Session?> currentSession() async {
    final ongoing = _box.values
        .map((m) => m.toEntity())
        .where((s) => s.isOngoing)
        .toList()
      ..sort((a, b) => b.startedAt.compareTo(a.startedAt));
    return ongoing.isEmpty ? null : ongoing.first;
  }

  @override
  Future<Session> startSession(Session session) async {
    await _box.put(session.id, SessionModel.fromEntity(session));
    return session;
  }

  @override
  Future<Session> endSession(String id, {required DateTime endedAt}) async {
    final m = _box.get(id);
    if (m == null) {
      throw StateError('Session $id not found');
    }
    m.endedAt = endedAt;
    await m.save();
    return m.toEntity();
  }

  @override
  Future<Session> updateSession(Session session) async {
    await _box.put(session.id, SessionModel.fromEntity(session));
    return session;
  }

  @override
  Future<void> deleteSession(String id) => _box.delete(id);

  Future<void> close() async {
    await _subject.close();
  }
}
