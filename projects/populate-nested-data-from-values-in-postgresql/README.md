# Populate Nested Data From _VALUES_ in PostgreSQL

We usually handle [normalized data](https://en.wikipedia.org/wiki/Database_normalization) when dealing with a relational database like [PostgreSQL][postgres]. 

A situation in which we have some login users with a profile who write blog articles will likely be described with 3 tables:

- _accounts_: contains login related info
- _profiles_: contains decorative info about the account
- _articles_: contains the list of blog posts

For my entire career, I've seen the following data-entry approach applied at application level (as in Go, NodeJS, .NET...):

- INSERT INTO _accounts_ and get the LAST CREATED ID
- INSERT INTO _profiles_, referencing the LAST CREATED ID
- INSERT INTO _articles_, referencing the LAST CREATED ID

> All these actions in separated queries, with or without a transaction, each with its own **round trip latency** and possibility for **networking errors**.

In this project, we assume that one or more users are ready to be created, some may even have a list of articles already.

We learn how to create the the complete dataset running a single round trip, leveraging on a few nice [PostgreSQL][postgres] features:

- [WITH][with]
- [VALUES][values]
- [unnest()](https://www.postgresql.org/docs/current/functions-array.html)
- [functions](https://www.postgresql.org/docs/current/sql-createfunction.html)

---

## Table of Contents

- [Prerequisites](#prerequisites)
- [Run the Project](#run-the-project)
- [Using the "unnest()" Function](#using-the-unnest-function)
- [Data Set as VALUES](#data-set-as-values)

---

## Prerequisites

The following notes are written using MacOS as running environment and assume you have the following software installed on your machine:

- [Docker][docker]
- [Make][make]

👉 [Read about the general prerequisites here. 🔗](../../README.md#prerequisites-for-running-the-examples)

---

## Run the Project

This project simulates a PostgreSQL extension with its own unit tests.  
Run the following commands to run it:

```bash
# Build the "pgtap" image and start PostgreSQL with Docker
make start

# Build the project and run the unit tests
make test

# Build the project and populate it with dummy data
# so that you can play with it using a client like PSQL
make seed

# Stop the running PostgreSQL and remove the container
# (data is still persisted to the local disk)
make stop
```

---

## Using the "unnest()" Function

The function `unnest()` explodes an array value into rows:

```sql
SELECT unnest(ARRAY[1, 2, 3])::INT AS "num";
```

| num |
|:---:|
|  1  |
|  2  |
|  3  |

This could be useful to mess with an imput that had nested information, like this one:

```sql
WITH "raw_data" ("character", "movies") AS (
  VALUES
    ('luke', ARRAY[4, 5, 6]),
    ('padme', ARRAY[1, 2, 3]),
    ('obi-one', ARRAY[1, 2, 3, 4])
)
SELECT * FROM "raw_data";
```

| character | movies      |
|----------:|-------------|
|      luke | `{4,5,6}`   |
|     padme | `{1,2,3}`   |
|   obi-one | `{1,2,3,4}` |

> 👉 Movies are coded in the story's chronological order. Movie n.`1` is the horrible _CGI_ ejaculation with _Jar Jar Binks_, while movie n.`4` is the majestic _A New Hope_, in which Luke destroys the Death Star.

You can explode the list of movies in which the charater appears by using `unnest`:

```sql
WITH 
-- input raw data:
  "raw_data" ("character", "movies") AS (
    VALUES
      ('luke', ARRAY[4, 5, 6]),
      ('padme', ARRAY[1, 2, 3]),
      ('obi-one', ARRAY[1, 2, 3, 4])
  )

-- compose a data structure in which to list each appearance:
SELECT 
	"character", 
	unnest("movies")::INT AS "movie" 
FROM "raw_data";
```

| character | movie |
|----------:|-------|
|      luke | `4`   |
|      luke | `5`   |
|     padme | `1`   |
|       ... | ...   |

Now it becomes possible to query for the characters that appears in a specific movie:

```sql
WITH 
-- input raw data:
  "raw_data" ("character", "movies") AS (
    VALUES
      ('luke', ARRAY[4, 5, 6]),
      ('padme', ARRAY[1, 2, 3]),
      ('obi-one', ARRAY[1, 2, 3, 4])
  )

-- compose a data structure with the full list of appearances:
, "appearances" ("movie", "character", "movies") AS (
	SELECT  
      unnest("movies")::INT AS "movie",
      "character", 
      "movies"
    FROM "raw_data"
)

-- show charater and movies, filtering by movie:
SELECT "character", "movies"
FROM "appearances" 
WHERE "movie" = 4;
```

| character | movies      |
|----------:|-------------|
|      luke | `{4,5,6}`   |
|   obi-one | `{1,2,3,4}` |

Things become more interesting as we want to provide **a richer input data set**. Let's say that we know how many scenes per movie are played by a specific character:

```sql
VALUES
  ('luke', ARRAY[(4, 55), (5, 34), (6, 76)]),
  ('padme', ARRAY[(1, 20), (2, 37), (3, 18)]),
  ('obi-one', ARRAY[(1, 24), (2, 35), (3, 88), (4, 14)])
```

> 👉 Each tuple `(4, 55)` means `(movie, num_scenes)`. As in "Luke played 55 scenes in _A New Hope_". 
>
> 🥸 These info are completely made up, please help me with a PR if you have better data!

And now we would like to work out a data structure similar to the following:

| character | movie | scenes |
|----------:|:-----:|:------:|
|      luke |  `4`  |  `55`  |
|      luke |  `5`  |  `34`  |
|       ... |  ...  |  ...   |

We first need to describe the tuple that we are using as a [_composite data type_](https://www.postgresql.org/docs/current/rowtypes.html):

```sql
CREATE TYPE "appearance" AS ("movie" INT, "scenes" INT);
```

After that, we can create the proper data structure:

```sql
WITH 
-- input raw data:
  "raw_data" ("character", "movies") AS (
    VALUES
      ('luke', ARRAY[(4, 55), (5, 34), (6, 76)]),
      ('padme', ARRAY[(1, 20), (2, 37), (3, 18)]),
      ('obi-one', ARRAY[(1, 24), (2, 35), (3, 88), (4, 14)])
  )

-- create the appearances data view:
SELECT
  "character",   
  (unnest("movies")::TEXT::"appearance").*
FROM "raw_data";
```

Now let's say that we need to calculate the total number of appearances for our characters:

```sql
WITH 
-- input raw data:
  "raw_data" ("character", "movies") AS (
    VALUES
      ('luke', ARRAY[(4, 55), (5, 34), (6, 76)]),
      ('padme', ARRAY[(1, 20), (2, 37), (3, 18)]),
      ('obi-one', ARRAY[(1, 24), (2, 35), (3, 88), (4, 14)])
  )

-- create the appearances data view:
, "appearances" AS (
    SELECT
      "character",   
      (unnest("movies")::TEXT::"appearance").*
    FROM "raw_data"
)

-- get the total appearances per character:
SELECT
  "character", 
  sum("scenes") AS "appearances",
  array_agg("movie" ORDER BY "movie" ASC) AS "movies"
FROM "appearances"
GROUP BY "character";
```

| character | appearances | movies    |
|----------:|:-----------:|-----------|
|     padme |    `75`     | `{1,2,3}` |
|      luke |    `165`    | `{4,5,6}` |
| ... | ... | ... | ... |

---

## Data Set as VALUES

PostgreSQL's [`VALUS`][values] let you define a data set on the fly:

```sql
VALUES
  ('Luke', 'Skywalker')
, ('Darth', 'Vader');
```

| column1 | column2   |
|---------|-----------|
| Luke    | Skywalker |
| Darth   | Vader     |

You can use it in combination with [`WITH`][with] to customize the columns names:

```sql
WITH
  "raw_data"("name", "surname") AS (
    VALUES
      ('Luke', 'Skywalker')
    , ('Darth', 'Vader')
  )
SELECT * FROM "raw_data"
```

| name  | surname   |
|-------|-----------|
| Luke  | Skywalker |
| Darth | Vader     |

In this project we use this strategy to provide a full data set of users, with their profiles and the articles that belong to them:

```sql
WITH 
  "raw_data" ("nickname", "name", "surname", "articles") AS (
    VALUES
      ('lsk', 'Luke', 'Skywalker', ARRAY [
        ('How to blow the Death Star', '...')
      , ('How to become a Jedi', '...')
      ])
    , ('hsl', 'Han', 'Solo', ARRAY [
        ('How to kiss Leia', '...')
    ])
  )
...
```

---

[postgres]: https://www.postgresql.org/
[docker]: https://www.docker.com/
[make]: https://www.gnu.org/software/make/manual/make.html
[with]: https://www.postgresql.org/docs/current/queries-with.html
[values]: https://www.postgresql.org/docs/current/sql-values.html