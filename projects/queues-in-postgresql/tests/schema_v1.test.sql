BEGIN;
SELECT plan(5);

-- Insert single task:
TRUNCATE "queue_v1" RESTART IDENTITY CASCADE;

INSERT INTO "queue_v1"
VALUES ('{"name": "my task"}');

SELECT results_eq(
  'SELECT COUNT(*)::INT FROM "queue_v1"', 
  'VALUES (1::INT)',
  'It should be able to insert a single task'
);

-- Insert multiple tasks:
TRUNCATE "queue_v1" RESTART IDENTITY CASCADE;

INSERT INTO "queue_v1"
SELECT json_build_object('value', "t")
FROM generate_series(1, 10) AS "t";

SELECT results_eq(
  'SELECT COUNT(*)::INT FROM "queue_v1"', 
  'VALUES (10::INT)',
  'It should be able to insert multiple tasks'
);

-- Pick one task:
PREPARE "pick_one_task" AS
SELECT "task_id" FROM "queue_v1"
ORDER BY "task_id" ASC
LIMIT 1;

SELECT results_eq(
  'pick_one_task',
  'VALUES (1::BIGINT)',
  'It should be able to pick a task'
);

-- Process one task:
PREPARE "process_one_task" AS
DELETE FROM "queue_v1"
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

SELECT * FROM finish();
ROLLBACK;

