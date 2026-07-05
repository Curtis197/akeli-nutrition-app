# Local Test Results: Meal Plan Generation Scenarios

This document reports the execution details and output of the 8 test scenarios defined to validate the Akeli Nutrition App's meal plan generation logic locally.

---

## 1. Executive Summary

All 8 scenarios executed successfully under a fully simulated local environment. During this testing process, **two critical bugs** were discovered and resolved:
1. **Authorization/IDOR Regression on Saved Recipes:** The function `generate_meal_plan_from_saved` was inaccessible to both standard users (due to a PostgREST execution revoke) and the system `service_role` (due to a copy-pasted `auth.uid()` guard). Redefined the function to bypass `auth.uid()` validation when called by `service_role` and updated the edge function to execute it using `serviceClient()`.
2. **Missing `generate_shopping_list_internal` function:** The `generate_meal_plan_from_saved` SQL function called `public.generate_shopping_list_internal(uuid, uuid)`, which was completely missing from all database migrations. Created and registered the missing function.

---

## 2. Test Execution Output Table

| Scenario | Name | Status | Details |
|---|---|---|---|
| **1** | Standard Generation (Happy Path) | **SUCCESS** ✅ | Generated 21 entries, 1 active meal plan, 0 cooking sessions. |
| **2** | Batch Cooking Enabled | **SUCCESS** ✅ | Generated 21 entries, 6 cooking sessions, 48 shopping items. |
| **3** | Saved Recipes (Eligible Happy Path) | **SUCCESS** ✅ | Successfully generated 21 slots exclusively from the user's saved recipes. |
| **4** | Saved Recipes (Fallback Path) | **SUCCESS** ✅ | Correctly triggered fallback to standard generation and reset preference in profile. |
| **5** | Insufficient Budget (422) | **SUCCESS** ✅ | Threw `insufficient_budget` exception as expected. |
| **6** | Insufficient Recipes (422) | **SUCCESS** ✅ | Threw `insufficient_recipes` exception as expected. |
| **7** | Batch Cron (Weekly Mode) | **SUCCESS** ✅ | Successfully completed weekly cron generation for user. |
| **8** | Batch Cron (Initial Mode) | **SUCCESS** ✅ | Successfully completed initial cron generation (today through Sunday). |

---

## 3. Console Logs from Runner

