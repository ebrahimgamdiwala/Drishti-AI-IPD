/// Drishti App - Main Entry Point
///
/// Your Vision Companion - Accessibility-first mobile app.
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'core/themes/theme_provider.dart';
import 'data/providers/auth_provider.dart';
import 'data/providers/user_provider.dart';
import 'data/providers/vlm_provider.dart';
import 'data/services/storage_service.dart';
import 'data/services/voice_service.dart';
import 'routes/app_routes.dart';

void main() async {
  // Ensure Flutter is initialized
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Hive for local storage
  await Hive.initFlutter();

  // Initialize storage service
  await StorageService().init();

  // Initialize voice service
  await VoiceService().initTts();

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

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // Theme provider
        ChangeNotifierProvider(create: (_) => ThemeProvider()),

        // Auth provider
        ChangeNotifierProvider(create: (_) => AuthProvider()),

        // User provider
        ChangeNotifierProvider(create: (_) => UserProvider()),

        // VLM (Vision Language Model) provider
        ChangeNotifierProvider(create: (_) => VLMProvider()),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) {
          return MaterialApp(
            title: 'Drishti',
            debugShowCheckedModeBanner: false,

            // Theme - Glassmorphism
            theme: themeProvider.themeData,
            darkTheme: themeProvider.themeData,
            themeMode: ThemeMode.system,

            // Routes
            initialRoute: AppRoutes.splash,
            onGenerateRoute: AppRoutes.generateRoute,

            // Accessibility
            builder: (context, child) {
              return MediaQuery(
                // Respect system text scale factor for accessibility
                data: MediaQuery.of(context).copyWith(
                  textScaler: TextScaler.linear(
                    MediaQuery.of(
                      context,
                    ).textScaler.scale(1.0).clamp(1.0, 1.3),
                  ),
                ),
                child: child!,
              );
            },
          );
        },
      ),
    );
  }
}
