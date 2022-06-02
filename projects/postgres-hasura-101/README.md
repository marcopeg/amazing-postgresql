# PostgreSQL + Hasura.io = Backend-less GraphQL APIs

The goal of this project is to create the GraphQL APIs for a simple e-commerce solution using PostgreSQL and Hasura.io.

---

## Table of Contents

- [Prerequisites](#prerequisites)
- [Run the Project](#run-the-project)
- [Docker-Compose 101](#docker-compose-101)
  - [PostgreSQL on Docker-Compose](#postgresql-on-docker-compose)
  - [Adminer on Docker-Compose](#adminer-on-docker-compose)
  - [Hasura.io on Docker-Compose](#hasuraio-on-docker-compose)
- [Basic Schema](#basic-schema)
  - [tenants](#tenants)
  - [products](#products)
  - [movements](#movements)
- [Data Seeding](#data-seeding)

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

# Stop the running PostgreSQL and remove the container
# (data is still persisted to the local disk)
make stop
```

---

## Docker-Compose 101

[Docker-Compose][docker-compose] helps you run multi-container projects using a [YAML][yaml] file to declare each container properties and relations.

The basic structure of a Docker-Compose project is defined in a `docker-compose.yml` file:

```yaml
version: "3.9"
services:
  postgres:
  hasura:
```

- the `version` key identifies the project's capabilities and running APIs
- the `services` key contains a list of each container, identified by its name

### PostgreSQL on Docker-Compose

We can run PosrgreSQL using the latest version from the [Official Docker Image](https://hub.docker.com/_/postgres):

```yml
postgres:
  image: postgres:14
  ports:
    - "${POSTGRES_PORT:-5432}:5432"
  volumes:
    - .docker-data/pg:/var/lib/postgresql/data
  environment:
    POSTGRES_PASSWORD: ${POSTGRES_PASSWORD:-postgres}
```

- `ports` maps the container's exposed ports to the host machine
- `volumes` maps the container's file system to some folders on the host machine, it is used so data survives the temporary destruction of a container
- `environent` passes configuration to the container's service, you learn what variabile you need to set into the image's documentation page

👉 here we use `${POSTGRES_PORT:-5432}` which is a way to define values that let configure the value using a `.env` file.

If you want to change PostgreSQL's port, create a `.env` file and try to write:

```bash
POSTGRES_PORT=7777
```

You can use the same approach for the password or other configuration that you may want to add.

### Adminer on Docker-Compose

[Adminer][adminer] offers a simple web-based database administration interface, and we are going to use it to explore our schema and run experimental queries.

We can run it as a Docker-Compose service using the [Official Docker Image](https://hub.docker.com/_/adminer):

```yml
adminer:
  image: adminer:4.8.1
  ports:
    - "${ADMINER_PORT:-8008}:8080"
```

👉 Once you visit `http://localhost:8008` you can use the value `postgres` in each field of the login form and gain access to you local PostgreSQL instance.

### Hasura.io on Docker-Compose

[Hasura.io][hasura] generates a [GraphQL][graphql] API starting from a database schema and some YAML-based configuration rules.

We can run it as a Docker-Compose service using the [Official Docker Image](https://hub.docker.com/r/hasura/graphql-engine):

```yml
hasura:
  image: hasura/graphql-engine:v2.7.0
  ports:
    - "${HASURA_PORT:-8080}:8080"
  environment:
    HASURA_GRAPHQL_DEV_MODE: "true"
    HASURA_GRAPHQL_ENABLE_CONSOLE: "true"
    HASURA_GRAPHQL_ADMIN_SECRET: "${HASURA_ADMIN_SECRET:-hasura}"
    HASURA_GRAPHQL_DATABASE_URL: postgres://postgres:${POSTGRES_PASSWORD:-postgres}@postgres:5432/postgres
    HASURA_GRAPHQL_ENABLED_LOG_TYPES: startup, http-log, webhook-log, websocket-log, query-log
    HASURA_GRAPHQL_ENABLE_TELEMETRY: "false"
  restart: unless-stopped
```

👉 Once you visit `http://localhost:8080` you can use the value `hasura` to gain access to the console interface.

---

## Basic Schema

We want to run a multi-tenant and multi-user e-commerce service, so at the very least we need to show some products based on the shop someone is visiting.

Let's say that our first goal is to create a **products list** page that answers to the URL:  
`http://my-web-shop.com/:tenant`

We will need a few tables then:

- tenants
- products
- movements

### tenants

| name | type |
| ---- | ---- |
| id   | text |
| name | text |

👉 For sake of simplicity we will use text-based IDs like `t1`, `t2`. It will facilitate the data-seeding and the testing of our system.

```sql
CREATE TABLE "public"."tenants" (
  "id" TEXT,
  "name" TEXT NOT NULL,
  CONSTRAINT "tenants_pkey" PRIMARY KEY ("id")
);
```

### products

In this table we want to list the products that are sold by each tenant:

| name        |  type     | default |
| ----------- | --------- | ------- |
| id          | text      | -       |
| tenant_id   | text      | -       |
| is_visible  | boolean   | true    |
| name        | text      | -       |
| description | text      | -       |
| price       | integer   | -       |
| created_at  | timestamp |  now()  |
| updated_at  | timestamp |  now()  |

👉 For sake of simplicity we will use text-based IDs like `p1`, `p2`. It will facilitate the data-seeding and the testing of our system.

```sql
CREATE TABLE "public"."products" (
  "id" TEXT NOT NULL,
  "tenant_id" TEXT NOT NULL,
  "is_visible" BOOLEAN DEFAULT TRUE NOT NULL,
  "name" TEXT NOT NULL,
  "description" TEXT NOT NULL,
  "price" INTEGER NOT NULL,
  "created_at" TIMESTAMPTZ DEFAULT NOW() NOT NULL,
  "updated_at" TIMESTAMPTZ DEFAULT NOW() NOT NULL,
  CONSTRAINT "products_pkey" PRIMARY KEY ("id")
);
```

#### Data Validation

Next we want to add a simple **validation rule** that avoids stupid mistakes like setting negative prices on a product.

You can go a long way into enforcing data integrity with checks:

```sql
-- Create the constraint:
ALTER TABLE "public"."products"
ADD CONSTRAINT "products_price_check"
CHECK (price > 0);

-- Remove the constraint:
ALTER TABLE "products"
DROP CONSTRAINT "products_price_check"
```

- try to add or update a product with a negative price _before and after_ setting the check
- try to add a product with `price=0` _before_ adding the check, then try to add the check

#### Relational Data Integrity

The `tenant_id` is a logical link to the `tenants` table, but we can make this relation explicit to the PostgreSQL, and set rules how to handle related data events.

```sql
-- Create the constraint:
ALTER TABLE ONLY "public"."products"
ADD CONSTRAINT "products_tenant_id_fkey"
FOREIGN KEY (tenant_id) REFERENCES tenants(id)
ON UPDATE CASCADE
ON DELETE CASCADE
NOT DEFERRABLE;

-- Remove the constraint:
ALTER TABLE "products"
DROP CONSTRAINT "products_tenant_id_fkey"
```

- try to add a product thar reference a non-existent tenant _before and after_ adding the constraint
- try to add a few products for a specific tenant, and then delete the tenant, _before and after_ adding the constraint

#### Data Automation

The last step for this table is to add a simple automation and automagically update the `updated_at` value every time the product line changes.

```sql
CREATE FUNCTION "public"."set_current_timestamp_updated_at"()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
  NEW."updated_at" = NOW();
  RETURN NEW;
END;
$$

CREATE TRIGGER "set_public_products_updated_at"
BEFORE UPDATE ON "public"."products"
FOR EACH ROW EXECUTE FUNCTION "public"."set_current_timestamp_updated_at"();
```

> 🚧 Can you modify this function as so to update `updated_at` only when the `price` changes?

### movements

This table tracks the changes in produts availability.

It is a _timeserie_ where we will only INSERT an immutable list of information that record "what happened" to a specific product.

|  name      | type      | default       |
| ---------- | --------- | ------------- |
| id         | integer   | autoincrement |
| tenant_id  | text      | -             |
| product_id | text      | -             |
| created_at | timestamp | current-time  |
| amount     | integer   | 0             |
| note       | text      | -             |

```sql
CREATE SEQUENCE "movements_id_seq"
INCREMENT 1
MINVALUE 1
MAXVALUE 2147483647
CACHE 1;

CREATE TABLE "public"."movements" (
  "id" INTEGER NOT NULL DEFAULT nextval('movements_id_seq'),
  "tenant_id" TEXT NOT NULL,
  "product_id" TEXT NOT NULL,
  "created_at" TIMESTAMPTZ DEFAULT NOW() NOT NULL,
  "amount" INTEGER NOT NULL,
  "note" TEXT NOT NULL,
  CONSTRAINT "movements_pkey" PRIMARY KEY ("id")
);
```

You can play around with sequences as they were tables:

```sql
-- Get the current value:
SELECT "last_value" FROM "public"."movements_id_seq";

-- Increase the value and read it out:
SELECT nextval('movements_id_seq') AS "next_value";

-- Set the sequence to a specific value:
SELECT setval('movements_id_seq', 100);
```

And here is a handy query that will reset the sequence to the maximum value from a target table/column:

```sql
SELECT setval('movements_id_seq', COALESCE((
  SELECT MAX(id) + 1 FROM "public"."movements"
), 1), false);
```

Next step is to add the relational data integrity constraints:

```sql
ALTER TABLE ONLY "public"."movements"
ADD CONSTRAINT "movements_tenant_id_fkey"
FOREIGN KEY (tenant_id) REFERENCES tenants(id)
ON UPDATE CASCADE
ON DELETE CASCADE
NOT DEFERRABLE;

ALTER TABLE ONLY "public"."movements"
ADD CONSTRAINT "movements_product_id_fkey"
FOREIGN KEY (product_id) REFERENCES products(id)
ON UPDATE CASCADE
ON DELETE CASCADE
NOT DEFERRABLE;
```

---

## Data Seeding

It is extremely important to learn how to generated dataset that we can use to test our software.

We can use it to run 2 types of test:

- data integrity
- performance bottlenecks

### Insert a Single Value

```sql
INSERT INTO "tenants" ("id", "name")
VALUES ('t1', 'tenant1');
```

### Insert Multiple Values

```sql
INSERT INTO "public"."tenants" ("id", "name")
VALUES
  ('t2', 'tenant2')
, ('t3', 'tenant3')
, ('t4', 'tenant4')
;
```

### Upsert Exising Values

```sql
INSERT INTO "public"."tenants" ("id", "name")
VALUES
  ('t2', 'tenant2')
, ('t3', 'tenant3')
, ('t4', 'tenant4')
-- handle conflicts:
ON CONFLICT ON CONSTRAINT "tenants_pkey"
DO UPDATE SET "name" = EXCLUDED."name";
```

### Reset Data

```sql
TRUNCATE "public"."tenants"
RESTART IDENTITY
CASCADE;
```

### Generate Series

You can use `generate_series` to produce an arbitrary amount of rows:

```sql
SELECT * FROM generate_series(1, 10);
```

Then you can combine such data in order to generate the desired dataset:

```sql
SELECT
  CONCAT('t', "t") AS "id",
  CONCAT('Tenant', "t") AS "name"
FROM generate_series(1, 5) AS "t";
```

Finally, we can put things together and use this strategy to seed an arbitrary amount of data:

```sql
INSERT INTO "public"."tenants" ("id", "name")

-- Describe the dataset:
SELECT
  CONCAT('t', "t") AS "id",
  CONCAT('Tenant', "t") AS "name"

-- Set the size of the dataset:
FROM generate_series(1, 10) AS "t"

-- Manage conflicts with existing values:
ON CONFLICT ON CONSTRAINT "tenants_pkey"
DO UPDATE SET "name" = EXCLUDED."name"

-- Return the dataset that was produced:
RETURNING *;
```

### Generate Randomic Data

So far we have managed to generate and insert 10 tenants, and we could use the same queries to generate thousands of products.

But we have a problem, a product must refer to an existing tenant, and the idea would be to distribute some thousands of products among the different tenants.

> An easy way out would be to associate the product line with a randomic `tenant_id`: `[t1 .. t10]`.

```sql
-- Produce a randomic number between 1 and 10:
SELECT floor(random() * (10 - 1 + 1) + 1);

-- Generate a randomic tenant_id:
SELECT CONCAT('t', floor(random() * (10 - 1 + 1) + 1)) AS "tenant_id";
```

Let's now put the things together:

```sql
INSERT INTO "public"."products"
("id", "tenant_id", "is_visible", "name", "description", "price")

-- Describe the dataset:
SELECT
  CONCAT('p', "p") AS "id",
  -- randomic tenant_id (t1 .. t10)
  CONCAT('t', floor(random() * (10 - 1 + 1) + 1)) AS "tenant_id",
  -- 25% of the products are set as hidden
  random() > 0.25 AS "is_visible",
  CONCAT('Product', "p") AS "name",
  CONCAT('Description for product', "p") AS "description",
  -- randomic price (10 .. 100)
  floor(random() * (10 - 1 + 1) + 1) * 10 AS "price"

-- Set the size of the dataset:
FROM generate_series(1, 100) AS "p"

-- Manage conflicts with existing values:
ON CONFLICT ON CONSTRAINT "products_pkey"
DO UPDATE SET
  "tenant_id" = EXCLUDED."tenant_id",
  "name" = EXCLUDED."name",
  "description" = EXCLUDED."description",
  "price" = EXCLUDED."price",
  "is_visible" = EXCLUDED."is_visible"

-- Return the dataset that was produced:
RETURNING *;
```

### Generate Randomic Timeserie

---

[docker-compose]: https://docs.docker.com/compose/
[yaml]: https://en.wikipedia.org/wiki/YAML
[adminer]: https://www.adminer.org/
[hasura]: https://hasura.io/
[graphql]: https://graphql.org/
