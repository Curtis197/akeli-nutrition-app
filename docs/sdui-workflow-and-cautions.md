# SDUI — Workflow & Bug Cautions

_Branch: `server-driven-ui-fix-plan-96b8f` — synthesised from debugging session 2026-05-23_

---

## 1. Architecture Overview

```
Supabase DB (layouts table)
        │
        ▼
LayoutFetchService          ← cache-first fetch, offline fallback
        │
        ├─ cache hit  →  LayoutCacheService (Hive)
        │
        └─ cache miss →  Supabase .select() on layouts table
                              │
                         caches result in Hive
        │
        ▼
layoutDataProvider          ← StateNotifier, stores Map<mode, layoutJson>
layoutStateProvider         ← StateNotifier, stores Map<mode, LayoutLoadingState>
        │
        ▼
DynamicLayoutPage           ← ConsumerStatefulWidget, one per mode
        │
        ▼
WidgetFactory.buildComponent(component, mode)
        │
        └─ switch on component['type'] → builds Flutter widget
```

**Mode lifecycle:**
1. `currentModeProvider` holds active `AppMode` (nutrition, beauty, …).
2. `MainShell` or profile page calls `switchMode()` → re-renders `DynamicLayoutPage` with new mode string.
3. `DynamicLayoutPage.initState` / `didUpdateWidget` schedules `_loadLayout()` via `addPostFrameCallback`.
4. `_loadLayout` sets `layoutStateProvider` to loading, fetches, then to loaded/error.

---

## 2. Data Shape Contract

Layout row in Supabase (`layouts` table):

```json
{
  "id": "uuid",
  "mode": "nutrition",
  "layout": {
    "components": [
      { "type": "header",   "config": { "title": "…" } },
      { "type": "recipe_list", "config": { "limit": 6 } }
    ]
  },
  "version": 1,
  "culture_tags": ["west_africa"]
}
```

`LayoutCacheService` stores the **whole row** (including the top-level `layout` key) keyed as `"$mode:$layoutId"` in Hive.
`_buildLayoutContent` therefore navigates: `layoutData['layout']['components']`.

---

## 3. Registered Component Types (WidgetFactory)

| `type` string | Widget built |
|---|---|
| `recipe_list` | horizontal recipe card list |
| `featured_recipe` | large hero card |
| `section_title` | bold heading |
| `nutrition_summary` | macro ring chart |
| `meal_plan_preview` | upcoming meals strip |
| `quick_log` | fast calorie log button |
| `header` | page greeting header |
| `cultural_spotlight` | culture-tagged recipe highlight |
| `weight_tracker` / `weight_tracker_card` | weight trend card |
| `calories_graph` / `calorie_summary` | calorie bar chart |
| `routine_progress` | beauty/health routine tracker |
| `skin_hair_status` | skin & hair status card |

Any unrecognised type falls through to a greyed-out placeholder (`_buildUnknownComponent`).
**Add new types there first before deploying a layout JSON that uses them.**

---

## 4. Bugs Found & Fixes Applied

### 4.1 Provider modified during widget-tree build

**Symptom:** `FlutterError: Tried to modify a provider while the widget tree was building.`

**Root cause:** `_loadLayout()` called synchronously in `initState`, which triggered `ref.read(layoutStateProvider.notifier).setLoading(…)` inside the first build frame.

**Fix:**
```dart
@override
void initState() {
  super.initState();
  WidgetsBinding.instance.addPostFrameCallback((_) => _loadLayout());
}

@override
void didUpdateWidget(DynamicLayoutPage old) {
  super.didUpdateWidget(old);
  if (old.mode != widget.mode) {
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadLayout());
  }
}
```

**Rule:** Never call a Riverpod notifier method (or any `setState`) synchronously in `initState` or `didUpdateWidget`. Always defer with `addPostFrameCallback`.

---

### 4.2 `LinkedMap<dynamic, dynamic>` type-cast crash on Flutter Web

**Symptom:** `TypeError: type 'LinkedMap<dynamic, dynamic>' is not a subtype of type 'Map<String, dynamic>'` — crash in `_buildLayoutContent` at `layoutData['layout'] as Map<String, dynamic>`.

**Root cause:** Hive on Flutter Web uses IndexedDB as its backend. When a `Map<String, dynamic>` is written and read back through IndexedDB via JS interop, the Dart DDC compiler gets a JS object wrapper typed as `LinkedMap<dynamic, dynamic>`. A hard `as Map<String, dynamic>` cast fails because the DDC type system does not consider it a subtype, even though the runtime value is structurally identical.

Adding `_deepConvert` in `LayoutCacheService` alone was **not sufficient** — by the time data reaches `layoutDataProvider` and `DynamicLayoutPage`, the types had already been re-wrapped by the provider's storage layer.

