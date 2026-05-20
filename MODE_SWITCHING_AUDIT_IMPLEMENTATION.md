# AKELI Mode-Switching Architecture Audit & Implementation Plan

## Executive Summary

**Current State**: Nutrition mode is live and approved by Apple/Google. Home page currently shows nutrition-specific widgets (weight scaler, calories graph).

**Problem**: Beauty mode requires completely different home page UI (skin/hair care tracking instead of weight/calories). Current hard-coded HomePage cannot support both modes.

**Solution**: Implement Server-Driven UI (SDUI) for home page layout switching while keeping navigation shell stable.

---

## 1. Current Architecture Analysis

### 1.1 Navigation Structure

```
MainShell (Bottom Nav - 4 tabs)
├── /home → HomePage (HARD-CODED NUTRITION UI) ❌
├── /meal-planner → MealPlannerPage
├── /recipes → FeedPage
└── /community → CommunityPage

Standalone Routes (outside MainShell)
├── /nutrition → NutritionPage ✅ (Mode-ready)
├── /profile → ProfilePage
└── ... other routes
```

**Key Finding**: Nutrition page is already standalone (not in MainShell), making it mode-ready. HomePage is the bottleneck.

### 1.2 HomePage Hard-Coded Components

From `/workspace/lib/features/home/home_page.dart`:

| Component | Line Range | Nutrition-Specific | Beauty Equivalent Needed |
|-----------|------------|-------------------|-------------------------|
| Weight Stepper | 250-260 | ✅ Yes | Skin/Hair routine tracker |
| Weight Metric | 182-207 | ✅ Yes | Skin hydration/hair health metric |
| Calories Metric | 216-240 | ✅ Yes | Product usage/completion metric |
| Meal Plan Section | 263-327 | ✅ Yes | Beauty routine schedule |
| Shopping List | 330-400+ | ⚠️ Partial | Beauty product list |

**Conclusion**: 80% of HomePage content is nutrition-specific and cannot be reused for beauty mode without refactoring.

---

## 2. Recommended Architecture: Option A+ (Enhanced)

### 2.1 Core Principle

**Keep MainShell static** (performance + simplicity) but make **HomePage layout dynamic** via remote configuration.

```
┌─────────────────────────────────────┐
│         MainShell (Static)          │
│  [Home] [Meals] [Recipes] [Community]│
└─────────────────────────────────────┘
                  │
                  ▼
┌─────────────────────────────────────┐
│      HomePage (Mode-Agnostic)       │
│  ┌───────────────────────────────┐  │
│  │   Layout Engine (Dynamic)     │  │
│  │   - Fetches layout from DB    │  │
│  │   - Renders mode-specific     │  │
│  │   - Caches with Hive          │  │
│  └───────────────────────────────┘  │
└─────────────────────────────────────┘
```

### 2.2 What Gets Stored Where

| Component | Storage | Reason | Example |
|-----------|---------|--------|---------|
| **Layout Structure** | Remote DB + Hive Cache | Switchable per mode | `{"components": [{"type": "metric_card", "config": {...}}]}` |
| **Widget Types** | Local Code (WidgetFactory) | Performance + type safety | `MetricCardWidget`, `RoutineTrackerWidget` |
| **User Data** | Drift (SQLite) | Offline-first, queries | weight_logs, skin_care_logs |
| **Mode State** | Riverpod Provider | Reactive state management | `currentModeProvider` |
| **Navigation** | GoRouter (static) | Stability + deep linking | `/home`, `/beauty` |

---

## 3. Implementation Strategy

### Phase 1: Foundation (Week 1-2)

#### 3.1 Create Mode Model & Provider

```dart
// lib/shared/models/mode_config.dart
enum AppMode { nutrition, beauty, health, sport, family }

class ModeConfig {
  final AppMode mode;
  final String displayName;
  final IconData icon;
  final String layoutId; // Remote layout identifier
  final List<String> allowedWidgets;
  
  const ModeConfig({
    required this.mode,
    required this.displayName,
    required this.icon,
    required this.layoutId,
    required this.allowedWidgets,
  });
}

// lib/providers/mode_provider.dart
final currentModeProvider = StateNotifierProvider<ModeNotifier, AppMode>((ref) {
  return ModeNotifier();
});

class ModeNotifier extends StateNotifier<AppMode> {
  ModeNotifier() : super(AppMode.nutrition);
  
  void switchMode(AppMode newMode) {
    state = newMode;
    // Trigger layout fetch
    ref.read(layoutCacheProvider).fetchLayoutForMode(newMode);
  }
}
```

