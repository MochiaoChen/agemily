import 'package:drift/drift.dart';
import '../database.dart';
import '../tables.dart';

part 'session_dao.g.dart';

@DriftAccessor(tables: [Sessions])
class SessionDao extends DatabaseAccessor<AppDatabase>
    with _$SessionDaoMixin {
  SessionDao(super.db);

  Future<List<Session>> getAllSessions({bool includeArchived = false}) {
    final query = select(sessions)
      ..orderBy([(t) => OrderingTerm.desc(t.updatedAt)]);
    if (!includeArchived) {
      query.where((t) => t.isArchived.equals(false));
    }
    return query.get();
  }

  Stream<List<Session>> watchAllSessions({bool includeArchived = false}) {
    final query = select(sessions)
      ..orderBy([(t) => OrderingTerm.desc(t.updatedAt)]);
    if (!includeArchived) {
      query.where((t) => t.isArchived.equals(false));
    }
    return query.watch();
  }

  Future<Session?> getSessionById(String id) {
    return (select(sessions)..where((t) => t.id.equals(id)))
        .getSingleOrNull();
  }

  Future<Session?> getSessionByKey(String key) {
    return (select(sessions)..where((t) => t.sessionKey.equals(key)))
        .getSingleOrNull();
  }

  Future<void> upsertSession(SessionsCompanion session) {
    return into(sessions).insertOnConflictUpdate(session);
  }

  Future<void> updateSession(String id, SessionsCompanion companion) {
    return (update(sessions)..where((t) => t.id.equals(id)))
        .write(companion);
  }

  Future<void> archiveSession(String id) {
    return updateSession(
      id,
      SessionsCompanion(
        isArchived: const Value(true),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  Future<void> deleteSession(String id) {
    return (delete(sessions)..where((t) => t.id.equals(id))).go();
  }
}
