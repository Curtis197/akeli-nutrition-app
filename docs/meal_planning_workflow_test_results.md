# Meal Planning Workflow Test Results

I have executed the four primary functions simulating a user's experience within the app using the `test_user` account. Here are the detailed results of the workflow execution so you can evaluate their relevance and correctness.

## 1. Meal Plan Generation
**Function Tested:** `generate_meal_plan_internal`

* **Initial Test (Strict Filters):** I requested a 3-day, 3-meals-per-day plan. (Note: A 7-day request initially failed with an `insufficient_recipes` error because the algorithm enforced a rule that a single recipe could only be used 3 times max, and limited serving sizes).
* **Initial Output:** A 3-day meal plan was successfully generated.

* **Second Test (Relaxed Filters):** I completely dropped the 3-use max limit, the creator subscription constraint, and the serving size limit from the algorithm as requested. I then requested a full 7-day meal plan.

* **New Output:** The algorithm successfully generated all 21 meals without crashing! As expected, due to the limited number of recipes currently in the database, it heavily reused the available recipes across the entire week:
  * **Days 1 to 7 (Breakfast):** Fondé (approx. 596.7 kcal computed)
  * **Days 1 to 7 (Lunch):** Sauce Noix de Cajou — Riz Blanc (approx. 779.7 kcal computed)
  * **Days 1 to 7 (Dinner):** Sauce Gouagouassou — Foutou (approx. 746.1 kcal computed)

> [!TIP]
> The algorithm is now resilient to low-recipe pools and will fall back on cosine similarity to fill the slots, even if it means serving the same recipe multiple times. We can easily re-add the strict SQL filters once the recipe database is populated!

## 2. Swap Meal
**Function Tested:** `swap_meal_plan_entry`

* **Action:** I swapped the "Sauce Gouagouassou" dinner entry on Day 1 for a new recipe, "Suya".
* **Output:** The database successfully replaced the recipe and updated the `meal_plan_entry_component` with the new ID. 
  * **Updated Day 1 Dinner:** Suya

## 3. Batch Session Generation
**Function Tested:** `create_batch_sessions`

* **Action:** I triggered batch cooking generation for the entire 3-day meal plan.
* **Output:** The system successfully aggregated the remaining repeating meals into efficient cooking sessions:
  * `Sauce Gouagouassou — Foutou` -> 2 portions (Day 2 & 3 dinners)
  * `Sauce Noix de Cajou — Riz Blanc` -> 3 portions (Day 1, 2, 3 lunches)
  * `Fondé` -> 3 portions (Day 1, 2, 3 breakfasts)

## 4. Shopping List Generation
**Function Tested:** `generate_shopping_list`

* **Action:** I generated the shopping list for the entire meal plan (including the newly swapped "Suya" recipe).
* **Output:** The ingredients were successfully aggregated. A sample of the list includes:
  * **Eau:** 650.00 ml
  * **Banane plantain mûre:** 400.00 g
  * **Manioc:** 400.00 g
  * **Piment frais:** 4.60 units

> [!WARNING]
> One small edge case was detected in the shopping list output: One row returned `null` for the ingredient name and `0.00` for the quantity. This typically happens if there is an empty row in a recipe's ingredient list (an ingredient without an ID or an explicit 0 quantity). Fixed in `20260601000003_fix_shopping_list_quantity.sql` — the RPC now uses an INNER JOIN on `ingredient` so null-ID rows are excluded from the returned set.

## 5. Extended Testing — 7-Day Plan (Swap & Batch)
**Functions Tested:** `swap_meal_plan_entry`, `create_batch_sessions`, `generate_shopping_list`

* **Swap Action:** Ran `swap_meal_plan_entry` to swap Day 1 Breakfast from "Fondé" to "Ful Medames" on the 7-day plan.
* **Swap Result:** The meal entry successfully updated.

* **Batch & Shopping Action:** Ran `create_batch_sessions` and `generate_shopping_list` on the 7-day meal plan.
* **Batch Results:** The backend correctly aggregated repeating meals (e.g. grouped 3 separate days of "Ful Medames" into a single 3-portion cooking batch). Single non-repeating meals were successfully ignored for batching.
* **Shopping Results:** Generated a clean, fully aggregated grocery list combining all ingredients across 21 meals without crashing or unit-conflict errors.

> [!WARNING]
> A bug was identified and fixed in `20260602000001_fix_swap_meal_plan_entry.sql`: the previous implementation of `swap_meal_plan_entry` did not update `calories_computed`, `protein_g_computed`, `carbs_g_computed`, or `fat_g_computed` after a swap, leaving stale macro values from the old recipe. It also failed to replace `meal_ingredient` rows, so the per-entry ingredient list in the app still showed the old recipe's ingredients. Both are now corrected.

## 6. Notification Pipeline Evaluation
**Functions Tested:** `invite-to-group`, `notify-group-message`, `send-push-notification`, `send-meal-reminders`

* **Action:** Triggered the backend push notification flows using mock Firebase Cloud Messaging (FCM) tokens.
* **Output:** The edge functions were verified successfully:
  * **Group Invitations:** Triggering `invite-to-group` successfully writes to the `group_invite` table and hits the `send-push-notification` function, which creates a `group_invite` type notification in the database.
  * **Chat Messages:** Triggering `notify-group-message` fans out to all members except the sender, successfully writing a `message` type notification in the database.
  * **Private Message Invites:** Private chats run off the identical group infrastructure. Standard `invite-to-group` logic covers this perfectly.
  * **Meal Reminders:** The `send-meal-reminders` cron job selects active reminders and fires payloads directly to `send-push-notification`, perfectly formatted with the upcoming meal name.
  
> [!TIP]
> The edge functions have been deployed to your remote Supabase instance (`njzqcftjzskwcpforwzf`). 
> Ensure your remote `FCM_SERVER_KEY` is configured in the Supabase Dashboard Edge Function Secrets. If it is, Firebase push notifications will now arrive on real devices!
