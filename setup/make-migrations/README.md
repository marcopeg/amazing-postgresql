# Make Migrations

This project contains a basic migration facility made of _Makefile_ commands.

It let you break your project into different migration folders containing an `up.sql` and `down.sql` files as required in most of the famous migration tools out there.

```bash
# Boot your project
make start

# Apply migrations (all)
make up

# Unapply migrations (all)
make down

# Re-apply all migrations
make rebuild

# Reset the public schema
make reset