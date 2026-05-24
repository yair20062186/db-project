#!/usr/bin/env python3
"""
generate_data.py
──────────────────────────────────────────────────────────────────────
IDF Food & Dining Hall Management System – Mock Data Generator
Author : Yair Shushan | 215973686
Stage  : שלב א

Writes batched SQL INSERT statements to ../insertTables.sql

No external dependencies required – standard library only.
Run:  python3 generate_data.py
──────────────────────────────────────────────────────────────────────
"""

import random
import datetime
import os
import sys

# ══════════════════════════════════════════════════════════════════════
# Configuration
# ══════════════════════════════════════════════════════════════════════
SEED = 42
random.seed(SEED)

SCRIPT_DIR  = os.path.dirname(os.path.abspath(__file__))
OUTPUT_PATH = os.path.normpath(os.path.join(SCRIPT_DIR, '..', 'insertTables.sql'))
BATCH       = 500        # rows per INSERT VALUES block (keeps file readable)

N_SOLDIERS   = 600
N_HALLS      = 500
N_SUPPLIERS  = 500
N_DIETARY    = 1_000
N_ITEMS      = 500
N_SESSIONS   = 20_000
N_INVENTORY  = 20_000
# MEAL_MENU is derived: 2–4 items per session → ~50,000 rows

# ══════════════════════════════════════════════════════════════════════
# SQL helper utilities
# ══════════════════════════════════════════════════════════════════════
def esc(v):
    """Return a SQL-safe single-quoted string, or NULL."""
    if v is None:
        return 'NULL'
    return "'" + str(v).replace("'", "''") + "'"

def sql_date(d):
    return f"'{d.isoformat()}'" if d is not None else 'NULL'

def sql_time(t):
    return f"'{t.strftime('%H:%M:%S')}'" if t is not None else 'NULL'

def sql_ts(dt):
    return f"'{dt.strftime('%Y-%m-%d %H:%M:%S')}'" if dt is not None else 'NULL'

def sql_bool(b):
    return 'TRUE' if b else 'FALSE'

def sql_dec(v):
    return f'{v:.2f}' if v is not None else 'NULL'

def rand_date(start: datetime.date, end: datetime.date) -> datetime.date:
    delta = (end - start).days
    return start + datetime.timedelta(days=random.randint(0, max(delta, 0)))

def rand_ts(start: datetime.date, end: datetime.date) -> datetime.datetime:
    d = rand_date(start, end)
    return datetime.datetime(d.year, d.month, d.day,
                             random.randint(0, 23),
                             random.randint(0, 59),
                             random.randint(0, 59))

