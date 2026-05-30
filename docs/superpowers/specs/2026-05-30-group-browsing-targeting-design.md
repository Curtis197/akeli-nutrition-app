# Group Browsing & Demographic Targeting — Design Spec
**Date:** 2026-05-30  
**Status:** Approved  
**Sub-project:** 2 of 3 (Invitations → Browsing → Vector Discovery)

---

## Overview

Users can discover and instantly join public groups from a dedicated browse page. Group admins can tag their group with a food region, language, and topic to improve discoverability. A max member count can optionally be set. Sub-project 3 (vector recommendations) depends on this schema being in place.

---

## Data Model

### Migration: add targeting columns to `community_group`

```sql
ALTER TABLE community_group
  ADD COLUMN region_id   uuid REFERENCES food_region(id),
  ADD COLUMN language    text,
  ADD COLUMN topic       text CHECK (topic IN (
                           'cuisine_africaine', 'batch_cooking', 'nutrition',
                           'sport_forme', 'perte_de_poids', 'vegetarien', 'autre'
                         )),
  ADD COLUMN max_members int;  -- null = unlimited
```

`language` uses the same locale values as `user_profile.locale`: `fr | en | es | pt | wo | bm | ln`.

All four columns are nullable — groups created before this migration are unaffected. Admins set them via the edit sheet.

### Migration: `member_count` triggers

`member_count` already exists on `community_group`. Add increment/decrement triggers:

```sql
CREATE OR REPLACE FUNCTION _increment_group_member_count()
RETURNS TRIGGER LANGUAGE plpgsql AS $$
BEGIN
  UPDATE community_group SET member_count = member_count + 1 WHERE id = NEW.group_id;
  RETURN NEW;
END;
$$;

CREATE OR REPLACE FUNCTION _decrement_group_member_count()
RETURNS TRIGGER LANGUAGE plpgsql AS $$
BEGIN
  UPDATE community_group SET member_count = GREATEST(member_count - 1, 0) WHERE id = OLD.group_id;
  RETURN OLD;
END;
$$;

CREATE TRIGGER trg_group_member_count_inc
  AFTER INSERT ON group_member
  FOR EACH ROW EXECUTE FUNCTION _increment_group_member_count();

CREATE TRIGGER trg_group_member_count_dec
  AFTER DELETE ON group_member
  FOR EACH ROW EXECUTE FUNCTION _decrement_group_member_count();
```

### New RLS policy: instant join for public groups

```sql
CREATE POLICY "user joins public group" ON group_member
  FOR INSERT WITH CHECK (
    user_id = auth.uid() AND
    EXISTS (
      SELECT 1 FROM community_group cg
      WHERE cg.id = group_member.group_id
        AND cg.is_public = true
        AND (cg.max_members IS NULL OR cg.member_count < cg.max_members)
    )
  );
```

No new RLS needed on `community_group` SELECT — the existing `"public reads public groups"` policy (`is_public = true`) already covers browse queries.

---

## Flutter

### Browse page

**Route:** `/groups/browse` — new `GoRoute` in `router.dart`  
**Navigation:** Search/discover icon button in the Community tab AppBar  
**File:** `lib/features/community/browse_groups_page.dart`

### Provider: `browseGroupsProvider`

```dart
class BrowseGroupsParams {
  final String? regionId;
  final String? language;
  final String? topic;
  // Equality + hashCode for provider family key
}

final browseGroupsProvider =
    FutureProvider.autoDispose.family<List<Map<String, dynamic>>, BrowseGroupsParams>(
  (ref, params) async {
    // SELECT id, name, description, member_count, max_members,
    //        region_id, language, topic,
    //        food_region:region_id(name)
    // FROM community_group
    // WHERE is_public = true
    // [+ optional .eq filters]
    // ORDER BY member_count DESC
    // LIMIT 50
  }
);
```

### Page layout

