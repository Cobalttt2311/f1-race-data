# F1 - Race Data - ETL

An automated **Extract, Transform, and Load (ETL)** pipeline designed to ingest, process, and synchronize comprehensive historical and modern Formula 1 motorsport datasets (1950 – present) into a relational PostgreSQL database.

---

## 🎯 Project Overview & Objective

The primary objective of this project is to build a reliable, automated data engineering pipeline for Formula 1 racing statistics. It handles:
1. **Automated Extraction**: Fetching the latest curated Formula 1 dataset directly from Kaggle via `kagglehub`.
2. **Data Transformation & Cleaning**: Standardizing data types, handling missing values, and formatting relational tables.
3. **Database Ingestion**: Automatically creating and loading 14 relational tables into PostgreSQL using SQLAlchemy and Psycopg2.
4. **Automated Scheduling**: Periodically checking and syncing new race results and standings data without manual intervention.

---

## 📊 Data Source & Acknowledgements

* **Dataset Source**: [Kaggle - Formula 1 Race Data (1950 - 2026)](https://www.kaggle.com/datasets/jtrotman/formula-1-race-data)
* **Special Thanks**: Sincere gratitude to **James Trotman** for curating, maintaining, and providing this rich Formula 1 dataset to the data science community.

---

## 🗄️ Database Schema & Loaded Tables

The pipeline processes and synchronizes **14 core relational tables**:

| Table Name | Description |
| :--- | :--- |
| `circuits` | Track names, locations, country, coordinates, and altitudes |
| `constructors` | Team names, constructor references, nationalities, and wiki URLs |
| `drivers` | Driver names, permanent numbers, codes, DOB, and nationalities |
| `seasons` | Championship seasons archive with Wikipedia URLs |
| `races` | Grand Prix calendar, rounds, dates, and session start times |
| `qualifying` | Q1, Q2, Q3 lap times and grid qualifications |
| `results` | Final race finishing positions, points, laps, and fastest lap telemetry |
| `sprint_results` | Sprint race classifications, grid positions, and points |
| `driver_standings` | Cumulative driver championship points, ranks, and wins per round |
| `constructor_standings` | Constructor championship cumulative points, ranks, and wins |
| `constructor_results` | Constructor points and results per Grand Prix |
| `pit_stops` | Pit stop timings, stop counts, lap numbers, duration, and milliseconds |
| `lap_times` | Lap-by-lap timings, milliseconds, and track positions |
| `status` | Finishing status codes (e.g., Finished, Collision, Engine, Gearbox, etc.) |

---

## ⚙️ Prerequisites

* **Python**: Version 3.10 or higher
* **PostgreSQL**: Version 14, 15, or 16 (Local instance or Cloud PostgreSQL such as Supabase / AWS RDS)
* **Kaggle Account**: An active Kaggle account to authenticate with the Kaggle API.

---

## 🔑 Kaggle API Configuration

The pipeline uses the official `kagglehub` library to automatically download the dataset from Kaggle. You can authenticate using **either** of the following two methods:

### Option A: Standard `kaggle.json` File (Recommended)
1. Log in to your account on [Kaggle.com](https://www.kaggle.com).
2. Click on your profile picture in the top-right corner and select **Settings** (or go to `https://www.kaggle.com/settings`).
3. Scroll down to the **API** section and click **Create New Token**.
4. A file named `kaggle.json` will be downloaded to your computer.
5. Move the downloaded `kaggle.json` file to your user profile directory:
   * **Windows**: `C:\Users\<Your_Username>\.kaggle\kaggle.json`
   * **Linux / macOS**: `~/.kaggle/kaggle.json` (run `chmod 600 ~/.kaggle/kaggle.json` to secure permissions)

### Option B: Environment Variables (`.env`)
Alternatively, if you are deploying to a server or prefer using environment variables without creating the `.kaggle` folder, you can copy your credentials from `kaggle.json` directly into your `.env` file:
```env
KAGGLE_USERNAME=your_kaggle_username
KAGGLE_KEY=your_kaggle_api_key
```

---

## 🚀 Installation & Setup

### 1. Clone or Navigate to the Directory
```bash
cd f1-race-data
```

### 2. Create and Activate Virtual Environment
* **On Windows (PowerShell):**
  ```powershell
  python -m venv venv
  .\venv\Scripts\activate
  ```
* **On Linux / macOS:**
  ```bash
  python -m venv venv
  source venv/bin/activate
  ```

### 3. Install Dependencies
```bash
pip install -r requirements.txt
```

### 4. Configure Environment Variables (`.env`)
Create a `.env` file in the root of the `f1-race-data` directory (refer to [.env.example](file:///D:/Eksplorasi/f1-race-data/.env.example)):

```env
# PostgreSQL Database Configuration
DB_USER=postgres
DB_PASSWORD=your_secure_password
DB_HOST=localhost
DB_PORT=5432
DB_NAME=formula_one

# Optional Kaggle Credentials (if not using ~/.kaggle/kaggle.json)
KAGGLE_USERNAME=your_kaggle_username
KAGGLE_KEY=your_kaggle_api_key
```

> ⚠️ **Note**: Never commit your real `.env` file to public version control.

---

## 🏃 Running the ETL Pipeline

Execute the main script to run the full extraction, transformation, and database load:

```bash
python main.py
```

### Pipeline Workflow:
1. **Verification**: Connects to PostgreSQL and verifies the target database exists.
2. **Extraction**: Downloads and unpacks the latest archive from Kaggle into `formula-1-race-data/`.
3. **Transformation & Ingestion**: Reads each CSV, transforms data types, and ingests all 14 tables into PostgreSQL.
4. **Scheduler**: Stays active to periodically re-sync data according to the schedule (press `Ctrl + C` to stop).

---

## 🧪 Testing & Data Validation (SQL Queries)

After running the pipeline, you can validate the data by executing queries from [`queries.sql`](file:///D:/Eksplorasi/f1-race-data/queries.sql) using your preferred database tool (DBeaver, pgAdmin, `psql`, or VSCode Database Client):

```sql
-- 1. Top 10 Drivers with Most Race Wins
SELECT 
    d.forename || ' ' || d.surname AS driver_name,
    d.nationality,
    COUNT(r.resultid) AS total_wins
FROM results r
JOIN drivers d ON r.driverid = d.driverid
WHERE r.positionorder = 1
GROUP BY d.driverid, driver_name, d.nationality
ORDER BY total_wins DESC
LIMIT 10;

-- 2. Latest Season (2026) Constructor Championship Standings
SELECT 
    c.name AS constructor_name,
    cs.points,
    cs.wins,
    cs.position
FROM constructor_standings cs
JOIN constructors c ON cs.constructorid = c.constructorid
JOIN races r ON cs.raceid = r.raceid
WHERE r.year = 2026
ORDER BY cs.position ASC;

-- 3. Fastest Pit Stops in a Grand Prix
SELECT 
    d.forename || ' ' || d.surname AS driver_name,
    ps.stop AS stop_number,
    ps.lap,
    ps.duration,
    ps.milliseconds
FROM pit_stops ps
JOIN drivers d ON ps.driverid = d.driverid
WHERE ps.raceid = 1120
ORDER BY ps.milliseconds ASC
LIMIT 10;
```

---

## 📁 Project Structure

```text
f1-race-data/
├── formula-1-race-data/   # Extracted CSV datasets
├── main.py                # Main ETL script & scheduler
├── queries.sql            # Analytical & validation SQL queries
├── requirements.txt       # Python package dependencies
├── .env.example           # Template for environment variables
└── README.md              # Project documentation
```

---

## 📄 License
This project is intended for educational purposes, data engineering exploration, and motorsport analytics.

Made by Cobalt
