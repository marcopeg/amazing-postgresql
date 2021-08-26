
-- Generate seeding settings into a temporary table
CREATE TEMPORARY TABLE "run_settings" ("doc" JSONB);
INSERT INTO "run_settings" VALUES ('{
  "rows_counts_idx_min": 13,
  "rows_counts_idx_max": 17,
  "rows_counts": [
    1000

  , 10000
  , 25000
  , 50000
  , 75000
  , 100000

  , 250000
  , 500000
  , 750000
  , 1000000
  , 2500000

  , 5000000
  , 7500000
  , 10000000
  , 20000000
  , 30000000
  , 40000000
  , 50000000
  ],
  "repeat_tests": 25
}'::jsonb);

-- Reset tests results
DROP TABLE IF EXISTS "test_results";
CREATE TABLE IF NOT EXISTS "test_results" (
  "test_name" TEXT
, "rows_counts" INT
, "avg_duration" REAL
);


CREATE OR REPLACE FUNCTION "test_offset_method"(
  OUT ok BOOLEAN
)
AS $$
DECLARE
  rows_counts_idx_min INT = 0;
  rows_counts_idx_max INT = 1;
  rows_counts INT = 1;
  repeat_tests INT = 1;
  max_offset INT = 1;
BEGIN
  -- Get test settings
  SELECT ("doc"->'rows_counts_idx_min')::INT INTO rows_counts_idx_min FROM "run_settings";
  SELECT ("doc"->'rows_counts_idx_max')::INT INTO rows_counts_idx_max FROM "run_settings";
  SELECT ("doc"->'repeat_tests')::INT INTO repeat_tests FROM "run_settings";
  SELECT ("doc"->'rows_counts'->rows_counts_idx_max)::INT INTO rows_counts FROM "run_settings";

  -- Insert the max amount of rows that is needed for this test:
  raise notice 'test_offset_method: generating % rows', rows_counts; 
  TRUNCATE "users_with_ids" RESTART IDENTITY;
  INSERT INTO "users_with_ids" ("uname")
  SELECT CONCAT('u', "gs1")
  FROM generate_series(1, rows_counts) "gs1";

  -- Run the test on multiple offsets
  FOR i IN rows_counts_idx_min..rows_counts_idx_max LOOP
    -- calculate the offset that we want to achieve
    SELECT ("doc"->'rows_counts'->i)::INT INTO max_offset FROM "run_settings";
    raise notice '[offset] with offset: %', max_offset; 
  
    -- run the benchmark and log the result
    INSERT INTO "test_results"
    SELECT
      'offset' AS "test_name"
    , max_offset
    , "avg_duration" 
    FROM benchmark_sql(FORMAT(
      'SELECT * FROM "users_with_ids" OFFSET %s LIMIT 1',
      max_offset
    ), repeat_tests);
  END LOOP;
  ok = true;
END; $$
LANGUAGE plpgsql
VOLATILE;




CREATE OR REPLACE FUNCTION "test_order_by_random_method"(
  OUT ok BOOLEAN
)
AS $$
DECLARE
  rows_counts_idx_min INT = 0;
  rows_counts_idx_max INT = 1;
  rows_counts INT = 1;
  repeat_tests INT = 1;
  max_offset INT = 1;
BEGIN
  -- Get test settings
  SELECT ("doc"->'rows_counts_idx_min')::INT INTO rows_counts_idx_min FROM "run_settings";
  SELECT ("doc"->'rows_counts_idx_max')::INT INTO rows_counts_idx_max FROM "run_settings";
  SELECT ("doc"->'repeat_tests')::INT INTO repeat_tests FROM "run_settings";
  SELECT ("doc"->'rows_counts'->rows_counts_idx_max)::INT INTO rows_counts FROM "run_settings";

  FOR i IN rows_counts_idx_min..rows_counts_idx_max LOOP
    -- calculate the number of rows on which we want to run the test
    SELECT ("doc"->'rows_counts'->i)::INT INTO rows_counts FROM "run_settings";
    
    raise notice '[order_by_random] generating % rows', rows_counts; 
    TRUNCATE "users_with_ids" RESTART IDENTITY;
    INSERT INTO "users_with_ids" ("uname")
    SELECT CONCAT('u', "gs1")
    FROM generate_series(1, rows_counts) "gs1";
  
    -- run the benchmark and log the result
    raise notice '[order_by_random] running query on % rows', rows_counts; 
    INSERT INTO "test_results"
    SELECT
      'order_by_random' AS "test_name"
    , rows_counts
    , "avg_duration" 
    FROM benchmark_sql('SELECT * FROM "users_with_ids" ORDER BY random() LIMIT 1;', repeat_tests);
  END LOOP;
  ok = true;
END; $$
LANGUAGE plpgsql
VOLATILE;





CREATE OR REPLACE FUNCTION "test_random_ids_method"(
  OUT ok BOOLEAN
)
AS $$
DECLARE
  rows_counts_idx_min INT = 0;
  rows_counts_idx_max INT = 1;
  rows_counts INT = 1;
  repeat_tests INT = 1;
  max_offset INT = 1;
