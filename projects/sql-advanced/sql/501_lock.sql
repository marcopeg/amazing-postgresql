WITH "data" AS (
  SELECT * FROM "tasks"
  ORDER BY "id"
  LIMIT 1
  FOR UPDATE
)
SELECT "id" FROM "data", pg_sleep(5);