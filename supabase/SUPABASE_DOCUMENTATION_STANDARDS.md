# AKELI - Supabase Documentation Standards

## 🚨 CRITICAL RULE #1: SUPABASE FOLDER IS SOURCE OF TRUTH - ALWAYS UP TO DATE

**Every modification to the Supabase backend MUST be documented immediately in the Supabase folder.**

This is not optional. The Supabase folder is the **single source of truth** for the entire backend.

---

## 🚨 CRITICAL RULE #2: TRAFFIC FROM DAY ONE - PERFORMANCE IS MANDATORY

**The app MUST be ready for production traffic from launch.**

There is no "we'll optimize later." Performance decisions are baked in from the start.

### Core Principle: Client Does Simple, Backend Does Complex

| Client-Side (Flutter/Dart) | Backend (Supabase SQL/Edge Functions) |
|-----------|-----------|
| Simple SELECT with no joins | JOINs across multiple tables |
| Single table fetch by ID | Complex WHERE with multiple conditions |
| Display data as-is | Aggregations (COUNT, SUM, AVG, GROUP BY) |
| Local caching of static data | Pagination (LIMIT/OFFSET or cursor-based) |
| Form state management | Filtering and sorting on multiple columns |
| Simple validation | Full-text search and text matching |
| | Vector similarity (pgvector cosine similarity) |
| | Data transformations and denormalization |
| | Batch operations |
| | Rate limiting enforcement |
| | External API calls (Stripe, OpenAI, FCM) |
| | Revenue computation |
| | Recommendation engines |

### ✅ RULE: If it involves ANY of the following, it goes to the backend:

1. **JOINs** - Any query joining 2+ tables → SQL function or Edge Function
2. **Aggregations** - COUNT, SUM, AVG, MAX, MIN, GROUP BY → SQL function
3. **Pagination** - Any paginated list → SQL function with LIMIT/OFFSET or cursor
4. **Full-text search** - ILIKE, similarity, ranking → SQL function
5. **Vector operations** - Cosine similarity, embeddings → pgvector SQL function
6. **Complex filtering** - Multiple AND/OR conditions with subqueries → SQL function
7. **External API calls** - Stripe, OpenAI, FCM, Google Play → Edge Function
8. **Business logic computation** - Revenue, Fan mode limits, quotas → Edge Function
9. **Batch operations** - Bulk insert/update/delete → SQL function or Edge Function
10. **Data that benefits from caching** - Feed recommendations, creator profiles → Edge Function with cache

### ❌ RULE: Keep on client-side ONLY:

1. **Simple single-table fetches** - `supabase.from('table').select().eq('id', id)`
2. **Static reference data** - Already cached (regions, categories, units, tags)
3. **User's own profile updates** - Simple upserts
4. **Form validation** - Local before submission
5. **UI state** - Loading, error, selection states

---

## 📦 Backend Performance Arsenal

### SQL Functions (RPC) - For Complex Queries

Use `SECURITY DEFINER` functions called via `.rpc()` from Flutter:

```sql
CREATE OR REPLACE FUNCTION complex_feed(
  p_user_id uuid,
  p_limit int DEFAULT 20,
  p_offset int DEFAULT 0,
  p_filter text DEFAULT NULL
)
RETURNS TABLE (
  -- return columns
)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  -- Complex query with JOINs, aggregations, subqueries
  -- RLS is bypassed (SECURITY DEFINER), so filter explicitly
  RETURN QUERY SELECT ...
END;
$$;
```

**When to use SQL Functions:**
- Feed/recommendation queries (existing: `recommend_recipes`)
- Search with multiple filters (existing: `search_recipes`, `search_creators`)
- Aggregated views (creator dashboards, user stats)
- Complex JOINs that would require multiple client-side round-trips
- Pagination with computed fields

**SQL Function requirements:**
- Document parameters and return type
- Include RLS checks manually (since SECURITY DEFINER bypasses RLS)
- Add appropriate indexes for query patterns
- Test with realistic data volumes (not just 10 rows)

### pgvector - For Recommendations & Similarity

Use HNSW indexes for ~3ms cosine similarity on 2500+ records:

