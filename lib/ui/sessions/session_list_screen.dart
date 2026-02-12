import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../providers/database_provider.dart';
import '../../providers/session_providers.dart';
import '../../providers/settings_providers.dart';

class SessionListScreen extends ConsumerWidget {
  const SessionListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sessions = ref.watch(sessionListProvider);
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('会话列表'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => context.push('/settings'),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _createNewSession(context, ref),
        child: const Icon(Icons.add),
      ),
      body: sessions.when(
        data: (list) {
          if (list.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.chat_bubble_outline,
                      size: 64, color: colorScheme.onSurfaceVariant),
                  const SizedBox(height: 16),
                  Text('暂无会话',
                      style: TextStyle(color: colorScheme.onSurfaceVariant)),
                  const SizedBox(height: 24),
                  FilledButton.icon(
                    onPressed: () => _createNewSession(context, ref),
                    icon: const Icon(Icons.add),
                    label: const Text('新建对话'),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            itemCount: list.length,
            itemBuilder: (context, index) {
              final session = list[index];
              final isSelected =
                  ref.watch(currentSessionIdProvider) == session.id;

              return Dismissible(
                key: Key(session.id),
                direction: DismissDirection.endToStart,
                background: Container(
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.only(right: 20),
                  color: colorScheme.error,
                  child: Icon(Icons.archive, color: colorScheme.onError),
                ),
                onDismissed: (_) {
                  ref.read(databaseProvider).sessionDao.archiveSession(session.id);
                },
                child: ListTile(
                  selected: isSelected,
                  title: Text(
                    session.title ?? '新对话',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  subtitle: Text(
                    _formatTime(session.updatedAt),
                    style: TextStyle(
                      fontSize: 12,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  trailing: Text(
                    session.model.split('-').take(2).join('-'),
                    style: TextStyle(
                      fontSize: 11,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  onTap: () {
                    ref.read(currentSessionIdProvider.notifier).state =
                        session.id;
                    context.go('/chat');
                  },
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('加载失败: $e')),
      ),
    );
  }

  Future<void> _createNewSession(BuildContext context, WidgetRef ref) async {
    final model = ref.read(selectedModelProvider);
    final sessionId =
        await ref.read(sessionManagerProvider).createSession(model: model);
    ref.read(currentSessionIdProvider.notifier).state = sessionId;
    if (context.mounted) {
      context.go('/chat');
    }
  }

  String _formatTime(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 1) return '刚刚';
    if (diff.inHours < 1) return '${diff.inMinutes}分钟前';
    if (diff.inDays < 1) return '${diff.inHours}小时前';
    if (diff.inDays < 7) return '${diff.inDays}天前';
    return '${dt.month}/${dt.day}';
  }
}
