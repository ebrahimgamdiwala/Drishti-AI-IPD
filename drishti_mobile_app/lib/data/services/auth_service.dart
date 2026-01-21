/// Drishti App - Auth Service
/// 
/// Authentication service for login, signup, and Google OAuth.
library;

import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../../core/constants/api_endpoints.dart';
import '../models/user_model.dart';
import 'api_service.dart';

class AuthResult {
  final bool success;
  final String? message;
  final String? token;
  final UserModel? user;

  AuthResult({
    required this.success,
    this.message,
    this.token,
    this.user,
  });
}

class AuthService {
  final ApiService _api = ApiService();
  final GoogleSignIn? _googleSignIn = kIsWeb
      ? null
      : GoogleSignIn(
          scopes: ['email', 'profile'],
        );

  /// Login with email and password
  Future<AuthResult> login(String email, String password) async {
    try {
      final response = await _api.post(
        ApiEndpoints.login,
        data: {
          'email': email,
          'password': password,
        },
      );

      if (response.statusCode == 200) {
        final data = response.data;
        final token = data['token'];
        
        if (token != null) {
          await _api.setToken(token);
        }

        return AuthResult(
          success: true,
          message: data['message'] ?? 'Login successful',
          token: token,
          user: data['user'] != null 
              ? UserModel.fromJson(data['user']) 
              : null,
        );
      }

      return AuthResult(
        success: false,
        message: response.data['detail'] ?? 'Login failed',
      );
    } catch (e) {
      return AuthResult(
        success: false,
        message: _parseError(e),
      );
    }
  }

  /// Sign up with email and password
  Future<AuthResult> signup({
    required String email,
    required String password,
    required String name,
    String role = 'user',
  }) async {
    try {
      final response = await _api.post(
        ApiEndpoints.signup,
        data: {
          'email': email,
          'password': password,
          'name': name,
          'role': role,
        },
      );

      if (response.statusCode == 200) {
        final data = response.data;
        final token = data['token'];
        
        if (token != null) {
          await _api.setToken(token);
        }

        return AuthResult(
          success: true,
          message: data['message'] ?? 'Signup successful',
          token: token,
          user: data['user'] != null 
              ? UserModel.fromJson(data['user']) 
              : null,
        );
      }

      return AuthResult(
        success: false,
        message: response.data['detail'] ?? 'Signup failed',
      );
    } catch (e) {
      return AuthResult(
        success: false,
        message: _parseError(e),
      );
    }
  }

  /// Login with Google
  Future<AuthResult> googleSignIn() async {
    if (kIsWeb) {
      return AuthResult(
        success: false,
        message: 'Google Sign-In is not configured for web in this build.',
      );
    }

    if (_googleSignIn == null) {
      return AuthResult(success: false, message: 'Google Sign-In unavailable');
    }

    try {
      // Sign out first to allow account selection
      await _googleSignIn.signOut();
      
      final account = await _googleSignIn.signIn();
      
      if (account == null) {
        return AuthResult(
          success: false,
          message: 'Google sign in cancelled',
        );
      }

      final auth = await account.authentication;
      
      // Send token to backend
      final response = await _api.post(
        ApiEndpoints.googleAuth,
        data: {
          'access_token': auth.accessToken,
          'id_token': auth.idToken,
        },
      );

      if (response.statusCode == 200) {
        final data = response.data;
        final token = data['token'];
        
        if (token != null) {
          await _api.setToken(token);
        }

        return AuthResult(
          success: true,
          message: data['message'] ?? 'Google sign in successful',
          token: token,
          user: data['user'] != null 
              ? UserModel.fromJson(data['user']) 
              : null,
        );
      }

      return AuthResult(
        success: false,
        message: response.data['detail'] ?? 'Google sign in failed',
      );
    } catch (e) {
      return AuthResult(
        success: false,
        message: _parseError(e),
      );
    }
  }

  /// Request password reset
  Future<AuthResult> forgotPassword(String email) async {
    try {
      final response = await _api.post(
        ApiEndpoints.forgotPassword,
        data: {'email': email},
      );

      return AuthResult(
        success: true,
        message: response.data['message'] ?? 'Reset email sent',
      );
    } catch (e) {
      return AuthResult(
        success: false,
        message: _parseError(e),
      );
    }
  }

  /// Logout
  Future<void> logout() async {
    await _api.clearToken();
    if (!kIsWeb) {
      await _googleSignIn?.signOut();
    }
  }

  /// Check if user is logged in
  Future<bool> isLoggedIn() async {
    return await _api.isAuthenticated();
  }

  /// Parse error message from exception
  String _parseError(dynamic error) {
    if (error.toString().contains('SocketException')) {
      return 'No internet connection';
    }
    if (error.toString().contains('401')) {
      return 'Invalid credentials';
    }
    if (error.toString().contains('400')) {
      return 'Invalid request';
    }
    return 'Something went wrong. Please try again.';
  }
}