```sql
-- Index creation
CREATE INDEX idx_user_vector_hnsw ON user_vector
  USING hnsw (vector vector_cosine_ops) WITH (m = 16, ef_construction = 64);

-- Query with cosine similarity
SELECT r.*, (1 - (rv.vector <=> v_user_vector)) AS similarity
FROM recipe r
JOIN recipe_vector rv ON r.id = rv.recipe_id
ORDER BY similarity DESC
LIMIT 20;
```

**When to use pgvector:**
- Recipe recommendations (existing: `recommend_recipes`)
- Meal plan generation (existing: `generate_meal_plan`)
- Creator similarity (future)
- Content similarity (future)
- Personalization (future)

**pgvector requirements:**
- 50-dimension vectors for users and recipes
- HNSW index with m=16, ef_construction=64
- Compute vectors via Python service on Railway
- Fan mode boost (×1.5) for Fan creator's recipes

### Edge Functions - For External APIs & Business Logic

Use for operations that require:
- External API calls (Stripe, OpenAI, FCM, Google Play, App Store)
- Complex business logic with multiple steps
- Rate limiting enforcement
- Webhook handling
- Cron jobs (monthly revenue, Fan transitions, reminders)

```typescript
// Edge Function pattern
serve(async (req: Request) => {
  const logger = createLogger('function-name');
  const requestId = crypto.randomUUID();
  logger.setRequestId(requestId);
  
  // 1. Auth verification
  const supabase = userClient(req);
  const { user } = await supabase.auth.getUser();
  logger.setUserId(user.id);
  
  // 2. Cache check (if applicable)
  const cached = await getCache(`function-name:${user.id}:${params}`);
  if (cached) {
    logger.debug('Cache hit');
    return ok(cached);
  }
  
  // 3. Business logic
  const result = await doComplexLogic();
  
  // 4. Cache result (if applicable)
  await setCache(`function-name:${user.id}:${params}`, result, { ttl: 300 });
  
  // 5. Return response
  return ok(result);
});
```

**Edge Function requirements:**
- Comprehensive logging (see logging skill)
- Error handling with appropriate HTTP status codes
- CORS support via `_shared/cors.ts`
- Consistent response format via `_shared/response.ts`
- Request correlation (requestId)
- User correlation (userId)

### Caching Strategy

**When to cache:**

| Data Type | Cache Duration | Location |
|-----------|---------------|----------|
| Feed recommendations | 5-15 minutes | Edge Function (Redis/Supabase cache) |
| Creator public profiles | 30-60 minutes | Edge Function |
| Recipe detail (published) | 10-30 minutes | Edge Function |
| Search results | 5-10 minutes | Edge Function |
| Reference data (regions, tags) | 24 hours | Flutter client (static) |
| User's own profile | No cache (always fresh) | N/A |
| Real-time data (notifications) | No cache | N/A |

**Cache invalidation triggers:**
- User updates profile → invalidate user profile cache
- Creator publishes recipe → invalidate creator profile cache, feed cache
- Recipe gets new likes → invalidate recipe detail cache, feed cache
- Fan mode activated/cancelled → invalidate recommendation cache

**Cache implementation pattern:**

```typescript
// Use Supabase cache_store table (or Redis if available)
async function getCache(key: string): Promise<any | null> {
  const supabase = serviceClient();
  const { data } = await supabase
    .from('cache_store')
    .select('value, expires_at')
    .eq('key', key)
    .single();
  
  if (data && new Date(data.expires_at) > new Date()) {
    return data.value;
  }
  return null;
}

async function setCache(key: string, value: any, ttlSeconds: number = 300) {
  const supabase = serviceClient();
  const expiresAt = new Date(Date.now() + ttlSeconds * 1000);
  
  await supabase.from('cache_store').upsert({
    key,
    value,
    expires_at: expiresAt.toISOString(),
  }, { onConflict: 'key' });
}
```

**Optional: Create cache_store table for Edge Function caching:**

