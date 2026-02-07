/// Drishti App - API Endpoints
///
/// Backend API endpoint constants.
library;

class ApiEndpoints {
  ApiEndpoints._();

  // Base URL - point mobile clients to your PC on LAN
  static const String baseUrl = 'http://192.168.1.8:8000';

  // Auth Endpoints
  static const String login = '/api/auth/login';
  static const String signup = '/api/auth/signup';
  static const String googleAuth = '/api/auth/google';
  static const String verifyEmail = '/api/auth/verify-email';
  static const String forgotPassword = '/api/auth/forgot-password';
  static const String resetPassword = '/api/auth/reset-password';

  // User Endpoints
  static const String profile = '/api/users/profile';
  static const String connectUser = '/api/users/connect';
  static const String connectedUsers = '/api/users/connected';

  // Model Endpoints
  static const String analyze = '/api/model/analyze';
  static const String identify = '/api/model/identify';
  static const String modelHealth = '/api/model/health';

  // Alerts Endpoints
  static const String alerts = '/api/alerts';
  static const String alertStats = '/api/alerts/stats';

  // Known Persons / Relatives Endpoints
  static const String knownPersons = '/api/known-persons';

  // Subscriptions Endpoints
  static const String subscribe = '/api/subscribe';
  static const String subscribers = '/api/subscribe/subscribers';

  // Admin Endpoints
  static const String adminUsers = '/api/admin/users';
  static const String adminStats = '/api/admin/stats';
  static const String auditLogs = '/api/admin/audit-logs';

  // Health Check
  static const String health = '/api/health';
}
