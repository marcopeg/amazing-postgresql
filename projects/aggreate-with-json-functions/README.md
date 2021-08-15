# Aggregate With JSON Functions


Nice query to figure out insert order with foreign keys:
https://www.cybertec-postgresql.com/en/postgresql-foreign-keys-and-insertion-order-in-sql/

## Using the function "unnest()"

The function `unnest()` explodes an array value into rows:

```sql
SELECT unnest(ARRAY[1, 2, 3])::INT AS "num";
```

yelds:

num |
:---:
1
2
3

This could be useful to mess with an imput that had nested information:

```sql
WITH "raw_data" ("character", "movies") AS (
  VALUES
    ('luke', ARRAY[4, 5, 6]),
    ('padme', ARRAY[1, 2, 3]),
    ('obi-one', ARRAY[1, 2, 3, 4])
)
SELECT * FROM "raw_data";
```

yelds:

| character | movies |
| ---: | --- |
| luke | `{4,5,6}` |
| padme | `{1,2,3}` |
| obi-one | `{1,2,3,4}` |

You can explode the list of movies in which the charater appears by using `unnest`:

```sql
WITH "raw_data" ("character", "movies") AS (
  VALUES
    ('luke', ARRAY[4, 5, 6]),
    ('padme', ARRAY[1, 2, 3]),
    ('obi-one', ARRAY[1, 2, 3, 4])
)
SELECT 
	"character", 
	unnest("movies")::INT AS "movie" 
FROM "raw_data";
```

yelds:

| character | movie |
| ---: | :---: |
| luke | `4` |
| luke | `5` |
| luke | `6` |
| padme | `1` |
| padme | `2` |
| padme | `3` |
| obi-one | `1` |
| obi-one | `2` |
| obi-one | `3` |
| obi-one | `4` |

Now it becomes possible to query for the characters that appear in a specific movie:

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

yelds:

| character | movies |
| ---: | --- |
| luke | `{4,5,6}` |
| obi-one | `{1,2,3,4}` |

Things become more interesting if we want to provide a richer input data set, let's say that we know how many scenes per movie are played by a specific character:

```sql
VALUES
  ('luke', ARRAY[(4, 55), (5, 34), (6, 76)]),
  ('padme', ARRAY[(1, 20), (2, 37), (3, 18)]),
  ('obi-one', ARRAY[(1, 24), (2, 35), (3, 88), (4, 14)])
```

each tuple `(4, 55)` means `(movie, num_scenes)`, and now we would like to work out a data structure similar to the following:

| character | movie | scenes |
| ---: | :---: | :---: |
| luke | `4` | `55` |
| luke | `5` | `34` |
| ... | ... | ... |

We first need to describe the tuple that we are using as a _type_:

```sql
CREATE TYPE "appearance" AS ("movie" INT, "scenes" INT);
```

And then we can create the proper structure:

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
````

yelds:

| character | appearances | movies |
| ---: | :---: | --- |
| padme | `75` | `{1,2,3}` |
| luke | `165` | `{4,5,6}` |
| ... | ... | ... | ... |