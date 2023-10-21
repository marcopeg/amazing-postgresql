-- 1000 RECORDS

DROP TABLE IF EXISTS "users_1k";
CREATE UNLOGGED TABLE "users_1k" (
  "id" SERIAL PRIMARY KEY,
  "name" TEXT NOT NULL UNIQUE,
  "gender" TEXT NOT NULL,
  "date_of_birth" DATE NOT NULL,
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
INSERT INTO "users_1k" ("name", "gender", "date_of_birth", "favourite_color", "favourite_number", "favourite_word")
SELECT
  concat('User-', "n"),
  CASE
    WHEN random() < 0.4 THEN 'M'
    WHEN random() < 0.8 THEN 'F'
    ELSE 'O'
  END,
  to_timestamp("min_time" + (random() * ("max_time" - "min_time")))::date,
  colors[ceil(random() * array_length(colors, 1))::integer],
  floor(random() * 999999999 + 1)::integer,
  concat('word-', floor(random() * 5000 + 1)::integer)
FROM generate_series(1, 1000) "n", "raw_data";





-- 1 MILLION RECORDS

DROP TABLE IF EXISTS "users_1M";
CREATE UNLOGGED TABLE "users_1M" (
  "id" SERIAL PRIMARY KEY,
  "name" TEXT NOT NULL UNIQUE,
  "gender" TEXT NOT NULL,
  "date_of_birth" DATE NOT NULL,
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
INSERT INTO "users_1M" ("name", "gender", "date_of_birth", "favourite_color", "favourite_number", "favourite_word")
SELECT
  concat('User-', "n"),
  CASE
    WHEN random() < 0.4 THEN 'M'
    WHEN random() < 0.8 THEN 'F'
    ELSE 'O'
  END,
  to_timestamp("min_time" + (random() * ("max_time" - "min_time")))::date,
  colors[ceil(random() * array_length(colors, 1))::integer],
  floor(random() * 999999999 + 1)::integer,
  concat('word-', floor(random() * 5000 + 1)::integer)
FROM generate_series(1, 1000000) "n", "raw_data";






-- 25 MILLIONS

DROP TABLE IF EXISTS "users_25M";
CREATE UNLOGGED TABLE "users_25M" (
  "id" SERIAL PRIMARY KEY,
  "name" TEXT NOT NULL UNIQUE,
  "gender" TEXT NOT NULL,
  "date_of_birth" DATE NOT NULL,
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
INSERT INTO "users_25M" ("name", "gender", "date_of_birth", "favourite_color", "favourite_number", "favourite_word")
SELECT
  concat('User-', "n"),
  CASE
    WHEN random() < 0.4 THEN 'M'
    WHEN random() < 0.8 THEN 'F'
    ELSE 'O'
  END,
  to_timestamp("min_time" + (random() * ("max_time" - "min_time")))::date,
  colors[ceil(random() * array_length(colors, 1))::integer],
  floor(random() * 999999999 + 1)::integer,
  concat('word-', floor(random() * 5000 + 1)::integer)
FROM generate_series(1, 25000000) "n", "raw_data";