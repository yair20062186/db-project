-- ============================================================
-- Project  : IDF Food & Dining Hall Management System
--            מערכת ניהול מזון והסעדה - צה"ל
-- Author   : Yair Shushan  |  215973686
-- Stage    : שלב א – Create Tables
-- Description:
--   Creates all 8 tables in dependency order so every
--   FOREIGN KEY reference points to an already-existing table.
-- ============================================================


-- ------------------------------------------------------------
-- TABLE 1: SOLDIER
-- Stores basic information about each soldier.
-- No foreign-key dependencies → created first.
-- ------------------------------------------------------------
CREATE TABLE SOLDIER (
    soldier_id       SERIAL          PRIMARY KEY,
    personal_number  VARCHAR(20)     UNIQUE NOT NULL,
    full_name        VARCHAR(100)    NOT NULL,
    unit             VARCHAR(100),
    rank             VARCHAR(50),
    status           VARCHAR(20)     DEFAULT 'Active'
                                     CHECK (status IN ('Active', 'Discharged', 'Reserve')),
    enlistment_date  DATE,
    birth_date       DATE,
    phone            VARCHAR(20),
    -- Logical constraint: enlistment must be after birth
    CONSTRAINT chk_soldier_dates CHECK (
        birth_date IS NULL
        OR enlistment_date IS NULL
        OR enlistment_date > birth_date
    )
);


-- ------------------------------------------------------------
-- TABLE 2: DINING_HALL
-- Stores details about dining halls on different IDF bases.
-- No foreign-key dependencies → created second.
-- ------------------------------------------------------------
CREATE TABLE DINING_HALL (
    hall_id         SERIAL          PRIMARY KEY,
    hall_name       VARCHAR(100)    NOT NULL,
    base_location   VARCHAR(100)    NOT NULL,
    capacity        INT             CHECK (capacity > 0),
    hall_type       VARCHAR(30)     CHECK (hall_type IN ('Permanent', 'Temporary', 'Field')),
    opening_year    INT             CHECK (opening_year >= 1948),
    is_active       BOOLEAN         DEFAULT TRUE
);


-- ------------------------------------------------------------
-- TABLE 3: SUPPLIER
-- Food suppliers – who supplies what.
-- No foreign-key dependencies → created third.
-- ------------------------------------------------------------
CREATE TABLE SUPPLIER (
    supplier_id     SERIAL          PRIMARY KEY,
    supplier_name   VARCHAR(100)    NOT NULL,
    contact_person  VARCHAR(100),
    contact_phone   VARCHAR(20),
    supply_type     VARCHAR(50),
    is_active       BOOLEAN         DEFAULT TRUE
);


-- ------------------------------------------------------------
-- TABLE 4: DIETARY_RESTRICTION
-- Dietary restrictions per soldier (allergies, kosher, vegan…).
-- Depends on: SOLDIER
-- ------------------------------------------------------------
CREATE TABLE DIETARY_RESTRICTION (
    restriction_id   SERIAL          PRIMARY KEY,
    soldier_id       INT             NOT NULL,
    restriction_type VARCHAR(50)     NOT NULL,
    severity         VARCHAR(20)     CHECK (severity IN ('Mild', 'Moderate', 'Severe')),
    allergen_name    VARCHAR(100),
    details          TEXT,
    CONSTRAINT fk_dietrestr_soldier
        FOREIGN KEY (soldier_id)
        REFERENCES SOLDIER (soldier_id)
        ON DELETE CASCADE
);


-- ------------------------------------------------------------
-- TABLE 5: MENU_ITEM
-- Food items that can appear on any meal menu.
-- No foreign-key dependencies → created fifth.
-- ------------------------------------------------------------
CREATE TABLE MENU_ITEM (
    item_id         SERIAL          PRIMARY KEY,
    item_name       VARCHAR(100)    NOT NULL,
    category        VARCHAR(50),
    price           DECIMAL(6,2)    CHECK (price >= 0),
    calories        INT             CHECK (calories >= 0),
    is_kosher       BOOLEAN         DEFAULT TRUE,
    is_vegetarian   BOOLEAN         DEFAULT FALSE,
    is_vegan        BOOLEAN         DEFAULT FALSE,
    allergens       TEXT,
    -- A vegan item must also be vegetarian
    CONSTRAINT chk_vegan_vegetarian CHECK (
        is_vegan = FALSE OR is_vegetarian = TRUE
    )
);


-- ------------------------------------------------------------
-- TABLE 6: MEAL_SESSION
-- Documents every meal service event (when, where, how many).
-- Depends on: DINING_HALL
-- ------------------------------------------------------------
CREATE TABLE MEAL_SESSION (
    meal_id         SERIAL          PRIMARY KEY,
    hall_id         INT             NOT NULL,
    meal_type       VARCHAR(20)     NOT NULL
                                    CHECK (meal_type IN ('Breakfast', 'Lunch', 'Dinner', 'Snack')),
    meal_date       DATE            NOT NULL,
    meal_time       TIME,
    diners_count    INT             CHECK (diners_count >= 0),
    cost_per_meal   DECIMAL(8,2)    CHECK (cost_per_meal >= 0),
    CONSTRAINT fk_mealsession_hall
        FOREIGN KEY (hall_id)
        REFERENCES DINING_HALL (hall_id)
        ON DELETE CASCADE
);


-- ------------------------------------------------------------
-- TABLE 7: MEAL_MENU  (junction / bridge table)
-- Resolves the N:M relationship between MEAL_SESSION and
-- MENU_ITEM – one meal can contain many items; one item can
-- appear in many meals.
-- Depends on: MEAL_SESSION, MENU_ITEM
-- ------------------------------------------------------------
CREATE TABLE MEAL_MENU (
    menu_id     SERIAL  PRIMARY KEY,
    meal_id     INT     NOT NULL,
    item_id     INT     NOT NULL,
    quantity    INT     CHECK (quantity > 0),
    CONSTRAINT fk_mealmenu_session
        FOREIGN KEY (meal_id)
        REFERENCES MEAL_SESSION (meal_id)
        ON DELETE CASCADE,
    CONSTRAINT fk_mealmenu_item
        FOREIGN KEY (item_id)
        REFERENCES MENU_ITEM (item_id)
        ON DELETE CASCADE
);


-- ------------------------------------------------------------
-- TABLE 8: INVENTORY
-- Tracks stock levels of each menu item in each dining hall.
-- Depends on: DINING_HALL, MENU_ITEM
-- ------------------------------------------------------------
CREATE TABLE INVENTORY (
    inventory_id  SERIAL      PRIMARY KEY,
    hall_id       INT         NOT NULL,
    item_id       INT         NOT NULL,
    quantity      INT         CHECK (quantity >= 0),
    unit          VARCHAR(20),
    expiry_date   DATE,
    last_updated  TIMESTAMP   DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_inventory_hall
        FOREIGN KEY (hall_id)
        REFERENCES DINING_HALL (hall_id)
        ON DELETE CASCADE,
    CONSTRAINT fk_inventory_item
        FOREIGN KEY (item_id)
        REFERENCES MENU_ITEM (item_id)
        ON DELETE CASCADE
);


-- ============================================================
-- End of createTables.sql
-- ============================================================
