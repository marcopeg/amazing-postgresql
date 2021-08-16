BEGIN;
SELECT plan(5);

WITH
-- Provide the raw data that needs to be stored:
  "raw_data"("json") AS (
    VALUES 
    	('{
        "nickname": "lsk",
        "name": "Luke",
        "surname": "Skywalker",
        "articles": [
          {
            "title": "How to blow the Death Star",
            "content": "..."
          },
          {
            "title": "How to become a Jedi",
            "content": "..."
          }
        ]
      }'::json)
    , ('{
        "nickname": "hsl",
        "name": "Han",
        "surname": "Solo",
        "articles": [
          {
            "title": "How to kiss Leia",
            "content": "..."
          }
        ]
      }'::json)
    , ('{
        "nickname": "dvd",
        "name": "Darth",
        "surname": "Vader",
        "articles": []
      }'::json)
  )

-- Convert the JSON format into a tabular format
, "tab_data" AS (
  SELECT
    trim(("raw_data"."json" -> 'nickname')::text, '"') AS "nickname"
  , trim(("raw_data"."json" -> 'name')::text, '"') AS "name"
  , trim(("raw_data"."json" -> 'surname')::text, '"') AS "surname"
  , ("raw_data"."json" -> 'articles')::json AS "articles"
  FROM "raw_data"
)

, "tab_articles" AS (
  -- INSERT INTO "public"."articles" ("account_id", "title", "content")
  SELECT 
    "t"."nickname" AS "nickname",
    "x"."title" AS "title",
    "x"."content" AS "content"
  FROM 
    "tab_data" AS "t",
    json_to_recordset("t"."articles") AS "x"("title" text, "content" text)
)

-- Insert data into the normalized schema:
, "ins_accounts" AS (
    INSERT INTO "public"."accounts" ("nickname")
    SELECT "nickname"
    FROM "tab_data"
    ON CONFLICT DO NOTHING -- skip any duplicate nickname
    RETURNING *
  )
, "ins_profiles" AS (
    INSERT INTO "public"."profiles" ("account_id", "name", "surname")
    SELECT "ins_accounts"."id", "tab_data"."name", "tab_data"."surname"
    FROM "tab_data"
    JOIN "ins_accounts" USING ("nickname")
    RETURNING *
)
, "ins_articles" AS (
  INSERT INTO "public"."articles" ("account_id", "title", "content")
  SELECT 
    "a"."id" as "account_id",
    "t"."title",
    "t"."content"
  FROM "tab_articles" AS "t"
  JOIN "ins_accounts" AS "a" USING ("nickname")
  RETURNING *
)

-- Returning data from the entire operation:
SELECT
  "ins_accounts".*,
  "ins_profiles".*
FROM "ins_accounts"
JOIN "ins_profiles" ON "ins_accounts"."id" = "ins_profiles"."account_id";



--
-- >>> TESTING >>>
--

SELECT results_eq(
  'SELECT COUNT(*)::int AS "count" FROM "public"."accounts"',
  ARRAY[3],
  'There should be 3 records in table "accounts'
);

PREPARE "find_luke_account" AS
SELECT COUNT(*)::int AS "count" FROM "public"."accounts" WHERE "nickname" = 'lsk';

SELECT results_eq(
  'find_luke_account',
  ARRAY[1],
  'There should be 1 account that belongs to Luke'
);

SELECT results_eq(
  'SELECT COUNT(*)::int AS "count" FROM "public"."profiles"',
  ARRAY[3],
  'There should be 3 records in table "profiles'
);

SELECT results_eq(
  'SELECT COUNT(*)::int AS "count" FROM "public"."articles"',
  ARRAY[3],
  'There should be 3 records in table "articles'
);

PREPARE "count_luke_articles" AS
SELECT COUNT(*)::int AS "count" FROM "public"."articles"
WHERE "account_id" IN (
  SELECT "id" FROM "public"."accounts"
  WHERE "nickname" = 'lsk'
);

SELECT results_eq(
  'count_luke_articles',
  ARRAY[2],
  'Luke should own 2 articles'
);

SELECT * FROM finish();
ROLLBACK;

