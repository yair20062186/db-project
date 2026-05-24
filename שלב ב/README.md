# Stage B – Queries, Constraints, Indexes, Transactions

**IDF Food & Dining Hall Management System**  
Author: Yair Shushan | 215973686

---

## Overview

Stage B adds four SQL files on top of the schema and data created in Stage A.
Each file is independent and can be run directly in psql or pgAdmin.

---

## Files

| File | Purpose |
|------|---------|
| `Queries.sql` | 8 SELECT queries (4 as paired A/B forms) + 3 DELETEs + 3 UPDATEs |
| `Constraints.sql` | 3 new CHECK constraints added with ALTER TABLE |
| `Index.sql` | 3 B-Tree indexes with EXPLAIN ANALYZE before/after |
| `RollbackCommit.sql` | Transaction demos: one ROLLBACK, one COMMIT |

---

## Queries.sql

### Paired queries (two techniques, same result)

| Query | What it returns | Technique A | Technique B |
|-------|----------------|-------------|-------------|
| Q1 | Active soldiers with a SEVERE dietary restriction | JOIN + DISTINCT | EXISTS subquery |
| Q2 | Dining halls above the average session count | Subquery in HAVING | CTE (WITH clause) |
| Q3 | Menu items served in more than 50 sessions | JOIN + GROUP BY + HAVING | Correlated subquery |
| Q4 | Soldiers with above-average restriction count | GROUP BY + HAVING | CTE (WITH clause) |

### Additional queries (single form)

| Query | What it returns |
|-------|----------------|
| Q5 | Meal sessions grouped by year, month, and meal type |
| Q6 | Most popular menu items per category (by total portions) |
| Q7 | Inventory items expiring within 30 days (with urgency label) |
| Q8 | Most active dining halls in the last 90 days |

### DELETE queries

| Query | What it deletes |
|-------|----------------|
| D1 | Inventory rows expired more than 30 days ago |
| D2 | Discharged soldiers who enlisted more than 5 years ago |
| D3 | Mild restrictions belonging to discharged soldiers |

### UPDATE queries

| Query | What it updates |
|-------|----------------|
| U1 | Promotes Privates to First Private after 2+ years of service |
| U2 | Deactivates dining halls with no sessions in the past year |
| U3 | Raises price 10% on cheap kosher Main-category items |

---

## Constraints.sql

Three CHECK constraints are added to existing tables using `ALTER TABLE … ADD CONSTRAINT … CHECK (…)`.

| Table | Constraint Name | Rule |
|-------|----------------|------|
| SOLDIER | chk_personal_number_min_length | personal_number must be at least 5 characters |
| DINING_HALL | chk_capacity_range | capacity must be between 10 and 2000 |
| MENU_ITEM | chk_price_upper_bound | price must be 500.00 or less |

Each constraint is followed by:
1. A valid INSERT that succeeds.
2. A violating INSERT that produces an expected error.
3. A DELETE to clean up the test rows.

---

## Index.sql

Three B-Tree indexes are created to speed up the most common range queries.

| Index Name | Table | Column(s) | Queries accelerated |
|------------|-------|-----------|---------------------|
| idx_meal_session_date | MEAL_SESSION | meal_date | Q5, Q8, U2 |
| idx_dietary_soldier_severity | DIETARY_RESTRICTION | soldier_id, severity | Q1-A/B, Q4-A/B, D3 |
| idx_inventory_expiry | INVENTORY | expiry_date | Q7, D1 |

For each index the file shows:
- `EXPLAIN ANALYZE` before the index (sequential scan expected).
- `CREATE INDEX` statement.
- `EXPLAIN ANALYZE` after the index (index scan expected, faster).

---

## RollbackCommit.sql

### Section 8 – ROLLBACK demo
1. Read baseline prices for Main-category menu items.
2. `BEGIN` → `UPDATE` prices by +20%.
3. Read prices inside the open transaction (shows the change).
4. `ROLLBACK` → prices revert to the original values.
5. Read prices again to confirm the rollback worked.

### Section 9 – COMMIT demo
1. Read baseline ranks for eligible Privates.
2. `BEGIN` → `UPDATE` rank to `First Private`.
3. Read ranks inside the open transaction (shows the change).
4. `COMMIT` → changes become permanent.
5. Read ranks again to confirm they are saved.

---

## How to run

```bash
# Connect to your database
psql -U postgres -d idf_dining

# Run each file
\i 'path/to/Queries.sql'
\i 'path/to/Constraints.sql'
\i 'path/to/Index.sql'
\i 'path/to/RollbackCommit.sql'
```

Run `Constraints.sql` and `Index.sql` only once; running them a second time will
raise "already exists" errors unless the DROP / IF EXISTS lines are uncommented first.
