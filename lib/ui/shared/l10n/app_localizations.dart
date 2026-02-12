import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_zh.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('zh'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In zh, this message translates to:
  /// **'Agemily'**
  String get appTitle;

  /// No description provided for @chat.
  ///
  /// In zh, this message translates to:
  /// **'对话'**
  String get chat;

  /// No description provided for @sessions.
  ///
  /// In zh, this message translates to:
  /// **'会话列表'**
  String get sessions;

  /// No description provided for @settings.
  ///
  /// In zh, this message translates to:
  /// **'设置'**
  String get settings;

  /// No description provided for @newChat.
  ///
  /// In zh, this message translates to:
  /// **'新建对话'**
  String get newChat;

  /// No description provided for @send.
  ///
  /// In zh, this message translates to:
  /// **'发送'**
  String get send;

  /// No description provided for @typeMessage.
  ///
  /// In zh, this message translates to:
  /// **'输入消息...'**
  String get typeMessage;

  /// No description provided for @apiKey.
  ///
  /// In zh, this message translates to:
  /// **'API 密钥'**
  String get apiKey;

  /// No description provided for @apiKeyHint.
  ///
  /// In zh, this message translates to:
  /// **'输入你的 Anthropic API 密钥'**
  String get apiKeyHint;

  /// No description provided for @baseUrl.
  ///
  /// In zh, this message translates to:
  /// **'API 地址'**
  String get baseUrl;

  /// No description provided for @model.
  ///
  /// In zh, this message translates to:
  /// **'模型'**
  String get model;

  /// No description provided for @systemPrompt.
  ///
  /// In zh, this message translates to:
  /// **'系统提示词'**
  String get systemPrompt;

  /// No description provided for @systemPromptHint.
  ///
  /// In zh, this message translates to:
  /// **'设置 AI 的行为指令...'**
  String get systemPromptHint;

  /// No description provided for @save.
  ///
  /// In zh, this message translates to:
  /// **'保存'**
  String get save;

  /// No description provided for @cancel.
  ///
  /// In zh, this message translates to:
  /// **'取消'**
  String get cancel;

  /// No description provided for @delete.
  ///
  /// In zh, this message translates to:
  /// **'删除'**
  String get delete;

  /// No description provided for @archive.
  ///
  /// In zh, this message translates to:
  /// **'归档'**
  String get archive;

  /// No description provided for @memory.
  ///
  /// In zh, this message translates to:
  /// **'记忆'**
  String get memory;

  /// No description provided for @memoryNotes.
  ///
  /// In zh, this message translates to:
  /// **'记忆笔记'**
  String get memoryNotes;

  /// No description provided for @addNote.
  ///
  /// In zh, this message translates to:
  /// **'添加笔记'**
  String get addNote;

  /// No description provided for @noMessages.
  ///
  /// In zh, this message translates to:
  /// **'开始对话吧'**
  String get noMessages;

  /// No description provided for @noSessions.
  ///
  /// In zh, this message translates to:
  /// **'暂无会话'**
  String get noSessions;

  /// No description provided for @onboardingWelcome.
  ///
  /// In zh, this message translates to:
  /// **'欢迎使用 Agemily'**
  String get onboardingWelcome;

  /// No description provided for @onboardingDesc.
  ///
  /// In zh, this message translates to:
  /// **'你的私人 AI 助手，数据完全本地存储'**
  String get onboardingDesc;

  /// No description provided for @onboardingApiKey.
  ///
  /// In zh, this message translates to:
  /// **'设置 API 密钥'**
  String get onboardingApiKey;

  /// No description provided for @onboardingApiKeyDesc.
  ///
  /// In zh, this message translates to:
  /// **'输入你的 Anthropic API 密钥以开始使用'**
  String get onboardingApiKeyDesc;

  /// No description provided for @onboardingDone.
  ///
  /// In zh, this message translates to:
  /// **'开始使用'**
  String get onboardingDone;

  /// No description provided for @testConnection.
  ///
  /// In zh, this message translates to:
  /// **'测试连接'**
  String get testConnection;

  /// No description provided for @connectionSuccess.
  ///
  /// In zh, this message translates to:
  /// **'连接成功！'**
  String get connectionSuccess;

  /// No description provided for @connectionFailed.
  ///
  /// In zh, this message translates to:
  /// **'连接失败'**
  String get connectionFailed;

  /// No description provided for @thinking.
  ///
  /// In zh, this message translates to:
  /// **'思考中...'**
  String get thinking;

  /// No description provided for @contextUsage.
  ///
  /// In zh, this message translates to:
  /// **'上下文使用'**
  String get contextUsage;

  /// No description provided for @tokens.
  ///
  /// In zh, this message translates to:
  /// **'tokens'**
  String get tokens;

  /// No description provided for @compactions.
  ///
  /// In zh, this message translates to:
  /// **'压缩次数'**
  String get compactions;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'zh'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'zh':
      return AppLocalizationsZh();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
