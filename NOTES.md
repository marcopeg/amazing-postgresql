# Notes

Free resources, links and frustrated annotations while working on this project.

---

Nice query to figure out insert order with foreign keys:  
https://www.cybertec-postgresql.com/en/postgresql-foreign-keys-and-insertion-order-in-sql/

Article on random in PostgreSQL:  
https://www.simononsoftware.com/generating-random-data-in-postgresql/
https://dataschool.com/learn-sql/random-sequences/

Select random rows:  
https://stackoverflow.com/questions/8674718/best-way-to-select-random-rows-postgresql
https://newbedev.com/best-way-to-select-random-rows-postgresql

```sql
EXPLAIN ANALYSE 
WITH
  "estimates" AS (
    SELECT
      (
        SELECT reltuples AS ct FROM pg_class
        WHERE oid = 'public.users'::regclass
      ) AS "rows_count"
    , min("id") AS "id_min"
    , max("id") AS "id_max"
    , max("id") - min("id") AS "id_span"
    FROM "public"."users"
  )
, "random_sequence" AS (
    SELECT "id_min" + trunc(random() * "id_span")::int AS "id"
    FROM "estimates", generate_series(1, "rows_count"::int)
    GROUP BY 1
  )
, "random_rows" AS (
    SELECT * FROM "random_sequence" "r"
    JOIN "public"."users" USING ("id")
  )
SELECT * FROM "random_rows"
;

EXPLAIN ANALYSE
SELECT * FROM "users" ORDER BY random();
```

Tutorial on temporary tables:  
https://www.postgresqltutorial.com/postgresql-temporary-table/


Explanation on functions caching:  
https://www.enterprisedb.com/edb-docs/d/postgresql/reference/manual/13.1/plpgsql-implementation.html


Generate named columns:

```sql
SELECT 
  1,
  '{}'::json,
  'foo';
```

yields

```
 ?column? | json | ?column? 
----------+------+----------
        1 | {}   | foo
(1 row)
```

but you can assign names to the columns:

```sql
SELECT
  1 AS "c1",
  '{}'::json AS "c2",
  'foo' AS "c3";
```

yields

```
  c1 | c2 | c3  
----+----+-----
  1 | {} | foo
(1 row)
```

in a CTE:  
_this is useful to generate configs at the beginning of a CTE_

```sql
WITH
"config"("num", "doc") AS (VALUES (1::int, '{}'::json))
SELECT * FROM config;
```

yields

```
 num | doc 
-----+-----
   1 | {}
(1 row)
```