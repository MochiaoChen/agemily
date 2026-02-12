import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/services/agent_runner.dart';
import '../core/services/context_manager.dart';
import '../core/services/llm_anthropic.dart';
import '../core/services/llm_client.dart';
import '../core/services/memory_manager.dart';
import 'database_provider.dart';
import 'session_providers.dart';

final llmClientProvider = Provider<LlmClient>((ref) {
  final client = AnthropicClient();
  ref.onDispose(() => client.dispose());
  return client;
});

final contextManagerProvider = Provider<ContextManager>((ref) {
  return ContextManager();
});

final memoryManagerProvider = Provider<MemoryManager>((ref) {
  final db = ref.watch(databaseProvider);
  final llmClient = ref.watch(llmClientProvider);
  return MemoryManager(db, llmClient);
});

final agentRunnerProvider = Provider<AgentRunner>((ref) {
  return AgentRunner(
    database: ref.watch(databaseProvider),
    llmClient: ref.watch(llmClientProvider),
    sessionManager: ref.watch(sessionManagerProvider),
    contextManager: ref.watch(contextManagerProvider),
    memoryManager: ref.watch(memoryManagerProvider),
  );
});
