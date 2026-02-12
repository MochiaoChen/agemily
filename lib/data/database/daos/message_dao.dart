import 'package:drift/drift.dart';
import '../database.dart';
import '../tables.dart';

part 'message_dao.g.dart';

@DriftAccessor(tables: [Messages])
class MessageDao extends DatabaseAccessor<AppDatabase>
    with _$MessageDaoMixin {
  MessageDao(super.db);

  Future<List<Message>> getMessagesForSession(String sessionId) {
    return (select(messages)
          ..where((t) => t.sessionId.equals(sessionId))
          ..orderBy([(t) => OrderingTerm.asc(t.sortOrder)]))
        .get();
  }

  Stream<List<Message>> watchMessagesForSession(String sessionId) {
    return (select(messages)
          ..where((t) => t.sessionId.equals(sessionId))
          ..orderBy([(t) => OrderingTerm.asc(t.sortOrder)]))
        .watch();
  }

  Future<int> getMessageCount(String sessionId) async {
    final count = messages.id.count();
    final query = selectOnly(messages)
      ..addColumns([count])
      ..where(messages.sessionId.equals(sessionId));
    final row = await query.getSingle();
    return row.read(count) ?? 0;
  }

  Future<int> getNextSortOrder(String sessionId) async {
    final maxOrder = messages.sortOrder.max();
    final query = selectOnly(messages)
      ..addColumns([maxOrder])
      ..where(messages.sessionId.equals(sessionId));
    final row = await query.getSingle();
    return (row.read(maxOrder) ?? -1) + 1;
  }

  Future<void> insertMessage(MessagesCompanion message) {
    return into(messages).insert(message);
  }

  Future<void> updateMessage(String id, MessagesCompanion companion) {
    return (update(messages)..where((t) => t.id.equals(id)))
        .write(companion);
  }

  Future<void> deleteMessagesForSession(String sessionId) {
    return (delete(messages)..where((t) => t.sessionId.equals(sessionId)))
        .go();
  }

  Future<void> markAsCompactionSummary(String id) {
    return updateMessage(
      id,
      const MessagesCompanion(isCompactionSummary: Value(true)),
    );
  }
}
