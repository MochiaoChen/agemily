import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../core/models/llm_config.dart';
import 'database_provider.dart';

final secureStorageProvider = Provider<FlutterSecureStorage>((ref) {
  return const FlutterSecureStorage();
});

final apiKeyProvider =
    StateNotifierProvider<ApiKeyNotifier, String?>((ref) {
  return ApiKeyNotifier(ref.watch(secureStorageProvider));
});

class ApiKeyNotifier extends StateNotifier<String?> {
  final FlutterSecureStorage _storage;
  static const _key = 'anthropic_api_key';
  bool _initialized = false;

  ApiKeyNotifier(this._storage) : super(null) {
    if (!_initialized) _load();
  }

  void initWith(String? value) {
    _initialized = true;
    state = value;
  }

  Future<void> _load() async {
    state = await _storage.read(key: _key);
  }

  Future<void> setApiKey(String key) async {
    await _storage.write(key: _key, value: key);
    state = key;
  }

  Future<void> clearApiKey() async {
    await _storage.delete(key: _key);
    state = null;
  }
}

final baseUrlProvider =
    StateNotifierProvider<BaseUrlNotifier, String>((ref) {
  return BaseUrlNotifier(ref.watch(databaseProvider));
});

class BaseUrlNotifier extends StateNotifier<String> {
  final dynamic _db;
  static const _prefKey = 'api_base_url';
  static const _defaultUrl = 'https://api.anthropic.com';
  bool _initialized = false;

  BaseUrlNotifier(this._db) : super(_defaultUrl) {
    if (!_initialized) _load();
  }

  void initWith(String value) {
    _initialized = true;
    state = value;
  }

  Future<void> _load() async {
    final value = await _db.preferencesDao.getValue(_prefKey);
    if (value != null && value.isNotEmpty) {
      state = value;
    }
  }

  /// Validates and sets the API base URL. Requires HTTPS.
  /// Returns an error message if invalid, or null on success.
  Future<String?> setUrl(String url) async {
    final error = validateBaseUrl(url);
    if (error != null) return error;
    await _db.preferencesDao.setValue(_prefKey, url);
    state = url;
    return null;
  }

  /// Returns an error string if [url] is not a valid HTTPS URL, null if OK.
  static String? validateBaseUrl(String url) {
    final uri = Uri.tryParse(url);
    if (uri == null || !uri.hasScheme || !uri.hasAuthority) {
      return '请输入有效的 URL';
    }
    if (uri.scheme != 'https') {
      return '仅支持 HTTPS 地址';
    }
    return null;
  }
}

final selectedModelProvider = StateProvider<LlmModel>((ref) {
  return kDefaultModel;
});

/// Tracks which model was actually used for the current/last turn
/// (may differ from selected when auto-detection switches to Opus).
final activeModelProvider = StateProvider<LlmModel>((ref) {
  return ref.watch(selectedModelProvider);
});

final systemPromptProvider =
    StateNotifierProvider<SystemPromptNotifier, String>((ref) {
  return SystemPromptNotifier(ref.watch(databaseProvider));
});

class SystemPromptNotifier extends StateNotifier<String> {
  final dynamic _db;
  static const _prefKey = 'system_prompt';
  static const defaultPrompt = '''你是家庭助手，服务对象是家里的老人和小孩。

# 说话方式
- 像家人聊天一样，简单直白，不用术语、英文、格式符号
- 遇到专业词汇用大白话解释
- 简单问题简短回答；需要步骤或解读的问题（如体检报告、维修指导），可以详细说明，但每一步都要说得清楚易懂
- 用户没有说过自己的名字或身份之前，不要用"爷爷""奶奶""小朋友"等称呼，直接用"你"就好

# 核心原则
- 问题不清楚时，先确认再答，不要猜
- 涉及转账、验证码、中奖等话题，主动提醒可能是诈骗
- 对方重复问，耐心再答一遍

# 用药与健康
- 用户提到任何药品名称时，仔细核实药品信息，结合上下文（如用户的年龄、已知病史、正在服用的其他药物）给出谨慎的说明
- 说明药品的常见用途、常见副作用和注意事项，用大白话解释
- 特别注意药物之间的相互作用风险，如果用户提到多种药物，主动提醒可能的冲突
- 始终建议遵医嘱用药，不要自行调整剂量或停药，有疑问及时咨询医生或药师
- 不给具体的用药方案（如"每天吃几片"），只提供常识性参考''';

  SystemPromptNotifier(this._db) : super(defaultPrompt) {
    _load();
  }

  Future<void> _load() async {
    final value = await _db.preferencesDao.getValue(_prefKey);
    if (value != null) {
      state = value;
    }
  }

  Future<void> setPrompt(String prompt) async {
    await _db.preferencesDao.setValue(_prefKey, prompt);
    state = prompt;
  }
}

final llmConfigProvider = Provider<LlmConfig?>((ref) {
  final apiKey = ref.watch(apiKeyProvider);
  if (apiKey == null || apiKey.isEmpty) return null;

  final baseUrl = ref.watch(baseUrlProvider);
  final model = ref.watch(selectedModelProvider);
  final systemPrompt = ref.watch(systemPromptProvider);

  return LlmConfig(
    baseUrl: baseUrl,
    apiKey: apiKey,
    model: model,
    systemPrompt: systemPrompt,
  );
});

final hasApiKeyProvider = Provider<bool>((ref) {
  final key = ref.watch(apiKeyProvider);
  return key != null && key.isNotEmpty;
});
