import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../providers/database_provider.dart';
import '../../../providers/session_providers.dart';

String _relativeTime(DateTime dt) {
  final now = DateTime.now();
  final diff = now.difference(dt);
  if (diff.inMinutes < 1) return '刚刚';
  if (diff.inMinutes < 60) return '${diff.inMinutes} 分钟前';
  if (diff.inHours < 24) return '${diff.inHours} 小时前';
  if (diff.inDays == 1) return '昨天';
  if (diff.inDays < 7) return '${diff.inDays} 天前';
  if (diff.inDays < 30) return '${diff.inDays ~/ 7} 周前';
  return '${dt.month}月${dt.day}日';
}

class ChatDrawer extends ConsumerWidget {
  final VoidCallback? onClose;
  const ChatDrawer({super.key, this.onClose});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sessions = ref.watch(sessionListProvider);
    final currentId = ref.watch(currentSessionIdProvider);
    final colorScheme = Theme.of(context).colorScheme;
    final bg = Theme.of(context).scaffoldBackgroundColor;

    return Container(
      color: bg,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 16, 8),
              child: Text(
                '家庭小助手',
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
            // Navigation items
            _NavItem(
              icon: Icons.chat_bubble_outline,
              label: '对话',
              onTap: () {},
            ),
            const Divider(indent: 24, endIndent: 24, height: 16),
            // Recents label
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 4, 16, 8),
              child: Text(
                '最近',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
            // Session list
            Expanded(
              child: sessions.when(
                data: (list) {
                  if (list.isEmpty) {
                    return Center(
                      child: Text(
                        '暂无对话',
                        style: TextStyle(color: colorScheme.onSurfaceVariant),
                      ),
                    );
                  }
                  return ListView.builder(
                    padding: EdgeInsets.zero,
                    itemCount: list.length,
                    itemBuilder: (context, index) {
                      final session = list[index];
                      final isSelected = currentId == session.id;
                      return _SessionTile(
                        title: session.title ?? '新对话',
                        time: _relativeTime(session.lastMessageAt ?? session.updatedAt),
                        isSelected: isSelected,
                        onTap: () {
                          ref.read(currentSessionIdProvider.notifier).state =
                              session.id;
                          onClose?.call();
                        },
                        onDelete: () {
                          ref
                              .read(databaseProvider)
                              .sessionDao
                              .archiveSession(session.id);
                          if (isSelected) {
                            ref.read(currentSessionIdProvider.notifier).state =
                                null;
                          }
                        },
                      );
                    },
                  );
                },
                loading: () =>
                    const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(child: Text('Error: $e')),
              ),
            ),
            // Bottom section
            const Divider(indent: 24, endIndent: 24, height: 1),
            _NavItem(
              icon: Icons.settings_outlined,
              label: '设置',
              onTap: () {
                onClose?.call();
                context.push('/settings');
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      dense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 24),
      leading: Icon(icon, size: 20),
      title: Text(label, style: const TextStyle(fontSize: 15)),
      onTap: onTap,
    );
  }
}

class _SessionTile extends StatelessWidget {
  final String title;
  final String time;
  final bool isSelected;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _SessionTile({
    required this.title,
    required this.time,
    required this.isSelected,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Dismissible(
      key: Key(title + isSelected.toString()),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 16),
        color: colorScheme.error,
        child: Icon(Icons.delete_outline, color: colorScheme.onError),
      ),
      onDismissed: (_) => onDelete(),
      child: ListTile(
        dense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 24),
        title: Text(
          title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 14,
            color: isSelected
                ? colorScheme.onSurface
                : colorScheme.onSurfaceVariant,
            fontWeight: isSelected ? FontWeight.w500 : FontWeight.normal,
          ),
        ),
        subtitle: Text(
          time,
          style: TextStyle(
            fontSize: 12,
            color: colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
          ),
        ),
        selected: isSelected,
        selectedTileColor: colorScheme.primaryContainer.withValues(alpha: 0.5),
        onTap: onTap,
      ),
    );
  }
}
