import '../models/llm_config.dart';
import '../models/message.dart';
import '../models/usage.dart';

sealed class LlmEvent {}

class LlmTextDelta extends LlmEvent {
  final String text;
  LlmTextDelta(this.text);
}

class LlmThinkingDelta extends LlmEvent {
  final String thinking;
  LlmThinkingDelta(this.thinking);
}

class LlmMessageStart extends LlmEvent {
  final TokenUsage usage;
  LlmMessageStart(this.usage);
}

class LlmMessageComplete extends LlmEvent {
  final String? stopReason;
  final TokenUsage usage;
  LlmMessageComplete({this.stopReason, required this.usage});
}

class LlmError extends LlmEvent {
  final String message;
  LlmError(this.message);
}

abstract class LlmClient {
  Stream<LlmEvent> stream({
    required LlmConfig config,
    required List<Message> messages,
    required String? systemPrompt,
    int? maxTokens,
  });

  Future<void> testConnection(LlmConfig config);

  void dispose();
}
