import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../../data/database/database.dart' as db;
import '../models/llm_config.dart';

class SessionManager {
  final db.AppDatabase _db;
  final Duration idleTimeout;

  static const _uuid = Uuid();

  SessionManager(this._db, {this.idleTimeout = const Duration(minutes: 60)});

  Future<String> resolveSession({
    required String sessionKey,
    required LlmModel model,
  }) async {
    final existing = await _db.sessionDao.getSessionByKey(sessionKey);

    if (existing != null) {
      final isStale = _isSessionStale(existing.updatedAt);
      if (!isStale) {
        return existing.id;
      }
      await _db.sessionDao.archiveSession(existing.id);
      await _db.sessionDao.updateSession(
        existing.id,
        db.SessionsCompanion(
          sessionKey: Value('${existing.sessionKey}:archived:${existing.id}'),
        ),
      );
    }

    final id = _uuid.v4();
    final now = DateTime.now();
    await _db.sessionDao.upsertSession(
      db.SessionsCompanion.insert(
        id: id,
        sessionKey: sessionKey,
        model: model.id,
        provider: model.provider.name,
        createdAt: now,
        updatedAt: now,
      ),
    );
    return id;
  }

  bool _isSessionStale(DateTime updatedAt) {
    return DateTime.now().difference(updatedAt) > idleTimeout;
  }

  Future<String> createSession({
    required LlmModel model,
    String? title,
  }) async {
    final id = _uuid.v4();
    final now = DateTime.now();
    final sessionKey = 'chat:$id';
    await _db.sessionDao.upsertSession(
      db.SessionsCompanion.insert(
        id: id,
        sessionKey: sessionKey,
        title: Value(title),
        model: model.id,
        provider: model.provider.name,
        createdAt: now,
        updatedAt: now,
      ),
    );
    return id;
  }

  Future<void> autoTitle(String sessionId, String firstMessage) async {
    final session = await _db.sessionDao.getSessionById(sessionId);
    if (session != null && session.title == null) {
      var title = firstMessage.trim().replaceAll('\n', ' ');
      if (title.length > 30) {
        title = '${title.substring(0, 27)}...';
      }
      await _db.sessionDao.updateSession(
        sessionId,
        db.SessionsCompanion(title: Value(title)),
      );
    }
  }

  Future<void> updateTokens({
    required String sessionId,
    required int inputTokens,
    required int outputTokens,
  }) async {
    final session = await _db.sessionDao.getSessionById(sessionId);
    if (session == null) return;

    await _db.sessionDao.updateSession(
      sessionId,
      db.SessionsCompanion(
        inputTokens: Value(session.inputTokens + inputTokens),
        outputTokens: Value(session.outputTokens + outputTokens),
        totalTokens: Value(
          session.inputTokens + inputTokens + session.outputTokens + outputTokens,
        ),
        updatedAt: Value(DateTime.now()),
        lastMessageAt: Value(DateTime.now()),
      ),
    );
  }
}
