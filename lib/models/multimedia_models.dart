/// Model for recipe step with media support
class RecipeStep {
  final String id;
  final String recipeId;
  final int stepNumber;
  final String instructionText;
  final String? instructionTextFr;
  final String? instructionTextEn;
  final String? instructionTextEs;
  final String? instructionTextPt;
  final Duration? duration;
  final List<RecipeStepMedia> media;
  final DateTime createdAt;
  final DateTime updatedAt;

  RecipeStep({
    required this.id,
    required this.recipeId,
    required this.stepNumber,
    required this.instructionText,
    this.instructionTextFr,
    this.instructionTextEn,
    this.instructionTextEs,
    this.instructionTextPt,
    this.duration,
    this.media = const [],
    required this.createdAt,
    required this.updatedAt,
  });

  /// Get instruction text in the specified language with fallback
  String getInstruction(String langCode) {
    switch (langCode) {
      case 'en':
        return instructionTextEn ?? instructionText;
      case 'es':
        return instructionTextEs ?? instructionText;
      case 'pt':
        return instructionTextPt ?? instructionText;
      case 'fr':
      default:
        return instructionTextFr ?? instructionText;
    }
  }

  /// Get primary media (first image or video)
  RecipeStepMedia? getPrimaryMedia() {
    if (media.isEmpty) return null;
    return media.firstWhere((m) => m.isPrimary, orElse: () => media.first);
  }

  factory RecipeStep.fromJson(Map<String, dynamic> json) {
    return RecipeStep(
      id: json['id'] as String,
      recipeId: json['recipe_id'] as String,
      stepNumber: json['step_number'] as int,
      instructionText: json['instruction_text'] as String,
      instructionTextFr: json['instruction_text_fr'] as String?,
      instructionTextEn: json['instruction_text_en'] as String?,
      instructionTextEs: json['instruction_text_es'] as String?,
      instructionTextPt: json['instruction_text_pt'] as String?,
      duration: json['duration_seconds'] != null
          ? Duration(seconds: json['duration_seconds'] as int)
          : null,
      media: (json['media'] as List<dynamic>?)
              ?.map((m) => RecipeStepMedia.fromJson(m as Map<String, dynamic>))
              .toList() ??
          [],
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'recipe_id': recipeId,
      'step_number': stepNumber,
      'instruction_text': instructionText,
      'instruction_text_fr': instructionTextFr,
      'instruction_text_en': instructionTextEn,
      'instruction_text_es': instructionTextEs,
      'instruction_text_pt': instructionTextPt,
      'duration_seconds': duration?.inSeconds,
      'media': media.map((m) => m.toJson()).toList(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}

/// Model for recipe step media (image or video)
class RecipeStepMedia {
  final String id;
  final String stepId;
  final MediaType mediaType;
  final String mediaUrl;
  final String? thumbnailUrl;
  final String? altText;
  final int displayOrder;
  final bool isPrimary;
  final DateTime createdAt;

  RecipeStepMedia({
    required this.id,
    required this.stepId,
    required this.mediaType,
    required this.mediaUrl,
    this.thumbnailUrl,
    this.altText,
    required this.displayOrder,
    required this.isPrimary,
    required this.createdAt,
  });

  factory RecipeStepMedia.fromJson(Map<String, dynamic> json) {
    return RecipeStepMedia(
      id: json['id'] as String,
      stepId: json['step_id'] as String,
      mediaType: MediaType.fromString(json['media_type'] as String),
      mediaUrl: json['media_url'] as String,
      thumbnailUrl: json['thumbnail_url'] as String?,
      altText: json['alt_text'] as String?,
      displayOrder: json['display_order'] as int,
      isPrimary: json['is_primary'] as bool? ?? false,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'step_id': stepId,
      'media_type': mediaType.toString().split('.').last,
      'media_url': mediaUrl,
      'thumbnail_url': thumbnailUrl,
      'alt_text': altText,
      'display_order': displayOrder,
      'is_primary': isPrimary,
      'created_at': createdAt.toIso8601String(),
    };
  }
}

/// Enum for media type
enum MediaType {
  image,
  video;

  static MediaType fromString(String value) {
    switch (value.toLowerCase()) {
      case 'video':
        return MediaType.video;
      case 'image':
      default:
        return MediaType.image;
    }
  }

  bool get isImage => this == MediaType.image;
  bool get isVideo => this == MediaType.video;
}

/// Extended Ingredient model with image support
class Ingredient {
  final String id;
  final String name;
  final String? nameFr;
  final String? nameEn;
  final String? nameEs;
  final String? namePt;
  final String? description;
  final String? imageUrl;
  final String? imageThumbnailUrl;
  final DateTime? updatedAt;

  Ingredient({
    required this.id,
    required this.name,
    this.nameFr,
    this.nameEn,
    this.nameEs,
    this.namePt,
    this.description,
    this.imageUrl,
    this.imageThumbnailUrl,
    this.updatedAt,
  });

  /// Get name in the specified language with fallback
  String getName(String langCode) {
    switch (langCode) {
      case 'en':
        return nameEn ?? name;
      case 'es':
        return nameEs ?? name;
      case 'pt':
        return namePt ?? name;
      case 'fr':
      default:
        return nameFr ?? name;
    }
  }

  factory Ingredient.fromJson(Map<String, dynamic> json) {
    return Ingredient(
      id: json['id'] as String,
      name: json['name'] as String,
      nameFr: json['name_fr'] as String?,
      nameEn: json['name_en'] as String?,
      nameEs: json['name_es'] as String?,
      namePt: json['name_pt'] as String?,
      description: json['description'] as String?,
      imageUrl: json['image_url'] as String?,
      imageThumbnailUrl: json['image_thumbnail_url'] as String?,
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'name_fr': nameFr,
      'name_en': nameEn,
      'name_es': nameEs,
      'name_pt': namePt,
      'description': description,
      'image_url': imageUrl,
      'image_thumbnail_url': imageThumbnailUrl,
      'updated_at': updatedAt?.toIso8601String(),
    };
  }
}
