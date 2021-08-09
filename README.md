# Amazing PostgreSQL

This repository is a personal documentation project of my jurney with [PostgreSQL][postgres].

As I progress in this jurney, I will do my best to provide well defined use cases where PostgreSQL can make a difference in your engineering experience.

Tag along in this journey and you will learn how a single tool can offer advanced functionalities and **almost replace** the need for advanced systems like [Redis][redis], [RabbitMQ][rabbit] or [Kafka][kafka].

---

## Table of Contents

👉 In this page:

- [Why is PosgreSQL so cool?](#why-is-postgresql-so-cool)
- [One Tool to Handle 'em All](#one-tool-to-handle-em-all)
- [Prerequisites for Running the Examples](#prerequisites-for-running-the-examples)
- [Licence](#licence)

👉 Projects and Tutorials:

- [How to run Postgres](./setup/run-with-docker)
- Testing in PostgreSQL
  - [Unit Tests on PostgreSQL](./testing/unit-tests)
  - [Load Test on PostgreSQL](./testing/load-test)
  - [Run PostgreSQL queries on JMeter](./testing/jmeter/)
- Projects
  - [Timestamp as Primary Key in PostgreSQL](./projects/timestamp-as-primary-key-in-postgresql)
  - [Observing Tables Changes in PostgreSQL](./observing-tables-changes-in-postgresql)
  - How to handle counters in Postgres
  - How to do Event Sourcing in Postgres
  - How to handle Tasks in Postgres

---

## Why is PostgreSQL so cool?

Modern apps require a variety of data pattenrs. Even among small sized projects, it is common to witness normalized and denormalized data structures, cache layers, event emitters and reactive programming styles.

Surely, many different tools has been created over the yers as "the best option for X". Resulting in a **multi-technology hell in which engineers are demanded to learn way too many things, mastering none of them**.

> PostgreSQL is like McGyver's Swiss knife.  
> It can do many different things, and it does them pretty well too.

### My personal points are:

- PostgreSQL combines SQL and NoSQL into one single tool. You can handle tables AND documents.
- PostgreSQL comes with tons of extensions. GIS, UUID, and even Cron jobs!
- `SELECT ... FOR UPDATE ... SKIP LOCKED` is a magic spell that makes it possible to implement highly concurrent tasks on a single db instance. I made [Fetchq](https://fetchq.com) thanks to this feature.
- PostgreSQL embeds a pub/sub broker, making stuff like Redis or RabbitMQ slightly redundant.
- PostgreSQL offers table routing rules to store different data into different disks. Note that a single EBS disk can go up to 16Tb of data, with multiple disks you can potentially store in PostgreSQL more than 30Tb without clustering it.
- PostgreSQL offers table partitioning rules. This makes it possible to achive linear data ingestion performances even as data grows huge.

### Here are a few articles that I find inspiring:

- https://fulcrum.rocks/blog/why-use-postgresql-database/
- https://learnsql.com/blog/companies-that-use-postgresql-in-business/
- https://www.enterprisedb.com/blog/4-reasons-postgresql-was-named-database-management-system-year-2020

---

## One Tool to Handle 'em All

PostgreSQL is a safe bet for any new project.  
With it you can replace:

- [Redis][redis]: because it embeds a pub/sub broker.
- [RabbitMQ][rabbit]: because you can handle queues of billions of tasks that are given to a great number of parallel clients.
- [Kafka][kafka]: because you can store massive amount of events into partitioned tables, handling each client's cursor in it.
- [ElasticSearch][elastic]: because you can run full-text searches and index any field into a schema-less JSON data structure.

> You can focus in learning PostgreSQL deeply, instead of spreading your attention span over multiple tools!

PostgreSQL **is also free** as in "free of speech" and "free beer". No commercial licencing. You use it.

PostgreSQL **is also embarassingly cheap to run**. I've been running a massiva data scraping project on a ridiculous budget of ~~160 dollars per month by running PostgreSQL on an AWS EC2 machine via Docker. 

> A small-to-medium project will easily run Postgres + the application services on a single EC2 using stuff like CapRover for under 30 dollars / month!

---

## Prerequisites for Running the Examples

I run all my stuff on a MacOS while actively developing on it. I will possibly test a few things on Ubuntu20+ on AWS but there is no guarantee for any of the examples/projects to really work outside my machine 😅.

I will make a serious effort to avoid any local dependency by wrapping **almost everything** with [Docker][docker]. It works well most of the time.

Along this journey, I'll be using the following technologies:

- [PostgreSQL][postgres]: the database
- [PSql][psql]: Postgres' procedural language
- [PgTap][pgtap]: A Unit Test framework for Postgres
- [Docker][docker]: I will run **almost everything** as a container
- [Make][make]: I will document every _CLI_ command into _Makefiles_
- [NodeJS][node]: A few demo applications to play with Postgres
- [Typescript][typescript]: The emerging typed language for Javascript

---

## Licence

You can freely use the resources in this repo.

- [Read the full licence](./LICENCE.md)
- [MIT Licence](https://opensource.org/licenses/MIT)

> I would **seriously appreciate** if you mention me, my work and my website in case you find it useful and/or plan to use and/or redistribute my work.

---

[postgres]: https://www.postgresql.org/
[docker]: https://www.docker.com/
[make]: https://www.gnu.org/software/make/manual/make.html
[pgtap]: https://pgtap.org/
[psql]: https://www.postgresql.org/docs/13/app-psql.html
[node]: https://nodejs.org
[typescript]: https://www.typescriptlang.org/
[redis]: https://
[rabbit]: https://
[kafka]: https://
[elastic]: https://