#### 3.2 Layout Cache Service (Hive)

```dart
// lib/services/layout_cache_service.dart
class LayoutCacheService {
  final Box _box;
  
  Future<void> saveLayout(String modeId, Map<String, dynamic> layout) async {
    await _box.put('layout_$modeId', jsonEncode(layout));
    await _box.put('layout_${modeId}_timestamp', DateTime.now().toIso8601String());
  }
  
  Map<String, dynamic>? getLayout(String modeId) {
    final json = _box.get('layout_$modeId');
    return json != null ? jsonDecode(json) : null;
  }
  
  bool isLayoutStale(String modeId, Duration maxAge) {
    final timestampStr = _box.get('layout_${modeId}_timestamp') as String?;
    if (timestampStr == null) return true;
    final timestamp = DateTime.parse(timestampStr);
    return DateTime.now().difference(timestamp) > maxAge;
  }
}
```

#### 3.3 Widget Factory (Safe Rendering)

```dart
// lib/shared/widgets/sdui/widget_factory.dart
class SDUIWidgetFactory {
  static Widget buildComponent(
    BuildContext context,
    Map<String, dynamic> config,
    AppMode mode,
  ) {
    final type = config['type'] as String;
    
    try {
      switch (type) {
        // Nutrition-specific
        case 'weight_stepper':
          return AkeliWeightStepper(...);
        case 'calories_metric':
          return _buildCaloriesMetric(context, config);
          
        // Beauty-specific
        case 'routine_tracker':
          return BeautyRoutineTracker(...);
        case 'skin_health_metric':
          return _buildSkinHealthMetric(context, config);
          
        // Shared
        case 'hero_banner':
          return HeroBanner(...);
        case 'section_header':
          return AkeliSectionHeader(...);
          
        default:
          appLogger.warning('Unknown widget type: $type for mode: $mode');
          return const SizedBox.shrink();
      }
    } catch (e) {
      appLogger.error('Widget build error: $e', metadata: {'config': config});
      return ErrorWidget.builder(
        FlutterErrorDetails(exception: e),
      );
    }
  }
}
```

### Phase 2: HomePage Refactor (Week 3-4)

#### 2.1 New HomePage Structure

```dart
// lib/features/home/home_page.dart (refactored)
class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});
  
  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  late Future<Map<String, dynamic>?> _layoutFuture;
  
  @override
  void initState() {
    super.initState();
    _loadLayout();
  }
  
  void _loadLayout() {
    final mode = ref.read(currentModeProvider);
    _layoutFuture = ref.read(layoutCacheProvider).getLayoutForMode(mode);
  }
  
  @override
  Widget build(BuildContext context) {
    final mode = ref.watch(currentModeProvider);
    
    return FutureBuilder<Map<String, dynamic>?>(
      future: _layoutFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        
        if (snapshot.hasError || !snapshot.hasData) {
          return _buildFallbackUI(mode);
        }
        
        final layout = snapshot.data!;
        final components = layout['components'] as List<dynamic>;
        
        return SingleChildScrollView(
          child: Column(
            children: components
                .map((config) => SDUIWidgetFactory.buildComponent(
                      context,
                      config as Map<String, dynamic>,
                      mode,
                    ))
                .toList(),
          ),
        );
      },
    );
  }
  
  Widget _buildFallbackUI(AppMode mode) {
    // Show basic UI when layout fetch fails
    return Center(
      child: Text('Mode: ${mode.displayName}'),
    );
  }
}
```

#### 2.2 Mode Switcher UI

Add to HomePage AppBar or as floating button:

