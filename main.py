import time
from pathlib import Path

import kagglehub
import pandas as pd
import psycopg2
from psycopg2.extensions import ISOLATION_LEVEL_AUTOCOMMIT
import schedule
from sqlalchemy import create_engine

import os
from dotenv import load_dotenv

# Base directory relative to this script location (portable across systems)
BASE_DIR = Path(__file__).resolve().parent
DATA_DIR = BASE_DIR / "formula-1-race-data"

# Load environment variables directly from .env file
load_dotenv(dotenv_path=BASE_DIR / ".env")

# Database Configuration strictly from environment variables (.env)
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
  raise ValueError(f"Missing required environment variables in .env: {', '.join(missing_vars)}")

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
  """Transform & Load: Read CSVs, handle null representations, and load into PostgreSQL."""
  ensure_database_exists()

  engine = create_engine(DB_URI)
  csv_files = sorted(list(data_dir.glob("*.csv")))

  if not csv_files:
    print("[Load Warning] No CSV files found.")
    return

  print(f"\n[Transform & Load] Loading {len(csv_files)} tables to PostgreSQL...")

  for file_path in csv_files:
    table_name = file_path.stem  # file name without extension becomes table name
    try:
      # Transform: Handle Kaggle F1 null representations (\N, None, null)
      df = pd.read_csv(file_path, na_values=["\\N", "null", "None", ""])

      # Load raw data into PostgreSQL
      df.to_sql(
        name=table_name,
        con=engine,
        if_exists="replace",
        index=False,
        chunksize=5000,
        method="multi",
      )
      print(f" -> Table '{table_name}' loaded ({len(df):,} rows)")
    except Exception as error:
      print(f" -> [Error] Failed to load table '{table_name}': {error}")

  print("\n[ETL Completed] All Formula 1 data synchronized successfully to PostgreSQL!\n")


def run_etl():
  print("=" * 60)
  print(f"Starting ETL Pipeline: {time.strftime('%Y-%m-%d %H:%M:%S')}")
  print("=" * 60)

  data_dir = download_data()
  if data_dir is None:
    print("[Error] ETL pipeline stopped: data directory not found.")
    return

  load_to_postgres(data_dir)


# Schedule ETL to run hourly
schedule.every().hour.do(run_etl)

if __name__ == "__main__":
  # Run once immediately on startup
  run_etl()

  # Run scheduler loop
  print("Scheduler running... Press Ctrl + C to exit.")
  while True:
    schedule.run_pending()
    time.sleep(1)
