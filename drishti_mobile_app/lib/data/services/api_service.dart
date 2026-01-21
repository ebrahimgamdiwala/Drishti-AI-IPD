/// Drishti App - API Service
///
/// HTTP client for backend API communication using Dio.
library;

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/constants/api_endpoints.dart';

class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;

  late final Dio _dio;
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  SharedPreferences? _webPrefs;
  String? _memoryToken;

  static const String _tokenKey = 'auth_token';

  ApiService._internal() {
    _dio = Dio(
      BaseOptions(
        baseUrl: ApiEndpoints.baseUrl,
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 30),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    // Add interceptors
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          // Add auth token if available
          final token = await _readToken();
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          return handler.next(options);
        },
        onError: (error, handler) {
          // Handle 401 unauthorized
          if (error.response?.statusCode == 401) {
            // Token expired or invalid
            _deleteToken();
          }
          return handler.next(error);
        },
      ),
    );
  }

  Future<String?> _readToken() async {
    if (kIsWeb) {
      _webPrefs ??= await SharedPreferences.getInstance();
      return _webPrefs!.getString(_tokenKey) ?? _memoryToken;
    }
    return await _storage.read(key: _tokenKey);
  }

  Future<void> _writeToken(String token) async {
    if (kIsWeb) {
      _webPrefs ??= await SharedPreferences.getInstance();
      await _webPrefs!.setString(_tokenKey, token);
      _memoryToken = token;
      return;
    }
    await _storage.write(key: _tokenKey, value: token);
  }

  Future<void> _deleteToken() async {
    if (kIsWeb) {
      _webPrefs ??= await SharedPreferences.getInstance();
      await _webPrefs!.remove(_tokenKey);
      _memoryToken = null;
      return;
    }
    await _storage.delete(key: _tokenKey);
  }

  /// Set authentication token
  Future<void> setToken(String token) async {
    await _writeToken(token);
  }

  /// Get current token
  Future<String?> getToken() async {
    return await _readToken();
  }

  /// Clear authentication token
  Future<void> clearToken() async {
    await _deleteToken();
  }

  /// Check if user is authenticated
  Future<bool> isAuthenticated() async {
    final token = await _readToken();
    return token != null && token.isNotEmpty;
  }

  // === HTTP Methods ===

  /// GET request
  Future<Response> get(
    String endpoint, {
    Map<String, dynamic>? queryParameters,
  }) async {
    try {
      return await _dio.get(endpoint, queryParameters: queryParameters);
    } on DioException {
      rethrow;
    }
  }

  /// POST request
  Future<Response> post(
    String endpoint, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
  }) async {
    try {
      return await _dio.post(
        endpoint,
        data: data,
        queryParameters: queryParameters,
      );
    } on DioException {
      rethrow;
    }
  }

  /// PUT request
  Future<Response> put(
    String endpoint, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
  }) async {
    try {
      return await _dio.put(
        endpoint,
        data: data,
        queryParameters: queryParameters,
      );
    } on DioException {
      rethrow;
    }
  }

  /// DELETE request
  Future<Response> delete(
    String endpoint, {
    Map<String, dynamic>? queryParameters,
  }) async {
    try {
      return await _dio.delete(endpoint, queryParameters: queryParameters);
    } on DioException {
      rethrow;
    }
  }

  /// POST with FormData (for file uploads)
  Future<Response> postFormData(String endpoint, FormData formData) async {
    try {
      return await _dio.post(
        endpoint,
        data: formData,
        options: Options(contentType: 'multipart/form-data'),
      );
    } on DioException {
      rethrow;
    }
  }

  /// Check API health
  Future<bool> checkHealth() async {
    try {
      final response = await get(ApiEndpoints.health);
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }
}
