# How to Observe a Table

Use a combination of triggers and json functions to subscribe to a [PostgreSQL][postgres] table data change
and store a permanend log of anything that changes in your database.

## Prerequisites

The following notes are written using MacOS as running environment and assume you have the following software installed on your machine:

- [Docker][docker]
- [Make][make]

---

## Run the Example

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

Get table's triggers:

```sql
select event_object_schema as table_schema,
       event_object_table as table_name,
       trigger_schema,
       trigger_name,
       string_agg(event_manipulation, ',') as event,
       action_timing as activation,
       action_condition as condition,
       action_statement as definition
from information_schema.triggers
group by 1,2,3,4,6,7,8
order by table_schema,
         table_name;
```


[postgres]: https://www.postgresql.org/
[docker]: https://www.docker.com/
[make]: https://www.gnu.org/software/make/manual/make.html
[pgtap]: https://pgtap.org/
[psql]: https://www.postgresql.org/docs/13/app-psql.html