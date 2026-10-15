"""Shared database helpers: connection + running .sql files."""
import os
from pathlib import Path

import psycopg2
from dotenv import load_dotenv

PROJECT_ROOT = Path(__file__).resolve().parents[1]
load_dotenv(PROJECT_ROOT / ".env")


def get_connection():
    """Open a connection using the values in the .env file."""
    required = ["DB_HOST", "DB_PORT", "DB_NAME", "DB_USER", "DB_PASSWORD"]
    missing = [name for name in required if not os.getenv(name)]
    if missing:
        raise SystemExit(
            f"Missing settings in .env: {', '.join(missing)}\n"
            "Copy .env.example to .env and fill it in."
        )
    conn = psycopg2.connect(
        host=os.environ["DB_HOST"],
        port=os.environ["DB_PORT"],
        dbname=os.environ["DB_NAME"],
        user=os.environ["DB_USER"],
        password=os.environ["DB_PASSWORD"],
    )
    conn.set_client_encoding("UTF8")
    return conn


def run_sql_file(conn, path):
    """Execute every statement in a .sql file, then commit."""
    sql = Path(path).read_text(encoding="utf-8")
    with conn.cursor() as cur:
        cur.execute(sql)
    conn.commit()
    print(f"  ran {Path(path).name}")
