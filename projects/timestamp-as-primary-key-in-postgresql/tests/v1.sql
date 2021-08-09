BEGIN;
SELECT plan(3);

-- add first record

PREPARE "insert1" AS
INSERT INTO "public"."people_v1" ("name", "surname")
VALUES ('Luke', 'Skywalker');

SELECT performs_ok(
    'insert1',
    100,
    'It should be able to insert a single record within the transaction'
);

-- add second record

PREPARE "insert2" AS
INSERT INTO "public"."people_v1" ("name", "surname")
VALUES ('Han', 'Solo');

SELECT throws_ok(
    'insert2',
    '23505',
    'duplicate key value violates unique constraint "people_v1_pkey"',
    'It should fail to add multiple records with the same transaction'
);

-- check the final amount of records

SELECT results_eq(
  'SELECT COUNT(*)::int AS "count" FROM "public"."people_v1"',
  ARRAY[1]
);

SELECT * FROM finish();
ROLLBACK;

