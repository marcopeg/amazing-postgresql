# Data Seeding in PostgreSQL

Seeding data is a very complicated job for the following reasons:

- You would like realistic data but also randomic values
- Data has relations and constraints that you need to respect
- Data may have to respect weird business rules
- You may want to insert s**t tons of data to run load tests

In this project we aim to populate a basic social network data set, with users that can follow users. Here are the business rules:

- Users must be between 18 and 99 years old
- Users can follow up to 10 other users

## Table of Contents

- [Prerequisites](#prerequisites)
- [Run the Project](#run-the-project)
- [Project's Structure](#projects-services)
- [Generate Data Series](#generate-data-series)
- [Pick a Random Array Item](#pick-a-random-array-item)
- [Generate Randomic Numbers](#generate-randomic-numbers)
- [Compose Queries With CTE](#compose-queries-with-cte)

---

## Prerequisites

The following notes are written using MacOS as running environment and assume you have the following software installed on your machine:

- [Docker Compose][docker-compose]
- [Make][make]

👉 [Read about the general prerequisites here. 🔗](../../README.md#prerequisites-for-running-the-examples)

---

## Run the Project

This project comes as a composition of services that are describe as a [`docker-compose`][docker-compose] project.

> You need to run all the services in order to follow the rest of this document.

```bash
# Builds and run all the services involved in this project
# (it uses `docker-compose` under the hood)
make start

# Stops and removes all the services involved in this project
make stop

# Populate the database with randomic data
# (will reset the database)
make seed

# Increment the amount of data in the db
# (will NOT reset the database)
make fill

# Build the project and run the unit tests
make test
```

---

## Project's Structure

In the folder `/seed` you find the full seeding scripts that populate the schema.

There are a few basic unit tests to progressively test the CTEs.

---

## Generate Data Series

A first useful resource is `generate_series()` which creates n-th amount of values that we can easily manipulate to compose a dummy dataset:

```sql
SELECT * FROM generate_series(1, 10) "id";
```

| id  |
|:---:|
|  1  |
|  2  |
| ... |

You can then add custom fields:

```sql
SELECT
	"id",
	CONCAT('user', '-', "id") AS "uname"
FROM generate_series(1, 10) "id";
```

| id  | username |
|:---:|----------|
|  1  | user-1   |
|  2  | user-2   |
| ... | ...      |

Here is an article on the generation of randomic sequences:  
https://dataschool.com/learn-sql/random-sequences/

## Pick a Random Array Item

Let's say we want to add a country code to our users dataset:

```sql
SELECT
  "id",
  (
    SELECT (array['it', 'us', 'fr', 'se', 'no'])[floor(random() * 5 + 1)]
    WHERE "id" = "id"
  ) as "country"
FROM generate_series(1,10) "id";
```
	
| id  | country |
|:---:|:-------:|
|  1  |   it    |
|  2  |   se    |
| ... |   ...   |

## Generate Randomic Numbers

Another useful trick in the bag is **generating random numbers**.

Here are a few queries you can check out:

```sql
-- random number between 0-1
SELECT random();

-- random integer between 1-10
SELECT floor(random() * 10 + 1)::int;

-- random integer between 10-20
SELECT floor(random() * (20 - 10 + 1) + 10)::int;
```

Let's say we want to add an `age` field, and age should be in the 18-99 range:

```sql
SELECT
  "id",
  floor(random() * (99 - 18 + 1) + 18)::int AS "age"
FROM generate_series(1,10) "id";
```

| id  | age |
|:---:|:---:|
|  1  | 34  |
|  2  | 27  |
| ... | ... |

Another possibility is to generate a random birthday for the user:

```sql
SELECT
  "id",
  (
  	DATE_TRUNC(
  	  'day',
  	  NOW() - INTERVAL '1d' * (
        floor(random() * (99 * 365 - 18 * 365 + 1) + 18 * 365)::int
      )
    )
  ) AS "bday"
FROM generate_series(1,10) "id";
```

| id  | bday                   |
|:---:|------------------------|
|  1  | 1963-07-24 00:00:00+00 |
|  2  | 1928-08-17 00:00:00+00 |
| ... | ...                    |


## Compose Queries With CTE

Let's say that we want to compose a few fields out of the user's age:

- `username + year of birth` as in "Luke_99"
- year of birth
- current age

That is not really achievable within one single query, or I haven't been able to find a way to cross reference generated values in colums on the fly.

But the [`WITH`][with] statement comes in handy here as we can prepare statements and use them in subsequent queries:

```sql
WITH
  -- Generate a list of random numbers:
  "randomic_data" AS (
    SELECT floor(random() * 10 + 1)AS "rand"
    FROM generate_series(1,10) "id"
  )

  -- Use the row-by-row randomic number to compose
  -- realistic user information:
, "user_data" AS (
    SELECT
      -- randomic username
        (
          CONCAT(
            'user_',
            TO_CHAR(NOW() - INTERVAL '1y' * "rand" ,'YY')
          )
        ) AS "uname"

      -- randomic year of birth
      , DATE_TRUNC(
        'day',
        NOW() - INTERVAL '1d' * (
          floor(random() * ((
            ("rand" + 1) * 365
          ) - (
            "rand" * 365
          ) + 1) + (
            "rand" * 365
          ))::int
        )
      ) AS "bday"

      -- Also provide the simple age:
    , "rand" AS "age"

    -- Source values from the randomic list
    FROM "randomic_data"
  )

-- Eventually, use the generated dataset to populate a table
INSERT INTO "users" ("uname", "bday", "age")
SELECT * FROM "user_data"

-- NOTE: randomic values can easily generate duplicate!
ON CONFLICT ON CONSTRAINT "users_uname_key" DO NOTHING
RETURNING *;
```

This is also known as PostgreSQL CTE:

- [Official documentation][with]
- [Introductory tutorial](https://www.postgresqltutorial.com/postgresql-cte)

> 👉 I also like to use `WITH` for composing my query logic while exploring a problem. I can divide a problem into small chunks and apply the [SRP][srp] principle. Once every step is done, and I have my solution covered with **unit tests**, I move into a refactoring phase where I do my best improving the performances.
---

[with]: https://www.postgresql.org/docs/current/queries-with.html