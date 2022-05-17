# Event Sourcing in PostgreSQL - Events Log

This project explores a minimalist implementation of an **event sourcing system based on PostgreSQL**.

For sake of simplicity we will assume as follow:

- An **event** is just a _JSON_ payload
- Each client will remember the last consumed event

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

> At its core, an event sourcing system is really just a **time-based and sortable list of events**, where you can uniquely identify one event, the one that comes before and the one that comes after.

Based on this definition, we can define a minimal schema that will do just fine for our purpose:

- **etag:** a progressive and unique identifier
- **ctime:** a point in time when the log was first created
- **payload:** just a JSON payload

---

## BIGSERIAL as Etag

The most important feature of an **event sourcing system** is the ability to identify a specific log by a sortable id. 

We call this an `etag` and use a `BIGSERIAL` field to achieve this requirement.

> 🧐 Mmmm, aren't we going to run out of it?

Eventually, yes.   
But let's try to put "eventually" into perspective here.

The [`BIGSERIAL`](#datatypes) top limit is: `9223372036854775807`. I don't know about you, but it looks like a big number to me. 

Even so, human beings are not good at understanding big numbers:

<center><img alt="paul-franz-tweet" src="./images/paul-franz-tweet.png" width="300"></center>

### One Million Events Per Second

If our events log receives 1 event **every microsecond** it will take **millennia** before we run out of etags. In my book, that's definitely a _tomorrow's Marco(s)_ problem.

```
1 second = 1 million microseconds

1 day = 1μs * 1M * 60 * 60 *24 
= 86400000000 μs

1 year = 365 days
= 31536000000000 μs

9223372036854775807 / 31536000000000
= 292471
```

> If your system produces OME MILLION events per second, it will take 290+ MILLENNIA to run out of unique etags 🤪.

### Or With Stats From The Big Guys

To put this even further into perspective, we would be able to store (**):

- 86 thousands years worth of emails
- 396 thousands years worth of WhatsApp messages
- 4+ million years worth of Google searches
- 5+ million years worth of Facebook posts
- 51+ million years worth of Tweets
- 421+ million years worth of Instagram posts


> So I guess it will be ok to store your company's data in there

_(*) calculated on an average of 100 entries a user a day_  
_(**) [Source of the stats that I've used](https://www.zettasphere.com/mind-boggling-stats-for-1-second-of-internet-activity/)_

---

## Append New Events

This project [provides a simple function](./src/log_event.sql) to append new events into the log:

```sql
-- Append a single log:
SELECT log_event('{"event":"payload"}');

-- Append multiple logs:
SELECT log_event('[
  {"event":"payload1"},
  {"event":"payload2"},
  {"event":"payload3"}
]');
```

Of course, with this level of simplicity, it would be as simple as using `INSERT` statements into the table:

```sql
-- Populare 1k fake events:
INSERT INTO "public"."events_log" ("payload")
SELECT json_build_object('v', "t") AS "payload"
FROM generate_series(1, 1000) AS "t";
```

---

## Read Events

This project [provides a simple function](./src/get_event.sql) to read events from the log:

```sql
-- Get the first event:
SELECT get_event();

-- Get one event from a specific etag:
-- (will search from the NEXT etag)
SELECT get_event(1005);

-- Get multiple events at once:
SELECT get_event(1005, 10):
```

The shortcoming of this solution is that each client must keep track of the **last consumed message** independently. 

Also, with such a simple schema, each client that wants to consume the log **will not be able to scale horizontally** as we have no way to guarantee the order of the messages when consumed simultaneously.

---

## Stress Test With Big Data

In order to stress test this application, we can use [Docker][#docker] to simulate multiple data-producters that will inject some million events each. 

Each producer will log a number serie from 0 to a given limit, the limit being an environmental variable.

Then we can also run a client app that will read through the log, and keep the sum of the entire serie. 

By design, we can scale the data-producers almost indefinitely, but we will have to run a single instance of the data reader, as messages must be consumed in order.

- When the `get_event()` function will wield no values, it means that the job is done
- The consumer will keep the `MAX(etag(X) - etag(X-1))` and this value must be 1 to guarantee that all the messages have been queued without any conflict
- The resulting sum of all the messages must equal to: `PRODUCERS_SCALE * PRODUCERS_LIMIT`

| scale | insert_batch | insert_loops | tot_rows | read_batch  | lapsed_time | Throughput |
| ----: | -----------: | -----------: | -------: | ----------: | ----------: | ---------: |
| 10    | 10000        | 100          | 10000000 | 1000        | 63348       | 157858     |
| 10    | 10000        | 100          | 10000000 | 100         | 99953       | 100047     |
| 10    | 10000        | 100          | 10000000 | 10          | 471320      | 21217      |

---

## Next Steps

It would be nice to offer a way to automatically store the last consumed message for a given client. 

Something that will extend the `get_event()` API, by declaring a unique name for each client:

```sql
-- get next message
SELECT get_event('client-name');
```

---
[postgres]: https://www.postgresql.org/
[docker]: https://www.docker.com/
[make]: https://www.gnu.org/software/make/manual/make.html
[datatypes]: https://www.postgresql.org/docs/9.1/datatype-numeric.html