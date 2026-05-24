# mockarooFiles — Alternative Data Import Method

## What is this folder?

This folder is the designated location for the **Mockaroo-based data import method** — one of the three alternative approaches for populating the database, as required by Stage A of the project.

---

## Method Overview

**Mockaroo** (https://www.mockaroo.com) is a web-based mock data generator that allows you to define custom schemas and download data as `.sql`, `.csv`, `.json`, or `.xml` files.

This method was used as an **alternative** to the Python script in the `Programming/` folder.

---

## How to use Mockaroo for this project

1. Go to [https://www.mockaroo.com](https://www.mockaroo.com)
2. Define a schema matching one of the 8 tables (e.g., `SOLDIER`)
3. Configure field types:
   - Use **Row Number** for IDs
   - Use **Full Name** for `full_name`
   - Use **Custom List** for `status`, `rank`, `unit`, `meal_type`, etc.
   - Use **Date** for `birth_date`, `meal_date`, `enlistment_date`, `expiry_date`
   - Use **Number** for `price`, `calories`, `diners_count`
   - Use **Boolean** for `is_kosher`, `is_vegetarian`, `is_vegan`, `is_active`
4. Set the row count to **500** (or 20,000 for `MEAL_SESSION` and `INVENTORY`)
5. Select **SQL** as the output format
6. Download and place the `.sql` file in this folder

---

## Files that would go here

| File | Table | Rows |
|---|---|---|
| `soldier_data.sql` | SOLDIER | 600 |
| `dining_hall_data.sql` | DINING_HALL | 500 |
| `supplier_data.sql` | SUPPLIER | 500 |
| `dietary_restriction_data.sql` | DIETARY_RESTRICTION | 1,000 |
| `menu_item_data.sql` | MENU_ITEM | 500 |
| `meal_session_data.sql` | MEAL_SESSION | 20,000 |
| `meal_menu_data.sql` | MEAL_MENU | 50,000+ |
| `inventory_data.sql` | INVENTORY | 20,000 |

---

## Limitations of Mockaroo vs. the Python script

| Feature | Mockaroo | Python Script (`generate_data.py`) |
|---|---|---|
| FK constraint enforcement | ❌ Manual | ✅ Automatic |
| Custom date logic (birth < enlistment) | ❌ Hard | ✅ Built-in |
| Reproducible output (seeded) | ❌ No | ✅ seed=42 |
| Free row limit | ⚠️ 1,000/download | ✅ Unlimited |
| Requires internet | ✅ Yes | ❌ No |
| Realistic IDF-specific data | ⚠️ Partial | ✅ Full |

---

## Chosen primary method

For this project the **Python script** (`Programming/generate_data.py`) was used as the primary data generation method, producing `insertTables.sql` with full FK integrity, realistic data, and reproducible results. This folder documents the Mockaroo approach as the second alternative method.

---

*Stage A – IDF Food & Dining Hall Management System | Yair Shushan 215973686*
