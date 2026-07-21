import 'package:flutter_test/flutter_test.dart';
import 'package:akeli/shared/models/beauty_log.dart';

void main() {
  group('BeautyLog Model Tests', () {
    test('deserializes complete beauty log JSON accurately', () {
      final json = {
        'id': 'log-123',
        'user_id': 'user-456',
        'hair_length_cm': 32.5,
        'hair_strength_score': 7.8,
        'hair_thickness_score': 8.2,
        'hair_shedding_rate': 'low',
        'scalp_health_score': 9.0,
        'curl_retention_score': 8.5,
        'porosity_level': 'high',
        'protective_style_active': true,
        'skin_hydration_level': 8.0,
        'skin_clarity_score': 7.5,
        'sebum_oil_level': 'balanced',
        'acne_breakout_count': 1,
        'skin_elasticity_score': 8.5,
        'skin_redness_level': 'none',
        'routine_compliance_pct': 92.5,
        'routine_satisfaction_score': 9.0,
        'checkin_photo_urls': ['https://example.com/photo1.jpg'],
        'checkin_notes': 'Hair feeling stronger this month!',
        'logged_at': '2026-07-21T10:00:00Z',
        'created_at': '2026-07-21T10:00:00Z',
      };

      final log = BeautyLog.fromJson(json);

      expect(log.id, equals('log-123'));
      expect(log.userId, equals('user-456'));
      expect(log.hairLengthCm, equals(32.5));
      expect(log.hairStrengthScore, equals(7.8));
      expect(log.hairThicknessScore, equals(8.2));
      expect(log.hairSheddingRate, equals('low'));
      expect(log.protectiveStyleActive, isTrue);
      expect(log.routineCompliancePct, equals(92.5));
      expect(log.checkinPhotoUrls, contains('https://example.com/photo1.jpg'));
    });

    test('serializes BeautyLog to JSON accurately', () {
      final now = DateTime.now();
      final log = BeautyLog(
        id: 'log-789',
        userId: 'user-789',
        hairLengthCm: 25.0,
        hairStrengthScore: 6.5,
        loggedAt: now,
        createdAt: now,
      );

      final json = log.toJson();

      expect(json['id'], equals('log-789'));
      expect(json['user_id'], equals('user-789'));
      expect(json['hair_length_cm'], equals(25.0));
      expect(json['hair_strength_score'], equals(6.5));
    });
  });
}