**Fix — defensive casting at every consumer site:**
```dart
// dynamic_layout_page.dart — _buildLayoutContent
final rawLayout = layoutData['layout'];
final layout = rawLayout is Map ? Map<String, dynamic>.from(rawLayout) : null;
final rawComponents = layout?['components'];
final components = rawComponents is List ? rawComponents : <dynamic>[];

// Per component:
final raw = components[index];
final component = raw is Map ? Map<String, dynamic>.from(raw) : <String, dynamic>{};
```

```dart
// widget_factory.dart — buildComponent
final rawConfig = component['config'];
final config = rawConfig is Map<String, dynamic>
    ? rawConfig
    : rawConfig is Map
        ? Map<String, dynamic>.from(rawConfig)
        : <String, dynamic>{};
```

**Rule:** Never use `as Map<String, dynamic>` on data that has passed through Hive on Flutter Web. Always use `is Map` + `Map<String, dynamic>.from(value)`.

**Belt-and-suspenders:** `LayoutCacheService._deepConvert` was also added so cache reads are pre-sanitised — but consumer-site checks remain mandatory as a second layer.

---

### 4.3 Feed RPC — wrong function name

**Symptom:** `PostgrestException: Could not find the function public.get_personalized_feed`

**Root cause:** Provider was calling `get_personalized_feed`; the actual DB function is `generate_feed_personalized` (see migration `20260517000003_recommendation_feed_engine.sql`).

**Fix:** Renamed all occurrences in `recipe_provider.dart`.

**Rule:** Always cross-check provider RPC call names against the migration SQL before shipping. A copy-paste from an old design doc can silently diverge from the deployed schema.

---

### 4.4 Feed RPC — wrong parameter name (`p_offset` vs `p_exclude`)

**Symptom:** `PGRST202: Could not find generate_feed_personalized(p_limit, p_offset, p_user_id)` — hint listed the real signature as `(p_exclude, p_limit, p_user_id)`.

**Root cause:** `FeedParams` had an `offset: int` field carried over from a paginated design; the deployed function uses `p_exclude uuid[]` (a seen-recipe exclusion list, not a cursor offset).

**Fix:**
```dart
class FeedParams {
  final int limit;
  final List<String> exclude;   // replaces offset
  const FeedParams({this.limit = 20, this.exclude = const []});
}

// In feedProvider:
final rpcParams = {
  'p_user_id': user.id,
  'p_limit':   params.limit,
  'p_exclude': params.exclude,   // uuid[] passed as List<String>
};
```

**Rule:** When an RPC has an array parameter (`uuid[]`), pass it as `List<String>` — PostgREST serialises it correctly. Do not try to encode it as a comma-separated string.

---

### 4.5 Feed RPC returns `(recipe_id, score)` — not full recipe rows

**Symptom:** `TypeError: null: type 'Null' is not a subtype of type 'String'` inside `Recipe.fromJson` immediately after the RPC call.

**Root cause:** `generate_feed_personalized` returns only `RETURNS TABLE (recipe_id uuid, score numeric)`. The provider was calling `Recipe.fromJson` directly on these two-column rows, crashing on every required `String` field.

**Fix — two-step fetch:**
```dart
// Step 1: get ordered IDs + scores
final feedRows = await client.rpc('generate_feed_personalized', params: rpcParams) as List<dynamic>;
final recipeIds = feedRows.cast<Map<String, dynamic>>()
    .map((r) => r['recipe_id'] as String).toList();

// Step 2: hydrate full recipe rows preserving feed order
final recipeRows = await client.from('recipe').select().inFilter('id', recipeIds) as List<dynamic>;
final recipeMap = { for (final r in recipeRows.cast<Map<String, dynamic>>()) r['id'] as String: r };
final recipes = recipeIds
    .where((id) => recipeMap.containsKey(id))
    .map((id) => Recipe.fromJson(recipeMap[id]!))
    .toList();
```

**Rule:** Always read the `RETURNS TABLE` clause of every RPC before calling `Model.fromJson` on the result. If the function returns a projection (IDs + scores), a second query is required to hydrate full model objects. The feed order from the RPC is preserved by re-sorting using the ID list as an ordered key.

---

## 5. Checklist Before Adding a New SDUI Layout

- [ ] Migration SQL reviewed: confirm function name, parameter names/types, and `RETURNS TABLE` columns.
- [ ] Every `type` string used in the layout JSON has a matching case in `WidgetFactory`.
- [ ] All Hive reads use `is Map` + `Map<String, dynamic>.from()` — no hard `as` casts.
- [ ] Any provider mutation triggered from `initState` or `didUpdateWidget` is wrapped in `addPostFrameCallback`.
- [ ] RPC array parameters are `List<String>` (not encoded strings).
- [ ] RPC results that are projections (not full rows) have a hydration step before `Model.fromJson`.
- [ ] New component `config` fields are accessed defensively (null-safe, with fallbacks).
