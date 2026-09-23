-- ==============================================================================
-- Formula 1 Analytics & Master SQL Queries
-- Database Engine: PostgreSQL 14+ / Supabase
--
-- ARCHITECTURE NOTE:
-- All session timestamps (Race, Qualifying, Practices, Sprint) are stored in UTC.
-- Localized timezone conversions (e.g., WIB / UTC+7) are handled in the Backend 
-- application layer (DateHelper) to maintain database neutrality and global standard.
-- ==============================================================================


-- ==============================================================================
-- SECTION 0: ETL SYNCHRONIZATION & METADATA MONITORING
-- ==============================================================================

-- 0.1 View All ETL Synchronization Logs (Chronological History)
SELECT 
    id,
    last_synced_at,
    status,
    total_tables_synced
FROM public.etl_metadata
ORDER BY last_synced_at DESC;

-- 0.2 View Latest Database Synchronization Summary
SELECT 
    MAX(last_synced_at) AS latest_sync_time_utc,
    COUNT(*) AS total_sync_runs,
    SUM(CASE WHEN status = 'SUCCESS' THEN 1 ELSE 0 END) AS successful_runs,
    SUM(CASE WHEN status != 'SUCCESS' THEN 1 ELSE 0 END) AS failed_runs
FROM public.etl_metadata;


-- ==============================================================================
-- SECTION 1: CORE DIRECTORIES & REFERENCE DATA
-- ==============================================================================

-- 1.1 List All Available Seasons (Includes Season Wikipedia URL)
SELECT 
    "year", 
    "url" AS season_wiki_url
FROM public.seasons
ORDER BY "year" DESC;

-- 1.2 List All Circuits Worldwide (Includes GPS Coordinates & Elevation)
SELECT 
    "circuitId", 
    "circuitRef", 
    "name" AS circuit_name, 
    "location", 
    "country",
    "lat" AS latitude,
    "lng" AS longitude,
    "alt" AS altitude_meters,
    "url" AS circuit_wiki_url
FROM public.circuits
ORDER BY "country" ASC, "name" ASC;

-- 1.3 List All Historical Drivers
SELECT 
    "driverId", 
    "driverRef", 
    "code" AS driver_code, 
    "number" AS permanent_number,
    "forename" || ' ' || "surname" AS full_name, 
    "nationality",
    "dob" AS date_of_birth,
    "url" AS driver_wiki_url
FROM public.drivers
ORDER BY full_name ASC;

-- 1.4 List All Historical Constructors / Teams
SELECT 
    "constructorId", 
    "constructorRef", 
    "name" AS constructor_name, 
    "nationality" AS constructor_nationality,
    "url" AS constructor_wiki_url
FROM public.constructors
ORDER BY "name" ASC;

-- 1.5 Detailed Driver Career Profile (Races, Wins, Podiums, Total Points)
-- Replace :driver_id with specific driver ID (e.g., 1 for Lewis Hamilton, 830 for Max Verstappen)
SELECT 
    d."driverId",
    d."forename" || ' ' || d."surname" AS full_name,
    d."code" AS driver_code,
    d."number" AS permanent_number,
    d."dob" AS birth_date,
    d."nationality",
    d."url" AS driver_wiki_url,
    COUNT(res."resultId") AS total_races_entered,
    COUNT(CASE WHEN res."positionOrder" = 1 THEN 1 END) AS total_career_wins,
    COUNT(CASE WHEN res."positionOrder" IN (1, 2, 3) THEN 1 END) AS total_career_podiums,
    COALESCE(SUM(res."points"), 0) AS total_career_points
FROM public.drivers d
LEFT JOIN public.results res ON d."driverId" = res."driverId"
WHERE d."driverId" = 1
GROUP BY d."driverId", d."forename", d."surname", d."code", d."number", d."dob", d."nationality", d."url";


-- ==============================================================================
-- SECTION 2: SEASON CALENDAR & WEEKEND SCHEDULES
-- ==============================================================================