```sql
-- Migration: YYYYMMDDNNNNNN_add_cache_store.sql

CREATE TABLE IF NOT EXISTS cache_store (
  key         text PRIMARY KEY,
  value       jsonb NOT NULL,
  expires_at  timestamptz NOT NULL,
  created_at  timestamptz DEFAULT now(),
  updated_at  timestamptz DEFAULT now()
);

-- Index for expired key cleanup
CREATE INDEX idx_cache_store_expires ON cache_store(expires_at);

-- RLS: Only service role can access
ALTER TABLE cache_store ENABLE ROW LEVEL SECURITY;

CREATE POLICY "service manages cache_store" ON cache_store
  FOR ALL USING (auth.role() = 'service_role');

-- Cleanup function (call periodically)
CREATE OR REPLACE FUNCTION cleanup_expired_cache()
RETURNS int
LANGUAGE plpgsql
AS $$
DECLARE
  v_count int;
BEGIN
  WITH deleted AS (
    DELETE FROM cache_store WHERE expires_at < now()
    RETURNING id
  )
  SELECT COUNT(*) INTO v_count FROM deleted;
  RETURN v_count;
END;
$$;
```

---

## 📐 Architecture Decision Framework

### When building a new feature, ask these questions in order:

1. **Does this require JOINs?**
   - YES → SQL Function (RPC)
   - NO → Continue

2. **Does this require aggregations (COUNT, SUM, AVG)?**
   - YES → SQL Function (RPC)
   - NO → Continue

3. **Does this return a list with pagination?**
   - YES → SQL Function with LIMIT/OFFSET or cursor
   - NO → Continue

4. **Does this call external APIs (Stripe, OpenAI, FCM)?**
   - YES → Edge Function
   - NO → Continue

5. **Does this involve complex business logic (multiple steps, conditions)?**
   - YES → Edge Function
   - NO → Continue

6. **Does this benefit from caching (expensive computation, repeated access)?**
   - YES → Edge Function with cache OR SQL Function + Edge Function cache layer
   - NO → Continue

7. **Is this a simple single-table fetch for the user's own data?**
   - YES → Client-side `supabase.from('table').select()`
   - NO → Go back to question 1

---

## 🚀 Performance Checklist for New Features

### Before deploying ANY feature:

- [ ] **Complex queries** moved to SQL functions (RPC) if they involve JOINs, aggregations, or pagination
- [ ] **External API calls** moved to Edge Functions
- [ ] **Business logic** with multiple steps moved to Edge Functions
- [ ] **Expensive computations** cached with appropriate TTL
- [ ] **pgvector indexes** created for any new vector tables
- [ ] **Database indexes** created for all query patterns (JOIN columns, WHERE columns, ORDER BY columns)
- [ ] **N+1 queries** eliminated (use JOINs or batch queries)
- [ ] **Pagination** implemented (never return ALL rows)
- [ ] **Rate limiting** implemented for user-facing Edge Functions
- [ ] **Error handling** returns appropriate HTTP status codes
- [ ] **Logging** comprehensive in all Edge Functions and SQL functions
- [ ] **RLS policies** created and tested for all new tables
- [ ] **Documentation** updated (rls-list.md, EDGE_FUNCTIONS.md, database_schema.sql)

### Performance Targets:

| Operation | Target | Test Condition |
|-----------|--------|---------------|
| Feed load | < 500ms | 1000+ recipes |
| Search results | < 300ms | Full-text search |
| Recipe detail | < 200ms | Single fetch |
| Creator dashboard | < 500ms | Aggregated revenue data |
| Meal plan generation | < 2000ms | 7 days x 3 meals |
| Like toggle | < 200ms | Single mutation |

---

## What Must Be Kept Up to Date

### 1. `supabase/migrations/` - Migration Files
- **Every schema change** gets a new migration file
- **Naming convention**: `YYYYMMDDNNNNNN_description.sql` (YYYYMMDD + sequential number)
- **Must include**: RLS policies, indexes, triggers, functions, grants
- **Must NOT**: Assume previous migrations exist (use `IF NOT EXISTS`, `IF EXISTS`)
- **Never modify** existing migration files (they are immutable once deployed)

### 2. `supabase/rls-list.md` - RLS Policy Registry
- **Every RLS policy** added/modified/removed must be listed here
- **Must include**: Table name, policy name, operation, condition, migration source
- **Must flag**: Known bugs, potential issues, policy conflicts
- **Must update**: After every migration that touches RLS

