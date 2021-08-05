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
pgtap_version?=0.96.0-2

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

build:
	clear
	@echo "Building Project ..."
	@cat \
		$(CURDIR)/src/foobar.sql \
	> $(CURDIR)/$(pg_data)/init-schema.sql

test: build
	clear
	@echo "Setting up Database ..."
	@docker exec -i $(pg_name) psql -U postgres < reset-db.sql
	@docker exec -i $(pg_name) psql -U postgres test-db < $(CURDIR)/$(pg_data)/init-schema.sql
	clear
	@echo "Running Unit Tests ..."
	@docker run -it --rm --name pgtap --link $(pg_name):db -e PASSWORD=$(pg_password) -e DATABASE=test-db -v $(CURDIR)/tests/:/test lren/pgtap:$(pgtap_version) install.sh

