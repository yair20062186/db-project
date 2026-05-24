-- ============================================================
-- IDF Food & Dining Hall Management System
-- Author : Yair Shushan | 215973686
-- Stage  : Stage C – Views
--
-- Two views are created, each followed by two SELECT queries.
--
--   V1 – V_ACTIVE_RESTRICTIONS
--        Shows active soldiers and their dietary restrictions.
--        Tables used: SOLDIER, DIETARY_RESTRICTION (2 tables)
--
--   V2 – V_ARMORY_ASSIGNMENTS
--        Shows armory soldiers and the weapons assigned to them.
--        Tables used: ARMORY_SOLDIER, WEAPON_ASSIGNMENT,
--                     ARMORY_WEAPON (3 tables)
-- ============================================================


-- ============================================================
-- VIEW 1 : V_ACTIVE_RESTRICTIONS
-- Joins SOLDIER and DIETARY_RESTRICTION to show every active
-- soldier together with their dietary restrictions.
-- A LEFT JOIN is used so soldiers with NO restrictions still
-- appear in the view (their restriction columns will be NULL).
-- ============================================================

CREATE OR REPLACE VIEW V_ACTIVE_RESTRICTIONS AS
SELECT
    s.soldier_id,
    s.full_name,
    s.unit,
    s.rank,
    dr.restriction_type,
    dr.severity,
    dr.allergen_name
FROM SOLDIER s
LEFT JOIN DIETARY_RESTRICTION dr ON s.soldier_id = dr.soldier_id
WHERE s.status = 'Active';


-- Query 1-A : All active soldiers who have a SEVERE restriction
SELECT full_name, unit, rank, restriction_type, allergen_name
FROM V_ACTIVE_RESTRICTIONS
WHERE severity = 'Severe'
ORDER BY unit, full_name;


-- Query 1-B : Count of active soldiers per restriction severity
SELECT
    severity,
    COUNT(*) AS soldier_count
FROM V_ACTIVE_RESTRICTIONS
WHERE severity IS NOT NULL
GROUP BY severity
ORDER BY soldier_count DESC;


-- ============================================================
-- VIEW 2 : V_ARMORY_ASSIGNMENTS
-- Joins ARMORY_SOLDIER, WEAPON_ASSIGNMENT, and ARMORY_WEAPON
-- to show which weapon each armory soldier is carrying.
-- Only soldiers who have an active weapon assignment appear.
-- ============================================================

CREATE OR REPLACE VIEW V_ARMORY_ASSIGNMENTS AS
SELECT
    a.armory_id,
    a.first_name || ' ' || a.last_name AS soldier_name,
    a.rank_name,
    a.unit_name,
    w.weapon_type,
    w.serial_number,
    w.weapon_status,
    wa.assigned_date
FROM ARMORY_SOLDIER    a
JOIN WEAPON_ASSIGNMENT wa ON a.armory_id  = wa.armory_id
JOIN ARMORY_WEAPON     w  ON wa.weapon_id = w.weapon_id;


-- Query 2-A : All armory soldiers and the weapon they carry
SELECT soldier_name, rank_name, unit_name, weapon_type, serial_number
FROM V_ARMORY_ASSIGNMENTS
ORDER BY soldier_name;


-- Query 2-B : Count of soldiers carrying each type of weapon
SELECT
    weapon_type,
    COUNT(*) AS soldiers_armed
FROM V_ARMORY_ASSIGNMENTS
GROUP BY weapon_type
ORDER BY soldiers_armed DESC;


-- ============================================================
-- End of Views.sql
-- ============================================================
