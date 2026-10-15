# Olist E-Commerce: Data Pipeline & Analysis

End-to-end data project on the [Brazilian E-Commerce Public Dataset by Olist](https://www.kaggle.com/datasets/olistbr/brazilian-ecommerce):
CSV files → PostgreSQL (raw → staging → analytics) → exploratory analysis → insights.

## Business questions
1. **Theme 1: Purchasing behaviour and temporal trends**
   - How has order volume evolved over the observation period?
   - How does order volume vary across days of the week?
   - At what times of day are customers most likely to place orders?
   - How did monthly order volume change between 2017 and 2018?

2. **Theme 2: Revenue and product performance**
   - Which product categories generate the highest sales revenue?
   - How do product categories differ in sales volume, average selling price, and customer ratings?

3. **Theme 3: Customer behaviour and retention**
   - What proportion of customers make repeat purchases, and how much sales value do they contribute?
   - Which Brazilian states contribute the most and least to marketplace sales, and how do their customer and order profiles differ?

4. **Theme 4: Delivery and operational performance**
   - How frequently are orders delivered late?
   - How is delivery performance related to customer review scores?

5. **Theme 5: Payment behaviour**
   - Which payment methods are most frequently used, and how do their payment values and installment patterns compare?
   - How long does it take for orders to be approved after purchase, and how does this vary over time?
## Architecture

```
data/raw/*.csv ──┐
   (Kaggle)      ├─► raw schema ──► staging schema ──► analytics schema ──► dashboard
IBGE API ────────┘   as received    cleaned + typed    facts & dimensions     EDA & insights
 (states)            (all TEXT)     + keys
```

| Layer | Purpose | Built by |
|---|---|---|
| `raw` | Source data exactly as received, nothing fixed | `src/load_raw.py` (CSVs), `src/load_states.py` (IBGE API) |
| `staging` | Cleaned, correctly typed, keys enforced | `sql/03_staging.sql` |
| `analytics` | Business-ready tables (planned) | `sql/04_analytics.sql` |

The Brazilian states reference table (state code, name, region) is not a CSV: it is fetched from the
[IBGE localities API](https://servicodados.ibge.gov.br/api/docs/localidades). The API returns one row per mesoregion,
so each state appears several times in `raw`; staging keeps one row per state (27).

## Setup

**1. Install PostgreSQL** and a client such as pgAdmin or DBeaver.

**2. Create the database and a user** (run in pgAdmin's query tool or `psql` as the `postgres` user):
```sql
CREATE USER olist_user WITH PASSWORD 'choose_a_password';
CREATE DATABASE olist OWNER olist_user;
```

**3. Python environment**
```bash
python -m venv venv
venv\Scripts\activate          # Windows   (macOS/Linux: source venv/bin/activate)
pip install -r requirements.txt
```

**4. Configure credentials**: open .env` and fill in your password.

**5. Download the data** from Kaggle and put the 9 CSV files in `data/raw/` (see `data/README.md`).
The states data needs no download: it is fetched from the API when the pipeline runs (internet connection required).

## Run

```bash
python src/run_pipeline.py      # raw load (CSVs) + states load (API) + staging build
```
or step by step:
```bash
python src/load_raw.py          # CSV -> raw schema
python src/load_states.py       # IBGE API -> raw.brazil_states
python src/build_staging.py     # raw -> staging
```
All steps are safe to re-run: they rebuild their tables instead of appending duplicates.
`build_staging.py` needs `raw.brazil_states`, so run `load_states.py` before it.

## Project structure

```
├── data/
│   ├── raw/                 # CSVs live here 
│   └── README.md            # where to download the data
├── docs/
│   └── data_quality_log.md  # problems found + decision taken for each
├── notebooks/
│   └── 
├── reports/figures/         # exported charts
├── sql/
│   ├── 01_create_schemas.sql
│   ├── 02_raw_tables.sql
│   └── 03_staging.sql
├── src/
│   ├── db.py                # connection + SQL runner
│   ├── load_raw.py          # CSV files -> raw
│   ├── load_states.py       # IBGE API -> raw
│   ├── build_staging.py
│   └── run_pipeline.py
├── .env
├── requirements.txt
└── README.md
```

## Roadmap
- [x] Data profiling and cleaning rules (notebook)
- [x] Database setup, raw load, staging layer
- [x] Brazilian states loaded from the IBGE API
- [ ] Analytics layer (`fact_order_items`, dimensions, marts)
- [ ] Analysis, charts and written insights
- [ ] Dashboard

## Key findings
