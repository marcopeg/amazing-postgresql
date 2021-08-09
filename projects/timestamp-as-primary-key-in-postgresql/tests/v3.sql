BEGIN;
SELECT plan(2);

PREPARE "insert" AS
WITH
-- Generates values to be inserted into the target table:
"insert_values" AS (
	VALUES
	('Luke', 'Skywalker'), 
	('Han', 'Solo')
),
-- Allocate a Timestamp based ID with an incremental value
-- that is specific for each record:
"insert_records" AS (
	SELECT 
		CONCAT(
			(EXTRACT(EPOCH FROM now()) * 100000)::BIGINT,
			'-',
			row_number() OVER ()
		) AS "id",
		"a"."column1" as "name",
		"a"."column2" as "surname"
	FROM "insert_values" AS "a"
)
-- Run the insert statement:
INSERT INTO "public"."people_v3" 
SELECT * FROM "insert_records"
RETURNING *;

SELECT performs_ok(
    'insert',
    100,
    'It should be able to insert multiple records within the same transaction'
);

-- check the final amount of records
SELECT results_eq(
  'SELECT COUNT(*)::int AS "count" FROM "public"."people_v3"',
  ARRAY[2]
);

SELECT * FROM finish();
ROLLBACK;

