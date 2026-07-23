import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:akeli/providers/color_set_provider.dart';
import 'package:akeli/shared/widgets/color_set_modal.dart';

void main() {
  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('color_set_provider_test');
    Hive.init(tempDir.path);
    await Hive.openBox('mode_state');
  });

  tearDown(() async {
    await Hive.deleteFromDisk();
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  test('defaults to the first preset (Teal & Amber / Nutrition) when nothing is persisted', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final preset = container.read(colorSetProvider);
    expect(preset.id, equals(ColorSetModal.presets.first.id));
  });

  test('selectPreset persists the chosen preset id to Hive and updates state', () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final rosePreset = ColorSetModal.presets.firstWhere((p) => p.id == 'rose_beauty');

    await container.read(colorSetProvider.notifier).selectPreset(rosePreset);

    expect(container.read(colorSetProvider).id, equals('rose_beauty'));

    final box = Hive.box('mode_state');
    expect(box.get('selected_color_set_id'), equals('rose_beauty'));
  });

  test('a fresh provider instance loads the previously persisted preset from Hive (round-trip)', () async {
    final box = Hive.box('mode_state');
    await box.put('selected_color_set_id', 'sage_botanique');

    final container = ProviderContainer();
    addTearDown(container.dispose);

    final preset = container.read(colorSetProvider);
    expect(preset.id, equals('sage_botanique'));
  });
}
