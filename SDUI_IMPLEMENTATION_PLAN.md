# AKELI SDUI Implementation Plan: Option A (Dynamic Home)

## Executive Summary
**Decision**: Replace static `HomePage` with `DynamicLayoutPage` driven by remote JSON layouts.
**Goal**: Enable distinct UI experiences for Nutrition (weight/calories) vs. Beauty (skin/hair tracking) while maintaining a single codebase.
**Status**: Core services built. Ready for integration phase.

---

## 1. Architecture Overview (Option A)

### Current State (Static)
```
MainShell (Bottom Nav)
├── HomeTab -> HomePage (Hardcoded Nutrition Widgets) ❌
├── MealsTab
├── RecipesTab
└── CommunityTab
+ NutritionPage (Standalone) ✅
```

### Target State (SDUI Dynamic)
```
MainShell (Bottom Nav)
├── HomeTab -> DynamicLayoutPage (Fetches Layout based on Current Mode) ✅
├── MealsTab (Context-aware)
├── RecipesTab (Context-aware)
└── CommunityTab
+ NutritionPage (Standalone - Deep Link/Feature specific)
+ BeautyPage (Standalone - Deep Link/Feature specific)
```

**Key Change**: The "Home" tab is no longer a specific screen. It is a **viewport** that renders the JSON layout defined for the active mode (`nutrition` vs `beauty`).

---

## 2. Implementation Roadmap

### Phase 1: Database & Configuration (Day 1-2)
**Objective**: Prepare storage for layouts and initialize caching.

#### 2.1 Supabase Migration (SQL)
Run this in your Supabase SQL Editor to create the remote layout store.

```sql
-- Create layouts table
create table public.layouts (
  id uuid default gen_random_uuid() primary key,
  mode text not null check (mode in ('nutrition', 'beauty', 'health', 'sport', 'family')),
  version text not null,
  platform text default 'all', -- 'all', 'ios', 'android'
  is_active boolean default true,
  layout_json jsonb not null,
  created_at timestamptz default now(),
  unique(mode, version)
);

-- Enable RLS
alter table public.layouts enable row level security;

-- Allow public read access (layouts are not sensitive)
create policy "Public can read active layouts"
  on public.layouts
  for select
  using (is_active = true);

-- Insert Default Nutrition Layout (Migration from existing HomePage)
insert into public.layouts (mode, version, layout_json)
values (
  'nutrition',
  '1.0.0',
  '{
    "sections": [
      {
        "type": "hero_banner",
        "data": {"title": "Welcome Back", "subtitle": "Let\'s hit your goals today"}
      },
      {
        "type": "stats_row",
        "data": {"metrics": ["calories", "water", "weight"]}
      },
      {
        "type": "recent_meals_list",
        "data": {"limit": 3}
      }
    ]
  }'::jsonb
);

-- Insert Placeholder Beauty Layout
insert into public.layouts (mode, version, layout_json)
values (
  'beauty',
  '1.0.0',
  '{
    "sections": [
      {
        "type": "hero_banner",
        "data": {"title": "Glow Up", "subtitle": "Your daily ritual awaits"}
      },
      {
        "type": "stats_row",
        "data": {"metrics": ["hydration", "routine_streak", "skin_score"]}
      },
      {
        "type": "routine_tracker",
        "data": {"focus": "hair_care"}
      }
    ]
  }'::jsonb
);
```

#### 2.2 Hive Initialization (`lib/main.dart`)
Ensure Hive is initialized before the app runs.

```dart
// lib/main.dart
import 'package:hive_flutter/hive_flutter.dart';
import 'features/sdui/services/layout_cache_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Hive
  await Hive.initFlutter();
  
  // Open boxes for layout caching
  await Hive.openBox('layout_cache'); 
  await Hive.openBox('app_settings');

  runApp(
    ProviderScope(
      child: AkeliApp(),
    ),
  );
}
```

---

### Phase 2: Core Integration (Day 3-4)
**Objective**: Connect the existing services to the navigation flow.

#### 2.1 Update Router (`lib/core/router/app_router.dart`)
Ensure the home route points to the new dynamic page.

```dart
// Add/Update these routes
GoRoute(
  path: '/',
  name: 'home',
  builder: (context, state) => const DynamicLayoutPage(mode: 'nutrition'), // Default fallback
),
GoRoute(
  path: '/beauty',
  name: 'beauty-home',
  builder: (context, state) => const DynamicLayoutPage(mode: 'beauty'),
),
```

#### 2.2 Create `DynamicLayoutPage` (`lib/features/sdui/pages/dynamic_layout_page.dart`)
This replaces your current `HomePage`.

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/layout_fetch_service.dart';
import '../widget_factory.dart';
import 'package:akeli/core/providers/mode_provider.dart'; // Your existing provider

