WITH
-- Provide the raw data that needs to be stored:
  "raw_data"("document") AS ( VALUES ('
    [
      {
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
      }
      ,{
        "nickname": "hsl",
        "name": "Han",
        "surname": "Solo",
        "articles": [
          {
            "title": "How to kiss Leia",
            "content": "..."
          }
        ]
      }
      ,{
        "nickname": "dvd",
        "name": "Darth",
        "surname": "Vader",
        "articles": []
      }
    ]
  '))

-- Parse JSON and generate tabular data rapresentations that are
-- suitable for inserting the records into the normalized structure
, "tab_data" AS (
  SELECT
    "nickname",
    "name",
    "surname",
    "articles"
  FROM 
    "raw_data",
    json_to_recordset("document"::JSON) AS "x"(
      "nickname" TEXT,
      "name" TEXT,
      "surname" TEXT,
      "articles" JSON
    )
)
, "tab_articles" AS (
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
