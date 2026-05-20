import 'package:hive_flutter/hive_flutter.dart';

/// Box name for storing layout configurations
const String layoutsBoxName = 'layouts';

/// Box name for storing mode configurations
const String modesBoxName = 'modes';

/// Service responsible for caching and retrieving SDUI layouts
/// 
/// Uses Hive for fast key-value storage of:
/// - Layout JSON configurations per mode
/// - Mode metadata (version, last fetched, culture tags)
/// - User preferences for layout customization
class LayoutCacheService {
  static final LayoutCacheService _instance = LayoutCacheService._internal();
  factory LayoutCacheService() => _instance;
  LayoutCacheService._internal();

  Box<dynamic>? _layoutsBox;
  Box<dynamic>? _modesBox;

  /// Initialize Hive and open boxes
  Future<void> initialize() async {
    await Hive.initFlutter();
    
    // Register adapters if needed for custom types
    // await Hive.openLayoutAdapter();
    
    _layoutsBox = await Hive.openBox(layoutsBoxName);
    _modesBox = await Hive.openBox(modesBoxName);
    
    print('✅ LayoutCacheService initialized');
  }

  /// Cache a layout for a specific mode
  /// 
  /// [mode] - The mode identifier (e.g., 'nutrition', 'beauty')
  /// [layoutId] - Unique identifier for this layout version
  /// [layoutJson] - The layout configuration as a Map
  /// [metadata] - Optional metadata (version, fetchedAt, cultureTags)
  Future<void> cacheLayout({
    required String mode,
    required String layoutId,
    required Map<String, dynamic> layoutJson,
    Map<String, dynamic>? metadata,
  }) async {
    assert(_layoutsBox != null, 'LayoutCacheService not initialized');
    
    final layoutKey = '$mode:$layoutId';
    
    await _layoutsBox!.put(layoutKey, {
      'layout_id': layoutId,
      'mode': mode,
      'layout': layoutJson,
      'cached_at': DateTime.now().toIso8601String(),
      if (metadata != null) ...metadata,
    });
    
    // Update the current layout reference for this mode
    await _modesBox!.put('${mode}_current_layout', layoutId);
    
    print('📦 Cached layout $layoutId for mode $mode');
  }

  /// Retrieve a cached layout for a mode
  /// 
  /// Returns null if no layout is cached
  Map<String, dynamic>? getLayout(String mode) {
    assert(_layoutsBox != null, 'LayoutCacheService not initialized');
    
    final currentLayoutId = _modesBox!.get('${mode}_current_layout') as String?;
    if (currentLayoutId == null) return null;
    
    final layoutKey = '$mode:$currentLayoutId';
    final cachedData = _layoutsBox!.get(layoutKey) as Map<dynamic, dynamic>?;
    
    if (cachedData == null) return null;
    
    return Map<String, dynamic>.from(cachedData);
  }

  /// Check if a layout exists for a mode
  bool hasLayout(String mode) {
    assert(_layoutsBox != null, 'LayoutCacheService not initialized');
    return _modesBox!.containsKey('${mode}_current_layout');
  }

  /// Get layout metadata without the full layout
  Map<String, dynamic>? getLayoutMetadata(String mode) {
    final layout = getLayout(mode);
    if (layout == null) return null;
    
    return {
      'layout_id': layout['layout_id'],
      'mode': layout['mode'],
      'cached_at': layout['cached_at'],
      'version': layout['version'],
      'culture_tags': layout['culture_tags'],
    };
  }

  /// Clear cached layout for a specific mode
  Future<void> clearLayout(String mode) async {
    final currentLayoutId = _modesBox!.get('${mode}_current_layout') as String?;
    if (currentLayoutId != null) {
      await _layoutsBox!.delete('$mode:$currentLayoutId');
      await _modesBox!.delete('${mode}_current_layout');
      print('🗑️ Cleared layout for mode $mode');
    }
  }

  /// Clear all cached layouts
  Future<void> clearAll() async {
    await _layoutsBox?.clear();
    await _modesBox?.clear();
    print('🗑️ Cleared all layouts');
  }

  /// Get all cached modes
  List<String> getCachedModes() {
    final modes = <String>[];
    for (final key in _modesBox!.keys) {
      if (key.endsWith('_current_layout')) {
        modes.add(key.replaceAll('_current_layout', ''));
      }
    }
    return modes;
  }

  /// Check if a layout is stale (older than [maxAge] hours)
  bool isLayoutStale(String mode, {int maxAgeHours = 24}) {
    final metadata = getLayoutMetadata(mode);
    if (metadata == null || metadata['cached_at'] == null) return true;
    
    final cachedAt = DateTime.tryParse(metadata['cached_at'] as String);
    if (cachedAt == null) return true;
    
    final age = DateTime.now().difference(cachedAt);
    return age.inHours > maxAgeHours;
  }

  /// Close the cache service
  Future<void> close() async {
    await _layoutsBox?.close();
    await _modesBox?.close();
  }
}
