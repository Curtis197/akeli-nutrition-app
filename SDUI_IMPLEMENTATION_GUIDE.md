# SDUI Implementation Guide - AKELI Mode Switching

## Overview
This implementation enables dynamic UI switching between AKELI's 5 modes (Nutrition, Beauty, Health, Sport, Family) using Server-Driven UI (SDUI) architecture.

## Architecture Components

### 1. Core Files Created

#### `/lib/core/sdui/layout_cache_service.dart`
- **Purpose**: Local caching of remote layouts using Hive
- **Key Features**:
  - Stores layout JSON with version tracking
  - Manages current active mode
  - Provides offline-first capability
  - Fast key-value storage for instant mode switching

#### `/lib/core/sdui/widget_factory.dart`
- **Purpose**: Maps remote JSON components to Flutter widgets
- **Component Types**:
  - **Nutrition**: `weight_tracker`, `calories_graph`, `macro_card`
  - **Beauty**: `skin_care_progress`, `hair_care_routine`, `product_tracker`, `beauty_tips_grid`
  - **Generic**: `hero_banner`, `section_header`, `card_grid`, `action_button`, `stats_row`

#### `/lib/core/sdui/layout_fetch_service.dart`
- **Purpose**: Fetches layouts from Supabase
- **Key Features**:
  - Fetch by layout ID or mode
  - Culture-aware layout selection
  - Version checking for updates
  - Prefetching for performance

#### `/lib/providers/mode_provider.dart`
- **Purpose**: Riverpod state management for mode switching
- **Providers**:
  - `currentModeProvider`: Tracks active mode
  - `remoteLayoutProvider`: Manages layout fetching/caching
  - `sduiWidgetFactoryProvider`: Widget factory instance

### 2. Database Schema (Supabase)

```sql
CREATE TABLE remote_layouts (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  mode TEXT NOT NULL, -- 'nutrition', 'beauty', 'health', 'sport', 'family'
  version TEXT NOT NULL, -- Semver: '1.0.0'
  layout JSONB NOT NULL, -- The actual layout JSON
  culture_tag TEXT, -- Optional: 'west_african', 'caribbean', etc.
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  
  UNIQUE(mode, version, culture_tag)
);

CREATE INDEX idx_remote_layouts_mode ON remote_layouts(mode);
CREATE INDEX idx_remote_layouts_active ON remote_layouts(is_active);
CREATE INDEX idx_remote_layouts_culture ON remote_layouts(culture_tag);
```

### 3. Layout JSON Structure

```json
{
  "id": "layout-beauty-v1",
  "mode": "beauty",
  "version": "1.0.0",
  "culture_tag": "west_african",
  "components": [
    {
      "type": "hero_banner",
      "config": {
        "title": "Routine Naturelle",
        "subtitle": "Soins capillaires traditionnels",
        "badge": "Nouveau",
        "gradient_colors": [0xFF6750A4, 0xFFD0BCFF],
        "action_label": "Commencer"
      }
    },
    {
      "type": "skin_care_progress",
      "config": {
        "title": "Progression Soin de la Peau",
        "show_metrics": true
      }
    },
    {
      "type": "hair_care_routine",
      "config": {
        "title": "Routine Capillaire",
        "steps": [
          {
            "name": "Hydratation",
            "description": "Appliquer l'huile de baobab"
          },
          {
            "name": "Scellage",
            "description": "Fermer avec le beurre de karité"
          }
        ]
      }
    }
  ]
}
```

## Implementation Steps

### Phase 1: Foundation (Week 1)

1. **Add Dependencies** to `pubspec.yaml`:
```yaml
dependencies:
  hive_flutter: ^1.1.0
  flutter_riverpod: ^2.4.0
  supabase_flutter: ^2.0.0
```

2. **Initialize Hive** in `main.dart`:
```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  await layoutCacheService.init();
  runApp(ProviderScope(child: AkeliApp()));
}
```

3. **Create Supabase Table**: Run the SQL schema above

### Phase 2: Mode Provider Integration (Week 2)

