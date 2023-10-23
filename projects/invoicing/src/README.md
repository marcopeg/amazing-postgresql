# SQL Migrations

Create here your migrations.

## Folder Structure

Each migration goes in its own folder named as `{MigrationID}_{migration-description}` such as:

- 001_basic-tables
- 002_functions

The `MigrationID` should be an integer.  
Migrations will be applied in ascending order.

> Timestamp makes it for a wonderful MigrationID

## Migration Files

Inside each folder you should create an `up.sql` and `down.sql` file.

## Utilities

From the CLI:

```bash
# Apply all migrations
make up

# Destroy all migrations
make down

# Redo all migrations
make rebuild
```