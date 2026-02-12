import 'dart:async';
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'app.dart';
import 'data/database/database.dart';
import 'providers/database_provider.dart';
import 'providers/settings_providers.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load .env only in debug mode for local development convenience.
  // In release builds, users must enter their API key via the onboarding screen.
  if (kDebugMode) {
    try {
      await dotenv.load(fileName: '.env');
    } catch (_) {
      // .env file may not exist — that's fine
    }
  }

  // Catch Flutter framework errors (widget build errors, etc.)
  FlutterError.onError = (details) {
    FlutterError.presentError(details);
  };

  // Catch async errors that escape all try-catch blocks
  PlatformDispatcher.instance.onError = (error, stack) {
    if (kDebugMode) {
      debugPrint('Unhandled error: $error');
    }
    return true; // Prevent crash
  };

  // Start the app immediately with splash, init in background
  runApp(const _BootstrapApp());
}

/// Shows splash screen while initializing DB and credentials in background.
/// Uses a single ProviderScope — no nesting.
class _BootstrapApp extends StatefulWidget {
  const _BootstrapApp();

  @override
  State<_BootstrapApp> createState() => _BootstrapAppState();
}

class _BootstrapAppState extends State<_BootstrapApp> {
  bool _ready = false;
  String? _error;
  AppDatabase? _database;
  _BootConfig? _bootConfig;

  @override
  void initState() {
    super.initState();
    _initAsync();
  }

  Future<void> _initAsync() async {
    try {
      final database = await AppDatabase.getInstance();
      final bootConfig = await _loadBootConfig(database);
      if (mounted) {
        setState(() {
          _database = database;
          _bootConfig = bootConfig;
          _ready = true;
        });
      }
    } catch (e) {
      if (mounted) {
        if (kDebugMode) {
          debugPrint('Boot error: $e');
        }
        setState(() => _error = '启动失败，请重试');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      return _ErrorBootApp(error: _error!, onRetry: () {
        setState(() => _error = null);
        _initAsync();
      });
    }

    if (!_ready) {
      return const _SplashApp();
    }

    return ProviderScope(
      overrides: [
        databaseProvider.overrideWithValue(_database!),
        apiKeyProvider.overrideWith(
          (ref) => ApiKeyNotifier(ref.watch(secureStorageProvider))
            ..initWith(_bootConfig!.apiKey),
        ),
        baseUrlProvider.overrideWith(
          (ref) => BaseUrlNotifier(ref.watch(databaseProvider))
            ..initWith(_bootConfig!.baseUrl),
        ),
      ],
      child: const AgemilApp(),
    );
  }
}

/// Minimal app shell that shows only the splash screen.
class _SplashApp extends StatelessWidget {
  const _SplashApp();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        scaffoldBackgroundColor: Colors.white,
        brightness: Brightness.light,
      ),
      darkTheme: ThemeData(
        scaffoldBackgroundColor: const Color(0xFF1A1A1A),
        brightness: Brightness.dark,
      ),
      themeMode: ThemeMode.system,
      home: const _SplashScreen(),
    );
  }
}

class _SplashScreen extends StatelessWidget {
  const _SplashScreen();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Logo
            ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: Image.asset(
                'assets/logo.png',
                width: 96,
                height: 96,
              ),
            ),
            const SizedBox(height: 24),
            // App name
            Text(
              '家庭小助手',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            // Description
            Text(
              '家人身边的 AI 助手',
              style: TextStyle(
                fontSize: 15,
                color: isDark ? Colors.white60 : Colors.black45,
              ),
            ),
            const SizedBox(height: 48),
            // Loading indicator
            SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                color: isDark ? Colors.white38 : Colors.black26,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorBootApp extends StatelessWidget {
  final String error;
  final VoidCallback onRetry;
  const _ErrorBootApp({required this.error, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      themeMode: ThemeMode.system,
      theme: ThemeData(brightness: Brightness.light),
      darkTheme: ThemeData(brightness: Brightness.dark),
      home: Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline, size: 48, color: Colors.red),
                const SizedBox(height: 16),
                const Text('启动失败', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                Text(error, textAlign: TextAlign.center, style: const TextStyle(fontSize: 14)),
                const SizedBox(height: 24),
                ElevatedButton(onPressed: onRetry, child: const Text('重试')),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _BootConfig {
  final String? apiKey;
  final String baseUrl;
  _BootConfig({this.apiKey, required this.baseUrl});
}

Future<_BootConfig> _loadBootConfig(AppDatabase db) async {
  const storage = FlutterSecureStorage();

  var apiKey = await storage.read(key: 'anthropic_api_key');
  var baseUrl = await db.preferencesDao.getValue('api_base_url');

  // In debug mode, seed from .env if no key/URL is configured yet.
  if (kDebugMode) {
    final defaultApiKey = dotenv.env['LLM_API_KEY'] ?? '';
    final defaultBaseUrl = dotenv.env['LLM_API_BASE'] ?? '';

    if ((apiKey == null || apiKey.isEmpty) && defaultApiKey.isNotEmpty) {
      await storage.write(key: 'anthropic_api_key', value: defaultApiKey);
      apiKey = defaultApiKey;
    }
    if ((baseUrl == null || baseUrl.isEmpty) && defaultBaseUrl.isNotEmpty) {
      await db.preferencesDao.setValue('api_base_url', defaultBaseUrl);
      baseUrl = defaultBaseUrl;
    }
  }

  return _BootConfig(apiKey: apiKey, baseUrl: baseUrl ?? '');
}
