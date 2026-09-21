-- ==============================================================================
-- Formula 1 Analytics & Feature Queries (Complete Master Collection)
-- Database: formula_one (PostgreSQL)
-- Connection: postgresql
--
-- NOTE:
-- Ensure your SQL Client (DBeaver / pgAdmin / DataGrip) is connected to the
-- "formula_one" database under the "public" schema.
-- ==============================================================================


-- ==============================================================================
-- SECTION 1: BASIC & LOOKUP QUERIES
-- ==============================================================================

-- 1.1 List All Available Seasons (Includes Season Wikipedia URL)
SELECT 
    "year", 
    "url" AS season_wiki_url
FROM public.seasons
ORDER BY "year" DESC;
-- Parameter Notes:
--   - No parameter needed (retrieves all recorded F1 seasons)


-- 1.2 List All Circuits (Includes Circuit Wikipedia URL)
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
-- Parameter Notes:
--   - No parameter needed (retrieves all circuits worldwide)


-- 1.3 List All Drivers (Includes Driver Wikipedia URL)
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
-- Parameter Notes:
--   - No parameter needed (retrieves all drivers in F1 history)


-- 1.4 List All Constructors / Teams (Includes Constructor Wikipedia URL)
SELECT 
    "constructorId", 
    "constructorRef", 
    "name" AS constructor_name, 
    "nationality" AS constructor_nationality,
    "url" AS constructor_wiki_url
FROM public.constructors
ORDER BY "name" ASC;
-- Parameter Notes:
--   - No parameter needed (retrieves all constructor teams in F1 history)


-- 1.5 Complete Race Calendar by Selected Year (Includes Practice, Qualifying, Sprint, & Main Race in UTC and WIB)
SELECT 
    r."raceId",
    r."round",
    r."name" AS grand_prix_name,
    r."circuitId",
    c."name" AS circuit_name,
    c."location",
    c."country",
    CASE WHEN r."sprint_date" IS NOT NULL AND r."sprint_date" != '' AND r."sprint_date" != '\N' THEN true ELSE false END AS has_sprint,
    -- Main Race
    r."date" AS race_date,
    r."time" AS race_time_utc,
    CASE 
        WHEN r."time" IS NOT NULL AND r."time" ~ '^[0-9]{2}:[0-9]{2}:[0-9]{2}' AND r."date" ~ '^[0-9]{4}-[0-9]{2}-[0-9]{2}' THEN
            TO_CHAR((r."date" || ' ' || SUBSTRING(r."time" FROM 1 FOR 8))::TIMESTAMP + INTERVAL '7 hours', 'HH24:MI:SS')
        ELSE NULL 
    END AS race_time_wib,
    CASE 
        WHEN r."time" IS NOT NULL AND r."time" ~ '^[0-9]{2}:[0-9]{2}:[0-9]{2}' AND r."date" ~ '^[0-9]{4}-[0-9]{2}-[0-9]{2}' THEN
            TO_CHAR((r."date" || ' ' || SUBSTRING(r."time" FROM 1 FOR 8))::TIMESTAMP + INTERVAL '7 hours', 'YYYY-MM-DD HH24:MI:SS')
        ELSE NULL 
    END AS race_datetime_wib,
    -- Free Practice 1
    r."fp1_date",
    r."fp1_time" AS fp1_time_utc,
    CASE 
        WHEN r."fp1_time" IS NOT NULL AND r."fp1_time" ~ '^[0-9]{2}:[0-9]{2}:[0-9]{2}' AND r."fp1_date" ~ '^[0-9]{4}-[0-9]{2}-[0-9]{2}' THEN
            TO_CHAR((r."fp1_date" || ' ' || SUBSTRING(r."fp1_time" FROM 1 FOR 8))::TIMESTAMP + INTERVAL '7 hours', 'HH24:MI:SS')
        ELSE NULL 
    END AS fp1_time_wib,
    -- Free Practice 2 / Sprint Shootout
    r."fp2_date",
    r."fp2_time" AS fp2_time_utc,
    CASE 
        WHEN r."fp2_time" IS NOT NULL AND r."fp2_time" ~ '^[0-9]{2}:[0-9]{2}:[0-9]{2}' AND r."fp2_date" ~ '^[0-9]{4}-[0-9]{2}-[0-9]{2}' THEN
            TO_CHAR((r."fp2_date" || ' ' || SUBSTRING(r."fp2_time" FROM 1 FOR 8))::TIMESTAMP + INTERVAL '7 hours', 'HH24:MI:SS')
        ELSE NULL 
    END AS fp2_time_wib,
    -- Free Practice 3
    r."fp3_date",
    r."fp3_time" AS fp3_time_utc,
    CASE 
        WHEN r."fp3_time" IS NOT NULL AND r."fp3_time" ~ '^[0-9]{2}:[0-9]{2}:[0-9]{2}' AND r."fp3_date" ~ '^[0-9]{4}-[0-9]{2}-[0-9]{2}' THEN
            TO_CHAR((r."fp3_date" || ' ' || SUBSTRING(r."fp3_time" FROM 1 FOR 8))::TIMESTAMP + INTERVAL '7 hours', 'HH24:MI:SS')
        ELSE NULL 
    END AS fp3_time_wib,
    -- Qualifying
    r."quali_date",
    r."quali_time" AS quali_time_utc,
    CASE 
        WHEN r."quali_time" IS NOT NULL AND r."quali_time" ~ '^[0-9]{2}:[0-9]{2}:[0-9]{2}' AND r."quali_date" ~ '^[0-9]{4}-[0-9]{2}-[0-9]{2}' THEN
            TO_CHAR((r."quali_date" || ' ' || SUBSTRING(r."quali_time" FROM 1 FOR 8))::TIMESTAMP + INTERVAL '7 hours', 'HH24:MI:SS')
        ELSE NULL 
    END AS quali_time_wib,
    -- Sprint
    r."sprint_date",
    r."sprint_time" AS sprint_time_utc,
    CASE 
        WHEN r."sprint_date" IS NOT NULL AND r."sprint_date" != '' AND r."sprint_date" != '\N' AND r."sprint_time" IS NOT NULL AND r."sprint_time" ~ '^[0-9]{2}:[0-9]{2}:[0-9]{2}' AND r."sprint_date" ~ '^[0-9]{4}-[0-9]{2}-[0-9]{2}' THEN
            TO_CHAR((r."sprint_date" || ' ' || SUBSTRING(r."sprint_time" FROM 1 FOR 8))::TIMESTAMP + INTERVAL '7 hours', 'HH24:MI:SS')
        ELSE NULL 
    END AS sprint_time_wib,
    r."url" AS race_wiki_url,
    c."url" AS circuit_wiki_url
