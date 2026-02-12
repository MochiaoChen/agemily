import 'package:drift/drift.dart';

class Sessions extends Table {
  TextColumn get id => text()();
  TextColumn get sessionKey => text().unique()();
  TextColumn get title => text().nullable()();
  TextColumn get model => text()();
  TextColumn get provider => text()();
  IntColumn get inputTokens => integer().withDefault(const Constant(0))();
  IntColumn get outputTokens => integer().withDefault(const Constant(0))();
  IntColumn get totalTokens => integer().withDefault(const Constant(0))();
  IntColumn get contextTokens => integer().withDefault(const Constant(0))();
  IntColumn get compactionCount => integer().withDefault(const Constant(0))();
  BoolColumn get isArchived => boolean().withDefault(const Constant(false))();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  DateTimeColumn get lastMessageAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

class Messages extends Table {
  TextColumn get id => text()();
  TextColumn get sessionId => text().references(Sessions, #id)();
  TextColumn get parentId => text().nullable()();
  TextColumn get role => text()();
  TextColumn get content => text()();
  TextColumn get model => text().nullable()();
  IntColumn get inputTokens => integer().nullable()();
  IntColumn get outputTokens => integer().nullable()();
  TextColumn get stopReason => text().nullable()();
  BoolColumn get isCompactionSummary =>
      boolean().withDefault(const Constant(false))();
  DateTimeColumn get createdAt => dateTime()();
  IntColumn get sortOrder => integer()();

  @override
  Set<Column> get primaryKey => {id};
}

class MemoryNotes extends Table {
  TextColumn get id => text()();
  TextColumn get title => text()();
  TextColumn get content => text()();
  TextColumn get sourceSessionId => text().nullable()();
  TextColumn get tags => text().withDefault(const Constant('[]'))();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

class Preferences extends Table {
  TextColumn get key => text()();
  TextColumn get value => text()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {key};
}