-- 2.1 Complete Race Calendar by Selected Season (Standard UTC Timestamps)
-- Replace :year with target season (e.g., 2026)
SELECT 
    r."raceId",
    r."year",
    r."round",
    r."name" AS grand_prix_name,
    c."circuitId",
    c."name" AS circuit_name,
    c."location",
    c."country",
    (r."sprint_date" IS NOT NULL AND r."sprint_date" != '' AND r."sprint_date" NOT LIKE '%N%') AS has_sprint,
    -- Main Race (UTC)
    r."date" AS race_date,
    r."time" AS race_time_utc,
    -- Free Practice Sessions (UTC)
    r."fp1_date",
    r."fp1_time" AS fp1_time_utc,
    r."fp2_date",
    r."fp2_time" AS fp2_time_utc,
    r."fp3_date",
    r."fp3_time" AS fp3_time_utc,
    -- Qualifying & Sprint (UTC)
    r."quali_date",
    r."quali_time" AS quali_time_utc,
    r."sprint_date",
    r."sprint_time" AS sprint_time_utc,
    r."url" AS race_wiki_url,
    c."url" AS circuit_wiki_url
FROM public.races r
JOIN public.circuits c ON r."circuitId" = c."circuitId"
WHERE r."year" = 2026
ORDER BY r."round" ASC;

-- 2.2 Practice Schedule for a Specific Grand Prix Round (UTC)
-- Replace :year and :round_no (e.g., 2026, 1)
SELECT 
    r."raceId",
    r."year",
    r."round",
    r."name" AS grand_prix_name,
    c."name" AS circuit_name,
    -- Free Practice 1
    r."fp1_date",
    r."fp1_time" AS fp1_time_utc,
    -- Free Practice 2
    r."fp2_date",
    r."fp2_time" AS fp2_time_utc,
    -- Free Practice 3
    r."fp3_date",
    r."fp3_time" AS fp3_time_utc,
    -- Qualifying
    r."quali_date",
    r."quali_time" AS quali_time_utc,
    -- Sprint (if applicable)
    r."sprint_date",
    r."sprint_time" AS sprint_time_utc,
    -- Main Race
    r."date" AS race_date,
    r."time" AS race_time_utc
FROM public.races r
JOIN public.circuits c ON r."circuitId" = c."circuitId"
WHERE r."year" = 2026 AND r."round" = 1;

-- 2.3 Sprint Race Weekends for a Season (UTC)
-- Replace :year (e.g., 2026)
SELECT 
    r."raceId",
    r."round",
    r."name" AS grand_prix_name,
    c."name" AS circuit_name,
    c."location",
    c."country",
    r."sprint_date",
    r."sprint_time" AS sprint_time_utc,
    r."date" AS main_race_date,
    r."time" AS main_race_time_utc
FROM public.races r
JOIN public.circuits c ON r."circuitId" = c."circuitId"
WHERE r."year" = 2026 
  AND r."sprint_date" IS NOT NULL AND r."sprint_date" != '' AND r."sprint_date" NOT LIKE '%N%'
ORDER BY r."round" ASC;

-- 2.4 Active Driver Grid for a Season
SELECT DISTINCT
    r."year",
    d."driverId",
    d."code" AS driver_code,
    d."number" AS permanent_number,
    d."forename" || ' ' || d."surname" AS full_name,
    d."nationality",
    d."url" AS driver_wiki_url
FROM public.results res
JOIN public.races r ON res."raceId" = r."raceId"
JOIN public.drivers d ON res."driverId" = d."driverId"
WHERE r."year" = 2026
ORDER BY full_name ASC;

-- 2.5 Active Constructor Teams for a Season
SELECT DISTINCT
    r."year",
    c."constructorId",
    c."name" AS constructor_name,
    c."nationality" AS constructor_nationality,
    c."url" AS constructor_wiki_url
FROM public.results res
JOIN public.races r ON res."raceId" = r."raceId"
JOIN public.constructors c ON res."constructorId" = c."constructorId"
WHERE r."year" = 2026
ORDER BY constructor_name ASC;

-- 2.6 Official Team Driver Lineups for a Season
SELECT DISTINCT
    r."year",
    c."name" AS team_name,
    d."forename" || ' ' || d."surname" AS driver_name,
    d."code" AS driver_code,
    d."number" AS car_number,
    c."url" AS constructor_wiki_url,
    d."url" AS driver_wiki_url
FROM public.results res
JOIN public.races r ON res."raceId" = r."raceId"
JOIN public.constructors c ON res."constructorId" = c."constructorId"
JOIN public.drivers d ON res."driverId" = d."driverId"
WHERE r."year" = 2026
ORDER BY team_name ASC, driver_name ASC;