FROM public.races r
JOIN public.circuits c ON r."circuitId" = c."circuitId"
WHERE r."year" = 2023
ORDER BY r."round" ASC;
-- Parameter Notes:
--   - r."year" = 2023  --> Target season year (change to 2024, 2022, etc.)


-- 1.6 Driver Profile & Career Statistics Summary (Includes Driver Wikipedia URL)
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
-- Parameter Notes:
--   - d."driverId" = 1  --> Driver ID (e.g. 1 = Lewis Hamilton, 830 = Max Verstappen, 844 = Charles Leclerc)


-- 1.7 Circuit History & Past Winners at Specific Circuit (Includes Driver & Team Wikipedia URLs)
SELECT 
    rc."year",
    rc."name" AS grand_prix_name,
    d."forename" || ' ' || d."surname" AS winner_name,
    c."name" AS winning_team,
    res."time" AS winning_time,
    rc."url" AS race_wiki_url,
    d."url" AS driver_wiki_url,
    c."url" AS constructor_wiki_url
FROM public.results res
JOIN public.races rc ON res."raceId" = rc."raceId"
JOIN public.drivers d ON res."driverId" = d."driverId"
JOIN public.constructors c ON res."constructorId" = c."constructorId"
WHERE rc."circuitId" = 6
  AND res."positionOrder" = 1
ORDER BY rc."year" DESC;
-- Parameter Notes:
--   - rc."circuitId" = 6  --> Circuit ID (e.g. 6 = Monaco, 9 = Silverstone, 14 = Monza, 1 = Melbourne)


-- 1.8 Free Practice Sessions Schedule (FP1, FP2, FP3) for a Specific Grand Prix (UTC & WIB Times)
SELECT 
    r."raceId",
    r."year",
    r."round",
    r."name" AS grand_prix_name,
    c."name" AS circuit_name,
    c."country",
    -- Free Practice 1
    r."fp1_date",
    r."fp1_time" AS fp1_time_utc,
    CASE 
        WHEN r."fp1_time" IS NOT NULL AND r."fp1_time" ~ '^[0-9]{2}:[0-9]{2}:[0-9]{2}' AND r."fp1_date" ~ '^[0-9]{4}-[0-9]{2}-[0-9]{2}' THEN
            TO_CHAR((r."fp1_date" || ' ' || SUBSTRING(r."fp1_time" FROM 1 FOR 8))::TIMESTAMP + INTERVAL '7 hours', 'HH24:MI:SS')
        ELSE NULL 
    END AS fp1_time_wib,
    -- Free Practice 2 (or Sprint Shootout)
    r."fp2_date",
    r."fp2_time" AS fp2_time_utc,
    CASE 
        WHEN r."fp2_time" IS NOT NULL AND r."fp2_time" ~ '^[0-9]{2}:[0-9]{2}:[0-9]{2}' AND r."fp2_date" ~ '^[0-9]{4}-[0-9]{2}-[0-9]{2}' THEN
            TO_CHAR((r."fp2_date" || ' ' || SUBSTRING(r."fp2_time" FROM 1 FOR 8))::TIMESTAMP + INTERVAL '7 hours', 'HH24:MI:SS')
        ELSE NULL 
    END AS fp2_time_wib,
    -- Free Practice 3 (NULL if Sprint weekend)
    r."fp3_date",
    r."fp3_time" AS fp3_time_utc,
    CASE 
        WHEN r."fp3_time" IS NOT NULL AND r."fp3_time" ~ '^[0-9]{2}:[0-9]{2}:[0-9]{2}' AND r."fp3_date" ~ '^[0-9]{4}-[0-9]{2}-[0-9]{2}' THEN
            TO_CHAR((r."fp3_date" || ' ' || SUBSTRING(r."fp3_time" FROM 1 FOR 8))::TIMESTAMP + INTERVAL '7 hours', 'HH24:MI:SS')
        ELSE NULL 
    END AS fp3_time_wib,
    r."url" AS race_wiki_url
