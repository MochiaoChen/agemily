import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../providers/settings_providers.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hasKey = ref.watch(hasApiKeyProvider);
    final model = ref.watch(selectedModelProvider);
    final searchEnabled = ref.watch(searchEnabledProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('设置')),
      body: ListView(
        children: [
          _SectionHeader(title: 'API 配置'),
          ListTile(
            leading: const Icon(Icons.key),
            title: const Text('API 密钥'),
            subtitle: Text(hasKey ? '已配置' : '未配置'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push('/settings/api'),
          ),
          ListTile(
            leading: const Icon(Icons.smart_toy),
            title: const Text('模型'),
            subtitle: Text(model.name),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push('/settings/api'),
          ),
          _SectionHeader(title: '对话'),
          SwitchListTile(
            secondary: const Icon(Icons.travel_explore),
            title: const Text('联网搜索'),
            subtitle: const Text('允许助手搜索网络获取最新信息'),
            value: searchEnabled,
            onChanged: (_) =>
                ref.read(searchEnabledProvider.notifier).toggle(),
          ),
          ListTile(
            leading: const Icon(Icons.edit_note),
            title: const Text('系统提示词'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push('/settings/prompt'),
          ),
          ListTile(
            leading: const Icon(Icons.psychology),
            title: const Text('记忆笔记'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push('/settings/memory'),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }
}
