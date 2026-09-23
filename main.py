import io
import time
from pathlib import Path
import os
import kagglehub
import pandas as pd
import psycopg2
from psycopg2.extensions import ISOLATION_LEVEL_AUTOCOMMIT
import schedule
from sqlalchemy import create_engine
from dotenv import load_dotenv

# Base directory relative to this script location (portable across systems)
BASE_DIR = Path(__file__).resolve().parent
DATA_DIR = BASE_DIR / "formula-1-race-data"

# Load environment variables from .env file if present (falls back to system env in CI/CD)
env_file = BASE_DIR / ".env"
if env_file.exists():
    load_dotenv(dotenv_path=env_file)
else:
    load_dotenv()

# Database Configuration strictly from environment variables
DB_USER = os.getenv("DB_USER")
DB_PASSWORD = os.getenv("DB_PASSWORD")
DB_HOST = os.getenv("DB_HOST")
DB_PORT = os.getenv("DB_PORT")
DB_NAME = os.getenv("DB_NAME")

# Ensure all required environment variables are present
required_vars = {
    "DB_USER": DB_USER,
    "DB_PASSWORD": DB_PASSWORD,
    "DB_HOST": DB_HOST,
    "DB_PORT": DB_PORT,
    "DB_NAME": DB_NAME,
}
missing_vars = [key for key, val in required_vars.items() if not val]
if missing_vars:
    raise ValueError(f"Missing required environment variables: {', '.join(missing_vars)}")

DB_PORT = int(DB_PORT)
DB_URI = f"postgresql+psycopg2://{DB_USER}:{DB_PASSWORD}@{DB_HOST}:{DB_PORT}/{DB_NAME}"


def ensure_database_exists():
    """Ensure target database exists in PostgreSQL."""
    try:
        conn = psycopg2.connect(
            dbname="postgres",
            user=DB_USER,
            password=DB_PASSWORD,
            host=DB_HOST,
            port=DB_PORT,
        )
        conn.set_isolation_level(ISOLATION_LEVEL_AUTOCOMMIT)
        with conn.cursor() as cur:
            cur.execute("SELECT 1 FROM pg_database WHERE datname = %s", (DB_NAME,))
            if not cur.fetchone():
                cur.execute(f'CREATE DATABASE "{DB_NAME}"')
                print(f"[DB] Database '{DB_NAME}' created successfully.")
            else:
                print(f"[DB] Database '{DB_NAME}' is ready.")
        conn.close()
    except Exception as error:
        print(f"[DB Error] Failed to ensure database exists: {error}")


def record_sync_metadata(total_tables: int = 14, status: str = "SUCCESS"):
    """Record ETL synchronization timestamp and status to PostgreSQL."""
    try:
        conn = psycopg2.connect(
            dbname=DB_NAME,
            user=DB_USER,
            password=DB_PASSWORD,
            host=DB_HOST,
            port=DB_PORT,
        )
        conn.set_isolation_level(ISOLATION_LEVEL_AUTOCOMMIT)
        with conn.cursor() as cur:
            cur.execute("""
                CREATE TABLE IF NOT EXISTS etl_metadata (
                    id SERIAL PRIMARY KEY,
                    last_synced_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
                    status VARCHAR(50),
                    total_tables_synced INTEGER
                );
            """)
            cur.execute("""
                INSERT INTO etl_metadata (status, total_tables_synced)
                VALUES (%s, %s);
            """, (status, total_tables))
            print(f"[Metadata] Logged sync timestamp successfully to PostgreSQL ({status}, {total_tables} tables).")
        conn.close()
    except Exception as error:
        print(f"[Metadata Warning] Failed to log sync timestamp: {error}")


def download_data():
    """Extract: Download dataset from Kaggle or fallback to local files if available."""
    try:
        print("\n[Extract] Downloading dataset from Kaggle...")
        path = kagglehub.dataset_download(
            "jtrotman/formula-1-race-data",
            output_dir=str(DATA_DIR),
            force_download=True,
        )
        print(f"[Extract] Dataset downloaded to: {path}")
        return Path(path)
    except Exception as error:
        print(f"[Extract Warning] Kaggle download failed: {error}")
        if DATA_DIR.exists() and any(DATA_DIR.glob("*.csv")):
            print(f"[Extract] Using existing local files from: {DATA_DIR}")
            return DATA_DIR
        return None


