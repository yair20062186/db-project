-- ============================================================
-- IDF Food & Dining Hall Management System
-- Author : Yair Shushan | 215973686
-- Stage  : Stage B – Indexes
--
-- Three B-Tree indexes are created.
-- For each index:
--   1. EXPLAIN ANALYZE is run BEFORE to show the query plan
--      without an index (usually a sequential scan).
--   2. The index is created.
--   3. EXPLAIN ANALYZE is run AFTER to show the improved plan
--      (usually an index scan, which is faster).
--
-- Indexes created:
--   idx_meal_session_date         on MEAL_SESSION(meal_date)
--   idx_dietary_soldier_severity  on DIETARY_RESTRICTION(soldier_id, severity)
--   idx_inventory_expiry          on INVENTORY(expiry_date)
-- ============================================================


-- ============================================================
-- INDEX 1 : idx_meal_session_date
-- Table  : MEAL_SESSION
-- Column : meal_date
--
-- Why: Many queries filter meal sessions by date range
-- (e.g. "all sessions this month"). Without an index,
-- PostgreSQL reads every row in the table. With a B-Tree
-- index on meal_date, it jumps directly to the relevant rows.
-- ============================================================

-- BEFORE: run the query without an index
EXPLAIN ANALYZE
SELECT meal_id, hall_id, meal_type, meal_date, diners_count
FROM   MEAL_SESSION
WHERE  meal_date BETWEEN '2023-01-01' AND '2023-12-31'
ORDER  BY meal_date;

-- Create the index
CREATE INDEX idx_meal_session_date
    ON MEAL_SESSION (meal_date);

-- AFTER: run the same query – the plan should now show Index Scan
EXPLAIN ANALYZE
SELECT meal_id, hall_id, meal_type, meal_date, diners_count
FROM   MEAL_SESSION
WHERE  meal_date BETWEEN '2023-01-01' AND '2023-12-31'
ORDER  BY meal_date;


-- ============================================================
-- INDEX 2 : idx_dietary_soldier_severity
-- Table  : DIETARY_RESTRICTION
-- Columns: (soldier_id, severity)  – composite index
--
-- Why: Queries Q1-A and Q1-B filter on BOTH soldier_id AND
-- severity. A composite index satisfies both conditions in
-- one lookup instead of scanning the whole table.
-- ============================================================

-- BEFORE
EXPLAIN ANALYZE
SELECT soldier_id, restriction_type, severity, allergen_name
FROM   DIETARY_RESTRICTION
WHERE  soldier_id = 42
  AND  severity   = 'Severe';

-- Create the index
CREATE INDEX idx_dietary_soldier_severity
    ON DIETARY_RESTRICTION (soldier_id, severity);

-- AFTER
EXPLAIN ANALYZE
SELECT soldier_id, restriction_type, severity, allergen_name
FROM   DIETARY_RESTRICTION
WHERE  soldier_id = 42
  AND  severity   = 'Severe';

-- Also test with the EXISTS query from Q1-B
EXPLAIN ANALYZE
SELECT s.full_name, s.unit, s.rank, s.phone
FROM   SOLDIER s
WHERE  s.status = 'Active'
  AND  EXISTS (
      SELECT 1
      FROM   DIETARY_RESTRICTION dr
      WHERE  dr.soldier_id = s.soldier_id
        AND  dr.severity   = 'Severe'
  )
ORDER BY s.unit, s.full_name;


-- ============================================================
-- INDEX 3 : idx_inventory_expiry
-- Table  : INVENTORY
-- Column : expiry_date
--
-- Why: Q7 and D1 both filter by expiry_date with a range
-- condition. Without an index every row is read even though
-- only a small fraction will match.
-- ============================================================

-- BEFORE
EXPLAIN ANALYZE
SELECT hall_id, item_id, quantity, unit, expiry_date
FROM   INVENTORY
WHERE  expiry_date BETWEEN CURRENT_DATE AND CURRENT_DATE + INTERVAL '30 days'
  AND  quantity > 0
ORDER  BY expiry_date;

-- Create the index
CREATE INDEX idx_inventory_expiry
    ON INVENTORY (expiry_date);

-- AFTER
EXPLAIN ANALYZE
SELECT hall_id, item_id, quantity, unit, expiry_date
FROM   INVENTORY
WHERE  expiry_date BETWEEN CURRENT_DATE AND CURRENT_DATE + INTERVAL '30 days'
  AND  quantity > 0
ORDER  BY expiry_date;


-- ============================================================
-- Drop indexes (run only if you need to reset)
-- ============================================================
-- DROP INDEX IF EXISTS idx_meal_session_date;
-- DROP INDEX IF EXISTS idx_dietary_soldier_severity;
-- DROP INDEX IF EXISTS idx_inventory_expiry;


-- ============================================================
-- Summary
-- ============================================================
--
--  Index Name                    | Table               | Column(s)
--  ------------------------------|---------------------|----------------------
--  idx_meal_session_date         | MEAL_SESSION        | meal_date
--  idx_dietary_soldier_severity  | DIETARY_RESTRICTION | soldier_id, severity
--  idx_inventory_expiry          | INVENTORY           | expiry_date
--
-- ============================================================
-- End of Index.sql
-- ============================================================