FROM public.races r
JOIN public.circuits c ON r."circuitId" = c."circuitId"
WHERE r."year" = 2023 AND r."round" = 1;
-- Parameter Notes:
--   - r."year" = 2023   --> Target season year
--   - r."round" = 1     --> Grand Prix round number


-- 1.9 Dedicated Sprint Race Weekends Schedule for a Season (Includes Sprint & Main Race UTC & WIB Times)
SELECT 
    r."raceId",
    r."year",
    r."round",
    r."name" AS grand_prix_name,
    c."name" AS circuit_name,
    c."country",
    r."sprint_date",
    r."sprint_time" AS sprint_time_utc,
    CASE 
        WHEN r."sprint_time" IS NOT NULL AND r."sprint_time" ~ '^[0-9]{2}:[0-9]{2}:[0-9]{2}' AND r."sprint_date" ~ '^[0-9]{4}-[0-9]{2}-[0-9]{2}' THEN
            TO_CHAR((r."sprint_date" || ' ' || SUBSTRING(r."sprint_time" FROM 1 FOR 8))::TIMESTAMP + INTERVAL '7 hours', 'HH24:MI:SS')
        ELSE NULL 
    END AS sprint_time_wib,
    CASE 
        WHEN r."sprint_time" IS NOT NULL AND r."sprint_time" ~ '^[0-9]{2}:[0-9]{2}:[0-9]{2}' AND r."sprint_date" ~ '^[0-9]{4}-[0-9]{2}-[0-9]{2}' THEN
            TO_CHAR((r."sprint_date" || ' ' || SUBSTRING(r."sprint_time" FROM 1 FOR 8))::TIMESTAMP + INTERVAL '7 hours', 'YYYY-MM-DD HH24:MI:SS')
        ELSE NULL 
    END AS sprint_datetime_wib,
    r."date" AS main_race_date,
    r."time" AS main_race_time_utc,
    CASE 
        WHEN r."time" IS NOT NULL AND r."time" ~ '^[0-9]{2}:[0-9]{2}:[0-9]{2}' AND r."date" ~ '^[0-9]{4}-[0-9]{2}-[0-9]{2}' THEN
            TO_CHAR((r."date" || ' ' || SUBSTRING(r."time" FROM 1 FOR 8))::TIMESTAMP + INTERVAL '7 hours', 'HH24:MI:SS')
        ELSE NULL 
    END AS main_race_time_wib,
    r."url" AS race_wiki_url
FROM public.races r
JOIN public.circuits c ON r."circuitId" = c."circuitId"
WHERE r."year" = 2023 
  AND r."sprint_date" IS NOT NULL AND r."sprint_date" != '' AND r."sprint_date" != '\N'
ORDER BY r."round" ASC;
-- Parameter Notes:
--   - r."year" = 2023  --> Target season year


-- ==============================================================================
-- SECTION 2: SEASON-BASED PARTICIPATION (CIRCUITS, DRIVERS, CONSTRUCTORS)
-- ==============================================================================

-- 2.1 All Circuits Used in a Specific Season (Includes Circuit & Race Wikipedia URLs)
SELECT DISTINCT
    r."year",
    r."round",
    r."name" AS grand_prix_name,
    c."circuitId",
    c."name" AS circuit_name,
    c."location",
    c."country",
    c."lat" AS latitude,
    c."lng" AS longitude,
    c."url" AS circuit_wiki_url,
    r."url" AS race_wiki_url
FROM public.races r
JOIN public.circuits c ON r."circuitId" = c."circuitId"
WHERE r."year" = 2023
ORDER BY r."round" ASC;
-- Parameter Notes:
--   - r."year" = 2023  --> F1 Season Year to filter circuits


-- 2.2 All Active Drivers Competing in a Specific Season (Includes Driver & Team Wikipedia URLs)
SELECT DISTINCT 
    r."year",
    d."driverId",
    d."number" AS permanent_number,
    d."code" AS driver_code,
    d."forename" || ' ' || d."surname" AS driver_name,
    d."dob" AS date_of_birth,
    d."nationality",
    c."name" AS current_team,
    d."url" AS driver_wiki_url,
    c."url" AS constructor_wiki_url
FROM public.results res
JOIN public.races r ON res."raceId" = r."raceId"
JOIN public.drivers d ON res."driverId" = d."driverId"
JOIN public.constructors c ON res."constructorId" = c."constructorId"
WHERE r."year" = 2023
ORDER BY driver_name ASC;
-- Parameter Notes:
--   - r."year" = 2023  --> F1 Season Year to filter drivers


-- 2.3 All Active Constructors / Teams Competing in a Specific Season (Includes Constructor Wikipedia URL)
SELECT DISTINCT
    r."year",
    c."constructorId",
    c."name" AS constructor_name,
    c."nationality" AS constructor_country,
    c."url" AS constructor_wiki_url
