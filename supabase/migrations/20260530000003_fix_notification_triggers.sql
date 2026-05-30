-- ---------------------------------------------------------------------------
-- FIX 1: fn_notify_conversation_request used wrong column names.
-- The live conversation_request table has requester_id / recipient_id,
-- not from_user_id / to_user_id.
-- ---------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION fn_notify_conversation_request()
RETURNS TRIGGER LANGUAGE plpgsql SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_requester_name text;
BEGIN
  SELECT display_name INTO v_requester_name
    FROM user_profile WHERE id = NEW.requester_id;

  INSERT INTO notification (user_id, type, title, body, data)
  VALUES (
    NEW.recipient_id,
    'conversation_request',
    COALESCE(v_requester_name, 'Quelqu''un') || ' veut discuter',
    'Acceptez ou refusez la demande de conversation.',
    jsonb_build_object(
      'request_id',   NEW.id,
      'requester_id', NEW.requester_id
    )
  );

  RETURN NEW;
END;
$$;

-- Recreate trigger (idempotent)
DROP TRIGGER IF EXISTS trg_notify_conversation_request ON conversation_request;
CREATE TRIGGER trg_notify_conversation_request
  AFTER INSERT ON conversation_request
  FOR EACH ROW
  EXECUTE FUNCTION fn_notify_conversation_request();

-- ---------------------------------------------------------------------------
-- FIX 2: fn_notify_chat_message used LIMIT 1, notifying only one participant.
-- For DMs this was accidentally correct (2 participants → 1 recipient).
-- Group chats also use conversation_id but have N participants — LIMIT 1 drops
-- N-2 recipients.
--
-- Correct approach:
--   - DMs:   conversation.community_group_id IS NULL  → trigger handles them,
--            loops over all conversation_participant rows (always 1 recipient).
--   - Groups: conversation.community_group_id IS NOT NULL → skip here;
--             notify-group-message edge function handles push + in-app via
--             send-push-notification (which already inserts notification rows).
-- ---------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION fn_notify_chat_message()
RETURNS TRIGGER LANGUAGE plpgsql SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_sender_name  text;
  v_recipient    RECORD;
  v_is_group     boolean;
BEGIN
  -- Only handle DM conversations (conversation_id set)
  IF NEW.conversation_id IS NULL THEN
    RETURN NEW;
  END IF;

  -- Skip group-linked conversations — handled by notify-group-message edge fn
  SELECT (community_group_id IS NOT NULL)
    INTO v_is_group
    FROM conversation
   WHERE id = NEW.conversation_id;

  IF v_is_group THEN
    RETURN NEW;
  END IF;

  SELECT display_name INTO v_sender_name
    FROM user_profile WHERE id = NEW.sender_id;

  -- Loop over all participants except sender (DMs: always exactly one)
  FOR v_recipient IN
    SELECT user_id
      FROM conversation_participant
     WHERE conversation_id = NEW.conversation_id
       AND user_id != NEW.sender_id
  LOOP
    INSERT INTO notification (user_id, type, title, body, data)
    VALUES (
      v_recipient.user_id,
      'message',
      COALESCE(v_sender_name, 'Nouveau message'),
      LEFT(NEW.content, 100),
      jsonb_build_object(
        'conversation_id', NEW.conversation_id,
        'sender_id',       NEW.sender_id
      )
    );
  END LOOP;

  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_notify_chat_message ON chat_message;
CREATE TRIGGER trg_notify_chat_message
  AFTER INSERT ON chat_message
  FOR EACH ROW
  EXECUTE FUNCTION fn_notify_chat_message();
