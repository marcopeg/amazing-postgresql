# Event Emitter & Pub/Sub in PostgreSQL

Did you know that [PostgreSQL][postgres] embeds a fully working pub/sub server? Here you have an [interesting article](https://tapoueh.org/blog/2018/07/postgresql-listen-notify/) that shows how to create a decoupled cache layer for a Twitter-like application.

> In this project I focus on a minimal implementation of a publisher and subscriber app in NodeJS. It is intended as a pure demonstration of how messages can be sent and received and there is very little logic in it.

## Table of Contents

- [Prerequisites](#prerequisites)
- [Run the Project](#run-the-project)
- [Project's Services](#projects-services)

---

## Prerequisites

The following notes are written using MacOS as running environment and assume you have the following software installed on your machine:

- [Docker Compose][docker-compose]
- [Make][make]

👉 [Read about the general prerequisites here. 🔗](../../README.md#prerequisites-for-running-the-examples)

---

## Run the Project

This project comes as a composition of services that are describe as a [`docker-compose`][docker-compose] project.

> You need to run all the services in order to follow the rest of this document.

```bash
# Builds and run all the services involved in this project
# (it uses `docker-compose` under the hood)
make start

# Stops and removes all the services involved in this project
make stop

# Publish messages in some channels using an SQL source file
make seed
```

---

## Project's Services

The project's services are described in the [`docker-compose.yml`](./docker-compose.yml). You can run 'em all with `make start`.

### Postgres

Runs the [PostgreSQL][postgres] instance and make it available to the other services as _Docker DNS_.

> As we don't use any schema, and there is no need to connect to the db using an external app, I decided to omit the `ports` and `volumes` so to keep a smaller footprint on the host system.

### Publisher

This is a real NodeJS micro-service. It's a one file app that connects to the database using the standard library [`pg`](https://www.npmjs.com/package/pg) and emits a message on a random channel once a second.

### Subscriber 1 and 2

Those two services share the same source code to subscribe to a specific channel that is provided as an _environmental variable_.

I'm afraid the app doesn't do much more than subscribing and console logging the message 😅.

---

[postgres]: https://www.postgresql.org/
[docker-compose]: https://docs.docker.com/compose/
[make]: https://www.gnu.org/software/make/manual/make.html