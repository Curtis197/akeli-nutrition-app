import 'package:flutter/foundation.dart';

@immutable
class RecipeComment {
  final String id;
  final String recipeId;
  final String userId;
  final String? content;
  final int? rating;
  final int? ratingTaste;
  final int? ratingEase;
  final int? ratingSatiety;
  final DateTime createdAt;
  final DateTime updatedAt;

  // Joined user profile fields
  final String authorName;
  final String? authorAvatarUrl;

  const RecipeComment({
    required this.id,
    required this.recipeId,
    required this.userId,
    this.content,
    this.rating,
    this.ratingTaste,
    this.ratingEase,
    this.ratingSatiety,
    required this.createdAt,
    required this.updatedAt,
    required this.authorName,
    this.authorAvatarUrl,
  });

  factory RecipeComment.fromJson(Map<String, dynamic> json) {
    final profile = json['user_profile'] as Map<String, dynamic>?;
    
    String authorName = 'Utilisateur';
    if (profile != null) {
      final firstName = profile['first_name'] as String?;
      final lastName = profile['last_name'] as String?;
      final username = profile['username'] as String?;
      
      if (firstName != null && firstName.isNotEmpty) {
        authorName = lastName != null && lastName.isNotEmpty ? '$firstName $lastName' : firstName;
      } else if (username != null && username.isNotEmpty) {
        authorName = username;
      }
    }

    return RecipeComment(
      id: json['id'] as String,
      recipeId: json['recipe_id'] as String,
      userId: json['user_id'] as String,
      content: json['content'] as String?,
      rating: json['rating'] as int?,
      ratingTaste: json['rating_taste'] as int?,
      ratingEase: json['rating_ease'] as int?,
      ratingSatiety: json['rating_satiety'] as int?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      authorName: authorName,
      authorAvatarUrl: profile?['avatar_url'] as String?,
    );
  }
}
