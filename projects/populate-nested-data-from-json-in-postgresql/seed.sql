
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


-- INSERT MORE DATA
-- The function should ignore existing data by the unique key "nickname"
-- But should add non existing data:

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
