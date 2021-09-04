BEGIN;
SELECT plan(1);

-- Populate data into the event log
-- INSERT INTO "public"."events_log" ("payload")
-- SELECT json_build_object('v', "t") AS "payload"
-- FROM generate_series(1, 10) AS "t";

SELECT ok(true);

SELECT * FROM finish();
ROLLBACK;

