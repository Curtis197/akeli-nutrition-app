# AKELI Architecture Audit: Pages & Navigation for Mode-Based Layout Switching

**Date**: December 2024  
**Status**: Nutrition Mode ✅ Live (Apple & Google Approved)  
**Objective**: Audit current implementation to identify layouts that can be stored remotely and switched by mode for V1 (Nutrition + Beauty)

---

## 📊 Current Architecture Analysis

### 1. Navigation Structure (Current Implementation)

#### Main Shell (`main_shell.dart`)
**Current State**: Hard-coded bottom navigation with 4 tabs
```dart
static const _tabs = [
  _TabItem(route: AkeliRoutes.home, icon: Icons.home_outlined, label: 'Home'),
  _TabItem(route: AkeliRoutes.mealPlanner, icon: Icons.restaurant_menu_outlined, label: 'Meals'),
  _TabItem(route: AkeliRoutes.recipes, icon: Icons.menu_book_outlined, label: 'Recipes'),
  _TabItem(route: AkeliRoutes.community, icon: Icons.people_outlined, label: 'Community'),
];
```

**Issue**: Navigation is static and not mode-aware. All users see the same 4 tabs regardless of active wellness mode.

#### Router (`router.dart`)
**Current State**: GoRouter with mixed ShellRoute + individual routes
- **ShellRoute** (persistent nav): home, meal-planner, recipes, community
- **Top-level routes**: nutrition, fan-mode, subscription, ai-chat, profile, diet-plan, notifications, etc.

**Key Finding**: `nutrition` route exists as a standalone page (`/nutrition`), not integrated into the main shell navigation. This is actually a **mode-like pattern** already in place!

---

## 🗂️ Page Inventory & Classification

### Pages by Feature Area

| Page | Route | Current Nav Location | Mode Candidate? | SDUI Ready? | Priority |
|------|-------|---------------------|-----------------|-------------|----------|
| **HomePage** | `/home` | Shell (tab 1) | ❌ No (aggregator) | 🟡 Partial | High |
| **MealPlannerPage** | `/meal-planner` | Shell (tab 2) | ⚠️ Hybrid | ✅ Yes | High |
| **FeedPage** (Recipes) | `/recipes` | Shell (tab 3) | ❌ No (content feed) | ✅ Yes | Medium |
| **CommunityPage** | `/community` | Shell (tab 4) | ❌ No (social) | ✅ Yes | Low |
| **NutritionPage** | `/nutrition` | Standalone | ✅ **YES - Mode 1** | ✅ **Yes** | ✅ **Done** |
| **BeautyPage** | _(not built)_ | _(TBD)_ | ✅ **YES - Mode 2** | 🎯 **Target** | 🚀 **V1** |
| **FanModePage** | `/fan-mode` | Standalone | ❌ No (subscription feature) | ✅ Yes | Low |
| **ProfilePage** | `/profile` | App bar action | ❌ No (settings) | 🟡 Partial | Medium |
| **DietPlanPage** | `/diet-plan` | Standalone | ⚠️ Could be mode sub-feature | ✅ Yes | Medium |
| **AiChatPage** | `/ai-chat` | Standalone | ❌ No (utility) | ✅ Yes | Low |
| **NotificationsPage** | `/notifications` | Standalone | ❌ No (system) | ✅ Yes | Low |
| **SubscriptionPage** | `/subscription` | Standalone | ❌ No (billing) | ✅ Yes | Low |

---

## 🎯 Mode-Based Architecture Proposal

### Proposed 5 Modes for AKELI

| Mode | Purpose | Current Equivalent | Beauty Mode Equivalent |
|------|---------|-------------------|------------------------|
| **Nutrition** | Track meals, macros, hydration | ✅ `NutritionPage` | N/A |
| **Beauty** | Hair/skin routines, product tracking | _(new)_ | 🎯 `BeautyPage` (V1) |
| **Health** | Symptoms, medications, vitals | _(future)_ | `HealthPage` |
| **Sport** | Workouts, activity tracking | _(future)_ | `SportPage` |
| **Family** | Multi-user tracking, shared goals | _(future)_ | `FamilyPage` |

### Navigation Redesign for Mode Switching

