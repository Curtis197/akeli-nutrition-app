// lib/shared/models/creator_detail.dart
import 'package:flutter/foundation.dart';
import 'creator.dart';

@immutable
class CreatorDetail {
  final Creator creator;
  final int totalLikes;
  final int userConsumptionCount;
  final bool isFan;

  const CreatorDetail({
    required this.creator,
    required this.totalLikes,
    required this.userConsumptionCount,
    required this.isFan,
  });

  CreatorDetail copyWith({
    Creator? creator,
    int? totalLikes,
    int? userConsumptionCount,
    bool? isFan,
  }) =>
      CreatorDetail(
        creator: creator ?? this.creator,
        totalLikes: totalLikes ?? this.totalLikes,
        userConsumptionCount: userConsumptionCount ?? this.userConsumptionCount,
        isFan: isFan ?? this.isFan,
      );
}
