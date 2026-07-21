class BeautyLog {
  final String id;
  final String userId;

  // Hair Metrics
  final double? hairLengthCm;
  final double? hairStrengthScore;
  final double? hairThicknessScore;
  final String? hairSheddingRate;
  final double? scalpHealthScore;
  final double? curlRetentionScore;
  final String? porosityLevel;
  final bool protectiveStyleActive;

  // Skin Metrics
  final double? skinHydrationLevel;
  final double? skinClarityScore;
  final String? sebumOilLevel;
  final int acneBreakoutCount;
  final double? skinElasticityScore;
  final String? skinRednessLevel;

  // Routine Compliance & Journal
  final double? routineCompliancePct;
  final double? routineSatisfactionScore;
  final List<String> checkinPhotoUrls;
  final String? checkinNotes;
  final DateTime loggedAt;
  final DateTime createdAt;

  const BeautyLog({
    required this.id,
    required this.userId,
    this.hairLengthCm,
    this.hairStrengthScore,
    this.hairThicknessScore,
    this.hairSheddingRate,
    this.scalpHealthScore,
    this.curlRetentionScore,
    this.porosityLevel,
    this.protectiveStyleActive = false,
    this.skinHydrationLevel,
    this.skinClarityScore,
    this.sebumOilLevel,
    this.acneBreakoutCount = 0,
    this.skinElasticityScore,
    this.skinRednessLevel,
    this.routineCompliancePct,
    this.routineSatisfactionScore,
    this.checkinPhotoUrls = const [],
    this.checkinNotes,
    required this.loggedAt,
    required this.createdAt,
  });

  factory BeautyLog.fromJson(Map<String, dynamic> json) {
    return BeautyLog(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      hairLengthCm: (json['hair_length_cm'] as num?)?.toDouble(),
      hairStrengthScore: (json['hair_strength_score'] as num?)?.toDouble(),
      hairThicknessScore: (json['hair_thickness_score'] as num?)?.toDouble(),
      hairSheddingRate: json['hair_shedding_rate'] as String?,
      scalpHealthScore: (json['scalp_health_score'] as num?)?.toDouble(),
      curlRetentionScore: (json['curl_retention_score'] as num?)?.toDouble(),
      porosityLevel: json['porosity_level'] as String?,
      protectiveStyleActive: (json['protective_style_active'] as bool?) ?? false,
      skinHydrationLevel: (json['skin_hydration_level'] as num?)?.toDouble(),
      skinClarityScore: (json['skin_clarity_score'] as num?)?.toDouble(),
      sebumOilLevel: json['sebum_oil_level'] as String?,
      acneBreakoutCount: (json['acne_breakout_count'] as num?)?.toInt() ?? 0,
      skinElasticityScore: (json['skin_elasticity_score'] as num?)?.toDouble(),
      skinRednessLevel: json['skin_redness_level'] as String?,
      routineCompliancePct: (json['routine_compliance_pct'] as num?)?.toDouble(),
      routineSatisfactionScore: (json['routine_satisfaction_score'] as num?)?.toDouble(),
      checkinPhotoUrls: json['checkin_photo_urls'] is List
          ? List<String>.from(json['checkin_photo_urls'] as List)
          : const [],
      checkinNotes: json['checkin_notes'] as String?,
      loggedAt: json['logged_at'] != null
          ? DateTime.parse(json['logged_at'] as String)
          : DateTime.now(),
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'user_id': userId,
        'hair_length_cm': hairLengthCm,
        'hair_strength_score': hairStrengthScore,
        'hair_thickness_score': hairThicknessScore,
        'hair_shedding_rate': hairSheddingRate,
        'scalp_health_score': scalpHealthScore,
        'curl_retention_score': curlRetentionScore,
        'porosity_level': porosityLevel,
        'protective_style_active': protectiveStyleActive,
        'skin_hydration_level': skinHydrationLevel,
        'skin_clarity_score': skinClarityScore,
        'sebum_oil_level': sebumOilLevel,
        'acne_breakout_count': acneBreakoutCount,
        'skin_elasticity_score': skinElasticityScore,
        'skin_redness_level': skinRednessLevel,
        'routine_compliance_pct': routineCompliancePct,
        'routine_satisfaction_score': routineSatisfactionScore,
        'checkin_photo_urls': checkinPhotoUrls,
        'checkin_notes': checkinNotes,
        'logged_at': loggedAt.toIso8601String(),
        'created_at': createdAt.toIso8601String(),
      };
}
