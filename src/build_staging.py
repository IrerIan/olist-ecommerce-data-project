"""Build the `staging` layer from `raw` by running sql/03_staging.sql.

Usage (from the project root):
    python src/build_staging.py
"""
from db import PROJECT_ROOT, get_connection, run_sql_file

SQL_DIR = PROJECT_ROOT / "sql"

# (table name in raw, table name in staging)
TABLES = [
    ("customers", "customers"),
    ("sellers", "sellers"),
    ("products", "products"),
    ("orders", "orders"),
    ("order_items", "order_items"),
    ("order_payments", "order_payments"),
    ("order_reviews", "order_reviews"),
    ("geolocation", "geolocation"),            # expected to shrink: 1 row per zip prefix
    ("product_category_translation", "product_category_translation"),  # +2 added rows
    ("brazil_states", "brazil_states"),        # expected to shrink: 1 row per state
]


def main():
    conn = get_connection()
    try:
        print("Building staging layer ...")
        run_sql_file(conn, SQL_DIR / "03_staging.sql")

        print("\nRow counts (raw -> staging):")
        with conn.cursor() as cur:
            for raw_table, stg_table in TABLES:
                cur.execute(f"SELECT COUNT(*) FROM raw.{raw_table}")
                n_raw = cur.fetchone()[0]
                cur.execute(f"SELECT COUNT(*) FROM staging.{stg_table}")
                n_stg = cur.fetchone()[0]
                print(f"  {stg_table:<32} {n_raw:>10,} -> {n_stg:>10,}")
        print("\nStaging build complete.")
    finally:
        conn.close()


if __name__ == "__main__":
    main()
