import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../sdui/layout_cache_service.dart';

/// Service for fetching remote layouts from Supabase
class LayoutFetchService {
  final SupabaseClient _supabase;

  LayoutFetchService(this._supabase);

  /// Fetch layout by ID from Supabase
  Future<RemoteLayout?> fetchLayout(String layoutId) async {
    try {
      debugPrint('[LayoutFetchService] Fetching layout: $layoutId');
      
      final response = await _supabase
          .from('remote_layouts')
          .select()
          .eq('id', layoutId)
          .maybeSingle();

      if (response == null) {
        debugPrint('[LayoutFetchService] Layout not found: $layoutId');
        return null;
      }

      final layout = RemoteLayout.fromJson(response);
      debugPrint(
        '[LayoutFetchService] Successfully fetched layout: ${layout.id} (mode: ${layout.mode}, version: ${layout.version})',
      );

      return layout;
    } catch (e, stackTrace) {
      debugPrint('[LayoutFetchService] Error fetching layout: $e');
      debugPrint('$stackTrace');
      rethrow;
    }
  }

  /// Fetch latest layout for a specific mode
  Future<RemoteLayout?> fetchLatestLayoutForMode(AppMode mode, {String? cultureTag}) async {
    try {
      debugPrint('[LayoutFetchService] Fetching latest layout for mode: ${mode.name}');
      
      var query = _supabase
          .from('remote_layouts')
          .select()
          .eq('mode', mode.name)
          .eq('is_active', true)
          .order('version', ascending: false)
          .limit(1);

      // Add culture tag filter if provided
      if (cultureTag != null) {
        query = query.eq('culture_tag', cultureTag);
      }

      final response = await query.maybeSingle();

      if (response == null) {
        debugPrint('[LayoutFetchService] No layout found for mode: ${mode.name}');
        return null;
      }

      final layout = RemoteLayout.fromJson(response);
      debugPrint(
        '[LayoutFetchService] Found layout: ${layout.id} (version: ${layout.version})',
      );

      return layout;
    } catch (e, stackTrace) {
      debugPrint('[LayoutFetchService] Error fetching layout for mode: $e');
      debugPrint('$stackTrace');
      rethrow;
    }
  }

  /// Check if newer version is available
  Future<bool> hasNewerVersion(AppMode mode, String currentVersion) async {
    try {
      final latest = await fetchLatestLayoutForMode(mode);
      if (latest == null) return false;
      
      // Simple semver comparison (production should use proper semver package)
      return latest.version.compareTo(currentVersion) > 0;
    } catch (e) {
      debugPrint('[LayoutFetchService] Error checking version: $e');
      return false;
    }
  }

  /// Prefetch layouts for all modes (for faster switching)
  Future<Map<AppMode, RemoteLayout>> prefetchAllLayouts({String? cultureTag}) async {
    final results = <AppMode, RemoteLayout>{};
    
    for (final mode in AppMode.values) {
      try {
        final layout = await fetchLatestLayoutForMode(mode, cultureTag: cultureTag);
        if (layout != null) {
          results[mode] = layout;
          // Cache immediately
          await layoutCacheService.cacheLayout(layout);
        }
      } catch (e) {
        debugPrint('[LayoutFetchService] Failed to prefetch layout for ${mode.name}: $e');
      }
    }
    
    debugPrint('[LayoutFetchService] Prefetched ${results.length} layouts');
    return results;
  }
}