FROM public.results res
JOIN public.races r ON res."raceId" = r."raceId"
JOIN public.constructors c ON res."constructorId" = c."constructorId"
WHERE r."year" = 2023
ORDER BY constructor_name ASC;
-- Parameter Notes:
--   - r."year" = 2023  --> F1 Season Year to filter constructor teams


-- 2.4 Season Overview Summary: Total Races, Circuits, Drivers, and Teams (Grouped by Year)
SELECT 
    r."year",
    COUNT(DISTINCT r."raceId") AS total_races,
    COUNT(DISTINCT r."circuitId") AS total_circuits_used,
    COUNT(DISTINCT res."driverId") AS total_active_drivers,
    COUNT(DISTINCT res."constructorId") AS total_active_constructors
FROM public.races r
LEFT JOIN public.results res ON r."raceId" = res."raceId"
GROUP BY r."year"
ORDER BY r."year" DESC;
-- Parameter Notes:
--   - No parameter needed (automatically aggregates statistics by season year)


-- ==============================================================================
-- SECTION 3: RACE RESULTS, SPRINT, STANDINGS, & QUALIFYING
-- ==============================================================================

-- 3.1 Full Race Results for a Specific Grand Prix (Includes Wikipedia URLs)
SELECT 
    res."positionOrder" AS finish_position,
    res."grid" AS starting_grid,
    d."forename" || ' ' || d."surname" AS driver_name,
    c."name" AS team_name,
    res."laps" AS laps_completed,
    res."time" AS finish_time,
    res."points" AS points_earned,
    res."fastestLapTime",
    res."fastestLapSpeed",
    s."status" AS race_status,
    d."url" AS driver_wiki_url,
    c."url" AS constructor_wiki_url,
    r."url" AS race_wiki_url
FROM public.results res
JOIN public.races r ON res."raceId" = r."raceId"
JOIN public.drivers d ON res."driverId" = d."driverId"
JOIN public.constructors c ON res."constructorId" = c."constructorId"
JOIN public.status s ON res."statusId" = s."statusId"
WHERE r."year" = 2023 AND r."round" = 1
ORDER BY res."positionOrder" ASC;
-- Parameter Notes:
--   - r."year" = 2023   --> Target season year
--   - r."round" = 1     --> Grand Prix round number (e.g. 1 = Season Opener, 2 = Round 2)


-- 3.2 Sprint Race Results for a Specific Grand Prix (Includes Wikipedia URLs)
SELECT 
    sr."positionOrder" AS sprint_finish_position,
    sr."grid" AS sprint_starting_grid,
    d."forename" || ' ' || d."surname" AS driver_name,
    c."name" AS team_name,
    sr."laps" AS laps_completed,
    sr."time" AS sprint_time,
    sr."points" AS sprint_points_earned,
    s."status" AS sprint_status,
    d."url" AS driver_wiki_url,
    c."url" AS constructor_wiki_url
FROM public.sprint_results sr
JOIN public.races r ON sr."raceId" = r."raceId"
JOIN public.drivers d ON sr."driverId" = d."driverId"
JOIN public.constructors c ON sr."constructorId" = c."constructorId"
JOIN public.status s ON sr."statusId" = s."statusId"
WHERE r."year" = 2023 AND r."round" = 4
ORDER BY sr."positionOrder" ASC;
-- Parameter Notes:
--   - r."year" = 2023   --> Target season year
--   - r."round" = 4     --> Grand Prix round number with a Sprint event


-- 3.3 Combined Grand Prix Weekend Results (Main Race + Sprint + Total Weekend Points)
SELECT 
    r."positionOrder" AS main_race_position,
    d."forename" || ' ' || d."surname" AS driver_name,
    c."name" AS team_name,
    r."points" AS main_race_points,
    COALESCE(sr."positionOrder", NULL) AS sprint_position,
    COALESCE(sr."points", 0) AS sprint_points,
    (r."points" + COALESCE(sr."points", 0)) AS total_weekend_points,
    d."url" AS driver_wiki_url,
    c."url" AS constructor_wiki_url
FROM public.results r
JOIN public.races rc ON r."raceId" = rc."raceId"
JOIN public.drivers d ON r."driverId" = d."driverId"
JOIN public.constructors c ON r."constructorId" = c."constructorId"
LEFT JOIN public.sprint_results sr ON (r."raceId" = sr."raceId" AND r."driverId" = sr."driverId")
WHERE rc."year" = 2023 AND rc."round" = 4
ORDER BY total_weekend_points DESC, r."positionOrder" ASC;
-- Parameter Notes:
--   - rc."year" = 2023  --> Target season year
--   - rc."round" = 4    --> Grand Prix round number


-- 3.4 Full Qualifying Session Breakdown (Q1, Q2, Q3 Times)
SELECT 
    q."position" AS quali_rank,
    d."forename" || ' ' || d."surname" AS driver_name,
    c."name" AS team_name,
    q."q1" AS q1_time,
    q."q2" AS q2_time,
    q."q3" AS q3_time,
    d."url" AS driver_wiki_url,
    c."url" AS constructor_wiki_url
FROM public.qualifying q
JOIN public.races r ON q."raceId" = r."raceId"
JOIN public.drivers d ON q."driverId" = d."driverId"
JOIN public.constructors c ON q."constructorId" = c."constructorId"
WHERE r."year" = 2023 AND r."round" = 1
ORDER BY q."position" ASC;
-- Parameter Notes:
--   - r."year" = 2023   --> Target season year
--   - r."round" = 1     --> Grand Prix round number


