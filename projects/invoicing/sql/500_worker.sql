WITH
"pick_task" AS (
  SELECT * FROM "tasks"
  ORDER BY "id"
  LIMIT 1
  FOR UPDATE SKIP LOCKED
),
"slow_log" AS (
  INSERT INTO "logs"
  SELECT "id" FROM "pick_task", pg_sleep(5)
  returning *
)
DELETE FROM "tasks"
WHERE "id" IN (SELECT "value" FROM "slow_log")
RETURNING CONCAT('Completed TaskID: ', "id");