BEGIN
  -- Get test settings
  SELECT ("doc"->'rows_counts_idx_min')::INT INTO rows_counts_idx_min FROM "run_settings";
  SELECT ("doc"->'rows_counts_idx_max')::INT INTO rows_counts_idx_max FROM "run_settings";
  SELECT ("doc"->'repeat_tests')::INT INTO repeat_tests FROM "run_settings";
  SELECT ("doc"->'rows_counts'->rows_counts_idx_max)::INT INTO rows_counts FROM "run_settings";

  FOR i IN rows_counts_idx_min..rows_counts_idx_max LOOP
    -- calculate the offset that we want to achieve
    SELECT ("doc"->'rows_counts'->i)::INT INTO rows_counts FROM "run_settings";

    raise notice '[random_ids] generating % rows', rows_counts; 
    TRUNCATE "users_with_ids" RESTART IDENTITY;
    INSERT INTO "users_with_ids" ("uname")
    SELECT CONCAT('u', "gs1")
    FROM generate_series(1, rows_counts) "gs1";
  
    -- run the benchmark and log the result
    raise notice '[random_ids] running query on % rows', rows_counts; 
    INSERT INTO "test_results"
    SELECT
      'random_ids' AS "test_name"
    , rows_counts
    , "avg_duration" 
    FROM benchmark_sql(FORMAT('
      SELECT * FROM
        (
          SELECT (0 + trunc(random() * %s)) AS "user_id"
          FROM generate_series(1, 1)
          GROUP BY "user_id"
        ) AS "gs1"
      JOIN "users_with_ids" USING ("user_id")
      LIMIT 1;
    ', rows_counts), repeat_tests);
  END LOOP;
  ok = true;
END; $$
LANGUAGE plpgsql
VOLATILE;


-- SELECT test_offset_method();
-- SELECT test_order_by_random_method();
SELECT test_random_ids_method();



SELECT * FROM ( SELECT (0 + trunc(random() * 50000000)) AS "user_id" FROM generate_series(1, 1) GROUP BY "user_id" ) AS "gs1" JOIN "users_with_ids" USING ("user_id") LIMIT 1;


select * from "users_with_ids" 
where "user_id" in (
  SELECT (0 + trunc(random() * 50000000)) AS "user_id" 
  FROM generate_series(1, 1)
  GROUP BY "user_id"
)
limit 1;

select * from "users_with_ids" 
where "user_id" in (
  SELECT (0 + trunc(random() * 50000000)) AS "user_id" 
)
limit 1;

select * from "users_with_ids" 
where "user_id" in (
  29941252
)
limit 1;





-- SELECT test_offset_method();

-- PREPARE "random_offset_10000" AS
-- SELECT * FROM "users_with_ids" OFFSET 10000 LIMIT 1;

-- PREPARE "random_offset_100000" AS
-- SELECT * FROM "users_with_ids" OFFSET 100000 LIMIT 1;

-- PREPARE "random_offset_500000" AS
-- SELECT * FROM "users_with_ids" OFFSET 500000 LIMIT 1;


-- INSERT INTO "test_results"
-- SELECT
--   'random_offset_10000' AS "test_name"
-- , "avg_duration" 
-- FROM benchmark_sql('random_offset_10000', 100)
-- RETURNING *;

-- INSERT INTO "test_results"
-- SELECT
--   'random_offset_100000' AS "test_name"
-- , "avg_duration" 
-- FROM benchmark_sql('random_offset_100000', 100)
-- RETURNING *;

-- INSERT INTO "test_results"
-- SELECT
--   'random_offset_500000' AS "test_name"
-- , "avg_duration" 
-- FROM benchmark_sql('random_offset_500000', 100)
-- RETURNING *;

-- PREPARE "select_by_random" AS
-- SELECT * FROM "users_with_ids"
-- ORDER BY random()
-- LIMIT 10;

-- -- PREPARE "select_randomized_with_static_info" AS
-- SELECT
--   "user_id"
--   -- , "uname"
-- FROM
--   (
--     SELECT (0 + trunc(random() * 500000)) AS "user_id"
--     FROM generate_series(1, 1500000)
--     GROUP BY "user_id"
--   ) AS "gs1"

-- JOIN "users_with_ids" USING ("user_id")
-- ;


-- select * FROM benchmark_sql('select_by_random', 1);
-- select * FROM benchmark_sql('select_with_randomization', 1);


-- PREPARE "select_with_randomization" AS
-- SELECT "user_id", "uname"
-- FROM
--   (
--     SELECT (
--     0 + trunc(random() * (SELECT max("user_id") FROM "users_with_ids"))::int
--     ) AS "user_id"
--     FROM generate_series(1, (
--       SELECT COUNT(*) FROM "users_with_ids"
--     ))
--   ) AS "gs1"

-- JOIN "users_with_ids" USING ("user_id")
-- LIMIT 10;


-- select * FROM benchmark_sql('select_by_random', 1);
-- select * FROM benchmark_sql('select_with_randomization', 1);


-- Cleanup test functions
DROP FUNCTION IF EXISTS "test_offset_method";
DROP FUNCTION IF EXISTS "test_order_by_random_method";
DROP FUNCTION IF EXISTS "test_random_ids_method";
DROP TABLE "run_settings";