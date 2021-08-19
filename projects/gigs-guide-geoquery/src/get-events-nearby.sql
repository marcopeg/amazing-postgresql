-- Get data from a cache table
-- Fallback on geoquery + active caching
CREATE OR REPLACE FUNCTION "get_events_nearby"(
  PAR_city TEXT
, PAR_distance INTEGER
, PAR_cacheDistance INTEGER
) 
RETURNS SETOF "cached_distances"
AS $$
DECLARE
  VAR_r RECORD;
BEGIN
  -- Populate a temporary table with the cached results:
  CREATE TEMP TABLE "cached_rows" ON COMMIT DROP AS
  SELECT * FROM "cached_distances"
    WHERE "city" = PAR_city
      AND "distance" < PAR_distance;

  -- Evaluate and return the cached results if exist:
  SELECT 1 INTO VAR_r FROM "cached_rows";
  IF FOUND THEN
    RETURN QUERY
    SELECT * FROM "cached_rows";
  ELSE

    -- Evaluate if the query has already been cached
    SELECT 1 INTO VAR_r FROM "cached_queries" WHERE "city" = PAR_city;
    IF FOUND THEN
      RETURN QUERY
      SELECT * FROM "cached_rows";
    ELSE

      -- Run the geolocation
      RETURN QUERY
      WITH
        "cached_distances" AS (
          INSERT INTO "cached_distances"
          SELECT * FROM (
            SELECT
              "c"."wandercity_id" AS "city_id"
            , "e"."event_id"
            , "c"."name" AS "city"
            , ST_DistanceSphere(e.location::Geometry, c.location::Geometry)::int as "distance"
            FROM
              "cities" "c"
            , "all_music_events_temp" "e"
            WHERE
              "c"."name" = PAR_city
          ) AS "source"
          WHERE "distance" < PAR_cacheDistance
          ON CONFLICT ON CONSTRAINT "cached_distances_pkey" DO NOTHING
          RETURNING *
        )
      , "cached_queries" AS (
        INSERT INTO "cached_queries"
        VALUES (PAR_city)
        ON CONFLICT ON CONSTRAINT "cached_queries_pkey" DO NOTHING
      )
      SELECT * FROM "cached_distances"
      WHERE "distance" < PAR_distance;
      -- End of the caching query

    END IF;
  END IF;
END; $$
LANGUAGE plpgsql
VOLATILE;

-- Blocked cache radius
CREATE OR REPLACE FUNCTION "get_events_nearby"(
  PAR_city TEXT
, PAR_distance INTEGER
) 
RETURNS SETOF "cached_distances"
AS $$
BEGIN
  RETURN QUERY
  SELECT * FROM "get_events_nearby"(PAR_city, PAR_distance, 100000);
END; $$
LANGUAGE plpgsql
VOLATILE;

-- Blocked radius and cache radius
CREATE OR REPLACE FUNCTION "get_events_nearby"(
  PAR_city TEXT
) 
RETURNS SETOF "cached_distances"
AS $$
BEGIN
  RETURN QUERY
  SELECT * FROM "get_events_nearby"(PAR_city, 25000, 100000);
END; $$
LANGUAGE plpgsql
VOLATILE;