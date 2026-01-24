/// Drishti App - App Routes
///
/// Navigation routes configuration.
library;

import 'package:flutter/material.dart';
import '../presentation/screens/splash/splash_screen.dart';
import '../presentation/screens/auth/login_screen.dart';
import '../presentation/screens/auth/signup_screen.dart';
import '../presentation/screens/auth/forgot_password_screen.dart';
import '../presentation/screens/main_shell.dart';

class AppRoutes {
  AppRoutes._();

  // Route names
  static const String splash = '/';
  static const String login = '/login';
  static const String signup = '/signup';
  static const String forgotPassword = '/forgot-password';
  static const String main = '/main';
  static const String home = '/home';
  static const String dashboard = '/dashboard';
  static const String relatives = '/relatives';
  static const String relativeDetail = '/relative-detail';
  static const String addRelative = '/add-relative';
  static const String activity = '/activity';
  static const String settings = '/settings';
  static const String profile = '/profile';
  static const String editProfile = '/edit-profile';

  /// Generate routes
  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case splash:
        return _fadeRoute(const SplashScreen(), settings);

      case login:
        return _revealRoute(const LoginScreen(), settings);

      case signup:
        return _slideRoute(const SignupScreen(), settings);

      case forgotPassword:
        return _slideRoute(const ForgotPasswordScreen(), settings);

      case main:
        return _fadeRoute(const MainShell(), settings);

      default:
        return _fadeRoute(const SplashScreen(), settings);
    }
  }

  /// Fade transition
  static Route<dynamic> _fadeRoute(Widget page, RouteSettings settings) {
    return PageRouteBuilder(
      settings: settings,
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return FadeTransition(opacity: animation, child: child);
      },
      transitionDuration: const Duration(milliseconds: 300),
    );
  }

  /// Reveal transition (instant, no animation - used after splash)
  static Route<dynamic> _revealRoute(Widget page, RouteSettings settings) {
    return PageRouteBuilder(
      settings: settings,
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return child; // No animation, page is revealed instantly
      },
      transitionDuration: Duration.zero,
    );
  }

  /// Slide transition
  static Route<dynamic> _slideRoute(Widget page, RouteSettings settings) {
    return PageRouteBuilder(
      settings: settings,
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        const begin = Offset(1.0, 0.0);
        const end = Offset.zero;
        const curve = Curves.easeInOut;

        var tween = Tween(
          begin: begin,
          end: end,
        ).chain(CurveTween(curve: curve));

        return SlideTransition(position: animation.drive(tween), child: child);
      },
      transitionDuration: const Duration(milliseconds: 300),
    );
  }
}
