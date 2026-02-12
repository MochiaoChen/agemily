// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Agemily';

  @override
  String get chat => 'Chat';

  @override
  String get sessions => 'Sessions';

  @override
  String get settings => 'Settings';

  @override
  String get newChat => 'New Chat';

  @override
  String get send => 'Send';

  @override
  String get typeMessage => 'Type a message...';

  @override
  String get apiKey => 'API Key';

  @override
  String get apiKeyHint => 'Enter your Anthropic API key';

  @override
  String get baseUrl => 'API Base URL';

  @override
  String get model => 'Model';

  @override
  String get systemPrompt => 'System Prompt';

  @override
  String get systemPromptHint => 'Set AI behavior instructions...';

  @override
  String get save => 'Save';

  @override
  String get cancel => 'Cancel';

  @override
  String get delete => 'Delete';

  @override
  String get archive => 'Archive';

  @override
  String get memory => 'Memory';

  @override
  String get memoryNotes => 'Memory Notes';

  @override
  String get addNote => 'Add Note';

  @override
  String get noMessages => 'Start a conversation';

  @override
  String get noSessions => 'No sessions yet';

  @override
  String get onboardingWelcome => 'Welcome to Agemily';

  @override
  String get onboardingDesc =>
      'Your private AI assistant, all data stored locally';

  @override
  String get onboardingApiKey => 'Set up API Key';

  @override
  String get onboardingApiKeyDesc =>
      'Enter your Anthropic API key to get started';

  @override
  String get onboardingDone => 'Get Started';

  @override
  String get testConnection => 'Test Connection';

  @override
  String get connectionSuccess => 'Connection successful!';

  @override
  String get connectionFailed => 'Connection failed';

  @override
  String get thinking => 'Thinking...';

  @override
  String get contextUsage => 'Context Usage';

  @override
  String get tokens => 'tokens';

  @override
  String get compactions => 'compactions';
}
