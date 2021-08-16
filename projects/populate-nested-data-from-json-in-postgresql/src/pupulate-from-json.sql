-- In this function we incour in some ambiguity about the returning columns
-- https://stackoverflow.com/questions/44075069/why-i-am-getting-column-reference-is-ambiguous
--
-- So far, I don't have a full comprehension of this issue, the workaround that I've found
-- consists in creating an "_impl" function with prefixed (_) fields, and use that in
-- a wrapper function that will yield the good looking column names.


--
-- Implementation Function
--
CREATE OR REPLACE FUNCTION 
populate_from_json_impl(
  PAR_document JSON
) RETURNS TABLE (
  "_id" INT,
  "_nickname" VARCHAR(50),
  "_name" VARCHAR(50),
  "_surname" VARCHAR(50),
  "_articles" INT
)
AS $$
BEGIN
  RETURN QUERY
  WITH
  -- Provide the raw data that needs to be stored:
    "raw_data"("document") AS (VALUES(PAR_document))

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
      json_to_recordset("document") AS "x"(
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
    "ins_accounts"."id" AS "_id",
    "ins_accounts"."nickname" AS "_nickname",
    "ins_profiles"."name" AS "_name",
    "ins_profiles"."surname" AS "_surname",
    -- compute the total inserted articles:
    (
      SELECT COUNT(*)::int FROM "ins_articles"
      WHERE "ins_articles"."account_id" = "ins_accounts"."id"
    ) AS "_articles"
  FROM "ins_accounts"
  JOIN "ins_profiles" ON "ins_accounts"."id" = "ins_profiles"."account_id";

END; $$
LANGUAGE plpgsql;


--
-- Good looking API Function
--
CREATE OR REPLACE FUNCTION 
populate_from_json(
  PAR_document JSON
) RETURNS TABLE (
  "id" INT,
  "nickname" VARCHAR(50),
  "name" VARCHAR(50),
  "surname" VARCHAR(50),
  "articles" INT
)
AS $$
BEGIN

  RETURN QUERY
  SELECT
    "_id" AS "id",
    "_nickname" AS "nickname",
    "_name" AS "name",
    "_surname" AS "surname",
    "_articles" AS "articles"
  FROM populate_from_json_impl(PAR_document);

END; $$
LANGUAGE plpgsql;
