-- ============================================================
-- IDF Food & Dining Hall Management System
-- Author : Yair Shushan | 215973686
-- Stage  : Stage C – Integration
--
-- Integration Method A:
--   We received a backup from the partner system (Iron Shield
--   Armory Management). We import the relevant tables from that
--   backup into our database, then create a link table that
--   connects soldiers who appear in both systems.
--
-- Tables created here:
--   ARMORY_SOLDIER    – soldiers from the partner armory system
--   ARMORY_WEAPON     – weapons from the partner system
--   WEAPON_ASSIGNMENT – which armory soldier holds which weapon
--   SOLDIER_LINK      – links our SOLDIER rows to ARMORY_SOLDIER rows
-- ============================================================


-- ============================================================
-- Step 1: Create the partner tables
-- These tables store data that was exported from the armory system.
-- ============================================================

-- Soldiers in the armory system (different schema from our SOLDIER table)
CREATE TABLE IF NOT EXISTS ARMORY_SOLDIER (
    armory_id       INT          PRIMARY KEY,
    first_name      VARCHAR(30)  NOT NULL,
    last_name       VARCHAR(30)  NOT NULL,
    phone           VARCHAR(15),
    rank_name       VARCHAR(30),
    unit_name       VARCHAR(50)
);

-- Weapons tracked by the armory
CREATE TABLE IF NOT EXISTS ARMORY_WEAPON (
    weapon_id       INT          PRIMARY KEY,
    weapon_type     VARCHAR(50)  NOT NULL,
    serial_number   VARCHAR(30)  NOT NULL,
    weapon_status   VARCHAR(30)  DEFAULT 'Active'
);

-- Which weapon is assigned to which armory soldier
CREATE TABLE IF NOT EXISTS WEAPON_ASSIGNMENT (
    assignment_id   INT          PRIMARY KEY,
    armory_id       INT          NOT NULL REFERENCES ARMORY_SOLDIER(armory_id),
    weapon_id       INT          NOT NULL REFERENCES ARMORY_WEAPON(weapon_id),
    assigned_date   DATE         NOT NULL
);

-- Link table: maps our soldiers to armory soldiers
-- This lets us join data across both systems when needed.
CREATE TABLE IF NOT EXISTS SOLDIER_LINK (
    our_soldier_id    INT  NOT NULL REFERENCES SOLDIER(soldier_id),
    armory_soldier_id INT  NOT NULL REFERENCES ARMORY_SOLDIER(armory_id),
    linked_at         DATE NOT NULL DEFAULT CURRENT_DATE,
    PRIMARY KEY (our_soldier_id, armory_soldier_id)
);


-- ============================================================
-- Step 2: Insert sample data from the partner backup
-- In a real integration this would be a bulk import from the
-- pg_dump backup file. Here we insert 5 representative rows.
-- ============================================================

INSERT INTO ARMORY_SOLDIER (armory_id, first_name, last_name, phone, rank_name, unit_name) VALUES
    (1001, 'David',    'Cohen',    '050-1111111', 'Sergeant',        'Golani Brigade'),
    (1002, 'Michal',   'Levy',     '052-2222222', 'Private',         'Nahal Brigade'),
    (1003, 'Yossi',    'Ben-David','054-3333333', 'First Sergeant',  'Paratroopers'),
    (1004, 'Rivka',    'Mizrahi',  '050-4444444', 'Second Lieutenant','Armored Corps'),
    (1005, 'Eli',      'Shapiro',  '052-5555555', 'Private',         'Artillery');

INSERT INTO ARMORY_WEAPON (weapon_id, weapon_type, serial_number, weapon_status) VALUES
    (101, 'Assault Rifle', 'AR-20010', 'Active'),
    (102, 'Pistol',        'PS-30020', 'Active'),
    (103, 'Sniper Rifle',  'SR-40030', 'Under Maintenance'),
    (104, 'Assault Rifle', 'AR-50040', 'Active'),
    (105, 'Light Machine Gun', 'LM-60050', 'Active');

INSERT INTO WEAPON_ASSIGNMENT (assignment_id, armory_id, weapon_id, assigned_date) VALUES
    (1, 1001, 101, '2024-01-15'),
    (2, 1002, 102, '2024-02-20'),
    (3, 1003, 103, '2024-03-10'),
    (4, 1004, 104, '2024-04-05'),
    (5, 1005, 105, '2024-05-01');

-- Link 5 soldiers from our system to 5 armory soldiers.
-- In a real scenario this matching would be done by personal number or name.
-- Here we manually link soldiers with IDs 1-5 as a demonstration.
INSERT INTO SOLDIER_LINK (our_soldier_id, armory_soldier_id, linked_at) VALUES
    (1, 1001, CURRENT_DATE),
    (2, 1002, CURRENT_DATE),
    (3, 1003, CURRENT_DATE),
    (4, 1004, CURRENT_DATE),
    (5, 1005, CURRENT_DATE);


-- ============================================================
-- Step 3: Verify the integration
-- This query joins all four tables to show which soldiers from
-- our system are linked to the armory, and what weapon they hold.
-- ============================================================

SELECT
    s.full_name           AS our_soldier,
    s.unit                AS our_unit,
    a.first_name || ' ' || a.last_name AS armory_name,
    a.rank_name           AS armory_rank,
    w.weapon_type,
    w.serial_number
FROM SOLDIER s
JOIN SOLDIER_LINK      sl ON s.soldier_id    = sl.our_soldier_id
JOIN ARMORY_SOLDIER    a  ON sl.armory_soldier_id = a.armory_id
JOIN WEAPON_ASSIGNMENT wa ON a.armory_id     = wa.armory_id
JOIN ARMORY_WEAPON     w  ON wa.weapon_id    = w.weapon_id
ORDER BY s.full_name;


-- ============================================================
-- End of Integrate.sql
-- ============================================================
