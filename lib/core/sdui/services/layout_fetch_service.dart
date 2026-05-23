import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:akeli/core/logger.dart';
import 'layout_cache_service.dart';

final _logger = appLogger;

/// Service responsible for fetching SDUI layouts from Supabase.
///
/// Implements cache-first strategy with automatic fallback to bundled layouts.
class LayoutFetchService {
  static final LayoutFetchService _instance = LayoutFetchService._internal();
  factory LayoutFetchService() => _instance;
  LayoutFetchService._internal();

  final SupabaseClient _supabase = Supabase.instance.client;
  final LayoutCacheService _cache = LayoutCacheService();

  Future<Map<String, dynamic>?> fetchLayout({
    required String mode,
    List<String>? cultureTags,
    bool forceRefresh = false,
  }) async {
    if (!forceRefresh && _cache.hasLayout(mode) && !_cache.isLayoutStale(mode)) {
      _logger.db('AFTER | cache op: fetchLayout | mode: $mode | source: cache');
      return _cache.getLayout(mode);
    }

    try {
      _logger.db('BEFORE | table: layouts | op: SELECT | mode: $mode');

      var filterQuery = _supabase
          .from('layouts')
          .select()
          .eq('mode', mode)
          .eq('is_active', true);

      if (cultureTags != null && cultureTags.isNotEmpty) {
        filterQuery = filterQuery.contains('culture_tags', [cultureTags.first]);
      }

      final response = await filterQuery
          .order('version', ascending: false)
          .limit(1)
          .single();

      _logger.db('AFTER | table: layouts | rows: 1 | mode: $mode');

      // DB stores layout_json as a top-level JSON array; wrap it so
      // _buildLayoutContent can find layoutData['layout']['components'].
      final rawJson = response['layout_json'];
      final Map<String, dynamic> layoutMap;
      if (rawJson is List) {
        layoutMap = {'components': rawJson};
      } else if (rawJson is Map<String, dynamic>) {
        layoutMap = rawJson;
      } else {
        layoutMap = {'components': <dynamic>[]};
      }

      final layoutData = {
        'layout_id': response['id'] as String,
        'mode': response['mode'] as String,
        'version': response['version'] as String?,
        'layout': layoutMap,
        'culture_tags': response['culture_tags'] as List<dynamic>?,
      };

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

      _logger.db('AFTER | cache op: cacheLayout | layoutId: ${layoutData['layout_id']} | mode: $mode');
      return layoutData;
    } catch (e, st) {
      _logger.db(
        'ERROR | table: layouts | mode: $mode | $e',
        error: e,
        stackTrace: st,
      );

      if (_cache.hasLayout(mode)) {
        _logger.db('AFTER | cache op: fetchLayout | mode: $mode | source: stale-cache fallback');
        return _cache.getLayout(mode);
      }

      _logger.db('AFTER | cache op: fetchLayout | mode: $mode | source: bundled fallback');
      return _getBundledFallbackLayout(mode);
    }
  }

  Map<String, dynamic>? _getBundledFallbackLayout(String mode) {
    switch (mode) {
      case 'nutrition':
        return {
          'layout_id': 'bundled_nutrition_v1',
          'mode': 'nutrition',
          'version': '1.0.0',
          'layout': {
            'components': [
              {'type': 'hero_banner', 'config': {'title': 'Nutrition', 'subtitle': 'Track your meals'}},
              {'type': 'weight_tracker', 'config': {'title': 'Weight Progress'}},
              {'type': 'calories_graph', 'config': {'title': 'Daily Calories'}},
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
              {'type': 'hero_banner', 'config': {'title': 'Beauty', 'subtitle': 'Skin & Hair Care'}},
              {'type': 'routine_grid', 'config': {'title': 'Your Routines'}},
              {'type': 'product_tracker', 'config': {'title': 'Products'}},
            ],
          },
          'culture_tags': ['default'],
        };
      default:
        return null;
    }
  }

  Future<void> prefetchLayouts(List<String> modes) async {
    for (final mode in modes) {
      _logger.db('BEFORE | cache op: prefetchLayouts | mode: $mode');
      fetchLayout(mode: mode).catchError((Object e) {
        _logger.db('ERROR | cache op: prefetchLayouts | mode: $mode | $e');
        return null;
      });
    }
  }

  Future<void> invalidateCache(String mode) async {
    _logger.db('BEFORE | cache op: invalidateCache | mode: $mode');
    await _cache.clearLayout(mode);
    _logger.db('AFTER | cache op: invalidateCache | mode: $mode');
  }

  Future<bool> hasUpdateAvailable(String mode, String currentVersion) async {
    try {
      _logger.db('BEFORE | table: layouts | op: SELECT version | mode: $mode');
      final response = await _supabase
          .from('layouts')
          .select('version')
          .eq('mode', mode)
          .eq('is_active', true)
          .order('version', ascending: false)
          .limit(1)
          .single();

      final latestVersion = response['version'] as String;
      _logger.db('AFTER | table: layouts | rows: 1 | latestVersion: $latestVersion');
      return _compareVersions(latestVersion, currentVersion) > 0;
    } catch (e, st) {
      _logger.db('ERROR | table: layouts | op: hasUpdateAvailable | $e', error: e, stackTrace: st);
      return false;
    }
  }

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