-- 3.5 Season Race Winners (Includes Race, Driver & Constructor Wikipedia URLs)
SELECT 
    r."round",
    r."name" AS grand_prix,
    r."date",
    d."forename" || ' ' || d."surname" AS winner_name,
    c."name" AS winning_team,
    res."time" AS winning_time,
    r."url" AS race_wiki_url,
    d."url" AS driver_wiki_url,
    c."url" AS constructor_wiki_url
FROM public.results res
JOIN public.races r ON res."raceId" = r."raceId"
JOIN public.drivers d ON res."driverId" = d."driverId"
JOIN public.constructors c ON res."constructorId" = c."constructorId"
WHERE r."year" = 2023 AND res."positionOrder" = 1
ORDER BY r."round" ASC;
-- Parameter Notes:
--   - r."year" = 2023   --> Target season year to list all race winners


-- 3.6 Latest Driver Standings (Dynamic: Automatically takes the most recent race)
SELECT 
    lr."year" AS season,
    lr."round" AS after_round,
    lr."race_name" AS after_grand_prix,
    ds."position" AS championship_rank,
    d."code" AS driver_code,
    d."forename" || ' ' || d."surname" AS driver_name,
    d."nationality",
    COALESCE(c."name", 'Unknown') AS team_name,
    ds."points" AS total_points,
    ds."wins" AS total_wins,
    d."url" AS driver_wiki_url,
    c."url" AS constructor_wiki_url
FROM public.driver_standings ds
JOIN (
    SELECT r."raceId", r."year", r."round", r."name" AS race_name, r."date"
    FROM public.races r
    JOIN public.driver_standings ds ON r."raceId" = ds."raceId"
    ORDER BY r."date" DESC, r."round" DESC
    LIMIT 1
) lr ON ds."raceId" = lr."raceId"
JOIN public.drivers d ON ds."driverId" = d."driverId"
LEFT JOIN LATERAL (
    SELECT c."name", c."url"
    FROM public.results res
    JOIN public.constructors c ON res."constructorId" = c."constructorId"
    JOIN public.races r ON res."raceId" = r."raceId"
    WHERE res."driverId" = ds."driverId" AND r."year" = lr."year" AND r."round" <= lr."round"
    ORDER BY r."round" DESC
    LIMIT 1
) c ON true
ORDER BY ds."position" ASC;
-- Parameter Notes:
--   - No parameter needed (automatically detects the latest race recorded in the database)


-- 3.7 Latest Constructor Standings (Dynamic: Automatically takes the most recent race)
SELECT 
    lr."year" AS season,
    lr."round" AS after_round,
    lr."race_name" AS after_grand_prix,
    cs."position" AS championship_rank,
    c."name" AS constructor_name,
    c."nationality",
    cs."points" AS total_points,
    cs."wins" AS total_wins,
    c."url" AS constructor_wiki_url
FROM public.constructor_standings cs
JOIN (
    SELECT r."raceId", r."year", r."round", r."name" AS race_name, r."date"
    FROM public.races r
    JOIN public.constructor_standings cs ON r."raceId" = cs."raceId"
    ORDER BY r."date" DESC, r."round" DESC
    LIMIT 1
) lr ON cs."raceId" = lr."raceId"
JOIN public.constructors c ON cs."constructorId" = c."constructorId"
ORDER BY cs."position" ASC;
-- Parameter Notes:
--   - No parameter needed (automatically detects the latest race recorded in the database)


-- 3.8 Driver Championship Final / Latest Standings per Specific Season
SELECT 
    r."year" AS season,
    r."round" AS after_round,
    r."name" AS after_grand_prix,
    ds."position" AS championship_rank,
    d."code" AS driver_code,
    d."forename" || ' ' || d."surname" AS driver_name,
    d."nationality",
    COALESCE(c."name", 'Unknown') AS team_name,
    ds."points" AS total_points,
    ds."wins" AS total_wins,
    d."url" AS driver_wiki_url,
    c."url" AS constructor_wiki_url
FROM public.driver_standings ds
JOIN public.races r ON ds."raceId" = r."raceId"
JOIN public.drivers d ON ds."driverId" = d."driverId"
LEFT JOIN LATERAL (
    SELECT c."name", c."url"
    FROM public.results res
    JOIN public.constructors c ON res."constructorId" = c."constructorId"
    JOIN public.races r2 ON res."raceId" = r2."raceId"
    WHERE res."driverId" = ds."driverId" AND r2."year" = r."year" AND r2."round" <= r."round"
    ORDER BY r2."round" DESC
    LIMIT 1
) c ON true
WHERE r."year" = 2023 
  AND r."round" = (
      SELECT MAX(r2."round") 
      FROM public.races r2 
      JOIN public.driver_standings ds2 ON r2."raceId" = ds2."raceId" 
      WHERE r2."year" = 2023
  )
ORDER BY ds."position" ASC;
-- Parameter Notes:
--   - r."year" = 2023   --> Target season year for driver championship standings


