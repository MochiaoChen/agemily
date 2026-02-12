import '../models/message.dart';
import 'token_counter.dart';

class ContextManager {
  final int contextWindow;
  final int reserveTokensFloor;
  final int softThreshold;

  ContextManager({
    this.contextWindow = 200000,
    this.reserveTokensFloor = 20000,
    this.softThreshold = 4000,
  });

  /// Prepare context for LLM call.
  /// Returns messages that fit within the context window.
  /// Applies truncation and compaction as needed.
  PreparedContext prepareContext({
    required List<Message> messages,
    required int currentTokenCount,
  }) {
    var processed = _truncateLargeMessages(messages);
    final needsCompaction =
        currentTokenCount >= contextWindow - reserveTokensFloor - softThreshold;

    if (needsCompaction && processed.length > 4) {
      return _compact(processed, currentTokenCount);
    }

    return PreparedContext(
      messages: processed,
      compacted: false,
      estimatedTokens: currentTokenCount,
    );
  }

  /// Layer 1: Truncate any single message > 30% of context window
  List<Message> _truncateLargeMessages(List<Message> messages) {
    final maxChars = (contextWindow * 0.3 * 4).toInt(); // ~4 chars/token
    return messages.map((msg) {
      final text = msg.textContent;
      if (text.length > maxChars) {
        final truncated = '${text.substring(0, maxChars)}\n[已截断]';
        return msg.copyWith(
          content: [TextBlock(text: truncated)],
        );
      }
      return msg;
    }).toList();
  }

  /// Layer 3: Compaction — summarize old messages, keep recent
  PreparedContext _compact(List<Message> messages, int currentTokens) {
    // Keep ~40% of messages as recent
    final keepCount = (messages.length * 0.4).ceil().clamp(2, messages.length);
    final oldMessages = messages.sublist(0, messages.length - keepCount);
    final recentMessages = messages.sublist(messages.length - keepCount);

    // Build summary of old messages
    final summaryParts = <String>[];
    for (final msg in oldMessages) {
      final text = msg.textContent;
      if (text.isEmpty) continue;
      final role = msg.role == MessageRole.user ? '用户' : '助手';
      // Keep first 200 chars of each message for summary
      final snippet = text.length > 200
          ? '${text.substring(0, 200)}...'
          : text;
      summaryParts.add('$role: $snippet');
    }

    final summaryText = '以下是之前对话的摘要：\n${summaryParts.join('\n')}';
    final summaryMessage = Message(
      id: 'compaction-summary',
      sessionId: messages.first.sessionId,
      role: MessageRole.user,
      content: [TextBlock(text: summaryText)],
      isCompactionSummary: true,
      createdAt: DateTime.now(),
      sortOrder: -1,
    );

    final compactedMessages = [summaryMessage, ...recentMessages];
    final estimatedTokens = compactedMessages.fold<int>(
      0,
      (sum, msg) => sum + TokenCounter.estimate(msg.textContent),
    );

    return PreparedContext(
      messages: compactedMessages,
      compacted: true,
      estimatedTokens: estimatedTokens,
      oldMessageIds: oldMessages.map((m) => m.id).toList(),
    );
  }

  /// Check if context is approaching limits
  bool isNearLimit(int currentTokens) {
    return currentTokens >= contextWindow - reserveTokensFloor - softThreshold;
  }

  double usageRatio(int currentTokens) {
    return currentTokens / contextWindow;
  }
}

class PreparedContext {
  final List<Message> messages;
  final bool compacted;
  final int estimatedTokens;
  final List<String>? oldMessageIds;

  PreparedContext({
    required this.messages,
    required this.compacted,
    required this.estimatedTokens,
    this.oldMessageIds,
  });
}
