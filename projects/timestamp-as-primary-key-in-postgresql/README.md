# Timestamp as Primary Key

Sometimes it may seem a good idea to use `timestamp` as a primary key because even [`bigserial`](https://www.postgresql.org/docs/current/datatype-numeric.html) sequences will eventually run out of range!  
(It may take a while though....)


[Spoiler alert: it is not!](https://dba.stackexchange.com/questions/214110/can-current-timestamp-be-used-as-a-primary-key)

In this project, I try to highlight how easy is to fail this idea by running multiple inserts within the same transaction, and also propose a possible workaround that minimizes the possibility of collision for this unfortunate choice of pkey.

> BUT: PLEASE DON'T USE TIMESTAMP AS PKEY!

---

## Table of Contents

- [Prerequisites](#prerequisites)
- [Run the Project](#run-the-project)
- [Using Timestamp as Primary Key](#using-timestamp-as-primary-key)
- [But it is so easy to break it!](#but-it-is-so-easy-to-break-it)
- [How to get a real time value in PostgreSQL?](#how-to-get-a-real-time-value-in-postgresql)
- [A Tricky Solution](#a-tricky-solution)
- [Alternatives](#alternatives)

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

# Build the project and run the unit tests
make test

# Build the project and populate it with dummy data
# so that you can play with it using a client like PSQL
make seed

# Stop the running PostgreSQL and remove the container
# (data is still persisted to the local disk)
make stop
```

---

## Using Timestamp as Primary Key

This is the structure of a table that many of us have been tempted to create over the years:

```sql
CREATE TABLE "public"."people_v1" (
  "id" TIMESTAMP DEFAULT now(),
  "name" TEXT,
  "surname" TEXT,
  PRIMARY KEY ("id")
);
```

Surely, there are use cases in which the **possibility for a collision** of two consecutives timestamps is low enough.

Like creating a new user in a spontaneous registration system:

```sql
INSERT INTO "public"."people_v1" ("name", "surname")
VALUES ('Luke', 'Skywalker');
```

---

## But it is so easy to break it!

There are two ways to fail the choice of `people_v1` schema:

1. add multiple values within the same statement
2. run multiple stametems within the same transaction

```sql
-- Failing query n.1
INSERT INTO "public"."people_v1" ("name", "surname")
VALUES ('Luke', 'Skywalker'), ('Han', 'Solo');

-- Failing query n.2
BEGIN;
INSERT INTO "public"."people_v1" ("name", "surname")
VALUES ('Luke', 'Skywalker');
INSERT INTO "public"."people_v1" ("name", "surname")
VALUES ('Han', 'Solo');
COMMIT;
```

This happens because the value of `now()` is calculated at the beginning of a transaction.  
And that leaves me with a question:

## How to get a real time value in PostgreSQL?

[Somebody already posted this very question on Stackoverflow 🔗](https://stackoverflow.com/questions/3363376/how-to-get-a-real-time-within-postgresql-transaction).

We could use `clock_timestamp()` instead:

```sql
CREATE TABLE "public"."people_v2" (
  "id" TIMESTAMP DEFAULT clock_timestamp(),
  "name" TEXT,
  "surname" TEXT,
  PRIMARY KEY ("id")
);
```

As you can see in [`test/v2.sql`](./tests/v2.sql) and in the [`seed.sql`](./seed.sql) files, this let us run multiple inserts within the same transaction.

> The timestamp is calculated using _microseconds_. It's very unlikely that a collision happens, but **there is still absolutely no guaratee of univocy** if your server if fast enough, or with concurrent requests.

[Here you can get all the details from the official documentation 🔗](https://www.postgresql.org/docs/current/functions-datetime.html).

## A Tricky Solution

I recently found out about the [`row_number()`](https://www.postgresqltutorial.com/postgresql-row_number) function, which gives you the index of the row within the resultset of a query.

Combining with the possibility to play around with timestamps and text formats, and with the `with` statement... It is possible to use a very simple schema:

```sql
CREATE TABLE "public"."people_v3" (
  "id" TEXT PRIMARY KEY,
  "name" TEXT,
  "surname" TEXT
);
```

with a slightly more complex _INSERT STATEMENT_:

```sql
WITH
-- Generates values to be inserted into the target table:
"insert_values" AS (
	VALUES
	('Leia', 'Princess'), 
	('Obi-Wan', 'Kenobi'),
  ('Yoda', 'Master')
),

-- Allocate a Timestamp based ID with an incremental value
-- that is specific for each record:
"insert_records" AS (
	SELECT 
		CONCAT(
			(EXTRACT(EPOCH FROM now()) * 100000)::BIGINT,
			'-',
			row_number() OVER ()
		) AS "id",
		"a"."column1" as "name",
		"a"."column2" as "surname"
	FROM "insert_values" AS "a"
)

-- Run the insert statement:
INSERT INTO "public"."people_v3" 
SELECT * FROM "insert_records"
RETURNING *;
```

This is obviously overcomplicated and may still fail in case of true concurrent insert statements on a machine that is insanely fast (though I couldn't find a way to replicate it).

There is also the advantage the the resulting _id_ is sortable and will keep the exact insert order of every record. So it can be used as a cursor.

The obvious disadvantage is the complexity of the insert 😅.  
**But it is still an interesting piece of SQL code to read.**

## Alternatives

The obvious alternative is to **use a sequence**.

By using a `bigserial` sequence, it will take about 290 years to exaust the range... **if your system inserts one row every nanosecond**!

Another approach would be to use `uuid` as primary key:

```sql
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

CREATE TABLE "public"."people_uuid" (
  "id" UUID DEFAULT uuid_generate_v1(),
  "name" TEXT,
  "surname" TEXT,
  PRIMARY KEY ("id")
);
```

This will never go out of range, but you would lose the possibility to sort the records by ID, or to use it as a cursor!

Here is a great article on the topic:  
https://supabase.com/blog/choosing-a-postgres-primary-key


[postgres]: https://www.postgresql.org/
[docker]: https://www.docker.com/
[make]: https://www.gnu.org/software/make/manual/make.html