```dart
// lib/shared/widgets/mode_switcher.dart
class ModeSwitcher extends StatelessWidget {
  const ModeSwitcher({super.key});
  
  @override
  Widget build(BuildContext context) {
    final currentMode = ref.watch(currentModeProvider);
    
    return PopupMenuButton<AppMode>(
      icon: Icon(currentMode.icon, color: AkeliColors.primary),
      tooltip: 'Switch Mode',
      onSelected: (newMode) {
        ref.read(currentModeProvider.notifier).switchMode(newMode);
        HapticFeedback.lightImpact();
      },
      itemBuilder: (context) => [
        PopupMenuItem(
          value: AppMode.nutrition,
          child: Row(
            children: [
              Icon(Icons.restaurant, color: AkeliColors.primary),
              const SizedBox(width: 12),
              const Text('Nutrition'),
            ],
          ),
        ),
        PopupMenuItem(
          value: AppMode.beauty,
          child: Row(
            children: [
              Icon(Icons.spa, color: AkeliColors.primary),
              const SizedBox(width: 12),
              const Text('Beauty'),
            ],
          ),
        ),
        // Add other modes...
      ],
    );
  }
}
```

### Phase 3: Beauty Mode Content (Week 5-6)

#### 3.1 Beauty-Specific Widgets

Create new widget types:
- `BeautyRoutineTracker` (replaces WeightStepper)
- `SkinHealthMetric` (replaces WeightMetric)
- `ProductUsageMetric` (replaces CaloriesMetric)
- `BeautyScheduleSection` (replaces MealPlanSection)

#### 3.2 Remote Layout JSON Example

```json
{
  "mode": "beauty",
  "version": "1.0.0",
  "layout_id": "beauty_home_v1",
  "components": [
    {
      "type": "hero_banner",
      "config": {
        "title": "Beauty Routine",
        "subtitle": "Track your skin & hair journey",
        "image_url": "https://..."
      }
    },
    {
      "type": "skin_health_metric",
      "config": {
        "label": "Skin Hydration",
        "target": 80,
        "unit": "%",
        "gradient_colors": ["#FF6B6B", "#FFE66D"]
      }
    },
    {
      "type": "product_usage_metric",
      "config": {
        "label": "Products Used",
        "target": 5,
        "unit": "items"
      }
    },
    {
      "type": "routine_tracker",
      "config": {
        "routines": ["morning", "evening"],
        "track_hydration": true,
        "track_products": true
      }
    },
    {
      "type": "beauty_schedule_section",
      "config": {
        "title": "Today's Routine",
        "show_completed": true
      }
    },
    {
      "type": "product_list",
      "config": {
        "title": "Shopping List",
        "filter_options": ["to_buy", "in_stock"]
      }
    }
  ]
}
```

---

## 4. Stored Function Deployment Concerns

### 4.1 Current Supabase Functions

Check existing functions:
```bash
# In your Supabase dashboard or SQL editor
SELECT routine_name 
FROM information_schema.routines 
WHERE routine_schema = 'public';
```

### 4.2 Recommended Approach

**Option A: Keep Functions Minimal (Recommended)**
- Use Supabase functions only for complex aggregations
- Store layout logic in Flutter app + remote JSON
- Benefits: Faster iteration, no DB migrations for UI changes

**Option B: Function-Based Layout Fetching**
```sql
CREATE OR REPLACE FUNCTION get_layout_for_mode(
  p_mode TEXT,
  p_user_id UUID
)
RETURNS JSONB AS $$
DECLARE
  v_layout JSONB;
BEGIN
  -- Check user preferences first
  SELECT config INTO v_layout
  FROM user_preferences
  WHERE user_id = p_user_id AND mode = p_mode;
  
  -- Fallback to default layout
  IF v_layout IS NULL THEN
    SELECT layout_json INTO v_layout
    FROM mode_layouts
    WHERE mode = p_mode AND is_default = true;
  END IF;
  
  RETURN v_layout;
END;
$$ LANGUAGE plpgsql;
```

**Deployment Strategy**:
1. Version all functions: `get_layout_for_mode_v1()`
2. Use migration files for function changes
3. Test in staging before production
4. Keep rollback scripts ready

### 4.3 Migration Files Structure

```
supabase/migrations/
├── 20250101000000_create_mode_layouts_table.sql
├── 20250102000000_create_user_preferences_table.sql
├── 20250103000000_create_function_get_layout_v1.sql
└── 20250104000000_seed_default_layouts.sql
```

---

## 5. Database Schema Recommendations

### 5.1 Remote Layouts Table (Supabase)

