/// Drishti App - Relatives Repository
///
/// Handles API calls for known persons/relatives.
library;

import 'dart:io';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import '../../core/constants/api_endpoints.dart';
import '../models/relative_model.dart';
import '../services/api_service.dart';
import '../services/local_face_embedding_service.dart';
import '../services/network_status_service.dart';
import '../services/storage_service.dart';

class RelativesRepository {
  final ApiService _api = ApiService();
  final StorageService _storage = StorageService();
  final NetworkStatusService _network = NetworkStatusService();
  final LocalFaceEmbeddingService _localEmbedding = LocalFaceEmbeddingService();

  /// Get all relatives
  Future<List<RelativeModel>> getRelatives() async {
    final cached = _storage.getCachedRelatives();

    if (!await _network.hasInternetConnection()) {
      return cached;
    }

    try {
      await syncPendingOperations();

      final response = await _api.get(
        ApiEndpoints.knownPersons,
        queryParameters: {'include_embeddings': true},
      );

      if (response.statusCode == 200) {
        final body = response.data;
        final List<dynamic> data = body is List
            ? body
            : (body['knownPersons'] as List<dynamic>? ?? const []);

        final relatives = data
            .map((json) => RelativeModel.fromJson(json as Map<String, dynamic>))
            .toList();

        final hydrated = await _hydrateLocalEmbeddings(relatives, cached);
        final merged = _mergeWithPendingLocals(hydrated, cached);

        await _storage.cacheRelatives(merged);
        return merged;
      }
      return cached;
    } catch (e) {
      return cached;
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
    final localEmbedding = await _localEmbedding.embeddingFromImageFile(image);

    if (!await _network.hasInternetConnection()) {
      final localImagePath = await _copyRelativeImageToLocal(image);
      final localRelative = RelativeModel(
        id: 'local-${DateTime.now().millisecondsSinceEpoch}',
        name: name,
        relationship: relationship,
        addedBy: 'local',
        forUser: 'local',
        notes: notes,
        phoneNumber: phoneNumber,
        email: email,
        isPendingSync: true,
        localFaceEmbeddings: localEmbedding == null
            ? const []
            : [localEmbedding],
        images: localImagePath == null
            ? const []
            : [
                PersonImage(
                  filename: localImagePath.split('/').last,
                  path: localImagePath,
                  localPath: localImagePath,
                ),
              ],
      );
      await _upsertCachedRelative(localRelative);
      await _enqueuePendingOperation({
        'type': 'add',
        'payload': {
          'local_id': localRelative.id,
          'name': name,
          'relationship': relationship,
          'notes': notes,
          'phone_number': phoneNumber,
          'email': email,
          'image_path': localImagePath,
          'local_embedding': localEmbedding,
        },
      });
      return localRelative;
    }

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
        final body = response.data as Map<String, dynamic>;
        final relativeJson = (body['person'] as Map<String, dynamic>?) ?? body;
        final relative = RelativeModel.fromJson(relativeJson).copyWith(
          isPendingSync: false,
          localFaceEmbeddings: localEmbedding == null
              ? const []
              : [localEmbedding],
        );
        await _upsertCachedRelative(relative);
        return relative;
      } else {
        throw Exception('Failed to add relative');
      }
    } catch (e) {
      final localImagePath = await _copyRelativeImageToLocal(image);
      final localRelative = RelativeModel(
        id: 'local-${DateTime.now().millisecondsSinceEpoch}',
        name: name,
        relationship: relationship,
        addedBy: 'local',
        forUser: 'local',
        notes: notes,
        phoneNumber: phoneNumber,
        email: email,
        isPendingSync: true,
        localFaceEmbeddings: localEmbedding == null
            ? const []
            : [localEmbedding],
        images: localImagePath == null
            ? const []
            : [
                PersonImage(
                  filename: localImagePath.split('/').last,
                  path: localImagePath,
                  localPath: localImagePath,
                ),
              ],
      );
      await _upsertCachedRelative(localRelative);
      await _enqueuePendingOperation({
        'type': 'add',
        'payload': {
          'local_id': localRelative.id,
          'name': name,
          'relationship': relationship,
          'notes': notes,
          'phone_number': phoneNumber,
          'email': email,
          'image_path': localImagePath,
          'local_embedding': localEmbedding,
        },
      });
      return localRelative;
    }
  }

  /// Update a relative
  Future<RelativeModel> updateRelative(RelativeModel relative) async {
    if (!await _network.hasInternetConnection() ||
        relative.id.startsWith('local-')) {
      final pending = relative.copyWith(isPendingSync: true);
      await _upsertCachedRelative(pending);

      if (relative.id.startsWith('local-')) {
        await _updatePendingAddPayload(relative.id, {
          'name': pending.name,
          'relationship': pending.relationship,
          'notes': pending.notes,
          'phone_number': pending.phoneNumber,
          'email': pending.email,
          'local_embedding': pending.localFaceEmbeddings.isNotEmpty
              ? pending.localFaceEmbeddings.first
              : null,
        });
        return pending;
      }

      await _enqueuePendingOperation({
        'type': 'update',
        'payload': pending.toJson(),
      });
      return pending;
    }

    try {
      final payload = <String, dynamic>{
        'name': relative.name,
        'relationship': relative.relationship,
        if (relative.notes != null) 'notes': relative.notes,
        if (relative.phoneNumber != null) 'phone_number': relative.phoneNumber,
        if (relative.email != null) 'email': relative.email,
      };

      final response = await _api.put(
        '${ApiEndpoints.knownPersons}/${relative.id}',
        data: payload,
      );

      if (response.statusCode == 200) {
        final body = response.data as Map<String, dynamic>;
        final relativeJson =
            (body['knownPerson'] as Map<String, dynamic>?) ??
            (body['person'] as Map<String, dynamic>?) ??
            body;
        final updated = RelativeModel.fromJson(relativeJson);
        await _upsertCachedRelative(updated);
        return updated;
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

    final cached = _storage.getCachedRelatives();
    final filtered = cached.where((r) => r.id != id).toList(growable: false);
    await _storage.cacheRelatives(filtered);

    if (!await _network.hasInternetConnection() || id.startsWith('local-')) {
      if (id.startsWith('local-')) {
        await _removePendingLocalOperations(id);
      } else {
        await _enqueuePendingOperation({
          'type': 'delete',
          'payload': {'id': id},
        });
      }
      return;
    }

    try {
      await _api.delete('${ApiEndpoints.knownPersons}/$id');
    } catch (e) {
      await _enqueuePendingOperation({
        'type': 'delete',
        'payload': {'id': id},
      });
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
        final body = response.data as Map<String, dynamic>;
        final relativeJson =
            (body['knownPerson'] as Map<String, dynamic>?) ??
            (body['person'] as Map<String, dynamic>?) ??
            body;

        if (relativeJson.containsKey('name') &&
            relativeJson.containsKey('relationship')) {
          final updated = RelativeModel.fromJson(relativeJson);
          await _upsertCachedRelative(updated);
          return updated;
        }

        // /photos currently returns a compact knownPerson payload.
        final cached = _storage.getCachedRelatives();
        final existing = cached.where((r) => r.id == id).toList();
        if (existing.isNotEmpty) {
          return existing.first.copyWith();
        }

        throw Exception('Photo added but relative payload was incomplete');
      } else {
        throw Exception('Failed to add photo');
      }
    } catch (e) {
      throw Exception('Failed to add photo: $e');
    }
  }

  Future<void> syncPendingOperations() async {
    if (!await _network.hasInternetConnection()) return;

    final pending = _storage.getPendingRelativeOps();
    if (pending.isEmpty) return;

    final remaining = <Map<String, dynamic>>[];

    for (final op in pending) {
      final type = op['type'] as String? ?? '';
      final payload = (op['payload'] as Map<String, dynamic>?) ?? const {};

      try {
        if (type == 'add') {
          final localId = payload['local_id'] as String?;
          final imagePath = payload['image_path'] as String?;
          if (imagePath == null || imagePath.isEmpty) {
            continue;
          }
          final imageFile = File(imagePath);
          if (!await imageFile.exists()) {
            continue;
          }

          final formData = FormData.fromMap({
            'name': payload['name'],
            'relationship': payload['relationship'],
            if (payload['notes'] != null) 'notes': payload['notes'],
            if (payload['phone_number'] != null)
              'phone_number': payload['phone_number'],
            if (payload['email'] != null) 'email': payload['email'],
            'image': await MultipartFile.fromFile(
              imagePath,
              filename: imagePath.split('/').last,
            ),
          });

          final response = await _api.postFormData(
            ApiEndpoints.knownPersons,
            formData,
          );

          if (response.statusCode == 200) {
            final body = response.data as Map<String, dynamic>;
            final relativeJson =
                (body['person'] as Map<String, dynamic>?) ?? body;
            final syncedRelative = RelativeModel.fromJson(relativeJson)
                .copyWith(
                  isPendingSync: false,
                  localFaceEmbeddings: payload['local_embedding'] is List
                      ? [
                          (payload['local_embedding'] as List<dynamic>)
                              .map((v) => (v as num).toDouble())
                              .toList(growable: false),
                        ]
                      : const [],
                );

            final cached = _storage.getCachedRelatives();
            final withoutLocal = cached.where((r) => r.id != localId).toList();
            final existingIdx = withoutLocal.indexWhere(
              (r) => r.id == syncedRelative.id,
            );
            if (existingIdx >= 0) {
              withoutLocal[existingIdx] = syncedRelative;
            } else {
              withoutLocal.add(syncedRelative);
            }
            await _storage.cacheRelatives(withoutLocal);
          }
        } else if (type == 'delete') {
          final id = payload['id'] as String?;
          if (id != null && id.isNotEmpty) {
            await _api.delete('${ApiEndpoints.knownPersons}/$id');
          }
        } else if (type == 'update') {
          final model = RelativeModel.fromJson(payload);
          if (!model.id.startsWith('local-')) {
            await updateRelative(model.copyWith(isPendingSync: false));
          }
        }
      } catch (_) {
        remaining.add(op);
      }
    }

    await _storage.savePendingRelativeOps(remaining);
  }

  Future<void> _enqueuePendingOperation(Map<String, dynamic> op) async {
    final pending = _storage.getPendingRelativeOps();
    pending.add(op);
    await _storage.savePendingRelativeOps(pending);
  }

  Future<void> _updatePendingAddPayload(
    String localId,
    Map<String, dynamic> updates,
  ) async {
    final pending = _storage.getPendingRelativeOps();
    for (int i = 0; i < pending.length; i++) {
      final op = pending[i];
      final type = op['type'] as String?;
      final payload = (op['payload'] as Map<String, dynamic>?) ?? {};
      if (type == 'add' && payload['local_id'] == localId) {
        final merged = Map<String, dynamic>.from(payload);
        merged.addAll(updates);
        pending[i] = {'type': 'add', 'payload': merged};
        break;
      }
    }
    await _storage.savePendingRelativeOps(pending);
  }

  Future<void> _removePendingLocalOperations(String localId) async {
    final pending = _storage.getPendingRelativeOps();
    final filtered = pending
        .where((op) {
          final type = op['type'] as String?;
          final payload = (op['payload'] as Map<String, dynamic>?) ?? {};
          if (type == 'add' && payload['local_id'] == localId) {
            return false;
          }
          if (type == 'update' && payload['id'] == localId) {
            return false;
          }
          return true;
        })
        .toList(growable: false);
    await _storage.savePendingRelativeOps(filtered);
  }

  Future<void> _upsertCachedRelative(RelativeModel relative) async {
    final cached = _storage.getCachedRelatives();
    final idx = cached.indexWhere((r) => r.id == relative.id);
    if (idx >= 0) {
      cached[idx] = relative;
    } else {
      cached.add(relative);
    }
    await _storage.cacheRelatives(cached);
  }

  Future<List<RelativeModel>> _hydrateLocalEmbeddings(
    List<RelativeModel> serverRelatives,
    List<RelativeModel> cachedRelatives,
  ) async {
    final updated = <RelativeModel>[];

    for (final relative in serverRelatives) {
      if (relative.localFaceEmbeddings.isNotEmpty) {
        updated.add(relative);
        continue;
      }

      RelativeModel? cached;
      for (final r in cachedRelatives) {
        if (r.id == relative.id) {
          cached = r;
          break;
        }
      }
      if (cached != null && cached.localFaceEmbeddings.isNotEmpty) {
        updated.add(
          relative.copyWith(
            localFaceEmbeddings: cached.localFaceEmbeddings,
            isPendingSync: cached.isPendingSync,
          ),
        );
        continue;
      }

      List<double>? embedding;
      if (relative.images.isNotEmpty) {
        final first = relative.images.first;
        final imageUrl = first.path.startsWith('http')
            ? first.path
            : '${ApiEndpoints.baseUrl}${first.path}';
        try {
          final response = await Dio().get<List<int>>(
            imageUrl,
            options: Options(responseType: ResponseType.bytes),
          );
          final bytes = response.data;
          if (bytes != null) {
            embedding = await _localEmbedding.embeddingFromBytes(
              Uint8List.fromList(List<int>.from(bytes)),
            );
          }
        } catch (_) {
          embedding = null;
        }
      }

      updated.add(
        relative.copyWith(
          localFaceEmbeddings: embedding == null ? const [] : [embedding],
        ),
      );
    }

    return updated;
  }

  List<RelativeModel> _mergeWithPendingLocals(
    List<RelativeModel> serverRelatives,
    List<RelativeModel> cachedRelatives,
  ) {
    final merged = List<RelativeModel>.from(serverRelatives);
    final pendingLocals = cachedRelatives.where(
      (r) => r.isPendingSync || r.id.startsWith('local-'),
    );

    for (final local in pendingLocals) {
      if (!merged.any((r) => r.id == local.id)) {
        merged.add(local);
      }
    }

    return merged;
  }

  Future<String?> _copyRelativeImageToLocal(File image) async {
    try {
      final filename =
          'relative_${DateTime.now().millisecondsSinceEpoch}_${image.path.split('/').last}';
      return await _storage.saveImage(image, filename);
    } catch (_) {
      return null;
    }
  }
}