### 3. `supabase/database_schema.sql` - Complete Schema Snapshot
- **Current state** of ALL tables, columns, constraints, indexes
- **Must reflect** the state after ALL migrations have been applied
- **Must include**: Comments noting potential issues or bugs
- **Must update**: After every schema change
- **Format**: Full CREATE TABLE statements in dependency order

### 4. `supabase/functions/` - Edge Functions
- **Every edge function** must have its code in its own folder
- **Shared code** goes in `_shared/` folder
- **Every function** must be documented (see edge functions documentation)
- **Environment variables** must be listed in `.env.example`

### 5. `supabase/seed/` - Seed Data
- **Reference data** (regions, categories, units, tags) goes here
- **Must use** `ON CONFLICT DO NOTHING` for idempotent inserts
- **Must update**: When reference data changes

---

## When to Update Documentation

### IMMEDIATELY (same commit as the change):

| Action | Documentation to Update |
|--------|------------------------|
| Create migration | `migrations/` (new file), `rls-list.md` (if RLS changed), `database_schema.sql` |
| Add RLS policy | `rls-list.md` |
| Modify table schema | `database_schema.sql` |
| Add edge function | `functions/` folder, update edge function docs |
| Add env var | `.env.example` |
| Add seed data | `seed/` folder |
| Add SQL function (RPC) | Update migration, `database_schema.sql`, note in `EDGE_FUNCTIONS.md` |
| Add index for performance | Update migration, `database_schema.sql` |
| Add cache layer | Update migration (cache_store table), `database_schema.sql` |

### AT END OF SESSION (before committing):

| Action | Documentation to Update |
|--------|------------------------|
| Multiple migrations | Verify ALL docs are consistent |
| Refactor edge functions | Update function docs |
| Fix RLS bug | Update `rls-list.md` known issues section |
| Deprecate table/function | Mark as deprecated in docs |
| Performance optimization | Note in migration, update performance targets if changed |

---

## Documentation Standards

### Migration Files

```sql
-- =============================================================================
-- AKELI V1 — Migration: [Description]
-- Migration: YYYYMMDDNNNNNN_description.sql
-- Author: [Your Name]
-- Date: YYYY-MM-DD
-- Reason: Why this migration is needed
-- Impact: What tables/columns/policies are affected
-- Performance: Indexes added, queries optimized for X rows
-- Backwards compatible: YES/NO (if NO, explain migration order requirements)
-- =============================================================================

-- Migration SQL here
```

**Requirements:**
- Clear header with metadata
- Comments explaining WHY each change is made
- Comments flagging any potential issues
- Use `IF NOT EXISTS` / `IF EXISTS` / `CASCADE` as appropriate
- Test both forward migration and rollback (if reversible)
- Add indexes for all query patterns (JOIN columns, WHERE columns, ORDER BY columns)

### RLS List Updates

When adding a new policy:

```markdown
### `table_name`
| Policy Name | Operation | Condition | Migration | Notes |
|-------------|-----------|-----------|-----------|-------|
| policy_name | SELECT/INSERT/UPDATE/DELETE/ALL | SQL condition | YYYYMMDDNNNNNN | Which function requires this |
```

When fixing a bug:

```markdown
### ⚠️ KNOWN ISSUES

**Issue number**: Description
- **Table**: table_name
- **Policy**: policy_name
- **Issue**: What's wrong
- **Impact**: What breaks
- **Migration**: YYYYMMDDNNNNNN
- **Fix**: How to fix it
- **Status**: OPEN / IN PROGRESS / FIXED
```

### Database Schema Updates

When updating `database_schema.sql`:

```sql
-- Table: table_name
-- Description: What this table stores
-- RLS: ENABLED/DISABLED
-- Key columns: id (uuid), user_id (uuid FK), created_at (timestamptz)
-- Indexes: idx_name ON table(column)
-- Notes: Any special considerations

CREATE TABLE IF NOT EXISTS table_name (
  -- columns here
);

-- Indexes
CREATE INDEX IF NOT EXISTS idx_name ON table_name(column);

-- RLS
ALTER TABLE table_name ENABLE ROW LEVEL SECURITY;
-- Policies listed in rls-list.md
```

