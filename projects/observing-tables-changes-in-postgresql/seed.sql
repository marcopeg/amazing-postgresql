-- Setup a new table
CREATE TABLE "public"."names" (
  "id" SERIAL PRIMARY KEY,
  "name" VARCHAR(100)
);

-- And make it observable
SELECT * FROM observe_table('public', 'names', true);

-- Insert different records
INSERT INTO "public"."names" ("id", "name") VALUES
(1, 'Luke Skywalker'), (2, 'han solo'), (3, 'Topolino')
RETURNING *;

-- Update an existing record
UPDATE "public"."names"
SET "name" = 'Han Solo'
WHERE "id" = 2
RETURNING *;

-- Delete from the table
DELETE FROM "public"."names"
WHERE "id" = 3
RETURNING *;
