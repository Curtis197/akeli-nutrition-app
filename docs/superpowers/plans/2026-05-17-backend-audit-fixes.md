# Backend Audit Fixes Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Fix all critical and high-priority issues found in the May 2026 backend security and quality audit.

**Architecture:** Fixes span three layers — edge function logic (TypeScript), RLS policies (SQL migrations), and shared infrastructure. Migrations are additive; edge function fixes are in-place edits. Each task is independently deployable.

**Tech Stack:** Supabase Edge Functions (Deno/TypeScript), PostgreSQL RLS, Supabase CLI

---

## File Map

| File | Tasks |
|------|-------|
| `supabase/functions/_shared/supabase.ts` | T1 |
| `supabase/functions/_shared/response.ts` | T11 |
| `supabase/functions/send-push-notification/index.ts` | T1 |
| `supabase/functions/translate-content/index.ts` | T1 |
| `supabase/functions/process-fan-mode-transitions/index.ts` | T1, T4 |
| `supabase/functions/send-meal-reminders/index.ts` | T1, T9 |
| `supabase/functions/compute-monthly-revenue/index.ts` | T1, T3 |
| `supabase/functions/get-creator-dashboard/index.ts` | T5 |
| `supabase/functions/activate-fan-mode/index.ts` | T6 |
| `supabase/functions/cancel-fan-mode/index.ts` | T6 |
| `supabase/functions/stripe-webhook/index.ts` | T7, T11 |
| `supabase/functions/ai-assistant-chat/index.ts` | T8, T12 |
| `supabase/functions/create-checkout-session/index.ts` | T13 |
| `supabase/migrations/20260517000001_fix_recipe_step_rls.sql` | T2 |
| `supabase/migrations/20260517000002_subscription_insert_guard.sql` | T10 |
| `supabase/functions/.env.example` | T1 |

---

## Task 1: Add internal secret auth to all cron/internal edge functions (SEC-01, SEC-02, SEC-03)

`send-push-notification`, `translate-content`, `process-fan-mode-transitions`, `send-meal-reminders`, and `compute-monthly-revenue` have zero authentication — any internet caller can invoke them.

**Files:**
- Modify: `supabase/functions/_shared/supabase.ts`
- Modify: `supabase/functions/send-push-notification/index.ts`
- Modify: `supabase/functions/translate-content/index.ts`
- Modify: `supabase/functions/process-fan-mode-transitions/index.ts`
- Modify: `supabase/functions/send-meal-reminders/index.ts`
- Modify: `supabase/functions/compute-monthly-revenue/index.ts`
- Modify: `supabase/functions/.env.example`

- [ ] **Step 1: Add `verifyInternalSecret()` helper to `_shared/supabase.ts`**

Replace the entire file with:

```typescript
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const SUPABASE_URL = Deno.env.get("SUPABASE_URL")!;
const SUPABASE_ANON_KEY = Deno.env.get("SUPABASE_ANON_KEY")!;
const SUPABASE_SERVICE_KEY = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
const INTERNAL_SECRET = Deno.env.get("INTERNAL_SECRET")!;

// Client authentifié par le JWT de l'utilisateur (RLS actif)
export function userClient(authHeader: string) {
  return createClient(SUPABASE_URL, SUPABASE_ANON_KEY, {
    global: { headers: { Authorization: authHeader } },
  });
}

// Client service — bypass RLS, réservé aux cron + webhooks internes
export function serviceClient() {
  return createClient(SUPABASE_URL, SUPABASE_SERVICE_KEY, {
    auth: { persistSession: false },
  });
}

// Vérifie le JWT et retourne l'utilisateur, ou null si invalide
export async function getAuthUser(req: Request) {
  const authHeader = req.headers.get("Authorization");
  if (!authHeader) return { user: null, client: null };

  const client = userClient(authHeader);
  const { data: { user }, error } = await client.auth.getUser();
  if (error || !user) return { user: null, client: null };

  return { user, client };
}

// Vérifie le header x-internal-secret pour les fonctions internes/cron.
// Retourne true si valide, false sinon.
export function verifyInternalSecret(req: Request): boolean {
  const secret = req.headers.get("x-internal-secret");
  return !!secret && secret === INTERNAL_SECRET;
}
```

- [ ] **Step 2: Add `INTERNAL_SECRET` to `.env.example`**

Append to the bottom of `supabase/functions/.env.example`:

```
# Internal secret — partagé entre les cron jobs Supabase et les Edge Functions internes
# Génère avec: openssl rand -hex 32
INTERNAL_SECRET=your-internal-secret-here
```

- [ ] **Step 3: Add auth check to `send-push-notification/index.ts`**

Replace the `serve(async (req) => {` block opening with:

```typescript
serve(async (req) => {
  try {
    if (!verifyInternalSecret(req)) {
      return new Response(JSON.stringify({ error: "Unauthorized" }), { status: 401 });
    }

    const body = await req.json();
```

Full updated file:

