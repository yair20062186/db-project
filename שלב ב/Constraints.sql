-- ============================================================
-- IDF Food & Dining Hall Management System
-- Author : Yair Shushan | 215973686
-- Stage  : Stage B – Constraints
--
-- Adds 3 CHECK constraints to existing tables using ALTER TABLE.
-- After each constraint:
--   1. A valid INSERT is shown (should succeed).
--   2. A violating INSERT is shown (should produce an error).
--   3. The test row is removed with DELETE.
-- ============================================================


-- ============================================================
-- CONSTRAINT 1
-- Table  : SOLDIER
-- Name   : chk_personal_number_min_length
-- Rule   : personal_number must be at least 5 characters long.
-- Reason : IDF personal numbers are never shorter than 5 digits,
--          so shorter values are data-entry mistakes.
-- ============================================================

ALTER TABLE SOLDIER
ADD CONSTRAINT chk_personal_number_min_length
CHECK (LENGTH(personal_number) >= 5);

-- Valid INSERT – should succeed
INSERT INTO SOLDIER
    (personal_number, full_name, unit, rank, status, enlistment_date, birth_date, phone)
VALUES
    ('8123456', 'Test Soldier Valid', 'Golani', 'Private', 'Active',
     '2020-01-01', '2002-01-01', '050-1234567');

-- Violating INSERT – personal_number too short (only 3 chars)
-- Expected: ERROR – violates check constraint "chk_personal_number_min_length"
INSERT INTO SOLDIER
    (personal_number, full_name, unit, rank, status, enlistment_date, birth_date, phone)
VALUES
    ('123', 'Bad Soldier', 'Navy', 'Private', 'Active',
     '2021-01-01', '2003-01-01', '050-9999999');

-- Cleanup
DELETE FROM SOLDIER WHERE personal_number = '8123456';


-- ============================================================
-- CONSTRAINT 2
-- Table  : DINING_HALL
-- Name   : chk_capacity_range
-- Rule   : capacity must be between 10 and 2000 (inclusive).
-- Reason : Fewer than 10 seats is not a functional dining hall;
--          more than 2000 exceeds any realistic IDF facility.
-- ============================================================

ALTER TABLE DINING_HALL
DROP CONSTRAINT IF EXISTS chk_capacity_range;

ALTER TABLE DINING_HALL
ADD CONSTRAINT chk_capacity_range
CHECK (capacity BETWEEN 10 AND 2000);

-- Valid INSERT – should succeed
INSERT INTO DINING_HALL
    (hall_name, base_location, capacity, hall_type, opening_year, is_active)
VALUES
    ('Test Cafeteria Valid', 'Bahad 1', 150, 'Permanent', 2010, TRUE);

-- Violating INSERT – capacity is way too large
-- Expected: ERROR – violates check constraint "chk_capacity_range"
INSERT INTO DINING_HALL
    (hall_name, base_location, capacity, hall_type, opening_year, is_active)
VALUES
    ('Mega Hall', 'Test Base', 9999, 'Permanent', 2020, TRUE);

-- Cleanup
DELETE FROM DINING_HALL WHERE hall_name = 'Test Cafeteria Valid';


-- ============================================================
-- CONSTRAINT 3
-- Table  : MENU_ITEM
-- Name   : chk_price_upper_bound
-- Rule   : price must not exceed 500.00 (ILS).
-- Reason : Any per-serving price above 500 is almost certainly
--          a data-entry error and would corrupt cost reports.
-- ============================================================

ALTER TABLE MENU_ITEM
ADD CONSTRAINT chk_price_upper_bound
CHECK (price <= 500.00);

-- Valid INSERT – should succeed
INSERT INTO MENU_ITEM
    (item_name, category, price, calories, is_kosher, is_vegetarian, is_vegan)
VALUES
    ('Test Valid Dish', 'Main', 45.00, 400, TRUE, FALSE, FALSE);

-- Violating INSERT – price is way above 500
-- Expected: ERROR – violates check constraint "chk_price_upper_bound"
INSERT INTO MENU_ITEM
    (item_name, category, price, calories, is_kosher, is_vegetarian, is_vegan)
VALUES
    ('Ultra Luxury Gala Meal', 'Main', 999.99, 500, TRUE, FALSE, FALSE);

-- Cleanup
DELETE FROM MENU_ITEM WHERE item_name = 'Test Valid Dish';


-- ============================================================
-- Summary
-- ============================================================
--
--  Table        | Constraint Name                 | Rule
--  -------------|----------------------------------|----------
--  SOLDIER      | chk_personal_number_min_length  | length >= 5
--  DINING_HALL  | chk_capacity_range              | 10 – 2000
--  MENU_ITEM    | chk_price_upper_bound           | <= 500.00
--
-- ============================================================
-- End of Constraints.sql
-- ============================================================
