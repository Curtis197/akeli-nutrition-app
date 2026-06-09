-- ---------------------------------------------------------------------------
-- FIX: fn_notify_conversation_request and fn_notify_chat_message both SELECT
-- user_profile.display_name which does not exist.
-- user_profile has first_name / last_name; display_name belongs to creator.
-- Replace with TRIM(COALESCE(first_name,'') || ' ' || COALESCE(last_name,''))
-- falling back to username, then a static French fallback.
-- ---------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION fn_notify_conversation_request()
RETURNS TRIGGER LANGUAGE plpgsql SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_requester_name text;
BEGIN
  SELECT NULLIF(TRIM(COALESCE(first_name, '') || ' ' || COALESCE(last_name, '')), '')
    INTO v_requester_name
    FROM user_profile WHERE id = NEW.requester_id;

  -- Fall back to username if no name set
  IF v_requester_name IS NULL THEN
    SELECT username INTO v_requester_name
      FROM user_profile WHERE id = NEW.requester_id;
  END IF;

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

DROP TRIGGER IF EXISTS trg_notify_conversation_request ON conversation_request;
CREATE TRIGGER trg_notify_conversation_request
  AFTER INSERT ON conversation_request
  FOR EACH ROW
  EXECUTE FUNCTION fn_notify_conversation_request();

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
  IF NEW.conversation_id IS NULL THEN
    RETURN NEW;
  END IF;

  SELECT (community_group_id IS NOT NULL)
    INTO v_is_group
    FROM conversation
   WHERE id = NEW.conversation_id;

  IF v_is_group THEN
    RETURN NEW;
  END IF;

  SELECT NULLIF(TRIM(COALESCE(first_name, '') || ' ' || COALESCE(last_name, '')), '')
    INTO v_sender_name
    FROM user_profile WHERE id = NEW.sender_id;

  IF v_sender_name IS NULL THEN
    SELECT username INTO v_sender_name
      FROM user_profile WHERE id = NEW.sender_id;
  END IF;

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