def load_to_postgres(data_dir: Path):
    """
    Transform & High-Performance Load (Staging Table Pattern):
    1. Ingest raw CSV data directly into Staging Table (`stg_{table_name}`) via PostgreSQL native COPY.
    2. Atomically transfer and populate Main Table (`{table_name}`) from Staging Table.
    3. Clean up Staging Table to ensure database remains clean and optimized.
    """
    ensure_database_exists()

    engine = create_engine(DB_URI)
    conn = psycopg2.connect(
        dbname=DB_NAME,
        user=DB_USER,
        password=DB_PASSWORD,
        host=DB_HOST,
        port=DB_PORT,
    )
    conn.autocommit = False
    cur = conn.cursor()

    csv_files = sorted(list(data_dir.glob("*.csv")))
    if not csv_files:
        print("[Load Warning] No CSV files found.")
        conn.close()
        return

    print(f"\n[Transform & Load] Fast Staging & Bulk Ingestion for {len(csv_files)} tables...")

    loaded_count = 0
    for file_path in csv_files:
        table_name = file_path.stem
        staging_table = f"stg_{table_name}"
        try:
            # Step 1: Read CSV and sanitize nulls
            df = pd.read_csv(file_path, na_values=["\\N", "null", "None", ""])

            # Step 2: Create Staging Table schema
            df.head(0).to_sql(name=staging_table, con=engine, if_exists="replace", index=False)

            # Step 3: Fast Stream Bulk COPY directly into Staging Table
            buffer = io.StringIO()
            df.to_csv(buffer, index=False, header=False, na_rep="\\N")
            buffer.seek(0)
            cur.copy_expert(
                f'COPY "{staging_table}" FROM STDIN WITH (FORMAT CSV, NULL \'\\N\')',
                buffer
            )

            # Step 4: Atomic Transaction - Populate Main Table from Staging Table
            cur.execute(f'DROP TABLE IF EXISTS "{table_name}" CASCADE;')
            cur.execute(f'CREATE TABLE "{table_name}" AS TABLE "{staging_table}";')

            # Step 5: Clean up Staging Table
            cur.execute(f'DROP TABLE IF EXISTS "{staging_table}" CASCADE;')

            conn.commit()
            loaded_count += 1
            print(f" -> [Staging -> Main] Table '{table_name}' loaded ({len(df):,} rows)")
        except Exception as error:
            conn.rollback()
            print(f" -> [Error] Failed to load table '{table_name}': {error}")

    cur.close()
    conn.close()

    # Record sync timestamp to etl_metadata table
    record_sync_metadata(total_tables=loaded_count, status="SUCCESS" if loaded_count > 0 else "FAILED")

    print("\n[ETL Completed] All Formula 1 data staged & synchronized successfully to PostgreSQL!\n")


def run_etl():
    print("=" * 60)
    print(f"Starting ETL Pipeline: {time.strftime('%Y-%m-%d %H:%M:%S')}")
    print("=" * 60)

    data_dir = download_data()
    if data_dir is None:
        print("[Error] ETL pipeline stopped: data directory not found.")
        return

    load_to_postgres(data_dir)


if __name__ == "__main__":
    # -------------------------------------------------------------------------
    # 1. Single Execution Mode (Default for GitHub Actions / CLI one-time runs)
    # -------------------------------------------------------------------------
    run_etl()

    # -------------------------------------------------------------------------
    # 2. Local Scheduler Mode (Uncomment below to run continuous local loop)
    # -------------------------------------------------------------------------
    # schedule.every().hour.do(run_etl)
    # print("Scheduler running... Press Ctrl + C to exit.")
    # while True:
    #     schedule.run_pending()
    #     time.sleep(1)
