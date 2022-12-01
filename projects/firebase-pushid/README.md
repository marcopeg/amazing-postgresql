# Firebase PushID

Porting _plpgsql_ for generating Firebase's PushID:

- https://firebase.blog/posts/2015/02/the-2120-ways-to-ensure-unique_68 
- https://gist.github.com/mikelehen/3596a30bd69384624c11

---

## Table of Contents

- [Prerequisites](#prerequisites)
- [Run the Project](#run-the-project)

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

## Generate PushIDs

```sql
-- Generate a PushID using timestamp in milliseconds:
select * from pushid_ms();

-- Generate a PushID using timestamp in microseconds:
select * from pushid_mu();
```

[postgres]: https://www.postgresql.org/
[docker]: https://www.docker.com/
[make]: https://www.gnu.org/software/make/manual/make.html