-- 2.7 Grand Prix Race Winners for Every Round in a Season
SELECT 
    r."round",
    r."name" AS grand_prix_name,
    r."date" AS race_date,
    cir."name" AS circuit_name,
    d."forename" || ' ' || d."surname" AS winner_name,
    c."name" AS winning_team,
    res."time" AS winning_time,
    res."laps" AS laps_completed,
    r."url" AS race_wiki_url,
    d."url" AS driver_wiki_url,
    c."url" AS constructor_wiki_url
FROM public.results res
JOIN public.races r ON res."raceId" = r."raceId"
JOIN public.circuits cir ON r."circuitId" = cir."circuitId"
JOIN public.drivers d ON res."driverId" = d."driverId"
JOIN public.constructors c ON res."constructorId" = c."constructorId"
WHERE r."year" = 2026 AND res."positionOrder" = 1
ORDER BY r."round" ASC;

-- 2.8 Pole Position Sitters for Every Round in a Season
SELECT 
    r."round",
    r."name" AS grand_prix,
    d."forename" || ' ' || d."surname" AS pole_sitter,
    c."name" AS team_name,
    q."q3" AS fastest_q3_lap,
    d."url" AS driver_wiki_url,
    c."url" AS constructor_wiki_url
FROM public.qualifying q
JOIN public.races r ON q."raceId" = r."raceId"
JOIN public.drivers d ON q."driverId" = d."driverId"
JOIN public.constructors c ON q."constructorId" = c."constructorId"
WHERE r."year" = 2026 AND q."position" = 1
ORDER BY r."round" ASC;


-- ==============================================================================
-- SECTION 3: WORLD CHAMPIONSHIP STANDINGS
-- ==============================================================================

-- 3.1 Latest Driver Championship Standings (Most Recent Round Completed)
WITH latest_race AS (
    SELECT ds."raceId"
    FROM public.driver_standings ds
    JOIN public.races r ON ds."raceId" = r."raceId"
    ORDER BY r."date" DESC, r."round" DESC
    LIMIT 1
)
SELECT 
    ds."position",
    ds."positionText" AS position_text,
    ds."points",
    ds."wins",
    d."driverId",
    d."code" AS driver_code,
    d."number" AS permanent_number,
    d."forename" || ' ' || d."surname" AS driver_name,
    d."nationality",
    d."url" AS driver_wiki_url,
    r."year" AS season,
    r."name" AS latest_race_name
FROM public.driver_standings ds
JOIN public.drivers d ON ds."driverId" = d."driverId"
JOIN public.races r ON ds."raceId" = r."raceId"
WHERE ds."raceId" = (SELECT "raceId" FROM latest_race)
ORDER BY ds."position" ASC;

-- 3.2 Latest Constructor Championship Standings (Most Recent Round Completed)
WITH latest_race AS (
    SELECT cs."raceId"
    FROM public.constructor_standings cs
    JOIN public.races r ON cs."raceId" = r."raceId"
    ORDER BY r."date" DESC, r."round" DESC
    LIMIT 1
)
SELECT 
    cs."position",
    cs."positionText" AS position_text,
    cs."points",
    cs."wins",
    c."constructorId",
    c."name" AS constructor_name,
    c."nationality",
    c."url" AS constructor_wiki_url,
    r."year" AS season,
    r."name" AS latest_race_name
FROM public.constructor_standings cs
JOIN public.constructors c ON cs."constructorId" = c."constructorId"
JOIN public.races r ON cs."raceId" = r."raceId"
WHERE cs."raceId" = (SELECT "raceId" FROM latest_race)
ORDER BY cs."position" ASC;

-- 3.3 Driver Championship Standings for a Specific Season
-- Replace :year with target season (e.g., 2026)
WITH last_race_of_season AS (
    SELECT ds."raceId"
    FROM public.driver_standings ds
    JOIN public.races r ON ds."raceId" = r."raceId"
    WHERE r."year" = 2026
    ORDER BY r."round" DESC
    LIMIT 1
)
SELECT 
    ds."position",
    ds."positionText" AS position_text,
    ds."points",
    ds."wins",
    d."driverId",
    d."code" AS driver_code,
    d."number" AS permanent_number,
    d."forename" || ' ' || d."surname" AS driver_name,
    d."nationality",
    d."url" AS driver_wiki_url