```typescript
// Appel interne uniquement (service key)
// Envoi de push notification FCM + insert dans notification table
import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { ok, err, serverError } from "../_shared/response.ts";
import { serviceClient, verifyInternalSecret } from "../_shared/supabase.ts";

const FCM_SERVER_KEY = Deno.env.get("FCM_SERVER_KEY")!;
const FCM_URL = "https://fcm.googleapis.com/fcm/send";

serve(async (req) => {
  try {
    if (!verifyInternalSecret(req)) {
      return new Response(JSON.stringify({ error: "Unauthorized" }), { status: 401 });
    }

    const body = await req.json();
    const { user_id, title, body: notifBody, data = {}, type = "system" } = body;

    if (!user_id || !title) return err("user_id and title are required");

    const admin = serviceClient();

    // 1. Fetch le push token de l'utilisateur
    const { data: pushToken } = await admin
      .from("push_token")
      .select("token, platform")
      .eq("user_id", user_id)
      .order("updated_at", { ascending: false })
      .limit(1)
      .single();

    // 2. Insert dans notification (in-app center)
    await admin.from("notification").insert({
      user_id,
      type,
      title,
      body: notifBody,
      data,
    });

    // 3. Envoyer via FCM si token disponible
    if (pushToken?.token) {
      const fcmPayload = {
        to: pushToken.token,
        notification: { title, body: notifBody },
        data: { ...data, click_action: "FLUTTER_NOTIFICATION_CLICK" },
        priority: "high",
      };

      const fcmRes = await fetch(FCM_URL, {
        method: "POST",
        headers: {
          "Authorization": `key=${FCM_SERVER_KEY}`,
          "Content-Type": "application/json",
        },
        body: JSON.stringify(fcmPayload),
      });

      if (!fcmRes.ok) {
        console.error("[send-push-notification] FCM error:", await fcmRes.text());
      }
    }

    return ok({ sent: !!pushToken?.token, notification_inserted: true });
  } catch (e) {
    return serverError(e);
  }
});
```

- [ ] **Step 4: Add auth check to `translate-content/index.ts`**

Full updated file:

```typescript
// Traduit du contenu culinaire via Gemini (langues africaines)
// Appel interne uniquement — pas exposé directement à l'app
import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { ok, err, serverError } from "../_shared/response.ts";
import { verifyInternalSecret } from "../_shared/supabase.ts";

const GEMINI_API_KEY = Deno.env.get("GEMINI_API_KEY")!;
const GEMINI_URL =
  "https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent";

const LANGUAGE_NAMES: Record<string, string> = {
  wo: "Wolof",
  bm: "Bambara",
  ln: "Lingala",
  ar: "Arabic",
  fr: "French",
  en: "English",
  es: "Spanish",
  pt: "Portuguese",
};

const MAX_CONTENT_LENGTH = 5000;

serve(async (req) => {
  try {
    if (!verifyInternalSecret(req)) {
      return new Response(JSON.stringify({ error: "Unauthorized" }), { status: 401 });
    }

    const body = await req.json();
    const { content, source_language, target_language } = body;

    if (!content || !source_language || !target_language) {
      return err("content, source_language, and target_language are required");
    }

    if (content.length > MAX_CONTENT_LENGTH) {
      return err(`content must be ${MAX_CONTENT_LENGTH} characters or fewer`);
    }

    const sourceName = LANGUAGE_NAMES[source_language] ?? source_language;
    const targetName = LANGUAGE_NAMES[target_language] ?? target_language;

    const prompt = `You are a professional culinary translator specializing in African languages and food culture.
Translate the following culinary content from ${sourceName} to ${targetName}.
Preserve the meaning, cultural context, and food-specific terminology accurately.
Return ONLY the translated text, nothing else.

Content to translate:
${content}`;

    const geminiRes = await fetch(`${GEMINI_URL}?key=${GEMINI_API_KEY}`, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({
        contents: [{ parts: [{ text: prompt }] }],
        generationConfig: { temperature: 0.2, maxOutputTokens: 1024 },
      }),
    });

    if (!geminiRes.ok) {
      const errText = await geminiRes.text();
      throw new Error(`Gemini error: ${errText}`);
    }

    const geminiData = await geminiRes.json();
    const translation = geminiData.candidates?.[0]?.content?.parts?.[0]?.text;

    if (!translation) throw new Error("Empty translation response from Gemini");

    return ok({
      original: content,
      translation,
      source_language,
      target_language,
    });
  } catch (e) {
    return serverError(e);
  }
});
```

- [ ] **Step 5: Add auth check to `process-fan-mode-transitions/index.ts`**

Full updated file (auth check only — date filter is added in Task 4):

```typescript
// Cron — 1er de chaque mois à 00:05 UTC
// Traite toutes les transitions Mode Fan en attente
import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { ok, serverError } from "../_shared/response.ts";
import { serviceClient, verifyInternalSecret } from "../_shared/supabase.ts";

serve(async (req) => {
  try {
    if (!verifyInternalSecret(req)) {
      return new Response(JSON.stringify({ error: "Unauthorized" }), { status: 401 });
    }

    const admin = serviceClient();

    const today = new Date().toISOString().split("T")[0];

    // Activer uniquement les subscriptions dont effective_from est aujourd'hui ou dans le passé
    const { data: toActivate, error: activateError } = await admin
      .from("fan_subscription")
      .update({ status: "active" })
      .eq("status", "pending")
      .lte("effective_from", today)
      .select("user_id, creator_id");

    if (activateError) throw activateError;
    console.log(`[process-fan-mode-transitions] Activated: ${toActivate?.length ?? 0}`);

    return ok({
      activated: toActivate?.length ?? 0,
    });
  } catch (e) {
    return serverError(e);
  }
});
```

Note: This also covers Task 4 (ARCH-02 date filter fix). Skip Task 4's file edit since it's already done here.

- [ ] **Step 6: Add auth check to `send-meal-reminders/index.ts`**

Full updated file (auth check only — days_of_week fix is in Task 9):

