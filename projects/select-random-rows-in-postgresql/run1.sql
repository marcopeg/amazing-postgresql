CREATE TEMPORARY TABLE "run_settings" ("doc" JSONB);
INSERT INTO "run_settings" VALUES ('{
  "repeat_tests": 25
}'::jsonb);


DROP TABLE IF EXISTS "test_results";
CREATE TABLE IF NOT EXISTS "test_results" (
  "test_name" TEXT
, "rows_counts" INT
, "avg_duration" REAL
);


CREATE OR REPLACE FUNCTION "run_test"(
  PAR_testName TEXT,
  PAR_generateRows INT,
  PAR_emptyTable BOOLEAN,
  OUT ok BOOLEAN
)
AS $$
DECLARE
  max_user_id INT;
  ins_start INT;
  ins_end INT;
  curr_rows_count INT;
  repeat_tests INT;
BEGIN
  -- Get test settings
  SELECT ("doc"->'repeat_tests')::INT INTO repeat_tests FROM "run_settings";

  -- Generate data baseline before running the tests
  IF PAR_emptyTable THEN
    RAISE NOTICE 'Truncate table "users_with_ids"';
    TRUNCATE "users_with_ids" RESTART IDENTITY;
  END IF;

  SELECT COALESCE(max("user_id")::int, 0) INTO "max_user_id" FROM "users_with_ids";
  RAISE NOTICE 'Current max userId: %', max_user_id;
  ins_start = max_user_id + 1;
  ins_end = max_user_id + PAR_generateRows;

  RAISE NOTICE 'Insert rows: % -> %', ins_start, ins_end;
  INSERT INTO "users_with_ids" ("uname")
  SELECT CONCAT('u', "gs1")
  FROM generate_series(ins_start, ins_end) "gs1";

  SELECT COUNT(*) INTO curr_rows_count FROM "users_with_ids";
  RAISE NOTICE 'Current row count: %', curr_rows_count;


  -- test offset
  INSERT INTO "test_results"
  SELECT
    CONCAT('offset_', PAR_testName) AS "test_name"
  , curr_rows_count
  , "avg_duration" 
  FROM benchmark_sql(FORMAT(
    'SELECT * FROM "users_with_ids" OFFSET %s LIMIT 1',
    curr_rows_count
  ), repeat_tests);

  -- order by random
  INSERT INTO "test_results"
  SELECT
    CONCAT('order_by_random', PAR_testName) AS "test_name"
  , curr_rows_count
  , "avg_duration" 
  FROM benchmark_sql('SELECT * FROM "users_with_ids" ORDER BY random() LIMIT 1;', repeat_tests);

  INSERT INTO "test_results"
    SELECT
      CONCAT('random_ids_', PAR_testName) AS "test_name"
    , curr_rows_count
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
    ', curr_rows_count), repeat_tests);

  ok = true;
END; $$
LANGUAGE plpgsql
VOLATILE;

-- 10K > 100K
SELECT * FROM run_test('10k',  10000, true);
SELECT * FROM run_test('20k',  10000, false);
SELECT * FROM run_test('30k',  10000, false);
SELECT * FROM run_test('40k',  10000, false);
SELECT * FROM run_test('50k',  10000, false);
SELECT * FROM run_test('60k',  10000, false);
SELECT * FROM run_test('70k',  10000, false);
SELECT * FROM run_test('80k',  10000, false);
SELECT * FROM run_test('90k',  10000, false);
SELECT * FROM run_test('100k',  10000, false);

-- 100K > 1M
SELECT * FROM run_test('200k', 100000, false);
SELECT * FROM run_test('300k', 100000, false);
SELECT * FROM run_test('400k', 100000, false);
SELECT * FROM run_test('500k', 100000, false);
SELECT * FROM run_test('600k', 100000, false);
SELECT * FROM run_test('700k', 100000, false);
SELECT * FROM run_test('800k', 100000, false);
SELECT * FROM run_test('900k', 100000, false);
SELECT * FROM run_test('1M', 100000, false);

-- -- 1M > 10M
-- SELECT * FROM run_test('2M', 1000000, false);
-- SELECT * FROM run_test('3M', 1000000, false);
-- SELECT * FROM run_test('4M', 1000000, false);
-- SELECT * FROM run_test('5M', 1000000, false);
-- SELECT * FROM run_test('6M', 1000000, false);
-- SELECT * FROM run_test('7M', 1000000, false);
-- SELECT * FROM run_test('8M', 1000000, false);
-- SELECT * FROM run_test('9M', 1000000, false);
-- SELECT * FROM run_test('10M', 1000000, false);

-- -- 10M > 100M
-- SELECT * FROM run_test('20M', 10000000, false);
-- SELECT * FROM run_test('30M', 10000000, false);
-- SELECT * FROM run_test('40M', 10000000, false);
-- SELECT * FROM run_test('50M', 10000000, false);
-- SELECT * FROM run_test('60M', 10000000, false);
-- SELECT * FROM run_test('70M', 10000000, false);
-- SELECT * FROM run_test('80M', 10000000, false);
-- SELECT * FROM run_test('90M', 10000000, false);
-- SELECT * FROM run_test('100M', 10000000, false);



-- DROP FUNCTION IF EXISTS "run_test";
-- DROP TABLE "run_settings";


-- SELECT * FROM
--   (
--     SELECT (0 + trunc(random() * %s)) AS "user_id"
--     FROM generate_series(1, 1)
--     GROUP BY "user_id"
--   ) AS "gs1"
-- JOIN "users_with_ids" USING ("user_id")
-- LIMIT 1;

-- EXPLAIN 
-- SELECT * FROM "users_with_ids"
-- WHERE "user_id" = (
--   SELECT (0 + trunc(random() * 10000000))  
-- )
-- LIMIT 1;


-- SELECT * FROM "users_with_ids"
-- WHERE "user_id" IN (
--   SELECT (0 + trunc(random() * 10000000)) AS "user_id"
--   FROM generate_series(1, 1)
--   GROUP BY "user_id"
-- )
-- LIMIT 1;

-- -- SELECT (0 + trunc(random() * 1000))  ;

-- -- EXPLAIN 
-- SELECT * FROM "users_with_ids" LIMIT 1;