-- 3.9 Constructor Championship Final / Latest Standings per Specific Season
SELECT 
    r."year" AS season,
    r."round" AS after_round,
    r."name" AS after_grand_prix,
    cs."position" AS championship_rank,
    c."name" AS constructor_name,
    c."nationality",
    cs."points" AS total_points,
    cs."wins" AS total_wins,
    c."url" AS constructor_wiki_url
FROM public.constructor_standings cs
JOIN public.races r ON cs."raceId" = r."raceId"
JOIN public.constructors c ON cs."constructorId" = c."constructorId"
WHERE r."year" = 2023 
  AND r."round" = (
      SELECT MAX(r2."round") 
      FROM public.races r2 
      JOIN public.constructor_standings cs2 ON r2."raceId" = cs2."raceId" 
      WHERE r2."year" = 2023
  )
ORDER BY cs."position" ASC;
-- Parameter Notes:
--   - r."year" = 2023   --> Target season year for constructor championship standings


-- 3.10 Pole Position Holders (Qualifying P1) per Race
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
WHERE r."year" = 2023 AND q."position" = 1
ORDER BY r."round" ASC;
-- Parameter Notes:
--   - r."year" = 2023   --> Target season year for pole position winners


-- 3.11 Official Starting Grid for a Specific Grand Prix (Incorporating Penalties & Pit Lane Starts)
SELECT 
    CASE 
        WHEN r."grid" = 0 THEN 'PL' 
        ELSE CAST(r."grid" AS TEXT) 
    END AS starting_grid_position,
    d."number" AS car_number,
    d."code" AS driver_code,
    d."forename" || ' ' || d."surname" AS driver_name,
    c."name" AS team_name,
    q."position" AS qualifying_position,
    COALESCE(q."q3", q."q2", q."q1") AS qualifying_best_lap,
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
WHERE rc."year" = 2023 AND rc."raceId" = 1100
ORDER BY (CASE WHEN r."grid" = 0 THEN 999 ELSE r."grid" END) ASC;
-- Parameter Notes:
--   - rc."year" = 2023    --> Target season year
--   - rc."raceId" = 1100  --> Target Grand Prix Race ID (e.g., 1100 = 2023 Monaco GP, or filter by rc."round" = 6)


-- ==============================================================================
-- SECTION 4: ADVANCED STRATEGY & PERFORMANCE ANALYTICS
-- ==============================================================================

-- 4.1 Biggest Movers / Greatest Comebacks (Grid vs Finish Positions Gained)
SELECT 
    rc."year",
    rc."name" AS grand_prix,
    d."forename" || ' ' || d."surname" AS driver_name,
    c."name" AS team_name,
    r."grid" AS starting_grid,
    r."positionOrder" AS finish_position,
    (r."grid" - r."positionOrder") AS positions_gained,
    d."url" AS driver_wiki_url,
    rc."url" AS race_wiki_url
FROM public.results r
JOIN public.races rc ON r."raceId" = rc."raceId"
JOIN public.drivers d ON r."driverId" = d."driverId"
JOIN public.constructors c ON r."constructorId" = c."constructorId"
WHERE r."grid" > 0 AND r."positionOrder" > 0 
  AND rc."year" = 2023
ORDER BY positions_gained DESC
LIMIT 10;
-- Parameter Notes:
--   - rc."year" = 2023  --> Target season year
--   - LIMIT 10          --> Number of top biggest movers to return


-- 4.2 Pit Stop Efficiency & Average Duration by Constructor
SELECT 
    c."name" AS team_name,
    COUNT(ps."stop") AS total_pit_stops,
    ROUND(AVG(CAST(ps."duration" AS NUMERIC)), 2) AS avg_duration_seconds,
    MIN(CAST(ps."duration" AS NUMERIC)) AS fastest_stop_seconds,
    c."url" AS constructor_wiki_url
FROM public.pit_stops ps
JOIN public.races rc ON ps."raceId" = rc."raceId"
JOIN public.results r ON (r."raceId" = ps."raceId" AND r."driverId" = ps."driverId")
JOIN public.constructors c ON r."constructorId" = c."constructorId"
WHERE rc."year" = 2023 
  AND ps."duration" ~ '^[0-9]+(\.[0-9]+)?$'
GROUP BY c."name", c."url"
ORDER BY avg_duration_seconds ASC;
-- Parameter Notes:
--   - rc."year" = 2023  --> Target season year to analyze pit stop averages


-- 4.3 Pole-to-Win Conversion Rate (% of Pole Sitters Winning the Race)
SELECT 
    rc."year",
    COUNT(*) AS total_races,
    COUNT(CASE WHEN r."positionOrder" = 1 THEN 1 END) AS pole_and_won_count,
    ROUND(
        COUNT(CASE WHEN r."positionOrder" = 1 THEN 1 END) * 100.0 / COUNT(*), 
        2
    ) AS pole_to_win_percentage
FROM public.results r
JOIN public.races rc ON r."raceId" = rc."raceId"
WHERE r."grid" = 1 
  AND rc."year" >= 2015
GROUP BY rc."year"
ORDER BY rc."year" DESC;
-- Parameter Notes:
--   - rc."year" >= 2015 --> Starting era year to analyze


-- 4.4 Most Incident-Prone & High-DNF Circuits (Did Not Finish Analysis)
SELECT 
    c."name" AS circuit_name,
    c."country",
    COUNT(r."resultId") AS total_dnf_incidents,
    c."url" AS circuit_wiki_url
