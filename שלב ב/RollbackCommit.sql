-- ============================================================
-- IDF Food & Dining Hall Management System
-- Author : Yair Shushan | 215973686
-- Stage  : Stage B – ROLLBACK & COMMIT Demonstrations
--
-- Section 1: UPDATE → show change → ROLLBACK → confirm revert
-- Section 2: UPDATE → show change → COMMIT  → confirm save
--
-- Run each section as a single block in psql or pgAdmin.
-- The SELECT statements show the database state at each step.
-- ============================================================


-- ============================================================
-- SECTION 1 – ROLLBACK DEMONSTRATION
-- We raise Main-item prices 20% inside a transaction,
-- then ROLLBACK to undo all changes.
-- ============================================================

-- Step 1: See prices BEFORE the transaction
SELECT item_name, category, price AS price_before
FROM MENU_ITEM
WHERE category = 'Main'
ORDER BY price DESC
LIMIT 10;

-- Step 2: Start the transaction and update prices
BEGIN;

UPDATE MENU_ITEM
SET    price = ROUND((price * 1.20)::NUMERIC, 2)
WHERE  category = 'Main';

-- Step 3: See prices AFTER the UPDATE (still inside the transaction)
SELECT item_name, category, price AS price_after_update
FROM MENU_ITEM
WHERE category = 'Main'
ORDER BY price DESC
LIMIT 10;

-- Step 4: Undo all changes
ROLLBACK;

-- Step 5: Confirm prices are back to the original values
-- Expected: exactly the same as Step 1
SELECT item_name, category, price AS price_after_rollback
FROM MENU_ITEM
WHERE category = 'Main'
ORDER BY price DESC
LIMIT 10;

-- Explanation:
-- ROLLBACK cancels every change made since BEGIN.
-- The data returns to exactly the state it was in before the transaction.


-- ============================================================
-- SECTION 2 – COMMIT DEMONSTRATION
-- We promote eligible Privates to First Private inside a
-- transaction, then COMMIT to save the changes permanently.
-- ============================================================

-- Step 1: See current ranks BEFORE the transaction
SELECT full_name, rank AS rank_before, enlistment_date
FROM SOLDIER
WHERE rank   = 'Private'
  AND status = 'Active'
  AND enlistment_date < CURRENT_DATE - INTERVAL '2 years'
ORDER BY enlistment_date
LIMIT 10;

-- Step 2: Count how many soldiers are eligible for promotion
SELECT COUNT(*) AS eligible_count
FROM SOLDIER
WHERE rank   = 'Private'
  AND status = 'Active'
  AND enlistment_date < CURRENT_DATE - INTERVAL '2 years';

-- Step 3: Start the transaction and update ranks
BEGIN;

UPDATE SOLDIER
SET    rank = 'First Private'
WHERE  rank            = 'Private'
  AND  status          = 'Active'
  AND  enlistment_date < CURRENT_DATE - INTERVAL '2 years';

-- Step 4: See ranks AFTER the UPDATE (still inside the transaction)
SELECT full_name, rank AS rank_after_update, enlistment_date
FROM SOLDIER
WHERE rank   = 'First Private'
  AND status = 'Active'
ORDER BY enlistment_date
LIMIT 10;

-- Step 5: Make the changes permanent
COMMIT;

-- Step 6: Confirm changes are saved after COMMIT
-- Expected: the same promoted soldiers still show First Private
SELECT full_name, rank AS rank_after_commit, enlistment_date
FROM SOLDIER
WHERE rank   = 'First Private'
  AND status = 'Active'
ORDER BY enlistment_date
LIMIT 10;

-- Step 7: Confirm the count of First Privates increased
SELECT COUNT(*) AS first_privates_total
FROM SOLDIER
WHERE rank   = 'First Private'
  AND status = 'Active';

-- Explanation:
-- COMMIT makes all changes since BEGIN permanent.
-- After a COMMIT, ROLLBACK cannot undo these changes.


-- ============================================================
-- End of RollbackCommit.sql
-- ============================================================