FROM public.driver_standings ds
JOIN public.drivers d ON ds."driverId" = d."driverId"
WHERE ds."raceId" = (SELECT "raceId" FROM last_race_of_season)
ORDER BY ds."position" ASC;

-- 3.4 Constructor Championship Standings for a Specific Season
-- Replace :year with target season (e.g., 2026)
WITH last_race_of_season AS (
    SELECT cs."raceId"
    FROM public.constructor_standings cs
    JOIN public.races r ON cs."raceId" = r."raceId"
    WHERE r."year" = 2026
    ORDER BY r."round" DESC
    LIMIT 1
)
SELECT 
    cs."position",
    cs."positionText" AS position_text,
    cs."points",
    cs."wins",
    c."constructorId",
    c."name" AS constructor_name,
    c."nationality",
    c."url" AS constructor_wiki_url
FROM public.constructor_standings cs
JOIN public.constructors c ON cs."constructorId" = c."constructorId"
WHERE cs."raceId" = (SELECT "raceId" FROM last_race_of_season)
ORDER BY cs."position" ASC;


-- ==============================================================================
-- SECTION 4: GRAND PRIX WEEKEND TELEMETRY & SESSIONS
-- ==============================================================================

-- 4.1 Official Grand Prix Race Classification & Points
-- Replace :year and :round_no (e.g., 2026, 1)
SELECT 
    r."positionText" AS finish_position,
    d."number" AS car_number,
    d."code" AS driver_code,
    d."forename" || ' ' || d."surname" AS driver_name,
    c."name" AS team_name,
    r."grid" AS starting_grid,
    r."laps" AS laps_completed,
    r."time" AS race_time_or_gap,
    r."points" AS points_awarded,
    s."status",
    r."fastestLapTime" AS fastest_lap_time,
    r."rank" AS fastest_lap_rank,
    d."url" AS driver_wiki_url,
    c."url" AS constructor_wiki_url
FROM public.results r
JOIN public.races rc ON r."raceId" = rc."raceId"
JOIN public.drivers d ON r."driverId" = d."driverId"
JOIN public.constructors c ON r."constructorId" = c."constructorId"
JOIN public.status s ON r."statusId" = s."statusId"
WHERE rc."year" = 2026 AND rc."round" = 1
ORDER BY r."positionOrder" ASC;

-- 4.2 Official Starting Grid & Grid Penalty/Promotion Delta
-- Replace :year and :race_id (e.g., 2026, 1121)
SELECT 
    r."grid" AS starting_grid_position,
    d."number" AS car_number,
    d."code" AS driver_code,
    d."forename" || ' ' || d."surname" AS driver_name,
    c."name" AS team_name,
    q."position" AS qualified_position,
    CASE 
        WHEN r."grid" = 0 THEN 'Started from Pit Lane'
        WHEN q."position" IS NULL THEN 'Unclassified in Qualifying'
        WHEN r."grid" > q."position" THEN '+' || CAST(r."grid" - q."position" AS TEXT) || ' Places Grid Penalty'
        WHEN r."grid" < q."position" THEN '-' || CAST(q."position" - r."grid" AS TEXT) || ' Grid Promotion'
        ELSE 'As Qualified'
    END AS grid_status,
    d."url" AS driver_wiki_url,
    c."url" AS constructor_wiki_url,
    rc."url" AS race_wiki_url
FROM public.results r
JOIN public.races rc ON r."raceId" = rc."raceId"
JOIN public.drivers d ON r."driverId" = d."driverId"
JOIN public.constructors c ON r."constructorId" = c."constructorId"
LEFT JOIN public.qualifying q ON (r."raceId" = q."raceId" AND r."driverId" = q."driverId")
WHERE rc."year" = 2026 AND rc."round" = 1
ORDER BY (CASE WHEN r."grid" = 0 THEN 999 ELSE r."grid" END) ASC;