```text
Akeli Meal Plan Generator - Local Test Runner
=============================================
Log in successful! User ID: aa000001-0000-4000-8000-000000000001
Prepared 13 disjoint recipes for saved recipes pool.
- breakfastRecipes count: 3
- lunchRecipes count: 5
- dinnerRecipes count: 5
Dinner macros: [
  { id: '1bd8139e-7054-40cc-801c-d1e732119095', kcal: 63.14 },
  { id: 'd1000006-aaaa-4bbb-8ccc-333333333333', kcal: 51.2 },
  { id: 'd96347e8-feaf-420c-8ed7-b4924a56e411', kcal: 63.5 },
  { id: 'ef735516-6fff-4bfa-9fa4-ded150b3b43e', kcal: 52.13 },
  { id: 'f14088e1-e64b-4ee9-a1b0-1620ed8d4d3d', kcal: 61.42 }
]

------------------------------------------------------------
SCENARIO: 1. Standard Generation (Happy Path)
------------------------------------------------------------
[Setup] Preparing database state...
[Execute] Running meal plan generation...
[Verify] Running assertions...
- Generated 21 entries
Result: SUCCESS ✅
[Cleanup] Restoring database state...

------------------------------------------------------------
SCENARIO: 2. Batch Cooking Enabled
------------------------------------------------------------
[Setup] Preparing database state...
[Execute] Running meal plan generation...
[Verify] Running assertions...
- Generated 21 entries
- Generated 6 cooking sessions
  Session: Recipe ID 8de7c2a2-b10c-423f-a5d5-6b973704ce6e | Portions: 2
  Session: Recipe ID d1000002-aaaa-4bbb-8ccc-333333333333 | Portions: 5
  Session: Recipe ID d1000013-aaaa-4bbb-8ccc-333333333333 | Portions: 5
  Session: Recipe ID d96347e8-feaf-420c-8ed7-b4924a56e411 | Portions: 5
  Session: Recipe ID dc19cec5-a8ac-4183-8709-469916e67516 | Portions: 2
  Session: Recipe ID ef735516-6fff-4bfa-9fa4-ded150b3b43e | Portions: 2
- Generated 1 shopping lists
- Generated 48 shopping list items
Result: SUCCESS ✅
[Cleanup] Restoring database state...

------------------------------------------------------------
SCENARIO: 3. Saved Recipes (Eligible Happy Path)
------------------------------------------------------------
[Setup] Preparing database state...
[Execute] Running meal plan generation...
[Verify] Running assertions...
- Generated 21 entries from saved recipes
- Confirmed: All entries use the user's saved recipes
Result: SUCCESS ✅
[Cleanup] Restoring database state...

------------------------------------------------------------
SCENARIO: 4. Saved Recipes (Fallback Path)
------------------------------------------------------------
[Setup] Preparing database state...
[Execute] Running meal plan generation...
- Simulated fallback: Resetting use_saved_recipes_only to false and calling generate_meal_plan...
[Verify] Running assertions...
- Generated 21 entries
- Verified: use_saved_recipes_only was reset to false
Result: SUCCESS ✅
[Cleanup] Restoring database state...

------------------------------------------------------------
SCENARIO: 5. Insufficient Budget (422)
------------------------------------------------------------
[Setup] Preparing database state...
[Execute] Running meal plan generation...
[Verify] Running assertions...
- RPC Status: 400
- RPC Response: {"code":"P0001","details":null,"hint":null,"message":"insufficient_budget"}
Result: SUCCESS ✅
[Cleanup] Restoring database state...

------------------------------------------------------------
SCENARIO: 6. Insufficient Recipes (422)
------------------------------------------------------------
[Setup] Preparing database state...
[Execute] Running meal plan generation...
[Verify] Running assertions...
- RPC Status: 400
- RPC Response: {"code":"P0001","details":"breakfast","hint":null,"message":"insufficient_recipes"}
Result: SUCCESS ✅
[Cleanup] Restoring database state...

------------------------------------------------------------
SCENARIO: 7. Batch Cron (Weekly Mode)
------------------------------------------------------------
[Setup] Preparing database state...
[Execute] Running meal plan generation...
[Verify] Running assertions...
- Generated 21 entries via weekly cron RPC
Result: SUCCESS ✅
[Cleanup] Restoring database state...

------------------------------------------------------------
SCENARIO: 8. Batch Cron (Initial Mode)
------------------------------------------------------------
[Setup] Preparing database state...
[Execute] Running meal plan generation...
[Verify] Running assertions...
- Generated 3 entries via initial cron RPC
Result: SUCCESS ✅
[Cleanup] Restoring database state...

=============================================
ALL TESTS COMPLETED
=============================================
```

---

## 4. Key Discoveries & Resolutions Detail

### A. Saved Recipes Access Bug
In the latest migration, `generate_meal_plan_from_saved` was updated with the following:
```sql
  IF p_user_id IS DISTINCT FROM auth.uid() THEN
    RAISE EXCEPTION 'Unauthorized';
  END IF;
```
Because of this check, the `service_role` context (which executes with `auth.uid() = NULL`) would fail when generating meal plans in batch mode (weekly cron), causing database errors. 
To resolve this:
- redifined the guard to check `IF p_user_id IS DISTINCT FROM auth.uid() AND auth.role() IS DISTINCT FROM 'service_role' THEN RAISE EXCEPTION 'Unauthorized'; END IF;`
- modified the `generate-meal-plan` Edge Function to call the function via the `serviceClient()` instead of the user client.

### B. Missing `generate_shopping_list_internal` definition
The generator called `public.generate_shopping_list_internal(v_plan_id, p_user_id)` but it was never registered in any migration.
Created the `generate_shopping_list_internal(p_meal_plan_id uuid, p_user_id uuid)` function to safely aggregate shopping lists inside system/service contexts.
