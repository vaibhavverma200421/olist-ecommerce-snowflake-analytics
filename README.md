# Olist E-Commerce Analytics — Python + Snowflake + Power BI

An end-to-end data analytics pipeline built on the **Olist Brazilian E-Commerce** dataset (Kaggle) — from raw, messy CSVs to a cloud data warehouse and a live interactive dashboard.

This project was built to go beyond a typical local-database portfolio project and work hands-on with **Snowflake**, a cloud data warehouse platform widely used in the industry.

---

## 🔗 Pipeline Overview

```
Raw CSVs (5 tables)
      │
      ▼
Python (Pandas) — Cleaning & EDA
      │
      ▼
Snowflake — Cloud Data Warehouse (Database → Schema → Tables)
      │
      ▼
SQL — 30 queries (Joins, CTEs, Window Functions, MERGE, Views)
      │
      ▼
Power BI — Live-connected Interactive Dashboard
```

---

## 🛠️ Tech Stack

| Stage | Tools |
|---|---|
| Data Cleaning & EDA | Python, Pandas, Matplotlib |
| Data Warehouse | Snowflake (Cloud) |
| Querying | SQL (Snowflake SQL) |
| Visualization | Power BI (DirectQuery, live-connected to Snowflake) |

---

## 📊 Dataset

**Olist Brazilian E-Commerce Dataset** (Kaggle) — real, anonymized order data from a Brazilian e-commerce marketplace (2016–2018).

5 relational tables were used out of the original 9:
- `customers`
- `orders`
- `order_items`
- `products`
- `sellers`

---

## 🧹 Step 1: Data Cleaning & EDA (Python)

Performed in `EDA.ipynb` — for each of the 5 tables:
- Shape, structure, and datatype checks
- Null-value verification (not blindly imputed — e.g., missing delivery dates in `orders` were cross-verified against `order_status` before deciding to leave them as-is)
- Duplicate checks
- Outlier detection (IQR method) — verified high-value outliers (e.g., a ₹6735 order) by joining back to the `products` table to confirm they were genuine high-value/heavy items, not data errors
- Visualizations: order status distribution, monthly order trend, top product categories, top states by customer count, price distribution

Cleaned tables were exported as individual CSVs (kept separate — not pre-merged in Python — specifically so JOINs could be practiced in SQL instead).

---

## ❄️ Step 2: Snowflake Data Warehouse

Set up from scratch on a Snowflake free trial account:
- Created a **Database** and **Schema**
- Designed and created **5 tables** with explicit column types
- Loaded the 5 cleaned CSVs via Snowflake's native file-upload feature
- Debugged real-world issues along the way: type mismatches (e.g., ID columns wrongly typed as numeric), ambiguous column names in joins, and column-name typos

Wrote **30 SQL queries** (`Business Queries Snowflake.sql`) covering:
- Multi-table JOINs & aggregations
- CTEs (single, nested, and multiple in one query)
- Window functions — `RANK`, `DENSE_RANK`, `ROW_NUMBER`, `LAG`, `NTILE`, `PERCENT_RANK`
- Set operations (`EXCEPT`), `EXISTS` / `NOT EXISTS`
- `MERGE` (upsert), `CREATE VIEW`, `CTAS`
- `ROLLUP` and `GROUPING SETS` for multi-level aggregation
- A **recursive CTE** to generate a date series and find gap months
- Self-joins, `LISTAGG`, `COALESCE`, `HAVING` vs `WHERE`

---

## 📈 Step 3: Power BI Dashboard

Connected **live to Snowflake** (DirectQuery) to build an interactive dashboard.

![Power BI Dashboard](./SCREEN%20SHOT%20OF%20POWER%20BI%20DASHBOARD.png)

**KPIs tracked:**
- Total Orders, Total Revenue, Total Customers, Average Order Value
- Delivery Success Rate, Cancellation Rate, Average Delivery Time

**Visuals:**
- Order Status breakdown
- Revenue by Product Category, City, and State (with map)
- Revenue trend by Year
- Delivery Time Distribution (bucketed via a custom DAX measure)
- Year slicer for interactive filtering

---

## 💡 Key Insights

- A small number of product categories and cities (São Paulo, Rio de Janeiro) account for a disproportionate share of total revenue.
- Olist assigns a **new `customer_id` per order** — the true repeat-customer count only becomes visible when grouping by `customer_unique_id` instead.
- ~97% of orders are successfully delivered, with an average delivery time of ~12 days.
- High-value outliers in order pricing were verified as genuine (heavy/bulky products), not data-entry errors — avoiding the mistake of stripping legitimate revenue from the analysis.

---

## 🖼️ Project Screenshots (Pipeline Walkthrough)

See [`Project Screenshots thoughout the Pipeline`](./Project%20Screenshots%20thoughout%20the%20Pipeline) for step-by-step screenshots covering:
- Python EDA & cleaning in VS Code
- Snowflake database/schema/table setup
- SQL query development and results in Snowflake Worksheets
- Power BI dashboard building

---

## 📁 Repo Structure

```
├── Cleaned CSV Files/                          # Cleaned outputs from Python EDA
├── Project Screenshots thoughout the Pipeline/ # Screenshots across the full pipeline
├── EDA.ipynb                                    # Python cleaning + EDA + visualizations
├── Business Queries Snowflake.sql               # 30 SQL practice queries on Snowflake
├── Dashbord Oilist Dataset.pbix                 # Power BI dashboard file
├── Dashbord Oilist Dataset Power BI Dashboard.. # Dashboard export
├── SCREEN SHOT OF POWER BI DASHBOARD.png        # Final dashboard preview
└── README.md
```

---

## 🙋 About

Built by **Vaibhav Verma** — MCA student, aspiring Data Analyst.

- 🔗 [LinkedIn](https://linkedin.com/in/hey-vaibhav-verma/)
- 💻 [GitHub](https://github.com/vaibhavverma200421)
- 🌐 [Portfolio](https://vaibhavverma200421.github.io/My-portfolio/)
