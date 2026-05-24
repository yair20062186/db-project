-- ============================================================
-- IDF Food & Dining Hall Management System
-- Author : Yair Shushan | 215973686
-- Stage  : Stage B – Queries
-- ============================================================


-- ============================================================
-- PAIRED SELECT QUERIES
-- Each question is answered two ways to show different SQL
-- techniques that produce the same result.
-- ============================================================

-- ------------------------------------------------------------
-- Q1-A : Active soldiers with at least one SEVERE restriction
-- Technique: JOIN + DISTINCT
-- DISTINCT prevents duplicate rows when a soldier has more than
-- one severe restriction.
-- ------------------------------------------------------------
SELECT DISTINCT
    s.full_name,
    s.unit,
    s.rank,
    s.phone
FROM SOLDIER s
JOIN DIETARY_RESTRICTION dr ON s.soldier_id = dr.soldier_id
WHERE dr.severity = 'Severe'
  AND s.status    = 'Active'
ORDER BY s.unit, s.full_name;


-- ------------------------------------------------------------
-- Q1-B : Same result using EXISTS
-- EXISTS stops as soon as one matching row is found,
-- so no DISTINCT is needed.
-- ------------------------------------------------------------
SELECT
    s.full_name,
    s.unit,
    s.rank,
    s.phone
FROM SOLDIER s
WHERE s.status = 'Active'
  AND EXISTS (
      SELECT 1
      FROM DIETARY_RESTRICTION dr
      WHERE dr.soldier_id = s.soldier_id
        AND dr.severity   = 'Severe'
  )
ORDER BY s.unit, s.full_name;


-- ------------------------------------------------------------
-- Q2-A : Dining halls with more sessions than the average
-- Technique: subquery inside HAVING
-- ------------------------------------------------------------
SELECT
    dh.hall_name,
    dh.base_location,
    COUNT(ms.meal_id) AS total_sessions
FROM DINING_HALL dh
JOIN MEAL_SESSION ms ON dh.hall_id = ms.hall_id
WHERE dh.is_active = TRUE
GROUP BY dh.hall_id, dh.hall_name, dh.base_location
HAVING COUNT(ms.meal_id) > (
    SELECT AVG(cnt)
    FROM (
        SELECT COUNT(*) AS cnt
        FROM MEAL_SESSION
        GROUP BY hall_id
    ) AS counts_per_hall
)
ORDER BY total_sessions DESC;


-- ------------------------------------------------------------
-- Q2-B : Same result using a CTE (WITH clause)
-- The CTE computes each hall's total once so we avoid
-- repeating the subquery.
-- ------------------------------------------------------------
WITH hall_counts AS (
    SELECT hall_id, COUNT(*) AS total_sessions
    FROM MEAL_SESSION
    GROUP BY hall_id
)
SELECT
    dh.hall_name,
    dh.base_location,
    hc.total_sessions
FROM DINING_HALL dh
JOIN hall_counts hc ON dh.hall_id = hc.hall_id
WHERE dh.is_active = TRUE
  AND hc.total_sessions > (SELECT AVG(total_sessions) FROM hall_counts)
ORDER BY hc.total_sessions DESC;


-- ------------------------------------------------------------
-- Q3-A : Menu items served in more than 50 meal sessions
-- Technique: JOIN + GROUP BY + HAVING
-- ------------------------------------------------------------
SELECT
    mi.item_name,
    mi.category,
    mi.price,
    COUNT(mm.meal_id) AS times_served
FROM MENU_ITEM mi
JOIN MEAL_MENU mm ON mi.item_id = mm.item_id
GROUP BY mi.item_id, mi.item_name, mi.category, mi.price
HAVING COUNT(mm.meal_id) > 50
ORDER BY times_served DESC;


-- ------------------------------------------------------------
-- Q3-B : Same result using a correlated subquery
-- For each menu item a subquery counts how many times it
-- appeared.  Easier to read; slower on large tables.
-- ------------------------------------------------------------
SELECT
    mi.item_name,
    mi.category,
    mi.price,
    (SELECT COUNT(*)
     FROM MEAL_MENU mm
     WHERE mm.item_id = mi.item_id) AS times_served
FROM MENU_ITEM mi
WHERE (
    SELECT COUNT(*)
    FROM MEAL_MENU mm
    WHERE mm.item_id = mi.item_id
) > 50
ORDER BY mi.item_name;


-- ------------------------------------------------------------
-- Q4-A : Soldiers with more restrictions than the average soldier
-- Technique: GROUP BY + HAVING with a subquery for the average
-- ------------------------------------------------------------
SELECT
    s.full_name,
    s.unit,
    s.rank,
    COUNT(dr.restriction_id) AS restriction_count
FROM SOLDIER s
JOIN DIETARY_RESTRICTION dr ON s.soldier_id = dr.soldier_id
GROUP BY s.soldier_id, s.full_name, s.unit, s.rank
HAVING COUNT(dr.restriction_id) > (
    SELECT AVG(cnt)
    FROM (
        SELECT COUNT(*) AS cnt
        FROM DIETARY_RESTRICTION
        GROUP BY soldier_id
    ) AS soldier_counts
)
ORDER BY restriction_count DESC;