FROM public.results r
JOIN public.races rc ON r."raceId" = rc."raceId"
JOIN public.circuits c ON rc."circuitId" = c."circuitId"
JOIN public.status s ON r."statusId" = s."statusId"
WHERE s."status" NOT IN ('Finished', '+1 Lap', '+2 Laps', '+3 Laps', '+4 Laps', '+5 Laps', '+6 Laps')
GROUP BY c."name", c."country", c."url"
ORDER BY total_dnf_incidents DESC
LIMIT 10;
-- Parameter Notes:
--   - LIMIT 10          --> Number of highest-DNF circuits to display


-- 4.5 Historical Wins from the Deepest Starting Grid Positions (Comeback Champions)
SELECT 
    rc."year",
    rc."name" AS grand_prix,
    d."forename" || ' ' || d."surname" AS driver_name,
    c."name" AS team_name,
    r."grid" AS starting_grid_position,
    d."url" AS driver_wiki_url,
    rc."url" AS race_wiki_url
FROM public.results r
JOIN public.races rc ON r."raceId" = rc."raceId"
JOIN public.drivers d ON r."driverId" = d."driverId"
JOIN public.constructors c ON r."constructorId" = c."constructorId"
WHERE r."positionOrder" = 1 
  AND r."grid" > 10
ORDER BY r."grid" DESC
LIMIT 10;
-- Parameter Notes:
--   - r."grid" > 10     --> Filter for wins from starting grid P10 or worse
--   - LIMIT 10          --> Number of records to return


-- 4.6 Drivers with Most Laps Led in P1 (All-Time Race Leaders)
SELECT 
    d."forename" || ' ' || d."surname" AS driver_name,
    COUNT(lt."lap") AS total_laps_led,
    d."url" AS driver_wiki_url
FROM public.lap_times lt
JOIN public.drivers d ON lt."driverId" = d."driverId"
WHERE lt."position" = 1
GROUP BY d."driverId", d."forename", d."surname", d."url"
ORDER BY total_laps_led DESC
LIMIT 15;
-- Parameter Notes:
--   - LIMIT 15          --> Number of top all-time race leaders to return


-- 4.7 Fastest Race Speed Recorded in History
SELECT 
    rc."year",
    rc."name" AS grand_prix,
    c."name" AS circuit_name,
    d."forename" || ' ' || d."surname" AS driver_name,
    r."fastestLapSpeed" AS max_speed_kmh,
    r."fastestLapTime",
    d."url" AS driver_wiki_url,
    c."url" AS circuit_wiki_url
FROM public.results r
JOIN public.races rc ON r."raceId" = rc."raceId"
JOIN public.circuits c ON rc."circuitId" = c."circuitId"
JOIN public.drivers d ON r."driverId" = d."driverId"
WHERE r."fastestLapSpeed" IS NOT NULL
ORDER BY r."fastestLapSpeed" DESC
LIMIT 10;
-- Parameter Notes:
--   - LIMIT 10          --> Number of fastest speed records to return


-- 4.8 All-Time Grand Prix Race Winners (Hall of Fame)
SELECT 
    d."forename" || ' ' || d."surname" AS driver_name,
    d."nationality",
    COUNT(*) AS total_race_wins,
    d."url" AS driver_wiki_url
FROM public.results res
JOIN public.drivers d ON res."driverId" = d."driverId"
WHERE res."positionOrder" = 1
GROUP BY d."driverId", d."forename", d."surname", d."nationality", d."url"
ORDER BY total_race_wins DESC
LIMIT 15;
-- Parameter Notes:
--   - LIMIT 15          --> Number of top all-time winners to display


-- 4.9 Teammate Head-to-Head Qualifying Battle (Who Outqualified Whom in Season)
WITH team_quali AS (
    SELECT 
        rc."year",
        q."raceId",
        c."name" AS team_name,
        q."driverId",
        d."forename" || ' ' || d."surname" AS driver_name,
        q."position" AS quali_pos,
        ROW_NUMBER() OVER (PARTITION BY q."raceId", q."constructorId" ORDER BY q."position" ASC) AS team_rank
    FROM public.qualifying q
    JOIN public.races rc ON q."raceId" = rc."raceId"
    JOIN public.drivers d ON q."driverId" = d."driverId"
    JOIN public.constructors c ON q."constructorId" = c."constructorId"
    WHERE rc."year" = 2023
)
SELECT 
    team_name,
    driver_name,
    COUNT(CASE WHEN team_rank = 1 THEN 1 END) AS outqualified_teammate_count,
    COUNT(*) AS total_sessions_entered
FROM team_quali
GROUP BY team_name, driver_name
ORDER BY team_name ASC, outqualified_teammate_count DESC;
-- Parameter Notes:
--   - rc."year" = 2023  --> Target season year to analyze teammate qualifying head-to-head


-- 4.10 Lap-by-Lap Race Progression & Position Tracking (Lap Chart Data)
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
WHERE rc."year" = 2023 AND rc."round" = 1
ORDER BY lt."lap" ASC, lt."position" ASC;
-- Parameter Notes:
--   - rc."year" = 2023   --> Target season year
--   - rc."round" = 1     --> Grand Prix round number to plot the lap chart


