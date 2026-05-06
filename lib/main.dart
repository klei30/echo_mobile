import 'package:chatmcp/dao/init_db.dart';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:window_manager/window_manager.dart' as wm;
import './logger.dart';
import './page/layout/layout.dart';
import './page/auth/auth_page.dart';
import './provider/provider_manager.dart';
import 'package:logging/logging.dart';
import 'utils/platform.dart';
import 'package:chatmcp/provider/settings_provider.dart';
import 'package:chatmcp/echo/auth_service.dart';
import 'package:chatmcp/echo/echo_host_service.dart';
import 'package:chatmcp/echo/echo_offline_memory_service.dart';
import 'package:chatmcp/echo/echo_runtime_service.dart';
import 'package:chatmcp/echo/notification_service.dart';
import 'package:chatmcp/page/echo_tabs/today_screen.dart';
import 'package:chatmcp/page/echo_tabs/growth_timeline_screen.dart';
import 'package:chatmcp/page/echo_tabs/nightly_training_screen.dart';
import 'package:chatmcp/page/echo_tabs/shadow_tournament_screen.dart';
import 'package:chatmcp/page/echo_tabs/talent_screen.dart';
import 'utils/init.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:chatmcp/generated/app_localizations.dart';
import 'package:bot_toast/bot_toast.dart';

final GlobalKey<ScaffoldMessengerState> _scaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();

// Add global navigator key
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  initializeLogger();

  await initNonWeb();

  if (kIsDesktop) {
    await wm.windowManager.ensureInitialized();

    final wm.WindowOptions windowOptions = wm.WindowOptions(
      size: Size(1200, 800),
      minimumSize: Size(400, 600),
      center: true,
      backgroundColor: Colors.transparent,
      skipTaskbar: false,
      titleBarStyle: wm.TitleBarStyle.hidden,
      windowButtonVisibility: true,
      alwaysOnTop: false,
      fullScreen: false,
    );

    await wm.windowManager.waitUntilReadyToShow(windowOptions, () async {
      try {
        await wm.windowManager.show();
        await wm.windowManager.focus();
        // Add a small delay to ensure window is properly initialized
        await Future.delayed(const Duration(milliseconds: 100));
      } catch (e) {
        Logger.root.warning('Window initialization error: $e');
      }
    });
  }

  try {
    // AuthService MUST init first — it loads userId from SharedPreferences.
    // ProviderManager.init() calls adoptOrphanChats() which stamps chats with
    // the current userId. If AuthService hasn't loaded yet, userId is null and
    // all legacy chats get stamped as 'anonymous', making them invisible.
    await Future.wait([AuthService().init(), EchoHostService().init(), EchoRuntimeService().init(), EchoOfflineMemoryService().init(), initDb()]);
    // Quick tunnels die when cloudflared stops — verify before any API calls.
    await EchoHostService().verifyTunnel();
    await ProviderManager.init();

    await initNotifications(
      onTap: (payload) async {
        await Future.delayed(const Duration(milliseconds: 300));
        final screen = _screenForNotificationPayload(payload);
        navigatorKey.currentState?.push(MaterialPageRoute(builder: (_) => screen));
      },
    );

    // Sync JWT into Echo provider if already logged in
    if (AuthService().isLoggedIn) {
      await AuthService().syncTokenToSettings();
    }

    var app = MyApp();

    runApp(MultiProvider(providers: [...ProviderManager.providers], child: app));
  } catch (e, stackTrace) {
    Logger.root.severe('Main error: $e\nStack trace:\n$stackTrace');
  }
}

Widget _screenForNotificationPayload(String? payload) {
  try {
    final data = jsonDecode(payload ?? '{}') as Map<String, dynamic>;
    final kind = data['kind'] as String? ?? '';
    final action = data['action'] is Map ? Map<String, dynamic>.from(data['action'] as Map) : {};
    final actionType = action['type'] as String? ?? '';
    if (kind == 'training_ready' || actionType == 'open_training') {
      return const NightlyTrainingScreen();
    }
    if (kind == 'growth_proof' || actionType == 'open_growth_timeline') {
      return const GrowthTimelineScreen();
    }
    if (kind == 'talent_revelation' || actionType == 'open_revelation') {
      return const TalentScreen();
    }
    if (kind == 'clone_returned' || actionType == 'open_clone_mission') {
      return const ShadowTournamentScreen();
    }
  } catch (_) {}
  return const TodayScreen();
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // Get default font for current platform
  String getPlatformFontFamily() {
    if (kIsWindows) {
      return 'Microsoft YaHei'; // Microsoft YaHei font
    }
    return ''; // Use Flutter default font for other platforms
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<SettingsProvider>(
      builder: (context, settings, child) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          scaffoldMessengerKey: _scaffoldMessengerKey,
          navigatorKey: navigatorKey,
          title: 'Echo',
          theme: ThemeData(useMaterial3: true, brightness: Brightness.light, fontFamily: getPlatformFontFamily(), colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFFC4783A))),
          darkTheme: ThemeData(useMaterial3: true, brightness: Brightness.dark, fontFamily: getPlatformFontFamily(), colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFFC4783A), brightness: Brightness.dark)),
          themeMode: _getThemeMode(settings.generalSetting.theme),
          home: AuthService().isLoggedIn ? const LayoutPage() : AuthGate(),
          locale: Locale(settings.generalSetting.locale),
          builder: BotToastInit(), //1.调用BotToastInit
          navigatorObservers: [BotToastNavigatorObserver()], //2.注册路由观察者
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [Locale('en'), Locale('zh'), Locale('tr'), Locale('de')],
        );
      },
    );
  }

  ThemeMode _getThemeMode(String theme) {
    switch (theme) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      case 'system':
      default:
        return ThemeMode.system;
    }
  }
}

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return AuthPage(
      onAuthenticated: () {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const LayoutPage()),
        );
      },
    );
  }
}