-- ------------------------------------------------------------
-- Q4-B : Same result using a CTE
-- ------------------------------------------------------------
WITH restriction_counts AS (
    SELECT soldier_id, COUNT(*) AS cnt
    FROM DIETARY_RESTRICTION
    GROUP BY soldier_id
)
SELECT
    s.full_name,
    s.unit,
    s.rank,
    rc.cnt AS restriction_count
FROM SOLDIER s
JOIN restriction_counts rc ON s.soldier_id = rc.soldier_id
WHERE rc.cnt > (SELECT AVG(cnt) FROM restriction_counts)
ORDER BY restriction_count DESC;


-- ============================================================
-- ADDITIONAL SELECT QUERIES
-- ============================================================

-- ------------------------------------------------------------
-- Q5 : Sessions grouped by year, month, and meal type
-- EXTRACT pulls the numeric year and month from the date.
-- ------------------------------------------------------------
SELECT
    EXTRACT(YEAR  FROM meal_date) AS meal_year,
    EXTRACT(MONTH FROM meal_date) AS meal_month,
    meal_type,
    COUNT(*)          AS session_count,
    SUM(diners_count) AS total_diners
FROM MEAL_SESSION
GROUP BY
    EXTRACT(YEAR  FROM meal_date),
    EXTRACT(MONTH FROM meal_date),
    meal_type
ORDER BY meal_year DESC, meal_month DESC;


-- ------------------------------------------------------------
-- Q6 : Most popular menu items per category (by portions served)
-- ------------------------------------------------------------
SELECT
    mi.category,
    mi.item_name,
    mi.price,
    COUNT(mm.meal_id) AS sessions_appeared,
    SUM(mm.quantity)  AS total_portions
FROM MENU_ITEM mi
JOIN MEAL_MENU mm ON mi.item_id = mm.item_id
GROUP BY mi.item_id, mi.category, mi.item_name, mi.price
ORDER BY mi.category, total_portions DESC;


-- ------------------------------------------------------------
-- Q7 : Inventory items expiring within the next 30 days
-- CASE gives each row an urgency label so staff know what to
-- use up first.
-- ------------------------------------------------------------
SELECT
    dh.hall_name,
    mi.item_name,
    inv.quantity,
    inv.expiry_date,
    CASE
        WHEN inv.expiry_date < CURRENT_DATE         THEN 'Expired'
        WHEN inv.expiry_date < CURRENT_DATE + 7     THEN 'Critical'
        ELSE                                             'Warning'
    END AS urgency_label
FROM INVENTORY inv
JOIN DINING_HALL dh ON inv.hall_id = dh.hall_id
JOIN MENU_ITEM   mi ON inv.item_id = mi.item_id
WHERE inv.expiry_date <= CURRENT_DATE + INTERVAL '30 days'
  AND inv.quantity     > 0
ORDER BY inv.expiry_date;


-- ------------------------------------------------------------
-- Q8 : Most active dining halls in the last 90 days
-- Only halls with at least 5 sessions are included.
-- ------------------------------------------------------------
SELECT
    dh.hall_name,
    dh.base_location,
    COUNT(ms.meal_id)    AS session_count,
    SUM(ms.diners_count) AS total_diners
FROM DINING_HALL dh
JOIN MEAL_SESSION ms ON dh.hall_id = ms.hall_id
WHERE ms.meal_date >= CURRENT_DATE - INTERVAL '90 days'
  AND dh.is_active  = TRUE
GROUP BY dh.hall_id, dh.hall_name, dh.base_location
HAVING COUNT(ms.meal_id) >= 5
ORDER BY session_count DESC;


-- ============================================================
-- DELETE QUERIES
-- ============================================================

-- D1 : Remove inventory rows expired more than 30 days ago
DELETE FROM INVENTORY
WHERE expiry_date < CURRENT_DATE - INTERVAL '30 days';


-- D2 : Remove discharged soldiers who enlisted more than 5 years ago
DELETE FROM SOLDIER
WHERE status          = 'Discharged'
  AND enlistment_date < CURRENT_DATE - INTERVAL '5 years';


-- D3 : Remove Mild restrictions of all discharged soldiers
DELETE FROM DIETARY_RESTRICTION
WHERE severity   = 'Mild'
  AND soldier_id IN (
      SELECT soldier_id
      FROM   SOLDIER
      WHERE  status = 'Discharged'
  );


-- ============================================================
-- UPDATE QUERIES
-- ============================================================

-- U1 : Promote Privates to First Private after 2+ years of service
UPDATE SOLDIER
SET    rank = 'First Private'
WHERE  rank            = 'Private'
  AND  status          = 'Active'
  AND  enlistment_date < CURRENT_DATE - INTERVAL '2 years';


-- U2 : Deactivate dining halls with no sessions in the last year
UPDATE DINING_HALL
SET    is_active = FALSE
WHERE  is_active = TRUE
  AND  hall_id NOT IN (
      SELECT DISTINCT hall_id
      FROM   MEAL_SESSION
      WHERE  meal_date >= CURRENT_DATE - INTERVAL '365 days'
  );


-- U3 : Apply a 10% price increase to cheap kosher Main items
-- ROUND keeps the result to 2 decimal places.
UPDATE MENU_ITEM
SET    price = ROUND((price * 1.10)::NUMERIC, 2)
WHERE  category  = 'Main'
  AND  is_kosher = TRUE
  AND  price     < 30.00;


-- ============================================================
-- End of Queries.sql
-- ============================================================
