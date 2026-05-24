# Stage C – Integration, Views, Functions & Triggers

**IDF Food & Dining Hall Management System**  
Author: Yair Shushan | 215973686

---

## Overview

Stage C connects our dining-hall database with the partner **Iron Shield Armory
Management** system using **Integration Method A**: we import a backup from the
partner database and create local copies of the tables we need. A link table
then connects soldiers who appear in both systems.

On top of the integration we add two views, one function, one procedure, and
two triggers — all written in simple PL/pgSQL.

---

## Files

| File | Purpose |
|------|---------|
| `Integrate.sql` | Create partner tables, insert sample data, verify the link |
| `Views.sql` | Two views, two queries each |
| `Functions.sql` | One function, one procedure, two triggers |

---

## Integrate.sql

Creates four new tables in our database and inserts 5 sample rows into each:

| Table | Description |
|-------|-------------|
| `ARMORY_SOLDIER` | Soldiers imported from the armory system |
| `ARMORY_WEAPON` | Weapons tracked by the armory |
| `WEAPON_ASSIGNMENT` | Which armory soldier holds which weapon |
| `SOLDIER_LINK` | Links our SOLDIER rows to ARMORY_SOLDIER rows |

A verification query at the end joins the tables to confirm the integration works.

---

## Views.sql

### V_ACTIVE_RESTRICTIONS

Joins `SOLDIER` and `DIETARY_RESTRICTION` (LEFT JOIN).  
Filter: Active soldiers only.

| Query | What it shows |
|-------|--------------|
| 1-A | All active soldiers with a SEVERE restriction |
| 1-B | Count of active soldiers per restriction severity |

### V_ARMORY_ASSIGNMENTS

Joins `ARMORY_SOLDIER`, `WEAPON_ASSIGNMENT`, and `ARMORY_WEAPON` (3 tables).  
Shows which armory soldier is carrying which weapon.

| Query | What it shows |
|-------|--------------|
| 2-A | All armory soldiers and their weapon details |
| 2-B | Count of soldiers per weapon type |

---

## Functions.sql

### F1 – `get_hall_session_count(p_hall_id INT) RETURNS INT`

Counts meal sessions for a given dining hall and returns the number.

```sql
SELECT get_hall_session_count(1);   -- total sessions for hall 1
```

### P1 – `add_dietary_restriction(p_soldier_id, p_type, p_severity)`

Inserts a new dietary restriction for a soldier.  
Raises an error if the soldier does not exist.

```sql
CALL add_dietary_restriction(1, 'Gluten', 'Moderate');
```

### T1 – `trg_check_soldier_active`

| Item | Value |
|------|-------|
| Event | BEFORE INSERT on `DIETARY_RESTRICTION` |
| Action | Raises an error if the soldier is not `'Active'` |
| Purpose | Prevents adding restrictions to discharged or reserve soldiers |

### T2 – `trg_auto_remove_mild_restrictions`

| Item | Value |
|------|-------|
| Event | AFTER UPDATE on `SOLDIER` |
| Action | Deletes all `Mild` restrictions when a soldier is discharged |
| Purpose | Automates cleanup so staff do not need to do it manually |

---

## How to Run

```bash
psql -U postgres -d idf_dining

-- Integrate.sql must run first (Views and Functions depend on its tables)
\i 'path/to/Integrate.sql'
\i 'path/to/Views.sql'
\i 'path/to/Functions.sql'
```

All files use `CREATE OR REPLACE` or `IF NOT EXISTS`, so they are safe to run
more than once.