```
AppBar: "Découvrir des groupes"   [← back]
────────────────────────────────────────────────
Horizontal scrollable filter chips:
  [Région ▾]  [Langue ▾]  [Sujet ▾]  [Effacer]
  (Effacer only shown when ≥1 filter active)
────────────────────────────────────────────────
ListView.builder — GroupBrowseCard per group:
  ┌──────────────────────────────────────────┐
  │ Nom du groupe              [Rejoindre]   │
  │ Description (max 2 lines, ellipsis)      │
  │ 🌍 Région · 🌐 Langue · 📌 Sujet        │
  │ 👥 N membres  (/ max if set)             │
  └──────────────────────────────────────────┘
────────────────────────────────────────────────
Empty state: "Aucun groupe trouvé — essayez d'autres filtres"
```

Filter chips open `showModalBottomSheet` pickers (same pattern as preference selectors). Active filter chips show filled/colored style. Re-querying happens on each filter change (provider family key changes).

**"Rejoindre" button states:**
- Default: "Rejoindre" (enabled)
- Loading: CircularProgressIndicator
- Success: "Membre ✓" (disabled, green)
- Full: "Complet" (disabled, grey) — shown when `member_count >= max_members`
- Already member: "Membre ✓" (disabled) — detected by checking against `communityGroupsProvider`

### Join flow (Flutter client, no edge function)

Sequential writes, both covered by RLS:

1. INSERT `group_member { group_id, user_id, role: 'member' }` — `ON CONFLICT DO NOTHING`
2. SELECT `conversation.id WHERE community_group_id = group_id AND type = 'creator_group'`
3. INSERT `conversation_participant { conversation_id, user_id }`

On success: invalidate `browseGroupsProvider` + `communityGroupsProvider`.  
On partial failure (step 3 fails after step 1 succeeds): log RLS warning, show snackbar "Rejoindre a partiellement réussi — réessayez".

---

## Edit Sheet Updates

`_EditGroupSheet` in `group_chat_page.dart` gains four new fields below the public/private toggle:

| Field | Widget | Data source |
|---|---|---|
| Région | DropdownButtonFormField | `food_region` table via new `foodRegionsProvider` (or reuse existing) |
| Langue | DropdownButtonFormField | Hardcoded map: `fr→Français, en→English, es→Español, pt→Português, wo→Wolof, bm→Bambara, ln→Lingala` |
| Sujet | DropdownButtonFormField | Hardcoded map of 7 topics + Autre |
| Membres max | TextFormField (number) | Empty = illimité |

`groupDetailsProvider` select updated to include: `region_id, language, topic, max_members`.  
`updateGroup()` payload updated to include the four new fields.  
`createGroup()` unchanged — all new fields default to null at creation.

---

## Error Handling

| Scenario | Handling |
|---|---|
| Browse query fails | Error widget + "Réessayer" button |
| No results for active filters | Empty state: "Aucun groupe trouvé — essayez d'autres filtres" |
| Join blocked — group full (RLS 42501) | Snackbar "Ce groupe est complet" |
| Join blocked — other RLS | Snackbar "Impossible de rejoindre ce groupe" |
| `group_member` conflict (already member) | `ON CONFLICT DO NOTHING` — treated as success |
| `conversation_participant` fails after `group_member` succeeds | RLS warning logged, snackbar "Rejoindre a partiellement réussi — réessayez" |
| Food regions fail to load | Dropdown shows empty, field optional — save still works |
| Edit save fails | Inline error in sheet, user can retry |

---

## Files to Create / Modify

| File | Action |
|---|---|
| `supabase/migrations/YYYYMMDD_group_targeting.sql` | Add columns, triggers, RLS policy |
| `lib/features/community/browse_groups_page.dart` | New page |
| `lib/core/router.dart` | Add `/groups/browse` route |
| `lib/features/community/community_page.dart` | Add discover icon to AppBar |
| `lib/providers/dm_provider.dart` | Add `browseGroupsProvider` + `BrowseGroupsParams` |
| `lib/features/community/group_chat_page.dart` | Extend `_EditGroupSheet` with 4 new fields + update `groupDetailsProvider` select + `updateGroup()` payload |

---

## Out of Scope

- Sub-project 1 (invitations) — separate spec
- Sub-project 3 (vector recommendations) — depends on this spec's schema, separate spec
- Group search by name (text search) — deferred to sub-project 3
- Multiple topics per group — deferred, single topic sufficient for V1
