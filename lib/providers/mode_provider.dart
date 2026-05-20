import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/sdui/layout_cache_service.dart';

/// Provider for managing current app mode state
final currentModeProvider = StateNotifierProvider<ModeNotifier, AppMode>((ref) {
  return ModeNotifier();
});

class ModeNotifier extends StateNotifier<AppMode> {
  ModeNotifier() : super(AppMode.nutrition) {
    _loadSavedMode();
  }

  Future<void> _loadSavedMode() async {
    final savedMode = layoutCacheService.getCurrentMode();
    state = savedMode;
    debugPrint('[ModeNotifier] Loaded saved mode: ${savedMode.name}');
  }

  /// Switch to a different mode
  Future<void> switchMode(AppMode newMode) async {
    if (state == newMode) return;
    
    debugPrint('[ModeNotifier] Switching mode: ${state.name} -> ${newMode.name}');
    await layoutCacheService.setCurrentMode(newMode);
    state = newMode;
  }

  /// Get current mode synchronously
  AppMode get currentMode => state;
}

/// Provider for fetching and caching remote layouts
final remoteLayoutProvider = AsyncNotifierProvider<RemoteLayoutNotifier, RemoteLayout?>((ref) {
  return RemoteLayoutNotifier();
});

class RemoteLayoutNotifier extends AsyncNotifier<RemoteLayout?> {
  @override
  Future<RemoteLayout?> build() async {
    // Initial load from cache
    final mode = ref.read(currentModeProvider);
    return _loadFromCache(mode);
  }

  /// Load layout from cache
  Future<RemoteLayout?> _loadFromCache(AppMode mode) async {
    // For now, return null - will be implemented with actual layout IDs
    // In production, you'd fetch the layout ID for this mode from config
    return null;
  }

  /// Fetch layout from remote (Supabase)
  Future<void> fetchLayout(String layoutId, AppMode mode) async {
    state = const AsyncValue.loading();
    
    try {
      // TODO: Implement Supabase fetch
      // final response = await supabaseClient
      //     .from('remote_layouts')
      //     .select()
      //     .eq('id', layoutId)
      //     .single();
      
      // For now, simulate network delay
      await Future.delayed(const Duration(milliseconds: 500));
      
      // Placeholder - replace with actual fetch logic
      final layout = RemoteLayout(
        id: layoutId,
        mode: mode,
        version: '1.0.0',
        layoutJson: {'components': []},
        fetchedAt: DateTime.now(),
      );
      
      // Cache the layout
      await layoutCacheService.cacheLayout(layout);
      
      state = AsyncValue.data(layout);
      debugPrint('[RemoteLayoutNotifier] Fetched and cached layout: $layoutId');
    } catch (e, stackTrace) {
      debugPrint('[RemoteLayoutNotifier] Error fetching layout: $e');
      debugPrint('$stackTrace');
      state = AsyncValue.error(e, stackTrace);
    }
  }

  /// Load from cache or fetch if not available
  Future<void> loadLayout(String layoutId, AppMode mode) async {
    final cached = layoutCacheService.getCachedLayout(layoutId);
    
    if (cached != null) {
      state = AsyncValue.data(cached);
      debugPrint('[RemoteLayoutNotifier] Loaded from cache: $layoutId');
      return;
    }
    
    // Not in cache, fetch from remote
    await fetchLayout(layoutId, mode);
  }

  /// Invalidate cache for a specific layout
  Future<void> invalidateLayout(String layoutId) async {
    await layoutCacheService.removeLayout(layoutId);
    ref.invalidateSelf();
  }
}

/// Provider for SDUI widget factory
final sduiWidgetFactoryProvider = Provider<SDUIWidgetFactory>((ref) {
  return SDUIWidgetFactory();
});

/// Factory for creating widgets from remote layout JSON
class SDUIWidgetFactory {
  // This will be implemented in the next file
  // Maps component types to widget builders
}
