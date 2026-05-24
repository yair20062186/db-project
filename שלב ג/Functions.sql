-- ============================================================
-- IDF Food & Dining Hall Management System
-- Author : Yair Shushan | 215973686
-- Stage  : Stage C – Functions, Procedures, and Triggers
--
--   F1 – get_hall_session_count(hall_id)
--        Returns the total number of meal sessions for a hall.
--
--   P1 – add_dietary_restriction(soldier_id, type, severity)
--        Inserts a new restriction after checking the soldier
--        exists in the database.
--
--   T1 – trg_check_soldier_active  (BEFORE INSERT on DIETARY_RESTRICTION)
--        Blocks adding a restriction for a non-Active soldier.
--
--   T2 – trg_auto_remove_mild_restrictions  (AFTER UPDATE on SOLDIER)
--        When a soldier is discharged, removes their Mild
--        restrictions automatically.
-- ============================================================


-- ============================================================
-- FUNCTION F1 : get_hall_session_count
-- Returns the number of meal sessions for a given dining hall.
-- Example: SELECT get_hall_session_count(3);
-- ============================================================

CREATE OR REPLACE FUNCTION get_hall_session_count(p_hall_id INT)
RETURNS INT
LANGUAGE plpgsql
AS $$
DECLARE
    v_count INT;
BEGIN
    SELECT COUNT(*) INTO v_count
    FROM MEAL_SESSION
    WHERE hall_id = p_hall_id;

    RETURN v_count;
END;
$$;

-- Test 1: session count for hall 1
SELECT get_hall_session_count(1) AS session_count;

-- Test 2: session count for every active hall
SELECT hall_id, hall_name, get_hall_session_count(hall_id) AS total_sessions
FROM DINING_HALL
WHERE is_active = TRUE
ORDER BY total_sessions DESC;


-- ============================================================
-- PROCEDURE P1 : add_dietary_restriction
-- Inserts a new dietary restriction for a soldier.
-- Raises an error if the soldier does not exist.
-- ============================================================

CREATE OR REPLACE PROCEDURE add_dietary_restriction(
    p_soldier_id INT,
    p_type       TEXT,
    p_severity   TEXT
)
LANGUAGE plpgsql
AS $$
BEGIN
    -- Check the soldier exists before inserting
    IF NOT EXISTS (SELECT 1 FROM SOLDIER WHERE soldier_id = p_soldier_id) THEN
        RAISE EXCEPTION 'Soldier % does not exist.', p_soldier_id;
    END IF;

    INSERT INTO DIETARY_RESTRICTION (soldier_id, restriction_type, severity)
    VALUES (p_soldier_id, p_type, p_severity);
END;
$$;

-- Test: add a restriction to soldier 1 (should succeed)
CALL add_dietary_restriction(1, 'Gluten', 'Moderate');

-- Confirm the row was inserted
SELECT * FROM DIETARY_RESTRICTION
WHERE soldier_id = 1 AND restriction_type = 'Gluten';

-- Test with a non-existent soldier (uncomment to see the error):
-- CALL add_dietary_restriction(999999, 'Dairy', 'Severe');


-- ============================================================
-- TRIGGER T1 : trg_check_soldier_active
-- Event : BEFORE INSERT on DIETARY_RESTRICTION
-- Action: Raise an error if the soldier is not Active.
-- Purpose: Keep data clean — only Active soldiers should get
--          new dietary restrictions added.
-- ============================================================

CREATE OR REPLACE FUNCTION fn_check_soldier_active()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
DECLARE
    v_status TEXT;
BEGIN
    SELECT status INTO v_status
    FROM SOLDIER
    WHERE soldier_id = NEW.soldier_id;

    IF v_status IS NULL OR v_status <> 'Active' THEN
        RAISE EXCEPTION 'Cannot add restriction: soldier % is not Active.', NEW.soldier_id;
    END IF;

    RETURN NEW;
END;
$$;

CREATE OR REPLACE TRIGGER trg_check_soldier_active
BEFORE INSERT ON DIETARY_RESTRICTION
FOR EACH ROW
EXECUTE FUNCTION fn_check_soldier_active();

-- Test T1:
-- Find a discharged soldier, then try to insert a restriction for them.
-- SELECT soldier_id, full_name, status FROM SOLDIER WHERE status = 'Discharged' LIMIT 1;
-- INSERT INTO DIETARY_RESTRICTION (soldier_id, restriction_type, severity)
-- VALUES (<discharged_id>, 'Dairy', 'Mild');
-- Expected: ERROR – soldier is not Active


-- ============================================================
-- TRIGGER T2 : trg_auto_remove_mild_restrictions
-- Event : AFTER UPDATE on SOLDIER
-- Action: When a soldier's status changes to 'Discharged',
--         automatically delete their Mild restrictions.
-- Purpose: Automate routine cleanup so staff do not need to
--          remove these rows manually.
-- ============================================================

CREATE OR REPLACE FUNCTION fn_auto_remove_mild_restrictions()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
    -- Only act when the status just changed to 'Discharged'
    IF NEW.status = 'Discharged' AND OLD.status <> 'Discharged' THEN
        DELETE FROM DIETARY_RESTRICTION
        WHERE soldier_id = NEW.soldier_id
          AND severity   = 'Mild';
    END IF;

    RETURN NEW;
END;
$$;

CREATE OR REPLACE TRIGGER trg_auto_remove_mild_restrictions
AFTER UPDATE ON SOLDIER
FOR EACH ROW
EXECUTE FUNCTION fn_auto_remove_mild_restrictions();

-- Test T2:
-- 1. Find an Active soldier who has Mild restrictions:
--    SELECT s.soldier_id, s.full_name
--    FROM SOLDIER s
--    JOIN DIETARY_RESTRICTION dr ON s.soldier_id = dr.soldier_id
--    WHERE s.status = 'Active' AND dr.severity = 'Mild' LIMIT 1;
--
-- 2. Discharge them:
--    UPDATE SOLDIER SET status = 'Discharged' WHERE soldier_id = <id>;
--
-- 3. Confirm their Mild rows are gone (trigger ran automatically):
--    SELECT * FROM DIETARY_RESTRICTION WHERE soldier_id = <id> AND severity = 'Mild';
--    Expected: 0 rows


-- ============================================================
-- End of Functions.sql
-- ============================================================
