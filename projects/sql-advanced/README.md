# SQL - Advanced Examples

A list of "advanced" examples.

From the CLI interface:

```bash
# Change the current project
make project from=sql-advanced

# Start the project & work with it
make start
make reset
```

## Data Generation

Use `genereate_series` to create a solid foundation to dynamic data seeding:

```sql
SELECT generate_series(1, 10) "n";
```

```bash
make query from=101_generate-serie
```

Pair it with `random`:

```sql
SELECT generate_series(1, 10) AS "n", random() AS "r";
```

```bash
make query from=102_random-numbers
```

Combine different functions to get integers between 1-10:

```sql
SELECT "n", floor(random() * 10 + 1)::integer AS "r"
FROM generate_series(1, 10) "n";
```

```bash
make query from=103_random-integers
```

> `floor(random() * (MAX - MIN + 1) + MIN)`

Interpolate text to generate dynamic strings:

```sql
SELECT 
  "n", 
  concat('user-', "n") AS "user"
FROM generate_series(1, 10) "n";
```

```bash
make query from=104_usernames
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

```bash
make query from=105_random-years
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

```bash
make query from=106_random-dates
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

```bash
make query from=107_random-array-item
```

## Data Seeding

Let's operate on a simple schema for managing users:

```sql
-- Define a simple data structure:
DROP TABLE IF EXISTS "users";
CREATE TABLE "users" (
  "id" SERIAL PRIMARY KEY,
  "name" TEXT NOT NULL UNIQUE, -- extremely high cardinality
  "gender" TEXT NOT NULL, -- extremely low cardinality
  "date_of_birth" DATE NOT NULL, -- extremely high cardinality
  "favourite_color" TEXT, -- high(er) cardinality
  "favourite_number" INTEGER -- extremely high cardinality
);
```

```bash
make query from=200_schema-users
```

Now you can combine all the components above to generate a dynamic dataset with realistic data:

```sql
-- Seed the dataset with randomic data:
WITH "raw_data" AS (
  SELECT 
    ARRAY['Red', 'Green', 'Blue', 'Yellow', 'Purple', 'Orange', 'Pink', 'Brown', 'Grey', 'Black'] AS colors,
    extract(epoch from current_timestamp) AS "max_time",
    extract(epoch from (current_timestamp - interval '100 years')) AS "min_time"
)
INSERT INTO "users" ("name", "gender", "date_of_birth", "favourite_color", "favourite_number")
SELECT
  concat('User-', "n"),
  CASE
    WHEN random() < 0.4 THEN 'M'
    WHEN random() < 0.8 THEN 'F'
    ELSE 'O'
  END,
  to_timestamp("min_time" + (random() * ("max_time" - "min_time")))::date,
  colors[ceil(random() * array_length(colors, 1))::integer], -- low cardinality
  floor(random() * 999999999 + 1)::integer -- high cardinality
FROM generate_series(1, 10) "n", "raw_data"
returning *;
```

```bash
make query from=201_seed-users
```

## Massive Data Seeding

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

```bash
make query from=300_schema
```

A first execise is to get some users by `color`:

```sql
SELECT * FROM "users"
WHERE "favourite_color" = 'Black'
LIMIT 10;
```

```bash
make query from=301_colors-1k
```

There is not much difference because of the low cardinality.

Let's try to fool around with a high cardinality field:

```sql
SELECT * FROM "users"
WHERE "favourite_color" = 'Black'
LIMIT 10;
```

## Documents