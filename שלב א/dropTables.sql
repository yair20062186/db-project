-- ============================================================
-- Project  : IDF Food & Dining Hall Management System
--            מערכת ניהול מזון והסעדה - צה"ל
-- Author   : Yair Shushan  |  215973686
-- Stage    : שלב א – Drop Tables
-- Description:
--   Drops all 8 tables in REVERSE dependency order so that
--   child tables (those holding FOREIGN KEYs) are removed
--   before their parent tables.  IF EXISTS prevents errors
--   when a table has already been dropped or never existed.
--
--   Drop order (children → parents):
--     1. MEAL_MENU          depends on MEAL_SESSION + MENU_ITEM
--     2. INVENTORY          depends on DINING_HALL  + MENU_ITEM
--     3. DIETARY_RESTRICTION depends on SOLDIER
--     4. MEAL_SESSION       depends on DINING_HALL
--     5. MENU_ITEM          (now free of all dependents)
--     6. SUPPLIER           (standalone)
--     7. DINING_HALL        (now free of all dependents)
--     8. SOLDIER            (now free of all dependents)
-- ============================================================


-- 1. Bridge table – depends on MEAL_SESSION and MENU_ITEM
DROP TABLE IF EXISTS MEAL_MENU CASCADE;

-- 2. Inventory – depends on DINING_HALL and MENU_ITEM
DROP TABLE IF EXISTS INVENTORY CASCADE;

-- 3. Dietary restrictions – depends on SOLDIER
DROP TABLE IF EXISTS DIETARY_RESTRICTION CASCADE;

-- 4. Meal sessions – depends on DINING_HALL
DROP TABLE IF EXISTS MEAL_SESSION CASCADE;

-- 5. Menu items – now free of all dependents
DROP TABLE IF EXISTS MENU_ITEM CASCADE;

-- 6. Suppliers – standalone, no FK references
DROP TABLE IF EXISTS SUPPLIER CASCADE;

-- 7. Dining halls – now free of all dependents
DROP TABLE IF EXISTS DINING_HALL CASCADE;

-- 8. Soldiers – now free of all dependents
DROP TABLE IF EXISTS SOLDIER CASCADE;


-- ============================================================
-- End of dropTables.sql
-- ============================================================
