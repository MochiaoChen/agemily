import 'dart:async';

import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../../data/database/database.dart' as db;
import '../models/llm_config.dart';
import '../models/message.dart';
import '../models/usage.dart';
import 'context_manager.dart';
import 'llm_client.dart';
import 'memory_manager.dart';
import 'session_manager.dart';
import 'token_counter.dart';

sealed class AgentEvent {}

class AgentTextDelta extends AgentEvent {
  final String text;
  AgentTextDelta(this.text);
}

class AgentThinkingDelta extends AgentEvent {
  final String thinking;
  AgentThinkingDelta(this.thinking);
}

class AgentComplete extends AgentEvent {
  final Message message;
  AgentComplete(this.message);
}

class AgentError extends AgentEvent {
  final String message;
  AgentError(this.message);
}

class AgentRunner {
  final db.AppDatabase _db;
  final LlmClient _llmClient;
  final SessionManager _sessionManager;
  final ContextManager _contextManager;
  final MemoryManager _memoryManager;

  static const _uuid = Uuid();

  AgentRunner({
    required db.AppDatabase database,
    required LlmClient llmClient,
    required SessionManager sessionManager,
    required ContextManager contextManager,
    required MemoryManager memoryManager,
  })  : _db = database,
        _llmClient = llmClient,
        _sessionManager = sessionManager,
        _contextManager = contextManager,
        _memoryManager = memoryManager;

  Stream<AgentEvent> runTurn({
    required String sessionId,
    required List<ContentBlock> userContent,
    required LlmConfig config,
  }) async* {
    // 1. Load message history from DB
    final dbMessages = await _db.messageDao.getMessagesForSession(sessionId);
    final history = dbMessages
        .map((row) => Message(
              id: row.id,
              sessionId: row.sessionId,
              parentId: row.parentId,
              role: MessageRole.values.firstWhere(
                (r) => r.name == row.role,
                orElse: () => MessageRole.user,
              ),
              content: ContentBlock.listFromJson(row.content),
              model: row.model,
              inputTokens: row.inputTokens,
              outputTokens: row.outputTokens,
              stopReason: row.stopReason,
              isCompactionSummary: row.isCompactionSummary,
              createdAt: row.createdAt,
              sortOrder: row.sortOrder,
            ))
        .toList();

    // 2. Build user message and persist to DB
    final userMsgId = _uuid.v4();
    final nextOrder = await _db.messageDao.getNextSortOrder(sessionId);
    final userMessage = Message(
      id: userMsgId,
      sessionId: sessionId,
      role: MessageRole.user,
      content: userContent,
      createdAt: DateTime.now(),
      sortOrder: nextOrder,
    );

    await _db.messageDao.insertMessage(
      db.MessagesCompanion.insert(
        id: userMsgId,
        sessionId: sessionId,
        role: 'user',
        content: ContentBlock.listToJson(userMessage.content),
        createdAt: DateTime.now(),
        sortOrder: nextOrder,
      ),
    );

    // Flag for auto-title after first LLM reply
    final needsAutoTitle = history.isEmpty && userMessage.textContent.isNotEmpty;

    final allMessages = [...history, userMessage];

    // 3. Prepare context — truncation/compaction if needed
    final currentTokens = allMessages.fold<int>(
      0,
      (sum, msg) => sum + TokenCounter.estimate(msg.textContent),
    );

    final prepared = _contextManager.prepareContext(
      messages: allMessages,
      currentTokenCount: currentTokens,
    );

    // Update compaction count if compaction happened
    if (prepared.compacted) {
      final session = await _db.sessionDao.getSessionById(sessionId);
      if (session != null) {
        await _db.sessionDao.updateSession(
          sessionId,
          db.SessionsCompanion(
            compactionCount: Value(session.compactionCount + 1),
          ),
        );
      }
    }

    // 4. Build system prompt with memory
    final memoryContext = await _memoryManager.buildMemoryContext();
    final fullSystemPrompt = (config.systemPrompt ?? '') + memoryContext;

    // 5. Stream LLM response
    final textBuffer = StringBuffer();
    final thinkingBuffer = StringBuffer();
    String? stopReason;
    var usage = const TokenUsage();

    await for (final event in _llmClient.stream(
      config: config,
      messages: prepared.messages,
      systemPrompt: fullSystemPrompt.isEmpty ? null : fullSystemPrompt,
    )) {
      switch (event) {
        case LlmTextDelta(:final text):
          textBuffer.write(text);
          yield AgentTextDelta(text);

        case LlmThinkingDelta(:final thinking):
          thinkingBuffer.write(thinking);
          yield AgentThinkingDelta(thinking);

        case LlmMessageStart():
          break;

        case LlmMessageComplete():
          stopReason = event.stopReason;
          usage = event.usage;

        case LlmError(:final message):
          yield AgentError(message);
          return;
      }
    }

    // 6. Persist assistant message to DB
    final assistantMsgId = _uuid.v4();
    final assistantOrder = nextOrder + 1;
    final contentBlocks = <ContentBlock>[];

    if (thinkingBuffer.isNotEmpty) {
      contentBlocks.add(ThinkingBlock(thinking: thinkingBuffer.toString()));
    }
    if (textBuffer.isNotEmpty) {
      contentBlocks.add(TextBlock(text: textBuffer.toString()));
    }
    if (contentBlocks.isEmpty) {
      contentBlocks.add(TextBlock(text: ''));
    }

    await _db.messageDao.insertMessage(
      db.MessagesCompanion.insert(
        id: assistantMsgId,
        sessionId: sessionId,
        role: 'assistant',
        content: ContentBlock.listToJson(contentBlocks),
        model: Value(config.model.id),
        inputTokens: Value(usage.inputTokens),
        outputTokens: Value(usage.outputTokens),
        stopReason: Value(stopReason),
        createdAt: DateTime.now(),
        sortOrder: assistantOrder,
      ),
    );

    // Update session token counts
    await _sessionManager.updateTokens(
      sessionId: sessionId,
      inputTokens: usage.inputTokens,
      outputTokens: usage.outputTokens,
    );

    final assistantMessage = Message(
      id: assistantMsgId,
      sessionId: sessionId,
      role: MessageRole.assistant,
      content: contentBlocks,
      model: config.model.id,
      inputTokens: usage.inputTokens,
      outputTokens: usage.outputTokens,
      stopReason: stopReason,
      createdAt: DateTime.now(),
      sortOrder: assistantOrder,
    );

    yield AgentComplete(assistantMessage);

    // Auto-generate title from first reply using LLM
    if (needsAutoTitle && textBuffer.isNotEmpty) {
      _generateTitle(
        sessionId: sessionId,
        userText: userMessage.textContent,
        assistantText: textBuffer.toString(),
        config: config,
      );
    }

    // Fire-and-forget: extract memories after each turn
    _memoryManager.extractMemories(sessionId, config);
  }

