import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:akeli/core/logger.dart';
import '../services/layout_fetch_service.dart';
import '../../../providers/mode_provider.dart';
import '../../../l10n/app_localizations.dart';
import '../widgets/widget_factory.dart';

final _logger = appLogger;

/// A dynamic page that renders its UI based on remote layout configurations.
///
/// Fetches layout from cache or remote based on current mode, renders
/// components dynamically using WidgetFactory, and handles loading, error,
/// and offline states gracefully.
class DynamicLayoutPage extends ConsumerStatefulWidget {
  final String mode;

  const DynamicLayoutPage({
    super.key,
    required this.mode,
  });

  @override
  ConsumerState<DynamicLayoutPage> createState() => _DynamicLayoutPageState();
}

class _DynamicLayoutPageState extends ConsumerState<DynamicLayoutPage> {
  final LayoutFetchService _fetchService = LayoutFetchService();

  bool _isLoading = false;
  bool _hasError = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _logger.provider('DynamicLayoutPage initState | mode: ${widget.mode}');
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadLayout());
  }

  @override
  void didUpdateWidget(DynamicLayoutPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.mode != widget.mode) {
      _logger.provider('DynamicLayoutPage didUpdateWidget | mode changed: ${oldWidget.mode} → ${widget.mode}');
      WidgetsBinding.instance.addPostFrameCallback((_) => _loadLayout());
    }
  }

  @override
  void dispose() {
    _logger.provider('DynamicLayoutPage disposed | mode: ${widget.mode}');
    super.dispose();
  }

  Future<void> _loadLayout() async {
    if (!mounted) return;
    _logger.provider('DynamicLayoutPage → loading | mode: ${widget.mode}');
    setState(() {
      _isLoading = true;
      _hasError = false;
      _errorMessage = null;
    });

    try {
      ref.read(layoutStateProvider.notifier).setLoading(widget.mode);
      final cultureTags = ref.read(userCulturePreferencesProvider);

      _logger.db('BEFORE | table: layouts | op: SELECT | mode: ${widget.mode}');
      final layoutData = await _fetchService.fetchLayout(
        mode: widget.mode,
        cultureTags: cultureTags.isNotEmpty ? cultureTags : null,
      );
      _logger.db('AFTER | table: layouts | rows: ${layoutData != null ? 1 : 0}');

      if (!mounted) return;

      if (layoutData != null) {
        ref.read(layoutDataProvider.notifier).setLayout(widget.mode, layoutData);
        ref.read(layoutStateProvider.notifier).setLoaded(widget.mode);
        _logger.provider('DynamicLayoutPage → loaded | mode: ${widget.mode}');
        setState(() {
          _isLoading = false;
        });
      } else {
        throw Exception('No layout available for mode: ${widget.mode}');
      }
    } catch (e, st) {
      _logger.provider(
        'DynamicLayoutPage → error | mode: ${widget.mode} | $e',
        error: e,
        stackTrace: st,
      );
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _hasError = true;
        _errorMessage = e.toString();
      });
      ref.read(layoutStateProvider.notifier).setError(widget.mode);
    }
  }

  void _retry() {
    _logger.userAction('Retry tapped', screen: 'DynamicLayoutPage');
    _loadLayout();
  }

  @override
  Widget build(BuildContext context) {
    final layoutState = ref.watch(layoutStateProvider)[widget.mode] ?? LayoutLoadingState.notLoaded;
    final layoutData = ref.watch(layoutDataProvider)[widget.mode];

    // No nested Scaffold — this page lives inside MainShell's Scaffold body.
    return RefreshIndicator(
      onRefresh: _loadLayout,
      child: CustomScrollView(
        slivers: [
          if (layoutState == LayoutLoadingState.loading || _isLoading)
            const SliverFillRemaining(
              child: Center(child: CircularProgressIndicator()),
            )
          else if (layoutState == LayoutLoadingState.error || _hasError)
            SliverFillRemaining(
              child: _buildErrorView(),
            )
          else if (layoutData != null && layoutState == LayoutLoadingState.loaded)
            _buildLayoutContent(layoutData)
          else
            SliverFillRemaining(
              child: _buildEmptyView(),
            ),
        ],
      ),
    );
  }

  Widget _buildLayoutContent(Map<String, dynamic> layoutData) {
    final rawLayout = layoutData['layout'];
    final layout = rawLayout is Map ? Map<String, dynamic>.from(rawLayout) : null;
    final rawComponents = layout?['components'];
    final components = rawComponents is List ? rawComponents : <dynamic>[];

    if (components.isEmpty) {
      return SliverFillRemaining(child: _buildEmptyView());
    }

    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          final raw = components[index];
          final component = raw is Map ? Map<String, dynamic>.from(raw) : <String, dynamic>{};
          return WidgetFactory.buildComponent(component, widget.mode);
        },
        childCount: components.length,
      ),
    );
  }

  Widget _buildErrorView() {
    final l10n = AppLocalizations.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.cloud_off_outlined, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            Text(
              l10n.sduiErrorTitle,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage ?? l10n.sduiUnknownError,
              style: const TextStyle(color: Colors.grey),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _retry,
              icon: const Icon(Icons.refresh),
              label: Text(l10n.sduiRetryButton),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyView() {
    final l10n = AppLocalizations.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.view_quilt_outlined, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            Text(
              l10n.sduiEmptyTitle(widget.mode),
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              l10n.sduiEmptySubtitle,
              style: const TextStyle(color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}
