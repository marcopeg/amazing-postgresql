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
SELECT "id", "name", "height" 
FROM "athletes"
WHERE "height" > (
  SELECT AVG("height") FROM "athletes"
);

-- And get the results:
SELECT "id", "name", "height" 
FROM "athletes"
WHERE "height" > (
  SELECT AVG("height") FROM "athletes"
);
