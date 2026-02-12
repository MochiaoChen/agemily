import 'package:drift/drift.dart';
import '../database.dart';
import '../tables.dart';

part 'preferences_dao.g.dart';

@DriftAccessor(tables: [Preferences])
class PreferencesDao extends DatabaseAccessor<AppDatabase>
    with _$PreferencesDaoMixin {
  PreferencesDao(super.db);

  Future<String?> getValue(String key) async {
    final row = await (select(preferences)
          ..where((t) => t.key.equals(key)))
        .getSingleOrNull();
    return row?.value;
  }

  Future<void> setValue(String key, String value) {
    return into(preferences).insertOnConflictUpdate(
      PreferencesCompanion(
        key: Value(key),
        value: Value(value),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  Future<void> deleteValue(String key) {
    return (delete(preferences)..where((t) => t.key.equals(key))).go();
  }

  Stream<String?> watchValue(String key) {
    return (select(preferences)..where((t) => t.key.equals(key)))
        .watchSingleOrNull()
        .map((row) => row?.value);
  }
}
