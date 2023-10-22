DROP SCHEMA "public" CASCADE;
CREATE SCHEMA "public";

CREATE TYPE GENDER AS ENUM ('M', 'F', 'O');

-- Table without indexes:
DROP TABLE IF EXISTS "users";
CREATE UNLOGGED TABLE "users" (
  "id" SERIAL PRIMARY KEY,
  "uuid" UUID DEFAULT md5(random()::text || clock_timestamp()::text)::uuid,
  "name" TEXT,
  "gender" GENDER,
  "date_of_birth" DATE,
  "favourite_color" TEXT,
  "favourite_number" INTEGER,
  "favourite_word" TEXT
);

-- Seed the dataset with randomic data:
WITH "raw_data" AS (
  SELECT 
    ARRAY['Red', 'Green', 'Blue', 'Yellow', 'Purple', 'Orange', 'Pink', 'Brown', 'Grey', 'Black'] AS colors,
    extract(epoch from current_timestamp) AS "max_time",
    extract(epoch from (current_timestamp - interval '100 years')) AS "min_time"
)
INSERT INTO "users" ("name", "gender", "date_of_birth", "favourite_color", "favourite_number", "favourite_word")
SELECT
  concat('User-', "n"),
  (CASE
    WHEN random() < 0.55 THEN 'M'
    WHEN random() < 0.95 THEN 'F'
    ELSE 'O'
  END)::GENDER,
  to_timestamp("min_time" + (random() * ("max_time" - "min_time")))::date,
  colors[ceil(random() * array_length(colors, 1))::integer],
  floor(random() * 999999999 + 1)::integer,
  concat('word-', floor(random() * 5000 + 1)::integer)
FROM generate_series(1, 100000) "n", "raw_data";