import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Provider for managing the current active mode (nutrition, beauty, etc.)
final currentModeProvider = StateNotifierProvider<CurrentModeNotifier, String>((ref) {
  return CurrentModeNotifier();
});

/// Notifier for managing mode state
class CurrentModeNotifier extends StateNotifier<String> {
  CurrentModeNotifier() : super('nutrition'); // Default mode

  /// Switch to a different mode
  void switchTo(String mode) {
    if (state != mode) {
      state = mode;
      debugPrint('🔄 Switched to mode: $mode');
    }
  }

  /// Get the current mode
  String get currentMode => state;

  /// Check if a specific mode is active
  bool isMode(String mode) => state == mode;

  /// Reset to default mode
  void reset() {
    state = 'nutrition';
  }
}

/// Provider for tracking layout loading state per mode
final layoutStateProvider = StateNotifierProvider<LayoutStateNotifier, Map<String, LayoutLoadingState>>((ref) {
  return LayoutStateNotifier();
});

/// Loading states for layouts
enum LayoutLoadingState {
  notLoaded,
  loading,
  loaded,
  error,
}

/// Notifier for managing layout loading states
class LayoutStateNotifier extends StateNotifier<Map<String, LayoutLoadingState>> {
  LayoutStateNotifier() : super({});

  /// Set loading state for a mode
  void setLoading(String mode) {
    state = {...state, mode: LayoutLoadingState.loading};
  }

  /// Set loaded state for a mode
  void setLoaded(String mode) {
    state = {...state, mode: LayoutLoadingState.loaded};
  }

  /// Set error state for a mode
  void setError(String mode) {
    state = {...state, mode: LayoutLoadingState.error};
  }

  /// Get state for a mode
  LayoutLoadingState getState(String mode) {
    return state[mode] ?? LayoutLoadingState.notLoaded;
  }

  /// Check if a mode is loaded
  bool isLoaded(String mode) {
    return state[mode] == LayoutLoadingState.loaded;
  }

  /// Check if a mode is loading
  bool isLoading(String mode) {
    return state[mode] == LayoutLoadingState.loading;
  }

  /// Check if a mode has error
  bool hasError(String mode) {
    return state[mode] == LayoutLoadingState.error;
  }

  /// Clear state for a mode
  void clear(String mode) {
    final newState = {...state};
    newState.remove(mode);
    state = newState;
  }
}

/// Provider for storing the current layout data per mode
final layoutDataProvider = StateNotifierProvider<LayoutDataNotifier, Map<String, Map<String, dynamic>>>((ref) {
  return LayoutDataNotifier();
});

/// Notifier for managing layout data
class LayoutDataNotifier extends StateNotifier<Map<String, Map<String, dynamic>>> {
  LayoutDataNotifier() : super({});

  /// Store layout data for a mode
  void setLayout(String mode, Map<String, dynamic> layoutData) {
    state = {...state, mode: layoutData};
  }

  /// Get layout data for a mode
  Map<String, dynamic>? getLayout(String mode) {
    return state[mode];
  }

  /// Clear layout data for a mode
  void clearLayout(String mode) {
    final newState = {...state};
    newState.remove(mode);
    state = newState;
  }

  /// Clear all layout data
  void clearAll() {
    state = {};
  }
}

/// Provider for user culture preferences
final userCulturePreferencesProvider = StateProvider<List<String>>((ref) {
  // Default empty list - will be populated from user profile
  return [];
});

/// Provider to determine if layout should be refreshed
final layoutRefreshProvider = Provider.autoFamily<bool, String>((ref, mode) {
  final layoutState = ref.watch(layoutStateProvider);
  return layoutState[mode] == LayoutLoadingState.error || 
         layoutState[mode] == LayoutLoadingState.notLoaded;
});
