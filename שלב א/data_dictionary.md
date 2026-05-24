# Data Dictionary
## IDF Food & Dining Hall Management System

**Author:** Yair Shushan | **ID:** 215973686  
**Stage:** Stage A | **Database:** PostgreSQL

---

## Table of Contents

1. [SOLDIER](#1-soldier)
2. [DINING_HALL](#2-dining_hall)
3. [SUPPLIER](#3-supplier)
4. [DIETARY_RESTRICTION](#4-dietary_restriction)
5. [MENU_ITEM](#5-menu_item)
6. [MEAL_SESSION](#6-meal_session)
7. [MEAL_MENU](#7-meal_menu)
8. [INVENTORY](#8-inventory)

---

## 1. SOLDIER

Stores basic information about each soldier. This is the root table — dietary restrictions reference it.

**Relationships:** One SOLDIER → Many DIETARY_RESTRICTIONs (1:N)

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| `soldier_id` | `SERIAL` | PRIMARY KEY | Auto-generated unique ID for each soldier |
| `personal_number` | `VARCHAR(20)` | UNIQUE, NOT NULL | Official IDF personal number |
| `full_name` | `VARCHAR(100)` | NOT NULL | Soldier's full name |
| `unit` | `VARCHAR(100)` | — | Military unit (e.g., Golani, Paratroopers) |
| `rank` | `VARCHAR(50)` | — | Military rank (e.g., Private, Corporal) |
| `status` | `VARCHAR(20)` | DEFAULT `'Active'`, CHECK IN (`Active`, `Discharged`, `Reserve`) | Current service status |
| `enlistment_date` | `DATE` | CHECK > `birth_date` | Date the soldier enlisted |
| `birth_date` | `DATE` | CHECK < `enlistment_date` | Date of birth |
| `phone` | `VARCHAR(20)` | — | Contact phone number |

**Table constraint:** `chk_soldier_dates` — enlistment_date must be after birth_date (when both are provided).

---

## 2. DINING_HALL

Represents a physical dining facility on an IDF base.

**Relationships:** One DINING_HALL → Many MEAL_SESSIONs and Many INVENTORY records (1:N each)

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| `hall_id` | `SERIAL` | PRIMARY KEY | Auto-generated unique ID |
| `hall_name` | `VARCHAR(100)` | NOT NULL | Name of the dining hall |
| `base_location` | `VARCHAR(100)` | NOT NULL | Base where the hall is located |
| `capacity` | `INT` | CHECK > 0 | Maximum number of diners at once |
| `hall_type` | `VARCHAR(30)` | CHECK IN (`Permanent`, `Temporary`, `Field`) | Type of facility |
| `opening_year` | `INT` | CHECK >= 1948 | Year the hall opened (IDF founded in 1948) |
| `is_active` | `BOOLEAN` | DEFAULT `TRUE` | Whether the hall is currently operational |

---

## 3. SUPPLIER

Tracks food suppliers that deliver to IDF dining halls. Standalone table — no foreign key dependencies.

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| `supplier_id` | `SERIAL` | PRIMARY KEY | Auto-generated unique ID |
| `supplier_name` | `VARCHAR(100)` | NOT NULL | Official name of the supplier |
| `contact_person` | `VARCHAR(100)` | — | Primary contact at the company |
| `contact_phone` | `VARCHAR(20)` | — | Contact phone number |
| `supply_type` | `VARCHAR(50)` | — | Category of goods (e.g., Meat, Dairy, Dry Goods) |
| `is_active` | `BOOLEAN` | DEFAULT `TRUE` | Whether the supplier is currently contracted |

---

## 4. DIETARY_RESTRICTION

Records dietary restrictions and allergies for individual soldiers. One soldier can have many restrictions.

**Relationships:** Many DIETARY_RESTRICTIONs → One SOLDIER (N:1, cascades on delete)

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| `restriction_id` | `SERIAL` | PRIMARY KEY | Auto-generated unique ID |
| `soldier_id` | `INT` | NOT NULL, FK → SOLDIER | Links the restriction to its soldier |
| `restriction_type` | `VARCHAR(50)` | NOT NULL | Type of restriction (e.g., Gluten Intolerance, Vegan) |
| `severity` | `VARCHAR(20)` | CHECK IN (`Mild`, `Moderate`, `Severe`) | How critical the restriction is |
| `allergen_name` | `VARCHAR(100)` | — | Specific allergen (e.g., Peanuts, Gluten) |
| `details` | `TEXT` | — | Free-text notes from medical staff |

---

## 5. MENU_ITEM

A catalog of all food items that can be served in any dining hall.

**Relationships:** One MENU_ITEM → Many MEAL_MENU records and Many INVENTORY records (1:N each)

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| `item_id` | `SERIAL` | PRIMARY KEY | Auto-generated unique ID |
| `item_name` | `VARCHAR(100)` | NOT NULL | Name of the food item |
| `category` | `VARCHAR(50)` | — | Food category (Main, Side, Salad, Dessert, etc.) |
| `price` | `DECIMAL(6,2)` | CHECK >= 0 | Cost per serving in ILS (₪) |
| `calories` | `INT` | CHECK >= 0 | Calories per serving |
| `is_kosher` | `BOOLEAN` | DEFAULT `TRUE` | Whether the item is kosher |
| `is_vegetarian` | `BOOLEAN` | DEFAULT `FALSE` | Whether the item is vegetarian |
| `is_vegan` | `BOOLEAN` | DEFAULT `FALSE` | Whether the item is vegan |
| `allergens` | `TEXT` | — | Comma-separated list of allergens |

**Table constraint:** `chk_vegan_vegetarian` — if an item is vegan it must also be vegetarian.

---

## 6. MEAL_SESSION

Records every meal service event at a dining hall (when, where, how many diners).

**Relationships:** Many MEAL_SESSIONs → One DINING_HALL (N:1); One MEAL_SESSION → Many MEAL_MENU records (1:N)

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| `meal_id` | `SERIAL` | PRIMARY KEY | Auto-generated unique ID |
| `hall_id` | `INT` | NOT NULL, FK → DINING_HALL | The hall where this session took place |
| `meal_type` | `VARCHAR(20)` | NOT NULL, CHECK IN (`Breakfast`, `Lunch`, `Dinner`, `Snack`) | Type of meal |
| `meal_date` | `DATE` | NOT NULL | Date of the meal session |
| `meal_time` | `TIME` | — | Time the meal service started |
| `diners_count` | `INT` | CHECK >= 0 | Number of soldiers who ate |
| `cost_per_meal` | `DECIMAL(8,2)` | CHECK >= 0 | Total cost per diner in ILS (₪) |

---

## 7. MEAL_MENU

A bridge table that links meal sessions to the menu items served. Resolves the many-to-many relationship between MEAL_SESSION and MENU_ITEM.

**Relationships:** N:M bridge — parent tables are MEAL_SESSION and MENU_ITEM (both cascade on delete)

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| `menu_id` | `SERIAL` | PRIMARY KEY | Auto-generated unique ID |
| `meal_id` | `INT` | NOT NULL, FK → MEAL_SESSION | The session this item was served in |
| `item_id` | `INT` | NOT NULL, FK → MENU_ITEM | The food item served |
| `quantity` | `INT` | CHECK > 0 | Number of servings prepared |

---

## 8. INVENTORY

Tracks current stock levels of food items held at each dining hall.

**Relationships:** Many INVENTORY records → One DINING_HALL and One MENU_ITEM (N:1 each, both cascade)

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| `inventory_id` | `SERIAL` | PRIMARY KEY | Auto-generated unique ID |
| `hall_id` | `INT` | NOT NULL, FK → DINING_HALL | The hall where this stock is stored |
| `item_id` | `INT` | NOT NULL, FK → MENU_ITEM | The food item being stocked |
| `quantity` | `INT` | CHECK >= 0 | Current quantity in stock |
| `unit` | `VARCHAR(20)` | — | Unit of measurement (kg, liter, box, etc.) |
| `expiry_date` | `DATE` | — | Date after which the stock should not be used |
| `last_updated` | `TIMESTAMP` | DEFAULT `CURRENT_TIMESTAMP` | When the stock record was last changed |

---

## Entity Relationships

```
SOLDIER ─────────────── 1:N ─── DIETARY_RESTRICTION
DINING_HALL ─────────── 1:N ─── MEAL_SESSION
DINING_HALL ─────────── 1:N ─── INVENTORY
MENU_ITEM ───────────── 1:N ─── INVENTORY
MEAL_SESSION ─ N:M (via MEAL_MENU) ─── MENU_ITEM
SUPPLIER ─────────────────────────── (standalone)
```

## Key Design Decisions

| Decision | Reason |
|----------|--------|
| `DECIMAL` for prices | Avoids floating-point rounding errors |
| `BOOLEAN` flags for kosher/vegan/vegetarian | Simple and efficient to filter |
| `ON DELETE CASCADE` on all foreign keys | Keeps data consistent automatically |
| `MEAL_MENU` bridge table | Correctly models the many-to-many meal↔item relationship |
| Two `DATE` fields per relevant table | Meets the course requirement for ≥ 2 date attributes |
