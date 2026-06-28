-- Migration: Add missing foreign key indexes
-- Each index is created only if its table exists (guards local DB reset where
-- some tables were created directly on remote without migrations).

DO $$ BEGIN
  IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'specialty') THEN
    EXECUTE 'CREATE INDEX IF NOT EXISTS idx_specialty_region ON specialty (region)';
  END IF;
END $$;

DO $$ BEGIN
  IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'ingredient_submission') THEN
    EXECUTE 'CREATE INDEX IF NOT EXISTS idx_ingredient_submission_ingredient_id ON ingredient_submission (ingredient_id)';
  END IF;
END $$;

DO $$ BEGIN
  IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'conversation' AND column_name = 'community_group_id') THEN
    EXECUTE 'CREATE INDEX IF NOT EXISTS idx_conversation_community_group_id ON conversation (community_group_id)';
  END IF;
  IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'conversation' AND column_name = 'created_by') THEN
    EXECUTE 'CREATE INDEX IF NOT EXISTS idx_conversation_created_by ON conversation (created_by)';
  END IF;
END $$;

DO $$ BEGIN
  IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'recipe' AND column_name = 'parent_recipe_id') THEN
    EXECUTE 'CREATE INDEX IF NOT EXISTS idx_recipe_parent_recipe_id ON recipe (parent_recipe_id)';
  END IF;
END $$;

DO $$ BEGIN
  IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'recipe_ingredient_translation') THEN
    EXECUTE 'CREATE INDEX IF NOT EXISTS idx_recipe_ingredient_translation_unit ON recipe_ingredient_translation (unit)';
  END IF;
END $$;

DO $$ BEGIN
  IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'ingredient') THEN
    EXECUTE 'CREATE INDEX IF NOT EXISTS idx_ingredient_category ON ingredient (category)';
  END IF;
END $$;

DO $$ BEGIN
  IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'recipe_ingredient') THEN
    EXECUTE 'CREATE INDEX IF NOT EXISTS idx_recipe_ingredient_ingredient_id ON recipe_ingredient (ingredient_id)';
    EXECUTE 'CREATE INDEX IF NOT EXISTS idx_recipe_ingredient_unit ON recipe_ingredient (unit)';
  END IF;
END $$;

DO $$ BEGIN
  IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'recipe_image') THEN
    EXECUTE 'CREATE INDEX IF NOT EXISTS idx_recipe_image_recipe_id ON recipe_image (recipe_id)';
  END IF;
END $$;

DO $$ BEGIN
  IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'meal_consumption' AND column_name = 'meal_plan_entry_id') THEN
    EXECUTE 'CREATE INDEX IF NOT EXISTS idx_meal_consumption_meal_plan_entry_id ON meal_consumption (meal_plan_entry_id)';
  END IF;
  IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'meal_consumption' AND column_name = 'creator_id') THEN
    EXECUTE 'CREATE INDEX IF NOT EXISTS idx_meal_consumption_creator_id ON meal_consumption (creator_id)';
  END IF;
END $$;

DO $$ BEGIN
  IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'shopping_list') THEN
    EXECUTE 'CREATE INDEX IF NOT EXISTS idx_shopping_list_user_id ON shopping_list (user_id)';
  END IF;
END $$;

DO $$ BEGIN
  IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'shopping_list_item') THEN
    EXECUTE 'CREATE INDEX IF NOT EXISTS idx_shopping_list_item_shopping_list_id ON shopping_list_item (shopping_list_id)';
    EXECUTE 'CREATE INDEX IF NOT EXISTS idx_shopping_list_item_ingredient_id ON shopping_list_item (ingredient_id)';
    EXECUTE 'CREATE INDEX IF NOT EXISTS idx_shopping_list_item_unit ON shopping_list_item (unit)';
  END IF;
END $$;

DO $$ BEGIN
  IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'fan_subscription_history' AND column_name = 'subscription_id') THEN
    EXECUTE 'CREATE INDEX IF NOT EXISTS idx_fan_subscription_history_subscription_id ON fan_subscription_history (subscription_id)';
  END IF;
END $$;

DO $$ BEGIN
  IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'creator_revenue_log' AND column_name = 'recipe_id') THEN
    EXECUTE 'CREATE INDEX IF NOT EXISTS idx_creator_revenue_log_recipe_id ON creator_revenue_log (recipe_id)';
  END IF;
END $$;

DO $$ BEGIN
  IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'chat_message' AND column_name = 'sender_id') THEN
    EXECUTE 'CREATE INDEX IF NOT EXISTS idx_chat_message_sender_id ON chat_message (sender_id)';
  END IF;
  IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'chat_message' AND column_name = 'recipe_id') THEN
    EXECUTE 'CREATE INDEX IF NOT EXISTS idx_chat_message_recipe_id ON chat_message (recipe_id)';
  END IF;
END $$;

DO $$ BEGIN
  IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'community_group' AND column_name = 'creator_id') THEN
    EXECUTE 'CREATE INDEX IF NOT EXISTS idx_community_group_creator_id ON community_group (creator_id)';
  END IF;
  IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'community_group' AND column_name = 'region_code') THEN
    EXECUTE 'CREATE INDEX IF NOT EXISTS idx_community_group_region_code ON community_group (region_code)';
  END IF;
END $$;

DO $$ BEGIN
  IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'conversation_request') THEN
    EXECUTE 'CREATE INDEX IF NOT EXISTS idx_conversation_request_requester_id ON conversation_request (requester_id)';
    EXECUTE 'CREATE INDEX IF NOT EXISTS idx_conversation_request_recipient_id ON conversation_request (recipient_id)';
  END IF;
END $$;

DO $$ BEGIN
  IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'push_token') THEN
    EXECUTE 'CREATE INDEX IF NOT EXISTS idx_push_token_user_id ON push_token (user_id)';
  END IF;
END $$;

DO $$ BEGIN
  IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'support_message') THEN
    EXECUTE 'CREATE INDEX IF NOT EXISTS idx_support_message_user_id ON support_message (user_id)';
  END IF;
END $$;

DO $$ BEGIN
  IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'ai_conversation') THEN
    EXECUTE 'CREATE INDEX IF NOT EXISTS idx_ai_conversation_user_id ON ai_conversation (user_id)';
  END IF;
END $$;

DO $$ BEGIN
  IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'cooking_session_ingredient') THEN
    EXECUTE 'CREATE INDEX IF NOT EXISTS idx_cooking_session_ingredient_ingredient_id ON cooking_session_ingredient (ingredient_id)';
  END IF;
END $$;

DO $$ BEGIN
  IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'meal_ingredient') THEN
    EXECUTE 'CREATE INDEX IF NOT EXISTS idx_meal_ingredient_ingredient_id ON meal_ingredient (ingredient_id)';
  END IF;
END $$;

DO $$ BEGIN
  IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'group_invite') THEN
    EXECUTE 'CREATE INDEX IF NOT EXISTS idx_group_invite_inviter_id ON group_invite (inviter_id)';
  END IF;
END $$;

DO $$ BEGIN
  IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'allergen_suggestion') THEN
    EXECUTE 'CREATE INDEX IF NOT EXISTS idx_allergen_suggestion_user_id ON allergen_suggestion (user_id)';
  END IF;
END $$;
