DROP SCHEMA "public" CASCADE;
CREATE SCHEMA "public";

-- Table without indexes:
DROP TABLE IF EXISTS "users";
CREATE UNLOGGED TABLE "users" (
  "id" SERIAL PRIMARY KEY,
  "uuid" UUID DEFAULT md5(random()::text || clock_timestamp()::text)::uuid,
  "name" TEXT,
  "gender" TEXT,
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
  CASE
    WHEN random() < 0.55 THEN 'M'
    WHEN random() < 0.95 THEN 'F'
    ELSE 'O'
  END,
  to_timestamp("min_time" + (random() * ("max_time" - "min_time")))::date,
  colors[ceil(random() * array_length(colors, 1))::integer],
  floor(random() * 999999999 + 1)::integer,
  concat('word-', floor(random() * 5000 + 1)::integer)
FROM generate_series(1, 100000) "n", "raw_data";

-- Make some copies of the table to play around with indexes:

DROP TABLE IF EXISTS "users_idx_1";
CREATE UNLOGGED TABLE "users_idx_1" AS TABLE "users";
ALTER TABLE "users_idx_1" ADD PRIMARY KEY ("id");
CREATE SEQUENCE "users_idx_1_id_seq";
ALTER TABLE "users_idx_1" ALTER COLUMN "id" SET DEFAULT nextval('"users_idx_1_id_seq"'::regclass);
ALTER SEQUENCE "users_idx_1_id_seq" OWNED BY "users_idx_1"."id";
SELECT setval('users_idx_1_id_seq', (SELECT MAX("id") FROM "users_idx_1"));

DROP TABLE IF EXISTS "users_idx_2";
CREATE UNLOGGED TABLE "users_idx_2" AS TABLE "users";
ALTER TABLE "users_idx_2" ADD PRIMARY KEY ("id");
CREATE SEQUENCE "users_idx_2_id_seq";
ALTER TABLE "users_idx_2" ALTER COLUMN "id" SET DEFAULT nextval('"users_idx_2_id_seq"'::regclass);
ALTER SEQUENCE "users_idx_2_id_seq" OWNED BY "users_idx_2"."id";
SELECT setval('users_idx_2_id_seq', (SELECT MAX("id") FROM "users_idx_2"));

DROP TABLE IF EXISTS "users_idx_3";
CREATE UNLOGGED TABLE "users_idx_3" AS TABLE "users";
ALTER TABLE "users_idx_3" ADD PRIMARY KEY ("id");
CREATE SEQUENCE "users_idx_3_id_seq";
ALTER TABLE "users_idx_3" ALTER COLUMN "id" SET DEFAULT nextval('"users_idx_3_id_seq"'::regclass);
ALTER SEQUENCE "users_idx_3_id_seq" OWNED BY "users_idx_3"."id";
SELECT setval('users_idx_3_id_seq', (SELECT MAX("id") FROM "users_idx_3"));




-- Enable logging for the tables:
ALTER TABLE "users" SET LOGGED;
ALTER TABLE "users_idx_1" SET LOGGED;
ALTER TABLE "users_idx_2" SET LOGGED;
ALTER TABLE "users_idx_3" SET LOGGED;


-- Create indexes for the examples:
CREATE INDEX "users_idx_1_uuid_btree" ON "users_idx_1" USING btree ("uuid");
CREATE INDEX "users_idx_2_uuid_hash" ON "users_idx_2" USING hash ("uuid");

CREATE INDEX "users_idx_1_name_btree" ON "users_idx_1" USING btree ("name");
CREATE INDEX "users_idx_2_name_hash" ON "users_idx_2" USING hash ("name");

CREATE INDEX "users_idx_1_gender_btree" ON "users_idx_1" USING btree ("gender");
CREATE INDEX "users_idx_2_gender_hash" ON "users_idx_2" USING hash ("gender");
CREATE INDEX "users_idx_3_gender_part" ON "users_idx_3" ("gender") WHERE "gender" = 'M';

CREATE INDEX "users_idx_1_favourite_color_btree" ON "users_idx_1" USING btree ("favourite_color");
CREATE INDEX "users_idx_2_favourite_color_hash" ON "users_idx_2" USING hash ("favourite_color");
CREATE INDEX "users_idx_3_favourite_color_part" ON "users_idx_3" ("favourite_color") WHERE "favourite_color" = 'Red';

CREATE INDEX "users_idx_1_favourite_word_btree" ON "users_idx_1" USING btree ("favourite_word");
CREATE INDEX "users_idx_2_favourite_word_hash" ON "users_idx_2" USING hash ("favourite_word");
CREATE INDEX "users_idx_3_favourite_word_part" ON "users_idx_3" ("favourite_word") WHERE "favourite_word" = 'Word-1981';

CREATE INDEX "users_idx_1_date_of_birth_btree" ON "users_idx_1" USING btree ("date_of_birth");
CREATE INDEX "users_idx_2_date_of_birth_hash" ON "users_idx_2" USING hash ("date_of_birth");

CREATE INDEX "users_idx_1_favourite_number_btree" ON "users_idx_1" USING btree ("favourite_number");
CREATE INDEX "users_idx_2_favourite_number_hash" ON "users_idx_2" USING hash ("favourite_number");
CREATE INDEX "users_idx_3_favourite_number_part" ON "users_idx_3" USING btree ("favourite_number") WHERE "favourite_number" BETWEEN 91938000 AND 91939000;

VACUUM (FULL, ANALYZE) "users";
VACUUM (FULL, ANALYZE) "users_idx_1";
VACUUM (FULL, ANALYZE) "users_idx_2";
VACUUM (FULL, ANALYZE) "users_idx_3";