-- 4.3 Qualifying Session Classification (Q1, Q2, Q3 Times)
-- Replace :year and :round_no (e.g., 2026, 1)
SELECT 
    q."position" AS quali_position,
    d."number" AS car_number,
    d."code" AS driver_code,
    d."forename" || ' ' || d."surname" AS driver_name,
    c."name" AS team_name,
    q."q1" AS q1_time,
    q."q2" AS q2_time,
    q."q3" AS q3_time,
    d."url" AS driver_wiki_url,
    c."url" AS constructor_wiki_url
FROM public.qualifying q
JOIN public.races rc ON q."raceId" = rc."raceId"
JOIN public.drivers d ON q."driverId" = d."driverId"
JOIN public.constructors c ON q."constructorId" = c."constructorId"
WHERE rc."year" = 2026 AND rc."round" = 1
ORDER BY q."position" ASC;

-- 4.4 Sprint Race Classification
-- Replace :year and :round_no (e.g., 2026, 1)
SELECT 
    sr."positionText" AS finish_position,
    d."number" AS car_number,
    d."code" AS driver_code,
    d."forename" || ' ' || d."surname" AS driver_name,
    c."name" AS team_name,
    sr."grid" AS starting_grid,
    sr."laps" AS laps_completed,
    sr."time" AS sprint_time_or_gap,
    sr."points" AS points_awarded,
    s."status",
    d."url" AS driver_wiki_url,
    c."url" AS constructor_wiki_url
FROM public.sprint_results sr
JOIN public.races rc ON sr."raceId" = rc."raceId"
JOIN public.drivers d ON sr."driverId" = d."driverId"
JOIN public.constructors c ON sr."constructorId" = c."constructorId"
JOIN public.status s ON sr."statusId" = s."statusId"
WHERE rc."year" = 2026 AND rc."round" = 1
ORDER BY sr."positionOrder" ASC;

-- 4.5 Pit Stop Telemetry & Durations
-- Replace :year and :round_no (e.g., 2026, 1)
SELECT 
    ps."stop" AS stop_number,
    ps."lap" AS lap_number,
    ps."time" AS time_of_day,
    ps."duration" AS pit_duration_seconds,
    ps."milliseconds" AS pit_duration_ms,
    d."code" AS driver_code,
    d."forename" || ' ' || d."surname" AS driver_name,
    c."name" AS team_name
FROM public.pit_stops ps
JOIN public.races rc ON ps."raceId" = rc."raceId"
JOIN public.drivers d ON ps."driverId" = d."driverId"
JOIN public.results res ON (ps."raceId" = res."raceId" AND ps."driverId" = res."driverId")
JOIN public.constructors c ON res."constructorId" = c."constructorId"
WHERE rc."year" = 2026 AND rc."round" = 1
ORDER BY ps."lap" ASC, ps."stop" ASC;

-- 4.6 Lap-by-Lap Progression (Lap Chart Data for Interactive Race Replay)
-- Replace :year and :round_no (e.g., 2026, 1)
SELECT 
    lt."lap",
    lt."position" AS track_position,
    d."code" AS driver_code,
    d."forename" || ' ' || d."surname" AS driver_name,
    lt."time" AS lap_time_str,
    lt."milliseconds" AS lap_time_ms
FROM public.lap_times lt
JOIN public.races rc ON lt."raceId" = rc."raceId"
JOIN public.drivers d ON lt."driverId" = d."driverId"
WHERE rc."year" = 2026 AND rc."round" = 1
ORDER BY lt."lap" ASC, lt."position" ASC;


-- ==============================================================================
-- SECTION 5: ADVANCED STRATEGY & HISTORICAL PERFORMANCE ANALYTICS
-- ==============================================================================

-- 5.1 Greatest Comebacks & Biggest Movers (Grid vs Finish Positive Delta)
-- Replace :year and LIMIT (e.g., 2026, 10)
SELECT 
    rc."year",
    rc."name" AS race_name,
    d."code" AS driver_code,
    d."forename" || ' ' || d."surname" AS driver_name,
    c."name" AS team_name,
    r."grid" AS starting_grid,
    r."positionOrder" AS finish_position,
    (r."grid" - r."positionOrder") AS positions_gained,
    s."status"
FROM public.results r
JOIN public.races rc ON r."raceId" = rc."raceId"
JOIN public.drivers d ON r."driverId" = d."driverId"
JOIN public.constructors c ON r."constructorId" = c."constructorId"
JOIN public.status s ON r."statusId" = s."statusId"
WHERE rc."year" = 2026 
  AND r."grid" > 0 
  AND (r."grid" - r."positionOrder") > 0
