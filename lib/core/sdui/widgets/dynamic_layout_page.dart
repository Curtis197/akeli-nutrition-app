import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/layout_cache_service.dart';
import '../services/layout_fetch_service.dart';
import '../providers/mode_provider.dart';
import '../widgets/widget_factory.dart';

/// A dynamic page that renders its UI based on remote layout configurations
/// 
/// This is the core SDUI page that:
/// - Fetches layout from cache or remote based on current mode
/// - Renders components dynamically using WidgetFactory
/// - Handles loading, error, and offline states gracefully
/// - Supports cultural realignment through layout metadata
class DynamicLayoutPage extends ConsumerStatefulWidget {
  final String mode;
  
  const DynamicLayoutPage({
    Key? key,
    required this.mode,
  }) : super(key: key);

  @override
  ConsumerState<DynamicLayoutPage> createState() => _DynamicLayoutPageState();
}

class _DynamicLayoutPageState extends ConsumerState<DynamicLayoutPage> {
  final LayoutFetchService _fetchService = LayoutFetchService();
  final LayoutCacheService _cacheService = LayoutCacheService();
  
  bool _isLoading = false;
  bool _hasError = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadLayout();
  }

  @override
  void didUpdateWidget(DynamicLayoutPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.mode != widget.mode) {
      _loadLayout();
    }
  }

  Future<void> _loadLayout() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
      _errorMessage = null;
    });

    try {
      ref.read(layoutStateProvider.notifier).setLoading(widget.mode);

      // Get user culture preferences
      final cultureTags = ref.read(userCulturePreferencesProvider);

      // Fetch layout (cache-first strategy)
      final layoutData = await _fetchService.fetchLayout(
        mode: widget.mode,
        cultureTags: cultureTags.isNotEmpty ? cultureTags : null,
      );

      if (layoutData != null) {
        // Store layout data in provider
        ref.read(layoutDataProvider.notifier).setLayout(widget.mode, layoutData);
        ref.read(layoutStateProvider.notifier).setLoaded(widget.mode);
        
        setState(() {
          _isLoading = false;
        });
      } else {
        throw Exception('No layout available for mode: ${widget.mode}');
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _hasError = true;
        _errorMessage = e.toString();
      });
      
      ref.read(layoutStateProvider.notifier).setError(widget.mode);
      
      debugPrint('❌ Error loading layout for ${widget.mode}: $e');
    }
  }

  void _retry() {
    _loadLayout();
  }

  @override
  Widget build(BuildContext context) {
    final layoutState = ref.watch(layoutStateProvider)[widget.mode] ?? LayoutLoadingState.notLoaded;
    final layoutData = ref.watch(layoutDataProvider)[widget.mode];

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _loadLayout,
        child: CustomScrollView(
          slivers: [
            // App Bar with mode indicator
            SliverAppBar(
              floating: true,
              title: Text(
                widget.mode.toUpperCase(),
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              actions: [
                IconButton(
                  icon: const Icon(Icons.refresh),
                  onPressed: _isLoading ? null : _retry,
                  tooltip: 'Refresh layout',
                ),
              ],
            ),

            // Content based on state
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
      ),
    );
  }

  Widget _buildLayoutContent(Map<String, dynamic> layoutData) {
    final layout = layoutData['layout'] as Map<String, dynamic>?;
    final components = layout?['components'] as List<dynamic>? ?? [];

    if (components.isEmpty) {
      return SliverFillRemaining(
        child: _buildEmptyView(),
      );
    }

    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          final component = components[index] as Map<String, dynamic>;
          return WidgetFactory.buildComponent(component, widget.mode);
        },
        childCount: components.length,
      ),
    );
  }

  Widget _buildErrorView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.cloud_off_outlined,
              size: 64,
              color: Colors.grey,
            ),
            const SizedBox(height: 16),
            const Text(
              'Unable to load layout',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage ?? 'Unknown error',
              style: const TextStyle(color: Colors.grey),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _retry,
              icon: const Icon(Icons.refresh),
              label: const Text('Try Again'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.layout,
              size: 64,
              color: Colors.grey,
            ),
            const SizedBox(height: 16),
            Text(
              'No content for ${widget.mode} mode',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Check back later for updates',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}
