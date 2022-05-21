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

|  Tot Rows |  Lapsed Time |  Inserts/sec |
| --------- | ------------ | ------------ |
| 1M        | 34s          |  29k         |
| 2M        | 41s          |  24k         |
| 3M        | 56s          |  18k         |
| 4M        | 46s          |  22k         |
| 5M        | 51s          |  20k         |

## Integrity Check

With integrity check

|  Tot Rows |  Lapsed Time |  Inserts/sec |
| --------- | ------------ | ------------ |
| 1M        | 58s          |  17k         |
| 2M        | s            |  k           |
| 3M        | s            |  k           |
| 4M        | s            |  k           |
| 5M        | s            |  k           |