#### Option A: Mode-Agnostic Shell + Mode-Specific Pages (Recommended)
```
Bottom Navigation (Persistent):
├─ Home (dashboard changes per mode)
├─ Planner (meal planner OR beauty routine planner)
├─ Feed (recipes OR beauty tips)
├─ Community (unchanged)
└─ [Mode Switcher Button] → Opens mode selection modal

Standalone Mode Pages:
├─ /nutrition (current)
├─ /beauty (V1 target)
├─ /health (future)
├─ /sport (future)
└─ /family (future)
```

#### Option B: Mode as Top-Level Navigation
```
Bottom Navigation Changes Per Mode:
Nutrition Mode Active:
├─ Dashboard
├─ Meal Planner
├─ Recipes
├─ Nutrition Tracker ← replaces one tab
└─ Profile

Beauty Mode Active:
├─ Dashboard
├─ Routine Planner
├─ Beauty Feed
├─ Beauty Tracker ← replaces one tab
└─ Profile
```

**Recommendation**: Start with **Option A** for V1. It requires minimal changes to existing navigation while enabling Beauty mode integration.

---

## 📦 Layout Components Audit

### Components That Can Be Remote-Controlled via SDUI

#### ✅ High Confidence (Ready for Remote Layouts)

| Component | Current Location | SDUI Complexity | Cultural Override Potential |
|-----------|------------------|-----------------|----------------------------|
| **Macro Tracking Cards** | `NutritionPage`, `HomePage` | Low | High (different cultures track different macros) |
| **Water Tracker** | `NutritionPage` | Low | Medium (hydration customs vary) |
| **Weight Section** | `NutritionPage` | Low | Low |
| **Meal Cards** | `HomePage`, `MealPlannerPage` | Medium | High (African vs Western meal structures) |
| **Recipe Cards** | `FeedPage`, `HomePage` | Medium | High (ingredient substitutions) |
| **Section Headers** | All pages | Low | Medium (language, imagery) |
| **Progress Circles** | `HomePage`, `NutritionPage` | Low | Low |
| **Empty States** | All pages | Low | High (culturally relevant messaging) |

#### 🟡 Medium Confidence (Need Refactoring)

| Component | Issue | Effort | Recommendation |
|-----------|-------|--------|----------------|
| **TabBar in NutritionPage** | Hard-coded tabs ("Aujourd'hui", "Semaine") | Medium | Make tabs configurable via JSON |
| **Weight Stepper** | Local state only | Medium | Extract to reusable widget with config |
| **Shopping List Filters** | Hard-coded filters | Low | Move filter config to remote |
| **Hero Banners** | Mixed implementation | Low | Standardize for SDUI |

#### ⚠️ Low Confidence (Keep Local for Now)

| Component | Reason | Future Consideration |
|-----------|--------|---------------------|
| **Navigation Bar** | Performance critical | Keep local, but make tab labels configurable |
| **App Bar Actions** | Context-sensitive | Keep local |
| **Dialogs/Modals** | Complex interactions | Keep local initially |
| **Form Inputs** | Validation logic | Keep local, but field order could be remote |

---

## 🗄️ Database Schema Recommendations

### What to Store in Remote Layout DB vs Local Cache

#### Remote Layout Database (Supabase/Contentful)
```json
{
  "layout_id": "nutrition_v1_west_african",
  "mode": "nutrition",
  "version": "1.0.0",
  "culture_tags": ["west_african", "urban", "english"],
  "components": [
    {
      "type": "hero_banner",
      "config": {
        "title": "Track Your African Meals",
        "subtitle": "From jollof rice to thieboudienne",
        "image_url": "https://...",
        "action_button": "Log Meal"
      }
    },
    {
      "type": "macro_tracker",
      "config": {
        "show_protein": true,
        "show_carbs": true,
        "show_fat": true,
        "show_fiber": false,
        "custom_macros": ["carbs_from_tuber"]
      }
    },
    {
      "type": "water_tracker",
      "config": {
        "default_target_ml": 2000,
        "glass_size_ml": 250,
        "icon_style": "modern"
      }
    }
  ],
  "fallback_layout_id": "nutrition_v1_default"
}
```

#### Local Cache (Hive) - Layout Metadata Only
```dart
// Store parsed layout + version for instant switching
{
  "current_mode": "nutrition",
  "layout_id": "nutrition_v1_west_african",
  "layout_version": "1.0.0",
  "fetched_at": "2024-12-01T10:00:00Z",
  "cache_expiry": "2024-12-08T10:00:00Z"
}
```

