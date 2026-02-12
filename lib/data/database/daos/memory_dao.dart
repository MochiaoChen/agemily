import 'package:drift/drift.dart';
import '../database.dart';
import '../tables.dart';

part 'memory_dao.g.dart';

@DriftAccessor(tables: [MemoryNotes])
class MemoryDao extends DatabaseAccessor<AppDatabase>
    with _$MemoryDaoMixin {
  MemoryDao(super.db);

  Future<List<MemoryNote>> getAllNotes() {
    return (select(memoryNotes)
          ..orderBy([(t) => OrderingTerm.desc(t.updatedAt)]))
        .get();
  }

  Stream<List<MemoryNote>> watchAllNotes() {
    return (select(memoryNotes)
          ..orderBy([(t) => OrderingTerm.desc(t.updatedAt)]))
        .watch();
  }

  Future<List<MemoryNote>> getRecentNotes({int limit = 20}) {
    return (select(memoryNotes)
          ..orderBy([(t) => OrderingTerm.desc(t.updatedAt)])
          ..limit(limit))
        .get();
  }

  Future<void> upsertNote(MemoryNotesCompanion note) {
    return into(memoryNotes).insertOnConflictUpdate(note);
  }

  Future<List<MemoryNote>> getAutoNotes() {
    return (select(memoryNotes)
          ..where((t) => t.tags.like('%"auto"%'))
          ..orderBy([(t) => OrderingTerm.desc(t.updatedAt)]))
        .get();
  }

  Future<void> replaceAutoNotes(List<MemoryNotesCompanion> notes) {
    return transaction(() async {
      await (delete(memoryNotes)..where((t) => t.tags.like('%"auto"%'))).go();
      for (final note in notes) {
        await into(memoryNotes).insert(note);
      }
    });
  }

  /// Batch-update tags and updatedAt for hit tracking.
  Future<void> batchUpdateTags(Map<String, String> idToTags) {
    return transaction(() async {
      final now = DateTime.now();
      for (final entry in idToTags.entries) {
        await (update(memoryNotes)..where((t) => t.id.equals(entry.key)))
            .write(MemoryNotesCompanion(
          tags: Value(entry.value),
          updatedAt: Value(now),
        ));
      }
    });
  }

  Future<void> deleteNote(String id) {
    return (delete(memoryNotes)..where((t) => t.id.equals(id))).go();
  }
}
