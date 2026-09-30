"""Builds a SIMULATED Swiggy-style food-delivery dataset (seeded, reproducible).
Not real Swiggy data. Replace the CSVs in data/ with real/public data if available."""
import numpy as np, pandas as pd
from pathlib import Path

DATA = Path(__file__).resolve().parents[1] / "data"
rng = np.random.default_rng(7)

CITIES = ["Bhubaneswar", "Bengaluru", "Mumbai", "Delhi", "Hyderabad"]
MENU = {  # cuisine -> [(food, base price)]
    "North Indian": [("Butter Chicken", 320), ("Paneer Tikka", 260), ("Dal Makhani", 220), ("Butter Naan", 60)],
    "South Indian": [("Masala Dosa", 120), ("Idli Sambar", 90), ("Filter Coffee", 50), ("Medu Vada", 80)],
    "Biryani": [("Chicken Biryani", 280), ("Veg Biryani", 210), ("Mutton Biryani", 360), ("Raita", 40)],
    "Chinese": [("Veg Hakka Noodles", 190), ("Chicken Manchurian", 240), ("Fried Rice", 200), ("Spring Rolls", 150)],
    "Fast Food": [("Veg Burger", 130), ("Chicken Burger", 170), ("French Fries", 100), ("Peri Peri Wrap", 160)],
    "Pizza": [("Margherita Pizza", 250), ("Farmhouse Pizza", 340), ("Garlic Bread", 120), ("Pepperoni Pizza", 380)],
    "Desserts": [("Chocolate Brownie", 110), ("Gulab Jamun", 90), ("Ice Cream Sundae", 140), ("Rasmalai", 120)],
}
CUIS = list(MENU)

# restaurants + menu items
rest, items = [], []
for rid in range(1, 151):
    cu = rng.choice(CUIS)
    rest.append([rid, f"Restaurant_{rid:03d}", rng.choice(CITIES), cu, round(rng.uniform(3.2, 4.9), 1)])
    for food, p in MENU[cu]:
        items.append([len(items) + 1, rid, food, int(p * rng.uniform(0.9, 1.15))])
restaurants = pd.DataFrame(rest, columns=["restaurant_id", "name", "city", "cuisine", "rating"])
menu = pd.DataFrame(items, columns=["item_id", "restaurant_id", "item_name", "price"])
by_city_cuisine = restaurants.groupby(["city", "cuisine"]).restaurant_id.apply(list).to_dict()
by_city = restaurants.groupby("city").restaurant_id.apply(list).to_dict()
menu_by_rest = {r: g for r, g in menu.groupby("restaurant_id")}

# customers: signups ramp up through 2024 (growth story)
n_c = 2500
signup_days = (rng.beta(1.3, 1.0, n_c) * 330).astype(int)
cust = pd.DataFrame({
    "customer_id": range(1, n_c + 1),
    "city": rng.choice(CITIES, n_c, p=[.15, .3, .25, .2, .1]),
    "signup_date": pd.Timestamp("2024-01-01") + pd.to_timedelta(signup_days, unit="D"),
    "fav_cuisine": rng.choice(CUIS, n_c),
})
END = pd.Timestamp("2024-12-31")
hour_w = np.array([1,1,0,0,0,0,1,2,3,3,3,5,9,9,6,3,3,4,6,9,10,9,6,3], float); hour_w /= hour_w.sum()

orders, oitems = [], []
oid = 0
for c in cust.itertuples():
    end = END
    if rng.random() < 0.35:  # churners stop ordering after a while
        end = min(END, c.signup_date + pd.Timedelta(days=int(rng.integers(15, 150))))
    span = max(1, (end - c.signup_date).days)
    n = max(1, rng.poisson(rng.gamma(1.5, 0.9) * span / 30))
    fav_food = None
    for d in np.sort(rng.integers(0, span + 1, n)):
        ts = c.signup_date + pd.Timedelta(days=int(d), hours=int(rng.choice(24, p=hour_w)), minutes=int(rng.integers(0, 60)))
        pool = by_city_cuisine.get((c.city, c.fav_cuisine)) if rng.random() < 0.6 else None
        r = int(rng.choice(pool if pool else by_city[c.city]))
        m = menu_by_rest[r]
        if fav_food is None:
            fav_food = m.item_name.iloc[int(rng.integers(len(m)))]
        chosen = m[m.item_name == fav_food].head(1) if rng.random() < 0.5 and (m.item_name == fav_food).any() else m.sample(1, random_state=int(rng.integers(1e9)))
        extra = m.sample(int(rng.integers(0, 3)), random_state=int(rng.integers(1e9)))
        lines = pd.concat([chosen, extra]).drop_duplicates("item_id")
        oid += 1
        sub = 0
        for l in lines.itertuples():
            q = int(rng.choice([1, 2], p=[.8, .2])); sub += l.price * q
            oitems.append([oid, l.item_id, q, l.price])
        disc = round(sub * rng.uniform(0.1, 0.3)) if rng.random() < 0.35 else 0
        fee = int(rng.choice([0, 25, 40]))
        status = "Cancelled" if rng.random() < 0.06 else "Delivered"
        orders.append([oid, c.customer_id, r, ts.strftime("%Y-%m-%d %H:%M:%S"), status, disc, fee, sub - disc + fee])

cust.assign(signup_date=cust.signup_date.dt.strftime("%Y-%m-%d")).drop(columns="fav_cuisine").to_csv(DATA / "customers.csv", index=False)
restaurants.to_csv(DATA / "restaurants.csv", index=False)
menu.to_csv(DATA / "menu_items.csv", index=False)
pd.DataFrame(orders, columns=["order_id", "customer_id", "restaurant_id", "order_ts", "status", "discount_amount", "delivery_fee", "total_amount"]).to_csv(DATA / "orders.csv", index=False)
pd.DataFrame(oitems, columns=["order_id", "item_id", "quantity", "unit_price"]).to_csv(DATA / "order_items.csv", index=False)
print(f"customers={len(cust)} restaurants={len(restaurants)} menu_items={len(menu)} orders={len(orders)} order_items={len(oitems)}")
