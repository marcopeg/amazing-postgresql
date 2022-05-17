# Queues in PostgreSQL - FIFO

This project explores a minimalist implementation of a **Queue based on PostgreSQL**.

A system that works pretty much like [RabbitMQ][rabbitmq] but leverages on our favourite data-management system and its outstanding reliability

For sake of simplicity we will assume as follow:

- A **task** is represented as a _JSON payload_
- A **queue** is represented by a _Table_

---

## Table of Contents

- [Prerequisites](#prerequisites)
- [Run the Project](#run-the-project)
- [A Simple Data Schema](#a-simple-data-schema)
- [BIGSERIAL as Etag](#bigserial-as-etag)
- [Append New Events](#append-new-events)
- [Read Events](#read-events)
- [Stress Test With Big Data](#stress-test-with-big-data)
- [Next Steps](#next-steps)

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

## A Simple Data Schema

A first approach might be to use numbers to sort out the tasks execution order.

> After all, we just need to:
>
> 1. pick one single task
> 2. do stuff
> 3. delete it

```sql
CREATE TABLE "queue_v1" (
  "id" SERIAL PRIMARY KEY,
  "payload" JSONB
);
```

> **NOTE:** using `SERIAL` as TaskID yelds roughly 6 tasks/second for about 10 years. Which is already longer than most startup would last.
>
> Switching to `BIGSERIAL` yelds 1 million tasks a second for about 2 thousands years.
>
> It's more than IKEA needs to count their screws.

### Appending New Tasks

Inserting tasks is trivial:

```sql
INSERT INTO "queue_v1" ("payload")
VALUES ('{"name": "my task"}')
RETURNING *;
```

### Data Ingestion Rates

We can seed some large amount of tasks by combining this query with `generate_series`:

```sql
INSERT INTO "queue_v1" ("payload")
SELECT json_build_object('value', "t") AS "payload"
FROM generate_series(1, 1000000) AS "t"
RETURNING *;
```

> My shiny 3 years old Mac yields ~47k inserts/sec.

It is **important** to understand that the _inserts/sec_ performance will progressively degrade with data growth.

🔥 Data ingestion rate is possibly the strongest limitation in using an ACID Table for a queue. If you need to ingest more than a couple of hundred tasks/sec, it's probably the time time to consider [RabbitMQ][rabbitmq].

Here is a very empirical dataset for inserting 1M tasks each time on my Mac. It's not rocket science, and you can see that the performance "stabilizes" between 30 and 40 thousands inserts/s.

|  Tot Rows |  Lapsed Time |  Inserts/sec |
| --------- | ------------ | ------------ |
| 1M        | 21s          |  47k         |
| 2M        | 28s          |  35k         |
| 3M        | 32s          |  31k         |
| 4M        | 30s          |  33k         |
| 5M        | 33s          |  30k         |
| 6M        | 32s          |  31k         |
| 7M        | 32s          |  31k         |
| 8M        | 28s          |  35k         |
| 9M        | 27s          |  37k         |
| 10M       | 24s          |  41k         |

👉 Once again, I wouldn't use SQL if massive data ingestion rates must be guaranteed, but numbers into the thousands of tasks/s should fit way above 80% of the use cases. Pareto wins!

### Consuming The Queue

Consuming the queue means 2 things:

1. Getting the next task that needs to be worked out
2. Delete it after the work is done:

```sql
-- Pick a task:
SELECT * FROM "queue_v1"
ORDER BY "id" ASC
LIMIT 1;

-- Complete a task:
DELETE FROM "queue_v1"
WHERE "id" = 1
RETURNING *;
```

---

[postgres]: https://www.postgresql.org/
[docker]: https://www.docker.com/
[make]: https://www.gnu.org/software/make/manual/make.html
[datatypes]: https://www.postgresql.org/docs/9.1/datatype-numeric.html
[rabbitmq]: https://www.rabbitmq.com/
