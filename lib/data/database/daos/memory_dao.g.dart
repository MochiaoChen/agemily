// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'memory_dao.dart';

// ignore_for_file: type=lint
mixin _$MemoryDaoMixin on DatabaseAccessor<AppDatabase> {
  $MemoryNotesTable get memoryNotes => attachedDatabase.memoryNotes;
  MemoryDaoManager get managers => MemoryDaoManager(this);
}

class MemoryDaoManager {
  final _$MemoryDaoMixin _db;
  MemoryDaoManager(this._db);
  $$MemoryNotesTableTableManager get memoryNotes =>
      $$MemoryNotesTableTableManager(_db.attachedDatabase, _db.memoryNotes);
}