1. **Update Main Shell** to use mode provider:
```dart
class MainShell extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentMode = ref.watch(currentModeProvider);
    
    return Scaffold(
      body: IndexedStack(
        index: currentMode.index,
        children: [
          HomePage(), // Will be SDUI-driven
          NutritionPage(),
          BeautyPage(), // New
          CommunityPage(),
          ProfilePage(),
        ],
      ),
      bottomNavigationBar: ModeSwitcherBar(),
    );
  }
}
```

2. **Create Mode Switcher Bar**:
```dart
class ModeSwitcherBar extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return BottomNavigationBar(
      currentIndex: ref.watch(currentModeProvider).index,
      onTap: (index) => ref.read(currentModeProvider.notifier).switchMode(
        AppMode.values[index],
      ),
      items: AppMode.values.map((mode) {
        return BottomNavigationBarItem(
          icon: Icon(Icons.iconsMap[mode.iconData]),
          label: mode.displayName,
        );
      }).toList(),
    );
  }
}
```

### Phase 3: SDUI-Driven Home Page (Week 3-4)

Replace hard-coded HomePage with SDUI renderer:

```dart
class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  @override
  void initState() {
    super.initState();
    _loadLayout();
  }

  Future<void> _loadLayout() async {
    final mode = ref.read(currentModeProvider);
    final layoutId = _getLayoutIdForMode(mode);
    
    await ref.read(remoteLayoutProvider.notifier).loadLayout(layoutId, mode);
  }

  @override
  Widget build(BuildContext context) {
    final layoutAsync = ref.watch(remoteLayoutProvider);
    
    return layoutAsync.when(
      loading: () => Center(child: CircularProgressIndicator()),
      error: (err, _) => ErrorWidget(err),
      data: (layout) => _buildSDUILayout(layout),
    );
  }

  Widget _buildSDUILayout(RemoteLayout? layout) {
    if (layout == null) return _buildFallbackUI();
    
    final components = layout.layoutJson['components'] as List? ?? [];
    final factory = ref.read(sduiWidgetFactoryProvider);
    
    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: components.map((component) {
          return Padding(
            padding: EdgeInsets.only(bottom: 16),
            child: factory.buildComponent(
              component as Map<String, dynamic>,
            ),
          );
        }).toList(),
      ),
    );
  }

  String _getLayoutIdForMode(AppMode mode) {
    // In production, fetch from config or remote
    switch (mode) {
      case AppMode.nutrition:
        return 'layout-nutrition-home-v1';
      case AppMode.beauty:
        return 'layout-beauty-home-v1';
      default:
        return 'layout-default-home-v1';
    }
  }
}
```

### Phase 4: Beauty Mode Launch (Week 5-6)

1. **Create Beauty Page** at `/lib/features/beauty/beauty_page.dart`
2. **Insert Beauty Layout** into Supabase
3. **Test Mode Switching** performance
4. **Add Analytics** tracking for mode usage

## Performance Optimizations

1. **Prefetch Adjacent Modes**: Load beauty layout while user is in nutrition
2. **Cache First Strategy**: Always show cached layout first, then update
3. **Background Sync**: Check for layout updates on app start
4. **Image Caching**: Use `cached_network_image` for all remote images

## Security Considerations

1. **Validate JSON Schema**: Ensure remote layouts match expected structure
2. **Version Pinning**: Allow rollback to known-good versions
3. **Rate Limiting**: Prevent abuse of layout fetch endpoints
4. **RLS Policies**: Restrict layout access to authenticated users

## Testing Checklist

- [ ] Mode switching < 300ms
- [ ] Offline mode shows cached layouts
- [ ] Layout updates propagate correctly
- [ ] Unknown component types show graceful fallback
- [ ] Culture-specific layouts load correctly
- [ ] Memory usage stable across multiple switches

## Next Steps

1. Review and merge these files into `beauty-mode` branch
2. Add Hive dependency to pubspec.yaml
3. Create Supabase migration for `remote_layouts` table
4. Insert initial beauty mode layout JSON
5. Update HomePage to use SDUI renderer
6. Test with beta users from diaspora community
