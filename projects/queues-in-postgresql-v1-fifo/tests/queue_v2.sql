BEGIN;
SELECT plan(10);

-- Insert one task:
TRUNCATE "queue_v2" RESTART IDENTITY CASCADE;
INSERT INTO "queue_v2" VALUES ('{"name": "my task"}');

-- It should be flagged as available:
SELECT results_eq(
  'SELECT COUNT(*)::INT FROM "queue_v2"', 
  'VALUES (1::INT)',
  'It should be able to insert a single task'
);
SELECT results_eq(
  'SELECT "is_available" FROM "queue_v2"', 
  'VALUES (true)',
  'The new task availability flag should be defaulted to true'
);

-- Insert multiple tasks:
TRUNCATE "queue_v2" RESTART IDENTITY CASCADE;

INSERT INTO "queue_v2"
SELECT
  json_build_object('value', "t"),
  random() > 0.5
FROM generate_series(1, 10) AS "t"
RETURNING *;

SELECT results_eq(
  'SELECT COUNT(*)::INT FROM "queue_v2"', 
  'VALUES (10::INT)',
  'It should be able to insert multiple tasks'
);

-- Pick one task:
TRUNCATE "queue_v2" RESTART IDENTITY CASCADE;
INSERT INTO "queue_v2"
SELECT json_build_object('name', CONCAT('task', "t"))
FROM generate_series(1, 10) AS "t";

PREPARE "pick_one_task" AS
SELECT 
  "task_id", 
  ("payload"->'name')::TEXT
FROM "queue_v2"
WHERE "is_available" = true
ORDER BY "task_id" ASC
LIMIT 1;

SELECT results_eq(
  'pick_one_task',
  $$VALUES ( 1::BIGINT, '"task1"'::TEXT)$$,
  'It should be able to pick a task'
);

-- Mark one task as processing
PREPARE "flag_task" AS
UPDATE "queue_v2"
SET "is_available" = false
WHERE "task_id" = 1
  AND "is_available" = true
RETURNING "task_id";

SELECT results_eq(
  'flag_task',
  $$VALUES ( 1::BIGINT )$$,
  'It should be able to flag a task as WIP'
);

SELECT is_empty(
  'flag_task',
  'It should NOT flag the task twice'
);

-- Process one task:
PREPARE "process_one_task" AS
DELETE FROM "queue_v2"
WHERE "task_id" = 1
RETURNING "task_id";

SELECT results_eq(
  'process_one_task',
  'VALUES (1::BIGINT)',
  'It should be able to process a single task'
);

SELECT is_empty(
  'process_one_task',
  'It should NOT process the same task twice'
);

-- Pick & Flag
TRUNCATE "queue_v2" RESTART IDENTITY CASCADE;
INSERT INTO "queue_v2"
SELECT json_build_object('name', CONCAT('task', "t"))
FROM generate_series(1, 10) AS "t";

PREPARE "pick_and_flag" AS
UPDATE "queue_v2"
SET "is_available" = false
WHERE "task_id" = (
  SELECT "task_id"
  FROM "queue_v2"
  WHERE "is_available" = true
  FOR UPDATE SKIP LOCKED
  LIMIT 1
)
RETURNING 
  "task_id", 
  ("payload"->'name')::TEXT
;

SELECT results_eq(
  'pick_and_flag',
  $$VALUES ( 1::BIGINT, '"task1"'::TEXT)$$,
  'It should be able to pick and flag the first task'
);

SELECT results_ne(
  'pick_and_flag',
  $$VALUES ( 1::BIGINT, '"task1"'::TEXT)$$,
  'It should NOT pick and flag the first task again'
);

SELECT * FROM finish();
ROLLBACK;

