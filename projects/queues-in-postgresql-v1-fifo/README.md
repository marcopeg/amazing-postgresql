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
- [Appending New Tasks](#appending-new-tasks)
- [Data Ingestion Rates](#data-ingestion-rates)
- [Consuming The Queue](#consuming-the-queue)
- [Distributed Processing](#distributed-processing)
- [Flag the Active Tasks](#flag-the-active-tasks)
- [FOR UPDATE SKIP LOCKED](#for-update-skip-locked)
- [Batching The Execution](#batching-the-execution)
- [Optimizing For Speed](#optimizing-for-speed)
- [The True Cost of Speed](#the-true-cost-of-speed)
- [Fully Cached Indexes](#fully-cached-indexes)

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

---

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

---

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

---

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

---

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

---

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

---

## FOR UPDATE SKIP LOCKED

The following statement uses the magic spell `FOR UPDATE SKIP LOCKED`, and a sub-query, to perform points n.1 and n.2 of the previous list **atomically**:

1. Pick a task
2. Flag it as "work in progress"

```sql
UPDATE "queue_v2"
SET "is_available" = false
WHERE "task_id" = (
  SELECT "task_id"
  FROM "queue_v2"
  WHERE "is_available" = true
  ORDER BY "task_id" ASC
  FOR UPDATE SKIP LOCKED
  LIMIT 1
)
RETURNING *;
```

Once the task is performed, we can use a similar statement for removing the task from the queue:

```sql
DELETE FROM "queue_v2"
WHERE "task_id" = (
  SELECT "task_id"
  FROM "queue_v2"
  WHERE "task_id" = $1
  FOR UPDATE SKIP LOCKED
  LIMIT 1
)
RETURNING *;
```

---

## Batching The Execution

Let's start tapping into **performance optimiziations**.

Reading and processing one task at the time can be slow. One of the most common optimiztion is batching or pre-fetching: we get X amount of tasks all together, and then we process them one at the time in-memory.

> Each _active worker_ can pull a batch of tasks concurrently, but then it processes one at the time in-memory.

```sql
UPDATE "queue_v2"
SET "is_available" = false
WHERE "task_id" IN (
  SELECT "task_id"
  FROM "queue_v2"
  WHERE "is_available" = true
  ORDER BY "task_id" ASC
  FOR UPDATE SKIP LOCKED
  LIMIT 5
)
RETURNING *;
```

---

## Optimizing For Speed

Now we can start looking into performance bottlenecks.

Unfortunately (or fortunaltely), Postgres works exceedingly fast WHEN EMPTY. If you have a table with just a few thousands of rows, there is no such thing as slow queries.

So the first step into finding and solving performance bottlenecks is to populate out dataset with some decent amount of data:

```sql
INSERT INTO "queue_v2"
SELECT
  json_build_object('name', CONCAT('task', "t")),
  random() > 0.99990
FROM generate_series(1, 1000000) AS "t";
```

This will populate 1M rows worth of tasks, with only _~1 available task each 10K rows_.

> 👉 The available tasks are so sparse as so to put more stress on the db, and highlight a possible bottleneck.

|  Tot Rows |  Lapsed Time |  Inserts/sec |
| --------- | ------------ | ------------ |
| 1M        | 16s          |  62K         |
| 2M        | 18s          |  55K         |
| 3M        | 18s          |  55K         |
| 4M        | 17s          |  58K         |
| 5M        | 17s          |  58K         |
| 10M       | 103s         |  48K         |

The insert performances don't change much from my previous test. After all, this index is quite unexpensive.

> This test also highlight how testing on a consumer OS - like a Mac - is highly unpredictable. The test results variate a lot based on the overall OS activities.
>
> I had Teams running during my first test, and that little bastard is eager of CPU cycles!

Now it is time to test our **Task Picking Performances** with the following query:

```sql
UPDATE "queue_v2"
SET "is_available" = false
WHERE "task_id" = (
  SELECT "task_id"
  FROM "queue_v2"
  WHERE "is_available" = true
  ORDER BY "task_id" ASC
  FOR UPDATE SKIP LOCKED
  LIMIT 1
)
RETURNING *;
```

Here are some results that I've collected:

|  Tot Rows |   Pick One Task |
| --------- | --------------- |
| 1M        | 8ms             |
| 2M        | 90ms            |
| 3M        | 130ms           |
| 4M        | 1500ms          |
| 5M        | 1000ms          |
| 10M       | 4500ms          |

> 🤬 This sucks, right? Only 10M rows in a table (this is not even starting to be "data") and the query runs for SECONDS! That is like "foreverandever" in PostgreSQL world!

Fortunately, _PARTIAL INDEXES_ help speeding up the whole process!

```sql
-- Create an Index:
CREATE INDEX "queue_v2_pick_idx"
ON "queue_v2" ( "task_id" ASC )
WHERE ( "is_available" = true );

-- Drop an Index:
DROP INDEX "queue_v2_pick_idx";
```

|  Tot Rows |   Pick Without Index | Pick With Index |
| --------- | -------------------- | --------------- |
| 1M        | 8ms                  |  5ms            |
| 2M        | 90ms                 |  5ms            |
| 3M        | 130ms                |  7ms            |
| 4M        | 1500ms               |  7ms            |
| 5M        | 1000ms               |  7ms            |
| 10M       | 4500ms               |  8ms            |

🔥 It is evident that this index helps to keep the task picking performances stable even with a linear data growth.

It's interesting to compare the EXECUTION PLAN with and without an index.

For sake of simplicity, we only consider the `SELECT` statement of our Task Picking query:

```sql
EXPLAIN ANALYZE
SELECT *
FROM "queue_v2"
WHERE "is_available" = true
ORDER BY "task_id" ASC
LIMIT 1;
```

Execution plan WITHOUT index:

```
Limit  (cost=0.43..514.71 rows=1 width=36) (actual time=21.834..21.857 rows=1 loops=1)
  ->  Index Scan using queue_v2_pkey on queue_v2  (cost=0.43..343021.43 rows=667 width=36) (actual time=21.820..21.826 rows=1 loops=1)
        Filter: is_available
        Rows Removed by Filter: 161421
Planning Time: 1.340 ms
Execution Time: 21.912 ms
```

Execution plan WITH index:

```
Limit  (cost=0.28..0.33 rows=1 width=36) (actual time=0.880..0.939 rows=1 loops=1)
  ->  Index Scan using queue_v2_pick_idx on queue_v2  (cost=0.28..35.28 rows=667 width=36) (actual time=0.869..0.903 rows=1 loops=1)
Planning Time: 3.508 ms
Execution Time: 0.985 ms
```

The relevant part is that in the second example, we read:

`Index Scan using queue_v2_pick_idx`

👉 That means that the lookup is performed on the index where the **available tasks** have already been filtered out!

> Always keep in mind that indexes should be use to EXCLUDE DATA from your sequential scans.

---

## The True Cost of Speed

😍 Waaaait, are indexes so awesome?  
🤪 Can we put it just... like... everywhere?

PostgreSQL stores data to the disk. It also applies in-memory caching and wonderful optimizations, but in the end data reaches the disk.

**That is how data stay safe in PostgreSQL.**

Here is a fancy query to get some data-size stats out of your PostgreSQL:

```sql
SELECT
  i.relname "Table Name",
  indexrelname "Index Name",
  pg_size_pretty(pg_total_relation_size(relid)) As "Total Size",
  pg_size_pretty(pg_indexes_size(relid)) as "Total Size of all Indexes",
  pg_size_pretty(pg_relation_size(relid)) as "Table Size",
  pg_size_pretty(pg_relation_size(indexrelid)) "Index Size",
  reltuples::bigint "Estimated table row count"
FROM pg_stat_all_indexes i JOIN pg_class c ON i.relid=c.oid
WHERE i.relname='queue_v2';
```

And here are some stats from my system:

```
| Tot Rows |  Disk Space |  Index Space |
| -------- | ----------- | ------------ |
| 1M       |   65M       | 14K          |
| 5M       |   326M      | 32K          |
| 10M      |   651M      | 40kK          |
```

As you can see, there are 2 costs factors in the solution we presented:

1. Disk Space: Indexes are stored to disk as well, they need space
2. I/O: When data changes, indexes must be updated too. The data ingestion rate will decrease with the indexes

> 👉 So far, we use BIGINT as `task_id`, which is a relatively small piece of data. So the index is very small.
>
> Things may change dramatically if you consider using `UUIDs` instead. Always keep an eye on the data size!

Indexes are great, Partial Indexes are better, but always use them responsibly 😎.

---

## Fully Cached Indexes

Since version 11, you can add an `INCLUDE` clause to your statement, as so to force such index to collect additional data:

```sql
-- Create a Fully Cached Index
CREATE INDEX "queue_v2_pick_idx"
ON "queue_v2" ( "task_id" ASC )
INCLUDE ( "task_id", "payload", "is_available" )
WHERE ( "is_available" = true );
```

The new execution plan looks like:

```
Limit  (cost=0.28..0.34 rows=1 width=36) (actual time=0.039..0.065 rows=1 loops=1)
  ->  Index Only Scan using queue_v2_pick_idx on queue_v2  (cost=0.28..46.28 rows=667 width=36) (actual time=0.024..0.031 rows=1 loops=1)
        Heap Fetches: 0
Planning Time: 0.091 ms
Execution Time: 0.116 ms
```

And the difference is `Index Only Scan`. That means that the data table doesn't even get touched by the query.

🔥 As you can see, BOTH plannin and execution time improve dramatically. 🔥

> Fully Cached Indexes can work wonders, but they also cost more disk space, and more writing efforts.
>
> Again, balance!

---

[postgres]: https://www.postgresql.org/
[docker]: https://www.docker.com/
[make]: https://www.gnu.org/software/make/manual/make.html
[datatypes]: https://www.postgresql.org/docs/9.1/datatype-numeric.html
[rabbitmq]: https://www.rabbitmq.com/
