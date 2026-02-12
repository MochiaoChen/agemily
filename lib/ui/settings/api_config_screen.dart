import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/models/llm_config.dart';
import '../../core/services/llm_anthropic.dart';
import '../../providers/settings_providers.dart';

class ApiConfigScreen extends ConsumerStatefulWidget {
  const ApiConfigScreen({super.key});

  @override
  ConsumerState<ApiConfigScreen> createState() => _ApiConfigScreenState();
}

class _ApiConfigScreenState extends ConsumerState<ApiConfigScreen> {
  late TextEditingController _apiKeyController;
  late TextEditingController _baseUrlController;
  bool _testing = false;
  String? _testResult;

  @override
  void initState() {
    super.initState();
    _apiKeyController = TextEditingController();
    _baseUrlController = TextEditingController(
      text: ref.read(baseUrlProvider),
    );
    // Load existing key
    final currentKey = ref.read(apiKeyProvider);
    if (currentKey != null) {
      _apiKeyController.text = currentKey;
    }
  }

  @override
  void dispose() {
    _apiKeyController.dispose();
    _baseUrlController.dispose();
    super.dispose();
  }

  Future<void> _testConnection() async {
    final key = _apiKeyController.text.trim();
    if (key.isEmpty) return;

    final url = _baseUrlController.text.trim();
    if (url.isNotEmpty) {
      final urlError = BaseUrlNotifier.validateBaseUrl(url);
      if (urlError != null) {
        setState(() => _testResult = urlError);
        return;
      }
    }

    setState(() {
      _testing = true;
      _testResult = null;
    });

    try {
      final client = AnthropicClient();
      await client.testConnection(LlmConfig(
        baseUrl: url,
        apiKey: key,
        model: ref.read(selectedModelProvider),
      ));
      client.dispose();
      setState(() => _testResult = '连接成功！');
    } catch (_) {
      setState(() => _testResult = '连接失败，请检查地址和密钥');
    } finally {
      setState(() => _testing = false);
    }
  }

  void _save() {
    final key = _apiKeyController.text.trim();
    final url = _baseUrlController.text.trim();

    if (url.isNotEmpty) {
      final error = BaseUrlNotifier.validateBaseUrl(url);
      if (error != null) {
        setState(() => _testResult = error);
        return;
      }
      ref.read(baseUrlProvider.notifier).setUrl(url);
    }
    if (key.isNotEmpty) {
      ref.read(apiKeyProvider.notifier).setApiKey(key);
    }

    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final selectedModel = ref.watch(selectedModelProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('API 配置'),
        actions: [
          TextButton(onPressed: _save, child: const Text('保存')),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Base URL
          TextField(
            controller: _baseUrlController,
            decoration: const InputDecoration(
              labelText: 'API 地址',
              hintText: 'https://api.anthropic.com',
            ),
          ),
          const SizedBox(height: 16),
          // API Key
          TextField(
            controller: _apiKeyController,
            obscureText: true,
            decoration: const InputDecoration(
              labelText: 'API 密钥',
              hintText: 'sk-ant-...',
            ),
          ),
          const SizedBox(height: 16),
          // Model picker
          DropdownButtonFormField<LlmModel>(
            initialValue: selectedModel,
            decoration: const InputDecoration(labelText: '模型'),
            items: kAnthropicModels
                .map((m) => DropdownMenuItem(
                      value: m,
                      child: Text(m.name),
                    ))
                .toList(),
            onChanged: (model) {
              if (model != null) {
                ref.read(selectedModelProvider.notifier).state = model;
              }
            },
          ),
          const SizedBox(height: 24),
          // Test button
          FilledButton.tonal(
            onPressed: _testing ? null : _testConnection,
            child: _testing
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('测试连接'),
          ),
          if (_testResult != null) ...[
            const SizedBox(height: 12),
            Text(
              _testResult!,
              style: TextStyle(
                color: _testResult!.contains('成功')
                    ? Colors.green
                    : Theme.of(context).colorScheme.error,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
