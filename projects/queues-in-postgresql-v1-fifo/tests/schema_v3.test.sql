BEGIN;
SELECT plan(3);

-- Pick & Flag: should update the "picked_at" field
TRUNCATE "queue_v3" RESTART IDENTITY CASCADE;
INSERT INTO "queue_v3" VALUES 
  ( '{ "name": "Task1" }' ),
  ( '{ "name": "Task2" }' );

UPDATE "queue_v3"
SET "is_available" = false
WHERE "task_id" = (
  SELECT "task_id"
  FROM "queue_v3"
  WHERE "is_available" = true
  ORDER BY "task_id" ASC
  FOR UPDATE SKIP LOCKED
  LIMIT 1
);

SELECT results_eq(
  $$
    SELECT COUNT(*)::INT
    FROM "queue_v3"
    WHERE "picked_at" IS NOT NULL
  $$,
  $$
    VALUES ( 1::INT)
  $$,
  'It should update the "picked_at" field when picking a task'
);


SELECT results_eq(
  $$
    UPDATE "queue_v3"
    SET "payload" = 
      jsonb_set(
        payload, '{etag}', 
        to_jsonb(to_char(now(),'YYYY-MM-DD HH:MM:SS')), 
        true
      )
    WHERE ("payload"->>'name')::TEXT = 'Task2'
    RETURNING 
      "task_id", 
      ("payload"->'name')::TEXT
  $$,
  $$
    VALUES ( 2::BIGINT, '"Task2"'::TEXT)
  $$,
  'It should NOT updat the "picked_at" when changing stuff into the payload'
);


-- Recovery from task failover
TRUNCATE "queue_v3" RESTART IDENTITY CASCADE;
INSERT INTO "queue_v3"
("payload", "is_available", "picked_at") VALUES 
( '{ "name": "Task1" }', false, now() - INTERVAL '10s'  );

SELECT results_eq(
  $$
    UPDATE "queue_v3"
    SET "is_available" = true
    WHERE "task_id" IN (
      SELECT "task_id" 
      FROM "queue_v3"
      WHERE "is_available" = false
        AND "picked_at" < now() - INTERVAL '5s'
      FOR UPDATE SKIP LOCKED
    )
    RETURNING ("payload"->'name')::TEXT
  $$,
  $$
    VALUES ( '"Task1"'::TEXT)
  $$,
  'It should recover a timeouted task'
);

SELECT * FROM finish();
ROLLBACK;