```typescript
// Cron — toutes les heures (0 * * * *)
// Envoie des push notifications pour les rappels repas configurés
import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { ok, serverError } from "../_shared/response.ts";
import { serviceClient, verifyInternalSecret } from "../_shared/supabase.ts";

const SELF_URL = Deno.env.get("SUPABASE_URL")!;
const SERVICE_KEY = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
const INTERNAL_SECRET = Deno.env.get("INTERNAL_SECRET")!;

serve(async (req) => {
  try {
    if (!verifyInternalSecret(req)) {
      return new Response(JSON.stringify({ error: "Unauthorized" }), { status: 401 });
    }

    const admin = serviceClient();

    const now = new Date();
    const currentHour = now.getUTCHours();
    const currentMinute = now.getUTCMinutes();
    // 1=Lundi ... 7=Dimanche (matches days_of_week column convention)
    const currentDayOfWeek = now.getUTCDay() === 0 ? 7 : now.getUTCDay();

    // Fetch les rappels actifs avec days_of_week
    const { data: reminders, error } = await admin
      .from("meal_reminder")
      .select("user_id, meal_type, reminder_time, days_of_week")
      .eq("is_active", true);

    if (error) throw error;

    let sent = 0;

    for (const reminder of reminders ?? []) {
      const [rHour, rMinute] = reminder.reminder_time.split(":").map(Number);
      const diffMinutes = Math.abs(rHour * 60 + rMinute - (currentHour * 60 + currentMinute));

      if (diffMinutes > 5) continue;

      // Skip if today is not in the user's configured days
      const days: number[] = reminder.days_of_week ?? [1, 2, 3, 4, 5, 6, 7];
      if (!days.includes(currentDayOfWeek)) continue;

      const mealLabels: Record<string, string> = {
        breakfast: "Petit-déjeuner",
        lunch: "Déjeuner",
        dinner: "Dîner",
        snack: "Collation",
      };

      // Appel interne à send-push-notification
      await fetch(`${SELF_URL}/functions/v1/send-push-notification`, {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          "x-internal-secret": INTERNAL_SECRET,
        },
        body: JSON.stringify({
          user_id: reminder.user_id,
          title: `⏰ C'est l'heure du ${mealLabels[reminder.meal_type] ?? reminder.meal_type}`,
          body: "Consultez votre plan repas Akeli",
          type: "meal_reminder",
          data: { meal_type: reminder.meal_type },
        }),
      });

      sent++;
    }

    return ok({ checked: reminders?.length ?? 0, sent });
  } catch (e) {
    return serverError(e);
  }
});
```

Note: This also covers Task 9 (API-01 days_of_week fix) and the `is_enabled` → `is_active` bug. Skip Task 9's file edit.

- [ ] **Step 7: Add auth check to `compute-monthly-revenue/index.ts`**

Skip this step — the full fix (including auth + column names) is covered in Task 3.

- [ ] **Step 8: Commit**

```
git add supabase/functions/_shared/supabase.ts
git add supabase/functions/send-push-notification/index.ts
git add supabase/functions/translate-content/index.ts
git add supabase/functions/process-fan-mode-transitions/index.ts
git add supabase/functions/send-meal-reminders/index.ts
git add supabase/functions/.env.example
git commit -m "fix(security): add internal secret auth to all cron and internal edge functions"
```

---

## Task 2: Fix recipe_step RLS policies (RLS-01, RLS-02)