def rand_time_between(t_start: datetime.time, t_end: datetime.time) -> datetime.time:
    s = t_start.hour * 60 + t_start.minute
    e = t_end.hour   * 60 + t_end.minute
    m = random.randint(s, e)
    return datetime.time(m // 60, m % 60)

def add_years_safe(d: datetime.date, years: int) -> datetime.date:
    """Add years to a date; handles Feb-29 edge case."""
    try:
        return d.replace(year=d.year + years)
    except ValueError:          # Feb 29 → Mar 1
        return d + datetime.timedelta(days=365 * years + years // 4)

def write_inserts(f, table: str, cols: list, rows: list):
    """Write rows as batched INSERT statements, BATCH rows at a time."""
    if not rows:
        return
    col_str = ', '.join(cols)
    for i in range(0, len(rows), BATCH):
        chunk = rows[i:i + BATCH]
        vals  = ',\n    '.join(chunk)
        f.write(f'INSERT INTO {table} ({col_str}) VALUES\n    {vals};\n\n')
    print(f'  ✓  {table:<25} {len(rows):>8,} rows')

# ══════════════════════════════════════════════════════════════════════
# Data pools
# ══════════════════════════════════════════════════════════════════════

FIRST_NAMES = [
    'Yair','David','Moshe','Avi','Nir','Lior','Eitan','Ron','Guy','Tal',
    'Yonatan','Amit','Shai','Or','Gal','Rotem','Itai','Omri','Idan','Barak',
    'Noam','Tomer','Yuval','Shay','Ori','Doron','Ran','Amir','Uri','Elad',
    'Noa','Maya','Tamar','Shira','Yael','Michal','Hila','Inbar','Roni','Dana',
    'Liron','Ayelet','Einat','Galit','Shirley','Keren','Adi','Sivan','Ofir','Tali',
    'Zohar','Gilad','Nadav','Benny','Haim','Efrat','Rivka','Leah','Rachel','Dor',
]

LAST_NAMES = [
    'Cohen','Levi','Mizrahi','Peretz','Biton','Ben-David','Azoulay','Dahan',
    'Friedman','Shapiro','Goldberg','Katz','Weiss','Barak','Shamir','Nir',
    'Golan','Carmeli','Ben-Ami','Harel','Tamir','Shalom','Amar','Sela',
    'Avraham','Alkalai','Bar','Ben-Or','Caspi','Danino','Eliyahu','Gabay',
    'Hasson','Israeli','Jacobson','Kahan','Levin','Manor','Naor','Ovadia',
    'Pinto','Rozenberg','Stern','Tzur','Uzan','Vered','Wexler','Yona','Zadok','Halevi',
]

UNITS = [
    'Golani','Paratroopers','Armored Corps','Artillery','Navy','Air Force',
    'Intelligence','Engineering Corps','Signal Corps','Logistics',
    'Military Police','Medical Corps','Ordnance Corps','Special Forces',
    'Border Police','Home Front Command','Southern Command',
    'Northern Command','Central Command','Cyber Defense',
]

# Weighted ranks (more privates than colonels)
RANKS = (
    ['Private'] * 5 +
    ['First Private'] * 4 +
    ['Corporal'] * 4 +
    ['Sergeant'] * 3 +
    ['Staff Sergeant'] * 2 +
    ['Warrant Officer'] * 1 +
    ['Second Lieutenant', 'First Lieutenant', 'Captain', 'Major',
     'Lieutenant Colonel', 'Colonel']
)

# Weighted statuses (mostly active)
STATUSES = ['Active'] * 5 + ['Reserve'] * 3 + ['Discharged'] * 2

BASE_LOCATIONS = [
    'Tel HaShomer','Kirya Tel Aviv','Ramat David','Palmachim','Nevatim',
    'Hatzor','Ramon','Glilot','Tzrifin','Nitzanim','Julis',
    'Bahad 1','Bahad 4','Bahad 6','Beer Sheva','Haifa',
    'Eilat','Tiberias','Afula','Rishon LeZion','Petah Tikva',
    'Ramla','Lod','Ashdod','Netanya','Herzliya',
    'Kfar Saba','Rehovot','Holon','Bat Yam',
]

HALL_PREFIXES = [
    'Main','Northern','Southern','Eastern','Western','Central',
    'Upper','Lower','New','Old','Base','Field','Reserve','Coastal',
]
HALL_SUFFIXES = [
    'Cafeteria','Dining Hall','Mess Hall','Canteen','Food Court','Restaurant',
]
HALL_TYPES = ['Permanent'] * 5 + ['Temporary'] * 3 + ['Field'] * 2

# 30 × 20 = 600 unique supplier name combinations (> N_SUPPLIERS=500)
SUPPLIER_ADJ = [
    'Alpha','Beta','Delta','Prime','Golden','Fresh','Royal','Star',
    'Superior','National','Central','Eastern','Western','Northern','Southern',
    'United','Allied','Global','Premium','Quality','Elite','Top',
    'First','Best','Reliable','Trusted','Certified','Approved','Leading','Local',
]
SUPPLIER_NOUN = [
    'Foods','Supplies','Provisions','Distributors','Logistics','Solutions',
    'Catering','Agriculture','Meats','Dairy','Produce','Bakery','Imports',
    'Trading','Group','Industries','Corp','Services','Partners','Deliveries',
]

SUPPLY_TYPES = [
    'Meat & Poultry','Dairy','Vegetables & Fruits','Bread & Bakery',
    'Dry Goods','Frozen Foods','Beverages','Canned Goods',
    'Spices & Condiments','Eggs & Protein','Seafood',
    'Kosher Specialty','Mixed Provisions','Cleaning Supplies','Packaging Materials',
]

RESTRICTION_TYPES = [
    'Gluten Intolerance','Lactose Intolerance','Nut Allergy','Shellfish Allergy',
    'Egg Allergy','Soy Allergy','Vegetarian','Vegan','Kosher Only','Halal Only',
    'Diabetic Diet','Low Sodium','Low Fat','Fish Allergy',
    'Sesame Allergy','Celiac Disease','Wheat Allergy','Corn Allergy',
]

# Weighted severity (more mild/moderate than severe)
SEVERITIES = ['Mild'] * 4 + ['Moderate'] * 4 + ['Severe'] * 2

# Allergen pool with ~40 % NULL (no specific allergen)
ALLERGEN_POOL = (
    ['Gluten','Milk','Eggs','Nuts','Peanuts','Sesame',
     'Soy','Fish','Shellfish','Wheat','Tree Nuts','Mustard'] +
    [None] * 8
)

RESTRICTION_DETAILS = [
    'Doctor-verified', 'Self-reported', 'Lab confirmed',
    'Mild reaction observed', 'Severe – EpiPen required',
    'Noted in medical record', 'Annual review required',
    None, None,   # ~22 % null
]

# Meal timing windows by type
MEAL_TIME_RANGES = {
    'Breakfast': (datetime.time(6,  0), datetime.time(9,  0)),
    'Lunch':     (datetime.time(11, 0), datetime.time(14, 0)),
    'Dinner':    (datetime.time(17, 0), datetime.time(20, 0)),
    'Snack':     (datetime.time(9,  0), datetime.time(16, 0)),
}

# Weighted meal types (cumulative thresholds)
_MEAL_TYPES      = ['Breakfast', 'Lunch', 'Dinner', 'Snack']
_MEAL_WEIGHTS_CUM = [0.25,       0.60,   0.90,    1.00]

def weighted_meal_type() -> str:
    r = random.random()
    for t, threshold in zip(_MEAL_TYPES, _MEAL_WEIGHTS_CUM):
        if r < threshold:
            return t
    return 'Snack'

STOCK_UNITS = ['kg', 'liter', 'unit', 'pack', 'crate', 'box', 'bag']

# ══════════════════════════════════════════════════════════════════════
# Menu-item pool builder  (→ 500 unique items)
# ══════════════════════════════════════════════════════════════════════

# Fixed seed items (35 hand-crafted rows)
_FIXED_ITEMS = [
    # (name, category, price, calories, kosher, vegetarian, vegan)
    ('Grilled Chicken Breast',  'Main',      38.0, 320, True,  False, False),
    ('Beef Stew',               'Main',      45.0, 480, True,  False, False),
    ('Lamb Kebab',              'Main',      52.0, 410, True,  False, False),
    ('Schnitzel',               'Main',      40.0, 390, True,  False, False),
    ('Turkey Burger',           'Main',      36.0, 370, True,  False, False),
    ('Salmon Fillet',           'Main',      55.0, 340, True,  False, False),
    ('Tuna Casserole',          'Main',      42.0, 310, True,  False, False),
    ('Falafel Plate',           'Main',      22.0, 290, True,  True,  True),
    ('Shakshuka',               'Breakfast', 25.0, 380, True,  True,  False),
    ('Scrambled Eggs',          'Breakfast', 18.0, 260, True,  True,  False),
    ('Pancakes',                'Breakfast', 15.0, 340, True,  True,  False),
    ('Granola Bowl',            'Breakfast', 14.0, 310, True,  True,  True),
    ('Toast & Eggs',            'Breakfast', 12.0, 280, True,  True,  False),
    ('French Toast',            'Breakfast', 16.0, 350, True,  True,  False),
    ('Oatmeal Porridge',        'Breakfast', 10.0, 220, True,  True,  True),
    ('Avocado Egg Toast',       'Breakfast', 20.0, 310, True,  True,  True),
    ('Rice Pilaf',              'Side',      12.0, 210, True,  True,  True),
    ('Mashed Potatoes',         'Side',      10.0, 190, True,  True,  False),
    ('Roasted Vegetables',      'Side',      14.0, 120, True,  True,  True),
    ('Steamed Broccoli',        'Side',      10.0,  55, True,  True,  True),
    ('Fried Rice',              'Side',      15.0, 250, True,  True,  True),
    ('Couscous',                'Side',      11.0, 180, True,  True,  True),
    ('Caesar Salad',            'Salad',     18.0, 150, True,  True,  False),
    ('Greek Salad',             'Salad',     16.0, 140, True,  True,  True),
    ('Israeli Salad',           'Salad',     12.0,  80, True,  True,  True),
    ('Tabbouleh',               'Salad',     13.0, 100, True,  True,  True),
    ('Hummus',                  'Starter',   10.0, 180, True,  True,  True),
    ('Tahini Dip',              'Starter',    8.0, 120, True,  True,  True),
    ('Pita Bread',              'Starter',    5.0, 160, True,  True,  True),
    ('Vegetable Soup',          'Soup',      14.0,  90, True,  True,  True),
    ('Chicken Soup',            'Soup',      18.0, 150, True,  False, False),
    ('Lentil Soup',             'Soup',      15.0, 130, True,  True,  True),
    ('Tomato Soup',             'Soup',      13.0, 100, True,  True,  True),
    ('Mushroom Soup',           'Soup',      14.0, 110, True,  True,  True),
    # Desserts
    ('Chocolate Mousse',        'Dessert',   16.0, 350, True,  True,  False),
    ('Vanilla Pudding',         'Dessert',   14.0, 280, True,  True,  False),
    ('Baklava',                 'Dessert',   18.0, 370, True,  True,  True),
    ('Fresh Fruit Cup',         'Dessert',   10.0,  80, True,  True,  True),
    ('Rice Pudding',            'Dessert',   13.0, 270, True,  True,  False),
    ('Chocolate Brownie',       'Dessert',   15.0, 420, True,  True,  False),
    ('Halva Slice',             'Dessert',   12.0, 390, True,  True,  True),
    ('Date Cookies',            'Dessert',   11.0, 320, True,  True,  True),
    ('Cheesecake Slice',        'Dessert',   18.0, 450, True,  True,  False),
    ('Apple Strudel',           'Dessert',   14.0, 340, True,  True,  False),
    # Beverages
    ('Orange Juice',            'Beverage',   8.0, 110, True,  True,  True),
    ('Apple Juice',             'Beverage',   7.0, 120, True,  True,  True),
    ('Mineral Water',           'Beverage',   4.0,   0, True,  True,  True),
    ('Chocolate Milk',          'Beverage',   9.0, 190, True,  True,  False),
    ('Coffee',                  'Beverage',   6.0,   5, True,  True,  True),
    ('Black Tea',               'Beverage',   5.0,   0, True,  True,  True),
    ('Lemonade',                'Beverage',   7.0,  90, True,  True,  True),
    ('Pomegranate Juice',       'Beverage',  10.0, 134, True,  True,  True),
    ('Protein Shake',           'Beverage',  22.0, 180, True,  True,  False),
    # Snacks
    ('Peanut Butter Toast',     'Snack',     12.0, 280, True,  True,  True),
    ('Cheese Crackers',         'Snack',     10.0, 200, True,  True,  False),
    ('Granola Bar',             'Snack',      8.0, 180, True,  True,  True),
    ('Trail Mix',               'Snack',      9.0, 220, True,  True,  True),
    ('Hummus & Pita',           'Snack',     12.0, 240, True,  True,  True),
    ('Vegetable Sticks',        'Snack',      8.0,  60, True,  True,  True),
    ('Boiled Eggs',             'Snack',      6.0, 140, True,  True,  False),
]

_COOKING = [
    'Grilled','Baked','Fried','Roasted','Steamed',
    'Braised','Sauteed','Stir-Fried','Pan-Seared','Slow-Cooked',
]
_PROTEINS = [
    'Chicken','Beef','Lamb','Turkey','Salmon',
    'Tuna','Tofu','Chickpea','Veal','Duck',
]
_VEGS = [
    'Broccoli','Carrots','Spinach','Zucchini','Eggplant',
    'Bell Pepper','Mushroom','Cauliflower','Green Beans','Corn',
]
_CARBS = [
    'Rice','Pasta','Quinoa','Couscous','Sweet Potato',
    'Bulgur','Polenta','Barley','Buckwheat','Lentils',
]
_ADJ = [
    'Spicy','Honey-Glazed','Garlic','Lemon','BBQ','Crispy',
    'Golden','Mediterranean','Herbed','Teriyaki','Classic',
    'Sweet','Smoky','Tangy','Asian-Style','Italian',
]
_SOUP_BASES = [
    'French Onion','Minestrone','Gazpacho','Harira','Borscht',
    'Potato Leek','Thai Coconut','Butternut Squash','Bean','Pea',
    'Cream of Celery','Red Pepper','Spinach Cream','Corn Chowder','Miso',
]
_SALAD_BASES = [
    'Fattoush','Nicoise','Caprese','Pasta','Waldorf',
    'Mediterranean','Arugula','Spinach','Chickpea','Beet',
    'Quinoa','Kale','Mango','Roasted Vegetable','Lentil',
]

_ITEM_ALLERGENS = ['Gluten','Milk','Eggs','Nuts','Sesame','Soy','Fish',None,None,None]


def build_menu_items(target: int = 500) -> list:
    """Generate up to `target` unique menu items, filling from fixed then generated."""
    pool = []
    seen = set()

    def add(name, cat, price, cal, kosher, veg, vegan):
        if name in seen or len(pool) >= target:
            return
        seen.add(name)
        is_veg  = bool(veg or vegan)
        is_vegan = bool(vegan)
        pool.append((name, cat, round(float(price), 2), int(cal),
                     bool(kosher), is_veg, is_vegan))

    # 1. Fixed hand-crafted items
    for item in _FIXED_ITEMS:
        add(*item)

    # 2. cooking × protein (10 × 10 = 100 potential mains)
    for c in _COOKING:
        for p in _PROTEINS:
            vg = p in ('Tofu', 'Chickpea')
            add(f'{c} {p}', 'Main',
                random.uniform(24, 68), random.randint(240, 560),
                True, vg, vg)

    # 3. adjective × protein (16 × 10 = 160 potential mains)
    for adj in _ADJ:
        for p in _PROTEINS:
            vg = p in ('Tofu', 'Chickpea')
            add(f'{adj} {p}', 'Main',
                random.uniform(26, 70), random.randint(250, 570),
                True, vg, vg)

    # 4. cooking × vegetable (10 × 10 = 100 potential sides)
    for c in _COOKING:
        for v in _VEGS:
            add(f'{c} {v}', 'Side',
                random.uniform(8, 20), random.randint(40, 180),
                True, True, True)

    # 5. adjective × carb (16 × 10 = 160 potential sides)
    for adj in _ADJ[:8]:
        for carb in _CARBS:
            add(f'{adj} {carb}', 'Side',
                random.uniform(9, 19), random.randint(150, 300),
                True, True, adj not in ('Honey-Glazed',))

    # 6. Soups
    for base in _SOUP_BASES:
        add(f'{base} Soup', 'Soup',
            random.uniform(10, 22), random.randint(80, 220),
            True, True, True)

    # 7. Salads
    for base in _SALAD_BASES:
        add(f'{base} Salad', 'Salad',
            random.uniform(12, 25), random.randint(60, 200),
            True, True, random.random() > 0.4)

    # 8. Fallback: numbered variants to reach target
    idx = 1
    base_items = _FIXED_ITEMS[:20]
    while len(pool) < target:
        base = random.choice(base_items)
        adj  = random.choice(_ADJ)
        name = f'{adj} {base[0]}'
        add(name, base[1],
            base[2] * random.uniform(0.9, 1.2),
            int(base[3] * random.uniform(0.9, 1.1)),
            base[4], base[5], base[6])
        # If that name was taken, try a numbered variant
        if len(pool) < target:
            add(f'{base[0]} Variant {idx}', base[1],
                base[2] * 1.05, base[3], base[4], base[5], base[6])
        idx += 1

    return pool[:target]


# ══════════════════════════════════════════════════════════════════════
# Main
# ══════════════════════════════════════════════════════════════════════
def main():
    print('=' * 62)
    print(' IDF Food & Dining Hall Management System')
    print(' Mock Data Generator  |  Yair Shushan 215973686')
    print('=' * 62)
    print(f' Output file: {OUTPUT_PATH}')
    print()

    # ── SOLDIER ──────────────────────────────────────────────────────
    print('Generating SOLDIER ...')
    dob_start = datetime.date(1990, 1,  1)
    dob_end   = datetime.date(2003, 12, 31)
    soldier_rows = []
    for i in range(1, N_SOLDIERS + 1):
        fn     = random.choice(FIRST_NAMES)
        ln     = random.choice(LAST_NAMES)
        pnum   = str(7_000_000 + i)          # unique 7-digit personal numbers
        name   = f'{fn} {ln}'
        unit   = random.choice(UNITS)
        rank   = random.choice(RANKS)
        status = random.choice(STATUSES)
        bd     = rand_date(dob_start, dob_end)
        enl    = add_years_safe(bd, 18) + datetime.timedelta(days=random.randint(0, 730))
        phone  = f'05{random.randint(0,9)}-{random.randint(1_000_000, 9_999_999)}'
        soldier_rows.append(
            f"({esc(pnum)},{esc(name)},{esc(unit)},{esc(rank)},{esc(status)},"
            f"{sql_date(enl)},{sql_date(bd)},{esc(phone)})"
        )

    # ── DINING_HALL ──────────────────────────────────────────────────
    print('Generating DINING_HALL ...')
    hall_rows = []
    for i in range(1, N_HALLS + 1):
        hname = f"{random.choice(HALL_PREFIXES)} {random.choice(HALL_SUFFIXES)} {i}"
        base  = random.choice(BASE_LOCATIONS)
        htype = random.choice(HALL_TYPES)
        cap   = random.randint(50, 600)
        year  = random.randint(1960, 2023)
        actv  = sql_bool(random.random() > 0.08)
        hall_rows.append(
            f"({esc(hname)},{esc(base)},{cap},{esc(htype)},{year},{actv})"
        )

    # ── SUPPLIER ─────────────────────────────────────────────────────
    print('Generating SUPPLIER ...')
    all_sup_combos = [f"{a} {n}" for a in SUPPLIER_ADJ for n in SUPPLIER_NOUN]
    random.shuffle(all_sup_combos)
    supplier_rows = []
    for sname in all_sup_combos[:N_SUPPLIERS]:
        cp    = f"{random.choice(FIRST_NAMES)} {random.choice(LAST_NAMES)}"
        phone = f'0{random.randint(2,9)}-{random.randint(1_000_000, 9_999_999)}'
        stype = random.choice(SUPPLY_TYPES)
        actv  = sql_bool(random.random() > 0.08)
        supplier_rows.append(
            f"({esc(sname)},{esc(cp)},{esc(phone)},{esc(stype)},{actv})"
        )

    # ── DIETARY_RESTRICTION ──────────────────────────────────────────
    print('Generating DIETARY_RESTRICTION ...')
    dietary_rows = []
    for _ in range(N_DIETARY):
        sid    = random.randint(1, N_SOLDIERS)
        rtype  = random.choice(RESTRICTION_TYPES)
        sev    = random.choice(SEVERITIES)
        alg    = random.choice(ALLERGEN_POOL)
        detail = random.choice(RESTRICTION_DETAILS)
        dietary_rows.append(
            f"({sid},{esc(rtype)},{esc(sev)},{esc(alg)},{esc(detail)})"
        )

    # ── MENU_ITEM ────────────────────────────────────────────────────
    print('Generating MENU_ITEM ...')
    item_pool  = build_menu_items(N_ITEMS)
    item_rows  = []
    for name, cat, price, cal, kosher, veg, vegan in item_pool:
        alg = random.choice(_ITEM_ALLERGENS)
        item_rows.append(
            f"({esc(name)},{esc(cat)},{sql_dec(price)},{cal},"
            f"{sql_bool(kosher)},{sql_bool(veg)},{sql_bool(vegan)},{esc(alg)})"
        )

    # ── MEAL_SESSION ─────────────────────────────────────────────────
    print('Generating MEAL_SESSION (20,000) ...')
    sess_start  = datetime.date(2022, 1,  1)
    sess_end    = datetime.date(2024, 12, 31)
    session_rows = []
    for _ in range(N_SESSIONS):
        hid  = random.randint(1, N_HALLS)
        mtyp = weighted_meal_type()
        mdat = rand_date(sess_start, sess_end)
        tr   = MEAL_TIME_RANGES[mtyp]
        mtim = rand_time_between(tr[0], tr[1])
        cnt  = random.randint(10, 500)
        cost = round(random.uniform(15.0, 85.0), 2)
        session_rows.append(
            f"({hid},{esc(mtyp)},{sql_date(mdat)},{sql_time(mtim)},{cnt},{sql_dec(cost)})"
        )

    # ── MEAL_MENU ────────────────────────────────────────────────────
    print('Generating MEAL_MENU (~50,000) ...')
    meal_menu_rows = []
    for meal_id in range(1, N_SESSIONS + 1):
        n_items  = random.randint(2, 4)
        item_ids = random.sample(range(1, N_ITEMS + 1), n_items)
        for iid in item_ids:
            qty = random.randint(10, 150)
            meal_menu_rows.append(f"({meal_id},{iid},{qty})")

    # ── INVENTORY ────────────────────────────────────────────────────
    print('Generating INVENTORY (20,000) ...')
    exp_start = datetime.date(2024,  6,  1)
    exp_end   = datetime.date(2026, 12, 31)
    upd_start = datetime.date(2024,  1,  1)
    upd_end   = datetime.date(2024, 12, 31)

    # Sample 20,000 unique (hall_id, item_id) pairs from 500×500 = 250,000
    all_pairs    = [(h, it) for h in range(1, N_HALLS + 1)
                             for it in range(1, N_ITEMS + 1)]
    chosen_pairs = random.sample(all_pairs, N_INVENTORY)

    inventory_rows = []
    for hid, iid in chosen_pairs:
        qty  = random.randint(0, 1_000)
        unit = random.choice(STOCK_UNITS)
        exp  = rand_date(exp_start, exp_end)
        upd  = rand_ts(upd_start, upd_end)
        inventory_rows.append(
            f"({hid},{iid},{qty},{esc(unit)},{sql_date(exp)},{sql_ts(upd)})"
        )

    # ── Write SQL file ────────────────────────────────────────────────
    print()
    print(f'Writing SQL → {OUTPUT_PATH}')
    total = (len(soldier_rows) + len(hall_rows) + len(supplier_rows) +
             len(dietary_rows) + len(item_rows)  + len(session_rows) +
             len(meal_menu_rows) + len(inventory_rows))

    with open(OUTPUT_PATH, 'w', encoding='utf-8') as f:
        # Header
        f.write('-- ' + '=' * 60 + '\n')
        f.write('-- IDF Food & Dining Hall Management System\n')
        f.write('-- מערכת ניהול מזון והסעדה – צה"ל\n')
        f.write('-- Author : Yair Shushan | 215973686\n')
        f.write('-- Stage  : שלב א – Insert Data\n')
        f.write(f'-- Generated: {datetime.datetime.now().strftime("%Y-%m-%d %H:%M:%S")}\n')
        f.write('--\n')
        f.write('-- Record counts:\n')
        f.write(f'--   SOLDIER              : {len(soldier_rows):>8,}\n')
        f.write(f'--   DINING_HALL          : {len(hall_rows):>8,}\n')
        f.write(f'--   SUPPLIER             : {len(supplier_rows):>8,}\n')
        f.write(f'--   DIETARY_RESTRICTION  : {len(dietary_rows):>8,}\n')
        f.write(f'--   MENU_ITEM            : {len(item_rows):>8,}\n')
        f.write(f'--   MEAL_SESSION         : {len(session_rows):>8,}\n')
        f.write(f'--   MEAL_MENU            : {len(meal_menu_rows):>8,}\n')
        f.write(f'--   INVENTORY            : {len(inventory_rows):>8,}\n')
        f.write(f'--   TOTAL                : {total:>8,}\n')
        f.write('-- ' + '=' * 60 + '\n\n')

        # Tables in FK-safe order
        write_inserts(f, 'SOLDIER',
            ['personal_number','full_name','unit','rank','status',
             'enlistment_date','birth_date','phone'],
            soldier_rows)

        write_inserts(f, 'DINING_HALL',
            ['hall_name','base_location','capacity','hall_type',
             'opening_year','is_active'],
            hall_rows)

        write_inserts(f, 'SUPPLIER',
            ['supplier_name','contact_person','contact_phone',
             'supply_type','is_active'],
            supplier_rows)

        write_inserts(f, 'DIETARY_RESTRICTION',
            ['soldier_id','restriction_type','severity',
             'allergen_name','details'],
            dietary_rows)

        write_inserts(f, 'MENU_ITEM',
            ['item_name','category','price','calories',
             'is_kosher','is_vegetarian','is_vegan','allergens'],
            item_rows)

        write_inserts(f, 'MEAL_SESSION',
            ['hall_id','meal_type','meal_date','meal_time',
             'diners_count','cost_per_meal'],
            session_rows)

        write_inserts(f, 'MEAL_MENU',
            ['meal_id','item_id','quantity'],
            meal_menu_rows)

        write_inserts(f, 'INVENTORY',
            ['hall_id','item_id','quantity','unit',
             'expiry_date','last_updated'],
            inventory_rows)

    # ── Summary ───────────────────────────────────────────────────────
    sz = os.path.getsize(OUTPUT_PATH)
    print()
    print('=' * 62)
    print(f' Done!  Total rows : {total:,}')
    print(f'        File size  : {sz / 1_048_576:.1f} MB')
    print(f'        Output     : {OUTPUT_PATH}')
    print('=' * 62)


if __name__ == '__main__':
    main()
