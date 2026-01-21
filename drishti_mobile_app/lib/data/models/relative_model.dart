/// Drishti App - Relative Model
/// 
/// Known person / relative data model.
library;

class RelativeModel {
  final String id;
  final String name;
  final String relationship;
  final String addedBy;
  final String forUser;
  final List<PersonImage> images;
  final bool hasFaceEmbeddings;
  final String? notes;
  final String? phoneNumber;
  final String? email;
  final DateTime createdAt;
  final DateTime updatedAt;

  RelativeModel({
    required this.id,
    required this.name,
    required this.relationship,
    required this.addedBy,
    required this.forUser,
    this.images = const [],
    this.hasFaceEmbeddings = false,
    this.notes,
    this.phoneNumber,
    this.email,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  factory RelativeModel.fromJson(Map<String, dynamic> json) {
    return RelativeModel(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      relationship: json['relationship'] ?? '',
      addedBy: json['added_by'] ?? '',
      forUser: json['for_user'] ?? '',
      images: (json['images'] as List<dynamic>?)
          ?.map((e) => PersonImage.fromJson(e))
          .toList() ?? [],
      hasFaceEmbeddings: json['has_face_embeddings'] ?? false,
      notes: json['notes'],
      phoneNumber: json['phone_number'],
      email: json['email'],
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'relationship': relationship,
      'added_by': addedBy,
      'for_user': forUser,
      'images': images.map((e) => e.toJson()).toList(),
      'has_face_embeddings': hasFaceEmbeddings,
      'notes': notes,
      'phone_number': phoneNumber,
      'email': email,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  RelativeModel copyWith({
    String? id,
    String? name,
    String? relationship,
    String? addedBy,
    String? forUser,
    List<PersonImage>? images,
    bool? hasFaceEmbeddings,
    String? notes,
    String? phoneNumber,
    String? email,
  }) {
    return RelativeModel(
      id: id ?? this.id,
      name: name ?? this.name,
      relationship: relationship ?? this.relationship,
      addedBy: addedBy ?? this.addedBy,
      forUser: forUser ?? this.forUser,
      images: images ?? this.images,
      hasFaceEmbeddings: hasFaceEmbeddings ?? this.hasFaceEmbeddings,
      notes: notes ?? this.notes,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      email: email ?? this.email,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }
}

class PersonImage {
  final String filename;
  final String path;
  final DateTime? uploadedAt;
  
  // Local path for cached/stored images
  final String? localPath;

  PersonImage({
    required this.filename,
    required this.path,
    this.uploadedAt,
    this.localPath,
  });

  factory PersonImage.fromJson(Map<String, dynamic> json) {
    return PersonImage(
      filename: json['filename'] ?? '',
      path: json['path'] ?? '',
      uploadedAt: json['uploaded_at'] != null
          ? DateTime.parse(json['uploaded_at'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'filename': filename,
      'path': path,
      'uploaded_at': uploadedAt?.toIso8601String(),
    };
  }
}
