import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/services/session_manager.dart';
import 'database_provider.dart';

final sessionManagerProvider = Provider<SessionManager>((ref) {
  final db = ref.watch(databaseProvider);
  return SessionManager(db);
});

final sessionListProvider = StreamProvider((ref) {
  final db = ref.watch(databaseProvider);
  return db.sessionDao.watchAllSessions();
});

final currentSessionIdProvider = StateProvider<String?>((ref) => null);

final currentSessionProvider = FutureProvider((ref) async {
  final sessionId = ref.watch(currentSessionIdProvider);
  if (sessionId == null) return null;
  final db = ref.watch(databaseProvider);
  return db.sessionDao.getSessionById(sessionId);
});
