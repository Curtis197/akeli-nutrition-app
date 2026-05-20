import 'package:supabase_flutter/supabase_flutter.dart';
import 'layout_cache_service.dart';

/// Service responsible for fetching SDUI layouts from Supabase
/// 
/// Implements:
/// - Remote layout fetching with version control
/// - Automatic cache invalidation
/// - Fallback to bundled layouts on error
/// - Culture-aware layout selection
class LayoutFetchService {
  static final LayoutFetchService _instance = LayoutFetchService._internal();
  factory LayoutFetchService() => _instance;
  LayoutFetchService._internal();

  final SupabaseClient _supabase = Supabase.instance.client;
  final LayoutCacheService _cache = LayoutCacheService();

  /// Fetch a layout for a specific mode
  /// 
  /// [mode] - The mode identifier (e.g., 'nutrition', 'beauty')
  /// [cultureTags] - Optional culture tags for personalized layout
  /// [forceRefresh] - If true, bypass cache and fetch from remote
  /// 
  /// Returns the layout as a Map, or null if not found
  Future<Map<String, dynamic>?> fetchLayout({
    required String mode,
    List<String>? cultureTags,
    bool forceRefresh = false,
  }) async {
    // Check cache first unless force refresh
    if (!forceRefresh && _cache.hasLayout(mode) && !_cache.isLayoutStale(mode)) {
      print('📦 Using cached layout for mode: $mode');
      return _cache.getLayout(mode);
    }

    try {
      print('🌐 Fetching layout from remote for mode: $mode');
      
      // Build query parameters
      var query = _supabase
          .from('layouts')
          .select()
          .eq('mode', mode)
          .eq('is_active', true)
          .order('version', ascending: false)
          .limit(1);

      // Add culture filtering if tags provided
      if (cultureTags != null && cultureTags.isNotEmpty) {
        // Filter by culture tags (array overlap)
        query = query.contains('culture_tags', cultureTags.first);
      }

      final response = await query.single();

      if (response == null) {
        print('⚠️ No layout found for mode: $mode');
        return null;
      }

      // Parse the layout JSON
      final layoutData = {
        'layout_id': response['id'] as String,
        'mode': response['mode'] as String,
        'version': response['version'] as String?,
        'layout': response['layout_json'] as Map<String, dynamic>,
        'culture_tags': response['culture_tags'] as List<dynamic>?,
        'metadata': response['metadata'] as Map<String, dynamic>?,
      };

      // Cache the layout
      await _cache.cacheLayout(
        mode: mode,
        layoutId: layoutData['layout_id'] as String,
        layoutJson: layoutData['layout'] as Map<String, dynamic>,
        metadata: {
          'version': layoutData['version'],
          'culture_tags': layoutData['culture_tags'],
          'fetched_at': DateTime.now().toIso8601String(),
        },
      );

      print('✅ Successfully fetched and cached layout ${layoutData['layout_id']} for mode $mode');
      return layoutData;
    } catch (e) {
      print('❌ Error fetching layout for mode $mode: $e');
      
      // Return cached layout as fallback if available
      if (_cache.hasLayout(mode)) {
        print('🔄 Falling back to cached layout for mode: $mode');
        return _cache.getLayout(mode);
      }
      
      // Return bundled fallback layout
      return _getBundledFallbackLayout(mode);
    }
  }

  /// Get bundled fallback layout for offline/error scenarios
  Map<String, dynamic>? _getBundledFallbackLayout(String mode) {
    // These would be bundled in your app assets
    // For now, return minimal default layouts
    switch (mode) {
      case 'nutrition':
        return {
          'layout_id': 'bundled_nutrition_v1',
          'mode': 'nutrition',
          'version': '1.0.0',
          'layout': {
            'components': [
              {
                'type': 'hero_banner',
                'config': {'title': 'Nutrition', 'subtitle': 'Track your meals'},
              },
              {
                'type': 'weight_tracker',
                'config': {'title': 'Weight Progress'},
              },
              {
                'type': 'calories_graph',
                'config': {'title': 'Daily Calories'},
              },
            ],
          },
          'culture_tags': ['default'],
        };
      
      case 'beauty':
        return {
          'layout_id': 'bundled_beauty_v1',
          'mode': 'beauty',
          'version': '1.0.0',
          'layout': {
            'components': [
              {
                'type': 'hero_banner',
                'config': {'title': 'Beauty', 'subtitle': 'Skin & Hair Care'},
              },
              {
                'type': 'routine_grid',
                'config': {'title': 'Your Routines'},
              },
              {
                'type': 'product_tracker',
                'config': {'title': 'Products'},
              },
            ],
          },
          'culture_tags': ['default'],
        };
      
      default:
        return null;
    }
  }

  /// Prefetch layouts for multiple modes (background loading)
  Future<void> prefetchLayouts(List<String> modes) async {
    for (final mode in modes) {
      // Fetch without blocking UI
      fetchLayout(mode: mode).catchError((e) {
        print('⚠️ Prefetch failed for mode $mode: $e');
      });
    }
  }

  /// Invalidate cache for a specific mode
  Future<void> invalidateCache(String mode) async {
    await _cache.clearLayout(mode);
    print('🗑️ Invalidated cache for mode: $mode');
  }

  /// Check if a layout update is available
  Future<bool> hasUpdateAvailable(String mode, String currentVersion) async {
    try {
      final response = await _supabase
          .from('layouts')
          .select('version')
          .eq('mode', mode)
          .eq('is_active', true)
          .order('version', ascending: false)
          .limit(1)
          .single();

      if (response != null) {
        final latestVersion = response['version'] as String;
        return _compareVersions(latestVersion, currentVersion) > 0;
      }
      
      return false;
    } catch (e) {
      print('❌ Error checking for updates: $e');
      return false;
    }
  }

  /// Compare two version strings
  /// Returns: 1 if v1 > v2, -1 if v1 < v2, 0 if equal
  int _compareVersions(String v1, String v2) {
    final parts1 = v1.split('.').map(int.parse).toList();
    final parts2 = v2.split('.').map(int.parse).toList();
    
    for (int i = 0; i < 3; i++) {
      final p1 = i < parts1.length ? parts1[i] : 0;
      final p2 = i < parts2.length ? parts2[i] : 0;
      
      if (p1 > p2) return 1;
      if (p1 < p2) return -1;
    }
    
    return 0;
  }
}
