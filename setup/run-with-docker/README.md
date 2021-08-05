# Run PostgreSQL with Docker

The simple and containerized way to run any version of [PostgreSQL][postgres].

- [Prerequisites](#prerequisites)
- [Run PostgreSQL with Docker](#run-postgresql-with-docker)
- [Run PostgreSQL with Docker Compose](#run-postgresql-with-docker-compose)
- [Run PSQL with Docker](#run-psql-with-docker)
- [Run a SQL query programmatically](#run-a-sql-query-programmatically)
- [Run an SQL script programmatically](#run-an-sql-script-programmatically)

---

## Prerequisites

The following notes are written using MacOS as running environment and assume you have the following software installed on your machine:

- [Docker][docker]
- [Docker Compose][docker-compose]
- [Make][make]

---

## Run PostgreSQL with Docker

The official PostgreSQL Docker image is:  
https://hub.docker.com/_/postgres

You can quickly run it locally as:

```bash
docker run \
  --rm \
  --name pg \
  -p 5432:5432 \
  -v $(pwd)/.docker-data:/var/lib/postgresql/data \
  -e POSTGRES_PASSWORD=postgres \
  postgres:13.2
```

- `--rm` will automatically remove the containers once you stop it (`Ctrl + c`)
- `--name` will give an explicit name to the container, so that we can play with it
- `-p` will expose the PostgreSQL process on your host's network on the default port
- `-v` sets a persisted data volume for your database
- `-e` sets the password for the default user (`postgres`) on the default database (`postgres`)

> 👉 The cool thing is that you can play with many different versions of PostgreSQL by changing the tag of the image that you want to run.

It is common to store bash commands into a [Makefile][make] so that you don't have to remember them.

🔗 Please have a look at [this example Makefile](./Makefile).

---

## Run PostgreSQL with Docker Compose

It is common to describe a complex application as a collection of containers using [Docker Compose][docker-compose].

This way, you can easily start/stop containers using:

```bash
docker-compose up

docker-compose down
```

And enjoy container-to-container automatic DNS mapping using the container's names or the [_links_ attribute](https://docs.docker.com/compose/compose-file/compose-file-v3/#links).

---

## Run PSQL with Docker

You can also use Docker to run the `psql` cli tool.

This example uses the running PostgreSQL container and runs `psql` inside it.

👉 We can easily do that as we set an explicit name `pg` that we can now use to connect to such container.

```bash
docker exec -it pg psql -U postgres postgres
```

Or we can spin up a new container to run `psql` and link it to the running PostgreSQL container, also here we use the container's name as link target:

```bash
docker run \
  --rm \
  -it \
  --link pg:pg \
  postgres:13.2 \
  psql postgresql://postgres:postgres@pg:5432/postgres
```

- `-it` will attach your terminal to the container's shell
- `--link` will create a DNS to the PostgreSQL running container

---

## Run a SQL query programmatically

Using `psql` from the same container:

```bash
docker exec -it pg psql -U postgres postgres \
  -c 'select now();'
```

Using a dedicated container:

```bash
docker run \
  --rm \
  -it \
  --link pg:pg \
  postgres:13.2 \
  psql postgresql://postgres:postgres@pg:5432/postgres \
  -c 'select now();'
```

---

## Run an SQL script programmatically

Using `psql` from the same container:

```bash
docker exec -i pg psql -U postgres postgres \
  < example.sql
```

Using a dedicated container:

```bash
docker run \
  --rm \
  -i \
  --link pg:pg \
  postgres:13.2 \
  psql postgresql://postgres:postgres@pg:5432/postgres \
  < example.sql
```

[postgres]: https://www.postgresql.org/
[docker]: https://www.docker.com/
[docker-compose]: https://docs.docker.com/compose/
[make]: https://www.gnu.org/software/make/manual/make.html