# Run Unit Tests on PostgreSQL

[PgTap](pgtap) is a collection of [psql][psql] functions that facilitate testing your [PostgreSQL][postgres] database.

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

# Just run the tests
# (faster because it doesnt re-create the schema)
make run

# Stop the running PostgreSQL and remove the container
# (data is still persisted to the local disk)
make stop
```

---

## Project Structure

- `/src` contains the project's source files as migration folders
- `/tests` contains the project's tests
- `reset-db.sql` contains a reset utility to be executed before the tests

---

## PgTap on Docker

This example uses Docker to run `pgtap`, this is the repo I uses:  
https://github.com/walm/docker-pgtap

> The issue is that project doesn't get any update since 2016, and PgTap has been improved since then. By building our custom `pgtap` image, we ensure to use the latest availale version of the software.

---

## Other Resources

- https://medium.com/engineering-on-the-incline/unit-testing-postgres-with-pgtap-af09ec42795
- https://medium.com/engineering-on-the-incline/unit-testing-functions-in-postgresql-with-pgtap-in-5-simple-steps-beef933d02d3
- https://www.slideshare.net/justatheory/pgtap-best-practices


[postgres]: https://www.postgresql.org/
[docker]: https://www.docker.com/
[make]: https://www.gnu.org/software/make/manual/make.html
[pgtap]: https://pgtap.org/
[psql]: https://www.postgresql.org/docs/13/app-psql.html