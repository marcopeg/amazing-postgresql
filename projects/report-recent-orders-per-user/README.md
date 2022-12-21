# Report Recent Orders Per User

In this project we dive into the building of a data report out of a simple USERS / ORDERS schema:

```
Report all the customers that placed at least three orders in the last week, and serve the data in JSON format, including the last three orders made by each user.
```

---

## Table of Contents

- [Prerequisites](#prerequisites)
- [Run the Project](#run-the-project)
- [Find Recent Orders](#find-recent-orders)
- [Get the Last Three Orders](#get-the-last-three-orders)
- [Window Functions To Rescue](#window-functions-to-rescue)
- [Lateral Join for Performances](#lateral-join-for-performances)

---

## Prerequisites

The following notes are written using MacOS as running environment and assume you have the following software installed on your machine:

- [Docker][docker]
- [Make][make]

👉 [Read about the general prerequisites here. 🔗](../../README.md#prerequisites-for-running-the-examples)

---

## Schema V1

The schema for this project is rather simple:

- `users` will store user data
- `orders` will store orders placed by users

> The `UserID` will be a simple text like `Luke`.

## Run the Project

This project simulates a PostgreSQL extension with its own unit tests.  
Run the following commands to run it:

```bash
# Build the "pgtap" image and start PostgreSQL with Docker
make start

# Build the project and populate it with dummy data
# so that you can play with it using a client like PSQL
make seed

# Stop the running PostgreSQL and remove the container
# (data is still persisted to the local disk)
make stop
```

---

## Find Recent Orders

The first portion of the task requires us to identify orders that had been placed during the **last week**. This is just a matter of placing a relative time condition:

```sql
SELECT *
FROM "v1"."orders" AS "ord"
WHERE "ord"."date" >= now() - '1w'::interval;
```

It is interesting to note how we can simply cast a string to be used as _interval_.

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


---

## Stress Test

100 users, 1000 orders

| query              | throughput |
|--------------------|-----------:|
| join2records       |      904.2 |
| join2json          |      871.8 |
| full-json          |      867.3 |
| single-user        |      862.8 |
| single-user2       |      852.5 |
| full-json-document |      851.8 |

100 users, 5000 orders

| query              | throughput |
|--------------------|-----------:|
| join2records       |      409.2 |
| full-json          |      244.9 |
| join2json          |      242.0 |
| single-user        |      224.0 |
| single-user2       |      222.6 |
| full-json-document |      221.2 |

100 users, 10000 orders

| query              | throughput |
|--------------------|-----------:|
| join2records       |      202.5 |
| full-json          |      131.6 |
| join2json          |      124.4 |
| single-user        |      117.5 |
| single-user2       |      115.6 |
| full-json-document |      112.2 |

100 users, 50000 orders

| query              | throughput |
|--------------------|-----------:|
| join2records       |       44.4 |
| full-json          |       28.4 |
| join2json          |       26.6 |
| full-json-document |       24.8 |
| single-user        |       24.0 |
| single-user2       |       23.8 |



100 users, 100000 orders

| query              | throughput |
|--------------------|-----------:|
| join2records       |            |
| full-json          |            |
| join2json          |            |
| single-user        |            |
| single-user2       |            |
| full-json-document |            |



100 users, 50000 orders

| query              | throughput |
|--------------------|-----------:|
| join2records       |            |
| full-json          |            |
| join2json          |            |
| single-user        |            |
| single-user2       |            |
| full-json-document |            |



100 users, 50000 orders

| query              | throughput |
|--------------------|-----------:|
| join2records       |            |
| full-json          |            |
| join2json          |            |
| single-user        |            |
| single-user2       |            |
| full-json-document |            |



