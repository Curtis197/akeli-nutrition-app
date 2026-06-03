# Group Vector Recommendations — Design Spec
**Date:** 2026-05-30  
**Status:** Approved  
**Sub-project:** 3 of 3 (Invitations → Browsing → Vector Discovery)  
**Depends on:** Sub-project 2 (group_browsing-targeting-design.md) — requires `community_group` targeting columns and browse page to exist first.

---

## Overview

Groups are vectorized nightly by averaging the `user_vector` of their members. When a user browses groups with no filters active, groups are silently ordered by cosine similarity to the user's own vector — most aligned first. Users with no vector (cold start) fall back to profile-field matching. Personalization is invisible: no "Recommended" label, just better ordering.

---

## Data Model

### New table: `group_vector`

```sql
CREATE TABLE IF NOT EXISTS group_vector (
  group_id             uuid PRIMARY KEY REFERENCES community_group(id) ON DELETE CASCADE,
  vector               vector(50) NOT NULL,
  last_computed        timestamptz NOT NULL DEFAULT now(),
  member_count_sampled int NOT NULL DEFAULT 0
);

CREATE INDEX IF NOT EXISTS idx_group_vector_hnsw
  ON group_vector USING hnsw (vector vector_cosine_ops)
  WITH (m = 16, ef_construction = 64);

ALTER TABLE group_vector ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "service manages group_vector" ON group_vector;
CREATE POLICY "service manages group_vector" ON group_vector
  FOR ALL USING (true);
```

Mirrors `creator_vector` exactly. The `member_count_sampled` column records how many members had vectors at computation time — useful for debugging and future weighting logic.

### New RPC: `generate_groups_personalized`

```sql
CREATE OR REPLACE FUNCTION generate_groups_personalized(
  p_user_id  uuid,
  p_limit    int     DEFAULT 20,
  p_exclude  uuid[]  DEFAULT '{}'
)
RETURNS TABLE (group_id uuid, score numeric)
LANGUAGE plpgsql STABLE SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
  v_user_vector vector(50);
BEGIN
  IF auth.uid() IS DISTINCT FROM p_user_id THEN
    RAISE EXCEPTION 'Unauthorized';
  END IF;

  SELECT uv.vector INTO v_user_vector
  FROM user_vector uv WHERE uv.user_id = p_user_id;

  -- Cold start: fallback to profile field matching
  IF v_user_vector IS NULL THEN
    RETURN QUERY
    SELECT cg.id AS group_id, 0::numeric AS score
    FROM community_group cg
    LEFT JOIN user_profile up ON up.id = p_user_id
    WHERE cg.is_public = true
      AND cg.id <> ALL(p_exclude)
      AND (
        cg.language = up.locale
        OR cg.region_id IN (
          SELECT ucp.region::uuid FROM user_cuisine_preference ucp
          WHERE ucp.user_id = p_user_id
        )
      )
    ORDER BY cg.member_count DESC
    LIMIT LEAST(p_limit, 100);
    RETURN;
  END IF;

  -- Personalized path: cosine similarity
  RETURN QUERY
  SELECT
    cg.id                                           AS group_id,
    (1 - (gv.vector <=> v_user_vector))::numeric    AS score
  FROM community_group cg
  JOIN group_vector gv ON gv.group_id = cg.id
  WHERE cg.is_public = true
    AND cg.id <> ALL(p_exclude)
  ORDER BY (gv.vector <=> v_user_vector) ASC
  LIMIT LEAST(p_limit, 100);
END;
$$;
```

Groups without a `group_vector` row are excluded from personalized results via the INNER JOIN — they still appear in filter-based browse queries.

---

## Edge Function: `compute-group-vectors`

**File:** `supabase/functions/compute-group-vectors/index.ts`  
**JWT required:** no — secured via `x-internal-secret` header  
**Schedule:** `0 23 * * 0` (Sunday 23:00 UTC) — after the meal plan batch

**Steps:**
1. `verifyInternalSecret(req)` — return 401 if missing
2. Fetch all `community_group.id WHERE is_public = true` via service client
3. Process in batches of 50 groups to avoid memory spikes:
   ```sql
   SELECT AVG(uv.vector) as avg_vector, COUNT(*) as sampled
   FROM user_vector uv
   JOIN group_member gm ON gm.user_id = uv.user_id
   WHERE gm.group_id = $group_id
   ```
4. If `avg_vector` non-null: UPSERT into `group_vector { group_id, vector, last_computed, member_count_sampled }`
5. If `avg_vector` null (0 vectorized members): skip, log in `skipped`
6. Single group failure: log error, continue batch — do not abort
7. Return `{ computed: N, skipped: M, failed: K, duration_ms: T }`

**CORS:** `handleCors(req)` at top (mandatory — learned from `notify-group-message` incident).

---

## Flutter: Browse Page Integration

`browseGroupsProvider` uses two paths based on filter state:

### Path 1 — No filters active (personalized)
```
1. Call RPC generate_groups_personalized(p_user_id, p_limit: 50)
2. Extract ordered group_ids from result
3. Fetch full community_group rows for those IDs (IN filter)
4. Re-apply RPC order (IN does not preserve order)
5. Return ordered list — most aligned first, silently
```

### Path 2 — Any filter active (explicit)
```
Query community_group directly:
  WHERE is_public = true
  [AND region_id = ?]
  [AND language = ?]
  [AND topic = ?]
  ORDER BY member_count DESC
  LIMIT 50
```

Filters trump personalization — the user expressed an explicit preference.

### `BrowseGroupsParams` (updated from sub-project 2)

```dart
class BrowseGroupsParams {
  final String? userId;    // set = personalized RPC path; null = popularity fallback
  final String? regionId;
  final String? language;
  final String? topic;
  // == and hashCode required for provider family key
}
```

When `userId` is set and all filter fields are null → Path 1 (RPC).  
When any filter field is set → Path 2 (direct query), regardless of `userId`.

### RPC failure fallback

If the RPC call throws, `browseGroupsProvider` catches and falls back to Path 2 with no filters (`ORDER BY member_count DESC`) — browse still works, just unpersonalized.

---

## Error Handling

| Scenario | Handling |
|---|---|
| User has no `user_vector` | Cold start path in RPC — profile-field matching, `score = 0` |
| Group has no `group_vector` | Excluded from RPC (INNER JOIN) — visible in filter path only |
| RPC returns empty | Flutter shows normal empty state, same as no results |
| RPC call fails | Fallback to `member_count DESC` unfiltered browse — no crash |
| Cron: group has 0 vectorized members | Skip silently, count in `skipped` |
| Cron: AVG returns null | Skip that group, continue batch |
| Cron: missing `x-internal-secret` | 401 |
| Cron: individual group computation fails | Log error, continue — don't abort batch |

---

## Files to Create / Modify

| File | Action |
|---|---|
| `supabase/migrations/YYYYMMDD_group_vector.sql` | Create `group_vector` table + HNSW index + RLS + `generate_groups_personalized` RPC |
| `supabase/functions/compute-group-vectors/index.ts` | New cron edge function |
| `lib/providers/dm_provider.dart` | Update `browseGroupsProvider` + `BrowseGroupsParams` to support personalized path |

---

## Deployment Notes

- `group_vector` table will be empty at first deploy — all users see cold start path until first Sunday cron run
- The HNSW index is built at migration time on an empty table — no reindex needed after first batch
- Cron must be registered in Supabase dashboard or via `pg_cron` extension after deployment

---

## Out of Scope

- Real-time vector update on member join/leave (deferred — nightly batch sufficient for V1)
- Multiple topics per group
- Text search within browse
- Group recommendations on creator profiles
