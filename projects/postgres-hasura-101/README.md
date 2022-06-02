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
  - [Insert a Single Value](#insert-a-single-value)
  - [Insert Multiple Values](#insert-multiple-values)
  - [Upsert Exising Values](#upsert-exising-values)
  - [Reset Data](#reset-data)
  - [Generate Series](#generate-series)
  - [Generate Randomic Data](#generate-randomic-data)
  - [Generate Randomic Timestamp](#generate-randomic-timestamp)
  - [Work With Regular Expressions](#work-with-regular-expressions)
- [Tracking Tables with Hasura.io](#tracking-tables-with-hasuraio)
- [Hasura Queries](#hasura-queries)
  - [Single Table Query](#single-table-query)
  - [Fetching Related Data](#fetching-related-data)
  - [Data Aggregation](#data-aggregation)
  - [Query Params](#query-params)
  - [Rename Fields & Sub Queries](#rename-fields--sub-queries)
- [Hasura Mutations](#hasura-mutations)
  - [Insert Single Record](#insert-single-record)
  - [Insert Single Record (variant)](#insert-single-record-variant)
  - [Insert Multiple Records](#insert-multiple-records)
  - [Insert Nested Data](#insert-nested-data)
- [Custom Relationships on Multiple Fields](#custom-relationships-on-multiple-fields)
- [Data Aggregation & Views](#data-aggregation--views)
  - [The Availability Query](#the-availability-query)
  - [The Availability View](#the-availability-view)
  - [PostgreSQL Views & Hasura.io](#postgresql-views--hasuraio)
  - [Materialized Views](#materialized-views)
- [Test For Performance Issues](#test-for-performance-issues)

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

### Generate Randomic Timestamp

Now we need to generate some product movements data.

This is somewhat more tricky for 2 reasons:

1. we want to simulate data over a long span of time, say last month
2. we want to randomize the `product_id` very much, but we don't want to hard-code the limits of it

To generate a randomic date we can mix `random()` and `interval`:

```sql
SELECT now() - '30d'::INTERVAL * random();
```

### Work With Regular Expressions

For the randomization of the `product_id`, we know that the IDs are contiguous, but we also know that they are strings, and that we need to know the highest number that is contained into it.

How do we extract `99` from `p99`?

```sql
SELECT NULLIF(regexp_replace('p9', '\D','','g'), '')::INT;
```

So we can get the max value contained into a `product_id`:

```sql
SELECT NULLIF(regexp_replace("id", '\D','','g'), '')::INT
FROM "public"."products"
ORDER BY "id" DESC
LIMIT 1;
```

For the `tenants` table we want to use a slightly different approach because we are **less certain** that the last row contains the highest ID:

```sql
SELECT MAX(NULLIF(regexp_replace("id", '\D','','g'), '')::INT)
FROM "public"."tenants"
```

We can put things together and build our seeding query:

```sql
INSERT INTO "public"."movements"
  ("tenant_id", "product_id", "created_at", "amount", "note")
SELECT
  -- randomic tenant_id in range:
  CONCAT('t', floor(random() * ((
    SELECT MAX(NULLIF(regexp_replace("id", '\D','','g'), '')::INT)
    FROM "public"."tenants"
  )- 1 + 1) + 1)) AS "tenant_id",

  -- randomic product_id in range:
  CONCAT('p', floor(random() * ((
    SELECT NULLIF(regexp_replace("id", '\D','','g'), '')::INT
    FROM "public"."products"
    ORDER BY "id" DESC
    LIMIT 1
  ) - 1 + 1) + 1)) AS "product_id",

  -- randomic created_at within the last 30 days
  now() - '30d'::INTERVAL * random() AS "created_at",

  -- randomic amount between -50 and 100 units
  floor(random() * (100 + 50 + 1) - 50)::int AS "amount",

  -- just a dummy note because we set a non null constraint
  '-'
FROM generate_series(1, 10) AS "m"
RETURNING *
```

---

## Tracking Tables with Hasura.io

In order to expose a GraphQL API over the data structure that we have created, we need to add the proper configuration into Hasura.

1. Go to the "data" tab
2. Click on the "public" schema
3. Click "track" on each of the tables we created

![Track tables](./images/track-tables.jpg)

Once Hasura gets to know the tables, it may also offer the possibility to track the _FOREIGN KEYS_ that have been set:

![Track relationships](./images/track-relationships.jpg)

Go ahead and track:

- tenants -> [producs]
- products -> [movements]
- products -> tenants

---

## Hasura Queries

### Single Table Query

Let's now move into the "API" tab and use the "Explorer" panel to build our first query:

![List tenants](./images/list-tenants.jpg)

```gql
query listTenants {
  tenants(order_by: { id: asc }, limit: 3) {
    name
  }
}
```

### Fetching Related Data

You should notice that you have `products` as a form of available field into your tenants explorer data-structure.

Open it up and select some products as well:

```gql
query listTenants {
  tenants(order_by: { id: asc }, limit: 3) {
    name
    products(
      where: { is_visible: { _eq: true } }
      order_by: { updated_at: desc }
      limit: 10
    ) {
      name
      price
    }
  }
}
```

👉 This is possible because we tracked the `tenants -> products` relation that Hasura could identify thanks to the _FOREIGN KEY_ that we have set.

We can take this approach even further and list all the movements that have been recorded for each Product:

```gql
query listTenants {
  tenants(order_by: { id: asc }, limit: 3) {
    name
    products(
      where: { is_visible: { _eq: true } }
      order_by: { updated_at: desc }
      limit: 10
    ) {
      name
      price
      movements(order_by: { created_at: asc }) {
        amount
        created_at
      }
    }
  }
}
```

### Data Aggregation

Getting the list of movements is not really useful, is it?

What we really want is to know **the product's availability**, which is the `SUM()` of all the movements:

```gql
query listTenants {
  tenants(order_by: { id: asc }, limit: 3) {
    name
    products(
      where: { is_visible: { _eq: true } }
      order_by: { updated_at: desc }
      limit: 10
    ) {
      name
      price
      movements_aggregate {
        aggregate {
          sum {
            amount
          }
        }
      }
    }
  }
}
```

### Query Params

Let's say we want to create a query that returns the informations for a specific product given its ID:

```gql
query getProduct($productId: String) {
  products(where: { id: { _eq: $productId } }, limit: 1) {
    name
    price
  }
}
```

variables:

{
"productId":"p1"
}

### Rename Fields & Sub Queries

With GraphQL and Hasura you can quickly put together quite complex queries that fetch related data from multiple tables, and generate many sub-queries to extract different aggregated values:

- product's fields
- product's availability out of the movements
- last 10 movements
- tenant's name
- tenant's products stats

```gql
query getProduct($productId: String!) {
  product: products_by_pk(id: $productId) {
    is_visible
    name
    description
    price
    updated_at
    created_at
    available_items: movements_aggregate {
      aggregate {
        sum {
          amount
        }
      }
    }
    last_movements: movements(order_by: { created_at: desc }, limit: 5) {
      created_at
      amount
      note
    }
    tenant {
      id
      name
      total_products: products_aggregate {
        aggregate {
          count(columns: id)
        }
      }
      visible_products: products_aggregate(
        where: { is_visible: { _eq: true } }
      ) {
        aggregate {
          count(columns: id)
        }
      }
      hidden_products: products_aggregate(
        where: { is_visible: { _eq: false } }
      ) {
        aggregate {
          count(columns: id)
        }
      }
    }
  }
}
```

The output looks something like:

```json
{
  "data": {
    "product": {
      "is_visible": true,
      "name": "Product1",
      "description": "Description for product1",
      "price": 80,
      "updated_at": "2022-06-02T07:02:02.400745+00:00",
      "created_at": "2022-06-02T07:02:02.400745+00:00",
      "available_items": {
        "aggregate": {
          "sum": {
            "amount": 192
          }
        }
      },
      "last_movements": [
        {
          "created_at": "2022-06-02T04:25:09.963454+00:00",
          "amount": -33,
          "note": "-"
        },
        {
          "created_at": "2022-06-02T01:22:39.041886+00:00",
          "amount": 38,
          "note": "-"
        },
        {
          "created_at": "2022-06-01T07:58:44.505914+00:00",
          "amount": 52,
          "note": "-"
        },
        {
          "created_at": "2022-05-29T17:33:32.004624+00:00",
          "amount": -49,
          "note": "-"
        },
        {
          "created_at": "2022-05-24T02:13:33.322909+00:00",
          "amount": 76,
          "note": "-"
        }
      ],
      "tenant": {
        "id": "t3",
        "name": "Tenant3",
        "total_products": {
          "aggregate": {
            "count": 8
          }
        },
        "visible_products": {
          "aggregate": {
            "count": 6
          }
        },
        "hidden_products": {
          "aggregate": {
            "count": 2
          }
        }
      }
    }
  }
}
```

---

## Hasura Mutations

### Insert Single Record

```gql
mutation addTenant($id: String!, $name: String!) {
  tenant: insert_tenants_one(
    object: { id: $id, name: $name }
    on_conflict: { constraint: tenants_pkey, update_columns: name }
  ) {
    id
    name
  }
}
```

variables:

```json
{
  "id": "mpe",
  "name": "Marco Peg"
}
```

output:

```json
{
  "data": {
    "tenant": {
      "id": "mpe",
      "name": "Marco Peg"
    }
  }
}
```

🚧 Play out with the conflict management, remove it, learn about Hasura errors.

### Insert Single Record (variant)

This mutation still inserts one single record:

```gql
mutation addTenant($id: String!, $name: String!) {
  tenants: insert_tenants(
    objects: { id: $id, name: $name }
    on_conflict: { constraint: tenants_pkey, update_columns: name }
  ) {
    affected_rows
    records: returning {
      id
      name
    }
  }
}
```

variables:

```json
{
  "id": "mpe",
  "name": "Marco Peg"
}
```

output:

```json
{
  "data": {
    "tenants": {
      "affected_rows": 1,
      "records": [
        {
          "id": "mpe",
          "name": "Marco Peg"
        }
      ]
    }
  }
}
```

### Insert Multiple Records

So far we played with a simple data type to characterize our input: `String`.

But Hasura builds more complex data types based on the schema that we provide.

Use the "Docs" panel on the right side of the GraphiQL editor, and navigate to (or search) the `insert_tenants` definition:

![Add tenants docs](./images/add-tenants-docs.jpg)

With this new information we can upgrade our mutation and receive a list of values that we want to upsert:

```gql
mutation addTenants($data: [tenants_insert_input!]!) {
  tenants: insert_tenants(
    objects: $data
    on_conflict: { constraint: tenants_pkey, update_columns: name }
  ) {
    affected_rows
    records: returning {
      id
      name
    }
  }
}
```

variables:

```json
{
  "data": [
    {
      "id": "mpe",
      "name": "Marco Peg"
    },
    {
      "id": "lsk",
      "name": "Luke Skywalker"
    }
  ]
}
```

output:

```json
{
  "data": {
    "tenants": {
      "affected_rows": 2,
      "records": [
        {
          "id": "mpe",
          "name": "Marco Peg"
        },
        {
          "id": "lsk",
          "name": "Luke Skywalker"
        }
      ]
    }
  }
}
```

### Insert Nested Data

Thanks to the data relations it is possible to insert nested data in one single mutation:

```gql
mutation addTenants(
  $id: String!
  $name: String!
  $products: [products_insert_input!]!
) {
  tenant: insert_tenants(
    objects: {
      id: $id
      name: $name
      products: {
        data: $products
        on_conflict: {
          constraint: products_pkey
          update_columns: [price, name, description]
        }
      }
    }
    on_conflict: { constraint: tenants_pkey, update_columns: name }
  ) {
    affected_rows
    records: returning {
      id
      name
      products(where: { updated_at: { _eq: "now()" } }) {
        id
        is_visible
        name
        price
        created_at
        updated_at
        movements(where: { created_at: { _eq: "now()" } }) {
          id
          created_at
          amount
          note
        }
      }
    }
  }
}
```

variables:

```json
{
  "id": "mpe",
  "name": "Marco Peg",
  "products": [
    {
      "id": "mpe_p1",
      "name": "First Product",
      "description": "First product from Marco",
      "price": 10,
      "movements": {
        "data": [
          {
            "amount": 1,
            "note": "First load",
            "tenant_id": "mpe"
          }
        ]
      }
    },
    {
      "id": "mpe_p2",
      "name": "Second Product",
      "description": "Second product from Marco",
      "price": 10
    }
  ]
}
```

🔥 Note that we must replicate the `tenant_id`. That is because the relation `product -> movements` is only set on the `id` field.

output:

```json
{
  "data": {
    "tenant": {
      "affected_rows": 4,
      "records": [
        {
          "id": "mpe",
          "name": "Marco Peg",
          "products": [
            {
              "id": "mpe_p1",
              "is_visible": true,
              "name": "First Product",
              "price": 10,
              "created_at": "2022-06-02T08:42:13.483459+00:00",
              "updated_at": "2022-06-02T08:49:15.807776+00:00",
              "movements": [
                {
                  "id": 11087,
                  "created_at": "2022-06-02T08:49:15.807776+00:00",
                  "amount": 1,
                  "note": "First load"
                }
              ]
            },
            {
              "id": "mpe_p2",
              "is_visible": true,
              "name": "Second Product",
              "price": 10,
              "created_at": "2022-06-02T08:43:51.169635+00:00",
              "updated_at": "2022-06-02T08:49:15.807776+00:00",
              "movements": []
            }
          ]
        }
      ]
    }
  }
}
```

---

## Custom Relationships on Multiple Fields

We want to improve the [Insert Nested Data](#insert-nested-data) mutation and avoid the need to duplicate the `tenant_id` inside each _movement_.

To achieve this, we need to setup a custom relationship between `products -> movements` and explain to hasura that both `product.id -> movement.product_id` and `product.tenant_id -> movement.tenant_id`.

1. Go to the "Data" tab
2. Click on the "Products" table from the left menu
3. Click on the "Relationships" tab
4. Under the "Array relationships", click "Edit" on movements
5. Remove the relationship

Now that you have removed the default relationship that Hasura did setup thanks to our _FOREIGN KEYS_, you can click on "Add a new relationship manually -> Configure":

![Relationship on multiple fields](./images/relationship-on-multiple-fields.jpg)

Once you have saved, you can go back to that [Insert Nested Data](#insert-nested-data) Mutation and remove the duplicated `tenant_id` from the movements rows.

---

## Data Aggregation & Views

In our simple schema, the availability of any given product must be calculated by summing all the related movement records.

Such a request can be achieved via Hasura:

```gql
query getProductsWithAvailability {
  products {
    id
    name
    description
    price
    is_visible
    availability: movements_aggregate {
      aggregate {
        sum {
          amount
        }
      }
    }
    tenant_id
    created_at
    updated_at
  }
}
```

🧐 Besides the sub-optimal output structure, with this solution we can't filter products by availability!

### The Availability Query

We could use plain SQL to perform the very same calculation:

```sql
SELECT "product_id", sum("amount") AS "amount"
FROM "movements"
GROUP BY "product_id"
LIMIT 10;
```

### The Availability View

And the next step is to "save" this query into a PostgreSQL view:

```sql
CREATE VIEW "public"."products_availability_live" AS
SELECT "product_id", sum("amount") AS "amount"
FROM "movements"
GROUP BY "product_id";
```

### PostgreSQL Views & Hasura.io

Views are just like tables in Hasura.

You can _track_ our new view, and you can setup a relationship that goes from the `products` table to the `products_availability_live` view.

1. Go to the "Data" tab
2. Click "Track _products_availability_live_" under "Untracked tables or views"
3. Click on "Products" from the left menu
4. Navigate to the "Relationships" tab
5. Add a manual Object relationship to the `products_availability_live` view

![Products Live Availability](./images/products-live-availability.jpg)

With this new configuration in place, we can go back to the API tab and simplify our query:

```gql
query getProductsWithAvailability {
  products {
    id
    name
    price
    availability: availability_live {
      amount
    }
  }
}
```

Now that we have this relationship in place, we can start to use the `availability.amount` field to sort and filter our dataset:

```gql
query getAvailableProducts {
  products(
    order_by: { availability_live: { amount: asc } }
    where: { availability_live: { amount: { _gt: "0" } } }
  ) {
    id
    name
    price
    availability: availability_live {
      amount
    }
  }
}
```

### Materialized Views

Materialized views store the result of a query in a persisted table instead of sourcing the real data at update time.

🔥 Materialized Views are a Cache Mechanism

For this reason, it is a good idea to add a `timestamp` information to the table, that will be forcefully updated when the view gets refreshed:

```sql
SELECT
  "product_id",
  sum("amount") AS "amount",
  now() AS "updated_at"
FROM "movements"
GROUP BY "product_id"
LIMIT 10;
```

The command to create the materialized view is similar to the one we used for the view:

```sql
CREATE MATERIALIZED VIEW "public"."products_availability_cached" AS
SELECT
  "product_id",
  sum("amount") AS "amount",
  now() AS "updated_at"
FROM "movements"
GROUP BY "product_id";
```

- try to change some availability and see that the "live" view updates while the "cached" view doesn't
- try to add or remove products as well

In order to update a materialized view we must issue a manual command:

```sql
REFRESH MATERIALIZED VIEW "public"."products_availability_cached";
```

👉 Be careful with Materialized Views, they are cool, but occupy much disk space and may end up being quite heavy to refresh!

With Hasura, you can use Materialized Views pretty much the same way you use Views.

### The ProductsDisplay View

We can move a step forward and look into joining data between tables and views, as so to provide a linear data structure that would give us only visible and available products.

The query may be:

```sql
SELECT
  "p"."id",
  "p"."tenant_id",
  "p"."name",
  "p"."description",
  "p"."price",
  "a"."amount",
  "p"."created_at",
  "p"."updated_at"
FROM "products_availability_live" AS "a"
LEFT JOIN "products" AS "p" ON "p"."id" = "a"."product_id"
WHERE "p"."is_visible" IS TRUE
  AND "a"."amount" > 0
LIMIT 10;
```

And the resulting view:

```sql
CREATE VIEW "public"."products_display" AS
SELECT
  "p"."id",
  "p"."tenant_id",
  "p"."name",
  "p"."description",
  "p"."price",
  "a"."amount",
  "p"."created_at",
  "p"."updated_at"
FROM "products_availability_live" AS "a"
LEFT JOIN "products" AS "p" ON "p"."id" = "a"."product_id"
WHERE "p"."is_visible" IS TRUE
  AND "a"."amount" > 0;
```

---

## Test For Performance Issues

The first step for finding bottleneck is to seed TONS of data.

- use the `products` seed query and plant at least 100k products
- use the `movements` seed query and plant at least 500k products

And right away we can start noticing that the following query takes above 1 second to perform:

```gql
query MyQuery {
  products_display(limit: 10) {
    name
    amount
  }
}
```

The reason is that there is great diversity in the `product_id` from line to line.

It would be much easier for the PostgreSQL engine to do the math if all `p1` lines where one after the other, and then `p2`, and so forth.

Luckily, we can fix this with an index:

```sql
CREATE INDEX "movements_product_id_idx"
ON "movements" ("product_id" ASC);
```

> 🔥 Even with indexes, keeping a live inventory for a large amount of products/movements is a **really bad idea!**

---

[docker-compose]: https://docs.docker.com/compose/
[yaml]: https://en.wikipedia.org/wiki/YAML
[adminer]: https://www.adminer.org/
[hasura]: https://hasura.io/
[graphql]: https://graphql.org/
