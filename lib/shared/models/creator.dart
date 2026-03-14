import 'package:flutter/foundation.dart';

@immutable
class Creator {
  final String id;
  final String userId;
  final String displayName;
  final String? avatarUrl;
  final String? bio;
  final List<String> specialties;
  final int recipeCount;
  final int fanCount;
  final bool isFanEligible; // recipe_count >= 30
  final bool isMyFanCreator;
  final double averageRating;
  final String? regionId;

  const Creator({
    required this.id,
    required this.userId,
    required this.displayName,
    this.avatarUrl,
    this.bio,
    required this.specialties,
    required this.recipeCount,
    required this.fanCount,
    required this.isFanEligible,
    required this.isMyFanCreator,
    required this.averageRating,
    this.regionId,
  });

  factory Creator.fromJson(Map<String, dynamic> json) => Creator(
        id: json['id'] as String,
        userId: json['user_id'] as String,
        displayName: json['display_name'] as String,
        avatarUrl: json['avatar_url'] as String?,
        bio: json['bio'] as String?,
        specialties: (json['specialties'] as List<dynamic>?)?.cast<String>() ?? [],
        recipeCount: (json['recipe_count'] as int?) ?? 0,
        fanCount: (json['fan_count'] as int?) ?? 0,
        isFanEligible: (json['is_fan_eligible'] as bool?) ?? false,
        isMyFanCreator: (json['is_my_fan_creator'] as bool?) ?? false,
        averageRating: (json['average_rating'] as num?)?.toDouble() ?? 0.0,
        regionId: json['food_region_id'] as String?,
      );
}

@immutable
class FanSubscription {
  final String id;
  final String userId;
  final String creatorId;
  final String status; // pending / active / cancelled
  final DateTime? effectiveFrom;
  final DateTime? effectiveUntil;
  final DateTime createdAt;

  const FanSubscription({
    required this.id,
    required this.userId,
    required this.creatorId,
    required this.status,
    this.effectiveFrom,
    this.effectiveUntil,
    required this.createdAt,
  });

  bool get isActive => status == 'active';
  bool get isPending => status == 'pending';

  factory FanSubscription.fromJson(Map<String, dynamic> json) =>
      FanSubscription(
        id: json['id'] as String,
        userId: json['user_id'] as String,
        creatorId: json['creator_id'] as String,
        status: json['status'] as String,
        effectiveFrom: json['effective_from'] != null
            ? DateTime.parse(json['effective_from'] as String)
            : null,
        effectiveUntil: json['effective_until'] != null
            ? DateTime.parse(json['effective_until'] as String)
            : null,
        createdAt: DateTime.parse(json['created_at'] as String),
      );
}
