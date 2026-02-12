import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/settings_providers.dart';

class SystemPromptScreen extends ConsumerStatefulWidget {
  const SystemPromptScreen({super.key});

  @override
  ConsumerState<SystemPromptScreen> createState() =>
      _SystemPromptScreenState();
}

class _SystemPromptScreenState extends ConsumerState<SystemPromptScreen> {
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: ref.read(systemPromptProvider));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('系统提示词'),
        actions: [
          TextButton(
            onPressed: () {
              ref
                  .read(systemPromptProvider.notifier)
                  .setPrompt(_controller.text);
              Navigator.of(context).pop();
            },
            child: const Text('保存'),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: TextField(
          controller: _controller,
          maxLines: null,
          expands: true,
          textAlignVertical: TextAlignVertical.top,
          decoration: const InputDecoration(
            hintText: '设置 AI 的行为指令...',
            border: OutlineInputBorder(),
            alignLabelWithHint: true,
          ),
        ),
      ),
    );
  }
}
