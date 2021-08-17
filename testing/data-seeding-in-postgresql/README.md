# Data Seeding in PostgreSQL

## Generate Series

A first useful resource is `generate_series()` which creates n-th amount of values that we can easily manipulate to compose a dummy dataset:

```sql
SELECT * FROM generate_series(1,10) "id";
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
FROM generate_series(1,10) "id";
```

| id  | username |
|:---:|----------|
|  1  | user-1   |
|  2  | user-2   |
| ... | ...      |

## Pick a Radom Array Item

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

## Generate a Random Number

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
  (
  	SELECT floor(random() * (99 - 18 + 1) + 18)::int
  	WHERE "id" = "id"
  ) AS "age"
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
  	SELECT DATE_TRUNC(
  	  'day',
  	  NOW() - INTERVAL '1y' * (
        SELECT floor(random() * (99 - 18 + 1) + 18)::int
        WHERE "id" = "id"
      )
    )
  ) AS "bday"
FROM generate_series(1,10) "id";
```

| id  | bday                   |
|:---:|------------------------|
|  1  | 1963-08-17 00:00:00+00 |
|  2  | 1928-08-17 00:00:00+00 |
| ... | ...                    |

## Row by Row or Query by Query?

You may have noticed a weird `WHERE "id" = "id"` statement in the random related queries.

That forces PostgreSQL to generated different random results **for every row** instead of calculating a static value for the entire query.

Try to comment it out...  
and check the results!

## Composing Queries 

Let's say that we want to compose a few fields out of the user's age:

- `username + year of birth` as in "Luke99"
- year of birth
- current age

That is not really achievable within one single query, or I haven't been able to find a way to cross reference generated values in colums on the fly.

But the [`WITH`][with] statement comes in handy here as we can prepare statements and use them in subsequent queries:

```sql
WITH 
-- Static Data
-- (we use this as source for dictionary-based randomic selections)
 "static_data"("doc") AS ( VALUES ('{
    "tot_users": 100,
    "usernames": [
      "Luke",
      "Leia",
      "Darth",
      "Han",
      "Obi-One"
    ],
    "countries": ["it","us","fr","es","de","se","dk","no"]
  }'::json))

-- Randomic Data
-- this is where we generate the data-set, with random values and
-- also some support data structures from the static data
, "randomic_data" AS (
    SELECT
      "id",
      (
        SELECT floor(random() * (99 - 18 + 1) + 18)::int
        WHERE "id" = "id"
      ) AS "age"
    -- Casting static data to PostgreSQL's ARRAY will
    -- facilitate a lot the randomization of dictionary-based values
    , (
        SELECT ARRAY(SELECT json_array_elements_text("doc"->'usernames')) FROM "static_data"
      ) AS "usernames_values"
    , (
        SELECT json_array_length("doc"->'usernames') FROM "static_data"
      ) AS "usernames_length"
    , (
        SELECT ARRAY(SELECT json_array_elements_text("doc"->'countries')) FROM "static_data"
      ) AS "countries_values"
    , (
        SELECT json_array_length("doc"->'countries') FROM "static_data"
      ) AS "countries_length"
    FROM generate_series(1, (
      SELECT ("doc" -> 'tot_users')::text::int from "static_data"
    )) "id"
  )

-- Users Dataset
-- we can finally generate a dataset that can populate our "users" table:
, "users_dataset" AS (
    SELECT
      -- User ID
      -- (reporting from the generated values)
      "id"

      -- Username 
      -- (random value from a list + year of birth)
    , (
        CONCAT(
          (
            SELECT ("usernames_values")[floor(random() * ("usernames_length") + 1)]
            WHERE "id" = "id"
          ),
          '_',
          TO_CHAR(
            NOW() - INTERVAL '1y' * "age"
            ,'YY'
          )
        )
      ) AS "uname"

    -- Year of Birth
    -- (current time minus random age)  
    , DATE_TRUNC(
        'day',
        NOW() - INTERVAL '1y' * "age"
    ) AS "bday"

    -- Age
    -- (reporting from the previous query)
    , "age"

    -- Country
    -- (random value from a list)
    , (
        SELECT ("countries_values")[floor(random() * ("countries_length") + 1)]
        WHERE "id" = "id"
      ) AS "country"
    FROM "randomic_data"
  )

-- >> Output >>
SELECT * FROM "users_dataset";
```

In this query we leverage on PostgreSQL' JSON capabilities to provide the settings of our seeding to the seeding query.
This includes dictionaries and amount of data that we want to generate.

> 👉 I also like to use `WITH` for composing my query logic while exploring a problem. I can divide a problem into small chunks and apply the [SRP][srp] principle. Once every step is done, and I have my solution covered with **unit tests**, I move into a refactoring phase where I do my best improving the performances.