**Requirements:**
- Tables in dependency order (referenced tables first)
- All columns listed with types and constraints
- All foreign keys noted
- All indexes listed
- RLS status noted
- Comments for non-obvious design decisions

### Edge Function Documentation

Each edge function must have a header comment:

```typescript
// =============================================================================
// AKELI Edge Function: function-name
// Path: supabase/functions/function-name/index.ts
// Author: [Your Name]
// Date: YYYY-MM-DD
//
// Purpose: What this function does
// Auth: verify_jwt = true/false (see config.toml)
//
// Request: POST/GET with body { ... }
// Response: { success: true, data: ... } or { error: "message" }
//
// Tables: table1, table2, table3 (read/write)
// RLS: userClient (RLS enforced) or serviceClient (RLS bypassed)
//
// External APIs: Stripe, OpenAI, FCM, etc. (if any)
//
// Caching: YES (TTL: 300s) / NO
// Cache invalidation: On [event]
//
// Error handling: What errors are caught and how they're handled
// =============================================================================
```

---

## 🔒 SECURITY DOCUMENTATION RULES

### What to Document (Never Secrets):
- ✅ Table names and column names
- ✅ RLS policies and conditions
- ✅ Edge function endpoints and request/response formats
- ✅ Environment variable NAMES (not values)
- ✅ Migration order and dependencies
- ✅ Known bugs and potential issues
- ✅ Performance characteristics (indexes, query patterns, cache TTLs)

### What to NEVER Document:
- ❌ Actual environment variable values (API keys, secrets)
- ❌ Database connection strings
- ❌ Service role keys
- ❌ User data or PII
- ❌ Passwords or tokens

---

## 🚨 CRITICAL RULE #3: ANNOTATE EVERYTHING - ZERO GUESSING

**Every table, column, SQL function, RLS policy, Edge Function, Flutter page, widget, and provider MUST be extensively annotated.**

There is no "this is obvious, no comment needed." Everything gets annotated.

### Database Annotations (PostgreSQL COMMENT)

Every table and column MUST have a PostgreSQL COMMENT:

```sql
-- In migration files:
COMMENT ON TABLE table_name IS 'ROLE: ... | PURPOSE: ... | USAGE: ...';
COMMENT ON COLUMN table_name.column_name IS 'Description | Used by: ... | Notes: ...';
COMMENT ON FUNCTION function_name IS 'ROLE: ... | PURPOSE: ... | RETURNS: ... | SECURITY: ...';
COMMENT ON POLICY policy_name ON table_name IS 'ROLE: ... | Required by: ...';
```

**What to annotate:**
- ✅ Every table: ROLE, PURPOSE, USAGE
- ✅ Every key column: Description, used by, notes
- ✅ Every SQL function (RPC): ROLE, PURPOSE, RETURNS, ALGORITHM, SECURITY
- ✅ Every RLS policy: ROLE, required by
- ✅ Every trigger: ROLE, when fired, purpose
- ✅ Every extension: What it's for

**Where annotations live:**
1. PostgreSQL COMMENT (in migration files) - visible in Supabase Studio, psql \d+
2. `rls-list.md` - RLS policy registry
3. `EDGE_FUNCTIONS.md` - Edge function registry
4. `PROJECT_PLAN.md` - Master index of everything
5. Code comments in migration headers

### Edge Function Annotations

Every Edge Function MUST have a header comment:

```typescript
// =============================================================================
// AKELI Edge Function: function-name
// Path: supabase/functions/function-name/index.ts
// 
// ROLE: What this function does in the system
// PURPOSE: Why it exists, the problem it solves
// USAGE: Who calls it, when
// Auth: verify_jwt = true/false
// 
// Request: POST/GET with body { ... }
// Response: { success: true, data: ... } or { error: "message" }
// 
// Tables: table1, table2 (read/write)
// RLS: userClient or serviceClient
// External APIs: Stripe, OpenAI, FCM (if any)
// Caching: YES/NO (TTL if YES)
// Error handling: What errors are caught
// =============================================================================
```

