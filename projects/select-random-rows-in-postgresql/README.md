# Select Random Rows in PostgreSQL

There are a few posts on StackOverflow that try to solve the "pick a random row" from a PostgreSQL table.
Here are a few considerations and a few tests around it.

## The Dumbest Way

By far, the easies and dumbest way to pick a single random row from a table is by choosing a random `OFFSET` and limit the query to 1 result:

```sql
SELECT * FROM "users_with_ids" 
OFFSET (SELECT floor(random() * 100 + 1))
LIMIT 1;
```

<iframe width="271" height="167" seamless frameborder="0" scrolling="no" src="https://docs.google.com/spreadsheets/d/e/2PACX-1vSnAnSugZhCOFeqEf4U59EW2LfVuMcWFmHcjDQ5ehfVB2zh2X03J0z21RpgZtNpEcEC_Jojji1YjKL8/pubchart?oid=1635017177&amp;format=interactive"></iframe>

## The Easiest Way

```sql
SELECT * FROM "my_table"
ORDER BY random()
LIMIT 1;
```

## The Smart Way

```sql
SELECT * FROM
  (
    SELECT (0 + trunc(random() * 1000)) AS "user_id"
    FROM generate_series(1, 10000)
    GROUP BY "user_id"
  ) AS "gs1"
JOIN "users_with_ids" USING ("user_id")
LIMIT 1;
```