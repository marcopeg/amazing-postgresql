# Run Unit Tests on PostgreSQL

[PgTap](pgtap) is a collection of [psql][psql] functions that facilitate testing your PostgreSQL schema.

## Prerequisites

The following notes are written using MacOS as running environment and assume you have the following software installed on your machine:

- [Docker][docker]
- [Make][make]

---

## Run the Example

This project simulates a PostgreSQL extension with its own unit tests.  
Run the following commands to run it:

```bash
# Start PostgreSQL with Docker
make start

# Build the project and run the unit tests
make test
```

## Project Structure

- `/src` contains the project's source files
- `/tests` contains the project's tests
- `reset-db.sql` contains a reset utility to be executed before the tests

## PgTap on Docker

This example uses Docker to run `pgtap`, this is the image I used:  
https://hub.docker.com/r/lren/pgtap

And here is its source-code:  
https://github.com/LREN-CHUV/docker-pgtap


[pgtap]: https://pgtap.org/
[psql]: https://www.postgresql.org/docs/13/app-psql.html