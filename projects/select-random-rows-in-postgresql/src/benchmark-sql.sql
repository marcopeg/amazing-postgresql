DROP FUNCTION IF EXISTS benchmark_sql (TEXT, INT);
CREATE OR REPLACE FUNCTION benchmark_sql (
  PAR_sql TEXT
, PAR_rep INT
, OUT min_duration REAL
, OUT max_duration REAL
, OUT avg_duration REAL
, OUT tot_duration REAL
, OUT time_start TIMESTAMP WITH TIME ZONE
, OUT time_end TIMESTAMP WITH TIME ZONE
, OUT executions INT
, OUT results JSON
)
AS $$
DECLARE
  run_sql TEXT;
  run_duration REAL;
  run_time_start TIMESTAMP WITH TIME ZONE;
  run_time_end TIMESTAMP WITH TIME ZONE;
BEGIN

  -- Collect each execution results
  CREATE TEMP TABLE "temp_results" (
    "duration" REAL
  , "time_start" TIMESTAMP WITH TIME ZONE
  , "time_end" TIMESTAMP WITH TIME ZONE
  ) ON COMMIT DROP;

  -- Hanldes both straight queries or prepared statements:
  -- https://github.com/theory/pgtap/blob/master/sql/pgtap.sql.in#L648
  SELECT CASE
    WHEN PAR_sql LIKE '"%' OR PAR_sql !~ '[[:space:]]' THEN 'EXECUTE ' || PAR_sql
    ELSE PAR_sql
  END INTO run_sql;

  -- Run the tests
  SELECT clock_timestamp() INTO time_start;
  FOR i IN 1..PAR_rep LOOP
    -- Execute the statement tracking time before/after:
    SELECT clock_timestamp() INTO run_time_start;
    EXECUTE run_sql;
    SELECT clock_timestamp() INTO run_time_end;

    -- Calculate the time difference as duration:
    SELECT EXTRACT(EPOCH FROM (run_time_end - run_time_start)) INTO run_duration;

    -- Queue the results:
    INSERT INTO "temp_results"
    VALUES ( run_duration, run_time_start, run_time_end );
  END LOOP;
  SELECT clock_timestamp() INTO time_end;
  
  -- Compose the test report:
  SELECT EXTRACT(EPOCH FROM (time_end - time_start)) INTO tot_duration;
  SELECT COUNT(*) INTO executions FROM "temp_results";
  SELECT json_agg(t.*) INTO results FROM "temp_results" AS "t";
  SELECT max("t"."duration") INTO max_duration FROM "temp_results" AS "t";
  SELECT min("t"."duration") INTO min_duration FROM "temp_results" AS "t";
  SELECT avg("t"."duration") INTO avg_duration FROM "temp_results" AS "t";

  -- Cleanup:
  DROP TABLE "temp_results";
END; $$
LANGUAGE plpgsql
VOLATILE;