  /// Fire-and-forget: ask LLM to generate a short session title.
  void _generateTitle({
    required String sessionId,
    required String userText,
    required String assistantText,
    required LlmConfig config,
  }) async {
    try {
      // Use a short snippet to save tokens
      final userSnippet = userText.length > 200
          ? userText.substring(0, 200)
          : userText;
      final assistantSnippet = assistantText.length > 300
          ? assistantText.substring(0, 300)
          : assistantText;

      final titlePrompt = Message(
        id: 'title-prompt',
        sessionId: sessionId,
        role: MessageRole.user,
        content: [
          TextBlock(
            text: '根据以下对话生成一个简短的标题（不超过15个字，不要引号）：\n\n'
                '用户：$userSnippet\n\n'
                '助手：$assistantSnippet',
          ),
        ],
        createdAt: DateTime.now(),
        sortOrder: 0,
      );

      final titleBuffer = StringBuffer();
      await for (final event in _llmClient.stream(
        config: config,
        messages: [titlePrompt],
        systemPrompt: '你是标题生成器。只输出标题本身，不要任何其他内容。',
        maxTokens: 30,
      )) {
        if (event is LlmTextDelta) {
          titleBuffer.write(event.text);
        }
      }

      var title = titleBuffer.toString().trim();
      // Clean up: remove quotes, limit length
      title = title.replaceAll(RegExp(r'^["""「」『』]+|["""「」『』]+$'), '');
      if (title.length > 30) {
        title = '${title.substring(0, 27)}...';
      }
      if (title.isNotEmpty) {
        await _sessionManager.autoTitle(sessionId, title);
      }
    } catch (_) {
      // Fallback: use user's first message as title
      var fallback = userText.trim().replaceAll('\n', ' ');
      if (fallback.length > 30) {
        fallback = '${fallback.substring(0, 27)}...';
      }
      await _sessionManager.autoTitle(sessionId, fallback);
    }
  }
}
