/// Drishti App - Auth Provider
/// 
/// State management for authentication.
library;

import 'package:flutter/foundation.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';
import '../services/storage_service.dart';

enum AuthStatus {
  initial,
  loading,
  authenticated,
  unauthenticated,
  error,
}

class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();
  final StorageService _storage = StorageService();

  AuthStatus _status = AuthStatus.initial;
  UserModel? _user;
  String? _error;

  AuthStatus get status => _status;
  UserModel? get user => _user;
  String? get error => _error;
  bool get isAuthenticated => _status == AuthStatus.authenticated;
  bool get isLoading => _status == AuthStatus.loading;

  /// Initialize auth state
  Future<void> init() async {
    // Don't call notifyListeners at the start to avoid issues during build
    _status = AuthStatus.loading;

    try {
      // Check for stored user
      final storedUser = _storage.getUser();
      final isLoggedIn = await _authService.isLoggedIn();

      if (storedUser != null && isLoggedIn) {
        _user = storedUser;
        _status = AuthStatus.authenticated;
      } else {
        _status = AuthStatus.unauthenticated;
      }
    } catch (e) {
      _status = AuthStatus.unauthenticated;
    }

    // Only notify once at the end
    notifyListeners();
  }

  /// Login with email and password
  Future<bool> login(String email, String password) async {
    _status = AuthStatus.loading;
    _error = null;
    notifyListeners();

    final result = await _authService.login(email, password);

    if (result.success && result.user != null) {
      _user = result.user;
      await _storage.saveUser(result.user!);
      _status = AuthStatus.authenticated;
      notifyListeners();
      return true;
    }

    _error = result.message;
    _status = AuthStatus.error;
    notifyListeners();
    return false;
  }

  /// Sign up with email and password
  Future<bool> signup({
    required String email,
    required String password,
    required String name,
  }) async {
    _status = AuthStatus.loading;
    _error = null;
    notifyListeners();

    final result = await _authService.signup(
      email: email,
      password: password,
      name: name,
    );

    if (result.success && result.user != null) {
      _user = result.user;
      await _storage.saveUser(result.user!);
      _status = AuthStatus.authenticated;
      notifyListeners();
      return true;
    }

    _error = result.message;
    _status = AuthStatus.error;
    notifyListeners();
    return false;
  }

  /// Sign in with Google
  Future<bool> googleSignIn() async {
    _status = AuthStatus.loading;
    _error = null;
    notifyListeners();

    final result = await _authService.googleSignIn();

    if (result.success && result.user != null) {
      _user = result.user;
      await _storage.saveUser(result.user!);
      _status = AuthStatus.authenticated;
      notifyListeners();
      return true;
    }

    _error = result.message;
    _status = AuthStatus.error;
    notifyListeners();
    return false;
  }

  /// Request password reset
  Future<bool> forgotPassword(String email) async {
    _status = AuthStatus.loading;
    notifyListeners();

    final result = await _authService.forgotPassword(email);

    _status = result.success ? AuthStatus.unauthenticated : AuthStatus.error;
    _error = result.success ? null : result.message;
    notifyListeners();

    return result.success;
  }

  /// Logout
  Future<void> logout() async {
    _status = AuthStatus.loading;
    notifyListeners();

    await _authService.logout();
    await _storage.clearUser();

    _user = null;
    _status = AuthStatus.unauthenticated;
    notifyListeners();
  }

  /// Update user data
  void updateUser(UserModel user) {
    _user = user;
    _storage.saveUser(user);
    notifyListeners();
  }

  /// Clear error
  void clearError() {
    _error = null;
    if (_status == AuthStatus.error) {
      _status = AuthStatus.unauthenticated;
    }
    notifyListeners();
  }
}