class DynamicLayoutPage extends ConsumerStatefulWidget {
  final String? mode; // Optional: if null, uses global currentMode

  const DynamicLayoutPage({super.key, this.mode});

  @override
  ConsumerState<DynamicLayoutPage> createState() => _DynamicLayoutPageState();
}

class _DynamicLayoutPageState extends ConsumerState<DynamicLayoutPage> {
  @override
  void initState() {
    super.initState();
    // Trigger fetch if not cached
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final targetMode = widget.mode ?? ref.read(currentModeProvider);
      ref.read(layoutFetchServiceProvider).fetchLayout(targetMode);
    });
  }

  @override
  Widget build(BuildContext context) {
    final targetMode = widget.mode ?? ref.watch(currentModeProvider);
    
    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () => ref.read(layoutFetchServiceProvider).fetchLayout(targetMode),
        child: Consumer(
          builder: (context, ref, child) {
            final layoutState = ref.watch(layoutFetchServiceProvider);
            
            return layoutState.when(
              data: (layoutJson) {
                if (layoutJson == null) {
                  return const Center(child: Text("No layout configured"));
                }
                return ListView.builder(
                  itemCount: layoutJson['sections'].length,
                  itemBuilder: (context, index) {
                    final section = layoutJson['sections'][index];
                    return WidgetFactory.build(section, mode: targetMode);
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, stack) => Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline, color: Colors.red),
                    const SizedBox(height: 8),
                    Text("Failed to load layout"),
                    TextButton(
                      onPressed: () => ref.read(layoutFetchServiceProvider).fetchLayout(targetMode),
                      child: const Text("Retry"),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
```

---

### Phase 3: Mode Switching Logic (Day 5)
**Objective**: Allow users to toggle between modes seamlessly.

#### 3.1 Global Mode Switcher Component
Create a reusable widget to switch modes (place in App Bar or Settings).

```dart
// lib/features/sdui/widgets/mode_switcher.dart
class ModeSwitcher extends ConsumerWidget {
  const ModeSwitcher({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentMode = ref.watch(currentModeProvider);

    return PopupMenuButton<String>(
      icon: Icon(
        currentMode == 'nutrition' ? Icons.restaurant : Icons.spa,
        color: Colors.white,
      ),
      onSelected: (newMode) {
        ref.read(currentModeProvider.notifier).state = newMode;
        // Navigate to home to trigger layout reload
        context.goNamed('home'); 
      },
      itemBuilder: (context) => [
        const PopupMenuItem(value: 'nutrition', child: Text('Nutrition Mode')),
        const PopupMenuItem(value: 'beauty', child: Text('Beauty Mode')),
        // Add future modes here
      ],
    );
  }
}
```

**Usage**: Add `ModeSwitcher()` to your `MainShell` AppBar actions.

---

## 3. Audit Checklist: What's Left?

| Component | Status | Action Required | Owner |
|-----------|--------|-----------------|-------|
| **Services** | ✅ Done | None | Dev |
| **Widget Factory** | ✅ Done | Add missing Beauty widgets (e.g., `product_ingredient_scan`) | Dev |
| **Hive Setup** | ⚠️ Pending | Add initialization to `main.dart` | Dev |
| **Supabase Table** | ⚠️ Pending | Run SQL migration script | Dev |
| **DynamicLayoutPage** | ⚠️ Pending | Create file & replace HomePage reference | Dev |
| **Router Update** | ⚠️ Pending | Update routes to point to DynamicLayoutPage | Dev |
| **Mode Provider** | ✅ Done | Ensure it persists state (Hive/SharedPrefs) | Dev |
| **Testing** | ❌ Todo | Test offline mode, slow network, schema errors | QA |

---

## 4. Risk Mitigation

1. **Blank Screen Risk**: 
   - *Solution*: Bundle a default `default_layout_nutrition.json` and `default_layout_beauty.json` in assets. If network fails AND cache is empty, load assets.

2. **Schema Drift**:
   - *Solution*: The `WidgetFactory` must have a `default` case that returns a `SizedBox.shrink()` or a generic "Content Unavailable" widget instead of crashing.

3. **Performance**:
   - *Solution*: Use `AutomaticKeepAliveClientMixin` in the `DynamicLayoutPage` if it's inside a `PageView` to preserve scroll position when switching tabs.

---

## 5. Next Immediate Steps

1. **Run the SQL Script** in Supabase Dashboard.
2. **Commit the Services** (`layout_cache_service`, `widget_factory`, etc.) to the `beauty-mode` branch.
3. **Execute Phase 2** (Integration) by creating `DynamicLayoutPage`.
4. **Verify**: Switch mode in the app and watch the Home screen transform from Nutrition stats to Beauty routines.
