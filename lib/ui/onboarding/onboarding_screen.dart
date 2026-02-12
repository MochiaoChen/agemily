import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/models/llm_config.dart';
import '../../core/services/llm_anthropic.dart';
import '../../providers/settings_providers.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _pageController = PageController();
  final _apiKeyController = TextEditingController();
  int _currentPage = 0;
  bool _testing = false;
  String? _testError;

  @override
  void dispose() {
    _pageController.dispose();
    _apiKeyController.dispose();
    super.dispose();
  }

  void _nextPage() {
    if (_currentPage < 2) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  Future<void> _testAndSave() async {
    final key = _apiKeyController.text.trim();
    if (key.isEmpty) return;

    setState(() {
      _testing = true;
      _testError = null;
    });

    try {
      final client = AnthropicClient();
      await client.testConnection(LlmConfig(
        baseUrl: ref.read(baseUrlProvider),
        apiKey: key,
        model: kAnthropicModels.first,
      ));
      client.dispose();

      await ref.read(apiKeyProvider.notifier).setApiKey(key);
      setState(() {
        _testing = false;
      });
      _nextPage();
    } catch (_) {
      setState(() {
        _testError = '连接失败，请检查密钥是否正确';
        _testing = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                onPageChanged: (i) => setState(() => _currentPage = i),
                children: [
                  // Page 1: Welcome
                  _buildWelcomePage(colorScheme),
                  // Page 2: API Key
                  _buildApiKeyPage(colorScheme),
                  // Page 3: Done
                  _buildDonePage(colorScheme),
                ],
              ),
            ),
            // Page indicator
            Padding(
              padding: const EdgeInsets.all(24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(3, (i) {
                  return Container(
                    width: i == _currentPage ? 24 : 8,
                    height: 8,
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    decoration: BoxDecoration(
                      color: i == _currentPage
                          ? colorScheme.primary
                          : colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  );
                }),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWelcomePage(ColorScheme colorScheme) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.smart_toy, size: 80, color: colorScheme.primary),
          const SizedBox(height: 24),
          Text(
            '欢迎使用 Agemily',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            '你的私人 AI 助手\n数据完全本地存储，安全可靠',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 48),
          FilledButton(
            onPressed: _nextPage,
            child: const Padding(
              padding: EdgeInsets.symmetric(horizontal: 24, vertical: 4),
              child: Text('开始设置'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildApiKeyPage(ColorScheme colorScheme) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.key, size: 48, color: colorScheme.primary),
          const SizedBox(height: 24),
          Text(
            '设置 API 密钥',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '输入你的 Anthropic API 密钥以开始使用',
            textAlign: TextAlign.center,
            style: TextStyle(color: colorScheme.onSurfaceVariant),
          ),
          const SizedBox(height: 32),
          TextField(
            controller: _apiKeyController,
            obscureText: true,
            decoration: const InputDecoration(
              labelText: 'API 密钥',
              hintText: 'sk-ant-...',
              prefixIcon: Icon(Icons.vpn_key),
            ),
          ),
          const SizedBox(height: 16),
          if (_testError != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Text(
                _testError!,
                style: TextStyle(color: colorScheme.error, fontSize: 13),
              ),
            ),
          FilledButton(
            onPressed: _testing ? null : _testAndSave,
            child: _testing
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('测试连接并继续'),
          ),
          const SizedBox(height: 12),
          TextButton(
            onPressed: () {
              // Skip without testing
              final key = _apiKeyController.text.trim();
              if (key.isNotEmpty) {
                ref.read(apiKeyProvider.notifier).setApiKey(key);
              }
              _nextPage();
            },
            child: const Text('跳过测试'),
          ),
        ],
      ),
    );
  }

  Widget _buildDonePage(ColorScheme colorScheme) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.check_circle, size: 80, color: Colors.green),
          const SizedBox(height: 24),
          Text(
            '设置完成！',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            '现在可以开始和 AI 对话了',
            style: TextStyle(
              fontSize: 16,
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 48),
          FilledButton(
            onPressed: () => context.go('/sessions'),
            child: const Padding(
              padding: EdgeInsets.symmetric(horizontal: 24, vertical: 4),
              child: Text('开始使用'),
            ),
          ),
        ],
      ),
    );
  }
}
