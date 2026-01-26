/// Drishti App - User Repository
///
/// Handles API calls for user profile and settings.
library;

import 'dart:io';
import 'package:dio/dio.dart';
import '../../core/constants/api_endpoints.dart';
import '../models/user_model.dart';
import '../services/api_service.dart';

class UserRepository {
  final ApiService _api = ApiService();

  /// Get user profile
  Future<UserModel> getProfile() async {
    try {
      final response = await _api.get(ApiEndpoints.profile);

      if (response.statusCode == 200) {
        return UserModel.fromJson(response.data['user']);
      } else {
        throw Exception('Failed to load profile');
      }
    } catch (e) {
      throw Exception('Failed to load profile: $e');
    }
  }

  /// Update user profile
  Future<UserModel> updateProfile({
    String? name,
    UserSettings? settings,
  }) async {
    try {
      final Map<String, dynamic> data = {};
      if (name != null) data['name'] = name;
      if (settings != null) data['settings'] = settings.toJson();

      final response = await _api.put(ApiEndpoints.profile, data: data);

      if (response.statusCode == 200) {
        return UserModel.fromJson(response.data['user']);
      } else {
        throw Exception('Failed to update profile');
      }
    } catch (e) {
      throw Exception('Failed to update profile: $e');
    }
  }

  /// Connect to another user
  Future<void> connectUser(String targetUserId) async {
    try {
      await _api.post(
        ApiEndpoints.connectUser,
        data: {'target_user_id': targetUserId},
      );
    } catch (e) {
      throw Exception('Failed to connect user: $e');
    }
  }

  /// Get connected users
  Future<List<dynamic>> getConnectedUsers() async {
    try {
      final response = await _api.get(ApiEndpoints.connectedUsers);

      if (response.statusCode == 200) {
        return response.data['connectedUsers'];
      }
      return [];
    } catch (e) {
      throw Exception('Failed to load connected users: $e');
    }
  }

  /// Upload profile photo
  Future<UserModel> uploadProfilePhoto(File image) async {
    try {
      String fileName = image.path.split('/').last;

      FormData formData = FormData.fromMap({
        'image': await MultipartFile.fromFile(image.path, filename: fileName),
      });

      final response = await _api.postFormData(
        '${ApiEndpoints.profile}/photo',
        formData,
      );

      if (response.statusCode == 200) {
        return UserModel.fromJson(response.data['user']);
      } else {
        throw Exception('Failed to upload profile photo');
      }
    } catch (e) {
      throw Exception('Failed to upload profile photo: $e');
    }
  }

  /// Update emergency contacts
  Future<UserModel> updateEmergencyContacts(
    List<Map<String, dynamic>> contacts,
  ) async {
    try {
      final response = await _api.put(
        ApiEndpoints.profile,
        data: {'emergency_contacts': contacts},
      );

      if (response.statusCode == 200) {
        return UserModel.fromJson(response.data['user']);
      } else {
        throw Exception('Failed to update emergency contacts');
      }
    } catch (e) {
      throw Exception('Failed to update emergency contacts: $e');
    }
  }

  /// Get favorites
  Future<List<dynamic>> getFavorites() async {
    try {
      final response = await _api.get('/api/favorites');

      if (response.statusCode == 200) {
        return response.data['favorites'];
      }
      return [];
    } catch (e) {
      throw Exception('Failed to load favorites: $e');
    }
  }

  /// Add to favorites
  Future<void> addToFavorites(String personId) async {
    try {
      await _api.post('/api/favorites/$personId');
    } catch (e) {
      throw Exception('Failed to add to favorites: $e');
    }
  }

  /// Remove from favorites
  Future<void> removeFromFavorites(String personId) async {
    try {
      await _api.delete('/api/favorites/$personId');
    } catch (e) {
      throw Exception('Failed to remove from favorites: $e');
    }
  }

  /// Get help content
  Future<Map<String, dynamic>> getHelpContent() async {
    try {
      final response = await _api.get('/api/content/help');

      if (response.statusCode == 200) {
        return response.data;
      }
      return {};
    } catch (e) {
      throw Exception('Failed to load help content: $e');
    }
  }

  /// Get privacy policy
  Future<Map<String, dynamic>> getPrivacyPolicy() async {
    try {
      final response = await _api.get('/api/content/privacy');

      if (response.statusCode == 200) {
        return response.data;
      }
      return {};
    } catch (e) {
      throw Exception('Failed to load privacy policy: $e');
    }
  }

  /// Get about content
  Future<Map<String, dynamic>> getAboutContent() async {
    try {
      final response = await _api.get('/api/content/about');

      if (response.statusCode == 200) {
        return response.data;
      }
      return {};
    } catch (e) {
      throw Exception('Failed to load about content: $e');
    }
  }

  /// Remove profile photo
  Future<UserModel> removeProfilePhoto() async {
    try {
      final response = await _api.delete('${ApiEndpoints.profile}/photo');

      if (response.statusCode == 200) {
        return UserModel.fromJson(response.data['user']);
      } else {
        throw Exception('Failed to remove profile photo');
      }
    } catch (e) {
      throw Exception('Failed to remove profile photo: $e');
    }
  }

  /// Change password
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      final response = await _api.post(
        '/api/users/change-password',
        queryParameters: {
          'current_password': currentPassword,
          'new_password': newPassword,
        },
      );

      if (response.statusCode != 200) {
        throw Exception(response.data['detail'] ?? 'Failed to change password');
      }
    } catch (e) {
      if (e.toString().contains('detail')) {
        rethrow;
      }
      throw Exception('Failed to change password: $e');
    }
  }

  /// Delete account
  Future<void> deleteAccount(String password) async {
    try {
      final response = await _api.delete(
        '/api/users/account',
        queryParameters: {'password': password},
      );

      if (response.statusCode != 200) {
        throw Exception(response.data['detail'] ?? 'Failed to delete account');
      }
    } catch (e) {
      if (e.toString().contains('detail')) {
        rethrow;
      }
      throw Exception('Failed to delete account: $e');
    }
  }
}
