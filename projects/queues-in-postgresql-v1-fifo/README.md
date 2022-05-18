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
  "payload" JSONB,
  "task_id" SERIAL PRIMARY KEY
);
```

> 👉 using `SERIAL` as TaskID yelds roughly 6 tasks/second for about 10 years. Which is already longer than most startup would last.
>
> Switching to `BIGSERIAL` yelds 1 million tasks a second for about 2 thousands years.
>
> It's more than IKEA needs to count their screws.

## Appending New Tasks

Inserting tasks is trivial:

```sql
INSERT INTO "queue_v1"
VALUES ('{"name": "my task"}')
RETURNING *;
```

> 👉 In this query we skip the field names declaration.
>
> This is possible because we set `payload` as first field in the data structure. That was a choice made on purpose 😎.

## Data Ingestion Rates

We can seed some large amount of tasks by combining this query with `generate_series`:

```sql
INSERT INTO "queue_v1"
SELECT json_build_object('value', "t")
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

- What does MASSIVE data ingestion mean to you?
- What does MASSIVE data ingestion mean to your project?
- How do you estimate your data ingestion peaks?

> 🧐 Is it worth to use Kafka or SQL just because you don't know the ansers to the questions above?

## Consuming The Queue

Consuming the queue means 2 things:

1. Getting the next task that needs to be worked out
2. Delete it after the work is done:

```sql
-- Pick a task:
SELECT * FROM "queue_v1"
ORDER BY "task_id" ASC
LIMIT 1;

-- Complete a task:
DELETE FROM "queue_v1"
WHERE "task_id" = 1
RETURNING *;
```

This is quite straightforward, right?

> And it works perfectly fine if we consume the queue one task at the time!

## Distributed Processing

But queues exists as so to tap into the wonders of distributed processing:

> DISTRIBUTE PROCESSING:
>
> - different processes
> - running on different servers
> - process multiple tasks
> - in parallel

That simply means that many tasks should be "picked" before the first one gets completed.

🚧 Here our current solution breaks! 🚧

> If you run the task picking query multiple times... you always get the same task!

## Flag the Active Tasks

Somehow, it becomes necessary to mark a task as "work in progress" after picking it up.

Here is a second version of our queue data structure. Note that we keep the trick of setting `payload` as first field in the list!

```sql
CREATE TABLE IF NOT EXISTS "public"."queue_v2" (
  "payload" JSONB,
  "is_available" BOOLEAN DEFAULT TRUE,
  "task_id" BIGSERIAL PRIMARY KEY
);
```

And we will use the field `is_available` to figure out whether the task is available for processing or not.

Appending a new task in the queue remains as trivial as it was before:

```sql
INSERT INTO "queue_v2"
VALUES ('{"name": "my task"}')
RETURNING *;
```

But we need a bit more effort with the _data seeding_ as we want to randomize the `is_available` value, as so to simulate some tasks that have already been processed:

```sql
INSERT INTO "queue_v2"
SELECT
  json_build_object('value', "t"),
  random() > 0.5
FROM generate_series(1, 1000000) AS "t"
RETURNING *;
```

Now we can refine our **task picking query** as to target only tasks that are available for processing:

```sql
SELECT * FROM "queue_v2"
WHERE "is_available" = true
ORDER BY "task_id" ASC
LIMIT 1;
```

But this is not yet enough. This query still don't flag the task as "picked".

The whole process of processing a task should look like:

1. Pick a task
2. Flag as "work in progress"
3. Do some work
4. Delete the task

Flagging the task is a simple `UPDATE` statement:

```sql
UPDATE "queue_v2"
SET "is_available" = false
WHERE "task_id" = 1
RETURNING *;
```

We can also refine this query as so to avoid useless updates on tasks that are already flagged:

```sql
UPDATE "queue_v2"
SET "is_available" = false
WHERE "task_id" = 1
  AND "is_available" = true
RETURNING *;
```

👉 This works much better than before, but it is **still prone to concurrency errors**.

> But there is a gap between the `SELECT` and `UPDATE` statements, and within this gap, two consumers may pick the same task.

## FOR UPDATE SKIP LOCKED

Nice article:  
https://www.2ndquadrant.com/en/blog/what-is-select-skip-locked-for-in-postgresql-9-5/

The following statement uses the magic spell `FOR UPDATE SKIP LOCKED`, and a sub-query, to perform points n.1 and n.2 of the previoud list **atomically**:

1. Pick a task
2. Flag as "work in progress"

```sql
UPDATE "queue_v2"
SET "is_available" = false
WHERE "task_id" = (
  SELECT "task_id"
  FROM "queue_v2"
  WHERE "is_available" = true
  FOR UPDATE SKIP LOCKED
  LIMIT 1
)
RETURNING *;
```

---

[postgres]: https://www.postgresql.org/
[docker]: https://www.docker.com/
[make]: https://www.gnu.org/software/make/manual/make.html
[datatypes]: https://www.postgresql.org/docs/9.1/datatype-numeric.html
[rabbitmq]: https://www.rabbitmq.com/
