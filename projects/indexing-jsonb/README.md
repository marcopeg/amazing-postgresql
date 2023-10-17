# Indexing JSONB

In this project we will use concepts from randomic data seeding and `pgbench` to study different approaches into indexing a JSONB table.

## Quick Start

```bash
# Start / stop the project
make start
make stop

# SQL migrations
make up
make down

# Seeding
make seed
make seed from=file-name

# Test
make test
make run
```