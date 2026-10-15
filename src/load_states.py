"""Fetch Brazilian states from the IBGE API and load them into raw.brazil_states.

The API endpoint returns one record per mesoregion, so every state shows up
several times. Following the ELT approach, the data lands in `raw` exactly as
received (duplicates included); the staging layer removes the duplicates.

Usage (from the project root):
    python src/load_states.py
"""
import pandas as pd
import requests
from psycopg2.extras import execute_values

from db import PROJECT_ROOT, get_connection, run_sql_file

SQL_DIR = PROJECT_ROOT / "sql"

IBGE_API_URL = "https://servicodados.ibge.gov.br/api/v1/localidades/mesorregioes"

# Columns of the flattened API response -> columns of raw.brazil_states
COLUMN_MAP = {
    "UF.id": "state_id",
    "UF.sigla": "state_initial",
    "UF.nome": "state_name",
    "UF.regiao.nome": "region_name",
}


def fetch_mesoregions():
    """Call the IBGE API and return the parsed JSON (a list of mesoregions)."""
    response = requests.get(IBGE_API_URL, timeout=30)
    response.raise_for_status()
    return response.json()


def flatten_states(payload):
    """Flatten the nested JSON into a DataFrame with one row per mesoregion."""
    df = pd.json_normalize(payload)
    return df[list(COLUMN_MAP)].rename(columns=COLUMN_MAP).astype(str)


def main():
    print("Fetching states from the IBGE API ...")
    states = flatten_states(fetch_mesoregions())

    conn = get_connection()
    try:
        # Same idempotent setup as load_raw.py, so this script can run on its own
        run_sql_file(conn, SQL_DIR / "01_create_schemas.sql")
        run_sql_file(conn, SQL_DIR / "02_raw_tables.sql")

        with conn, conn.cursor() as cur:
            cur.execute("TRUNCATE TABLE raw.brazil_states")
            execute_values(
                cur,
                "INSERT INTO raw.brazil_states (state_id, state_initial, state_name, region_name) VALUES %s",
                list(states.itertuples(index=False, name=None)),
            )
        distinct = states["state_initial"].nunique()
        print(f"  raw.brazil_states {len(states):>10,} rows ({distinct} distinct states)")
    finally:
        conn.close()


if __name__ == "__main__":
    main()
