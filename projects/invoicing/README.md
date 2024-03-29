# SQL - Advanced Examples

A list of "advanced" examples.

## On This Page

- [SQL - Advanced Examples](#sql---advanced-examples)
  - [On This Page](#on-this-page)
  - [Quick Start](#quick-start)
  - [Basic Concepts](#basic-concepts)
    - [Values](#values)
    - [Sub Queries](#sub-queries)
    - [Common Table Expressions](#common-table-expressions)
  - [Joins](#joins)
    - [Cartesian Product](#cartesian-product)
    - [Natural Join](#natural-join)
    - [Join](#join)
    - [Left/Right Join](#leftright-join)
    - [Full Outer Join](#full-outer-join)
    - [Lateral Join](#lateral-join)
  - [Generate Series \& Random](#generate-series--random)
  - [Realistic Data Seeding](#realistic-data-seeding)
  - [Data Seeding for Load Tests](#data-seeding-for-load-tests)
  - [Index Playground](#index-playground)
    - [Search by Value \& Sequential Scan](#search-by-value--sequential-scan)
    - [High Cardinality](#high-cardinality)
    - [Low Cardinality](#low-cardinality)
    - [Medium Cardinality](#medium-cardinality)
    - [Sorting](#sorting)
    - [Numbers](#numbers)
    - [Index Sizes](#index-sizes)
    - [Insert Performance](#insert-performance)
    - [Index Only Scan](#index-only-scan)
    - [Composite Indexes](#composite-indexes)
  - [Checks Constraints](#checks-constraints)
  - [Custom Types](#custom-types)
  - [For Update Skip Locked](#for-update-skip-locked)
  - [Documents](#documents)

## Quick Start

From the CLI interface:

```bash
# Change the current project
make project from=sql-advanced

# Start the project & work with it
make start
make reset
```

## Basic Concepts

### Values

You can generate datasets using `VALUES`:

```sql
VALUES 
  (1, 'Red'),
  (2, 'Green'),
  (3, 'Blue'),
  (4, 'Yellow');
```

But this will yield unknown columns.

Here is a refined version in which we add column names to it:

```sql
SELECT * FROM (VALUES 
  (1, 'Red'),
  (2, 'Green'),
  (3, 'Blue'),
  (4, 'Yellow')
) AS t(id, color);
```

And you can go the extra mile and add types:

```sql
SELECT
  "c1"::integer AS "id",
  "c2"::text AS "color"
FROM (VALUES 
  (1, 'Red'),
  (2, 'Green'),
  (3, 'Blue'),
  (4, 'Yellow')
) AS t("c1", "c2");
```

And you can add your custom values in the mix:

```sql
SELECT
  "c1"::integer AS "id",
  "c2"::text AS "color",
  123 AS "static_number"
FROM (VALUES 
  (1, 'Red'),
  (2, 'Green'),
  (3, 'Blue'),
  (4, 'Yellow')
) AS t("c1", "c2");
```

Run this to see all the example at work:

```bash
make query from=001_values
```

### Sub Queries

Sub queries are useful into many dynamic data situation.

Let's say that we want to pick athletes that are higher than average:

```sql
SELECT "id", "name", "height" 
FROM "athletes"
WHERE "height" > (
  SELECT AVG("height") FROM "athletes"
);
```

Try this out:

```bash
make query from=002_sub-query
```

### Common Table Expressions

Common Table Expressions (CTEs) offer a way to improve readability on complex queries that may end up with multiple sub-queries:

```sql
WITH avg_height AS (
  SELECT AVG("height") AS avg_height_value FROM "athletes"
)
SELECT "id", "name", "height"
FROM "athletes", avg_height
WHERE "height" > avg_height.avg_height_value;
```

Try this out:

```bash
make query from=003_cte
```

> Generally speaking, CTEs have similar performances to the sub-query equivalent. But they are more readable.  
> 👉 USE CTEs 👈

I often use CTEs to generate datasets or parameters that I want to use inside a complex query. They are also extremely useful while generating random data seeds that necessitates of multiple and complex steps to reach a reasonably good dataset.


## Joins

### Cartesian Product

The cartesian product of 2 or more tables will combine every line of every table with every line of every other table.

```bash
make query from=010_cartesian
```

An interesting use case that I came across is to generate language combos out of a sinlge languages table.

```bash
make query from=011_languages
```

### Natural Join

This happens when you have matching columns in two different tables:

In a classing invoicing app, both the `invoices` and `lines` tables may have an `invoice_id` column. In such a case, a _natural join_ will do:

```sql
CREATE TABLE invoice (
  invoice_id INTEGER PRIMARY KEY,
  ...
);

CREATE TABLE lines (
  line_id INTEGER PRIMARY KEY,
  invoice_id INTEGER,
  ...
);

SELECT *
FROM invoice
NATURAL JOIN lines;
```

Try out the full example:

```bash
make query from=012_natural-join
```

### Join

You could have been achieved the very same result with a normal join such as:

```sql
SELECT *
FROM "invoices" 
JOIN "lines" ON "invoices"."invoice_id" = "lines"."invoice_id";
```

The reason why we see this join more often than a natural join is because more often than not the joining fields have different names in the different tables.

You can also assign aliases to the involved tables to make thinks easier to read:

```sql
SELECT *
FROM "invoices" AS "i"
JOIN "lines" AS "l" ON "i"."id" = "l"."invoice_id";
```

Last, you can use the aliases to reference the columns you want to extract:

```sql
SELECT 
  "i".*,
  "l"."line_id",
  "l"."product",
  "l"."quantity"
FROM "invoices" AS "i"
JOIN "lines" AS "l" ON "i"."id" = "l"."invoice_id";
```

Here is the full code:

```bash
make query from=013_join
```

### Left/Right Join

Joining tables yields results that are found in both tables. In the previous dataset there is an invoice to Charlie that has no lines. Using a normal join we would miss such result.

```sql
SELECT *
FROM "invoices" 
LEFT JOIN "lines" ON "invoices"."id" = "lines"."invoice_id";
```

Using `LEFT JOIN` shows also invoice n.3 - Charlie's - but without any associated line:

```
 id | customer | invoice_date | line_id | invoice_id | product | quantity 
----+----------+--------------+---------+------------+---------+----------
  1 | Alice    | 2022-01-01   |       1 |          1 | Apple   |        1
  1 | Alice    | 2022-01-01   |       2 |          1 | Banana  |        2
  2 | Bob      | 2022-01-02   |       3 |          2 | Cherry  |        1
  2 | Bob      | 2022-01-02   |       4 |          2 | Date    |        3
  3 | Charlie  | 2022-01-03   |         |            |         |    
```

The `RIGHT JOIN` works the other way around:

```sql
SELECT *
FROM "invoices" 
RIGHT JOIN "lines" ON "invoices"."id" = "lines"."invoice_id";
```

in our case, it highlights a data inconsistency because we have an invoice line that refers to a non existing invoice:

```
 id | customer | invoice_date | line_id | invoice_id | product | quantity 
----+----------+--------------+---------+------------+---------+----------
  1 | Alice    | 2022-01-01   |       1 |          1 | Apple   |        1
  1 | Alice    | 2022-01-01   |       2 |          1 | Banana  |        2
  2 | Bob      | 2022-01-02   |       3 |          2 | Cherry  |        1
  2 | Bob      | 2022-01-02   |       4 |          2 | Date    |        3
    |          |              |       5 |         20 | Sausage |        3
```

> Note that this inconsistency would not be possible had we introduced relational constraints!

```bash
make query from=014_join-left-right
```

### Full Outer Join

This join basically combines left + right:

```sql
SELECT *
FROM "invoices" 
FULL OUTER JOIN "lines" ON "invoices"."id" = "lines"."invoice_id";
```

yielding:

```
 id | customer | invoice_date | line_id | invoice_id | product | quantity 
----+----------+--------------+---------+------------+---------+----------
  1 | Alice    | 2022-01-01   |       1 |          1 | Apple   |        1
  1 | Alice    | 2022-01-01   |       2 |          1 | Banana  |        2
  2 | Bob      | 2022-01-02   |       3 |          2 | Cherry  |        1
  2 | Bob      | 2022-01-02   |       4 |          2 | Date    |        3
    |          |              |       5 |         20 | Sausage |        3
  3 | Charlie  | 2022-01-03   |         |            |         |    
```

It produces matching and non matching rows from both sides.

```bash
make query from=015_outer-join
```

### Lateral Join

Lateral joins are the best of the bunch. It lets you run sub-queries that can reference the row matched by the first one.

```bash
make query from=016_lateral-join
```

## Generate Series & Random

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

## Realistic Data Seeding

Let's operate on a simple schema for managing users:

```sql
-- Define a simple data structure:
DROP TABLE IF EXISTS "users";
CREATE TABLE "users" (
  "id" SERIAL PRIMARY KEY,
  "name" TEXT NOT NULL UNIQUE, -- extremely high cardinality
  "gender" TEXT NOT NULL, -- extremely low cardinality
  "date_of_birth" DATE NOT NULL, -- high cardinality
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

## Data Seeding for Load Tests

When playing around with seeds for load testing, it's a good idea to turn off logging:

```sql
ALTER TABLE "users" SET UNLOGGED;
```

When you are done, turn it back on:

```sql
ALTER TABLE "users" SET LOGGED;
```

## Index Playground

Before proceeding, create `users` and `users_idx` with the same structure as before.

👉 Let's insert at least `1.000.000` records in each table.

```bash
make query from=300_schema
```

### Search by Value & Sequential Scan

The first type of query that we can run is an exact match for a value.

The idea is to run the query to fetch some data, and then play with a possible index to see if we can speed up the situation.

Let's start with some basic queries that search for a straight match for a specific value:

```sql
EXPLAIN ANALYZE
SELECT * FROM "users"
where "id" = 500
LIMIT 1;

EXPLAIN ANALYZE
SELECT * FROM "users"
where "uuid" = 'eb1851f4-be69-fccb-16f3-85b0741689e2'
LIMIT 1;

-- more examples in the source code!
```

```bash
make query from=301_search
```

```
                                                QUERY PLAN                                                
----------------------------------------------------------------------------------------------------------
 Limit  (cost=0.00..120.10 rows=1 width=54) (actual time=6.658..6.659 rows=0 loops=1)
   ->  Seq Scan on users  (cost=0.00..2402.00 rows=20 width=54) (actual time=6.658..6.658 rows=0 loops=1)
         Filter: (favourite_word = 'word-3676*'::text)
         Rows Removed by Filter: 100000
 Planning Time: 0.064 ms
 Execution Time: 6.668 ms
(6 rows)
```

The most interesting part here is `Seq Scan` which implies that the db will have to traverse the entire dataset and read from disk.

Whan can impact performances during a full-scan?

- early hits with `LIMIT=1` make good performances because the search can safely stop
- searches for non-existing values make poor performances because it forces a full-scan

👉 Always set `LIMIT=1` if you know in advance that there is max 1 result for a given search.

### High Cardinality

Let's now focus on the field `uuid` and `name` which has a **high cardinality**.

> _Cardinality_ measures uniqueness of the values withing a column. The highes the amount of unique values, the highest the cardinality.

From ChatGPT I learn that `b-tree` and `hash` should be good indexes for this kind of situation:

```sql
CREATE INDEX "users_idx_1_uuid_btree" ON "users_idx_1" USING btree ("uuid");
CREATE INDEX "users_idx_2_uuid_hash" ON "users_idx_2" USING hash ("uuid");
```

```bash
make query from=302_uuid
make query from=303_name
```

and we run queries like:

```sql
EXPLAIN ANALYZE
SELECT *
FROM "users_idx_2"
where "name" = 'User-9999'
LIMIT 10;
```

that yields a plan like:

```
-------------------------------------------------------------------------------------------------------------------------------------------
 Limit  (cost=0.42..8.44 rows=1 width=54) (actual time=0.047..0.048 rows=1 loops=1)
   ->  Index Scan using users_idx_1_name_btree on users_idx_1  (cost=0.42..8.44 rows=1 width=54) (actual time=0.047..0.047 rows=1 loops=1)
         Index Cond: (name = 'User-20999'::text)
 Planning Time: 0.298 ms
 Execution Time: 0.057 ms
(5 rows)
```

The most interesting part is `Index Scan`; It tells us that Postgres will use a specific index to run that search, and it also gives us the name of the index.

> Setting good names for your idexes is an important debugging improvement!

The interesting result is that `hash` seems to outperform `btree` **if the value exists**.

Instead, the `LIMIT=1` seems to be less relevant when it comes to searching an indexed column

### Low Cardinality

Let's now take a look at the `gender` field that has a `CARDINALITY=3`:

- M
- F
- O

```bash
make query from=304_gender
```

In this case, we've added indexes all around and still the planner chooses to run `Seq scan` for values that are _LIKELY TO BE FOUND_ in the table. 

It's courious that values that are `UNLIKELY TO BE FOUND` (such as `M*`) will hit the index.

> The partial index on `users_idx_3` seems to be completly irrelevant for this level of cardinality.

👉 With this low level of cardinality a `btree` or `hash` index could help only in queries that are likely to hit no values. In a case such `gender` where we are likely to apply a `NOT NULL` and a `CHECK` indexes are completely useless!

Let's move to a higer cardinality (`CARDINALITY=10`) with the `favourite_color` field:

```bash
make query from=305_color
```

And we basically have the same result.

### Medium Cardinality

Let's move to a even higher cardinality (`CARDINALITY=5000`) with the `favourite_word`:

```bash
make query from=306_word
```

```
 Limit  (cost=4.45..40.59 rows=10 width=54) (actual time=0.010..0.010 rows=0 loops=1)
   ->  Bitmap Heap Scan on users_idx_1  (cost=4.45..76.73 rows=20 width=54) (actual time=0.009..0.009 rows=0 loops=1)
         Recheck Cond: (favourite_word = 'Word-1981'::text)
         ->  Bitmap Index Scan on users_idx_1_favourite_word_btree  (cost=0.00..4.44 rows=20 width=0) (actual time=0.008..0.008 rows=0 loops=1)
               Index Cond: (favourite_word = 'Word-1981'::text)
 Planning Time: 0.143 ms
 Execution Time: 0.027 ms
(7 rows)
```

The important part is `Bitmap Index Scan on users_idx_1_favourite_word_btree`.

🎉 Finally we hit a level of cardinality for which the planner takes our indexes into account! 🎉

Here we also notice that `b-tree` outperforms `hash` (remember that with high cardinality is the other way around).

We get the best possible performances with the **partial index**:

```sql
CREATE INDEX "users_idx_3_favourite_word_part"
ON "users_idx_3" ("favourite_word") 
WHERE "favourite_word" = 'Word-1981';
```

But this is a delicate situation because we can not create 5000 partial indexes!

> Partial indexes are great with composite conditions.

### Sorting

Let's now stick to simple searches, but let's add the sorting instruction into our queries.

After all, this is a classic: _Give me the first 10 users that have been born in 1981_

```sql
SELECT * FROM "users"
WHERE "date_of_birth" >= '1981-06-30'
ORDER BY "date_of_birth" ASC
LIMIT 10;
```

and the index:

```sql
CREATE INDEX "users_idx_1_date_of_birth_btree"
ON "users_idx_1" 
USING btree ("date_of_birth");
```

```bash
make query from=307_date1
make query from=307_date2
```

The first test only uses the `>=` constraint. The second also adds the `ORDER BY` clause.

It is very clear that the `ORDER BY` is increasing computation time dramatically for a `Seq scan`.

It is also clear that the `hash` index is ignored, it's simply not useful in situations in which the order is important.

For this kind of queries, `b-tree` indexes are best.

### Numbers

Numbers and indexes are a weird animal.

```bash
make query from=308_numbers1
make query from=308_numbers2
make query from=308_numbers3
```

- `hash` and `b-tree` are almost the same when it comes to equality `=` comparision
- `hash` is irrelevant when sorting (either `>` or `ORDER BY`)
- _partial indexes_ can still speed up straight lookups, but could be messy with sorted data

> Actually, the partial b-tree applied to `users_idx_3` is worsening the performances by far!

### Index Sizes

We saw that indexing can speed up reads by much. 

But in Life nothing comes for free!

Let's now analyze the first downside of indexes:  
**DISK SPACE**

Let's begin with analyzing a table's metrics for disk utilization:

```sql
SELECT 
  table_name, 
  pg_size_pretty(pg_total_relation_size(table_name::text) - pg_indexes_size(table_name::text)) AS table_size
FROM (
  SELECT table_name
  FROM information_schema.tables
  WHERE table_schema = 'public'
) AS sub
ORDER BY table_name ASC;
```

```bash
make query from=320_size-tables
```

Running this query we can clearly see that the tables are exactly the same.

```
 table_name  | table_size 
-------------+------------
 users       | 9120 kB
 users_idx_1 | 9120 kB
 users_idx_2 | 9120 kB
 users_idx_3 | 9120 kB
```

And now we can get the same info relative to the indexes:

```sql
SELECT 
  indrelid::regclass AS table_name, 
  indexrelid::regclass AS index_name, 
  pg_size_pretty(pg_relation_size(indexrelid::regclass)) AS index_size
FROM pg_index
JOIN pg_class ON pg_class.oid = pg_index.indexrelid
JOIN pg_namespace ON pg_namespace.oid = pg_class.relnamespace
WHERE nspname = 'public'
ORDER BY table_name, index_name;
```

```bash
make query from=321_size-indexes
```

From this results, by instance, it appears clear that `hash` indexes are more expensive than `b-tree`.

```
 table_name  |             index_name             | index_size 
-------------+------------------------------------+------------
 users       | users_pkey                         | 2208 kB
 users_idx_1 | users_idx_1_uuid_btree             | 3104 kB
 users_idx_1 | users_idx_1_name_btree             | 3104 kB
 users_idx_1 | users_idx_1_gender_btree           | 696 kB
 users_idx_1 | users_idx_1_favourite_color_btree  | 696 kB
 users_idx_1 | users_idx_1_favourite_word_btree   | 840 kB
 users_idx_1 | users_idx_1_date_of_birth_btree    | 1488 kB
 users_idx_1 | users_idx_1_favourite_number_btree | 2208 kB
 users_idx_2 | users_idx_2_uuid_hash              | 4112 kB
 users_idx_2 | users_idx_2_name_hash              | 4112 kB
 users_idx_2 | users_idx_2_gender_hash            | 6064 kB
 users_idx_2 | users_idx_2_favourite_color_hash   | 6032 kB
 users_idx_2 | users_idx_2_favourite_word_hash    | 4120 kB
 users_idx_2 | users_idx_2_date_of_birth_hash     | 4112 kB
 users_idx_2 | users_idx_2_favourite_number_hash  | 4112 kB
 users_idx_3 | users_idx_3_gender_part            | 392 kB
 users_idx_3 | users_idx_3_favourite_color_part   | 88 kB
 users_idx_3 | users_idx_3_favourite_word_part    | 8192 bytes
 users_idx_3 | users_idx_3_favourite_number_part  | 8192 bytes
```

So the general rule of the thumb is that indexes require more disk space, and more important, more IOPS!!!

Here is a convenient query to check out disk-size stats for your db:

```bash
make query from=322_stats
```

### Insert Performance

```bash
make bench numTransactions=100 from=323_insert1
make bench numTransactions=100 from=323_insert2
make bench numTransactions=100 from=323_insert3
make bench numTransactions=100 from=323_insert4
```

Here are the results running this on GitHub Codespaces:  
(and I ran those commands multiple times to average out)

|    Table    |  Ops    | Index   |
|-------------|---------|---------|
| users       |  72.94  | none    |
| users_idx_1 |  30.78  | btree   |
| users_idx_2 |  10.46  | hash    |
| users_idx_3 |  74.85  | partial |

The `hash` index yields the worst possible write performances, while adding a few `b-tree` indexes already cut the write performances in half.

While writing data, all the relative indexes must be written as well. 

### Index Only Scan

So far we ran queries that fetch the entire dataset using `SELECT *`.

This is a convenient choice during an exercise, but it is almost inevitably a poor choice in your software.

Controlling the dataset that you need to extract may lead you to indexing choices such:

```sql
CREATE INDEX "users_idx_only" ON "users" USING btree ("name") 
INCLUDE ("date_of_birth");
```

This index definition is useful for searching over the `name` field as we saw before. But we are also asking the db to keep the `date_of_birth` together with the indexed data.

```bash
make query from=370_schema
```

Queries such:

```sql
SELECT *
FROM "users"
where "name" = 'User-100';
```

will benefit from the index as we saw before.

But more specific queries such:

```sql
SELECT "name", "date_of_birth"
FROM "users"
where "name" = 'User-999';
```

will hit an `Index Only Scan` that reduces the I/O by using only the index's data to return the full dataset.

```bash
make query from=370_query
```

> Including columns in an index will effectively create a sort of **sub-table** and data will be duplicated. This has downsides for bot disk-space and write performances.

### Composite Indexes

A composite index puts together multiple colums from the target table and looks like this:

```sql
CREATE INDEX "users_idx_comp" ON "users" 
USING btree ("name" ASC, "date_of_birth" DESC);
```

```bash
make query from=380_schema
```

This helps with composite filters such as:

```sql
SELECT *
FROM "users"
WHERE "name" = 'User-100'
  AND "date_of_birth" > '1980-01-01';
```

```bash
make query from=380_query
```

With recent versions of Postgres the order of the fields in the `WHERE` conditions is not relevant.

It is important to notice that you must use all the indexed columns in your query. If you don't, the planner will not use the index and you will end up with a sequential scan:

```sql
-- this query will NOT hit the index
SELECT *
FROM "users"
WHERE "date_of_birth" > '1980-01-01';
```

On the contrary, you can add more filters beyond the colums that are specified in the index and still benefit from it:

```sql
SELECT "name", "date_of_birth"
FROM "users"
WHERE "date_of_birth" > '1980-01-01'
  AND "name" = 'User-100'
  AND "gender" = 'M';
```

the execution plan looks like:

```
Index Scan using users_idx_comp on users  (cost=0.42..8.44 rows=1 width=14) (actual time=0.010..0.010 rows=0 loops=1)
  Index Cond: ((name = 'User-100'::text) AND (date_of_birth > '1980-01-01'::date))
  Filter: (gender = 'M'::gender)
Planning Time: 0.072 ms
Execution Time: 0.018 ms
```

Here we can see that the index is hit by the first 2 conditions, then the `gender` is applied to the data out of the filter.

> You should play smart with indexes and use them to reduce the data space on which to apply further filtering. Indexes should rule out big chunks of data, but you can't add an index for every possible query. Not only you will consume a lot of disk and choke your writing performances, but you can also quickly **run out of IOPS credits** on Cloud based virtual discs!


## Checks Constraints

A way to improve the previous schema would be to apply static checks for the low cardinality of the `gender`:

```sql
"gender" TEXT CHECK (gender IN ('M', 'F', 'O')),
```

Here is the query to create the new schema:

```bash
make query from=400_schema
```

Unfortunately, as the following query demonstrates, the checks are not used at read-time to avoind going through the entire dataset when looking for a value that is not possible anyway:

```bash
make query from=401_gender
```

> Checks constraints are great to ensure data integrity at write-time, but can't offer help while reading.

## Custom Types

Another possibility to improve things is to define a **custom type** for low cardinality fields:

```sql
CREATE TYPE GENDER AS ENUM ('M', 'F', 'O');

CREATE UNLOGGED TABLE "users" (
  ...
  "gender" GENDER,
```

Here is the query to create the new schema:

```bash
make query from=410_schema
```

This approach has the advantage that queries that try to search for values that can not exists will fail:

```bash
make query from=411_gender
```

Although custom types make for a great way to add strict rules to the values for low cardinality fields, they might become quite cumbersome when it comes the time to make changes:

```sql
ALTER TYPE GENDER ADD VALUE 'I am a Fridge';
```

It is also NOT POSSIBLE to remove a value from an existing ENUM (custom type).

In such a case, you must create a new TYPE, switch it into the table, then delete the previous one.

```sql
-- Create the new ENUM type without 'M'
CREATE TYPE GENDER_NEW AS ENUM ('F', 'O', 'Fridge');

-- Update the table to use the new ENUM type
ALTER TABLE "users" ALTER COLUMN "gender" TYPE GENDER_NEW USING "gender"::text::GENDER_NEW;

-- Drop the old ENUM type
DROP TYPE GENDER;

-- Rename the new ENUM type to the original name
ALTER TYPE GENDER_NEW RENAME TO GENDER;
```

Also, you would have to first update the rows that refer to the value that you want to remove. 

This could be a real pain!

```sql
UPDATE "users" SET "gender" = 'Fridge' WHERE "gender" = 'M';
```

## For Update Skip Locked

One of the most powerful inventions of humankind are queues. 

In nature everything happens at once, usually with violent and devastating effects. But we've learned to harness this messy situation and quietly perform one task at the time. Slow and steady wins the race, isn't that right? Right?

Let's explore queues in Postgres using a simple schema:

```sql
-- Super duper simple tasks management
CREATE TABLE tasks (
  "id" SERIAL PRIMARY KEY
);

-- Insert 3 tasks
INSERT INTO tasks DEFAULT VALUES;
INSERT INTO tasks DEFAULT VALUES;
INSERT INTO tasks DEFAULT VALUES;
```

This is enough to play with, for we are going to use some simple magic tricks to makes the common problems evident.

Now, it's not really important _WHAT_ we are going to do with our tasks. What really matters is that performed **one task should be once**.

So our "task" will simply append the _TaskID_ into a log table that offer no constraints:

```sql
CREATE TABLE logs (
  "value" INTEGER
);
```

You can create the schema with:

```bash
make query from=500_schema
```

Let's now create our task implementation using a CTE:

```sql
WITH
-- Pick the next task to run:
"pick_task" AS (
  SELECT * FROM "tasks"
  ORDER BY "id"
  LIMIT 1
),
-- Simulate a very slow job:
"slow_log" AS (
  INSERT INTO "logs"
  SELECT "id" FROM "pick_task", pg_sleep(5)
  returning *
)
-- Complete the task:
DELETE FROM "tasks"
WHERE "id" IN (SELECT "value" FROM "slow_log")
RETURNING CONCAT('Completed TaskID: ', "id");
```

Run this from multiple terminal windows.

```bash
make query from=500_worker
```

> We set a sleep time of 5 seconds so you have plenty of time to run it from multiple terminals.
> You can also increase this time to make it more comfortable.

👉 I want you to understand that this is not how we should test for concurrency In Real Life. This is a super-duper simple and slow didactical implementation 👈

Anyway, once you run the worker 3 times, the `tasks` table should be empty, and the `logs` table should contain `1, 2, 3`, right? Because only 3 tasks were to be executed.

🧐 But in the `logs` table we have a situation like `1, 1, 2, 2, 3, 3`. 🧐

**Each task has been executed twice!**  
<small>_Well, it depends how many clients did you run._</small>


Let's now introduce `FOR UPDATE SKIP LOCKED`:

```sql
WITH
"pick_task" AS (
  SELECT * FROM "tasks"
  ...
  FOR UPDATE SKIP LOCKED
),
```

Run it again from multiple clients:

```bash
make query from=500_worker-safe
```

🤪 This is as close as it can get to a freakin **magic spell**.

Postgres manages our behalf a **row-level lock** for all the lines identified by the `SELECT` (that's the `FOR UPDATE` part), but also skips any already locked row (that's the `SKIP LOCKED`).

Let's break this down into two different queries to better understand it.  
<small>(Reset your schema `make query from=500_schema`)</small>

The first query is designed to acquire the lock as first thing, then to await some time before releasing it:

```sql
WITH "data" AS (
  SELECT * FROM "tasks"
  ORDER BY "id"
  LIMIT 1
  FOR UPDATE
)
SELECT "id" FROM "data", pg_sleep(5);
```

And the second is even simpler because there is no awaiting time. This one is designed to run fast and demonstrate the different visibile rows while the first query blocks some of them:

```sql
SELECT * FROM "tasks"
ORDER BY "id"
FOR UPDATE SKIP LOCKED;
```

You can play with those:

```bash
make query from=501_lock
make query from=501_read
```

## Documents

