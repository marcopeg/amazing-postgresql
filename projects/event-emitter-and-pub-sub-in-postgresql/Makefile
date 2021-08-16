# Local Variables
# ===============
#
# Pass custom values to the `make` cli as:
# > make start pg_name=foobar
#
pg_name?=test-db
pg_password?=postgres
pg_version?=13.2
pg_data?=.docker-data

start:
	@echo "Starting Project..."
	@mkdir -p $(CURDIR)/$(pg_data)
	@docker-compose up -d
	@docker-compose logs -f

stop:
	@echo "Stopping Project..."
	@docker-compose down

logs:
	clear
	@echo "Attaching to Postgres logs..."
	@docker-compose logs -f

psql:
	@echo "Connecting to the database ("quit" to exit) ..."
	@docker exec -it $(pg_name) psql -U postgres postgres

seed:
	@docker exec -i $(pg_name) psql -U postgres postgres < ./seed.sql

#                                                                                         #
# --------------------------------------------------------------------------------------- #
#                                                                                         #

# This command will run the application using an isolated Docker container instead of
# the `docker-compose` version.
# I leave it here mostly as documentation how to use the `--entrypoint` in conjunction
# with a custom start command, using the standard Node image
app:
	@docker run --rm \
		-v $(CURDIR)/$(pg_data)/node_modules:/usr/src/app/node_modules:cached \
		-v $(CURDIR)/src:/usr/src/app/src:delegated \
		-v $(CURDIR)/package.json:/usr/src/app/package.json:delegated \
		-v $(CURDIR)/package-lock.json:/usr/src/app/package-lock.json:delegated \
		-e PGSTRING=postgresql://postgres:postgres@db:5432/postgres \
		--link test-db:db \
		--workdir="/usr/src/app" \
		--entrypoint="" \
		node:14-alpine \
		npm run start:docker
	