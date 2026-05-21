# Stitch ↔ Dart Pages Correspondence Audit

**Audit Date:** 2026-05-20  
**Purpose:** Map all Stitch design prototypes to their corresponding Flutter/Dart implementations and identify gaps.

---

## Summary Statistics

| Category | Count |
|----------|-------|
| **Total Stitch Designs** | 35 |
| **Existing Dart Pages** | 20 |
| **Missing Dart Pages** | 4 |
| **Bottom Sheets/Components** | 2 (both missing) |
| **Coverage Rate** | ~83% |

---

## Detailed Mapping Table

### ✅ Auth & Onboarding Flow

| Stitch Directory | Stitch File | Dart File | Status | Notes |
|-----------------|-------------|-----------|--------|-------|
| `akeli_auth_login` | `code.html` | `lib/features/auth/auth_page.dart` | ✅ Match | Wave 1 completed |
| `akeli_auth_sign_up` | `code.html` | `lib/features/auth/auth_page.dart` | ✅ Match | Combined in same file |
| `akeli_onboarding_language_selection` | `code.html` | `lib/features/auth/onboarding_page.dart` | ✅ Match | Wave 1 completed |
| `akeli_onboarding_profile` | `code.html` | `lib/features/auth/onboarding_page.dart` | ✅ Match | Multiple screens in one file |
| `akeli_onboarding_goals` | `code.html` | `lib/features/auth/onboarding_page.dart` | ✅ Match | — |
| `akeli_onboarding_preferences` | `code.html` | `lib/features/auth/onboarding_page.dart` | ✅ Match | — |
| `akeli_onboarding_consent` | `code.html` | `lib/features/auth/onboarding_page.dart` | ✅ Match | — |
| `akeli_onboarding_summary` | `code.html` | `lib/features/auth/onboarding_page.dart` | ✅ Match | — |

---

### ✅ Core Navigation & Dashboard

| Stitch Directory | Stitch File | Dart File | Status | Notes |
|-----------------|-------------|-----------|--------|-------|
| `akeli_digital_editorial_dashboard` | `code.html` | `lib/features/home/home_page.dart` | ✅ Match | Wave 2 completed (d2635f5) |
| `akeli_recipe_discovery_editorial` | `code.html` | `lib/features/recipes/feed_page.dart` | ✅ Match | Wave 2 completed (cb84a1f) |
| `akeli_premium_recipe_detail_editorial` | `code.html` | `lib/features/recipes/recipe_detail_page.dart` | ✅ Match | Wave 3 completed |

---

### ✅ Meal Planning Suite

| Stitch Directory | Stitch File | Dart File | Status | Notes |
|-----------------|-------------|-----------|--------|-------|
| `akeli_full_week_planner_v2` | `code.html` | `lib/features/meal_planner/meal_planner_page.dart` | ✅ Match | Wave 3 completed |
| `akeli_full_week_meal_planner` | `code.html` | `lib/features/meal_planner/meal_planner_page.dart` | ✅ Match | Earlier version, superseded by v2 |
| `akeli_meal_detail_simplified_ingredients` | `code.html` | `lib/features/meal_planner/meal_detail_page.dart` | ✅ Match | Wave 3 completed |
| `akeli_batch_cooking_tracker` | `code.html` | `lib/features/meal_planner/batch_cooking_page.dart` | ✅ Match | Wave 3 completed |
| `akeli_editorial_shopping_list` | `code.html` | `lib/features/meal_planner/shopping_list_page.dart` | ✅ Match | Wave 3 completed |
| `akeli_diet_plan_editorial` | `code.html` | `lib/features/diet_plan/diet_plan_page.dart` | ✅ Match | Wave 3 completed |

---

### ✅ Features with Implementations

| Stitch Directory | Stitch File | Dart File | Status | Notes |
|-----------------|-------------|-----------|--------|-------|
| `akeli_editorial_chat` | `code.html` | `lib/features/ai_assistant/ai_chat_page.dart` | ✅ Match | Wave 3 completed |
| `akeli_notification_settings_editorial` | `code.html` | `lib/features/notifications/notifications_page.dart` | ✅ Match | Pending redesign |
| `akeli_community_groups` | `code.html` | `lib/features/community/community_page.dart` | ✅ Match | Pending redesign |
| `akeli_community_conversations` | `code.html` | `lib/features/community/group_chat_page.dart` | ✅ Match | Pending redesign |
| `akeli_subscription_management_editorial` | `code.html` | `lib/features/subscription/subscription_page.dart` | ✅ Match | Pending redesign |

---

### ⚠️ Partial Matches / Multiple Stitches

| Stitch Directories | Dart File | Status | Notes |
|-------------------|-----------|--------|-------|
| `akeli_profile_digital_editorial` + `akeli_profile_create_edit` + `akeli_edit_info_editorial` | `lib/features/profile/profile_page.dart` | ⚠️ Complex | 3 stitch designs → 1 Dart file (needs consolidation) |

---

### ❌ Missing Dart Pages (Have Stitch Designs)

