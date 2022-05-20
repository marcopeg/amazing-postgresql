# Queues in PostgreSQL

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
- [Manging Failed Tasks](#manging-failed-tasks)
  - [Worker Keep Alive](#worker-keep-alive)
  - [Task Timeout](#task-timeout)
  - [Time Based Execution](#timestamp-execution-plan)

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

## Manging Failed Tasks

So far we use `is_available::boolean` to filter out tasks that are available for processing.
And we flag them `is_available -> false` when a worker pick them up.

When a worker completes its work, it will eventually `DELETE` the task as so to clean up the queue.

🧐 **What happens if the worker throws while processing the task?** 🧐

Unfortunately, with our current implementation, the task will not be visible to other workers until the `is_available` flag gets reset to true. But we have no available information _WHEN_ this should happen.

Here we tap into the mighty world of **FAILURE MANAGEMENT**, and we have a few possible ways to go about it:

- [Worker Keep Alive](#worker-keep-alive)
- [Task Timeout](#task-timeout)
- [Time Based Execution](#timestamp-execution-plan)

### Worker Keep Alive

1. we ask the worker to send a `keep alive` signal
2. we flag the picked task with the worker's id
3. we timeout the worker's `keep alive` and release the related tasks

> 👉 This is the advanced mechanic usually employed by famous tools such as RabitMQ or Kafka.
>
> It works great, but **it requires an explicit SDK** as so to negotiate the WorkerID.

### Task Timeout

1. when we pick a task, we annotate the pick up date
2. after a while, we reset tasks that are expired by an arbitrary timeout

> This solution is very simple, but **it requires us to run a batch job** to release tasks that have been not completed in time.

In order to achieve so, we can introduce a new column `picked_at` in our schema:

```sql
CREATE TABLE IF NOT EXISTS "public"."queue_v3" (
  "payload" JSONB,
  "is_available" BOOLEAN DEFAULT true,
  "task_id" BIGSERIAL PRIMARY KEY,
  "picked_at" TIMESTAMP
);
```

This column should always contain _the last time that the task was picked by a worker_.

The pick-up query should now evolve into:

```sql
UPDATE "queue_v3"
SET "is_available" = false,
    "picked_at" = now()
WHERE ...
```

The thing is, I don't think it's a good idea to put this responsibility into the pick-up query: what if the engineer messes up with it?

🔥 **Luckily, PostgreSQL offers great automation support through triggers** 🔥

First, we can define a _TRIGGER FUNCTION_ that will update the `picked_at` information when needed:

```sql
CREATE OR REPLACE FUNCTION "queue_v3_picked_at"()
RETURNS TRIGGER AS $$
BEGIN
  IF NEW."is_available" = false AND
     OLD."is_available" = true
  THEN
    NEW.picked_at = NOW();
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE 'plpgsql';
```

Then, we can associace such function to a _DATA EVENT_ in our queue table:

```sql
CREATE TRIGGER "queue_v3_picked_at"
BEFORE UPDATE
ON "queue_v3"
FOR EACH ROW
EXECUTE PROCEDURE "queue_v3_picked_at"();
```

> **NOTE:** `BEFORE UPDATE` triggers can manipulate the incoming data, and even perform data-validation with the purpose of failing the request.
>
> So much business logic can be moved from the Application Layer into the DB, achieving unbelievable performances at very little load price.

The last piece of this implementation would be to recover tasks that have timeouted:

```sql
UPDATE "queue_v3"
SET "is_available" = true
WHERE "task_id" IN (
  SELECT "task_id"
  FROM "queue_v3"
  WHERE "is_available" = false
    AND "picked_at" < now() - INTERVAL '5s'
  ORDER BY "picked_at" ASC
  FOR UPDATE SKIP LOCKED
) RETURNING *;
```

> **NOTE:** this query will attempt to recover ALL the timeouted tasks.

It is a good idea to never run queries that target an entire dataset, for the execution time is unpredictable.

I'd rather `LIMIT` the subquery as so to apply a ceiling to the possible updates, and then repeat my query until it returns zero rows. This way, the execution time would spread in time and reduce the workload on the machine.

🧐 **What about recover performances?** 🧐

Let's insert some randomic timeouted tasks in our db:

```sql
INSERT INTO "queue_v3" ("payload", "is_available", "picked_at")
SELECT
  json_build_object('name', CONCAT('Task', "t")),
  random() > 0.99990,
  now() - '10m'::INTERVAL * random()
FROM generate_series(1, 1000000) AS "t";
```

We suddenly experience a DRAMATIC PERFORMANCE ISSUE with out recover query.

> In my machine it goes up to 5s to recover one sigle task!

That is because we want to recover the older tasks first:

```sql
ORDER BY "picked_at" ASC
```

You can test this out by running the `SELECT` part of the recovery query:

```sql
EXPLAIN ANALYZE
SELECT "task_id"  FROM "queue_v3"
WHERE "is_available" = false AND "picked_at" < now() - INTERVAL '5s'
ORDER BY "picked_at" ASC
LIMIT 1;
```

You get this huge plan:

```
Limit  (cost=19720.54..19720.66 rows=1 width=16) (actual time=3011.554..3016.628 rows=1 loops=1)
  ->  Gather Merge  (cost=19720.54..116926.99 rows=833140 width=16) (actual time=3011.542..3016.604 rows=1 loops=1)
        Workers Planned: 2
        Workers Launched: 2
        ->  Sort  (cost=18720.52..19761.94 rows=416570 width=16) (actual time=3001.399..3001.411 rows=1 loops=3)
              Sort Key: picked_at
              Sort Method: top-N heapsort  Memory: 25kB
              Worker 0:  Sort Method: top-N heapsort  Memory: 25kB
              Worker 1:  Sort Method: top-N heapsort  Memory: 25kB
              ->  Parallel Seq Scan on queue_v3  (cost=0.00..16637.67 rows=416570 width=16) (actual time=0.011..1509.963 rows=333283 loops=3)
                    Filter: ((NOT is_available) AND (picked_at < (now() - '00:00:05'::interval)))
                    Rows Removed by Filter: 50
Planning Time: 4.226 ms
Execution Time: 3016.759 ms
```

But if you just remove the `ORDER BY` clause you get top knotch performances:

```sql
Limit  (cost=0.00..0.03 rows=1 width=8) (actual time=0.025..0.044 rows=1 loops=1)
  ->  Seq Scan on queue_v3  (cost=0.00..26846.00 rows=999767 width=8) (actual time=0.015..0.020 rows=1 loops=1)
        Filter: ((NOT is_available) AND (picked_at < (now() - '00:00:05'::interval)))
Planning Time: 0.878 ms
Execution Time: 0.123 ms
```

🤬 WTF?

> We get this gigantic difference because we inserted 1M timeouted tasks with a randomic `picked_at` value.

In reality, it would never be THAT BAD because timeouted tasks will always be more or less adjacent one to another at the top of the queue.

Still, this is evidence of a performance bottleneck that we are able to fix with a _PARTIAL INDEX_:

```sql
CREATE INDEX "queue_v3_recover_idx"
ON "queue_v3" ( "picked_at" ASC )
WHERE ( "is_available" = false );
```

And now our recovery query plan turns out to be:

```
Limit  (cost=0.43..0.50 rows=1 width=16) (actual time=0.064..0.089 rows=1 loops=1)
  ->  Index Scan using queue_v3_recover_idx on queue_v3  (cost=0.43..65853.80 rows=999767 width=16) (actual time=0.049..0.056 rows=1 loops=1)
        Index Cond: (picked_at < (now() - '00:00:05'::interval))
Planning Time: 0.168 ms
Execution Time: 0.143 ms
```

And the query keeps running in just under 2ms to recover 1 task, and under 20ms to recover 100.

### Timestamp Execution Plan

This approach introduces a radical change, for we are going to use a `timestamp` to manage the different states of a task:

- if `ts <= now()` the task _should be processed_, and it is available
- if `ts > now()` the task is just planned for execution and it is NOT available

```sql
CREATE TABLE IF NOT EXISTS "public"."queue_v4" (
  "payload" JSONB,
  "next_iteration" TIMESTAMP NOT NULL DEFAULT now(),
  "task_id" BIGSERIAL PRIMARY KEY
);
```

This little schema has HUGE implications:

1. We can insert tasks in the queue at any point in time  
   <small>the "queue" becomes a "calendar"</small>
2. Flagging a task as "under execution" is achieved by modifying the `next_iteration`
3. Managing an _execution timeout_ is achieved through a smart setting of `next_iteration`
4. The recovery of timed-out tasks is _AUTOMATIC_ as time keeps moving!

The pick-up query becomes:

```sql
UPDATE "queue_v4"
SET "next_iteration" = now() + INTERVAL '10s'
WHERE "task_id" = (
  SELECT "task_id"
  FROM "queue_v4"
  WHERE "next_iteration" <= now()
  ORDER BY "next_iteration" ASC
  FOR UPDATE SKIP LOCKED
  LIMIT 1
) RETURNING *;
```

This query will pick one single task, setting a timeout of 10 seconds for its execution.  
Try running again after that amount of time, the task will be picked up again!

😎 **TO GOOD TO BE TRUE** 😎

Let's populate our queue with some randomic tasks:

```sql
INSERT INTO "queue_v4" ("payload", "next_iteration")
SELECT
  json_build_object('name', CONCAT('Task', "t")),
  CASE
  	WHEN random() > 0.5 THEN now() - '10m'::INTERVAL * random()
  	ELSE now() + '10s'::INTERVAL * random()
  END
FROM generate_series(1, 1000000) AS "t";
```

Unfortunately, we quickly see a **DRAMATIC PERFORMANCE DROP** 😒.

| rows |  pick-up |
| ---- | -------- |
| 10   |  3ms     |
| 10k  |  7ms     |
| 100k |  270ms   |
| 1M   |  3.6sms  |

By now, you would think: "let's just add a Partial Index"!

```sql
CREATE INDEX "queue_v4_pick_idx"
ON "queue_v3" ( "next_interval" ASC )
WHERE ( "next_interval" <= now() );
```

Unfortunately (get used to "unfortunately"), TIME can not be partially indexed, as it constantly change.

```Error
ERROR:  functions in index predicate must be marked IMMUTABLE
```

> FUTURE NOWs live in the PAST

But we can AT THE VERY LEAST build an index that helps keeping stuff in the proper order:

```sql
CREATE INDEX "queue_v4_pick_idx"
ON "queue_v4" ( "next_iteration" ASC );
```

Here are the results... no comments...

| rows |  pick-up | with index |
| ---- | -------- | ---------- |
| 10   |  3ms     | 3ms        |
| 10k  |  7ms     | 3ms        |
| 100k |  270ms   | 3ms        |
| 1M   |  3.6s    | 4ms        |
| 5M   |   42s    | 6ms        |
| 10M  |   81s    | 6ms        |

😎 **TO GOOD TO BE TRUE** 😎

Indeed, those performances come with a cost: DISK SPACE!

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
WHERE i.relname='queue_v4';
```

With 10M rows, the table size is up to `730Mb`, but the indexes are taking another `426Mb` for a grand total of `1.2Gb`.

🔥 **The query performance costs us a 30% increase in disk size, and disk I/O.** 🔥

---

[postgres]: https://www.postgresql.org/
[docker]: https://www.docker.com/
[make]: https://www.gnu.org/software/make/manual/make.html
[datatypes]: https://www.postgresql.org/docs/9.1/datatype-numeric.html
[rabbitmq]: https://www.rabbitmq.com/