#### Local Database (Drift) - User Data Only
```sql
-- Nutrition data (already exists)
CREATE TABLE meal_logs (
  id TEXT PRIMARY KEY,
  user_id TEXT,
  recipe_id TEXT,
  calories REAL,
  protein_g REAL,
  carbs_g REAL,
  fat_g REAL,
  logged_at TIMESTAMP
);

-- Beauty data (V1 addition)
CREATE TABLE beauty_logs (
  id TEXT PRIMARY KEY,
  user_id TEXT,
  routine_type TEXT, -- 'hair', 'skin', 'nails'
  products_used TEXT[], -- JSON array
  notes TEXT,
  logged_at TIMESTAMP
);

-- User cultural preferences (shared across modes)
CREATE TABLE user_preferences (
  user_id TEXT PRIMARY KEY,
  primary_culture TEXT, -- 'west_african', 'caribbean', etc.
  language_preference TEXT,
  dietary_restrictions TEXT[],
  beauty_preferences TEXT -- JSON: {hair_type, skin_tone, concerns}
);
```

---

## 🔧 Required Code Changes for V1 (Beauty Mode)

### Phase 1: Minimal Changes (Week 1-2)

#### 1. Create Mode Provider
```dart
// lib/providers/mode_provider.dart
enum WellnessMode { nutrition, beauty, health, sport, family }

final currentModeProvider = StateNotifierProvider<ModeNotifier, WellnessMode>((ref) {
  return ModeNotifier();
});

class ModeNotifier extends StateNotifier<WellnessMode> {
  ModeNotifier() : super(WellnessMode.nutrition);
  
  void setMode(WellnessMode mode) => state = mode;
}
```

#### 2. Add Beauty Route to Router
```dart
// lib/core/router.dart
static const beauty = "/beauty";

// Add route
GoRoute(
  path: AkeliRoutes.beauty,
  builder: (context, state) => const BeautyPage(),
),
```

#### 3. Create BeautyPage Placeholder
```dart
// lib/features/beauty/beauty_page.dart
class BeautyPage extends ConsumerWidget {
  const BeautyPage({super.key});
  
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // For V1, mirror NutritionPage structure
    // Later: Load layout from SDUI
    return Scaffold(
      appBar: AppBar(title: Text('Beauty')),
      body: Center(child: Text('Beauty Mode - V1 Coming Soon')),
    );
  }
}
```

### Phase 2: SDUI Integration (Week 3-4)

#### 4. Create Layout Service
```dart
// lib/services/layout_service.dart
class LayoutService {
  final HiveCache _cache;
  final Dio _api;
  
  Future<LayoutConfig> getLayoutForMode(WellnessMode mode) async {
    // Check cache first
    final cached = await _cache.get('layout_$mode');
    if (cached != null && !cached.isExpired) {
      return cached.layout;
    }
    
    // Fetch from remote
    final response = await _api.get('/layouts/$mode');
    final layout = LayoutConfig.fromJson(response.data);
    
    // Cache it
    await _cache.put('layout_$mode', layout);
    return layout;
  }
}
```

#### 5. Update MainShell to Support Mode Switching
```dart
// lib/shared/widgets/main_shell.dart
// Add mode switcher button in app bar or as 5th tab
```

### Phase 3: Beauty Mode Content (Week 5-6)

#### 6. Create Beauty-Specific Widgets
- `HairRoutineTracker`
- `ProductIngredientAnalyzer`
- `SkinCareStepCard`
- `CulturalBeautyTipBanner`

#### 7. Add Beauty Logging to Drift DB
```dart
// lib/data/database.dart
@DriftDatabase(tables: [BeautyLogs, UserPreferences])
class AppDatabase extends _$AppDatabase {}
```

---

## 📈 Migration Strategy: Current → Mode-Based

### Step-by-Step Transition

| Step | Action | Risk | Rollback Plan |
|------|--------|------|---------------|
| 1 | Add `currentModeProvider` without UI changes | Low | Remove provider |
| 2 | Create `/beauty` route, keep hidden | None | Don't link to it |
| 3 | Build `BeautyPage` mirroring `NutritionPage` structure | Low | Keep as draft |
| 4 | Add mode switcher in settings (beta only) | Medium | Feature flag off |
| 5 | Migrate 1-2 Nutrition components to SDUI | Medium | Fallback to hardcoded |
| 6 | Full Beauty mode launch with SDUI | High | Disable mode, show maintenance |