| Stitch Directory | Stitch File | Target Dart File | Priority | Notes |
|-----------------|-------------|------------------|----------|-------|
| `akeli_privacy_policy_editorial` | `code.html` | `lib/features/legal/privacy_policy_page.dart` | Medium | Legal requirement |
| `akeli_terms_of_service_editorial` | `code.html` | `lib/features/legal/terms_of_service_page.dart` | Medium | Legal requirement |
| `akeli_support_editorial` | `code.html` | `lib/features/support/support_page.dart` | High | User support needed |
| `akeli_referral_management_editorial` | `code.html` | `lib/features/referral/referral_page.dart` | Medium | Growth feature |

---

### ❌ Missing Bottom Sheets & Components

| Stitch Directory | Stitch File | Target Dart File | Priority | Notes |
|-----------------|-------------|------------------|----------|-------|
| `new_cooking_session_bottom_sheet` | `code.html` | `lib/shared/widgets/cooking_session_sheet.dart` | High | Meal tracking flow |
| `journaling_bottom_sheet_no_feelings` | `code.html` | `lib/shared/widgets/journaling_sheet.dart` | Medium | Nutrition journaling |

---

### 📊 Standalone / Reference Stitches (No Direct Page)

| Stitch Directory | Purpose | Notes |
|-----------------|---------|-------|
| `akeli_oasis` | Design system reference | Token documentation |
| `akeli_oasis_v2` | Design system reference | Updated tokens + DESIGN.md |
| `akelibadge_showcase_v2` | Component library | Badge variations reference |
| `audit_exemple/code.html` | Audit example | Reference for auditing format |
| `meal_detail/code.html` | Legacy meal detail | Superseded by stitch4 version |
| `stitch_meal_planner/code.html` | Legacy meal planner | Superseded by stitch4 version |

---

## Gaps Analysis

### Critical Gaps (User-Facing Features)

1. **Support Page** - Users have no way to contact support
   - Stitch: `akeli_support_editorial`
   - Missing: `lib/features/support/support_page.dart`

2. **Legal Pages** - Required for app store compliance
   - Privacy Policy: `akeli_privacy_policy_editorial`
   - Terms of Service: `akeli_terms_of_service_editorial`

3. **Bottom Sheets** - Key interaction patterns missing
   - Cooking Session tracking broken without bottom sheet
   - Journaling flow incomplete

### Moderate Gaps (Growth & Engagement)

4. **Referral Management** - User acquisition feature
   - Stitch: `akeli_referral_management_editorial`
   - Missing: `lib/features/referral/referral_page.dart`

5. **Group Detail Page** - Community feature gap
   - Has `group_chat_page.dart` but no `group_detail_page.dart`
   - No dedicated stitch, should use design system spec

---

## Recommendations

### Immediate Actions (Week 1)

1. **Create Support Page** - High user impact
   ```bash
   lib/features/support/support_page.dart
   ```
   Reference: `stitch/stitch_modern_dashboard_akeli_victoire/akeli_support_editorial/code.html`

2. **Create Legal Pages** - Compliance requirement
   ```bash
   lib/features/legal/privacy_policy_page.dart
   lib/features/legal/terms_of_service_page.dart
   ```

3. **Create Bottom Sheets** - Complete core flows
   ```bash
   lib/shared/widgets/cooking_session_sheet.dart
   lib/shared/widgets/journaling_sheet.dart
   ```

### Short-Term Actions (Week 2-3)

4. **Profile Page Redesign** - Consolidate 3 stitch designs
   - Current file needs major refactor to match editorial design
   - Reference all three profile stitches

5. **Community Pages Completion**
   - Create `group_detail_page.dart`
   - Redesign existing community pages per stitch3

6. **Referral System** - Growth feature
   - Create `referral_page.dart` from stitch2 design

---

## File Structure Recommendations

```
lib/
├── features/
│   ├── legal/                    # NEW DIRECTORY
│   │   ├── privacy_policy_page.dart
│   │   └── terms_of_service_page.dart
│   ├── support/                  # NEW DIRECTORY
│   │   └── support_page.dart
│   ├── referral/                 # NEW DIRECTORY
│   │   └── referral_page.dart
│   └── community/
│       ├── community_page.dart
│       ├── group_chat_page.dart
│       ├── group_detail_page.dart  # TODO: Create
│       └── widgets/
└── shared/
    └── widgets/
        ├── cooking_session_sheet.dart  # TODO: Create
        └── journaling_sheet.dart       # TODO: Create
```

---

## Design System Compliance Checklist

For each page audit, verify:

- [ ] Uses `AkeliColors` tokens (no hardcoded hex values)
- [ ] Uses `GoogleFonts.plusJakartaSans` for headlines
- [ ] Uses `GoogleFonts.inter` for body text
- [ ] Uses `AkeliRadius.*` for border radius
- [ ] Uses `AkeliShadows.sm/md/lg` for shadows
- [ ] Implements logging standard (dispose, build entry, userAction)
- [ ] Removes comment banners (`// ═══`, `// ───`)
- [ ] Matches stitch layout structure
- [ ] Responsive for mobile-first design

---

## Next Steps

1. **Prioritize missing pages** by user impact and compliance needs
2. **Create plan files** for each missing page following tracker workflow
3. **Execute redesigns** wave by wave as documented in `organic-editorial-tracker.md`
4. **Update this audit** after each wave completion

---

**Audit Completed By:** AI Assistant  
**Verification Method:** Automated file system scan + manual cross-reference with organic-editorial-tracker.md
