import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:sqlite3_flutter_libs/sqlite3_flutter_libs.dart';
import 'package:sqlite3/sqlite3.dart';

import 'tables.dart';
import 'daos/session_dao.dart';
import 'daos/message_dao.dart';
import 'daos/memory_dao.dart';
import 'daos/preferences_dao.dart';

part 'database.g.dart';

@DriftDatabase(
  tables: [Sessions, Messages, MemoryNotes, Preferences],
  daos: [SessionDao, MessageDao, MemoryDao, PreferencesDao],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase._internal(super.e);

  static AppDatabase? _instance;

  static Future<AppDatabase> getInstance() async {
    if (_instance != null) return _instance!;
    final executor = await _openConnection();
    _instance = AppDatabase._internal(executor);
    return _instance!;
  }

  @override
  int get schemaVersion => 1;

  static Future<LazyDatabase> _openConnection() async {
    return LazyDatabase(() async {
      final dbFolder = await getApplicationDocumentsDirectory();
      final file = File(p.join(dbFolder.path, 'agemily.db'));

      if (Platform.isAndroid) {
        await applyWorkaroundToOpenSqlite3OnOldAndroidVersions();
      }
      final cacheBase = (await getTemporaryDirectory()).path;
      sqlite3.tempDirectory = cacheBase;

      return NativeDatabase.createInBackground(file);
    });
  }
}
