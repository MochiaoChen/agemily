import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/models/llm_config.dart';
import '../core/models/message.dart';
import '../core/services/agent_runner.dart';
import '../data/database/database.dart' as db;
import 'agent_providers.dart';
import 'database_provider.dart';
import 'session_providers.dart';
import 'settings_providers.dart';

final messagesProvider = StreamProvider.family<List<db.Message>, String>(
  (ref, sessionId) {
    final database = ref.watch(databaseProvider);
    return database.messageDao.watchMessagesForSession(sessionId);
  },
);

final isStreamingProvider = StateProvider<bool>((ref) => false);

final streamingTextProvider = StateProvider<String>((ref) => '');

final streamingThinkingProvider = StateProvider<String>((ref) => '');

/// Whether the LLM is currently executing a web search.
final isSearchingProvider = StateProvider<bool>((ref) => false);

/// The search query the LLM decided to use (empty until known).
final searchQueryProvider = StateProvider<String>((ref) => '');

final chatErrorProvider = StateProvider<String?>((ref) => null);

final sendMessageProvider = Provider((ref) {
  return SendMessageAction(ref);
});

class SendMessageAction {
  final Ref _ref;

  SendMessageAction(this._ref);

  Future<void> call(String text, {List<ImageBlock>? images}) async {
    final sessionId = _ref.read(currentSessionIdProvider);
    final config = _ref.read(llmConfigProvider);
    if (sessionId == null || config == null) return;

    // Auto-detect difficulty → switch to Opus if needed
    final useModel = isDifficultQuery(text) ? kOpusModel : config.model;
    final effectiveConfig = config.copyWith(model: useModel);
    _ref.read(activeModelProvider.notifier).state = useModel;

    _ref.read(isStreamingProvider.notifier).state = true;
    _ref.read(streamingTextProvider.notifier).state = '';
    _ref.read(streamingThinkingProvider.notifier).state = '';
    _ref.read(isSearchingProvider.notifier).state = false;
    _ref.read(searchQueryProvider.notifier).state = '';
    _ref.read(chatErrorProvider.notifier).state = null;

    final runner = _ref.read(agentRunnerProvider);

    // Build content blocks
    final contentBlocks = <ContentBlock>[];
    if (images != null) {
      contentBlocks.addAll(images);
    }
    contentBlocks.add(TextBlock(text: text));

    try {
      await for (final event in runner.runTurn(
        sessionId: sessionId,
        userContent: contentBlocks,
        config: effectiveConfig,
      )) {
        switch (event) {
          case AgentTextDelta(:final text):
            _ref.read(streamingTextProvider.notifier).state += text;

          case AgentThinkingDelta(:final thinking):
            _ref.read(streamingThinkingProvider.notifier).state += thinking;

          case AgentSearching(:final query):
            _ref.read(isSearchingProvider.notifier).state = true;
            if (query.isNotEmpty) {
              _ref.read(searchQueryProvider.notifier).state = query;
            }

          case AgentSearchComplete():
            _ref.read(isSearchingProvider.notifier).state = false;

          case AgentComplete():
            break;

          case AgentError(:final message):
            _ref.read(chatErrorProvider.notifier).state = message;
        }
      }
    } catch (_) {
      _ref.read(chatErrorProvider.notifier).state = '发送失败，请重试';
    } finally {
      _ref.read(isStreamingProvider.notifier).state = false;
      _ref.read(isSearchingProvider.notifier).state = false;
    }
  }
}
