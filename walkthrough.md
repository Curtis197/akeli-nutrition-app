# Enforcing Single Comment Per Recipe 

## Overview
We identified that the `recipe_comment` table allowed users to post an unlimited number of comments per recipe. We implemented a restriction to ensure one comment per user per recipe, and updated the frontend UI to gracefully allow editing.

## Database Changes
- **Migration**: Created `20260601000002_unique_recipe_comment.sql`
- **Deduplication**: Deleted existing duplicate comments to ensure the integrity constraint could be applied securely.
- **Constraint**: Applied a `UNIQUE(user_id, recipe_id)` constraint on the `recipe_comment` table.

## Frontend Changes
- **Upsert Logic**: In `recipe_comment_provider.dart`, the `.insert()` was upgraded to `.upsert()` with `onConflict: 'user_id, recipe_id'`. This handles both initial posting and future edits through the exact same mechanism, leveraging Supabase's conflict resolution.
- **UI Adaptation**: In `recipe_comments_sheet.dart`, the component now detects if the `currentUser` has already submitted a comment.
  - **Before**: Always showed an empty "Ajouter un commentaire..." text field.
  - **After**: Shows a clean success banner "Vous avez déjà commenté cette recette." with a **Modifier** (Edit) button.
  - When **Modifier** is clicked, it opens the text field pre-filled with the user's previous comment, allowing seamless updates.

### 2. Group Chat & Direct Messages "Read/Unread"
- **UI & Logic:** Implemented dynamic tracking of the `isRead` status for individual messages inside the `AkeliChatBubble`.
- **Database Tracking:** Added `otherParticipantsLastReadProvider` in `dm_provider.dart` to calculate the max `last_read_at` value from other participants in the `conversation_participant` table.
- **Result:** Messages you send will now accurately display the double-check icon (`Icons.done_all`) in green exactly when they are read by others!

### 3. Shopping List Generation Fix
- **Issue:** Generating a shopping list would crash with a `violates not-null constraint` when aggregating ingredients like "A pinch of salt" (which have a null quantity).
- **Fix:** Created a new Supabase migration (`20260601000003_fix_shopping_list_quantity.sql`) to explicitly wrap ingredient aggregations in a `COALESCE(SUM(...), 0)` fallback inside the `generate_shopping_list` RPC.
- **Result:** Shopping lists generate seamlessly regardless of missing base quantities!

## Validation & Code Quality
- **0-Warnings Rule:** Ran `flutter analyze` ensuring all Dart code, including the newly added read-receipt providers, is fully compliant with 0 warnings. Removed unused variables and resolved type discrepancies (`neq` on streams).

*Note: You can test the newly adjusted comment UI in the recipe pages, and test out read receipts by jumping into a chat and sending a message to a friend!*
