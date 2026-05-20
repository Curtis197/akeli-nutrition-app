# Language Selection Feature — Technical Audit

**Date:** March 2026  
**Branch:** language-selection  
**Author:** AI Development Team  
**Status:** Pre-implementation audit

---

## Executive Summary

This audit examines the current state of internationalization (i18n) and language support in the Akeli V1 codebase. The goal is to implement a comprehensive language selection system that:

1. Stores all static UI text in a database-backed translation system
2. Renders recipes in the user's selected language
3. Supports feed and meal planner content in multiple languages
4. Provides seamless language switching across Flutter, SQL, and Edge Functions

**Current State:** No i18n infrastructure exists. The app has multilingual data fields but no unified translation management system.

---

## 1. Current Language Support Inventory

### 1.1 Supported Languages (Declared)

From `user_profile.locale` and reference data:

| Code | Language | Region | Status |
|------|----------|--------|--------|
| `fr` | French | France/Base | ✅ Default |
| `en` | English | International | ⚠️ Partial |
| `es` | Spanish | Latin America/Spain | ⚠️ Partial |
| `pt` | Portuguese | Brazil/Portugal | ⚠️ Partial |
| `wo` | Wolof | Senegal/West Africa | ❌ Not implemented |
| `bm` | Bambara | Mali/West Africa | ❌ Not implemented |
| `ln` | Lingala | DRC/Central Africa | ❌ Not implemented |

**Issue:** African languages (wo, bm, ln) are declared in schema but have no translation infrastructure.

---

### 1.2 Existing Multilingual Fields

#### Database Tables with Multi-language Columns

| Table | Columns | Languages Supported | Notes |
|-------|---------|---------------------|-------|
| `food_region` | `name_fr`, `name_en`, `name_es`, `name_pt` | 4 | Seed data complete |
| `ingredient_category` | `name_fr`, `name_en` | 2 | Limited coverage |
| `measurement_unit` | `name_fr`, `name_en`, `name_es`, `name_pt` | 4 | Seed data complete |
| `tag` | `name_fr`, `name_en`, `name_es`, `name_pt` | 4 | Seed data complete |
| `ingredient` | `name_fr`, `name_en`, `name_es`, `name_pt` | 4 | Reference data only |
| `recipe` | `language` (single field) | 1 per recipe | Recipe content NOT translated |
| `user_profile` | `locale` | 7 (declared) | User preference stored |

**Critical Gap:** Recipe `title`, `description`, `instructions` are NOT translated—they exist in a single language per recipe.

---

### 1.3 Flutter Frontend State

#### Current Implementation

```dart
// lib/main.dart - DEFAULT Flutter template
MaterialApp(
  title: 'Flutter Demo',  // ❌ Hardcoded English
  home: MyHomePage(title: 'Flutter Demo Home Page'),  // ❌ Hardcoded
)

// Navigation labels (from TECHNICAL_AUDIT.md)
BottomNavigationBarItem(label: 'Home', ...)  // ❌ All 4 tabs say "Home"
```

**Issues Identified:**

| Issue | Severity | Location | Impact |
|-------|----------|----------|--------|
| Hardcoded strings | High | Throughout | No i18n capability |
| Missing localization setup | High | `MaterialApp` | Cannot switch languages |
| No translation files | High | N/A | No .arb or .json translations |
| No locale detection | Medium | N/A | Cannot auto-detect device language |
| No language selector UI | Medium | Settings | User cannot change language |

#### Dependencies Missing

```yaml
# pubspec.yaml - NO i18n packages
dependencies:
  flutter: sdk: flutter
  cupertino_icons: ^1.0.8
  # ❌ Missing: flutter_localizations, intl, easy_localization, etc.
```

---

### 1.4 Backend/SQL State

#### RPC Functions

All RPC functions return data in the language stored in the database:

```sql
-- recommend_recipes() returns recipe.title as-is
-- No language parameter, no translation logic
-- search_recipes() same issue
-- generate_meal_plan() same issue
```

**Missing:**

1. Language parameter in RPC functions
2. Fallback logic when translation missing
3. Dynamic translation lookup

#### Reference Data

Seed file `01_reference_data.sql` contains translations for:
- ✅ Regions (4 languages)
- ✅ Categories (2 languages)
- ✅ Units (4 languages)
- ✅ Tags (4 languages)

**Gap:** No mechanism to retrieve these by user's locale automatically.

---

## 2. Technical Debt & Risks

### 2.1 Schema Design Issues

| Issue | Risk | Recommendation |
|-------|------|----------------|
| Fixed columns (`name_fr`, `name_en`) | Cannot add new languages without migration | Use EAV or JSONB model |
| Recipe content not translatable | Single-language recipes limit reach | Add `recipe_translation` table |
| No `supported_language` reference table | Language codes scattered | Create master language table |

