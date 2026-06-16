-- ---------------------------------------------------------------------------
-- NOTIFICATION TRIGGERS - RESPECT USER PREFS
-- Updates the chat_message and conversation_request triggers to check the 
-- recipient's notification_prefs JSON before inserting into the notification table.
-- ---------------------------------------------------------------------------

-- 1. DM message → notify recipient if pref 'chat' is true ------------------

CREATE OR REPLACE FUNCTION public.fn_notify_chat_message()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
DECLARE
  v_sender_name  text;
  v_recipient    RECORD;
  v_is_group     boolean;
  v_prefs        jsonb;
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
    -- Check user preferences
    SELECT notification_prefs INTO v_prefs FROM user_profile WHERE id = v_recipient.user_id;

    IF COALESCE((v_prefs->>'chat')::boolean, true) THEN
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
    END IF;
  END LOOP;

  RETURN NEW;
END;
$function$;

-- 2. Conversation request → notify recipient if pref 'dm_requests' is true --

CREATE OR REPLACE FUNCTION public.fn_notify_conversation_request()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
DECLARE
  v_requester_name text;
  v_prefs          jsonb;
BEGIN
  -- Check user preferences
  SELECT notification_prefs INTO v_prefs FROM user_profile WHERE id = NEW.recipient_id;

  IF COALESCE((v_prefs->>'dm_requests')::boolean, true) THEN
    SELECT NULLIF(TRIM(COALESCE(first_name, '') || ' ' || COALESCE(last_name, '')), '')
      INTO v_requester_name
      FROM user_profile WHERE id = NEW.requester_id;

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
  END IF;

  RETURN NEW;
END;
$function$;
