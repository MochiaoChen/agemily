// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Chinese (`zh`).
class AppLocalizationsZh extends AppLocalizations {
  AppLocalizationsZh([String locale = 'zh']) : super(locale);

  @override
  String get appTitle => 'Agemily';

  @override
  String get chat => '对话';

  @override
  String get sessions => '会话列表';

  @override
  String get settings => '设置';

  @override
  String get newChat => '新建对话';

  @override
  String get send => '发送';

  @override
  String get typeMessage => '输入消息...';

  @override
  String get apiKey => 'API 密钥';

  @override
  String get apiKeyHint => '输入你的 Anthropic API 密钥';

  @override
  String get baseUrl => 'API 地址';

  @override
  String get model => '模型';

  @override
  String get systemPrompt => '系统提示词';

  @override
  String get systemPromptHint => '设置 AI 的行为指令...';

  @override
  String get save => '保存';

  @override
  String get cancel => '取消';

  @override
  String get delete => '删除';

  @override
  String get archive => '归档';

  @override
  String get memory => '记忆';

  @override
  String get memoryNotes => '记忆笔记';

  @override
  String get addNote => '添加笔记';

  @override
  String get noMessages => '开始对话吧';

  @override
  String get noSessions => '暂无会话';

  @override
  String get onboardingWelcome => '欢迎使用 Agemily';

  @override
  String get onboardingDesc => '你的私人 AI 助手，数据完全本地存储';

  @override
  String get onboardingApiKey => '设置 API 密钥';

  @override
  String get onboardingApiKeyDesc => '输入你的 Anthropic API 密钥以开始使用';

  @override
  String get onboardingDone => '开始使用';

  @override
  String get testConnection => '测试连接';

  @override
  String get connectionSuccess => '连接成功！';

  @override
  String get connectionFailed => '连接失败';

  @override
  String get thinking => '思考中...';

  @override
  String get contextUsage => '上下文使用';

  @override
  String get tokens => 'tokens';

  @override
  String get compactions => '压缩次数';
}