ORDER BY positions_gained DESC, r."positionOrder" ASC
LIMIT 10;

-- 5.2 Pit Stop Efficiency & Fastest Average Durations by Constructor Team
-- Replace :year (e.g., 2026)
SELECT 
    c."name" AS team_name,
    COUNT(ps."stop") AS total_pit_stops,
    ROUND(AVG(ps."milliseconds" / 1000.0), 3) AS avg_duration_seconds,
    ROUND(MIN(ps."milliseconds" / 1000.0), 3) AS fastest_stop_seconds
FROM public.pit_stops ps
JOIN public.races rc ON ps."raceId" = rc."raceId"
JOIN public.results res ON (ps."raceId" = res."raceId" AND ps."driverId" = res."driverId")
JOIN public.constructors c ON res."constructorId" = c."constructorId"
WHERE rc."year" = 2026
  AND ps."milliseconds" IS NOT NULL
  AND ps."milliseconds" BETWEEN 15000 AND 60000 -- Excludes long mechanical repairs
GROUP BY c."name"
HAVING COUNT(ps."stop") >= 5
ORDER BY avg_duration_seconds ASC;

-- 5.3 Pole-to-Win Conversion Rate by Season (Turbo Hybrid & Modern Eras)
-- Replace :start_year (e.g., 2015)
SELECT 
    r."year",
    COUNT(r."raceId") AS total_races,
    COUNT(CASE WHEN res."grid" = 1 AND res."positionOrder" = 1 THEN 1 END) AS pole_wins,
    ROUND(
        COUNT(CASE WHEN res."grid" = 1 AND res."positionOrder" = 1 THEN 1 END) * 100.0 / NULLIF(COUNT(r."raceId"), 0), 
        1
    ) AS pole_win_percentage
FROM public.races r
JOIN public.results res ON (r."raceId" = res."raceId" AND res."positionOrder" = 1)
WHERE r."year" >= 2015
GROUP BY r."year"
ORDER BY r."year" DESC;

-- 5.4 High DNF & Incident-Prone Circuits (Highest Attrition Rate All-Time)
SELECT 
    c."name" AS circuit_name,
    c."location",
    c."country",
    COUNT(DISTINCT r."raceId") AS total_gps_hosted,
    COUNT(res."resultId") AS total_entries,
    COUNT(CASE WHEN s."status" NOT IN ('Finished', '+1 Lap', '+2 Laps', '+3 Laps', '+4 Laps', '+5 Laps', '+6 Laps') THEN 1 END) AS total_dnfs,
    ROUND(
        COUNT(CASE WHEN s."status" NOT IN ('Finished', '+1 Lap', '+2 Laps', '+3 Laps', '+4 Laps', '+5 Laps', '+6 Laps') THEN 1 END) * 100.0 / NULLIF(COUNT(res."resultId"), 0), 
        1
    ) AS dnf_percentage
FROM public.circuits c
JOIN public.races r ON c."circuitId" = r."circuitId"
JOIN public.results res ON r."raceId" = res."raceId"
JOIN public.status s ON res."statusId" = s."statusId"
GROUP BY c."circuitId", c."name", c."location", c."country"
HAVING COUNT(DISTINCT r."raceId") >= 10
ORDER BY dnf_percentage DESC
LIMIT 10;

-- 5.5 Miracle Wins from Deep on the Grid (Started P10 or Worse)
SELECT 
    r."year",
    r."name" AS grand_prix,
    d."forename" || ' ' || d."surname" AS driver_name,
    c."name" AS team_name,
    res."grid" AS starting_grid,
    res."positionOrder" AS finish_position,
    res."time" AS winning_time
FROM public.results res
JOIN public.races r ON res."raceId" = r."raceId"
JOIN public.drivers d ON res."driverId" = d."driverId"
JOIN public.constructors c ON res."constructorId" = c."constructorId"
WHERE res."positionOrder" = 1 AND res."grid" >= 10
ORDER BY res."grid" DESC, r."year" DESC
LIMIT 10;

-- 5.6 Drivers with Most Laps Led in P1 (All-Time Formula 1 Leaders)
SELECT 
    d."driverId",
    d."code" AS driver_code,
    d."forename" || ' ' || d."surname" AS driver_name,
    d."nationality",
    COUNT(lt."lap") AS total_laps_led
