INSERT INTO "public"."events_log" ("payload")
SELECT json_build_object('v', "t") AS "payload"
FROM generate_series(1, 1000) AS "t";
