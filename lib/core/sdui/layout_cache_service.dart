import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';

/// Layout modes available in AKELI
enum AppMode {
  nutrition,
  beauty,
  health,
  sport,
  family,
}

extension AppModeExtension on AppMode {
  String get displayName {
    switch (this) {
      case AppMode.nutrition:
        return 'Nutrition';
      case AppMode.beauty:
        return 'Beauté';
      case AppMode.health:
        return 'Santé';
      case AppMode.sport:
        return 'Sport';
      case AppMode.family:
        return 'Famille';
    }
  }

  String get iconData {
    switch (this) {
      case AppMode.nutrition:
        return 'restaurant';
      case AppMode.beauty:
        return 'spa';
      case AppMode.health:
        return 'favorite';
      case AppMode.sport:
        return 'fitness_center';
      case AppMode.family:
        return 'family_restroom';
    }
  }

  String get routePath {
    switch (this) {
      case AppMode.nutrition:
        return '/nutrition';
      case AppMode.beauty:
        return '/beauty';
      case AppMode.health:
        return '/health';
      case AppMode.sport:
        return '/sport';
      case AppMode.family:
        return '/family';
    }
  }
}

/// Remote layout model fetched from Supabase
class RemoteLayout {
  final String id;
  final AppMode mode;
  final String version;
  final Map<String, dynamic> layoutJson;
  final DateTime fetchedAt;
  final String? cultureTag;

  RemoteLayout({
    required this.id,
    required this.mode,
    required this.version,
    required this.layoutJson,
    required this.fetchedAt,
    this.cultureTag,
  });

  factory RemoteLayout.fromJson(Map<String, dynamic> json) {
    return RemoteLayout(
      id: json['id'] as String,
      mode: AppMode.values.firstWhere(
        (m) => m.name == json['mode'],
        orElse: () => AppMode.nutrition,
      ),
      version: json['version'] as String,
      layoutJson: json['layout'] as Map<String, dynamic>,
      fetchedAt: DateTime.parse(json['fetched_at'] as String),
      cultureTag: json['culture_tag'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'mode': mode.name,
      'version': version,
      'layout': layoutJson,
      'fetched_at': fetchedAt.toIso8601String(),
      'culture_tag': cultureTag,
    };
  }
}

/// Cache service for storing remote layouts locally using Hive
class LayoutCacheService {
  static const String _boxName = 'remote_layouts';
  static const String _currentModeKey = 'current_mode';
  static const String _layoutVersionKey = 'layout_version_';

  late Box<Map<dynamic, dynamic>> _layoutBox;

  Future<void> init() async {
    await Hive.openBox<Map<dynamic, dynamic>>(_boxName);
    _layoutBox = Hive.box<Map<dynamic, dynamic>>(_boxName);
    debugPrint('[LayoutCacheService] Initialized Hive box: $_boxName');
  }

  /// Store a remote layout in cache
  Future<void> cacheLayout(RemoteLayout layout) async {
    await _layoutBox.put(layout.id, layout.toJson());
    await _layoutBox.put('${_layoutVersionKey}${layout.mode.name}', layout.version);
    debugPrint(
      '[LayoutCacheService] Cached layout: ${layout.id} (mode: ${layout.mode}, version: ${layout.version})',
    );
  }

  /// Retrieve a cached layout by ID
  RemoteLayout? getCachedLayout(String layoutId) {
    final data = _layoutBox.get(layoutId);
    if (data == null) return null;
    
    try {
      return RemoteLayout.fromJson(Map<String, dynamic>.from(data));
    } catch (e) {
      debugPrint('[LayoutCacheService] Error parsing cached layout: $e');
      return null;
    }
  }

  /// Get cached layout version for a mode
  String? getCachedVersion(AppMode mode) {
    return _layoutBox.get('${_layoutVersionKey}${mode.name}') as String?;
  }

  /// Set current active mode
  Future<void> setCurrentMode(AppMode mode) async {
    await _layoutBox.put(_currentModeKey, mode.name);
    debugPrint('[LayoutCacheService] Current mode set to: ${mode.name}');
  }

  /// Get current active mode
  AppMode getCurrentMode() {
    final modeName = _layoutBox.get(_currentModeKey) as String?;
    if (modeName == null) return AppMode.nutrition;
    
    return AppMode.values.firstWhere(
      (m) => m.name == modeName,
      orElse: () => AppMode.nutrition,
    );
  }

  /// Check if layout exists in cache
  bool hasCachedLayout(String layoutId) {
    return _layoutBox.containsKey(layoutId);
  }

  /// Clear all cached layouts
  Future<void> clearCache() async {
    await _layoutBox.clear();
    debugPrint('[LayoutCacheService] Cache cleared');
  }

  /// Remove specific layout from cache
  Future<void> removeLayout(String layoutId) async {
    await _layoutBox.delete(layoutId);
    debugPrint('[LayoutCacheService] Removed layout: $layoutId');
  }

  /// Get all cached layout IDs
  List<String> getAllCachedLayoutIds() {
    return _layoutBox.keys
        .where((key) => key is String && !key.toString().startsWith(_layoutVersionKey))
        .map((key) => key.toString())
        .toList();
  }
}

// Singleton instance
final layoutCacheService = LayoutCacheService();
