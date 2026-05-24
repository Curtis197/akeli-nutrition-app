-- ---------------------------------------------------------------------------
-- NOTIFICATION TRIGGERS
-- Inserts into `notification` when a DM is sent or a conversation request
-- is created. Both functions are SECURITY DEFINER so they can write to
-- `notification` regardless of the caller's RLS context.
-- ---------------------------------------------------------------------------

-- 1. DM message → notify recipient -----------------------------------------

CREATE OR REPLACE FUNCTION fn_notify_chat_message()
RETURNS TRIGGER LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE
  v_sender_name  text;
  v_recipient_id uuid;
BEGIN
  -- Only handle private DMs (conversation_id set, group_id null)
  IF NEW.conversation_id IS NULL THEN
    RETURN NEW;
  END IF;

  SELECT display_name INTO v_sender_name
    FROM user_profile WHERE id = NEW.sender_id;

  SELECT user_id INTO v_recipient_id
    FROM conversation_participant
   WHERE conversation_id = NEW.conversation_id
     AND user_id != NEW.sender_id
   LIMIT 1;

  IF v_recipient_id IS NOT NULL THEN
    INSERT INTO notification (user_id, type, title, body, data)
    VALUES (
      v_recipient_id,
      'message',
      COALESCE(v_sender_name, 'Nouveau message'),
      LEFT(NEW.content, 100),
      jsonb_build_object(
        'conversation_id', NEW.conversation_id,
        'sender_id',       NEW.sender_id
      )
    );
  END IF;

  RETURN NEW;
END;
$$;

CREATE TRIGGER trg_notify_chat_message
  AFTER INSERT ON chat_message
  FOR EACH ROW
  EXECUTE FUNCTION fn_notify_chat_message();

-- 2. Conversation request → notify recipient --------------------------------

CREATE OR REPLACE FUNCTION fn_notify_conversation_request()
RETURNS TRIGGER LANGUAGE plpgsql SECURITY DEFINER AS $$
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

CREATE TRIGGER trg_notify_conversation_request
  AFTER INSERT ON conversation_request
  FOR EACH ROW
  EXECUTE FUNCTION fn_notify_conversation_request();