```sql
CREATE TABLE mode_layouts (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  mode TEXT NOT NULL CHECK (mode IN ('nutrition', 'beauty', 'health', 'sport', 'family')),
  version TEXT NOT NULL,
  layout_json JSONB NOT NULL,
  culture_tags TEXT[],
  region TEXT,
  is_default BOOLEAN DEFAULT false,
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_mode_layouts_active ON mode_layouts(mode, is_active);
CREATE INDEX idx_mode_layouts_region ON mode_layouts(region) WHERE is_active = true;
```

### 5.2 User Preferences Table

```sql
CREATE TABLE user_preferences (
  user_id UUID REFERENCES auth.users(id),
  mode TEXT NOT NULL,
  selected_layout_id UUID REFERENCES mode_layouts(id),
  custom_config JSONB,
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  PRIMARY KEY (user_id, mode)
);
```

### 5.3 Local Drift Tables (Flutter)

```dart
// lib/data/database.dart
@DriftDatabase(tables: [
  // Existing tables
  Meals,
  Recipes,
  // New tables for mode switching
  ModeLayouts,
  UserPreferences,
  // Beauty-specific tables
  SkinCareLogs,
  HairCareLogs,
  BeautyProducts,
])
class AppDatabase extends _$AppDatabase {}
```

---

## 6. Risk Mitigation

| Risk | Impact | Mitigation |
|------|--------|------------|
| Layout fetch fails | High | Cache fallback + bundled default layouts |
| Widget type mismatch | Medium | Safe WidgetFactory with error boundaries |
| Mode switch latency | Medium | Prefetch adjacent mode layouts |
| Breaking layout schema | High | Version validation + backward compatibility |
| App store rejection (dynamic UI) | Low | Document SDUI pattern in review notes |
| Stored function deployment errors | Medium | Versioned functions + staging environment |

---

## 7. Success Metrics

### Pre-Launch
- [ ] Layout fetch < 300ms (cached)
- [ ] Mode switch < 500ms (uncached)
- [ ] Zero crashes from unknown widget types
- [ ] Offline mode works with cached layouts

### Post-Launch
- Mode adoption rate (Beauty vs Nutrition)
- Average session duration per mode
- Layout engagement heatmaps
- User retention by cultural segment

---

## 8. Implementation Checklist

### Week 1-2: Foundation
- [ ] Create `AppMode` enum and `ModeConfig` model
- [ ] Implement `currentModeProvider` with Riverpod
- [ ] Set up Hive boxes for layout caching
- [ ] Create `LayoutCacheService`
- [ ] Build `SDUIWidgetFactory` with 3 widget types

### Week 3-4: HomePage Refactor
- [ ] Refactor HomePage to use layout engine
- [ ] Add mode switcher UI component
- [ ] Implement layout fetching from Supabase
- [ ] Add loading/error states
- [ ] Test offline scenarios

### Week 5-6: Beauty Mode
- [ ] Create beauty-specific widgets (4 types)
- [ ] Design beauty layout JSON schema
- [ ] Seed beauty layout in Supabase
- [ ] Add beauty data tables to Drift
- [ ] Beta test with 10 users

### Week 7-8: Polish & Launch
- [ ] Performance optimization (prefetching)
- [ ] Analytics integration
- [ ] App store update submission
- [ ] Marketing materials for Beauty mode
- [ ] Launch V1

---

## 9. Next Immediate Actions

1. **Audit Supabase functions**: List all existing stored functions
2. **Create layout JSON schema**: Define structure for nutrition + beauty
3. **Build minimal WidgetFactory**: Start with 3 shared + 2 mode-specific widgets
4. **Set up Hive cache**: Initialize boxes for layout storage
5. **Design beauty widgets**: Mock up skin/hair tracking UI components

---

## Conclusion

Your architecture is **70% ready** for mode switching. The main gap is the hard-coded HomePage, which this plan addresses through SDUI. By keeping MainShell static and making HomePage dynamic, you get:

✅ Fast mode switching without navigation rebuilds  
✅ Cultural customization without app updates  
✅ Offline-first UX with local caching  
✅ Scalable to 5 modes without code bloat  

**Recommendation**: Proceed with Phase 1 immediately while preparing beauty content creators for Phase 3.
