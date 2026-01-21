/// Drishti App - User Provider
/// 
/// State management for user profile and settings.
library;

import 'package:flutter/foundation.dart';
import '../../core/constants/api_endpoints.dart';
import '../models/user_model.dart';
import '../services/api_service.dart';
import '../services/storage_service.dart';

class UserProvider extends ChangeNotifier {
  final ApiService _api = ApiService();
  final StorageService _storage = StorageService();

  UserModel? _user;
  bool _isLoading = false;
  String? _error;

  UserModel? get user => _user;
  bool get isLoading => _isLoading;
  String? get error => _error;

  /// Set user from auth
  void setUser(UserModel? user) {
    _user = user;
    notifyListeners();
  }

  /// Fetch user profile from server
  Future<void> fetchProfile() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _api.get(ApiEndpoints.profile);
      
      if (response.statusCode == 200) {
        _user = UserModel.fromJson(response.data['user']);
        await _storage.saveUser(_user!);
      }
    } catch (e) {
      _error = 'Failed to fetch profile';
    }

    _isLoading = false;
    notifyListeners();
  }

  /// Update user profile
  Future<bool> updateProfile({
    String? name,
    List<EmergencyContact>? emergencyContacts,
    UserSettings? settings,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final data = <String, dynamic>{};
      
      if (name != null) data['name'] = name;
      if (emergencyContacts != null) {
        data['emergency_contacts'] = emergencyContacts
            .map((c) => c.toJson())
            .toList();
      }
      if (settings != null) {
        data['settings'] = settings.toJson();
      }

      final response = await _api.put(
        ApiEndpoints.profile,
        data: data,
      );

      if (response.statusCode == 200) {
        _user = UserModel.fromJson(response.data['user']);
        await _storage.saveUser(_user!);
        _isLoading = false;
        notifyListeners();
        return true;
      }
    } catch (e) {
      _error = 'Failed to update profile';
    }

    _isLoading = false;
    notifyListeners();
    return false;
  }

  /// Update voice speed setting
  Future<void> updateVoiceSpeed(double speed) async {
    if (_user == null) return;

    final newSettings = UserSettings(
      voiceSpeed: speed,
      highContrast: _user!.settings.highContrast,
      continuousListening: _user!.settings.continuousListening,
      alertPreferences: _user!.settings.alertPreferences,
    );

    await updateProfile(settings: newSettings);
  }

  /// Toggle high contrast
  Future<void> toggleHighContrast() async {
    if (_user == null) return;

    final newSettings = UserSettings(
      voiceSpeed: _user!.settings.voiceSpeed,
      highContrast: !_user!.settings.highContrast,
      continuousListening: _user!.settings.continuousListening,
      alertPreferences: _user!.settings.alertPreferences,
    );

    await updateProfile(settings: newSettings);
  }

  /// Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }
}
