BEGIN;
SELECT plan(1);

PREPARE "insert_multiple_events" AS
INSERT INTO "public"."events_log" ("payload")
SELECT json_build_object('v', "t") AS "payload"
FROM generate_series(1, 1000) AS "t";

SELECT performs_ok(
  'insert_multiple_events',
  100,
  'It should be able to insert multiple events within the transaction'
);

SELECT * FROM finish();
ROLLBACK;

