# Report Recent Orders Per User

In this project we dive into building a _JSON_ data report out of a simple USERS / ORDERS schema:

```
Report all the customers that placed at least three orders in the last week, and serve the data in JSON format, including the last three orders made by each user.
```

---

## Table of Contents

- [Prerequisites](#prerequisites)
- [Run the Project](#run-the-project)
- [Schema V1](#schema-v1)
- [Find Recent Orders](#find-recent-orders)
- [Get the Last Three Orders](#get-the-last-three-orders)
- [Window Functions To Rescue](#window-functions-to-rescue)
- [Lateral Join for Performances](#lateral-join-for-performances)
- [Order to JSON](#order-to-json)
- [One Row per User](#one-row-per-user)
- [Ordering By Nested Data](#ordering-by-nested-data)
- [Build the JSON report](#build-the-json-report)
- [Performance Analysis](#performance-analysis)

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

# Build the project and populate it with dummy data
# so that you can play with it using a client like PSQL
make seed
make seed file=randomic-100

# Run queries from the "query" folder:
make run file=query-name

# Stop the running PostgreSQL and remove the container
# (data is still persisted to the local disk)
make stop
```

---

## Schema V1

The schema for this project is rather simple:

- `users` will store user data
- `orders` will store orders placed by users

> The `UserID` will be a simple text like `Luke` as so to make it easier to produce fake data.

---

## Find Recent Orders

The first portion of the task requires us to identify orders that had been placed during the **last week**. This is just a matter of placing a relative time condition:

```sql
SELECT *
FROM "v1"."orders" AS "ord"
WHERE "ord"."date" >= now() - '1w'::interval;
```

```bash
make run file=001-latest-orders
```

[SQL source file 🔗](./query/001-latest-orders.sql)

It is interesting to note how we can simply cast a string to be used as [_interval_](https://www.postgresqltutorial.com/postgresql-tutorial/postgresql-interval/).

## At Least Three Orders

The second part of the task requires to list the users that had placed at least three orders during the last week.

A first step towards this goal would be to _GROUP_ the users and count how many orders were placed:

```sql
SELECT 
  "ord"."user_id",
  COUNT(*) AS "orders_count"
FROM "v1"."orders" AS "ord"
WHERE "ord"."date" >= now() - '1w'::interval
GROUP BY "ord"."user_id";
```

Now it would be a good time to start using a `CTE` with the goal of structuring our query:

```sql
WITH
"users_with_orders" AS (
  SELECT 
    "ord"."user_id" AS "id",
    COUNT(*) AS "orders_count"
  FROM "v1"."orders" AS "ord"
  WHERE "ord"."date" >= now() - '1w'::interval
  GROUP BY "ord"."user_id"
)
SELECT "id" 
FROM "users_with_orders"
WHERE "orders_count" >= 3;
```

Here we have isolated the list of users with at least 3 orders.

## Get the Last Three Orders

The third part of the tasks wants us to extract the __last three orders__ made by the users we found so far.

My first approach would be to join back with the `orders` table:

```sql
WITH
"users_with_orders" AS (
  SELECT 
    "ord"."user_id" AS "id",
    COUNT(*) AS "orders_count"
  FROM "v1"."orders" AS "ord"
  WHERE "ord"."date" >= now() - '1w'::interval
  GROUP BY "ord"."user_id"
),
"active_users" AS (
  SELECT "id" 
  FROM "users_with_orders"
  WHERE "orders_count" >= 3
)
SELECT *
FROM "active_users" AS "usr"
LEFT JOIN "v1"."orders" AS "ord" ON "usr"."id" = "ord"."user_id";
```

This query will get ALL the orders placed by the `active users`, but the task only requires us to show the **last three orders**.

Using a `LIMIT` won't work because it will put a constraint on the entire dataset, and we want such constraint to apply only to the "orders within each user"

We are back to the drawing board.

## Window Functions To Rescue

[Window functions](https://www.postgresqltutorial.com/postgresql-window-function/) help us working towards our solution. I found a similar problem [here](https://stackoverflow.com/questions/72533266/find-first-3-orders-for-each-customer) and applied the proposed approach to our problem:

```sql
SELECT
  *,
  row_number() OVER (
    PARTITION BY "ord"."user_id" 
    ORDER BY "ord"."date" DESC 
  ) AS "_rn"
FROM "v1"."orders" AS "ord"
WHERE "ord"."date" >= now() - '1w'::interval;
```

In the previous query we still get the full dataset for the orders within the last week, and we assign a progressive number to each one within isolated `user_id`-based groups.

We can now put things together and get the data we want:

```sql
WITH
"last_orders" AS (
  SELECT
    *,
    row_number() OVER (
      PARTITION BY "ord"."user_id" 
      ORDER BY "ord"."date" DESC 
    ) AS "_rn"
  FROM "v1"."orders" AS "ord"
  WHERE "ord"."date" >= now() - '1w'::interval
),
"users_orders" AS (
  SELECT
    "user_id", 
    COUNT(*) AS "tot_orders"
  FROM "last_orders"
  GROUP BY "user_id"
),
"active_users" AS (
  SELECT * FROM "users_orders"
  WHERE "tot_orders" >= 3
)
SELECT
  "ord"."id" AS "order_id",
  "ord"."date",
  "ord"."amount",
  "act"."user_id",
  "act"."tot_orders"   
FROM "active_users" AS "act"
LEFT JOIN "last_orders" AS "ord" ON "act"."user_id" = "ord"."user_id"
WHERE "_rn" <= 3;
```

NOTE: This works like a charm, but I've tested it with ~500k orders randomly spread over the course of 2 weeks and it turns out it is slow. ~2.3s average execution time.

> This approach could be used for slow queries on a read-only replica that is not intended to be used by a multi-tenant audience!

## Lateral Join for Performances

I found [yet another answer on StackOverflow](https://stackoverflow.com/questions/1124603/grouped-limit-in-postgresql-show-the-first-n-rows-for-each-group) that proposes a slightly different approach. It uses Lateral Join.

```sql
SELECT "last_orders".*
FROM (
  SELECT DISTINCT "user_id"
  FROM "v1"."orders"
) "users"
JOIN LATERAL (
  SELECT *
  FROM "v1"."orders" AS "ord"
  WHERE "ord"."user_id" = "users"."user_id"
    AND "ord"."date" >= NOW() - '1w'::interval
  ORDER BY "ord"."date" DESC
  LIMIT 3
) "last_orders" ON true;
```

This query gets me the last 3 orders for every user that made an order within the last week. The performances are dramatically improved from the previous approach.

We can rewrite the full query and have it spitting out the data in ~55ms!

```sql
WITH
"last_orders" AS (
  SELECT "last_orders".*
  FROM (
    SELECT DISTINCT "user_id" AS "id"
    FROM "v1"."orders"
  ) "usr"
  JOIN LATERAL (
    SELECT *
    FROM "v1"."orders" AS "ord"
    WHERE "ord"."user_id" = "usr"."id"
      AND "ord"."date" >= NOW() - '1w'::interval
    ORDER BY "ord"."date" DESC
    LIMIT 3
  ) "last_orders" ON true
),
"users_orders" AS (
  SELECT
    "user_id", 
    COUNT(*) AS "tot_orders"
  FROM "last_orders"
  GROUP BY "user_id"
),
"active_users" AS (
  SELECT * FROM "users_orders"
  WHERE "tot_orders" >= 3
)
SELECT
  "act"."user_id",
  "ord"."id" AS "order_id",
  "ord"."date",
  "ord"."amount"
FROM "active_users" AS "act"
LEFT JOIN "last_orders" AS "ord" ON "act"."user_id" = "ord"."user_id";
```

## Order to JSON

In this step we use the [`json_build_object()`](https://www.postgresql.org/docs/current/functions-json.html#:~:text=foo%22%2C%204%2C%205%5D-,json_build_object,-(%20VARIADIC%20%22any) function to transform the order details into a JSON object:

Here is the interesting portion of our query:

```sql
...
SELECT
  "act"."user_id",
  json_build_object(
    'id', "ord"."id",
    'date', "ord"."date",
    'amount', "ord"."amount"
  ) AS "order"
...
```

And here is the full version of it:

```sql
WITH
"last_orders" AS (
  SELECT "last_orders".*
  FROM (
    SELECT DISTINCT "user_id" AS "id"
    FROM "v1"."orders"
  ) "usr"
  JOIN LATERAL (
    SELECT *
    FROM "v1"."orders" AS "ord"
    WHERE "ord"."user_id" = "usr"."id"
      AND "ord"."date" >= NOW() - '1w'::interval
    ORDER BY "ord"."date" DESC
    LIMIT 3
  ) "last_orders" ON true
),
"users_orders" AS (
  SELECT
    "user_id", 
    COUNT(*) AS "tot_orders"
  FROM "last_orders"
  GROUP BY "user_id"
),
"active_users" AS (
  SELECT * FROM "users_orders"
  WHERE "tot_orders" >= 3
)
SELECT
  "act"."user_id",
  json_build_object(
    'id', "ord"."id",
    'date', "ord"."date",
    'amount', "ord"."amount"
  ) AS "order"
FROM "active_users" AS "act"
LEFT JOIN "last_orders" AS "ord" ON "act"."user_id" = "ord"."user_id";
```

## One Row per User

The result we got so far is not really fulfilling the assigment (yet). We need to output a single report, but so far we have one row per order.

A step towards the solution would be to `GROUP` our results `BY` the `user_id` and collect the list of orders as an `ARRAY` of some kind.

The grouping can be achieved by appending the relative instruction to our query:

```sql
GROUP BY "act"."user_id"
```

Next we need to aggregate the JSON `order` that we've previously built into an array using [`json_agg`](https://www.postgresql.org/docs/9.5/functions-aggregate.html#:~:text=equivalent%20to%20bool_and-,json_agg,-(expression)):

```sql
json_agg(
  json_build_object(
    'id', "ord"."id",
    'date', "ord"."date",
    'amount', "ord"."amount"
  )
) AS "orders"
```

Here is the full query:

```sql
WITH
"last_orders" AS (
  SELECT "last_orders".*
  FROM (
    SELECT DISTINCT "user_id" AS "id"
    FROM "v1"."orders"
  ) "usr"
  JOIN LATERAL (
    SELECT *
    FROM "v1"."orders" AS "ord"
    WHERE "ord"."user_id" = "usr"."id"
      AND "ord"."date" >= NOW() - '1w'::interval
    ORDER BY "ord"."date" DESC
    LIMIT 3
  ) "last_orders" ON true
),
"users_orders" AS (
  SELECT
    "user_id", 
    COUNT(*) AS "tot_orders"
  FROM "last_orders"
  GROUP BY "user_id"
),
"active_users" AS (
  SELECT * FROM "users_orders"
  WHERE "tot_orders" >= 3
)
SELECT
  "act"."user_id",
  json_agg(
    json_build_object(
      'id', "ord"."id",
      'date', "ord"."date",
      'amount', "ord"."amount"
    )
  ) AS "orders"
FROM "active_users" AS "act"
LEFT JOIN "last_orders" AS "ord" ON "act"."user_id" = "ord"."user_id"
GROUP BY "act"."user_id"
ORDER BY "act"."user_id" ASC;
```

## Ordering By Nested Data

After applying a `GROUP BY` instruction, we lose the possibility to sort by a single order's property.

Ordering the results by the User's ID is rather simple:

```sql
ORDER BY "act"."user_id" ASC
```

But if we want to sort by the most recent order, we have to use other aggregation functions:

```sql
SELECT
  ...
  min("ord"."date") AS "oldest_order",
  max("ord"."date") AS "latest_order"

...
ORDER BY "latest_order" DESC;
```

> NOTE: this will add on the computational efforts!

## Build the JSON report

The last step into fulfilling the requirement would be to nicely pack all those informations into one single JSON document.

We move the previous query into the CTE under the name `users_with_orders`, so to use it in a further JSON aggregation and produce the desired output:

```sql
...
SELECT
  json_build_object(
    'users', json_agg("record")
  ) AS "report"
FROM (
  SELECT
    json_build_object(
      'id', "user_id",
      'orders', "orders"
    ) AS "record"
  FROM "users_with_orders"
) t;
```

The sub-query `t` will simply rewrite each record into a JSON object, also skipping the `latest_order` info that we used for sorting purpose only.

Then we aggregate such results one more time in the final JSON document that will have the following structure:

```json
{
  "users": [
    {
      "id": "user-1",
      "orders": [
        {
          "id": 1500281,
          "date": "2022-12-20T17:22:32.349028+00:00",
          "amount": 232
        }
      ]
    }
  ]
}
```

Here is our final query:

```sql
WITH
"last_orders" AS (
  SELECT "last_orders".*
  FROM (
    SELECT DISTINCT "user_id" AS "id"
    FROM "v1"."orders"
  ) "usr"
  JOIN LATERAL (
    SELECT *
    FROM "v1"."orders" AS "ord"
    WHERE "ord"."user_id" = "usr"."id"
      AND "ord"."date" >= NOW() - '1w'::interval
    ORDER BY "ord"."date" DESC
    LIMIT 3
  ) "last_orders" ON true
),
"users_orders" AS (
  SELECT
    "user_id", 
    COUNT(*) AS "tot_orders"
  FROM "last_orders"
  GROUP BY "user_id"
),
"active_users" AS (
  SELECT * FROM "users_orders"
  WHERE "tot_orders" >= 3
),
"users_with_orders" AS (
  SELECT
    "act"."user_id",
    json_agg(
      json_build_object(
        'id', "ord"."id",
        'date', "ord"."date",
        'amount', "ord"."amount"
      )
    ) AS "orders"
  FROM "active_users" AS "act"
  LEFT JOIN "last_orders" AS "ord" ON "act"."user_id" = "ord"."user_id"
  GROUP BY "act"."user_id"
  ORDER BY "act"."user_id" ASC
)
SELECT
  json_build_object(
    'users', json_agg("record")
  ) AS "report"
FROM (SELECT
  json_build_object(
    'id', "user_id",
    'orders', "orders"
  ) AS "record"
FROM "users_with_orders") t;
```

---

## Performance Analysis

The first test that comes to mind increments both `users` AND `orders`. That is to simulate a realistic increasing load of a very successful online shopping enterprise.

In the last test, we run 100k users that place 2.7M orders within the last 2 weeks.
That is ~200k orders a day, or ~8000 orders per hour.  
👉 THAT IS A LOT

> For referece, Amazon.com produces approximately 66k orders per hour **world-wide**. 

|  users |  orders | Returned Rows | First Hit (ms) | Avg. Time (ms) |
|-------:|--------:|--------------:|---------------:|---------------:|
|      4 |      13 |             2 |             15 |              3 |
|    100 |   10500 |            70 |             18 |              7 |
|   1000 |  105000 |           679 |             60 |             44 |
|  10000 | 1050000 |          6775 |           1900 |            575 |
| 100000 | 2750000 |         52000 |         102000 |           8000 |

From this results, we clearly see a fast degrading of performances to a point in which this query is totally useless. (Not that this particular query would be run by every customer on every order... it's a reporting query and it would probably be run once per day or so...)

A second test involves keeping the users steady, and increment the amount of available orders. We fix the users at 1000:

|  orders | Returned Rows | Avg. Time (ms) |
|--------:|--------------:|---------------:|
|  105000 |           679 |             40 |
|  210000 |           906 |             60 |
|  315000 |           973 |             68 |
|  420000 |           996 |             68 |
|  630000 |           999 |             80 |
|  945000 |          1000 |            104 |
| 1455000 |          1000 |            150 |
| 1965000 |          1000 |            200 |
| 2970000 |          1000 |           1400 |

We grew a bit over the amount of orders that we had in the previous test, still we have nearly 5x better performances!

## Performance Decay with Orders Growth

The first thing that comes to mind is that the `SELECT DISTINCT "user_id" AS "id" FROM "v1"."orders"` may be _somewhat_ responsible.

On one side it guarantees that we run the `JOIN LATERAL` only for users that have orders, on the other, it is a taxing query for the DB to execute.

We can replace that with simple list of all the existing users:

```sql
"last_orders" AS (
  SELECT "last_orders".*
  FROM "v1"."users" AS "usr"
  JOIN LATERAL (
    SELECT *
    FROM "v1"."orders" AS "ord"
    WHERE "ord"."user_id" = "usr"."id"
      AND "ord"."date" >= NOW() - '1w'::interval
    ORDER BY "ord"."date" DESC
    LIMIT 3
  ) "last_orders" ON true
),
```

This query begets an impressive gain for a small change in the code.

|  orders | Returned Rows | Avg. Time (ms) |
|--------:|--------------:|---------------:|
|  105000 |           679 |             14 |
|  210000 |           906 |             35 |
|  315000 |           973 |             35 |
|  420000 |           996 |             33 |
|  630000 |           999 |             35 |
|  945000 |          1000 |             35 |
| 1455000 |          1000 |             37 |
| 1965000 |          1000 |             38 |
| 2970000 |          1000 |             40 |

It must be underlined that in the previous test **the amount of user is constant**. The good news is that we keep a relatively constant execution time regardless the increase in the orders.

Now we can repeat the test with the variable users:

|  users |  orders | Returned Rows | First Hit (ms) | Avg. Time (ms) |
|-------:|--------:|--------------:|---------------:|---------------:|
|    100 |   10500 |            70 |             17 |              4 |
|   1000 |  105000 |           679 |             39 |             26 |
|  10000 | 1050000 |          6775 |            612 |            480 |
| 100000 | 2750000 |         52000 |          80300 |           8000 |

For sure we got a sensible improvement up to 10k users (which is already a goal that not many company can reach), but then, when we go into the 100k users we can see a drop in performances. 

👉 **Scanning ALL THE USERS is not a scalable solution.**

> **CONCLUSIONS:** the amount of users is the bottleneck of this task.

