# SQL - Advanced Examples

## Data Generation

Use `genereate_series` to create a solid foundation to dynamic data seeding:

```sql
SELECT generate_series(1, 10) "n";
```

Pair it with `random`:

```sql
SELECT generate_series(1, 10) AS "n", random() AS "r";
```

Combine different functions to get integers between 1-10:

```sql
SELECT
  "n",
  generate_series(1, 10) AS "n", 
  random() AS "r",
FROM generate_series(1, 10) "n"
;
```

Interpolate text to generate dynamic strings:

```sql
SELECT 
  "n", 
  concat('user-', "n") AS "user"
FROM generate_series(1, 10) "n"
;
```

Play with numbers to generate randomic years from the last century:

```sql
WITH "boundaries" AS (
  SELECT 
    extract(year from current_date) AS "max", 
    extract(year from current_date) - 100 AS "min"
)
SELECT 
  "n",
  floor(random() * ("max" - "min" + 1) + "min")::integer AS "r"
FROM generate_series(1, 10) "n", "boundaries";
```

Same concept with full dates:

```sql
WITH "boundaries" AS (
  SELECT 
    current_timestamp AS "max", 
    current_timestamp - interval '100 years' AS "min"
)
SELECT
  "n",
  "min" + (random() * ("max" - "min")) AS "date"
FROM generate_series(1, 10) AS "n", "boundaries";
```

Pick randomic values from an array:

```sql
WITH "raw_data" AS (
  SELECT ARRAY['Red', 'Blue', 'Green', 'Yellow', 'Orange', 'Purple', 'Brown', 'Black', 'White', 'Gray'] AS "colors"
)
SELECT 
  "colors"[floor(random() * array_length("colors", 1) + 1)::integer] AS "color"
FROM generate_series(1, 10) AS "n", "raw_data";
```

## Data Seeding

```sql
-- Define a custom type for the Gender:
CREATE TYPE GENDER AS ENUM ('Male', 'Female', 'Other');

-- Define a simple data structure:
CREATE TABLE "users" (
  "id" SERIAL PRIMARY KEY,
  "name" TEXT NOT NULL UNIQUE, -- extremely high cardinality
  "gender" GENDER, -- extremely low cardinality
  "date_of_birth" DATE NOT NULL, -- extremely high cardinality
  "favourite_color" TEXT, -- high(er) cardinality
  "favourite_number" INTEGER -- extremely high cardinality
);

-- Replace the dataset with randomic data:
TRUNCATE "users";
WITH "raw_data" AS (
  SELECT 
    ARRAY['Red', 'Green', 'Blue', 'Yellow', 'Purple', 'Orange', 'Pink', 'Brown', 'Grey', 'Black'] AS colors,
    extract(epoch from current_timestamp) AS "max_time",
    extract(epoch from (current_timestamp - interval '100 years')) AS "min_time"
)
INSERT INTO "users" ("name", "gender", "date_of_birth", "favourite_color", "favourite_number")
SELECT
  concat('User-', "n"),
  (CASE
    WHEN random() < 0.33 THEN 'Male'
    WHEN random() < 0.66 THEN 'Female'
    ELSE 'Other'
  END)::GENDER,
  to_timestamp("min_time" + (random() * ("max_time" - "min_time")))::date,
  colors[ceil(random() * array_length(colors, 1))::integer], -- low cardinality
  floor(random() * 999999999 + 1)::integer -- high cardinality
FROM generate_series(1, 10) "n", "raw_data"
returning *;
```

## Massive Data Seed

When playing around with seeds, it's a good idea to turn off logging:

```sql
ALTER TABLE "users" SET UNLOGGED;
```

When you are done, turn it back on:

```sql
ALTER TABLE "users" SET LOGGED;
```

## Indexes

Before proceeding, create `users` and `users_big` with the same structure as before.

👉 Insert `1000` records into `users`, and `1.000.000` into `users_big`.

🤖 You could also attempt creating a `users_huge` and insert tens of millions of rows.

A first execise is to get some users by `color`:

```sql
SELECT * FROM "users"
WHERE "favourite_color" = 'Black'
LIMIT 10;

SELECT * FROM "users_big"
WHERE "favourite_color" = 'Black'
LIMIT 10;
```

There is not much difference because of the low cardinality.

Let's try to fool around with a high cardinality field:

```sql

```

## Documents