### Flutter Component Annotations

Every page, widget, provider, and service MUST have annotations.

**File header:**
```dart
// =============================================================================
// AKELI - [Component Type]: [Component Name]
// Path: lib/[path]/[file].dart
// 
// ROLE: What it does in the system
// PURPOSE: Why it exists, the problem it solves
// USAGE: How it's used, who calls it
// DATA SOURCE: Where data comes from (provider, RPC, EF, local)
// NAVIGATION: What screens it navigates to (if page)
// DEPENDENCIES: What providers/services it relies on
// NOTES: Important caveats, performance considerations
// =============================================================================
```

**Class annotation:**
```dart
/// [Class name]
/// 
/// ROLE: What this class does
/// PURPOSE: Why this class exists
/// USAGE: How this class is used
class MyClass { ... }
```

**Method annotation:**
```dart
/// [Method name]
/// 
/// ROLE: What this method does
/// PURPOSE: Why this method exists
/// USAGE: How this method is called
/// DATA: What data it operates on
void myMethod() { ... }
```

**Provider annotation:**
```dart
/// [Provider name]
/// 
/// ROLE: What data this provides
/// PURPOSE: Why this provider exists
/// USAGE: How this provider is watched/read
/// DATA SOURCE: Where data comes from
/// BACKEND: Whether client-side or RPC/Edge Function
final myProvider = FutureProvider(...);
```

### Annotation Standards

**DO:**
- Annotate WHAT something is (ROLE)
- Annotate WHY it exists (PURPOSE)
- Annotate HOW it's used (USAGE)
- Annotate WHERE data comes from (DATA SOURCE)
- Annotate performance considerations (NOTES)
- Annotate bugs and known issues
- Be specific: "Used by complete-onboarding EF" not "used by EF"
- Include table names, function names, column names

**DON'T:**
- Don't say "obvious" - nothing is obvious
- Don't skip annotations because "the code is self-explanatory"
- Don't annotate secrets or sensitive data
- Don't use vague descriptions

### Master Index

**PROJECT_PLAN.md** is the master index of everything:
- Every table with role, purpose, usage, RLS, notes
- Every SQL function with algorithm, security, performance
- Every Edge Function with flow, tables, external APIs
- Every Flutter page with data sources, navigation, dependencies
- Every external service with purpose, cost, env vars

**This document MUST be updated with every new component.**

---

## 📋 DOCUMENTATION CHECKLIST

### After Every Backend Change:

#### Schema Changes:
- [ ] Migration file created with proper header
- [ ] Migration file has comments explaining WHY
- [ ] Migration file uses safe operations (IF NOT EXISTS, etc.)
- [ ] `rls-list.md` updated if RLS policies added/modified
- [ ] `database_schema.sql` updated to reflect new state
- [ ] Known issues section updated if bug found
- [ ] `.env.example` updated if new env var needed
- [ ] Edge function docs updated if function added/modified
- [ ] Indexes added for all query patterns

#### RLS Changes:
- [ ] Policy name is descriptive
- [ ] Policy condition is correct and tested
- [ ] `rls-list.md` updated with new policy
- [ ] Potential bugs flagged in known issues
- [ ] Edge functions that require this policy noted

#### Edge Function Changes:
- [ ] Function has proper header comment
- [ ] Function uses shared helpers (_shared/logger.ts, etc.)
- [ ] Function has logging throughout
- [ ] Error handling is comprehensive
- [ ] Response format is consistent
- [ ] `config.toml` updated if verify_jwt changed
- [ ] `.env.example` updated if new env var needed
- [ ] Function documented in edge functions docs
- [ ] Caching implemented if applicable (with TTL documented)

#### Performance Changes:
- [ ] SQL function (RPC) created for complex queries
- [ ] pgvector index added for vector operations
- [ ] Cache layer added with appropriate TTL
- [ ] Pagination implemented for list endpoints
- [ ] Rate limiting added for user-facing functions
- [ ] N+1 queries eliminated
- [ ] Performance targets met (see checklist above)

---

