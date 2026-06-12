-- Trigger: increment/decrement cooking_session.portions_used when a
-- meal_plan_entry.is_consumed toggles. Links via meal_plan_entry_component.

CREATE OR REPLACE FUNCTION trg_fn_meal_entry_portions_used()
RETURNS trigger LANGUAGE plpgsql AS $$
BEGIN
  IF NEW.is_consumed = OLD.is_consumed THEN
    RETURN NEW;
  END IF;

  IF NEW.is_consumed = TRUE THEN
    UPDATE cooking_session cs
    SET portions_used = cs.portions_used + 1
    FROM meal_plan_entry_component mec
    WHERE mec.meal_plan_entry_id = NEW.id
      AND mec.cooking_session_id IS NOT NULL
      AND mec.cooking_session_id = cs.id;
  ELSE
    UPDATE cooking_session cs
    SET portions_used = GREATEST(0, cs.portions_used - 1)
    FROM meal_plan_entry_component mec
    WHERE mec.meal_plan_entry_id = NEW.id
      AND mec.cooking_session_id IS NOT NULL
      AND mec.cooking_session_id = cs.id;
  END IF;

  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_meal_entry_portions_used ON meal_plan_entry;
CREATE TRIGGER trg_meal_entry_portions_used
  AFTER UPDATE OF is_consumed ON meal_plan_entry
  FOR EACH ROW EXECUTE FUNCTION trg_fn_meal_entry_portions_used();