FROM public.lap_times lt
JOIN public.drivers d ON lt."driverId" = d."driverId"
WHERE lt."position" = 1
GROUP BY d."driverId", d."code", d."forename", d."surname", d."nationality"
ORDER BY total_laps_led DESC
LIMIT 15;

-- 5.7 Fastest Race Speeds Recorded in History (Speed Trap Data)
SELECT 
    r."year",
    r."name" AS grand_prix,
    d."code" AS driver_code,
    d."forename" || ' ' || d."surname" AS driver_name,
    c."name" AS team_name,
    res."fastestLapSpeed"::numeric AS top_speed_kmh,
    res."fastestLapTime" AS fastest_lap_time
FROM public.results res
JOIN public.races r ON res."raceId" = r."raceId"
JOIN public.drivers d ON res."driverId" = d."driverId"
JOIN public.constructors c ON res."constructorId" = c."constructorId"
WHERE res."fastestLapSpeed" IS NOT NULL AND res."fastestLapSpeed" != '' AND res."fastestLapSpeed" != '\N'
ORDER BY top_speed_kmh DESC
LIMIT 10;

-- 5.8 All-Time Grand Prix Winners (Hall of Fame)
SELECT 
    d."driverId",
    d."code" AS driver_code,
    d."forename" || ' ' || d."surname" AS driver_name,
    d."nationality",
    COUNT(res."resultId") AS total_wins,
    MIN(r."year") AS first_win_year,
    MAX(r."year") AS latest_win_year
FROM public.results res
JOIN public.drivers d ON res."driverId" = d."driverId"
JOIN public.races r ON res."raceId" = r."raceId"
WHERE res."positionOrder" = 1
GROUP BY d."driverId", d."code", d."forename", d."surname", d."nationality"
ORDER BY total_wins DESC
LIMIT 15;

-- 5.9 Teammate Head-to-Head Qualifying Battles (Season Qualifying Duels)
-- Replace :year (e.g., 2026)
WITH quali_duels AS (
    SELECT 
        q1."raceId",
        q1."constructorId",
        c."name" AS team_name,
        q1."driverId" AS d1_id,
        d1."code" AS d1_code,
        d1."forename" || ' ' || d1."surname" AS d1_name,
        q1."position" AS d1_pos,
        q2."driverId" AS d2_id,
        d2."code" AS d2_code,
        d2."forename" || ' ' || d2."surname" AS d2_name,
        q2."position" AS d2_pos
    FROM public.qualifying q1
    JOIN public.qualifying q2 ON (
        q1."raceId" = q2."raceId" 
        AND q1."constructorId" = q2."constructorId" 
        AND q1."driverId" < q2."driverId"
    )
    JOIN public.races r ON q1."raceId" = r."raceId"
    JOIN public.constructors c ON q1."constructorId" = c."constructorId"
    JOIN public.drivers d1 ON q1."driverId" = d1."driverId"
    JOIN public.drivers d2 ON q2."driverId" = d2."driverId"
    WHERE r."year" = 2026
)
SELECT 
    team_name,
    d1_code,
    d1_name,
    COUNT(CASE WHEN d1_pos < d2_pos THEN 1 END) AS d1_wins,
    d2_code,
    d2_name,
    COUNT(CASE WHEN d2_pos < d1_pos THEN 1 END) AS d2_wins,
    COUNT(*) AS total_races
FROM quali_duels
GROUP BY team_name, d1_code, d1_name, d2_code, d2_name
ORDER BY team_name ASC;

-- 5.10 Driver Rolling Form (Last 5 Races Moving Average Points)
-- Replace :year (e.g., 2026)
WITH driver_race_points AS (
    SELECT 
        r."round",
        r."name" AS grand_prix,
        d."driverId",
        d."code" AS driver_code,
        d."forename" || ' ' || d."surname" AS driver_name,
        res."points"
    FROM public.results res
    JOIN public.races r ON res."raceId" = r."raceId"
    JOIN public.drivers d ON res."driverId" = d."driverId"
    WHERE r."year" = 2026
),
rolling_calc AS (
    SELECT 
        "round",
        grand_prix,
        driver_code,
        driver_name,
        "points",
        ROUND(AVG("points") OVER (
            PARTITION BY "driverId" 
            ORDER BY "round" 
            ROWS BETWEEN 4 PRECEDING AND CURRENT ROW
        ), 2) AS moving_avg_5_races
    FROM driver_race_points
)
SELECT * FROM rolling_calc
ORDER BY "round" ASC, moving_avg_5_races DESC;