---

## ⚠️ Risks & Mitigations

### Technical Risks

| Risk | Impact | Likelihood | Mitigation |
|------|--------|------------|------------|
| Layout fetch latency breaks UX | High | Medium | Aggressive caching + prefetch adjacent modes |
| Schema drift breaks rendering | High | Low | Versioned layouts + fallback to bundled default |
| Cache invalidation bugs | Medium | Medium | TTL-based expiry + manual refresh trigger |
| Offline mode fails | High | Low | Bundle default layouts in app assets |

### Product Risks

| Risk | Impact | Mitigation |
|------|--------|------------|
| Users confused by mode switching | High | Clear onboarding + visual mode indicators |
| Beauty mode content not culturally authentic | Critical | Partner with diaspora beauty creators from day 1 |
| Mode fragmentation reduces engagement | Medium | Track mode-switch frequency, optimize for common flows |

---

## ✅ Recommendations for V1 Launch

### Immediate Actions (Next 2 Weeks)

1. **Keep Nutrition Mode As-Is**: It's approved and working. Don't refactor unless necessary for Beauty integration.

2. **Build Beauty Mode Parallel to Nutrition**: Mirror the structure, don't merge yet.

3. **Add Mode Provider First**: Implement `currentModeProvider` without changing UI. This sets foundation for future SDUI.

4. **Create Remote Layout Schema**: Define JSON structure for Beauty mode layouts before building widgets.

5. **Start with Hybrid Approach**: 
   - Navigation stays local (performance)
   - Page content comes from remote layouts (flexibility)
   - User data stored in Drift (offline-first)

### Post-V1 Optimization (Months 2-3)

1. **Migrate Nutrition to SDUI**: Once Beauty proves the pattern, backport to Nutrition.

2. **Add Cultural Overrides**: Use `user_preferences` table to customize layouts per culture.

3. **Implement Prefetching**: Load next probable mode layouts in background.

4. **Analytics Integration**: Track which layouts drive best engagement per cultural segment.

---

## 📋 Checklist: Is Your App Ready for Mode Switching?

### Architecture Readiness
- [x] Nutrition mode live and stable
- [ ] Mode provider implemented
- [ ] Layout service abstraction created
- [ ] Cache layer (Hive) configured
- [ ] Database schema supports multiple modes
- [ ] Error handling for missing layouts

### Content Readiness
- [x] Nutrition content validated
- [ ] Beauty content creators lined up
- [ ] Cultural review process established
- [ ] Translation/localization plan

### Testing Readiness
- [ ] Unit tests for mode provider
- [ ] Widget tests for SDUI renderer
- [ ] Integration tests for offline mode
- [ ] Beta testing group recruited

---

## 🎯 Success Metrics for Mode Switching

| Metric | Target | Measurement |
|--------|--------|-------------|
| Mode switch latency | <300ms | Analytics event timing |
| Layout load success rate | >95% | Error tracking |
| Beauty mode adoption (V1) | >30% of users | DAU/MAU by mode |
| Cultural relevance score | >4.5/5 | User surveys |
| Offline functionality | 100% core features | QA testing matrix |

---

## 🔮 Future Considerations (Post-V1)

1. **Dynamic Tab Configuration**: Let remote config change bottom nav tabs per mode
2. **A/B Testing Layouts**: Serve different layouts to test engagement
3. **User-Generated Layouts**: Let creators design custom tracking screens
4. **Cross-Mode Insights**: "Your nutrition affects your skin health" correlations
5. **White-Label SDUI Engine**: License to other cultural wellness apps

---

## 📞 Next Steps

1. **Review this audit** with your team
2. **Prioritize V1 scope**: Beauty mode parallel build vs full SDUI migration
3. **Schedule technical spike**: 2-day prototype of layout service
4. **Identify beauty creators**: Start content curation now
5. **Set up analytics**: Track baseline metrics before mode switching

---

**Document Version**: 1.0  
**Last Updated**: December 2024  
**Owner**: AKELI Development Team  
**Status**: Ready for Review
