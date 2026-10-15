"""Load the Olist CSV files into the `raw` schema of PostgreSQL (step: Extract + Load).

Safe to re-run: each table is emptied and reloaded inside ONE transaction,
so a failed run never leaves  with half-loaded data.

"""
import csv

from db import PROJECT_ROOT, get_connection, run_sql_file

RAW_DIR = PROJECT_ROOT / "data" / "raw"
SQL_DIR = PROJECT_ROOT / "sql"

# CSV file name -> table in the raw schema
FILE_TO_TABLE = {
    "olist_customers_dataset.csv": "customers",
    "olist_geolocation_dataset.csv": "geolocation",
    "olist_orders_dataset.csv": "orders",
    "olist_order_items_dataset.csv": "order_items",
    "olist_order_payments_dataset.csv": "order_payments",
    "olist_order_reviews_dataset.csv": "order_reviews",
    "olist_products_dataset.csv": "products",
    "olist_sellers_dataset.csv": "sellers",
    "product_category_name_translation.csv": "product_category_translation",
}

# "utf-8-sig" silently strips the invisible BOM character some CSVs start with
ENCODING = "utf-8-sig"


def read_header(path):
    with open(path, newline="", encoding=ENCODING) as f:
        return next(csv.reader(f))


def count_csv_records(path):
    """Count records with the csv module (NOT `wc -l`): review comments
    contain line breaks inside quotes, so lines != records."""
    with open(path, newline="", encoding=ENCODING) as f:
        return sum(1 for _ in csv.reader(f)) - 1  # minus header


def load_file(cur, path, table):
    columns = ", ".join(f'"{c}"' for c in read_header(path))
    cur.execute(f"TRUNCATE TABLE raw.{table}")
    copy_sql = f"COPY raw.{table} ({columns}) FROM STDIN WITH (FORMAT csv, HEADER true)"
    with open(path, newline="", encoding=ENCODING) as f:
        cur.copy_expert(copy_sql, f)
    cur.execute(f"SELECT COUNT(*) FROM raw.{table}")
    loaded = cur.fetchone()[0]
    expected = count_csv_records(path)
    if loaded != expected:
        raise RuntimeError(f"{table}: loaded {loaded} rows but the CSV has {expected}")
    return loaded


def main():
    missing = [name for name in FILE_TO_TABLE if not (RAW_DIR / name).exists()]
    if missing:
        raise SystemExit(
            f"These files are missing from {RAW_DIR}:\n  " + "\n  ".join(missing)
            + "\nDownload the dataset from Kaggle (see data/README.md)."
        )

    conn = get_connection()
    try:
        print("Creating schemas and raw tables ...")
        run_sql_file(conn, SQL_DIR / "01_create_schemas.sql")
        run_sql_file(conn, SQL_DIR / "02_raw_tables.sql")

        print("Loading CSV files ...")
        with conn, conn.cursor() as cur:  # commit if all OK, rollback on any error
            for file_name, table in FILE_TO_TABLE.items():
                n = load_file(cur, RAW_DIR / file_name, table)
                print(f"  raw.{table:<32} {n:>10,} rows")
        print("Raw load complete.")
    finally:
        conn.close()


if __name__ == "__main__":
    main()
