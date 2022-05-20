BEGIN;
SELECT plan(4);

-- Pick task based on next execution date:
TRUNCATE "queue_v4" RESTART IDENTITY CASCADE;
INSERT INTO "queue_v4" VALUES 
  ('{"name": "task1"}', now()),                 -- Insert FIFO
  ('{"name": "task2"}', now() + INTERVAL '1s'), -- Insert in the future
  ('{"name": "task3"}', now() - INTERVAL '1s')  -- Should be processed first
;

PREPARE "pick_one_task" AS
UPDATE "queue_v4"
SET "next_iteration" = now() + INTERVAL '10s'
WHERE "task_id" = (
  SELECT "task_id"
  FROM "queue_v4"
  WHERE "next_iteration" <= now()
  ORDER BY "next_iteration" ASC
  FOR UPDATE SKIP LOCKED
  LIMIT 1
)
RETURNING ("payload"->'name')::TEXT;

SELECT results_eq(
  'pick_one_task',
  $$VALUES ( '"task3"'::TEXT )$$,
  'Task3 should go first'
);

SELECT results_eq(
  'pick_one_task',
  $$VALUES ( '"task1"'::TEXT )$$,
  'Task1 should go second'
);

SELECT is_empty(
  'pick_one_task',
  'Task2 is in the future and should not be visible'
);

SELECT results_eq(
  $$
  SELECT COUNT("task_id")::INT 
  FROM "queue_v4"
  WHERE "next_iteration" = now() + INTERVAL '10000ms'
  $$,
  $$VALUES ( 2::INT )$$,
  'Task1 and Task3 should have been rescheduled in the future'
);


SELECT * FROM finish();
ROLLBACK;

