// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'message_dao.dart';

// ignore_for_file: type=lint
mixin _$MessageDaoMixin on DatabaseAccessor<AppDatabase> {
  $SessionsTable get sessions => attachedDatabase.sessions;
  $MessagesTable get messages => attachedDatabase.messages;
  MessageDaoManager get managers => MessageDaoManager(this);
}

class MessageDaoManager {
  final _$MessageDaoMixin _db;
  MessageDaoManager(this._db);
  $$SessionsTableTableManager get sessions =>
      $$SessionsTableTableManager(_db.attachedDatabase, _db.sessions);
  $$MessagesTableTableManager get messages =>
      $$MessagesTableTableManager(_db.attachedDatabase, _db.messages);
}
