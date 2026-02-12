import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'providers/agent_providers.dart';
import 'providers/session_providers.dart';
import 'providers/settings_providers.dart';
import 'ui/chat/chat_screen.dart';
import 'ui/settings/api_config_screen.dart';
import 'ui/settings/memory_screen.dart';
import 'ui/settings/settings_screen.dart';
import 'ui/settings/system_prompt_screen.dart';
import 'ui/shared/theme.dart';

final _router = GoRouter(
  initialLocation: '/chat',
  routes: [
    GoRoute(
      path: '/chat',
      builder: (context, state) => const ChatScreen(),
    ),
    GoRoute(
      path: '/settings',
      builder: (context, state) => const SettingsScreen(),
      routes: [
        GoRoute(
          path: 'api',
          builder: (context, state) => const ApiConfigScreen(),
        ),
        GoRoute(
          path: 'prompt',
          builder: (context, state) => const SystemPromptScreen(),
        ),
        GoRoute(
          path: 'memory',
          builder: (context, state) => const MemoryScreen(),
        ),
      ],
    ),
  ],
);

class AgemilApp extends ConsumerWidget {
  const AgemilApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp.router(
      title: 'Agemily',
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: ThemeMode.system,
      routerConfig: _router,
      debugShowCheckedModeBanner: false,
      builder: (context, child) {
        return _AppLifecycleWrapper(child: child ?? const SizedBox.shrink());
      },
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('zh', 'CN'),
        Locale('en'),
      ],
      locale: const Locale('zh', 'CN'),
    );
  }
}

class _AppLifecycleWrapper extends ConsumerStatefulWidget {
  final Widget child;
  const _AppLifecycleWrapper({required this.child});

  @override
  ConsumerState<_AppLifecycleWrapper> createState() =>
      _AppLifecycleWrapperState();
}

class _AppLifecycleWrapperState extends ConsumerState<_AppLifecycleWrapper>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      final sessionId = ref.read(currentSessionIdProvider);
      final config = ref.read(llmConfigProvider);
      if (sessionId != null && config != null) {
        ref.read(memoryManagerProvider).extractMemories(sessionId, config);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
