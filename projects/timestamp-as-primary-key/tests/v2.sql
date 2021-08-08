BEGIN;
SELECT plan(2);

-- add multiple records

PREPARE "insert1" AS
INSERT INTO "public"."people_v2" ("name", "surname")
VALUES
  ('Luke', 'Skywalker'), 
  ('Han', 'Solo'),
  ('Leia', 'Princess'),
  ('Obi-Wan', 'Kenobi'),
  ('Yoda', 'Master');

SELECT performs_ok(
    'insert1',
    100,
    'It should be able to insert a multiple records within the same instruction'
);

-- check the final amount of records

SELECT results_eq(
  'SELECT COUNT(*)::int AS "count" FROM "public"."people_v2"',
  ARRAY[5]
);

SELECT * FROM finish();
ROLLBACK;