-- 5.11 Cumulative Season Points Trajectory
-- Replace :year (e.g., 2026)
SELECT 
    r."round",
    r."name" AS grand_prix,
    d."code" AS driver_code,
    d."forename" || ' ' || d."surname" AS driver_name,
    res."points" AS race_points,
    SUM(res."points") OVER (
        PARTITION BY d."driverId" 
        ORDER BY r."round" ASC
    ) AS cumulative_points
FROM public.results res
JOIN public.races r ON res."raceId" = r."raceId"
JOIN public.drivers d ON res."driverId" = d."driverId"
WHERE r."year" = 2026
ORDER BY r."round" ASC, cumulative_points DESC;

-- 5.12 Constructor 1-2 Finishes in History (Total Team Dominance)
WITH race_podiums AS (
    SELECT 
        r."raceId",
        r."year",
        r."name" AS grand_prix,
        c."name" AS team_name,
        res."positionOrder"
    FROM public.results res
    JOIN public.races r ON res."raceId" = r."raceId"
    JOIN public.constructors c ON res."constructorId" = c."constructorId"
    WHERE res."positionOrder" IN (1, 2)
)
SELECT 
    team_name,
    COUNT(DISTINCT "raceId") AS total_one_twos,
    MIN("year") AS first_one_two_year,
    MAX("year") AS latest_one_two_year
FROM race_podiums
GROUP BY team_name
HAVING COUNT(DISTINCT "raceId") > 0 AND COUNT(CASE WHEN "positionOrder" = 1 THEN 1 END) = COUNT(CASE WHEN "positionOrder" = 2 THEN 1 END)
ORDER BY total_one_twos DESC;

-- 5.13 Youngest Grand Prix Winners in Formula 1 History
SELECT 
    d."forename" || ' ' || d."surname" AS driver_name,
    d."nationality",
    r."name" AS grand_prix,
    r."year",
    r."date" AS race_date,
    d."dob" AS birth_date,
    ROUND(((r."date"::date - d."dob"::date) / 365.25), 2) AS age_in_years
FROM public.results res
JOIN public.races r ON res."raceId" = r."raceId"
JOIN public.drivers d ON res."driverId" = d."driverId"
WHERE res."positionOrder" = 1 AND d."dob" IS NOT NULL AND r."date" IS NOT NULL
ORDER BY age_in_years ASC
LIMIT 10;

-- 5.14 King of the Circuit (Drivers with Most Wins at a Specific Track)
SELECT 
    c."name" AS circuit_name,
    c."country",
    d."forename" || ' ' || d."surname" AS driver_name,
    COUNT(res."resultId") AS circuit_wins
FROM public.results res
JOIN public.races r ON res."raceId" = r."raceId"
JOIN public.circuits c ON r."circuitId" = c."circuitId"
JOIN public.drivers d ON res."driverId" = d."driverId"
WHERE res."positionOrder" = 1
GROUP BY c."circuitId", c."name", c."country", d."driverId", d."forename", d."surname"
HAVING COUNT(res."resultId") >= 4
ORDER BY circuit_wins DESC, circuit_name ASC
LIMIT 15;

-- 5.15 Historical Circuit Winners & Fastest Lap History
-- Replace :circuit_id (e.g., 6 for Monaco, 14 for Monza, 1 for Albert Park)
SELECT 
    rc."year",
    rc."name" AS race_name,
    d."forename" || ' ' || d."surname" AS winner_name,
    c."name" AS winning_team,
    res."time" AS winning_time,
    res."fastestLapTime" AS fastest_lap_time
FROM public.results res
JOIN public.races rc ON res."raceId" = rc."raceId"
JOIN public.drivers d ON res."driverId" = d."driverId"
JOIN public.constructors c ON res."constructorId" = c."constructorId"
WHERE rc."circuitId" = 6
  AND res."positionOrder" = 1
ORDER BY rc."year" DESC;
