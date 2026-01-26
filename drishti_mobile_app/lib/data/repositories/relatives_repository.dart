/// Drishti App - Relatives Repository
///
/// Handles API calls for known persons/relatives.
library;

import 'dart:io';
import 'package:dio/dio.dart';
import '../../core/constants/api_endpoints.dart';
import '../models/relative_model.dart';
import '../services/api_service.dart';

class RelativesRepository {
  final ApiService _api = ApiService();

  /// Get all relatives
  Future<List<RelativeModel>> getRelatives() async {
    try {
      final response = await _api.get(ApiEndpoints.knownPersons);

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data;
        return data.map((json) => RelativeModel.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      throw Exception('Failed to load relatives: $e');
    }
  }

  /// Add a new relative
  Future<RelativeModel> addRelative({
    required String name,
    required String relationship,
    required File image,
    String? notes,
    String? phoneNumber,
    String? email,
  }) async {
    try {
      String fileName = image.path.split('/').last;

      FormData formData = FormData.fromMap({
        'name': name,
        'relationship': relationship,
        'image': await MultipartFile.fromFile(image.path, filename: fileName),
        if (notes != null) 'notes': notes,
        if (phoneNumber != null) 'phone_number': phoneNumber,
        if (email != null) 'email': email,
      });

      final response = await _api.postFormData(
        ApiEndpoints.knownPersons,
        formData,
      );

      if (response.statusCode == 200) {
        return RelativeModel.fromJson(response.data);
      } else {
        throw Exception('Failed to add relative');
      }
    } catch (e) {
      throw Exception('Failed to add relative: $e');
    }
  }

  /// Update a relative
  Future<RelativeModel> updateRelative(RelativeModel relative) async {
    try {
      FormData formData = FormData.fromMap({
        'name': relative.name,
        'relationship': relative.relationship,
        if (relative.notes != null) 'notes': relative.notes,
        if (relative.phoneNumber != null) 'phone_number': relative.phoneNumber,
        if (relative.email != null) 'email': relative.email,
      });

      final response = await _api.put(
        '${ApiEndpoints.knownPersons}/${relative.id}',
        data: formData,
      );

      if (response.statusCode == 200) {
        return RelativeModel.fromJson(response.data);
      } else {
        throw Exception('Failed to update relative');
      }
    } catch (e) {
      throw Exception('Failed to update relative: $e');
    }
  }

  /// Delete a relative
  Future<void> deleteRelative(String id) async {
    if (id.isEmpty) {
      throw Exception('Invalid ID: cannot delete relative with empty ID');
    }

    try {
      await _api.delete('${ApiEndpoints.knownPersons}/$id');
    } catch (e) {
      throw Exception('Failed to delete relative: $e');
    }
  }

  /// Add a photo to a relative
  Future<RelativeModel> addPhoto(String id, File image) async {
    try {
      String fileName = image.path.split('/').last;

      FormData formData = FormData.fromMap({
        'image': await MultipartFile.fromFile(image.path, filename: fileName),
      });

      final response = await _api.postFormData(
        '${ApiEndpoints.knownPersons}/$id/photos',
        formData,
      );

      if (response.statusCode == 200) {
        return RelativeModel.fromJson(response.data);
      } else {
        throw Exception('Failed to add photo');
      }
    } catch (e) {
      throw Exception('Failed to add photo: $e');
    }
  }
}
