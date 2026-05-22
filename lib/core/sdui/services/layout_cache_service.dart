import 'package:hive_flutter/hive_flutter.dart';
import 'package:akeli/core/logger.dart';

final _logger = appLogger;

const String layoutsBoxName = 'layouts';
const String modesBoxName = 'modes';

/// Service responsible for caching and retrieving SDUI layouts using Hive.
class LayoutCacheService {
  static final LayoutCacheService _instance = LayoutCacheService._internal();
  factory LayoutCacheService() => _instance;
  LayoutCacheService._internal();

  Box<dynamic>? _layoutsBox;
  Box<dynamic>? _modesBox;

  Future<void> initialize() async {
    _logger.db('BEFORE | cache op: LayoutCacheService.initialize');
    await Hive.initFlutter();
    _layoutsBox = await Hive.openBox(layoutsBoxName);
    _modesBox = await Hive.openBox(modesBoxName);
    _logger.db('AFTER | cache op: LayoutCacheService.initialize | boxes: $layoutsBoxName, $modesBoxName');
  }

  Future<void> cacheLayout({
    required String mode,
    required String layoutId,
    required Map<String, dynamic> layoutJson,
    Map<String, dynamic>? metadata,
  }) async {
    assert(_layoutsBox != null, 'LayoutCacheService not initialized');
    final layoutKey = '$mode:$layoutId';
    _logger.db('BEFORE | cache op: cacheLayout | key: $layoutKey');

    await _layoutsBox!.put(layoutKey, {
      'layout_id': layoutId,
      'mode': mode,
      'layout': layoutJson,
      'cached_at': DateTime.now().toIso8601String(),
      if (metadata != null) ...metadata,
    });
    await _modesBox!.put('${mode}_current_layout', layoutId);

    _logger.db('AFTER | cache op: cacheLayout | key: $layoutKey');
  }

  Map<String, dynamic>? getLayout(String mode) {
    assert(_layoutsBox != null, 'LayoutCacheService not initialized');
    final currentLayoutId = _modesBox!.get('${mode}_current_layout') as String?;
    if (currentLayoutId == null) {
      _logger.db('AFTER | cache op: getLayout | mode: $mode | rows: 0');
      return null;
    }
    final layoutKey = '$mode:$currentLayoutId';
    final cachedData = _layoutsBox!.get(layoutKey) as Map<dynamic, dynamic>?;
    _logger.db('AFTER | cache op: getLayout | mode: $mode | rows: ${cachedData != null ? 1 : 0}');
    if (cachedData == null) return null;
    return Map<String, dynamic>.from(cachedData);
  }

  bool hasLayout(String mode) {
    assert(_layoutsBox != null, 'LayoutCacheService not initialized');
    return _modesBox!.containsKey('${mode}_current_layout');
  }

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

  Future<void> clearLayout(String mode) async {
    final currentLayoutId = _modesBox!.get('${mode}_current_layout') as String?;
    if (currentLayoutId != null) {
      _logger.db('BEFORE | cache op: clearLayout | mode: $mode');
      await _layoutsBox!.delete('$mode:$currentLayoutId');
      await _modesBox!.delete('${mode}_current_layout');
      _logger.db('AFTER | cache op: clearLayout | mode: $mode');
    }
  }

  Future<void> clearAll() async {
    _logger.db('BEFORE | cache op: clearAll');
    await _layoutsBox?.clear();
    await _modesBox?.clear();
    _logger.db('AFTER | cache op: clearAll');
  }

  List<String> getCachedModes() {
    final modes = <String>[];
    for (final key in _modesBox!.keys) {
      if (key.endsWith('_current_layout')) {
        modes.add(key.replaceAll('_current_layout', ''));
      }
    }
    return modes;
  }

  bool isLayoutStale(String mode, {int maxAgeHours = 24}) {
    final metadata = getLayoutMetadata(mode);
    if (metadata == null || metadata['cached_at'] == null) return true;
    final cachedAt = DateTime.tryParse(metadata['cached_at'] as String);
    if (cachedAt == null) return true;
    return DateTime.now().difference(cachedAt).inHours > maxAgeHours;
  }

  Future<void> close() async {
    await _layoutsBox?.close();
    await _modesBox?.close();
  }
}