`recipe_step` SELECT checks `r.status = 'published'` (column doesn't exist — should be `r.is_published = true`). The mutate policy checks `r.creator_id = auth.uid()` but `creator_id` is a UUID referencing the `creator` table, not `auth.users`. Both bugs mean recipe steps are broken for all users.

**Files:**
- Create: `supabase/migrations/20260517000001_fix_recipe_step_rls.sql`

- [ ] **Step 1: Create migration**

```sql
-- =============================================================================
-- AKELI V1 — Migration: Fix recipe_step RLS Policies
-- Migration: 20260517000001_fix_recipe_step_rls.sql
-- Fixes RLS-01: SELECT policy references r.status (column doesn't exist)
-- Fixes RLS-02: Mutate policy checks creator_id = auth.uid() (wrong join)
-- =============================================================================

-- DROP the two broken policies created in 20260314000001_recipe_tracking_schema.sql

DROP POLICY IF EXISTS "recipe_step_select_published" ON recipe_step;
DROP POLICY IF EXISTS "recipe_step_mutate_creator" ON recipe_step;

-- Public can read steps of published recipes (uses is_published boolean, not r.status)
CREATE POLICY "recipe_step_select_published" ON recipe_step
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM recipe r
      WHERE r.id = recipe_step.recipe_id
        AND r.is_published = true
    )
  );

-- Only the recipe creator can insert/update/delete steps
-- creator_id on recipe references the creator table (not auth.users),
-- so we must join through creator.user_id to get the auth UUID.
CREATE POLICY "recipe_step_mutate_creator" ON recipe_step
  FOR ALL USING (
    EXISTS (
      SELECT 1 FROM recipe r
      JOIN creator c ON c.id = r.creator_id
      WHERE r.id = recipe_step.recipe_id
        AND c.user_id = auth.uid()
    )
  );
```

- [ ] **Step 2: Verify by checking the policies in Supabase dashboard or via psql**

Expected: two new policies on `recipe_step`, old broken ones gone.

- [ ] **Step 3: Commit**

```
git add supabase/migrations/20260517000001_fix_recipe_step_rls.sql
git commit -m "fix(rls): correct recipe_step SELECT and mutate policies"
```

---

## Task 3: Fix compute-monthly-revenue column names and idempotency (SCH-02, ARCH-01)

The function writes to columns `revenue_type`, `amount`, `logged_at` which don't exist in `creator_revenue_log`. The actual columns are `month_key`, `fan_revenue`, `fan_count`. Balance columns `available_balance`/`lifetime_earnings` don't exist — actual are `balance`/`total_earned`.

**Files:**
- Modify: `supabase/functions/compute-monthly-revenue/index.ts`

- [ ] **Step 1: Rewrite `compute-monthly-revenue/index.ts`**

```typescript
// Cron — 1er de chaque mois à 01:00 UTC (après process-fan-mode-transitions)
// Calcule les revenus de tous les créateurs pour le mois écoulé
import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { ok, serverError } from "../_shared/response.ts";
import { serviceClient, verifyInternalSecret } from "../_shared/supabase.ts";

serve(async (req) => {
  try {
    if (!verifyInternalSecret(req)) {
      return new Response(JSON.stringify({ error: "Unauthorized" }), { status: 401 });
    }

    const admin = serviceClient();

    // Mois écoulé (ex: si on est le 1er mars 2026 → calcule février 2026)
    const prevDate = new Date();
    prevDate.setMonth(prevDate.getMonth() - 1);
    const monthKey = prevDate.toISOString().slice(0, 7); // ex: '2026-02'

    console.log(`[compute-monthly-revenue] Computing revenue for ${monthKey}`);

    // 1. Récupérer tous les créateurs actifs (qui ont des recettes publiées)
    const { data: creators, error: creatorsError } = await admin
      .from("creator")
      .select("id")
      .gt("recipe_count", 0);

    if (creatorsError) throw creatorsError;
    if (!creators?.length) return ok({ month_key: monthKey, creators_processed: 0 });

    // 2. Éviter de recalculer si déjà fait ce mois-ci
    // Uses UNIQUE(creator_id, month_key) constraint on creator_revenue_log
    const { data: alreadyLogged } = await admin
      .from("creator_revenue_log")
      .select("creator_id")
      .eq("month_key", monthKey);

    const alreadyDone = new Set((alreadyLogged ?? []).map((r) => r.creator_id));

    let processedCount = 0;

    for (const { id: creator_id } of creators) {
      if (alreadyDone.has(creator_id)) continue;

      // Fan revenue: nombre de fans actifs ce mois × 1€
      const { count: fanCount } = await admin
        .from("fan_subscription")
        .select("id", { count: "exact" })
        .eq("creator_id", creator_id)
        .eq("status", "active");

      const fans = fanCount ?? 0;
      const fanRevenue = fans * 1.0;

      // Insérer dans creator_revenue_log (colonnes réelles du schéma)
      if (fanRevenue > 0) {
        const { error: logError } = await admin.from("creator_revenue_log").insert({
          creator_id,
          month_key: monthKey,
          fan_revenue: fanRevenue,
          fan_count: fans,
        });
        if (logError) {
          // UNIQUE constraint violation = already processed concurrently, skip
          if (logError.code === "23505") {
            console.log(`[compute-monthly-revenue] ${creator_id} already processed (race), skipping`);
            continue;
          }
          throw logError;
        }
      }

      // Mettre à jour creator_balance (colonnes réelles: balance, total_earned)
      if (fanRevenue > 0) {
        const { data: existing } = await admin
          .from("creator_balance")
          .select("balance, total_earned")
          .eq("creator_id", creator_id)
          .maybeSingle();

        await admin.from("creator_balance").upsert({
          creator_id,
          balance: (existing?.balance ?? 0) + fanRevenue,
          total_earned: (existing?.total_earned ?? 0) + fanRevenue,
          last_updated: new Date().toISOString(),
        });
      }

      processedCount++;
    }

    console.log(
      `[compute-monthly-revenue] Processed ${processedCount}/${creators.length} creators for ${monthKey}`,
    );

    return ok({ month_key: monthKey, creators_processed: processedCount });
  } catch (e) {
    return serverError(e);
  }
});
```

- [ ] **Step 2: Commit**

```
git add supabase/functions/compute-monthly-revenue/index.ts
git commit -m "fix(revenue): correct creator_revenue_log and creator_balance column names"
```

---

## Task 4: Fix process-fan-mode-transitions date filter (ARCH-02)

**Already done in Task 1, Step 5.** The date filter `lte("effective_from", today)` was added when applying the auth check. No additional file change needed.

- [ ] **Step 1: Verify Task 1 Step 5 includes `.lte("effective_from", today)`**

Open `supabase/functions/process-fan-mode-transitions/index.ts` and confirm the update query is:

```typescript
const { data: toActivate, error: activateError } = await admin
  .from("fan_subscription")
  .update({ status: "active" })
  .eq("status", "pending")
  .lte("effective_from", today)
  .select("user_id, creator_id");
```

---

## Task 5: Fix get-creator-dashboard column names (SCH-03)

`creator_balance` is queried for `available_balance`/`lifetime_earnings` — actual columns are `balance`/`total_earned`. `creator_revenue_log` is queried for `revenue_type`/`amount`/`logged_at` — actual columns are `month_key`/`fan_revenue`/`total_revenue`.

**Files:**
- Modify: `supabase/functions/get-creator-dashboard/index.ts`

- [ ] **Step 1: Rewrite `get-creator-dashboard/index.ts`**

```typescript
import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { handleCors } from "../_shared/cors.ts";
import { ok, err, unauthorized, serverError } from "../_shared/response.ts";
import { getAuthUser } from "../_shared/supabase.ts";

serve(async (req) => {
  const corsResponse = handleCors(req);
  if (corsResponse) return corsResponse;

  try {
    const { user, client } = await getAuthUser(req);
    if (!user || !client) return unauthorized();

    const url = new URL(req.url);
    const period = url.searchParams.get("period") ?? "last_3_months";

    // Vérifier que l'utilisateur est un créateur
    const { data: profile } = await client
      .from("user_profile")
      .select("is_creator")
      .eq("id", user.id)
      .single();

    if (!profile?.is_creator) return err("Creator account required", 403);

    // Récupérer le creator_id
    const { data: creator } = await client
      .from("creator")
      .select("id, display_name, recipe_count, fan_count, total_revenue")
      .eq("user_id", user.id)
      .single();

    if (!creator) return err("Creator profile not found", 404);

    const isFanEligible = (creator.recipe_count ?? 0) >= 30;

    // Calculer la plage de mois selon le period
    const now = new Date();
    let monthsBack = 3;
    if (period === "last_6_months") monthsBack = 6;
    if (period === "year_to_date") monthsBack = now.getMonth() + 1;

    const startDate = new Date(now);
    startDate.setMonth(startDate.getMonth() - monthsBack);
    const startMonthKey = startDate.toISOString().slice(0, 7);

    // Revenus sur la période (colonnes réelles: month_key, fan_revenue, total_revenue)
    const { data: revenueLogs } = await client
      .from("creator_revenue_log")
      .select("month_key, fan_revenue, total_revenue")
      .eq("creator_id", creator.id)
      .gte("month_key", startMonthKey)
      .order("month_key", { ascending: false });

    // Grouper par mois pour le graphique historique
    const byMonth: Record<string, { fan_revenue: number; total_revenue: number }> = {};
    for (const log of revenueLogs ?? []) {
      const mk = log.month_key as string;
      if (!byMonth[mk]) byMonth[mk] = { fan_revenue: 0, total_revenue: 0 };
      byMonth[mk].total_revenue += (log.total_revenue as number) ?? 0;
      byMonth[mk].fan_revenue += (log.fan_revenue as number) ?? 0;
    }
    const revenueHistory = Object.entries(byMonth)
      .map(([month_key, v]) => ({ month_key, ...v }))
      .sort((a, b) => b.month_key.localeCompare(a.month_key));

    // Solde créateur (colonnes réelles: balance, total_earned)
    const { data: balance } = await client
      .from("creator_balance")
      .select("balance, total_earned")
      .eq("creator_id", creator.id)
      .maybeSingle();

    return ok({
      creator: {
        id: creator.id,
        display_name: creator.display_name,
        recipe_count: creator.recipe_count,
        fan_count: creator.fan_count,
        is_fan_eligible: isFanEligible,
      },
      balance: balance ?? { balance: 0, total_earned: 0 },
      revenue_history: revenueHistory,
      period,
    });
  } catch (e) {
    return serverError(e);
  }
});
```

- [ ] **Step 2: Commit**

```
git add supabase/functions/get-creator-dashboard/index.ts
git commit -m "fix(dashboard): correct creator_balance and creator_revenue_log column names"
```

---

## Task 6: Fix fan_subscription_history inserts to match schema (SCH-04)

`activate-fan-mode` and `cancel-fan-mode` insert `{subscription_id, status}` into `fan_subscription_history`, but the table has no `subscription_id` column. Actual required columns: `user_id`, `creator_id`, `action`, `month_key`.

**Files:**
- Modify: `supabase/functions/activate-fan-mode/index.ts`
- Modify: `supabase/functions/cancel-fan-mode/index.ts`

- [ ] **Step 1: Rewrite `activate-fan-mode/index.ts`**

```typescript
import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { handleCors } from "../_shared/cors.ts";
import { ok, err, unauthorized, serverError } from "../_shared/response.ts";
import { getAuthUser } from "../_shared/supabase.ts";

function firstOfNextMonth(): string {
  const d = new Date();
  d.setMonth(d.getMonth() + 1, 1);
  return d.toISOString().split("T")[0];
}

serve(async (req) => {
  const corsResponse = handleCors(req);
  if (corsResponse) return corsResponse;

  try {
    const { user, client } = await getAuthUser(req);
    if (!user || !client) return unauthorized();

    const { creator_id } = await req.json();
    if (!creator_id) return err("creator_id is required");

    // 1. Vérifier que l'utilisateur a un abonnement actif
    const { data: sub } = await client
      .from("subscription")
      .select("status")
      .eq("user_id", user.id)
      .single();

    if (!sub || sub.status !== "active") {
      return err("Active subscription required to activate Fan mode", 403);
    }

    // 2. Vérifier que le créateur est éligible (≥ 30 recettes publiées)
    const { data: creator } = await client
      .from("creator")
      .select("is_fan_eligible, display_name")
      .eq("id", creator_id)
      .single();

    if (!creator) return err("Creator not found", 404);
    if (!creator.is_fan_eligible) {
      return err("Creator needs at least 30 published recipes to be Fan-eligible", 403);
    }

    // 3. Vérifier qu'il n'y a pas déjà un Fan actif ou pending
    const { data: existingSub } = await client
      .from("fan_subscription")
      .select("id, creator_id, status")
      .eq("user_id", user.id)
      .in("status", ["active", "pending"])
      .maybeSingle();

    const effectiveFrom = firstOfNextMonth();
    const monthKey = effectiveFrom.slice(0, 7); // ex: '2026-06'

    if (existingSub) {
      if (existingSub.creator_id === creator_id) {
        return err("Already a fan of this creator");
      }

      // Changer de créateur Fan — annuler l'ancien
      await client
        .from("fan_subscription")
        .update({ status: "cancelled", effective_until: effectiveFrom })
        .eq("id", existingSub.id);

      // Historique: action "changed" avec le créateur précédent
      await client.from("fan_subscription_history").insert({
        user_id: user.id,
        creator_id: existingSub.creator_id,
        action: "changed",
        previous_creator_id: existingSub.creator_id,
        month_key: monthKey,
      });
    }

    // 4. Créer le nouveau fan_subscription (pending → actif le 1er du mois suivant)
    const { data: newSub, error: subError } = await client
      .from("fan_subscription")
      .insert({
        user_id: user.id,
        creator_id,
        status: "pending",
        effective_from: effectiveFrom,
      })
      .select()
      .single();

    if (subError) throw subError;

    // 5. Historique: action "activated"
    await client.from("fan_subscription_history").insert({
      user_id: user.id,
      creator_id,
      action: "activated",
      month_key: monthKey,
    });

    return ok({
      fan_subscription_id: newSub.id,
      creator_name: creator.display_name,
      effective_from: effectiveFrom,
      status: "pending",
    });
  } catch (e) {
    return serverError(e);
  }
});
```

- [ ] **Step 2: Rewrite `cancel-fan-mode/index.ts`**

```typescript
import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { handleCors } from "../_shared/cors.ts";
import { ok, err, unauthorized, serverError } from "../_shared/response.ts";
import { getAuthUser } from "../_shared/supabase.ts";

function firstOfNextMonth(): string {
  const d = new Date();
  d.setMonth(d.getMonth() + 1, 1);
  return d.toISOString().split("T")[0];
}

serve(async (req) => {
  const corsResponse = handleCors(req);
  if (corsResponse) return corsResponse;

  try {
    const { user, client } = await getAuthUser(req);
    if (!user || !client) return unauthorized();

    // Trouver le Fan actif ou pending
    const { data: fanSub } = await client
      .from("fan_subscription")
      .select("id, creator_id, status")
      .eq("user_id", user.id)
      .in("status", ["active", "pending"])
      .maybeSingle();

    if (!fanSub) return err("No active fan subscription found", 404);

    const effectiveUntil = firstOfNextMonth();
    const monthKey = effectiveUntil.slice(0, 7);

    // Annuler (effectif au 1er du mois suivant)
    await client
      .from("fan_subscription")
      .update({ status: "cancelled", effective_until: effectiveUntil })
      .eq("id", fanSub.id);

    // Historique: action "cancelled" avec les colonnes réelles du schéma
    await client.from("fan_subscription_history").insert({
      user_id: user.id,
      creator_id: fanSub.creator_id,
      action: "cancelled",
      month_key: monthKey,
    });

    return ok({ cancelled: true, effective_until: effectiveUntil });
  } catch (e) {
    return serverError(e);
  }
});
```

- [ ] **Step 3: Commit**

```
git add supabase/functions/activate-fan-mode/index.ts
git add supabase/functions/cancel-fan-mode/index.ts
git commit -m "fix(fan-mode): align fan_subscription_history inserts with actual schema"
```

---

## Task 7: Fix stripe-webhook to write to creator_payout (SCH-05)

The webhook inserts into the legacy `payout` table with wrong column names (`status: "completed"`, `stripe_payout_id`). The actual table to use is `creator_payout` with columns `stripe_payment_intent_id`, `amount_cents` (int), `currency`, `status` (`succeeded`/`failed`).

**Files:**
- Modify: `supabase/functions/stripe-webhook/index.ts`

- [ ] **Step 1: Update stripe-webhook payment_intent handlers**

Replace the `case "payment_intent.succeeded"` and `case "payment_intent.payment_failed"` blocks:

```typescript
      // Creator payout succeeded
      case "payment_intent.succeeded": {
        const creatorId = event.data?.object?.metadata?.creator_id;
        if (creatorId) {
          await admin.from("creator_payout").insert({
            creator_id: creatorId,
            stripe_payment_intent_id: event.data.object.id as string,
            amount_cents: event.data.object.amount as number,
            currency: (event.data.object.currency as string) ?? "eur",
            status: "succeeded",
            paid_at: new Date().toISOString(),
          });
        }
        break;
      }

      // Creator payout failed
      case "payment_intent.payment_failed": {
        const creatorId = event.data?.object?.metadata?.creator_id;
        if (creatorId) {
          await admin.from("creator_payout").insert({
            creator_id: creatorId,
            stripe_payment_intent_id: event.data.object.id as string,
            amount_cents: event.data.object.amount as number,
            currency: (event.data.object.currency as string) ?? "eur",
            status: "failed",
          });
        }
        break;
      }
```

- [ ] **Step 2: Commit**

```
git add supabase/functions/stripe-webhook/index.ts
git commit -m "fix(stripe): write payout events to creator_payout table with correct columns"
```

---

## Task 8: Fix ai-assistant-chat column name mismatches (SCH-07)

Three separate column name bugs cause the AI to always see 0 kcal nutrition data:
1. `daily_nutrition_log` uses `calories`/`protein_g`/`carbs_g`/`fat_g`/`log_date` — code queries `total_calories`/`total_protein_g`/`total_carbs_g`/`total_fat_g`/`date`
2. `recipe_macro` join uses same wrong names
3. `buildContext` references same wrong names
4. `habits` module queries same wrong column names

**Files:**
- Modify: `supabase/functions/ai-assistant-chat/index.ts`

- [ ] **Step 1: Fix `meal_plan` module — recipe_macro column names (line ~122)**

Find:
```typescript
              .select("meal_type, date, recipe:recipe(title, recipe_macro(total_calories, total_protein_g, total_carbs_g, total_fat_g))")
```

Replace with:
```typescript
              .select("meal_type, date, recipe:recipe(title, recipe_macro(calories, protein_g, carbs_g, fat_g))")
```

- [ ] **Step 2: Fix `nutrition_stats` module — column names and date column (lines ~131-135)**

Find:
```typescript
          const { data } = await client
            .from("daily_nutrition_log")
            .select("total_calories, total_protein_g, total_carbs_g, total_fat_g")
            .eq("user_id", userId)
            .eq("date", today)
            .single();
```

Replace with:
```typescript
          const { data } = await client
            .from("daily_nutrition_log")
            .select("calories, protein_g, carbs_g, fat_g")
            .eq("user_id", userId)
            .eq("log_date", today)
            .single();
```

- [ ] **Step 3: Fix `habits` module — column names (lines ~167-172)**

Find:
```typescript
          const { data } = await client
            .from("daily_nutrition_log")
            .select("date, total_calories")
            .eq("user_id", userId)
            .order("date", { ascending: false })
            .limit(30);
          const tracked = data?.filter((d: { total_calories: number }) => (d.total_calories ?? 0) > 0).length ?? 0;
          result["habits"] = {
            days_tracked_last_30: tracked,
            days_with_data: data?.length ?? 0,
          };
```

Replace with:
```typescript
          const { data } = await client
            .from("daily_nutrition_log")
            .select("log_date, calories")
            .eq("user_id", userId)
            .order("log_date", { ascending: false })
            .limit(30);
          const tracked = data?.filter((d: { calories: number }) => (d.calories ?? 0) > 0).length ?? 0;
          result["habits"] = {
            days_tracked_last_30: tracked,
            days_with_data: data?.length ?? 0,
          };
```

- [ ] **Step 4: Fix `buildContext` — all column name references (lines ~198-203)**

Find:
```typescript
  if (data.nutrition_stats) {
    const n = data.nutrition_stats as Record<string, number>;
    parts.push(`Nutrition aujourd'hui: ${n.total_calories} kcal, ${n.total_protein_g}g protéines, ${n.total_carbs_g}g glucides, ${n.total_fat_g}g lipides`);
  }
  if (data.meal_plan) {
    const mp = data.meal_plan as { meals: Array<{ meal_type: string; recipe: { title: string; recipe_macro: { total_calories: number } } }> };
    const meals = mp.meals?.map((m) =>
      `${m.meal_type}: ${m.recipe?.title} (${m.recipe?.recipe_macro?.total_calories} kcal)`
    );
```

Replace with:
```typescript
  if (data.nutrition_stats) {
    const n = data.nutrition_stats as Record<string, number>;
    parts.push(`Nutrition aujourd'hui: ${n.calories} kcal, ${n.protein_g}g protéines, ${n.carbs_g}g glucides, ${n.fat_g}g lipides`);
  }
  if (data.meal_plan) {
    const mp = data.meal_plan as { meals: Array<{ meal_type: string; recipe: { title: string; recipe_macro: { calories: number } } }> };
    const meals = mp.meals?.map((m) =>
      `${m.meal_type}: ${m.recipe?.title} (${m.recipe?.recipe_macro?.calories} kcal)`
    );
```

- [ ] **Step 5: Commit**

```
git add supabase/functions/ai-assistant-chat/index.ts
git commit -m "fix(ai): correct daily_nutrition_log and recipe_macro column names"
```

---

## Task 9: Fix send-meal-reminders days_of_week and is_enabled bug (API-01)

**Already done in Task 1, Step 6.** Both the `days_of_week` filter and the `is_enabled` → `is_active` column name fix were applied when adding the auth check. No additional file change needed.

- [ ] **Step 1: Verify Task 1 Step 6 includes the day-of-week filter and uses `is_active`**

Open `supabase/functions/send-meal-reminders/index.ts` and confirm:
1. `.eq("is_active", true)` (not `is_enabled`)
2. `days_of_week` is included in the select
3. The `if (!days.includes(currentDayOfWeek)) continue;` guard is present

---

## Task 10: Add subscription INSERT guard (AUTH-02)

Users can directly INSERT an `active` subscription row via the Supabase client, bypassing `validate-store-purchase`. The current `FOR ALL` policy allows authenticated users to insert their own row. We need INSERT restricted to `service_role` only.

**Files:**
- Create: `supabase/migrations/20260517000002_subscription_insert_guard.sql`

- [ ] **Step 1: Create migration**

```sql
-- =============================================================================
-- AKELI V1 — Migration: Subscription INSERT Guard
-- Migration: 20260517000002_subscription_insert_guard.sql
-- Fixes AUTH-02: users could self-insert an active subscription, bypassing
-- validate-store-purchase. Restricts INSERT/UPDATE to service_role.
-- =============================================================================

-- Drop the existing catch-all "FOR ALL" policy (covers SELECT, INSERT, UPDATE, DELETE)
DROP POLICY IF EXISTS "owner only subscription" ON subscription;

-- Users can read their own subscription (needed by activate-fan-mode)
CREATE POLICY "owner reads subscription" ON subscription
  FOR SELECT USING (auth.uid() = user_id);

-- Only service_role can insert new subscriptions (validate-store-purchase uses serviceClient)
CREATE POLICY "service inserts subscription" ON subscription
  FOR INSERT WITH CHECK (auth.role() = 'service_role');

-- Only service_role can update subscriptions
CREATE POLICY "service updates subscription" ON subscription
  FOR UPDATE WITH CHECK (auth.role() = 'service_role');
```

- [ ] **Step 2: Verify `validate-store-purchase` uses `serviceClient()`**

Open `supabase/functions/validate-store-purchase/index.ts` and confirm the upsert uses `serviceClient()` (not the user's `client`). It does — line 190: `const admin = serviceClient();`. The migration won't break this.

- [ ] **Step 3: Commit**

```
git add supabase/migrations/20260517000002_subscription_insert_guard.sql
git commit -m "fix(rls): restrict subscription INSERT/UPDATE to service_role"
```

---

## Task 11: Harden Stripe signature comparison and scrub error messages (SEC-04, SEC-09)

SEC-04: `expectedHex === sig` is a non-constant-time string comparison that's theoretically exploitable for timing attacks. SEC-09: `serverError()` returns raw `e.message` to clients which leaks internal details (SQL constraint names, table names, API error bodies).

**Files:**
- Modify: `supabase/functions/stripe-webhook/index.ts`
- Modify: `supabase/functions/_shared/response.ts`

- [ ] **Step 1: Add `timingSafeEqual` and use it in stripe-webhook**

In `stripe-webhook/index.ts`, add the helper function before the `serve()` call and replace the comparison:

Find the end of `verifyStripeSignature` function — replace:
```typescript
  return expectedHex === sig;
```

With the full updated function:

```typescript
function timingSafeEqual(a: string, b: string): boolean {
  const aBytes = new TextEncoder().encode(a);
  const bBytes = new TextEncoder().encode(b);
  if (aBytes.length !== bBytes.length) return false;
  let diff = 0;
  for (let i = 0; i < aBytes.length; i++) diff |= aBytes[i] ^ bBytes[i];
  return diff === 0;
}

async function verifyStripeSignature(
  payload: string,
  signature: string,
  secret: string,
): Promise<boolean> {
  const parts = signature.split(",").reduce(
    (acc: Record<string, string>, part) => {
      const [k, v] = part.split("=");
      acc[k] = v;
      return acc;
    },
    {},
  );

  const timestamp = parts["t"];
  const sig = parts["v1"];
  if (!timestamp || !sig) return false;

  const key = await crypto.subtle.importKey(
    "raw",
    new TextEncoder().encode(secret),
    { name: "HMAC", hash: "SHA-256" },
    false,
    ["sign"],
  );
  const expected = await crypto.subtle.sign(
    "HMAC",
    key,
    new TextEncoder().encode(`${timestamp}.${payload}`),
  );
  const expectedHex = Array.from(new Uint8Array(expected))
    .map((b) => b.toString(16).padStart(2, "0"))
    .join("");

  return timingSafeEqual(expectedHex, sig);
}
```

- [ ] **Step 2: Scrub error messages from `_shared/response.ts`**

Replace the `serverError` function:

Find:
```typescript
export function serverError(e: unknown): Response {
  const message = e instanceof Error ? e.message : "Internal server error";
  console.error("[ERROR]", message);
  return err(message, 500);
}
```

Replace with:
```typescript
export function serverError(e: unknown): Response {
  console.error("[ERROR]", e);
  return err("Internal server error", 500);
}
```

- [ ] **Step 3: Commit**

```
git add supabase/functions/stripe-webhook/index.ts
git add supabase/functions/_shared/response.ts
git commit -m "fix(security): constant-time Stripe sig check, scrub internal errors from responses"
```

---

## Task 12: Fix AI rate limit to use user_id scope (AUTH-03)

The rate limit queries by `conversation_id`, falling back to a null UUID when `conversation_id` is absent. A user can bypass it by always sending requests without a `conversation_id` — each creates a new conversation with a fresh counter. Fix: count recent messages across all of the user's conversations (RLS already scopes to the authenticated user).

**Files:**
- Modify: `supabase/functions/ai-assistant-chat/index.ts`

- [ ] **Step 1: Replace the rate limit query**

Find:
```typescript
    // Rate limit: 30 messages / minute
    const oneMinuteAgo = new Date(Date.now() - 60_000).toISOString();
    const { count: recentCount } = await client
      .from("ai_message")
      .select("id", { count: "exact" })
      .eq("conversation_id", conversation_id ?? "00000000-0000-0000-0000-000000000000")
      .gte("sent_at", oneMinuteAgo);
```

Replace with:
```typescript
    // Rate limit: 30 messages / minute across all conversations (RLS scopes to this user)
    const oneMinuteAgo = new Date(Date.now() - 60_000).toISOString();
    const { count: recentCount } = await client
      .from("ai_message")
      .select("id", { count: "exact" })
      .gte("sent_at", oneMinuteAgo);
```

- [ ] **Step 2: Commit**

```
git add supabase/functions/ai-assistant-chat/index.ts
git commit -m "fix(ai): rate limit by user scope, not conversation_id"
```

---

## Task 13: Fix create-checkout-session authorization (SEC-06)

Any creator can initiate a payout for a different creator's account by passing any `creator_id`. There's also no check that `amount_cents` is within the available balance.

**Files:**
- Modify: `supabase/functions/create-checkout-session/index.ts`

- [ ] **Step 1: Add creator ownership and balance checks**

After the `profile.is_creator` check and before calling Stripe, insert these two checks. The existing code gets `creator` using `creator_id` from the request body. Add a lookup of the *authenticated user's* creator record first:

Find (the block after is_creator check):
```typescript
    const { creator_id, amount_cents, success_url, cancel_url } =
      await req.json();

    if (!creator_id || !amount_cents || !success_url || !cancel_url) {
      return err(
        "creator_id, amount_cents, success_url and cancel_url are required",
      );
    }

    // Retrieve the creator's Stripe Connect account ID
    const { data: creator } = await admin
```

Replace with:
```typescript
    const { creator_id, amount_cents, success_url, cancel_url } =
      await req.json();

    if (!creator_id || !amount_cents || !success_url || !cancel_url) {
      return err(
        "creator_id, amount_cents, success_url and cancel_url are required",
      );
    }

    // Verify the authenticated user owns the creator account being paid out
    const { data: userCreator } = await admin
      .from("creator")
      .select("id")
      .eq("user_id", user.id)
      .single();

    if (!userCreator) return err("Creator profile not found", 404);
    if (userCreator.id !== creator_id) {
      return err("You can only request payouts for your own account", 403);
    }

    // Verify amount is within available balance
    const { data: balance } = await admin
      .from("creator_balance")
      .select("balance")
      .eq("creator_id", creator_id)
      .maybeSingle();

    const availableCents = Math.floor((balance?.balance ?? 0) * 100);
    if (amount_cents > availableCents) {
      return err(`Amount exceeds available balance (max: ${availableCents} cents)`, 400);
    }

    // Retrieve the creator's Stripe Connect account ID
    const { data: creator } = await admin
```

- [ ] **Step 2: Commit**

```
git add supabase/functions/create-checkout-session/index.ts
git commit -m "fix(security): restrict checkout session to own creator account and validate balance"
```

---

## Verification Checklist

After all tasks are committed, verify the following before deploying:

- [ ] `INTERNAL_SECRET` is set in Supabase project secrets (Dashboard → Edge Functions → Secrets)
- [ ] All cron job invocations in Supabase scheduler include `x-internal-secret` header
- [ ] `send-meal-reminders` internal call to `send-push-notification` uses `x-internal-secret` header (done in Task 1 Step 6)
- [ ] Migrations `20260517000001` and `20260517000002` applied to production via `supabase db push`
- [ ] All edge functions deployed via `supabase functions deploy --all`
- [ ] Smoke test: GET `/functions/v1/get-creator-dashboard` returns non-zero `balance` for a creator with revenue
- [ ] Smoke test: Recipe detail screen loads steps (RLS-01/02 fix)
- [ ] Smoke test: `compute-monthly-revenue` cron returns 401 without the secret header
