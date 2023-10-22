DROP SCHEMA "public" CASCADE;
CREATE SCHEMA "public";

CREATE TABLE "athletes" (
  "id" SERIAL PRIMARY KEY,
  "name" TEXT NOT NULL,
  "height" INTEGER NOT NULL
);

INSERT INTO "athletes" ("name", "height") VALUES
('Alice', 180),
('Bob', 175),
('Charlie', 185),
('David', 190),
('Emily', 165);

-- Let's check the execution plan:
EXPLAIN ANALYZE
WITH avg_height AS (
  SELECT AVG("height") AS avg_height_value FROM "athletes"
)
SELECT "id", "name", "height"
FROM "athletes", avg_height
WHERE "height" > avg_height.avg_height_value;

-- And get the results:
WITH avg_height AS (
  SELECT AVG("height") AS avg_height_value FROM "athletes"
)
SELECT "id", "name", "height"
FROM "athletes", avg_height
WHERE "height" > avg_height.avg_height_value;
