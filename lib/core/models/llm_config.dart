enum LlmProvider { anthropic }

class LlmModel {
  final String id;
  final String name;
  final String description;
  final LlmProvider provider;
  final int contextWindow;
  final int maxTokens;
  final bool reasoning;

  const LlmModel({
    required this.id,
    required this.name,
    this.description = '',
    required this.provider,
    required this.contextWindow,
    required this.maxTokens,
    this.reasoning = false,
  });
}

const kAnthropicModels = [
  LlmModel(
    id: 'claude-sonnet-4-5-20250929',
    name: 'Sonnet 4.5',
    description: '日常问答',
    provider: LlmProvider.anthropic,
    contextWindow: 200000,
    maxTokens: 16384,
    reasoning: true,
  ),
  LlmModel(
    id: 'gemini-3-pro-high',
    name: 'Gemini 3 Pro',
    description: '复杂问题',
    provider: LlmProvider.anthropic,
    contextWindow: 200000,
    maxTokens: 32000,
    reasoning: true,
  ),
];

LlmModel get kDefaultModel => kAnthropicModels.first; // Sonnet 4.5
LlmModel get kOpusModel => kAnthropicModels.last;     // Gemini 3 Pro (complex)

/// Detect if user query is complex enough to use Opus.
bool isDifficultQuery(String text) {
  if (text.length > 300) return true;

  const keywords = [
    '分析', '报告', '体检', '诊断', '法律', '合同', '翻译',
    '编程', '代码', '计算', '数学', '论文', '研究', '策略',
    '规划', '设计', '架构', '优化', '比较', '评估', '总结',
    '详细', '复杂', '为什么', '怎么办', '解释一下',
    '心脏', '血压', '血糖', '彩超', '化验', 'CT', 'MRI',
    '保险', '理赔', '退款', '投诉',
    // 用药与健康
    '药', '用药', '服药', '停药', '换药', '减药', '加药',
    '药片', '胶囊', '药水', '药膏', '处方',
    '副作用', '不良反应', '过敏', '禁忌',
    '头孢', '阿莫西林', '布洛芬', '阿司匹林', '降压药', '降糖药',
    '抗生素', '消炎药', '止痛药', '感冒药', '维生素',
    '剂量', '药物', '中药', '西药',
  ];
  for (final kw in keywords) {
    if (text.contains(kw)) return true;
  }

  // Multiple questions
  final qCount =
      '？'.allMatches(text).length + '?'.allMatches(text).length;
  if (qCount >= 2) return true;

  return false;
}

class LlmConfig {
  final String baseUrl;
  final String apiKey;
  final LlmModel model;
  final String? systemPrompt;
  final bool searchEnabled;

  const LlmConfig({
    this.baseUrl = 'https://api.anthropic.com',
    required this.apiKey,
    required this.model,
    this.systemPrompt,
    this.searchEnabled = true,
  });

  LlmConfig copyWith({
    String? baseUrl,
    String? apiKey,
    LlmModel? model,
    String? systemPrompt,
    bool? searchEnabled,
  }) {
    return LlmConfig(
      baseUrl: baseUrl ?? this.baseUrl,
      apiKey: apiKey ?? this.apiKey,
      model: model ?? this.model,
      systemPrompt: systemPrompt ?? this.systemPrompt,
      searchEnabled: searchEnabled ?? this.searchEnabled,
    );
  }
}
