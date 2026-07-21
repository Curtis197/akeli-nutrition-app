class BeautyLog {
  final String id;
  final String userId;
  final double hairLengthCm;
  final double hairStrengthScore;
  final double hairThicknessScore;
  final String hairSheddingRate;
  final double? scalpHealthScore;
  final double? curlRetentionScore;
  final double skinHydrationLevel;
  final double skinClarityScore;
  final List<String> checkinPhotoUrls;
  final String? checkinNotes;
  final DateTime loggedAt;

  const BeautyLog({
    required this.id,
    required this.userId,
    required this.hairLengthCm,
    required this.hairStrengthScore,
    required this.hairThicknessScore,
    required this.hairSheddingRate,
    this.scalpHealthScore,
    this.curlRetentionScore,
    required this.skinHydrationLevel,
    required this.skinClarityScore,
    this.checkinPhotoUrls = const [],
    this.checkinNotes,
    required this.loggedAt,
  });

  factory BeautyLog.fromJson(Map<String, dynamic> json) {
    return BeautyLog(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      hairLengthCm: (json['hair_length_cm'] as num?)?.toDouble() ?? 15.0,
      hairStrengthScore: (json['hair_strength_score'] as num?)?.toDouble() ?? 7.0,
      hairThicknessScore: (json['hair_thickness_score'] as num?)?.toDouble() ?? 7.0,
      hairSheddingRate: json['hair_shedding_rate'] as String? ?? 'moderate',
      scalpHealthScore: (json['scalp_health_score'] as num?)?.toDouble(),
      curlRetentionScore: (json['curl_retention_score'] as num?)?.toDouble(),
      skinHydrationLevel: (json['skin_hydration_level'] as num?)?.toDouble() ?? 7.0,
      skinClarityScore: (json['skin_clarity_score'] as num?)?.toDouble() ?? 7.0,
      checkinPhotoUrls: (json['checkin_photo_urls'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? const [],
      checkinNotes: json['checkin_notes'] as String?,
      loggedAt: json['logged_at'] != null ? DateTime.parse(json['logged_at'] as String) : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'hair_length_cm': hairLengthCm,
      'hair_strength_score': hairStrengthScore,
      'hair_thickness_score': hairThicknessScore,
      'hair_shedding_rate': hairSheddingRate,
      'scalp_health_score': scalpHealthScore,
      'curl_retention_score': curlRetentionScore,
      'skin_hydration_level': skinHydrationLevel,
      'skin_clarity_score': skinClarityScore,
      'checkin_photo_urls': checkinPhotoUrls,
      'checkin_notes': checkinNotes,
      'logged_at': loggedAt.toIso8601String(),
    };
  }
}
