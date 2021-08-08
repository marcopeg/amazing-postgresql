BEGIN;
SELECT * FROM no_plan();


-- Setup an observable table:
CREATE TABLE "public"."foobar" (
  "id" SERIAL PRIMARY KEY,
  "name" VARCHAR(100)
);
SELECT * FROM observe_table('public', 'foobar', true);


-- Try to insert a single value and observe the changelog table grow in size:
INSERT INTO "public"."foobar" ("name") VALUES ('Luke');
SELECT results_eq(
  'SELECT COUNT(*)::int AS "count" FROM "public"."changelog"',
  ARRAY[1]
);


-- Disable the observable table:
SELECT * FROM observe_table('public', 'foobar', false);
INSERT INTO "public"."foobar" ("name") VALUES ('Han');
-- the sie of the table should grow
SELECT results_eq(
  'SELECT COUNT(*)::int AS "count" FROM "public"."foobar"',
  ARRAY[2]
);
-- but not the size of the changelog
SELECT results_eq(
  'SELECT COUNT(*)::int AS "count" FROM "public"."changelog"',
  ARRAY[1]
);


SELECT * FROM finish();
ROLLBACK;

