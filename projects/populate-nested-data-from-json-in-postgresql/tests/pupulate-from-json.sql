BEGIN;
SELECT plan(6);

-- INSERT DATA
-- The API function let us provide only the real data we want to send to
-- the database, using functions:
-- 1. less data will travel on the network (no query source code)
-- 2. the execution plan for the function's queries will be cached!
--    (https://www.postgresql.org/docs/current/plpgsql-implementation.html)

SELECT * FROM populate_from_json('
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
');



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


---
--- INSERT MORE DATA
--- The function should ignore existing data by the unique key "nickname"
--- But should add non existing data:

SELECT * FROM populate_from_json('
[
  {
    "nickname": "lrg",
    "name": "Leia",
    "surname": "Organa",
    "articles": [
      {
        "title": "How to defeat empire",
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
');

PREPARE "count_leia_articles" AS
SELECT COUNT(*)::int AS "count" FROM "public"."articles"
WHERE "account_id" IN (
  SELECT "id" FROM "public"."accounts"
  WHERE "nickname" = 'lrg'
);

SELECT results_eq(
  'count_leia_articles',
  ARRAY[1],
  'Leia should own 1 article'
);

SELECT * FROM finish();
ROLLBACK;

