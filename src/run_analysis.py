"""Loads CSVs into SQLite, runs every sql/*.sql query, saves result tables and charts."""
import sqlite3, pandas as pd, numpy as np, matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
OUT, FIG, RES = ROOT / "outputs", ROOT / "outputs" / "figures", ROOT / "outputs" / "query_results"
db = OUT / "swiggy.db"
if db.exists(): db.unlink()
con = sqlite3.connect(db)
for t in ["customers", "restaurants", "menu_items", "orders", "order_items"]:
    pd.read_csv(ROOT / "data" / f"{t}.csv").to_sql(t, con, index=False)

results = {}
for f in sorted((ROOT / "sql").glob("q*.sql")):
    df = pd.read_sql_query(f.read_text(), con)
    df.to_csv(RES / f"{f.stem}.csv", index=False)
    results[f.stem] = df
    print(f"{f.stem}: {len(df)} rows")

BLUE, ORG = "#FC8019", "#3D4152"   # Swiggy-ish palette
# Chart 1: monthly revenue + MoM growth
m = results["q06_mom_revenue_growth"]
fig, ax = plt.subplots(figsize=(9, 4.5))
ax.bar(m.month, m.revenue / 1e5, color=BLUE); ax.set_ylabel("Revenue (INR lakh)")
ax2 = ax.twinx(); ax2.plot(m.month, m.mom_revenue_growth_pct, "o-", color=ORG); ax2.set_ylabel("MoM growth (%)")
ax.set_title("Monthly revenue and month-over-month growth"); plt.setp(ax.get_xticklabels(), rotation=45)
fig.tight_layout(); fig.savefig(FIG / "01_monthly_revenue.png", dpi=150); plt.close(fig)
# Chart 2: cohort heatmap
c = results["q07_cohort_retention"].pivot(index="cohort", columns="month_n", values="retention_pct")
fig, ax = plt.subplots(figsize=(9, 5)); im = ax.imshow(c.to_numpy(float), cmap="Oranges", aspect="auto")
ax.set_xticks(range(c.shape[1])); ax.set_xticklabels(c.columns); ax.set_yticks(range(c.shape[0])); ax.set_yticklabels(c.index)
for i in range(c.shape[0]):
    for j in range(c.shape[1]):
        v = c.iat[i, j]
        if not np.isnan(v): ax.text(j, i, f"{v:.0f}", ha="center", va="center", fontsize=7)
ax.set_xlabel("Months since first order"); ax.set_title("Cohort retention (% of cohort ordering)"); fig.colorbar(im)
fig.tight_layout(); fig.savefig(FIG / "02_cohort_retention.png", dpi=150); plt.close(fig)
# Chart 3: repeat segments
r = results["q02_repeat_customers"]
fig, axes = plt.subplots(1, 2, figsize=(9, 4))
axes[0].bar(r.segment, r.pct_customers, color=ORG); axes[0].set_title("% of customers")
axes[1].bar(r.segment, r.pct_revenue, color=BLUE); axes[1].set_title("% of revenue")
for a in axes: plt.setp(a.get_xticklabels(), rotation=20)
fig.tight_layout(); fig.savefig(FIG / "03_repeat_vs_revenue.png", dpi=150); plt.close(fig)
# Chart 4: top foods
t = results["q04_top_foods"].iloc[::-1]
fig, ax = plt.subplots(figsize=(8, 4.5)); ax.barh(t.item_name, t.revenue / 1e5, color=BLUE)
ax.set_xlabel("Revenue (INR lakh)"); ax.set_title("Top 10 foods by revenue")
fig.tight_layout(); fig.savefig(FIG / "04_top_foods.png", dpi=150); plt.close(fig)
con.close()
