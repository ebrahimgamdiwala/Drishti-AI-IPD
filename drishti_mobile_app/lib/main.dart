/// Drishti App - Main Entry Point
///
/// Your Vision Companion - Accessibility-first mobile app.
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'generated/l10n/app_localizations.dart';

import 'core/themes/theme_provider.dart';
import 'data/providers/auth_provider.dart';
import 'data/providers/user_provider.dart';
import 'data/providers/vlm_provider.dart';
import 'data/providers/voice_navigation_provider.dart';
import 'data/providers/locale_provider.dart';
import 'data/services/storage_service.dart';
import 'data/services/voice_service.dart';
import 'data/services/sherpa_stt_service.dart';
import 'routes/app_routes.dart';

void main() async {
  // Ensure Flutter is initialized
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Hive for local storage
  await Hive.initFlutter();

  // Initialize storage service
  await StorageService().init();

  // Initialize voice service (TTS)
  await VoiceService().initTts();

  // Initialize Sherpa-ONNX STT (checks for models, doesn't block if not downloaded)
  await SherpaSTTService().initialize();

  // Set preferred orientations
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Set system UI overlay style
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );

  runApp(const DrishtiApp());
}

class DrishtiApp extends StatelessWidget {
  const DrishtiApp({super.key});

  // Global navigator key for voice navigation
  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // Theme provider
        ChangeNotifierProvider(create: (_) => ThemeProvider()),

        // Locale provider
        ChangeNotifierProvider(create: (_) => LocaleProvider()),

        // Auth provider
        ChangeNotifierProvider(create: (_) => AuthProvider()),

        // User provider
        ChangeNotifierProvider(create: (_) => UserProvider()),

        // VLM (Vision Language Model) provider
        ChangeNotifierProvider(create: (_) => VLMProvider()),
      ],
      child: Builder(
        builder: (context) {
          return MultiProvider(
            providers: [
              // Voice Navigation provider with callbacks
              ChangeNotifierProvider(
                create: (_) => VoiceNavigationProvider(
                  navigatorKey: navigatorKey,
                  onToggleTheme: () {
                    context.read<ThemeProvider>().toggleTheme();
                  },
                  onSetTheme: (themeType) {
                    switch (themeType) {
                      case 'dark':
                        context.read<ThemeProvider>().setTheme(ThemeType.dark);
                        break;
                      case 'light':
                        context.read<ThemeProvider>().setTheme(ThemeType.light);
                        break;
                      case 'system':
                        context.read<ThemeProvider>().setTheme(
                          ThemeType.system,
                        );
                        break;
                      default:
                        debugPrint(
                          '[DrishtiApp] Unknown theme type: $themeType',
                        );
                    }
                  },
                ),
              ),
            ],
            child: Consumer2<ThemeProvider, LocaleProvider>(
              builder: (context, themeProvider, localeProvider, child) {
                return MaterialApp(
                  title: 'Drishti',
                  debugShowCheckedModeBanner: false,
                  navigatorKey: navigatorKey,

                  // Localization
                  localizationsDelegates: const [
                    AppLocalizations.delegate,
                    GlobalMaterialLocalizations.delegate,
                    GlobalWidgetsLocalizations.delegate,
                    GlobalCupertinoLocalizations.delegate,
                  ],
                  supportedLocales: const [
                    Locale('en', ''), // English
                    Locale('hi', ''), // Hindi
                    Locale('ta', ''), // Tamil
                    Locale('te', ''), // Telugu
                    Locale('bn', ''), // Bengali
                  ],
                  locale: localeProvider.locale,

                  // Theme
                  theme: themeProvider.themeData,
                  darkTheme: themeProvider.themeData,
                  themeMode: ThemeMode.system,

                  // Routes
                  initialRoute: AppRoutes.splash,
                  onGenerateRoute: AppRoutes.generateRoute,

                  // Accessibility
                  builder: (context, widget) {
                    return MediaQuery(
                      // Respect system text scale factor for accessibility
                      data: MediaQuery.of(context).copyWith(
                        textScaler: TextScaler.linear(
                          MediaQuery.of(
                            context,
                          ).textScaler.scale(1.0).clamp(1.0, 1.3),
                        ),
                      ),
                      child: widget!,
                    );
                  },
                );
              },
            ),
          );
        },
      ),
    );
  }
}
