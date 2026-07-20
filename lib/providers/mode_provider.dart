import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:akeli/core/logger.dart';

final _logger = appLogger;

// ---------------------------------------------------------------------------
// AppMode enum
// ---------------------------------------------------------------------------

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

// ---------------------------------------------------------------------------
// RemoteLayout model
// ---------------------------------------------------------------------------

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

// ---------------------------------------------------------------------------
// ModeNotifier — persists mode in Hive box 'mode_state'
// ---------------------------------------------------------------------------

final currentModeProvider = NotifierProvider<ModeNotifier, AppMode>(ModeNotifier.new);

class ModeNotifier extends Notifier<AppMode> {
  static const _boxName = 'mode_state';
  static const _modeKey = 'current_mode';

  @override
  AppMode build() {
    _logger.provider('ModeNotifier build()');
    ref.onDispose(() => _logger.provider('ModeNotifier disposed'));

    try {
      if (Hive.isBoxOpen(_boxName)) {
        final box = Hive.box(_boxName);
        final saved = box.get(_modeKey, defaultValue: 'nutrition') as String?;
        final mode = AppMode.values.firstWhere(
          (m) => m.name == saved,
          orElse: () => AppMode.nutrition,
        );
        _logger.provider('ModeNotifier → initial: ${mode.name} (loaded from cache)');
        return mode;
      }
    } catch (e) {
      _logger.provider('ModeNotifier → box read error: $e');
    }
    return AppMode.nutrition;
  }

  Future<void> switchMode(AppMode newMode) async {
    if (state == newMode) return;
    _logger.provider('ModeNotifier → switching: ${state.name} → ${newMode.name}');
    try {
      final box = Hive.isBoxOpen(_boxName) ? Hive.box(_boxName) : await Hive.openBox(_boxName);
      await box.put(_modeKey, newMode.name);
    } catch (e) {
      _logger.provider('ModeNotifier switchMode error: $e');
    }
    state = newMode;
    _logger.provider('ModeNotifier → ${newMode.name}');
  }

  AppMode get currentMode => state;
}

// ---------------------------------------------------------------------------
// SDUI layout loading state
// ---------------------------------------------------------------------------

enum LayoutLoadingState {
  notLoaded,
  loading,
  loaded,
  error,
}

final layoutStateProvider =
    StateNotifierProvider<LayoutStateNotifier, Map<String, LayoutLoadingState>>(
  (_) => LayoutStateNotifier(),
);

class LayoutStateNotifier extends StateNotifier<Map<String, LayoutLoadingState>> {
  LayoutStateNotifier() : super({});

  void setLoading(String mode) {
    _logger.provider('LayoutStateNotifier → loading | mode: $mode');
    state = {...state, mode: LayoutLoadingState.loading};
  }

  void setLoaded(String mode) {
    _logger.provider('LayoutStateNotifier → loaded | mode: $mode');
    state = {...state, mode: LayoutLoadingState.loaded};
  }

  void setError(String mode) {
    _logger.provider('LayoutStateNotifier → error | mode: $mode');
    state = {...state, mode: LayoutLoadingState.error};
  }

  LayoutLoadingState getState(String mode) =>
      state[mode] ?? LayoutLoadingState.notLoaded;

  bool isLoaded(String mode) => state[mode] == LayoutLoadingState.loaded;
  bool isLoading(String mode) => state[mode] == LayoutLoadingState.loading;
  bool hasError(String mode) => state[mode] == LayoutLoadingState.error;

  void clear(String mode) {
    final updated = {...state}..remove(mode);
    state = updated;
  }
}

// ---------------------------------------------------------------------------
// SDUI layout data storage
// ---------------------------------------------------------------------------

final layoutDataProvider =
    StateNotifierProvider<LayoutDataNotifier, Map<String, Map<String, dynamic>>>(
  (_) => LayoutDataNotifier(),
);

class LayoutDataNotifier extends StateNotifier<Map<String, Map<String, dynamic>>> {
  LayoutDataNotifier() : super({});

  void setLayout(String mode, Map<String, dynamic> layoutData) {
    _logger.provider('LayoutDataNotifier → setLayout | mode: $mode');
    state = {...state, mode: layoutData};
  }

  Map<String, dynamic>? getLayout(String mode) => state[mode];

  void clearLayout(String mode) {
    final updated = {...state}..remove(mode);
    state = updated;
  }

  void clearAll() {
    state = {};
  }
}

// ---------------------------------------------------------------------------
// User culture preferences
// ---------------------------------------------------------------------------

final userCulturePreferencesProvider = StateProvider<List<String>>((_) => []);
