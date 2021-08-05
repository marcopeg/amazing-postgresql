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
	@echo "Starting Postgres..."
	@docker run --rm -d \
		--name $(pg_name) \
		-p 5432:5432 \
		-e POSTGRES_PASSWORD=postgres \
		-v $(CURDIR)/$(pg_data):/var/lib/postgresql/data \
		postgres:$(pg_version)

stop:
	@echo "Stopping Postgres..."
	@docker stop $(pg_name) || true

psql:
	@echo "Connecting to the database ("quit" to exit) ..."
	@docker exec -it $(pg_name) psql -U postgres postgres

bench-init:
	@echo "Populating PostgreSQL with dummy data ..."
	@docker exec -it $(pg_name) pgbench -U postgres -i -s 50 postgres

bench-run:
	@echo "Running pgbench on target database ..."
	@docker exec -it $(pg_name) pgbench -U postgres -c 10 -j 2 -t 10000 postgres