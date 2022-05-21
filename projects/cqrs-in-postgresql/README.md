# CQRS in PostgreSQL

This project explores a possible implementation of a **CQRS on PostgreSQL**.

In particular, we will try to figure out a schema that can ingest plenty of commands and offer facilitations to the clients.

---

## Table of Contents

- [Prerequisites](#prerequisites)
- [Run the Project](#run-the-project)
- [xx](#a-simple-data-schema)

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

## CQRS Annotation Hyper Table

The first choice we make is to use a set of 2 tables for storing the full commant state:

- **Intention:** what is expected to happen ([v1_commands](./src/schema_v1.sql#4))
- **Response:** how did it go ([v1_responses](./src/schema_v1.sql#10))

This way, the only operations that will ever by performed into such tables are:

- **INSERT:** To propose commands and report status updates
- **DELETES:** To manage data retention, and this is technically optional

### Insert a Command

This operation is a standard `INSERT` statement.  
It is non blocking and it will hardly fail.

```sql
INSERT INTO "v1_commands"
VALUES ('{"name":"foo"}')
RETURNING *;
```

or

```sql
INSERT INTO "v1_commands"
VALUES (jsonb_build_object('name', 'foo'))
RETURNING *;
```

### Commands Ingestion Rate

First, we clear any data from our table:

```sql
TRUNCATE "v1_commands" RESTART IDENTITY CASCADE;
```

Second, we need a seeding function that simulates some form of realistic data:

```sql
INSERT INTO "v1_commands"
SELECT
  json_build_object(
  	'cmd_name',
      CASE
        WHEN random() >= 0.5 THEN 'insert'
        WHEN random() >= 0.5 THEN 'update'
        ELSE 'delete'
      END,
  	'progressive_name', CONCAT('task', "t"),
  	'random_value', random(),
  	'random_date',
      CASE
        WHEN random() >= 0.5 THEN to_jsonb(to_char(now() + '10y'::INTERVAL * random(),'YYYY-MM-DD HH:MM:SS'))
        ELSE to_jsonb(to_char(now() - '10y'::INTERVAL * random(),'YYYY-MM-DD HH:MM:SS'))
      END
  )
FROM generate_series(1, 1000000) AS "t";
```

Now we can run this query a bounch of times, and collect stats on the execution time:

|  Tot Rows |  Lapsed Time |  Inserts/sec |
| --------- | ------------ | ------------ |
| 1M        | 40s          |  25k         |
| 2M        | 53s          |  18k         |
| 3M        | 64s          |  15k         |
| 4M        | 62s          |  16k         |
| 5M        | 50s          |  20k         |
| 6M        | 54s          |  18k         |
| 7M        | 50s          |  20k         |
| 8M        | 53s          |  18k         |
| 9M        | 49s          |  20k         |
| 10M       | 44s          |  23k         |

> **NOTE:** these numbers are only ment to give an understanding of the degrading performances.
>
> I wouldn't suggest to use a SQL database for a system that has more than a few hundreds commands/s as a peak throughput!

### Insert a Response

```sql
INSERT INTO "v1_responses"
VALUES ( 1, '{"name":"foo"}' )
RETURNING *;
```

we can data seed some randomic data with:

```sql
INSERT INTO "v2_responses"
SELECT
  floor(random()* (1000-1 + 1) + 1),
  json_build_object(
  	'cmd_name',
      CASE
        WHEN random() >= 0.5 THEN 'insert'
        WHEN random() >= 0.5 THEN 'update'
        ELSE 'delete'
      END,
  	'progressive_name', CONCAT('task', "t"),
  	'random_value', random(),
  	'random_date',
      CASE
        WHEN random() >= 0.5 THEN to_jsonb(to_char(now() + '10y'::INTERVAL * random(),'YYYY-MM-DD HH:MM:SS'))
        ELSE to_jsonb(to_char(now() - '10y'::INTERVAL * random(),'YYYY-MM-DD HH:MM:SS'))
      END
  )
FROM generate_series(1, 1000000) AS "t";
```

|  Tot Rows |  Lapsed Time |  Inserts/sec |
| --------- | ------------ | ------------ |
| 1M        | 34s          |  29k         |
| 2M        | 41s          |  24k         |
| 3M        | 56s          |  18k         |
| 4M        | 46s          |  22k         |
| 5M        | 51s          |  20k         |

It yields an average of 22.6K inserts per second.

## Integrity Check

With integrity check

|  Tot Rows |  Lapsed Time |  Inserts/sec |
| --------- | ------------ | ------------ |
| 1M        | 58s          |  17k         |
| 2M        | 69s          |  14k         |
| 3M        | 75s          |  13k         |
| 4M        | 68s          |  15k         |
| 5M        | 63s          |  16k         |

It yields an average of 15K inserts per second.

It's 40% less performances!

## Retrieve Commands

Populate some commands issued within the last 3 days:

```sql
INSERT INTO "v3_commands"
SELECT json_build_object(
  'cmd_name', CASE WHEN random() >= 0.5 THEN 'insert' WHEN random() >= 0.5 THEN 'update' ELSE 'delete' END,
  'cmd_target', CONCAT('task', "t")
),
now() - '72h'::INTERVAL * random()
FROM generate_series(1, 100000) AS "t";
```

Get a list of the commands that were issued during the last hour:

```sql
SELECT * FROM "v3_commands"
WHERE "created_at" > now() - INTERVAL '1h';
```

yields in about 60ms

But I want the latest issued commands first:

```sql
SELECT * FROM "v3_commands"
WHERE "created_at" > now() - INTERVAL '1h'
ORDER BY "created_at" DESC;
```

yields in about 75ms, which is 20% worse performance!

We can fix this with an index:

```sql
CREATE INDEX "v3_commands_read_idx"
ON "v3_commands" ( "created_at" DESC );
```

And now the query yields in about 45ms, which is a sound 50% improvement!

## Retrieve Responses

Next step, we want to get the responses more or less in the same fashion, but first we must seed some roughly related data:

```sql
INSERT INTO "v3_responses"
SELECT
  floor(random()* (5000 -1 + 1) + 1),
  json_build_object(
  	'status',
      CASE
        WHEN random() >= 0.5 THEN 'ok'
        WHEN random() >= 0.5 THEN 'ko'
        ELSE 'started'
      END
  ),
  now() - '72h'::INTERVAL * random()
FROM generate_series(1, 1000000) AS "t";
```

And then we can run:

```sql
SELECT * FROM "v3_responses"
WHERE "created_at" > now() - INTERVAL '1h'
ORDER BY "created_at" DESC;
```

Even in this case we get something around 70ms for 1M rows in the table and randomic time distribution.

Another index will yield around 50% query improvement:

```sql
CREATE INDEX "v3_responses_read_idx"
ON "v3_responses" ( "created_at" DESC );
```

But wait, our data structure allows for multiple responses to a single command!

This is done on purpose, for the workers may want to provide status updates before the command ends. That makes it for a more responsive and talkative User Experience.

We can easily visualize the repeated responses by adding a new order clause:

```sql
SELECT *
FROM "v3_responses"
WHERE "created_at" > now() - INTERVAL '1h'
ORDER BY "cmd_id" DESC, "created_at" DESC;
```

Obviously, we are only interested in getting the last issued response for each command:

```sql
SELECT DISTINCT ON ("cmd_id") *
FROM "v3_responses"
WHERE "created_at" > now() - INTERVAL '1h'
ORDER BY "cmd_id" DESC, "created_at" DESC;
```

## Building the Commands History

The idea is to rebuild the list of latest issued commands, with their last available response, in a single query. Of course, joining tables is the main point of a relational database!

```sql
SELECT DISTINCT ON ("c"."cmd_id") * FROM "v3_commands" AS "c"
LEFT JOIN "v3_responses" AS "r" ON "c"."cmd_id" = "r"."cmd_id"
WHERE "c"."created_at" > now() - INTERVAL '1h'
ORDER BY "c"."cmd_id" ASC, "c"."created_at" DESC;
```

This query yields in about 350ms, which is not that bad if you consider that is pulling stuff out millions of rows.

But... can we do better?

Of course we can, here is an equivalent result that uses a _sub-query_ to reduce the amount of data that needs to be joined:

```sql
SELECT * FROM "v3_commands" AS "c"
LEFT JOIN (
	SELECT DISTINCT ON ("cmd_id") *
	FROM "v3_responses"
	WHERE "created_at" > now() - INTERVAL '1h'
	ORDER BY "cmd_id" DESC, "created_at" DESC
) AS "r" ON "c"."cmd_id" = "r"."cmd_id"
WHERE "c"."created_at" > now() - INTERVAL '1h'
ORDER BY "c"."cmd_id" ASC, "c"."created_at" DESC;
```

It yields exactly the same result... but in ~60ms.  
That is 130% better performances!

👉 Always do whatever you can to reduce the dataset before a join! 👈

Of course, we can refine the query and return a better dataset:

```sql
SELECT
  "c"."cmd_id" AS "cmd_id",
  "c"."payload" AS "payload",
  "r"."payload" AS "status",
  "c"."created_at" AS "created_at",
  "r"."created_at" AS "last_response_at"
FROM "v3_commands" AS "c"
LEFT JOIN (
	SELECT DISTINCT ON ("cmd_id") *
	FROM "v3_responses"
	WHERE "created_at" > now() - INTERVAL '1h'
	ORDER BY "cmd_id" DESC, "created_at" DESC
) AS "r" ON "c"."cmd_id" = "r"."cmd_id"
WHERE "c"."created_at" > now() - INTERVAL '1h'
ORDER BY "c"."cmd_id" ASC, "c"."created_at" DESC;
```

## Reduce The Dataset

Most modern applications are organized around the concept of a TENANT, which is usually a constant within a user session.

We can therefore add a `"ref" VARCHAR(50) NOT NULL` field that we will use to reference such information in our query. As so to extract the available commands for a specific tenant.

Before we proceed, we need to seed with data that are related by tenant reference:

```sql
TRUNCATE "v4_commands" RESTART IDENTITY CASCADE;
TRUNCATE "v4_responses" RESTART IDENTITY CASCADE;

INSERT INTO "v4_commands"
SELECT
  -- Randomic TenantID (tenant-1234)
	(SELECT (ARRAY(SELECT concat('tenant-', t) FROM generate_series(1, 5000) AS "t"))[floor(random() * 5000 + 1)] where "t" = "t"),
	json_build_object(
	  'cmd_name', CASE WHEN random() >= 0.5 THEN 'insert' WHEN random() >= 0.5 THEN 'update' ELSE 'delete' END,
	  'cmd_target', CONCAT('task', "t")
	),
	now() - '24h'::INTERVAL * random()
FROM generate_series(1, 1000000) AS "t";

-- Generate randomic responses
INSERT INTO "v4_responses"
SELECT
	floor(random()* (5000 -1 + 1) + 1),
	'-', -- Just a non-null tenant id, will be reconciled
	json_build_object(
	'status',
	  CASE
	    WHEN random() >= 0.5 THEN 'ok'
	    WHEN random() >= 0.5 THEN 'ko'
	    ELSE 'started'
	  END
	),
	now() - '24h'::INTERVAL * random()
FROM generate_series(1, 1000000) AS "t";

-- Reconcile responses' TenantID linking it via CommandID
UPDATE "v4_responses" AS "r"
SET "ref" = "c"."ref"
FROM "v4_commands" AS "c"
WHERE "r"."cmd_id" = "c"."cmd_id";
```

Now we have quite a big dataset to play with.

We can get all the commands and responses issued within the last hour:

```sql
SELECT
  "c"."ref" AS "ref",
  "c"."cmd_id" AS "cmd_id",
  "c"."payload" AS "payload",
  "r"."payload" AS "status",
  "c"."created_at" AS "created_at",
  "r"."created_at" AS "last_response_at"
FROM "v4_commands" AS "c"
LEFT JOIN (
	SELECT DISTINCT ON ("cmd_id") *
	FROM "v4_responses"
	WHERE "created_at" > now() - INTERVAL '1h'
	ORDER BY "cmd_id" DESC, "created_at" DESC
) AS "r" ON "c"."cmd_id" = "r"."cmd_id"
WHERE "c"."created_at" > now() - INTERVAL '1h'
ORDER BY "c"."cmd_id" ASC, "c"."created_at" DESC;
```

This query benefits from the indexes that we have already saw (85% improvements):

```sql
CREATE INDEX "v4_commands_read_idx"
ON "v4_commands" ( "created_at" DESC );

CREATE INDEX "v4_responses_read_idx"
ON "v4_responses" ( "created_at" DESC );
```

But now you can also try to query by a specific tenant:

```sql
SELECT
  "c"."ref" AS "ref",
  "c"."cmd_id" AS "cmd_id",
  "c"."payload" AS "payload",
  "r"."payload" AS "status",
  "c"."created_at" AS "created_at",
  "r"."created_at" AS "last_response_at"
FROM "v4_commands" AS "c"
LEFT JOIN (
	SELECT DISTINCT ON ("cmd_id") *
	FROM "v4_responses"
	WHERE "ref" = 'tenant-XXX'                  -- filter by tenant
	  AND "created_at" > now() - INTERVAL '1h'  -- filter by time
	ORDER BY "cmd_id" DESC, "created_at" DESC
) AS "r" ON "c"."cmd_id" = "r"."cmd_id"
WHERE "c"."ref" = 'tenant-XXX' -- filter by tenant
  AND "c"."created_at" > now() - INTERVAL '1h'
ORDER BY "c"."cmd_id" ASC, "c"."created_at" DESC;
```

This query takes already great benefits from the indexes that we have created, but we can go one step further and gain another 163% worth of performance improvement:

```sql
CREATE INDEX "v4_commands_read_by_tenant_idx"
ON "v4_commands" ( "ref", "created_at" DESC );

CREATE INDEX "v4_responses_read_by_tenant_idx"
ON "v4_responses" ( "ref", "created_at" DESC );
```

As your third option, you can ask for ALL THE COMMANDS issued by a specific tenant:

```sql
SELECT
  "c"."ref" AS "ref",
  "c"."cmd_id" AS "cmd_id",
  "c"."payload" AS "payload",
  "r"."payload" AS "status",
  "c"."created_at" AS "created_at",
  "r"."created_at" AS "last_response_at"
FROM "v4_commands" AS "c"
LEFT JOIN (
	SELECT DISTINCT ON ("cmd_id") *
	FROM "v4_responses"
	WHERE "ref" = 'tenant-XXX'                  -- filter by tenant
	ORDER BY "cmd_id" DESC, "created_at" DESC
) AS "r" ON "c"."cmd_id" = "r"."cmd_id"
WHERE "c"."ref" = 'tenant-XXX'                -- filter by tenant
ORDER BY "c"."cmd_id" ASC, "c"."created_at" DESC;
```