### 2.2 Content Gaps

| Content Type | Translation Coverage | Effort to Complete |
|--------------|---------------------|-------------------|
| UI Static Text | 0% | High (requires full audit) |
| Recipe Titles | ~25% (French only) | Very High (creator-dependent) |
| Recipe Instructions | ~25% (French only) | Very High (AI-assisted) |
| Ingredient Names | ~60% (reference only) | Medium |
| Error Messages | 0% | Medium |
| Email Templates | 0% | Medium |

### 2.3 Performance Considerations

| Approach | Pros | Cons |
|----------|------|------|
| JOIN on every query | Real-time, always fresh | Query complexity |
| Cache in Edge Function | Fast response | Stale data risk |
| Duplicate columns | Simple queries | Data inconsistency |
| Client-side translation | Flexible | Large payload |

**Recommendation:** Hybrid approach—JOIN for critical paths, cache for common translations.

---

## 3. Competitive Analysis (Industry Standards)

### 3.1 Common Patterns

| App | Approach | Notes |
|-----|----------|-------|
| Duolingo | DB-backed + CDN | 40+ languages, dynamic |
| Airbnb | JSON blobs + ICU | Context-aware translations |
| Uber | Microservice i18n | Separate translation API |
| Spotify | Flat files + CMS | Artist-controlled metadata |

### 3.2 Recommended for Akeli

**Hybrid Model:**
- Static UI text → Database (flexible updates)
- Recipe content → Denormalized translation table
- Reference data → Existing multi-column approach (stable)
- Common phrases → Edge Function cache layer

---

## 4. Implementation Prerequisites

### 4.1 Database Changes Required

1. ✅ Create `supported_language` reference table
2. ✅ Create `app_translation` table (key-value by language)
3. ✅ Create `recipe_translation` table (1:N recipes)
4. ✅ Add language parameter to RPC functions
5. ✅ Update RLS policies for translations

### 4.2 Flutter Changes Required

1. ✅ Add localization dependencies
2. ✅ Set up `MaterialApp.localizationsDelegates`
3. ✅ Create translation retrieval service
4. ✅ Build language selector UI
5. ✅ Implement locale persistence
6. ✅ Update all hardcoded strings

### 4.3 Edge Functions Required

1. ✅ `get-translations` — bulk translation fetch
2. ✅ `translate-recipe` — AI-powered recipe translation
3. ✅ `sync-translations` — admin tool for batch updates

---

## 5. Success Metrics

| Metric | Target | Measurement |
|--------|--------|-------------|
| UI text coverage | 100% | String audit |
| Recipe translation availability | 80% top recipes | Analytics |
| Language switch latency | <200ms | Performance monitoring |
| Missing translation fallback | Graceful (FR→EN) | Error tracking |
| User satisfaction (language) | 4.5/5 | Survey |

---

## 6. Recommendations

### Immediate Actions (Phase 1)

1. **Create database schema** for translations
2. **Add Flutter localization** infrastructure
3. **Implement language selector** in settings
4. **Translate 100 most common UI strings**

### Medium-term (Phase 2)

1. **Recipe translation pipeline** (AI-assisted)
2. **Edge Function caching** layer
3. **Admin dashboard** for translation management
4. **Community contribution** system (like Duolingo)

### Long-term (Phase 3)

1. **Voice/audio** for African languages
2. **Offline translation** packs
3. **Contextual translations** (regional variants)
4. **Auto-detection** based on user behavior

---

## Appendix A: Language Code Standard

Use **ISO 639-1** (2-letter) where possible:

| Code | Language | ISO 639-1 | Notes |
|------|----------|-----------|-------|
| fr | French | fr | ✅ |
| en | English | en | ✅ |
| es | Spanish | es | ✅ |
| pt | Portuguese | pt | ✅ |
| wo | Wolof | wo | ✅ |
| bm | Bambara | bm | ✅ |
| ln | Lingala | ln | ✅ |

For regional variants, use BCP 47: `pt-BR`, `pt-PT`, `es-ES`, `es-MX`.

---

## Appendix B: File Structure Proposal

```
lib/
├── l10n/
│   ├── app_translations.dart      # Service layer
│   ├── translation_provider.dart  # State management
│   └── locale_selector.dart       # UI widget
├── generated/
│   └── l10n/                      # Auto-generated (if using arb)
└── ...

supabase/
├── migrations/
│   └── 20260301000003_i18n_schema.sql
├── seed/
│   └── 02_app_translations.sql
└── functions/
    ├── get-translations/
    │   └── index.ts
    └── translate-recipe/
        └── index.ts
```

---

**Next Step:** Review this audit, then proceed to implementation document.
