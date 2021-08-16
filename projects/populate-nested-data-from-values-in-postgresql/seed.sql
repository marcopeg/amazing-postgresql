
-- Insert multiple items who's data is distributed to multiple related tables
-- https://stackoverflow.com/questions/20561254/insert-data-in-3-tables-at-a-time-using-postgres
-- https://stackoverflow.com/questions/68791267/how-to-convert-plain-values-with-arrays-into-a-data-structure-in-postgresql
WITH 
-- Provide the raw data that needs to be stored:
  "raw_data" ("nickname", "name", "surname", "articles") AS (
    VALUES
      ('lsk', 'Luke', 'Skywalker', ARRAY [
        ('How to blow the Death Star', '...')
      , ('How to become a Jedi', '...')
      ])
    , ('hsl', 'Han', 'Solo', ARRAY [
        ('How to kiss Leia', '...')
    ])
    -- bad guys don't write so much...
    , ('dvd', 'Darth', 'Vader', NULL)
  )

-- Insert data into the normalized schema:
, "ins_accounts" AS (
    INSERT INTO "public"."accounts" ("nickname")
    SELECT "nickname"
    FROM "raw_data"
    ON CONFLICT DO NOTHING -- skip any duplicate nickname
    RETURNING *
  )
, "ins_profiles" AS (
    INSERT INTO "public"."profiles" ("account_id", "name", "surname")
    SELECT "ins_accounts"."id", "raw_data"."name", "raw_data"."surname"
    FROM "raw_data"
    JOIN "ins_accounts" USING ("nickname")
    RETURNING *
)
, "ins_articles" AS (
  INSERT INTO "public"."articles" ("account_id", "title", "content")
  SELECT 
    "ins_accounts"."id" AS "account_id", 
    ((unnest("articles"))::TEXT::"article_input").*
  FROM "raw_data"
  JOIN "ins_accounts" USING ("nickname")
)

-- Returning data from the entire operation:
SELECT
  "ins_accounts".*,
  "ins_profiles".*
FROM "ins_accounts"
JOIN "ins_profiles" ON "ins_accounts"."id" = "ins_profiles"."account_id";