## 🚨 CONSEQUENCES OF OUTDATED DOCUMENTATION

1. **Cannot verify RLS correctness** - Security holes go unnoticed
2. **Cannot debug efficiently** - Logs tell you WHAT failed, docs tell you WHY it matters
3. **Cannot onboard developers** - New devs can't understand the backend
4. **Cannot deploy safely** - Don't know what will break
5. **Cannot audit security** - Don't know what policies protect what data
6. **Cannot optimize performance** - Don't know what's already indexed, cached, or optimized
7. **Waste time and tokens** - Re-deriving what's already known

---

## 📁 FOLDER STRUCTURE (MUST BE MAINTAINED)

```
supabase/
├── config.toml                      # Edge function JWT config - UPDATE when functions added
├── database_schema.sql              # Complete schema snapshot - UPDATE after every schema change
├── rls-list.md                      # RLS policy registry - UPDATE after every RLS change
├── SUPABASE_DOCUMENTATION_STANDARDS.md  # This file - UPDATE when process changes
├── EDGE_FUNCTIONS.md                # Edge function registry - UPDATE after every function change
│
├── migrations/                      # Migration files - APPEND ONLY, never modify existing
│   ├── YYYYMMDDNNNNNN_description.sql
│   └── ...
│
├── seed/                            # Seed/reference data
│   └── 01_reference_data.sql        # UPDATE when reference data changes
│
├── functions/
│   ├── .env.example                 # UPDATE when env vars change
│   ├── _shared/                     # Shared library code
│   │   ├── cors.ts
│   │   ├── logger.ts
│   │   ├── response.ts
│   │   └── supabase.ts
│   ├── _examples/                   # Examples and templates
│   │   └── complete-onboarding-logged.ts
│   │
│   └── [function-name]/             # One folder per edge function
│       └── index.ts                 # Function code with header comment
│
└── .temp/                           # CLI cache (gitignored)
    └── cli-latest
```

---

## 🔄 UPDATE PROCESS

### When Creating a New Migration:

1. **Create migration file**:
   ```bash
   supabase migration new description
   ```
   Or manually: `supabase/migrations/YYYYMMDDNNNNNN_description.sql`

2. **Write migration** with:
   - Header comment (template above)
   - SQL with explanatory comments
   - Safe operations (IF NOT EXISTS, etc.)
   - RLS policies if applicable
   - Indexes for query patterns

3. **Test migration**:
   ```bash
   supabase db reset
   supabase db push
   ```

4. **Update documentation**:
   - [ ] `rls-list.md` if RLS changed
   - [ ] `database_schema.sql` to reflect new state
   - [ ] Known issues if bug found
   - [ ] This document if process changed

5. **Commit everything together**:
   ```bash
   git add supabase/
   git commit -m "migration: add table_name with RLS policies

   - Create table_name with columns X, Y, Z
   - Add RLS policies for owner, public, creator access
   - Add indexes on JOIN and WHERE columns
   - Update rls-list.md with new policies
   - Update database_schema.sql snapshot
   - Flag potential issue: column X may conflict with Y"
   ```

---

## 📊 DOCUMENTATION METRICS

| Document | Current Status | Last Updated | Next Review |
|----------|---------------|--------------|-------------|
| `rls-list.md` | ✅ Complete (80+ policies, known issues flagged) | 2026-04-13 | Before next RLS change |
| `database_schema.sql` | ✅ Header added with migration order and known issues | 2026-04-13 | After every schema change |
| `EDGE_FUNCTIONS.md` | ✅ Complete (16 functions documented) | 2026-04-13 | After every function change |
| `.env.example` | ✅ Exists | TBD | When env vars change |
| Seed data | ✅ Exists | TBD | When reference data changes |
| `SUPABASE_DOCUMENTATION_STANDARDS.md` | ✅ Current (performance rules added) | 2026-04-13 | When process changes |

---

**Version**: 2.0.0 - PERFORMANCE + DOCUMENTATION  
**Created**: 2026-04-13  
**Updated**: 2026-04-13  
**Maintainer**: Akeli Dev Team  
**Principle**: Supabase folder is source of truth - always up to date. Traffic-ready from day one.
