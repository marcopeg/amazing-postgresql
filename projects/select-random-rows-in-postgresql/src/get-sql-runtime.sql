-- I proposed the following function in:
-- https://stackoverflow.com/questions/3160426/statistics-on-query-time-postgresql

CREATE OR REPLACE FUNCTION "get_sql_runtime"(
  PAR_sql TEXT
, OUT sql_runtime REAL
)
AS $$
DECLARE
  run_sql TEXT;
  run_time_start TIMESTAMP WITH TIME ZONE;
  run_time_end TIMESTAMP WITH TIME ZONE;
BEGIN
  -- Hanldes both straight queries or prepared statements:
  -- https://github.com/theory/pgtap/blob/master/sql/pgtap.sql.in#L648
  SELECT CASE
    WHEN PAR_sql LIKE '"%' OR PAR_sql !~ '[[:space:]]' THEN 'EXECUTE ' || PAR_sql
    ELSE PAR_sql
  END INTO run_sql;

  -- Sandwich the execution of the query into timestamps:
  SELECT clock_timestamp() INTO run_time_start;
  EXECUTE run_sql;
  SELECT clock_timestamp() INTO run_time_end;

  -- Return the time difference:
  SELECT EXTRACT(EPOCH FROM (run_time_end - run_time_start)) INTO sql_runtime;
END; $$
LANGUAGE plpgsql
VOLATILE;
