
DROP TABLE IF EXISTS "test_results";
CREATE TABLE IF NOT EXISTS "test_results" (
  "test_name" TEXT
, "avg_duration" REAL
);

SELECT * FROM "users_with_ids" 
OFFSET (SELECT floor(random() * (
  SELECT count(*) FROM "users_with_ids"
) + 1))
LIMIT 1;





-- CREATE OR REPLACE FUNCTION "test_offset_method"(
--   OUT ok BOOLEAN
-- )
-- AS $$
-- DECLARE
--   max_offset INT;
-- BEGIN

--   FOR i IN 0..6 LOOP
--     -- calculate the offset that we want to achieve
--     max_offset = 5 * POWER(10, i);
--     raise notice 'offset: %', max_offset; 
  
--     -- run the benchmark and log the result
--     INSERT INTO "test_results"
--     SELECT
--       CONCAT('random_offset_', max_offset) AS "test_name"
--     , "avg_duration" 
--     FROM benchmark_sql(FORMAT(
--       'SELECT * FROM "users_with_ids" OFFSET %s LIMIT 1',
--       max_offset
--     ), 100);
--   END LOOP;
--   ok = true;
-- END; $$
-- LANGUAGE plpgsql
-- VOLATILE;

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
DROP FUNCTION "test_offset_method";