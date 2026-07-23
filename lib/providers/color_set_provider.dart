import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../core/logger.dart';
import '../shared/widgets/color_set_modal.dart';

final _logger = appLogger;

/// Persists the user's selected [ColorSetPreset] in the same Hive box
/// ('mode_state') that `ModeNotifier` (lib/providers/mode_provider.dart)
/// already opens in lib/main.dart — no new box is created.
final colorSetProvider = NotifierProvider<ColorSetNotifier, ColorSetPreset>(ColorSetNotifier.new);

class ColorSetNotifier extends Notifier<ColorSetPreset> {
  static const _boxName = 'mode_state';
  static const _colorSetKey = 'selected_color_set_id';

  @override
  ColorSetPreset build() {
    _logger.provider('ColorSetNotifier build()');
    ref.onDispose(() => _logger.provider('ColorSetNotifier disposed'));

    try {
      if (Hive.isBoxOpen(_boxName)) {
        final box = Hive.box(_boxName);
        final savedId = box.get(_colorSetKey) as String?;
        if (savedId != null) {
          final preset = ColorSetModal.presets.firstWhere(
            (p) => p.id == savedId,
            orElse: () => ColorSetModal.presets.first,
          );
          _logger.provider('ColorSetNotifier → initial: ${preset.id} (loaded from cache)');
          return preset;
        }
      }
    } catch (e) {
      _logger.provider('ColorSetNotifier → box read error: $e');
    }
    return ColorSetModal.presets.first;
  }

  Future<void> selectPreset(ColorSetPreset preset) async {
    _logger.provider('ColorSetNotifier → selecting: ${preset.id}');
    try {
      final box = Hive.isBoxOpen(_boxName) ? Hive.box(_boxName) : await Hive.openBox(_boxName);
      await box.put(_colorSetKey, preset.id);
    } catch (e) {
      _logger.provider('ColorSetNotifier selectPreset error: $e');
    }
    state = preset;
    _logger.provider('ColorSetNotifier → ${preset.id}');
  }
}
