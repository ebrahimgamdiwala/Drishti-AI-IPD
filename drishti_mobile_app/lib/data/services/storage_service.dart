/// Drishti App - Storage Service
///
/// Local storage for preferences, cached data, and images.
library;

import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';
import '../models/relative_model.dart';

class StorageService {
  static final StorageService _instance = StorageService._internal();
  factory StorageService() => _instance;
  StorageService._internal();

  SharedPreferences? _prefs;
  Directory? _appDir;
  Directory? _imagesDir;

  /// Initialize storage
  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();

    // Web: skip filesystem usage (not supported)
    if (kIsWeb) {
      _appDir = null;
      _imagesDir = null;
      return;
    }

    _appDir = await getApplicationDocumentsDirectory();
    _imagesDir = Directory('${_appDir!.path}/images');

    if (!await _imagesDir!.exists()) {
      await _imagesDir!.create(recursive: true);
    }
  }

  // === User Data ===

  /// Save user data
  Future<void> saveUser(UserModel user) async {
    await _prefs?.setString('user_data', jsonEncode(user.toJson()));
  }

  /// Get saved user data
  UserModel? getUser() {
    final data = _prefs?.getString('user_data');
    if (data != null) {
      return UserModel.fromJson(jsonDecode(data));
    }
    return null;
  }

  /// Clear user data
  Future<void> clearUser() async {
    await _prefs?.remove('user_data');
  }

  // === Settings ===

  /// Save a boolean setting
  Future<void> setBool(String key, bool value) async {
    await _prefs?.setBool(key, value);
  }

  /// Get a boolean setting
  bool getBool(String key, {bool defaultValue = false}) {
    return _prefs?.getBool(key) ?? defaultValue;
  }

  /// Save a string setting
  Future<void> setString(String key, String value) async {
    await _prefs?.setString(key, value);
  }

  /// Get a string setting
  String? getString(String key) {
    return _prefs?.getString(key);
  }

  /// Save a double setting
  Future<void> setDouble(String key, double value) async {
    await _prefs?.setDouble(key, value);
  }

  /// Get a double setting
  double getDouble(String key, {double defaultValue = 0.0}) {
    return _prefs?.getDouble(key) ?? defaultValue;
  }

  // === Image Storage ===

  /// Get images directory path
  String get imagesPath => _imagesDir?.path ?? '';

  /// Save image to local storage
  Future<String?> saveImage(File imageFile, String filename) async {
    try {
      if (kIsWeb) return null; // Skip on web
      if (_imagesDir == null) await init();

      final localPath = '${_imagesDir!.path}/$filename';
      await imageFile.copy(localPath);
      return localPath;
    } catch (e) {
      return null;
    }
  }

  /// Delete image from local storage
  Future<bool> deleteImage(String path) async {
    try {
      if (kIsWeb) return false;
      final file = File(path);
      if (await file.exists()) {
        await file.delete();
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  /// Get all local images
  Future<List<File>> getLocalImages() async {
    try {
      if (kIsWeb) return [];
      if (_imagesDir == null) await init();

      final files = _imagesDir!
          .listSync()
          .whereType<File>()
          .where(
            (f) =>
                f.path.endsWith('.jpg') ||
                f.path.endsWith('.jpeg') ||
                f.path.endsWith('.png'),
          )
          .toList();
      return files;
    } catch (e) {
      return [];
    }
  }

  // === Relatives Cache ===

  /// Save relatives list to cache
  Future<void> cacheRelatives(List<RelativeModel> relatives) async {
    final data = relatives.map((r) => r.toJson()).toList();
    await _prefs?.setString('cached_relatives', jsonEncode(data));
  }

  /// Get cached relatives
  List<RelativeModel> getCachedRelatives() {
    final data = _prefs?.getString('cached_relatives');
    if (data != null) {
      final list = jsonDecode(data) as List;
      return list.map((e) => RelativeModel.fromJson(e)).toList();
    }
    return [];
  }

  // === First Launch ===

  /// Check if first launch
  bool isFirstLaunch() {
    return _prefs?.getBool('first_launch') ?? true;
  }

  /// Mark first launch complete
  Future<void> setFirstLaunchComplete() async {
    await _prefs?.setBool('first_launch', false);
  }

  // === Clear All ===

  /// Clear all stored data
  Future<void> clearAll() async {
    await _prefs?.clear();

    if (kIsWeb) return;

    // Delete all images (mobile/desktop)
    if (_imagesDir != null && await _imagesDir!.exists()) {
      await _imagesDir!.delete(recursive: true);
      await _imagesDir!.create();
    }
  }
}
