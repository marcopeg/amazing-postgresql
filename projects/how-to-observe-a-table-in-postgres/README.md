# How to Observe a Table in PostgreSQL

Use a combination of triggers and json functions to subscribe to a [PostgreSQL][postgres] table data change
and store a permanent log of anything that change in your database.

## Table of Contents

- [Prerequisites](#prerequisites)
- [Run the Project](#run-the-project)
- [How to List Triggers](#how-to-list-triggers)

---

## Prerequisites

The following notes are written using MacOS as running environment and assume you have the following software installed on your machine:

- [Docker][docker]
- [Make][make]

👉 [Read about the general prerequisites here. 🔗](../../#prerequisites-for-running-the-examples)

---

## Run the Project

This project simulates a PostgreSQL extension with its own unit tests.  
Run the following commands to run it:

```bash
# Build the "pgtap" image and start PostgreSQL with Docker
make start

# Build the project and run the unit tests
make test

# Stop the running PostgreSQL and remove the container
# (data is still persisted to the local disk)
make stop
```

---

## How to List Triggers

Once you start playing with triggers, you will likely need to figure out which trigger is associated with which table.

The following query will return all the triggers that exists in your database.

```sql
WITH "all_triggers" AS (
  SELECT
    "event_object_schema" AS "table_schema",
    "event_object_table" AS "table_name",
    "trigger_schema",
    "trigger_name",
    string_agg("event_manipulation", ',') AS "event",
    "action_timing" AS "activation",
    "action_condition" AS "condition",
    "action_statement" AS "definition"
  FROM "information_schema"."triggers"
  GROUP BY 1,2,3,4,6,7,8
  ORDER BY "table_schema", "table_name"
)
SELECT * FROM "all_triggers";
```

You can refine the selection by applying filters to it:

```sql
WITH "all_triggers" AS (...)
SELECT * FROM "all_triggers"
WHERE "table_schema" = 'public';
```

👉 [Read more about the WITH statement in PostgreSQL 🔗](https://www.postgresql.org/docs/current/queries-with.html)

---


[postgres]: https://www.postgresql.org/
[docker]: https://www.docker.com/
[make]: https://www.gnu.org/software/make/manual/make.html
[pgtap]: https://pgtap.org/
[psql]: https://www.postgresql.org/docs/13/app-psql.html