-- 4.11 Driver Rolling Form (Last 5 Races Moving Average Points)
WITH driver_races AS (
    SELECT 
        rc."year",
        rc."round",
        rc."name" AS grand_prix,
        d."forename" || ' ' || d."surname" AS driver_name,
        r."points",
        AVG(r."points") OVER (
            PARTITION BY r."driverId" 
            ORDER BY rc."date", rc."round" 
            ROWS BETWEEN 4 PRECEDING AND CURRENT ROW
        ) AS rolling_avg_points_5_races
    FROM public.results r
    JOIN public.races rc ON r."raceId" = rc."raceId"
    JOIN public.drivers d ON r."driverId" = d."driverId"
    WHERE rc."year" = 2023
)
SELECT * FROM driver_races 
ORDER BY "round" ASC, rolling_avg_points_5_races DESC;
-- Parameter Notes:
--   - rc."year" = 2023  --> Target season year to calculate rolling average form


-- 4.12 Cumulative Points Progression Across Season (Championship Trajectory)
SELECT 
    rc."round",
    rc."name" AS grand_prix,
    d."forename" || ' ' || d."surname" AS driver_name,
    r."points" AS race_points,
    SUM(r."points") OVER (
        PARTITION BY r."driverId" 
        ORDER BY rc."round" ASC
    ) AS cumulative_season_points
FROM public.results r
JOIN public.races rc ON r."raceId" = rc."raceId"
JOIN public.drivers d ON r."driverId" = d."driverId"
WHERE rc."year" = 2023
ORDER BY rc."round" ASC, cumulative_season_points DESC;
-- Parameter Notes:
--   - rc."year" = 2023  --> Target season year for points accumulation


-- 4.13 Constructor 1-2 Finishes in a Season (Team Dominance)
WITH team_top_two AS (
    SELECT 
        rc."year",
        rc."round",
        rc."name" AS grand_prix,
        c."name" AS team_name,
        COUNT(CASE WHEN r."positionOrder" IN (1, 2) THEN 1 END) AS top_2_count
    FROM public.results r
    JOIN public.races rc ON r."raceId" = rc."raceId"
    JOIN public.constructors c ON r."constructorId" = c."constructorId"
    GROUP BY rc."year", rc."round", rc."name", c."name"
    HAVING COUNT(CASE WHEN r."positionOrder" IN (1, 2) THEN 1 END) = 2
)
SELECT 
    team_name,
    "year",
    COUNT(*) AS total_one_two_finishes
FROM team_top_two
GROUP BY team_name, "year"
ORDER BY total_one_two_finishes DESC;
-- Parameter Notes:
--   - No parameter needed (automatically calculates all 1-2 finishes across teams and years)


-- 4.14 Youngest Race Winners in F1 History (Includes Driver & Race Wikipedia URLs)
SELECT 
    d."forename" || ' ' || d."surname" AS driver_name,
    d."dob" AS birth_date,
    rc."date" AS race_date,
    rc."name" AS grand_prix,
    rc."year",
    DATE_PART('year', AGE(TO_DATE(rc."date", 'YYYY-MM-DD'), TO_DATE(d."dob", 'YYYY-MM-DD'))) AS age_years,
    DATE_PART('month', AGE(TO_DATE(rc."date", 'YYYY-MM-DD'), TO_DATE(d."dob", 'YYYY-MM-DD'))) AS age_months,
    DATE_PART('day', AGE(TO_DATE(rc."date", 'YYYY-MM-DD'), TO_DATE(d."dob", 'YYYY-MM-DD'))) AS age_days,
    d."url" AS driver_wiki_url,
    rc."url" AS race_wiki_url
FROM public.results r
JOIN public.races rc ON r."raceId" = rc."raceId"
JOIN public.drivers d ON r."driverId" = d."driverId"
WHERE r."positionOrder" = 1 
  AND rc."date" IS NOT NULL AND rc."date" != '' 
  AND d."dob" IS NOT NULL AND d."dob" != ''
ORDER BY AGE(TO_DATE(rc."date", 'YYYY-MM-DD'), TO_DATE(d."dob", 'YYYY-MM-DD')) ASC
LIMIT 10;
-- Parameter Notes:
--   - LIMIT 10          --> Number of youngest winners to return


-- 4.15 King of the Circuit (Drivers with Most Wins at a Specific Track)
SELECT 
    c."name" AS circuit_name,
    c."country",
    d."forename" || ' ' || d."surname" AS driver_name,
    COUNT(*) AS total_wins_at_circuit,
    c."url" AS circuit_wiki_url,
    d."url" AS driver_wiki_url
FROM public.results r
JOIN public.races rc ON r."raceId" = rc."raceId"
JOIN public.circuits c ON rc."circuitId" = c."circuitId"
JOIN public.drivers d ON r."driverId" = d."driverId"
WHERE r."positionOrder" = 1
GROUP BY c."circuitId", c."name", c."country", c."url", d."driverId", d."forename", d."surname", d."url"
ORDER BY total_wins_at_circuit DESC
LIMIT 15;
-- Parameter Notes:
--   - LIMIT 15          --> Number of circuit mastery records to return
